unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, DateTimePicker, Forms, Controls, Graphics,
  Dialogs, Menus, StdCtrls, ExtCtrls, Grids, LazFileUtils,
  DateUtils, MisUtils;
//MisUtils: https://github.com/t-edson/MisUtils

type

  { TForm1 }
  nazvy_stat = record
    typ:string;
    id:integer;
    kod:integer;
    mnozstvo:integer;
    cena:integer;
    meno:string;
    datum:integer;
   end;
  nazvy_top = record
    meno:string;
    kod:integer;
    prijmy:integer;
    naklad:integer;
    zisk:integer;
  end;
  nazvy_tovar = record
    meno:string;
    kod:integer;
  end;

  TForm1 = class(TForm)
    Button1: TButton;
    Filter: TButton;
    Image1: TImage;
    Image2: TImage;
    gridus: TStringGrid;
    Label1: TLabel;
    loadingImage: TImage;
    loadingg: TTimer;
    zisk: TLabel;
    MenuItem2: TMenuItem;
    Podlamena: TMenuItem;
    Podlakodu: TMenuItem;
    Zobrazujem: TLabel;
    Reload: TButton;
    filter4: TCheckBox;
    Priemercena: TLabel;
    priemerkvantita: TLabel;
    filter3: TCheckBox;
    filter1: TCheckBox;
    Kontrola_suborov: TTimer;
    filter2: TCheckBox;
    Oddatum: TDateTimePicker;
    PoDatum: TDateTimePicker;
    trzby: TLabel;
    naklady: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    Top10: TMenuItem;
    poT10: TMenuItem;
    MenuItem4: TMenuItem;
    procedure Button1Click(Sender: TObject);
    procedure FilterClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Kontrola_suborovTimer(Sender: TObject);
    procedure loadinggTimer(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure PodlakoduClick(Sender: TObject);
    procedure PodlamenaClick(Sender: TObject);
    procedure poT10Click(Sender: TObject);    //PROC 3
    procedure ReloadClick(Sender: TObject);
    procedure Top10Click(Sender: TObject);    //PROC 2
    procedure nacitanie;
    procedure sort;
    procedure top;
    procedure Vytvaranie_TOP;
    procedure filtrovanie;
    procedure spravmigraf;
    procedure defaultview;                    //PROC 1
    procedure cislujmi(pocet:integer);
  private

  public

  end;
Const //PATH = 'Z:\INFProjekt2019\TimA\';
      PATH = '';
var
  Form1: TForm1;
  ver_stati:integer; //verzie databaz
  ver_tovar:integer; //

  stats:array[1..1000] of nazvy_stat; //hlavne pole databaz
  stats_length:integer;              //dlžka pola (kolko riadkov)

  topp:array[1..1000] of nazvy_top;     //Zoradene produkty od naj po najmenej
  top_length:integer;                 //Počet produktov

  stats_filter:array[1..1000] of nazvy_stat;   //filtrovane pole stats
  stats_filter_length:integer;

  ptovar:array[1..1000] of nazvy_tovar;
  ptovar_length:integer;

  aktualna_proc:integer;
  frame:integer; //do loadingg timeru

//  debugCount: qword;     //Debug


implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
var i:integer;
    subor:textfile;
    pom_s:string;
begin
//incializacia + logo
image2.picture.LoadFromFile('logo_transparent.bmp');
frame:=0;
//Vyčistenie polí

 for i:=1 to stats_length do begin
       stats[i].id:=0;
       stats[i].kod:=0;
       stats[i].mnozstvo:=0;
       stats[i].cena:=0;
       topp[i].kod:=0;
       topp[i].prijmy:=0;
       topp[i].naklad:=0;
       topp[i].zisk:=0;
 end;

NACITANIE;
//Ziskanie verzii
AssignFile(subor,PATH+'STATISTIKY_VERZIA.txt');
Reset(subor);
ReadLn(subor,pom_s);
ver_stati:=StrToInt(pom_s);
CloseFile(subor);

AssignFile(subor,PATH+'TOVAR_VERZIA.txt');
Reset(subor);
ReadLn(subor,pom_s);
ver_tovar:=StrToInt(pom_s);
CloseFile(subor);

Podatum.date:=date;
DefaultView;
end;

procedure TForm1.DefaultView;
var i:integer;
begin
//Default view
{memo1.clear;
for i:=1 to top_length do
        memo1.append(topp[i].meno+' má aktualne prijmy: '+IntToStr(topp[i].prijmy)+'€'+' má naklady '+IntToStr(topp[i].naklad)+'€'+' s celkovym ziskom: '+IntToStr(topp[i].zisk)+'€');

        }
gridus.rowcount:=top_length+1;
cislujmi(gridus.rowcount);
for i:=1 to top_length do begin
    gridus.Cells[1,i]:=topp[i].meno;
    gridus.Cells[2,i]:=IntToStr(topp[i].prijmy)+'€';
    gridus.Cells[3,i]:=IntToStr(topp[i].naklad)+'€';
    gridus.Cells[4,i]:=IntToStr(topp[i].zisk)+'€';



      end;
aktualna_proc:=1;
zobrazujem.caption:='Zobrazujem: všetky tovary';
end;

procedure TForm1.Button1Click(Sender: TObject);
var pom_s:string;
    i:integer;
begin
  spravmigraf;
  //for i:=1 to stats_length do memo1.append(stats[i].typ+'  '+IntToStr(stats[i].kod)+'  '+IntToStr(stats[i].cena)+'  '+IntToStr(stats[i].mnozstvo));
end;

procedure TForm1.FilterClick(Sender: TObject);
begin
  //top;
  nacitanie;
zobrazujem.caption:='';
case aktualna_proc of
     1:DefaultView;
     2:Top10.click;
     3:poT10.click;
     end;
end;

procedure TForm1.Kontrola_suborovTimer(Sender: TObject);
var stati,tovarik:integer;
    subor:textfile;
    pom_s:string;
begin
  AssignFile(subor,PATH+'TOVAR_VERZIA.txt');
  Reset(subor);
  ReadLn(subor,pom_s);
  tovarik:=StrToInt(pom_s);
  Closefile(subor);

  AssignFile(subor,PATH+'STATISTIKY_VERZIA.txt');
  Reset(subor);
  ReadLn(subor,pom_s);
  stati:=StrToInt(pom_s);
  Closefile(subor);

  if ((stati > ver_stati) OR (tovarik > ver_tovar)) then
     begin nacitanie; Vytvaranie_TOP; end;
end;

procedure TForm1.loadinggTimer(Sender: TObject);
begin

  loadingImage.picture.loadfromfile('loading/loading_'+IntToStr(frame)+'.bmp');
  inc(frame);
  if frame > 39 then frame:=0;
end;

procedure TForm1.MenuItem4Click(Sender: TObject);
begin
   DefaultView;
end;

procedure TForm1.PodlakoduClick(Sender: TObject);
var userstring:string;
    i,hladany_kod:integer;
begin
zobrazujem.caption:='';
aktualna_proc:=0;
 if not InputQuery('Kód', 'Aký má kód?', UserString) then begin zobrazujem.caption:=''; exit; end;
 if not TryStrtoInt(userstring,hladany_kod) then begin MsgErr('Was das?'); exit; end;

for i:=top_length downto 1 do begin
      if (hladany_kod = topp[i].kod) then begin
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!        memo1.append(topp[i].meno+' má aktualne prijmy: '+IntToStr(topp[i].prijmy)+'€'+' má naklady '+IntToStr(topp[i].naklad)+'€'+' s celkovym ziskom: '+IntToStr(topp[i].zisk)+'€');
gridus.rowcount:=1+1;
cislujmi(gridus.rowcount);
    gridus.Cells[1,1]:=topp[i].meno;
    gridus.Cells[2,1]:=IntToStr(topp[i].prijmy)+'€';
    gridus.Cells[3,1]:=IntToStr(topp[i].naklad)+'€';
    gridus.Cells[4,1]:=IntToStr(topp[i].zisk)+'€';



      end;
      end;



zobrazujem.caption:='Zobrazujem: '+userstring;
end;

procedure TForm1.PodlamenaClick(Sender: TObject);
var userstring:string;
    i:integer;

begin
zobrazujem.caption:='';
aktualna_proc:=0;
 if not InputQuery('Meno', 'Ako sa volá?', UserString) then begin zobrazujem.caption:=''; exit; end;
for i:=top_length downto 1 do begin
      if userstring = topp[i].meno then begin
//!!!!!!!!!!!!!!!!!!!        memo1.append(topp[i].meno+' má aktualne prijmy: '+IntToStr(topp[i].prijmy)+'€'+' má naklady '+IntToStr(topp[i].naklad)+'€'+' s celkovym ziskom: '+IntToStr(topp[i].zisk)+'€');
        gridus.rowcount:=1+1;
cislujmi(gridus.rowcount);
    gridus.Cells[1,1]:=topp[i].meno;
    gridus.Cells[2,1]:=IntToStr(topp[i].prijmy)+'€';
    gridus.Cells[3,1]:=IntToStr(topp[i].naklad)+'€';
    gridus.Cells[4,1]:=IntToStr(topp[i].zisk)+'€';

      end;
zobrazujem.caption:='Zobrazujem: '+userString;
end;

end;

procedure TForm1.Top10Click(Sender: TObject);
var
    i,j:integer;
begin
gridus.rowcount:=11;
cislujmi(gridus.rowcount);
i:=1;
j:=1;
  while not (j = 11) do begin
        if not ((topp[i].naklad = 0) AND (topp[i].prijmy = 0)) then begin
           //memo1.append(inttostr(j)+'.  '+topp[i].meno+' má aktualne prijmy: '+IntToStr(topp[i].prijmy)+'€'+' má naklady '+IntToStr(topp[i].naklad)+'€'+' s celkovym ziskom: '+IntToStr(topp[i].zisk)+'€');
           gridus.Cells[1,j]:=topp[i].meno;
           gridus.Cells[2,j]:=IntToStr(topp[i].prijmy)+'€';
           gridus.Cells[3,j]:=IntToStr(topp[i].naklad)+'€';
           gridus.Cells[4,j]:=IntToStr(topp[i].zisk)+'€';
           inc(j);
           end;
        inc(i);
        if i = 100 then j:=11;
    end;

zobrazujem.caption:='Zobrazujem: Top 10 najpredavánejších produktov';
aktualna_proc:=2;

end;

procedure TForm1.poT10Click(Sender: TObject);
var i,j:integer;
begin
gridus.rowcount:=11;
j:=10;
for i:=1 to 10 do begin
    gridus.cells[0,i]:=IntToStr(j)+'.';
    inc(j,-1);
end;
i:=top_length;
j:=10;
           while i > 0 do begin
                 if not ((topp[i].naklad = 0) AND (topp[i].prijmy = 0)) then begin
                    //memo1.append(inttostr(j)+'.  '+topp[i].meno+' má aktualne prijmy: '+IntToStr(topp[i].prijmy)+' má naklady '+IntToStr(topp[i].naklad)+' s celkovym ziskom: '+IntToStr(topp[i].zisk));
                    gridus.Cells[1,j]:=topp[i].meno;
                     gridus.Cells[2,j]:=IntToStr(topp[i].prijmy)+'€';
                     gridus.Cells[3,j]:=IntToStr(topp[i].naklad)+'€';
                      gridus.Cells[4,j]:=IntToStr(topp[i].zisk)+'€';

                   inc(j,-1);

                 end;
                 inc(i,-1)
           end;

zobrazujem.caption:='Zobrazujem: Top 10 najmenej predávaných produktov';
aktualna_proc:=3;
end;

procedure TForm1.ReloadClick(Sender: TObject);
begin
zobrazujem.caption:='';
case aktualna_proc of
     1:DefaultView;
     2:Top10.click;
     3:poT10.click;
     end;
  nacitanie;
end;

procedure TForm1.nacitanie;
var subor:textfile;
    pom_s,meno:string;                   //pomocna pri nacitani
    i,j,dlzka,kod:integer;
    F:longint;                           //potrebuje to funkcia filedelete()
    dokoncenenacitanie:boolean;
begin
loadingimage.Visible:=true;
loadingg.enabled:=true; //loading ikona

dokoncenenacitanie:=false;


{STATISTIKY}

while not dokoncenenacitanie do begin
   if not FileExists(PATH+'STATISTIKY_LOCK.txt') then begin
     F:=FileCreate(PATH+'STATISTIKY_LOCK.txt'); //zmakne databazu
     Assignfile(subor,PATH+'STATISTIKY.txt');
     Reset(subor);
     Readln(subor,pom_s);
     stats_length:=strtoint(pom_s);

     for i:=1 to stats_length do begin
           ReadLn(subor,pom_s); //N;12345678;111;12;100;991231   -priklad


           stats[i].typ:=Copy                             (pom_s,1,1); //vždy len jeden znak
           Delete                                         (pom_s,1,1+1);

           stats[i].id:=StrToInt(Copy                     (pom_s,1,8)); //vždy 8 znakov
           Delete                                         (pom_s,1,8+1);

           stats[i].kod:=StrToInt(Copy                    (pom_s,1,3)); //vždy len tri znaky
           Delete                                         (pom_s,1,3+1);

           stats[i].mnozstvo:=StrToInt(Copy               (pom_s,1,Pos(';',pom_s)-1));
           Delete                                         (pom_s,1,Pos(';',pom_s));

           stats[i].cena:=StrToInt(Copy                   (pom_s,1,Pos(';',pom_s)-1));
           Delete                                         (pom_s,1,Pos(';',pom_s));

           stats[i].datum:=StrToInt(Copy                  (pom_s,1,Length(pom_s)));
           end;
     CloseFile(subor);
     FileClose(F);
     DeleteFile(PATH+'STATISTIKY_LOCK.txt');
     dokoncenenacitanie:=true;
   end;
end; //KONIEC načítania statistik


dokoncenenacitanie:=false;
{TOVAR to TOPP}

while not dokoncenenacitanie do begin
   if not FileExists(PATH+'TOVAR_LOCK.txt') then begin
     Assignfile(subor,PATH+'TOVAR.txt'); //ZACIATOK nacitania tovar (meno)
     F:=FileCreate(PATH+'TOVAR_LOCK.txt'); //zamkne tovar
     Reset(subor);
     Readln(subor,pom_s);
     dlzka:=strtoint(pom_s); //zisti velkost tovar.txt
     top_length:=dlzka;      //da tu hodnotu aj do arraju top
     for i:=1 to dlzka do begin
           ReadLn(subor,pom_s); //nacita prvy riadok do pomocnych kod a meno
           kod:=StrtoInt(Copy(pom_s,1,3));
           Delete(pom_s,1,4);
           meno:=Copy(pom_s,1,Length(pom_s));
           for j:=1 to stats_length do begin    //prehlada pole stats a prida meno ku kodu
                    if (kod = stats[i].kod) then stats[i].meno:=meno;
                 end;


           topp[i].meno:=meno;
           topp[i].kod:=kod;

           end; //KONIEC načítania statistik
     CloseFile(subor);
     FileClose(F);
     DeleteFile(PATH+'TOVAR_LOCK.txt');
     dokoncenenacitanie:=true;
   end;
end;



dokoncenenacitanie:=false;
  {KATEGORIE}

while not dokoncenenacitanie do begin
   if not FileExists(PATH+'KATEGORIE_LOCK.txt') then begin
     AssignFile(subor,PATH+'KATEGORIE.txt'); //Nacitanie KATEGORIE
     F:=FileCreate(PATH+'KATEGORIE_LOCK.txt');
     Reset(subor);

     ReadLn(subor,pom_s);
     filter1.caption:=pom_s; //Filter 1
     ReadLn(subor,pom_s);
     filter2.caption:=pom_s; //Filter 2
     ReadLn(subor,pom_s);
     filter3.caption:=pom_s; //Filter 3
     ReadLn(subor,pom_s);
     filter4.caption:=pom_s; //Filter 4

     CloseFile(subor);
     FileClose(F);
     DeleteFile(PATH+'KATEGORIE_LOCK.txt');
     dokoncenenacitanie:=true;
   end;
end;

dokoncenenacitanie:=false;
  {TOVAR}

while not dokoncenenacitanie do begin
   if not FileExists(PATH+'TOVAR_LOCK.txt') then begin
     AssignFile(subor,PATH+'TOVAR.txt'); //Nacitanie KATEGORIE
     F:=FileCreate(PATH+'TOVAR_LOCK.txt');
     Reset(subor);
     Readln(subor,pom_s);
     dlzka:=StrTOInt(pom_s);
     for i:=1 to dlzka do begin
        ReadLn(subor,pom_s);
        ptovar[i].kod:=StrToInt(Copy   (pom_s,1,3));
        Delete                         (pom_s,1,4);
        ptovar[i].meno:=Copy           (pom_s,1,Length(pom_s));
     end;
     ptovar_length:=dlzka;

     CloseFile(subor);
     FileClose(F);
     DeleteFile(PATH+'TOVAR_LOCK.txt');
     dokoncenenacitanie:=true;
   end;
end;
sort;
end;

procedure TForm1.sort;
var i,j,temp_kod,temp_prijmy,temp_naklad,temp_zisk:integer;
    temp_meno:string;
begin
top;
//Bubble sortik z netu (prosim funguj)
  For i:=1 to top_length do topp[i].zisk:=(topp[i].prijmy-topp[i].naklad); //spraví zisk pre každy tovar

  For i := top_length-1 DownTo 1 do
  		For j := 2 to i do
  			If (topp[j-1].zisk < topp[j].zisk) Then
  			Begin
                                temp_kod   := topp[j-1].kod;
                                temp_prijmy:= topp[j-1].prijmy;
                                temp_naklad:= topp[j-1].naklad;
                                temp_zisk  := topp[j-1].zisk;
                                temp_meno  := topp[j-1].meno;

  				topp[j-1].kod   := topp[j].kod;
                                topp[j-1].prijmy:= topp[j].prijmy;
                                topp[j-1].naklad:= topp[j].naklad;
                                topp[j-1].zisk  := topp[j].zisk;
                                topp[j-1].meno  := topp[j].meno;



  				topp[j].kod     := temp_kod;
                                topp[j].prijmy  := temp_prijmy;
                                topp[j].naklad  := temp_naklad;
                                topp[j].zisk    := temp_zisk;
                                topp[j].meno    := temp_meno;


  			End;


end;

procedure TForm1.top; {Pridava celkove naklady a celkove prijmy do top[i]}
var i,j:integer;
    naklady_p,trzby_p,zisk_p,priemerna_cena,priemerna_kvantita:integer;
    suma_nakupov,pocet_nakupov,id_nakupu,pocet_v_nakupe:integer;
    priemer_predaj, priemer_kvantita:currency;
begin
FILTROVANIE;
for i:=1 to top_length do begin   //vynulovanie topp
   topp[i].prijmy:=0;
   topp[i].naklad:=0;
   topp[i].zisk:=0;
   end;



  for i:=1 to stats_filter_length do begin
     for j:=1 to top_length do begin
        if stats_filter[i].typ = 'N' then
        begin
          if (stats_filter[i].kod = topp[j].kod) then begin
             topp[j].naklad:=stats_filter[i].mnozstvo*stats_filter[i].cena;
          end;

        end;

        if stats_filter[i].typ = 'P' then
           begin
          if (stats_filter[i].kod = topp[j].kod) then begin
             topp[j].prijmy:=stats_filter[i].mnozstvo*stats_filter[i].cena;
           end;
        end;
     end;
  end;


  //Dava celkove naklady a nakup a zisk
  naklady_p:=0;trzby_p:=0;zisk_p:=0;priemerna_cena:=0;priemerna_kvantita:=0; //inicializacia premennych
  for i:=1 to top_length do begin
     naklady_p:=naklady_p+topp[i].naklad;
     trzby_p:=trzby_p+topp[i].prijmy;

  end;
     trzby.caption:=         'Tržby: '+InttoStr(trzby_p)+'€';
     naklady.caption:=       'Náklady: '+IntToStr(naklady_p)+'€';

     if ((trzby_p-naklady_p) > 0) then
     zisk.font.color:=clgreen else if ((trzby_p-naklady_p) = 0) then
     zisk.font.color:=clDefault else zisk.font.color:=clred;
     zisk.caption:=          'Zisk: '+IntToStr(trzby_p-naklady_p)+'€';



  //Priemer
  suma_nakupov:=0;
  pocet_nakupov:=0;
  priemer_predaj:=0;
  priemer_kvantita:=0;
  pocet_v_nakupe:=0;
  for i:=1 to stats_filter_length do begin //Priemer celkovy
     if stats_filter[i].typ = 'P' then begin
       suma_nakupov:=suma_nakupov+stats_filter[i].cena*stats_filter[i].mnozstvo;
       inc(pocet_nakupov);
     end;
  end;
  if not (pocet_nakupov = 0) then priemer_predaj:=suma_nakupov / pocet_nakupov else priemer_predaj:=0;
  priemercena.caption:='Priemerna cena nakupu: '+FloattoStrF(priemer_predaj, ffGeneral, 3, 2)+'€';


  id_nakupu:=0;
  pocet_nakupov:=0;
  for i:=1 to stats_filter_length do begin
     if stats_filter[i].typ = 'P' then begin

        if not (id_nakupu = stats_filter[i].id) then begin
          inc(pocet_nakupov);
          id_nakupu:=stats_filter[i].id;
          for j:=1 to stats_filter_length do begin
             if (id_nakupu = stats_filter[j].id) then begin
                inc(pocet_v_nakupe);
             end;
          end;
        end;


     end;
  end;
    if not (pocet_nakupov = 0) then priemer_kvantita:=pocet_v_nakupe / pocet_nakupov else priemer_kvantita:=0;
    priemerkvantita.caption:='Priemerna kvantita nakupu: '+FloatToStrF(priemer_kvantita, ffGeneral, 3, 2);


 //Reloadne zobrazene vec
 zobrazujem.caption:='';
case aktualna_proc of
     1:DefaultView;
     2:Top10.click;
     3:poT10.click;
     end;

{
 loadingimage.Visible:=false;
 loadingg.enabled:=false; //loading ikona
}
end;

procedure TForm1.Vytvaranie_TOP;
var subor:textfile;
    verzia:integer;
    pom_s:string;
    topp_local:array[1..1000] of nazvy_top;
    topp_local_length:integer;
    i,j,temp_kod,temp_prijmy,temp_naklad,temp_zisk:integer;
    temp_meno:string;
begin
//VYTVARANIE LOCAL TOP
for i:=1 to ptovar_length do begin
    topp_local[i].meno:=ptovar[i].meno;
    topp_local[i].kod:= ptovar[i].kod;
   end;
topp_local_length:=ptovar_length;

//naplni LOCAL TOP
for i:=1 to stats_length do begin
   for j:=1 to topp_local_length do begin
      if stats[i].typ = 'N' then
      begin
        if (stats[i].kod = topp[j].kod) then begin
           topp[j].naklad:=stats[i].mnozstvo*stats[i].cena;
        end;

      end;

      if stats[i].typ = 'P' then
         begin
        if (stats[i].kod = topp[j].kod) then begin
           topp[j].prijmy:=stats[i].mnozstvo*stats[i].cena;
         end;
      end;
   end;
end;

//SORTOVANIe LOKALNE  (viem, ale je to narychlo)
For i:=1 to topp_local_length do topp_local[i].zisk:=(topp_local[i].prijmy-topp_local[i].naklad); //spraví zisk pre každy tovar

For i := topp_local_length-1 DownTo 1 do
		For j := 2 to i do
			If (topp[j-1].zisk < topp[j].zisk) Then
			Begin
                              temp_kod   := topp_local[j-1].kod;
                              temp_prijmy:= topp_local[j-1].prijmy;
                              temp_naklad:= topp_local[j-1].naklad;
                              temp_zisk  := topp_local[j-1].zisk;
                              temp_meno  := topp_local[j-1].meno;

			      topp_local[j-1].kod   := topp_local[j].kod;
                              topp_local[j-1].prijmy:= topp_local[j].prijmy;
                              topp_local[j-1].naklad:= topp_local[j].naklad;
                              topp_local[j-1].zisk  := topp_local[j].zisk;
                              topp_local[j-1].meno  := topp_local[j].meno;



			      topp_local[j].kod     := temp_kod;
                              topp_local[j].prijmy  := temp_prijmy;
                              topp_local[j].naklad  := temp_naklad;
                              topp_local[j].zisk    := temp_zisk;
                              topp_local[j].meno    := temp_meno;


			End;



//ZAPISOVANIE
if topp_local_length > 5 then begin
  AssignFile(subor,'TOP.txt');
  Rewrite(subor);
  For i:=1 to 5 do begin
      WriteLn(subor,IntToStr(topp_local[i].kod));
  end;
  CloseFile(subor);

  AssignFile(subor,'TOP_VERZIA.txt');
  Reset(subor);
  ReadLn(subor,pom_s);
  verzia:=StrToInt(pom_s);
  Inc(verzia);
  CloseFile(subor);
  Rewrite(subor);
  WriteLn(subor,IntToStr(verzia));
  CloseFile(subor);



end;
end;

procedure TForm1.filtrovanie;
var

OddatumP,PoDatumP,pom_string,rok,mesiac,den:string;
filterP:integer;
filterB:boolean;
i,j:integer;
//debugVypis: TStringList;
//aktCas: TDateTime;
begin
{
 inc(debugCount);

 //Set my date variable using the EncodeDateTime function
 aktCas := EncodeDateTime(2000, 02, 29, 12, 34, 56, 789);
 //LongTimeFormat := 'hh:mm:ss.z';  // Ensure that MSecs are
 debugVypis:= TStringList.Create;
 debugVypis.LoadFromFile('DEBUG.txt');
 debugVypis.Add(DateToStr(aktCas) +'  '+ intToStr(debugCount));
 debugVypis.SaveToFile('DEBUG.txt');
 debugVypis.Free;
}

pom_string:=DateTimeToStr(Oddatum.date); //31.12.1099
den:=copy(pom_string,1,(pos('.',pom_string)-1));
Delete(pom_string,1,pos('.',pom_string));
mesiac:=copy(pom_string,2,pos('.',pom_string)-1-1);
Delete(pom_string,1,pos('.',pom_string));
rok:=Copy(pom_string,4,2);


if StrToInt(den) < 10 then den:='0'+den;
if StrToInt(mesiac) < 10 then mesiac:='0'+mesiac;
if StrToInt(rok) < 10 then rok:='0'+rok;
OddatumP:=rok+mesiac+den;

pom_string:=DateTimeToStr(Podatum.date);
den:=copy(pom_string,1,pos('.',pom_string)-1);
Delete(pom_string,1,pos('.',pom_string));
mesiac:=copy(pom_string,2,pos('.',pom_string)-1-1);
Delete(pom_string,1,pos('.',pom_string));
rok:=Copy(pom_string,4,2);

if StrToInt(den) < 10 then den:='0'+den;
if StrToInt(mesiac) < 10 then mesiac:='0'+mesiac;
if StrToInt(rok) < 10 then rok:='0'+rok;
PodatumP:=rok+mesiac+den;

j:=1;
for i:=1 to stats_length do begin
if stats[i].kod >= 400 then filterP:=4 else if stats[i].kod >= 300 then filterP:=3 else if stats[i].kod >= 200 then filterP:=2 else FilterP:=1;
case filterP of
     4:filterB:=filter4.Checked;
     3:filterB:=filter3.Checked;
     2:filterB:=filter2.Checked;
     1:filterB:=filter1.Checked;
     end;

if (((StrToint(OddatumP) < stats[i].datum) AND (stats[i].datum < StrToInt(PodatumP))) AND (filterB)) then begin
     stats_filter[j].typ:=     stats[i].typ;
     stats_filter[j].id:=      stats[i].id;
     stats_filter[j].kod:=     stats[i].kod;
     stats_filter[j].mnozstvo:=stats[i].mnozstvo;
     stats_filter[j].cena:=    stats[i].cena;
     stats_filter[j].meno:=    stats[i].meno;
     stats_filter[j].datum:=   stats[i].datum;
     inc(j);
end;
end;
stats_filter_length:=j-1;
end;

procedure Tform1.spravmigraf;
var odsadenie,x1,x2,y1,y2,i:integer;
begin
image1.canvas.Brush.color:=clwhite;
image1.Canvas.fillrect(clientRect);
ODSADENIE:=20;

//vytvorenie asymptot
image1.canvas.Line(0+odsadenie,0,0+odsadenie,500-odsadenie);
image1.canvas.Line(0+odsadenie,500-odsadenie,500,500-odsadenie);
//end


x1:=odsadenie-5;
y1:=0;
x2:=odsadenie+5;
y2:=0;
      for i:=1 to 48 do begin
      inc(y1,10);
      inc(y2,10);
      image1.canvas.Line(x1,y1,x2,y2);
      end;




end;

procedure TForm1.cislujmi(pocet:integer);
var i,j:integer;
begin
pocet:=pocet-1;
for i:=1 to pocet do begin
    gridus.cells[0,i]:=IntToStr(i)+'.';
end;
//Čistenie dát
for i:=1 to 4 do begin
    for j:=1 to pocet do begin
        gridus.cells[i,j]:='';
    end;
   end;

end;

end.

