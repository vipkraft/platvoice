unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ZConnection, ZDataset, LazFileUtils,
  Forms, Controls, Graphics, Dialogs,
  ExtCtrls,
  StdCtrls,
    //ComCtrls,
  platproc,
  lazdynamic_bass,
  //lclproc,
  IniPropStorage,
  version_info,
//  CommonTypes,
  dateutils,
  voiceproc;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    IdleTimer1: TIdleTimer;
    Image1: TImage;
    IniPropStorage1: TIniPropStorage;
    Label1: TLabel;
    Label10: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Memo1: TMemo;
    Shape1: TShape;
    clock: TTimer;
    Shape2: TShape;
    Shape3: TShape;
    zapros: TTimer;
    ZConnection1: TZConnection;
    ZQuery1: TZQuery;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure CheckBox2Change(Sender: TObject);
    procedure clockTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Label4Click(Sender: TObject);
    procedure zaprosTimer(Sender: TObject);
    procedure test_sound();
    //прочитать глобальные переменные
    procedure ReadSettings();

  private
    { private declarations }
  public
    { public declarations }
  end;

const
  dirname = 'voice_log';

var
           Form1:TForm1;
         defpath:string;
  timeout_global:integer=0;  //счетчик таймер бездействия (перед окном закрытия форм операций)
   timeout_local:integer=0;
            Info:string='';
         flclose:boolean=true; //закрывать формы
  flagProfile, flag_access, flag1 :byte;
  stream: Hstream;  // Музыкальный поток
   MajorNum : String;
   MinorNum : String;
   RevisionNum : String;
   BuildNum : String;
   log_flag : boolean=false;


implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.ReadSettings();
var
  //Ini: TIniFile;
  i: Integer;
  fset: string;
begin
  fset:=IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName))+'settings.ini';
  if not FileExists(fset) then
    begin
     exit;
    end;
   form1.IniPropStorage1.inifilename:=fset;
   form1.IniPropStorage1.IniSection:='voice'; //указываем секцию
   log_flag:=form1.IniPropStorage1.ReadBoolean('writelog',false);
   form1.IniPropStorage1.FreeStorage;
  //Ini := TIniFile.Create(fset);
  //try
    //log_flag := Ini.ReadString('voice','writelog', 'no');
  //finally
    //Ini.Free;
  //end;
   form1.CheckBox2.Checked:=log_flag;
end;


procedure TForm1.test_sound();
var
 fset: string;
begin
  fset := ExtractFilePath(Application.ExeName)+'/sound/predv/sound1.mp3';
  If not FileExists(fset) then
    write_log('!!! NOT Exist file: '+fset)
  else
    write_log('start TEST SOUND');
   stream:= bass_streamCreateFile(false,Pchar(fset), 0, 0, 0);
  bass_channelplay(stream,false);
    repeat
      sleep(20);
      application.ProcessMessages;
    until BASS_ChannelIsActive(stream)=0;
  bass_streamfree(stream);
end;


procedure TForm1.FormCreate(Sender: TObject);
var
   logname,sss:string;
   Info: TVersionInfo;
   n:integer;
begin
   Info := TVersionInfo.Create;
   Info.Load(HINSTANCE);
   // grab just the Build Number
   MajorNum := IntToStr(Info.FixedInfo.FileVersion[0]);
   MinorNum := IntToStr(Info.FixedInfo.FileVersion[1]);
   RevisionNum := IntToStr(Info.FixedInfo.FileVersion[2]);
   BuildNum := IntToStr(Info.FixedInfo.FileVersion[3]);
   Info.Free;

  log_flag:=true;
   write_log('+Version: '+MajorNum+'.'+MinorNum+'.'+RevisionNum+'.'+BuildNum);
  log_flag:=false;

   //
    // ================= Считываем данные из файла локальных настроек ==================================
  flagProfile:=2;
  defpath:=ExtractFilePath(Application.ExeName);

  if ReadIniLocal(form1.IniPropStorage1,defpath+'local.ini')=false then
   begin
     write_log('Не найден файл настроек по заданному пути!'+#13+'Дальнейшая загрузка программы невозможна ! --m01--');
     halt;
   end;

  form1.Label10.Caption:='База Данных IP:  ' + connectINI[4];

  //прочитать глобальные переменные
   ReadSettings();

    //ConnectINI[4]:='172.27.1.5';
    //ConnectINI[5]:='5432';
    //ConnectINI[6]:='platforma_stav_av';

  //  sss:='';
  //for n:=low(connectINI) to high(connectINI) do
  //   begin
  //     sss:=sss+connectINI[n]+#13;
  //
  //   end;
   //showmessage(sss);
   //------------- Позиционируем форму на экране
  form1.Width:=1024;
  form1.Height:=768;
  //form1.Left:=(screen.Width div 2)-(form1.Width div 2);
  //form1.top:=(screen.Height div 2)-(form1.Height div 2);




  //-------------------- Инициализируем звуковой движок
  lazdynamic_bass.Load_BASSDLL(ExtractFilePath(Application.ExeName)+'libbass.so');
  if not(BASS_Init(-1, 41400, 0, Handle, nil)) then if not(BASS_Init(2, 41400, 0, Handle, nil)) then
     begin
      showmessage('Звуковой движок не обнаружен !!!');
      write_log('Звуковой движок не обнаружен !!! --m02--');
     end;

  form1.zapros.Enabled:=true;

end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  lazdynamic_bass.BASS_Free;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if key=27 then
    begin
      form1.Close;
      halt;
    end;

  //F1 Показывать сообщения
  if key=112 then
    begin
       key:=0;
    if form1.CheckBox1.Checked then
     form1.CheckBox1.Checked := false
    else
      form1.CheckBox1.Checked := true;
    end;
  //F2 Сохранить в файл
  if key=113 then
    begin
      key:=0;
      Memo1.Lines.SaveToFile(ExtractFilePath(Application.ExeName)+dirname+'/manual_'+FormatDateTime('yyyy-mm-dd_hhmm', now())+'.log');
      form1.memo1.Lines.Clear;
    end;
  //F3 вывести недостающие файлы
   if key=114 then
    form1.Button1.Click;
  //F5 очистка
  if key=116 then
    form1.memo1.Lines.Clear;

  //F9
  if key=120 then
  begin
    key:=0;
    if form1.CheckBox2.Checked then
     form1.CheckBox2.Checked := false
    else
      form1.CheckBox2.Checked := true;
  end;
  //F10
  if key=121 then
  begin
    key:=0;
    if form1.CheckBox3.Checked then
     form1.CheckBox3.Checked := false
    else
      form1.CheckBox3.Checked := true;
  end;
  //F12
  if key=123 then
  begin
    key:=0;
    form1.test_sound();
  end;
end;

//показать / записать массив объявлений
procedure TForm1.Label4Click(Sender: TObject);
var
  i0:integer;
begin
  i0 := 0;
  while length(mas_reklama)-1 >= i0 do
    begin
      write_log('R '+trim(mas_reklama[i0,0])+' 1: '+trim(mas_reklama[i0,1])+' 2: '+trim(mas_reklama[i0,2])+' 3: '+trim(mas_reklama[i0,3])+' 4: '+trim(mas_reklama[i0,4])+' 5: '+trim(mas_reklama[i0,5])+' 6: '+trim(mas_reklama[i0,6]));

      inc(i0);
    end;
  write_log('mas_reklama: ');
  showmas(mas_reklama);
end;


procedure TForm1.clockTimer(Sender: TObject);
 var
   sday:array[1..7] of string;
begin
  // Выводим текущее время и дату
  sday[1] := 'Понедельник';
  sday[2] := 'Вторник';
  sday[3] := 'Среда';
  sday[4] := 'Четверг';
  sday[5] := 'Пятница';
  sday[6] := 'Суббота';
  sday[7] := 'Воскресенье';
  form1.Label6.Caption:=sday[DayOfTheWeek(now())]+' '+FormatDateTime('dd.mm.yyyy hh:mm:ss', now());
  WORK_DATE:=now;
end;

procedure TForm1.Button1Click(Sender: TObject);    // Вычисляем недостающие звуки
var
  n:integer;
begin
  If not(Connect2(form1.ZConnection1, flagProfile)) then
  begin
    write_log('Соединение с сервером базы данных отсутствует ! --m04--');
    exit;
  end;

  form1.ZQuery1.SQL.Clear;
  form1.ZQuery1.SQL.add('select distinct b.kod_locality, trim(d.name) as name from av_shedule_sostav a, av_spr_point b, av_spr_locality d ');
  form1.ZQuery1.SQL.add('    where a.del=0 and b.del=0 and d.del=0 and a.id_point=b.id and b.kod_locality=d.id order by kod_locality;');
  try
    form1.ZQuery1.open;
  except
    write_log('--m05-- Выполнение команды SQL - ОШИБКА !'+#13+'Команда: '+form1.ZQuery1.SQL.Text);
    form1.ZQuery1.Close;
    form1.ZConnection1.disconnect;
    exit;
  end;
 write_log('Проверьте права доступа к файлам! (оптимальное 100444)');
 // Вычисляем файлы звука которых нет
  for n:=0 to form1.ZQuery1.RecordCount-1 do
    begin
      if not FileExists(ExtractFilePath(Application.ExeName)+'sound/point/'+PADL(trim(form1.ZQuery1.FieldByName('kod_locality').asString),'0',8)+'.mp3')
        then
           write_log('--m06--НЕ найден файл: '+ trim(form1.ZQuery1.FieldByName('kod_locality').asString)+' - '+trim(form1.ZQuery1.FieldByName('name').asString));
      form1.ZQuery1.Next;
    end;
  form1.ZQuery1.Close;
  form1.ZConnection1.disconnect;
end;

procedure TForm1.Button2Click(Sender: TObject);     // очистка
begin
  form1.memo1.Lines.Clear;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  Memo1.Lines.SaveToFile(ExtractFilePath(Application.ExeName)+dirname+'/manual_'+FormatDateTime('yyyy-mm-dd_hhmm', now())+'.log');
  form1.memo1.Lines.Clear;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  form1.close;
  halt;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  form1.test_sound();
end;


procedure TForm1.CheckBox2Change(Sender: TObject);
var
   lfile:string;
begin
  if form1.CheckBox2.Checked then
    log_flag:=true
  else
    log_flag:=false;

  lfile:=IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName))+'settings.ini';
  if not FileExists(lfile) then
    begin
      write_log('Не найден файл настроек! --m07--');
     //exit;
    end;
     form1.IniPropStorage1.inifilename:=lfile;
     form1.IniPropStorage1.IniSection:='voice'; //указываем секцию
     form1.IniPropStorage1.WriteBoolean('writelog',log_flag);
     form1.IniPropStorage1.FreeStorage;
end;

procedure TForm1.zaprosTimer(Sender: TObject);
begin
  //write_log('********************** START ITERATION ******************');
  form1.zapros.Enabled:=false;
  // Зажигаем активнсть
  form1.Shape1.Brush.Color:=clGreen;
  if tek_datetime='' then
    begin
     //write_log('get_time_date');//$
     If get_time_date(form1.ZConnection1, Form1.Zquery1) then
        begin
         prev_datetime:=tek_datetime;
        end;
    end;

  //---------------- Запрос новых заданий по рейсам ----------------//
  //write_log('get_new_event_rejs');

  if get_new_event_rejs(form1.ZConnection1, Form1.Zquery1)=true then
     begin
       form1.Shape2.Brush.Color:=clGreen;
       //write_log('1play_rejs_oper - start');
       //----------------------------------------- операции
       play_rejs_oper();//%разремарить
       //write_log('1play_rejs_oper - stop');
       form1.Shape2.Brush.Color:=clGray;
     end;

  //---------------- Запрос новых заданий по отправлению за 5n минут ----------------//
  //if to_nmin_rejs(form1.ZConnection1, Form1.Zquery1)=true then
  //   begin
  //     form1.zapros.Enabled:=false;
  //     // Зажигаем активнсть Операций над рейсами
  //     form1.Shape2.Brush.Color:=clGreen;
  //     application.ProcessMessages;
  //     //If get_time_date(form1.ZConnection1, Form1.Zquery1) then prev_datetime:=Tek_datetime;
  //     play_rejs_oper();
  //     form1.Shape2.Brush.Color:=clGray;
  //     form1.zapros.Enabled:=true;
  //   end;

  //---------------- Запрос новых заданий по отправлению за 15n минут (свободные места)----------------//
  //write_log('to_nmin_rejs_empty');
  if to_nmin_rejs_empty(form1.ZConnection1, Form1.Zquery1)=true then
     begin
       form1.Shape2.Brush.Color:=clGreen;
       //write_log('2play_rejs_oper-start');
       //----------------------------------------- операции
       play_rejs_oper();  //%разремарить
       //write_log('2play_rejs_oper-stop');
       form1.Shape2.Brush.Color:=clGray;
     end;

  //---------------- Запрос новых заданий по информационным сообщениям----------------//
  //write_log('get_reklama');
  if get_reklama(form1.ZConnection1, Form1.Zquery1)=true then
     begin
       form1.Shape2.Brush.Color:=clGreen;
       //write_log('3play_rejs_oper_reklama - start');
       //---------------------------------------- реклама
       play_rejs_oper_reklama();
       //write_log('3play_rejs_oper_reklama - stop');
       form1.Shape2.Brush.Color:=clGray;
     end;

  // Отключаем активность
  form1.Shape1.Brush.Color:=clGray;
  form1.Label8.Caption:=inttostr(strtoint(form1.Label8.Caption)+1);
  application.ProcessMessages;
  //write_log('********************** END ITERATION ******************');
  form1.zapros.Enabled:=true;
end;

end.

