unit voiceproc;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  ZConnection, ZDataset,
  dialogs,forms,
  lazdynamic_bass,
  CommonTypes,
  //lclproc,
  Controls,
  Graphics,
  DateUtils,
  LazFileUtils,
  //,fileutil,
  LazUtf8,
  platproc;

  //Новые задания по рейсам
  function get_new_event_rejs(ZCon:TZConnection; ZQ:TZquery):boolean;

  //Разбор для озвучивания рейсовых операций
  procedure play_rejs_oper;

  // Озвучивание рейсовых операций
  procedure play_rejs_sound(ind:integer);

  // Теущая дата и время сервера
  function get_time_date(ZCon:TZConnection; ZQ:TZquery):boolean;

  // Определяем состав рейса
  procedure sostav_rejs(ZCon:TZConnection; ZQ:TZquery;ind:integer);

  // Определяем сообщения за 5(n) минут до отправления открытого для продажи рейса
  function to_nmin_rejs(ZCon:TZConnection; ZQ:TZquery):boolean;

  // Пересчет динамичеких параметров для рейсов в массиве
  procedure Rascet_mas(ZCon:TZConnection; ZQ:TZquery;priznak:byte);

  // Очищаем блоки из full_mas по флагу 1-av_trip 2-av_trip_add full_mas[n,0];
  procedure clear_mas(flag_clear:byte);

  // Определяем сообщения за 15(n) минут до отправления открытого для продажи рейса (свободные места)
  function to_nmin_rejs_empty(ZCon:TZConnection; ZQ:TZquery):boolean;

  // Запрос на воспроизведение информационных сообщений
  function get_reklama(ZCon:TZConnection; ZQ:TZquery):boolean;

  // Текущее количество минут от начала суток
  function get_min():integer;
  // заложенное количество минут от начала суток - костыль
  function get_min_start_t(startt,mint:integer):integer;

  // Озвучивание информационных сообщений
  procedure play_rejs_sound_reklama(ind:integer);

  //Разбор для озвучивания информационных сообщений
  procedure play_rejs_oper_reklama;

  // Запись лога выполнения операций
  procedure write_log(str:string);

var
  old_fc:string=''; //для подавления одинаковых населенных пунктов (АВ и АС в одном населенном пункте, костыль в ошибку)
  prev_datetime:string='';
   tek_datetime:string='';
       full_mas:array of array of string; // массив всех текущий online состояний всех рейсов
  full_mas_size:integer=47; // Размерность массива
    md5_av_trip:string='';  // md5 для av_trip
md5_av_trip_add:string='';  // md5 для av_trip_add
  md5_operation:string='';
  dispcnt,shcnt:integer;
      WORK_DATE:TDatetime;
      back_time:string=''; //предыдущее время объявления до отправления за 5n минут
      back_time_empty:string=''; //предыдущее время объявления до отправления за 15n минут

   //^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^  FULL_MAS - описание ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
            // [n,0]  - Тип данных в массиве 1: из av_trip (регулярный) 2: из av_trip_add (заказной)
            // [n,1]  - id_shedule
            // [n,2]  - plat         //платформа
            // [n,3]  - ot_id_point
            // [n,4]  - ot_order
            // [n,5]  - ot_name
            // [n,6]  - do_id_point
            // [n,7]  - do_order
            // [n,8]  - do_name
            // [n,9]  - form         //признак формирующего
            // [n,10] - t_o
            // [n,11] - t_s
            // [n,12] - t_p
            // [n,13] - zakaz        //признак заказного
            // [n,14] - date_tarif
            // [n,15] - id_route
            // [n,16] - napr        //1:отправление, 2:прибытие
            // [n,17] - wihod       //1:выход в рейс в текущий workdate
            // [n,18] - id_kontr
            // [n,19] - name_kontr
            // [n,20] - id_ats
            // [n,21] - name_ats
            // [n,22] - active
            // [n,23] - dates
            // [n,24] - datepo
            // [n,25] - all_mest
            // [n,26] - activen
            // [n,27] - type_ats
            // [n,28] - trip_flag   //состояние рейса
            // [n,29] - doobil
            // [n,30] - oper_date   //дата операции
            // [n,31] - oper_time   //время операции
            // [n,32] - oper_user   //пользователь совершивший операцию
            // [n,33] - oper_remark //описание операции
            // [n,34] - kol_swob //кол-во свободных мест
             //[n,35] putevka
             //[n,36] driver1
             //[n,37] driver2').asString);
             //[n,38] driver3').asString);
             //[n,39] driver4').asString);
            // [n,40] - dateactive //дата начала работы расписания
            // [n,41] - dog_flag //флаг наличия договора
            // [n,42] - lic_flag //флаг наличия лицензии
            // [n,43] - kontr_flag //флаг наличия перевозчика
            // [n,44] - ats_flag //флаг наличия автобуса
            // [n,45] - ot_id_locality
            // [n,46] - do_id_locality

  popytki:integer=0;
  // Массив данных для озвучивания операций над рейсами в момент установки операций диспетчером
  mas_sound_rejs:array of array of string;
  //  mas_sound_rejs[n,0] id_shedule
  //  mas_sound_rejs[n,1] trip_time
  //  mas_sound_rejs[n,2] platforma
  //  mas_sound_rejs[n,3] ot_id_point
  //  mas_sound_rejs[n,4] do_id_point
  //  mas_sound_rejs[n,5] trip_flag
  //  mas_sound_rejs[n,6] ot_id_locality
  //  mas_sound_rejs[n,7] do_id_locality
  //  mas_sound_rejs[n,8] ot_order
  //  mas_sound_rejs[n,9] do_order
  // mas_sound_rejs[n,10] ot_name
  // mas_sound_rejs[n,11] do_name
  // mas_sound_rejs[n,12] createdate
  // mas_sound_rejs[n,13] createdate1

  // Массив состава рейса
  mas_rejs_sostav:array of string;
  // mas_rejs_sostav[n] - id_point

   mas_reklama:array of array of string;
  // mas_reklama[n,0] - id
  // mas_reklama[n,1] - level
  // mas_reklama[n,2] - file
  // mas_reklama[n,3] - remark
  // mas_reklama[n,4] - interval
  // mas_reklama[n,5] - status
  // mas_reklama[n,6] - tek time
     last_late_time:TDateTime= 25569.0; // 01/01/1970 //метка о последней объявлении опаздывающим пассажирам



implementation
uses
  main;

// Запись лога выполнения операций
procedure write_log(str:string);
 var
  filelog:TextFile;
  namelog:string='';
  log_file: textfile;
begin
  If (trim(str)='') then exit;

  if form1.CheckBox1.Checked then
               form1.Memo1.Lines.Add(str);
  //если не писать лог - выход
  if not log_flag then exit;

  namelog:=ExtractFilePath(Application.ExeName)+dirname+'/voice_'+FormatDateTime('yy-mm-dd', now())+'.log';
  // --------Проверяем что уже есть каталог LOG если нет то создаем
  If Not DirectoryExistsUTF8(ExtractFilePath(Application.ExeName)+dirname) then
    begin
     CreateDir(ExtractFilePath(Application.ExeName)+dirname);
    end;
  //--------- Создаем log: ..log/log_01.01.2012.log
  //if fileexistsUTF8(namelog) then
   //begin
    //fileutil.RenameFileUTF8(namelog, ExtractFilePath(Application.ExeName)+'log/'+FormatDateTime('yy-mm-dd_hh_nn', now())+'.log');
   //end;
  try
  {$I-} // отключение контроля ошибок ввода-вывода
   AssignFile(log_file,namelog);
   if fileexistsUTF8(namelog) then
       Append(log_file) else
       Rewrite(log_file); // открытие файла для записи
  {$I+} // включение контроля ошибок ввода-вывода
  if IOResult<>0 then // если есть ошибка открытия, то
   begin
     Exit;
   end;
  // id_user+datetime
     //writeln(log_file,'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
   //writeln(log_file,user_ip+'; ['+(inttostr(id_user))+'] '+name_user_active+'; '+FormatDateTime('dd/mm/yyyy hh:mm:ss', now()));
     writeln(log_file,FormatDateTime('yyyy-mm-dd.hh:mm:ss', now())+' | '+trim(str));
  finally
   // --------- Закрываем текстовый файл
     CloseFile(log_file);
  end;
end;

// Озвучивание информационных сообщений
procedure play_rejs_sound_reklama(ind:integer);
var
  fc:string='';
begin
  fc:=mas_reklama[ind,2];
  if not FileExists(fc) then
   begin
    write_log('--v01-- нет файла рекламы: '+fc);
    exit;
   end;
  write_log('--v02-- воспр реклама: '+fc);

  form1.Label9.font.Color:=clRED;
  form1.Label9.Caption:='СОСТОЯНИЕ: ГОВОРЮ';
  form1.Label4.Caption:='ОБЪЯВЛЕНИЕ: '+fc;
  application.ProcessMessages;
  if stream<>0 then bass_StreamFree(stream);

  // Открываем проигрываемый файл
  stream := bass_streamCreateFile(false,Pchar(trim(fc)), 0, 0, 0);
  // Начать проигрывание
  bass_channelplay(stream,false);
  repeat
    sleep(10);
  until BASS_ChannelIsActive(stream)=0;
  form1.Label9.font.Color:=clBlack;
  form1.Label9.Caption:='СОСТОЯНИЕ: МОЛЧУ';
  application.ProcessMessages;
end;


// Запрос на воспроизведение информационных сообщений
function get_reklama(ZCon:TZConnection; ZQ:TZquery):boolean;
 var
    n,m:integer;
    sweek, sweekR :string;
    sweekJ : Boolean;
begin
    // -------------------- Соединяемся с локальным сервером ----------------------
 If not(Connect2(Zcon, flagProfile)) then
  begin
   write_log('Соединение с сервером базы данных отсутствует ! --v003--');
   result:=false;
   exit;
  end;

  form1.Label3.Caption:='Активность данных: '+trim(prev_datetime);
 // Забираем новые и нформационные сообщения
ZQ.SQL.Clear;
ZQ.sql.add('SET statement_timeout = 2000'); // two second
try
     ZQ.open;
 except
       ZQ.Close;
       Zcon.disconnect;
       Result:=false;
       exit;
 end;

ZQ.SQL.Clear;
ZQ.sql.add('SELECT EXTRACT(DOW FROM now()) as todaydayofweek, id, message, message_file, min_t, regular, day_of_week, start_t');
ZQ.sql.add('FROM av_sound_reklama where standby=1 and del=0 and start_d<='+quotedstr(FormatDateTime('dd.mm.yyyy', now()))+' and end_d>'+quotedstr(FormatDateTime('dd.mm.yyyy', now())));
//showmessage(ZQ.SQL.text);//$
try
     ZQ.open;
 except
       ZQ.Close;
       Zcon.disconnect;
       Result:=false;
       exit;
 end;
 If Zq.RecordCount=0 then
   begin
      ZQ.Close;
      Zcon.disconnect;
      Result:=false;
      exit;
   end;

  // Обновляем массив
  // mas_reklama[n,0] - id
  // mas_reklama[n,1] - level
  // mas_reklama[n,2] - file
  // mas_reklama[n,3] - remark
  // mas_reklama[n,4] - interval
  // mas_reklama[n,5] - status
  // mas_reklama[n,6] - tek time
  if length(mas_reklama)=0 then
    begin
      sweek := FormatDateTime('ddd', now());
      for n:=0 to Zq.RecordCount-1 do
        begin
          SetLength(mas_reklama,length(mas_reklama)+1,7);
          if zq.FieldByName('regular').AsString='1' then
            begin
              mas_reklama[length(mas_reklama)-1,0]:=zq.FieldByName('id').AsString;
              mas_reklama[length(mas_reklama)-1,1]:=inttostr(strtoint(zq.FieldByName('id').AsString)+1);
              mas_reklama[length(mas_reklama)-1,2]:=zq.FieldByName('message_file').AsString;
              mas_reklama[length(mas_reklama)-1,3]:=zq.FieldByName('message').AsString;
              mas_reklama[length(mas_reklama)-1,4]:=zq.FieldByName('min_t').AsString;
              mas_reklama[length(mas_reklama)-1,5]:='1';
              if zq.FieldByName('start_t').AsString='0' then mas_reklama[length(mas_reklama)-1,6]:=inttostr(get_min()) else
                begin
                  mas_reklama[length(mas_reklama)-1,6]:=inttostr(get_min_start_t(strtoint(zq.FieldByName('start_t').AsString),strtoint(zq.FieldByName('min_t').AsString)));
//                  form1.memo1.Lines.Add('!!!: '+inttostr(get_min_start_t(strtoint(zq.FieldByName('start_t').AsString),strtoint(zq.FieldByName('min_t').AsString))));
                end;
            end
          else
            begin
              sweekR := zq.FieldByName('day_of_week').AsString;
              sweekJ := false;
              //case sweek of
               //'Mon': if sweekR[1]='1' then sweekJ:=true;
               // 'Tue': if sweekR[2]='1' then sweekJ:=true;
               // 'Wed': if sweekR[3]='1' then sweekJ:=true;
               // 'Thu': if sweekR[4]='1' then sweekJ:=true;
               // 'Fri': if sweekR[5]='1' then sweekJ:=true;
               // 'Sat': if sweekR[6]='1' then sweekJ:=true;
               // 'Sun': if sweekR[7]='1' then sweekJ:=true;
              case zq.FieldByName('todaydayofweek').AsInteger of
                1: if sweekR[1]='1' then sweekJ:=true;
                2: if sweekR[2]='1' then sweekJ:=true;
                3: if sweekR[3]='1' then sweekJ:=true;
                4: if sweekR[4]='1' then sweekJ:=true;
                5: if sweekR[5]='1' then sweekJ:=true;
                6: if sweekR[6]='1' then sweekJ:=true;
                0: if sweekR[7]='1' then sweekJ:=true;
              end;
            if sweekJ=true then
              begin
                mas_reklama[length(mas_reklama)-1,0]:=zq.FieldByName('id').AsString;
                mas_reklama[length(mas_reklama)-1,1]:=inttostr(strtoint(zq.FieldByName('id').AsString)+1);
                mas_reklama[length(mas_reklama)-1,2]:=zq.FieldByName('message_file').AsString;
                mas_reklama[length(mas_reklama)-1,3]:=zq.FieldByName('message').AsString;
                mas_reklama[length(mas_reklama)-1,4]:=zq.FieldByName('min_t').AsString;
                mas_reklama[length(mas_reklama)-1,5]:='1';
                if zq.FieldByName('start_t').AsString='00:00:00' then mas_reklama[length(mas_reklama)-1,6]:=inttostr(get_min()) else
                  begin
                    mas_reklama[length(mas_reklama)-1,6]:=inttostr(get_min_start_t(strtoint(zq.FieldByName('start_t').AsString),strtoint(zq.FieldByName('min_t').AsString)));
                  end;
              end;
           end;
          zq.Next;
        end;
    end;
  ZQ.Close;
  Zcon.disconnect;

  Result:=true;
end;

function get_min():integer; // Текущее количество минут от начала суток
 var
   myHour, myMin, mySec, myMilli : Word;
begin
   DecodeTime(now(), myHour, myMin, mySec, myMilli);
   Result:=(myHour*60)+ myMin;
end;

function get_min_start_t(startt, mint: integer): integer;
begin
  while (startt-mint)<=get_min() do
    begin
      startt := startt+mint;
    end;
  Result:=startt-mint-mint;
end;

// Определяем сообщения за 15(n) минут до отправления открытого для продажи рейса (свободные места)
function to_nmin_rejs_empty(ZCon:TZConnection; ZQ:TZquery):boolean;
 var
  ttt:string='';
  n:integer;
begin
  Result:=false;
 // Создаем массив доступных рейсов
  Rascet_mas(ZCon,ZQ,1);
  //write_log(inttostr(length(full_mas)));
  if length(full_mas)=0 then
    exit;


   // Вычисляем времы отправления - за 15 минут
   //DateTimeToString(ttt, 't', IncMinute(now(),15));
   //ttt:=copy(trim(ttt),1,5);
   ttt:=formatdatetime('hh:nn',IncMinute(now(),15));

   // Если время равно предыдущему то еще раз не объявлять
   if trim(back_time_empty)=trim(ttt) then
       exit;


   setlength(mas_sound_rejs,0);
   for n:=0 to length(full_mas)-1 do
     begin
      // Сканируем массив рейсов если они еще открыты и активны и время фактического отправления за 15 минут
      if (trim(full_mas[n,10])=trim(ttt)) then
        begin
          form1.Label5.Caption:='за 15 минут. t_o:'+trim(full_mas[n,10])+' / +15min: '+ttt;
           // Заполняем временный массив
           if (trim(full_mas[n,9])='1') and (((trim(full_mas[n,28])='0')) or (trim(full_mas[n,28])='1')) then
             begin
              SetLength(mas_sound_rejs,length(mas_sound_rejs)+1,16);
              mas_sound_rejs[length(mas_sound_rejs)-1,0]:=trim(full_mas[n,1]);
              mas_sound_rejs[length(mas_sound_rejs)-1,1]:=trim(full_mas[n,10]);
              mas_sound_rejs[length(mas_sound_rejs)-1,2]:='';
              mas_sound_rejs[length(mas_sound_rejs)-1,3]:=trim(full_mas[n,3]);
              mas_sound_rejs[length(mas_sound_rejs)-1,4]:=trim(full_mas[n,6]);
              mas_sound_rejs[length(mas_sound_rejs)-1,5]:='99';
              mas_sound_rejs[length(mas_sound_rejs)-1,6]:=trim(full_mas[n,45]);
              mas_sound_rejs[length(mas_sound_rejs)-1,7]:=trim(full_mas[n,46]);
              mas_sound_rejs[length(mas_sound_rejs)-1,8]:=trim(full_mas[n,4]);
              mas_sound_rejs[length(mas_sound_rejs)-1,9]:=trim(full_mas[n,7]);
              mas_sound_rejs[length(mas_sound_rejs)-1,10]:=trim(full_mas[n,5]);
              mas_sound_rejs[length(mas_sound_rejs)-1,11]:=trim(full_mas[n,8]);
              mas_sound_rejs[length(mas_sound_rejs)-1,12]:='';
              mas_sound_rejs[length(mas_sound_rejs)-1,13]:='';
              mas_sound_rejs[length(mas_sound_rejs)-1,14]:=inttostr(n);
              mas_sound_rejs[length(mas_sound_rejs)-1,15]:='';    //кол-во свободных мест
           end;
        end;
     end;

     if length(mas_sound_rejs)=0 then
          exit;


    // Определяем количество свободных мест в автобусе
    for n:=0 to length(mas_sound_rejs)-1 do
      begin
       //getbronsale(dater date,
                     //idot integer,
                     //iddo integer,
                     //idkontr integer,
                     //idshedule integer,
                     //triptime character,
                     //idats integer,
                     //form integer,
                     //order_ot integer,
                     //order_do integer,
                     //type_return integer)
        ZQ.SQL.Clear;
        ZQ.sql.add('select * from getbronsale('+Quotedstr(datetostr(work_date))+','+
                             full_mas[strtoint(mas_sound_rejs[n,14]),3]+','+
                             full_mas[strtoint(mas_sound_rejs[n,14]),6]+','+
                            full_mas[strtoint(mas_sound_rejs[n,14]),18]+','+
                             full_mas[strtoint(mas_sound_rejs[n,14]),1]+','+
                 Quotedstr(full_mas[strtoint(mas_sound_rejs[n,14]),10])+','+
                            full_mas[strtoint(mas_sound_rejs[n,14]),20]+','+
                             full_mas[strtoint(mas_sound_rejs[n,14]),9]+','+
                             full_mas[strtoint(mas_sound_rejs[n,14]),4]+','+
                             full_mas[strtoint(mas_sound_rejs[n,14]),7]+
                              ',2) as free;');
//        form1.memo1.Lines.AddStrings(ZQ.sql);
     //showmessage(zq.sql.Text);
        try
           ZQ.open;
        except
         ZQ.Close;
         Zcon.disconnect;
         exit;
        end;
        //кол-во свободных мест
        If Zq.RecordCount=0 then
         begin
          mas_sound_rejs[n,15]:='0';
         end
        else
         begin
          mas_sound_rejs[n,15]:=ZQ.FieldByName('free').asString;
         end;
      end;
     ZQ.Close;
     Zcon.disconnect;
     back_time_empty:=ttt;
     result:=true;
end;

// Определяем сообщения за 5(n) минут до отправления открытого для продажи рейса
function to_nmin_rejs(ZCon:TZConnection; ZQ:TZquery):boolean;
 var
  ttt:string='';
  n:integer;
begin
 // Создаем массив доступных рейсов
  Rascet_mas(ZCon,ZQ,1);
  //write_log(inttostr(length(full_mas)));
  if length(full_mas)=0 then
   begin
    result:=false;
    exit;
   end;

   // Вычисляем времы отправления - за 5 минут
   DateTimeToString(ttt, 't', IncMinute(now(),5));
   ttt:=copy(trim(ttt),1,5);

   // Если время равно предыдущему то еще раз не объявлять
   if trim(back_time)=trim(ttt) then
      begin
        result:=false;
        exit;
      end;

   setlength(mas_sound_rejs,0);
   for n:=0 to length(full_mas)-1 do
     begin
      // Сканируем массив рейсов если они еще открыты и активны и время фактичесого отправления за пять минут
      if (trim(full_mas[n,10])=trim(ttt)) and (((trim(full_mas[n,28])='0')) or (trim(full_mas[n,28])='1')) then
        begin
           // Заполняем временный массив
           SetLength(mas_sound_rejs,length(mas_sound_rejs)+1,16);
           mas_sound_rejs[length(mas_sound_rejs)-1,0]:=trim(full_mas[n,1]);
           mas_sound_rejs[length(mas_sound_rejs)-1,1]:=trim(full_mas[n,10]);
           mas_sound_rejs[length(mas_sound_rejs)-1,2]:='';
           mas_sound_rejs[length(mas_sound_rejs)-1,3]:=trim(full_mas[n,3]);
           mas_sound_rejs[length(mas_sound_rejs)-1,4]:=trim(full_mas[n,6]);
           mas_sound_rejs[length(mas_sound_rejs)-1,5]:='98';
           mas_sound_rejs[length(mas_sound_rejs)-1,6]:=trim(full_mas[n,45]);
           mas_sound_rejs[length(mas_sound_rejs)-1,7]:=trim(full_mas[n,46]);
           mas_sound_rejs[length(mas_sound_rejs)-1,8]:=trim(full_mas[n,4]);
           mas_sound_rejs[length(mas_sound_rejs)-1,9]:=trim(full_mas[n,7]);
           mas_sound_rejs[length(mas_sound_rejs)-1,10]:=trim(full_mas[n,5]);
           mas_sound_rejs[length(mas_sound_rejs)-1,11]:=trim(full_mas[n,8]);
           mas_sound_rejs[length(mas_sound_rejs)-1,12]:='';
           mas_sound_rejs[length(mas_sound_rejs)-1,13]:='';
           mas_sound_rejs[length(mas_sound_rejs)-1,14]:='';
           mas_sound_rejs[length(mas_sound_rejs)-1,15]:='';
        end;
  end;

//     form1.Label4.Caption:=inttostr(length(full_mas))+' - '+ttt;
//  application.ProcessMessages;

     if length(mas_sound_rejs)=0 then
        begin
          Result:=false;
          exit;
        end;
     back_time:=ttt;
     result:=true;
end;

// Определяем состав рейса
procedure sostav_rejs(ZCon:TZConnection; ZQ:TZquery;ind:integer);
var
  n,fl:integer;
begin
  SetLength(mas_rejs_sostav,0);
  If not(Connect2(Zcon, flagProfile)) then
  begin
   exit;
  end;

  // Устанавливаем таймаут запроса
  ZQ.SQL.Clear;
  ZQ.sql.add('SET statement_timeout = 2000'); // two second
  try
     ZQ.open;
   except
       ZQ.Close;
       Zcon.disconnect;
       exit;
   end;

  //Забираем состав рейса
  //write_log(trim(mas_sound_rejs[ind,8])+' - '+trim(mas_sound_rejs[ind,9]));
  ZQ.SQL.Clear;
  ZQ.sql.add('select * from get_sound_rejs_sostav('+quotedstr('sostav')+','+trim(mas_sound_rejs[ind,0])+','+trim(mas_sound_rejs[ind,8])+','+trim(mas_sound_rejs[ind,9])+');');
  ZQ.sql.add('FETCH ALL IN sostav;');
  try
     ZQ.open;
  except
      write_log('--v05-- Выполнение команды SQL - ОШИБКА !'+#13+'Команда: '+ZQ.SQL.Text);
       ZQ.Close;
       Zcon.disconnect;
       exit;
  end;
 If Zq.RecordCount=0 then
   begin
      ZQ.Close;
      Zcon.disconnect;
      exit;
   end;

  // Ложим все новые операции в массив
  fl:=0;
  for n:=0 to ZQ.RecordCount-1 do
    begin
      if (trim(ZQ.FieldByName('id_point').asString)=trim(connectini[14])) and (fl=0) then fl:=1;
      if fl=2 then
        begin
         SetLength(mas_rejs_sostav,length(mas_rejs_sostav)+1);
         mas_rejs_sostav[length(mas_rejs_sostav)-1]:=ZQ.FieldByName('kod').asString;
        end;
      if fl=1 then fl:=2;
      ZQ.Next;
    end;
  ZQ.close;
  ZCon.Disconnect;
end;

// Теущая дата и время сервера
function get_time_date(ZCon:TZConnection; ZQ:TZquery):boolean;
begin
 result:=false;
 // -------------------- Соединяемся с локальным сервером ----------------------
 If not(Connect2(Zcon, flagProfile)) then
  begin
   write_log('Соединение с сервером базы данных отсутствует ! --v06--');
   exit;
  end;
   // Устанавливаем таймаут запроса
  ZQ.SQL.Clear;
  ZQ.sql.add('SET statement_timeout = 2000'); // two second
  try
     ZQ.open;
   except
       ZQ.Close;
       Zcon.disconnect;
       exit;
   end;

 // Забираем время и дату
 //ZQ.Close;
 ZQ.SQL.Clear;
 ZQ.sql.add('select to_char(now(),'+quotedstr('dd.mm.yyyy hh24:mi:ss')+') as date, inet_client_addr();');
// form1.memo1.Lines.AddStrings(ZQ.sql);
 try
   ZQ.open;
 except
   ZQ.Close;
   Zcon.disconnect;
   exit;
 end;
 if ZQ.RecordCount>0 then
  begin
  Tek_datetime:=ZQ.FieldByName('date').asString;
  form1.Label7.caption := 'мой адрес IP:' + ZQ.FieldByName('inet_client_addr').asString;
  Result:=true;
  end;
   ZQ.Close;
   Zcon.disconnect;

   exit;
 end;

// Озвучивание рейсовых операций
procedure play_rejs_sound(ind:integer);
var
  sound_files:string='';
  kol_sound_files:integer=0;
  fc:string='';
  n,m:integer;
begin
  if stream<>0 then bass_StreamFree(stream);
    ////////////////// Разбираем команды на текущем элементе массива ///////////////

    // 1.0 Опаздывающие пассажиры
  if trim(mas_sound_rejs[ind,15])='100' then
     begin
       // Сигнал привлечения к сообщению
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/predv/sound1.mp3|';
       // Внимание ! Пассажиры с билетами на рейс
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/function/opoz1.mp3|';
       // Первый пункт отправления
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/point/'+PADL(trim(mas_sound_rejs[ind,6]),'0',8)+'.mp3|';
       // Последний пункт отправления
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/point/'+PADL(trim(mas_sound_rejs[ind,7]),'0',8)+'.mp3|';
       // Время отправления n часа
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/time/clock_'+PADL(copy(trim(mas_sound_rejs[ind,1]),1,2),'0',2)+'.mp3|';
       // n минут
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/time/minut_'+PADL(copy(trim(mas_sound_rejs[ind,1]),4,2),'0',2)+'.mp3|';
       // Займите места в автобусе, отправляющегося с посадочной площадки номер
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/function/opoz2.mp3|';
       // Номер площадки
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/function/0'+trim(mas_sound_rejs[ind,2])+'.mp3|';
       // Вы задерживаете его отправление
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/function/opoz3.mp3|';
     end;

  /////////////// Разбираем команды на текущем элементе массива ///////////////
  // 1.1 Отправление
  if (trim(mas_sound_rejs[ind,5])='4') and not(trim(mas_sound_rejs[ind,15])='100') and not(trim(mas_sound_rejs[ind,15])='80') then
     begin
       // Сигнал привлечения к сообщению
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/predv/sound1.mp3|';
       // Уважаемые пассажиры ! От n посадочной площадки отправляется автобус по маршруту..
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/function/platf_0'+trim(mas_sound_rejs[ind,2])+'.mp3|';
       // Первый пункт отправления
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/point/'+PADL(trim(mas_sound_rejs[ind,6]),'0',8)+'.mp3|';
       // Последний пункт отправления
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/point/'+PADL(trim(mas_sound_rejs[ind,7]),'0',8)+'.mp3|';
       // Время отправления n часа
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/time/clock_'+PADL(copy(trim(mas_sound_rejs[ind,1]),1,2),'0',2)+'.mp3|';
       // n минут
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/time/minut_'+PADL(copy(trim(mas_sound_rejs[ind,1]),4,2),'0',2)+'.mp3|';
       // Автобус следует
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/function/rejsout9.mp3|';
       // Состав маршрута
       if length(mas_rejs_sostav)>0 then
          begin
            for m:=0 to length(mas_rejs_sostav)-1 do
              begin
               kol_sound_files:=kol_sound_files+1;
               sound_files:=sound_files+'sound/point/'+PADL(trim(mas_rejs_sostav[m]),'0',8)+'.mp3|';
              end;
          end;
       // write_log(sound_files+'sound/point/'+PADL(trim(mas_rejs_sostav[m]),'0',8)+'.mp3|');
       // Счастливого пути
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/function/rejsout8.mp3|';
     end;

   ////////////////// Разбираем команды на текущем элементе массива ///////////////
  // 1.1.1 Дообилечивание
  if trim(mas_sound_rejs[ind,5])='1' then
     begin
       // Сигнал привлечения к сообщению
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/predv/sound1.mp3|';
       // Внимание перонного контролера ! Открыта ведомость дообилечивания на рейс..
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/function/doobil.wav|';
       // Первый пункт отправления
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/point/'+PADL(trim(mas_sound_rejs[ind,6]),'0',8)+'.mp3|';
       // Последний пункт отправления
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/point/'+PADL(trim(mas_sound_rejs[ind,7]),'0',8)+'.mp3|';
     end;

  // 1.2 Прибытие
  if trim(mas_sound_rejs[ind,5])='2' then
     begin
       // Сигнал привлечения к сообщению
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/predv/sound1.mp3|';
       // Внимание встречающих !!! Прибыл автобус
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/function/rejsinp0.mp3|';
       // Первый пункт отправления
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/point/'+PADL(trim(mas_sound_rejs[ind,6]),'0',8)+'.mp3|';
       // Последний пункт отправления
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/point/'+PADL(trim(mas_sound_rejs[ind,7]),'0',8)+'.mp3|';
       // Просьба пассажирам пройти на перрон
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/function/rejsinp1.mp3|';     // задание Щ о замене слова "пассажирам -> к встречающим"
     end;

// 1.3 Срыв отправления
  if (trim(mas_sound_rejs[ind,5])='5') and (trim(mas_sound_rejs[ind,14])='1') then
    begin
      //if (trim(ConnectINI[14])='816') then sleep(1) else
        begin
          // Сигнал привлечения к сообщению
          kol_sound_files:=kol_sound_files+1;
          sound_files:=sound_files+'sound/predv/sound1.mp3|';
          // Внимание !!! Пассажиры имеющие билеты по маршруту
          kol_sound_files:=kol_sound_files+1;
          sound_files:=sound_files+'sound/function/rejsbrk0.mp3|';
          // Первый пункт отправления
          kol_sound_files:=kol_sound_files+1;
          sound_files:=sound_files+'sound/point/'+PADL(trim(mas_sound_rejs[ind,6]),'0',8)+'.mp3|';
          // Последний пункт отправления
          kol_sound_files:=kol_sound_files+1;
          sound_files:=sound_files+'sound/point/'+PADL(trim(mas_sound_rejs[ind,7]),'0',8)+'.mp3|';
          // Время отправления n часа
          kol_sound_files:=kol_sound_files+1;
          sound_files:=sound_files+'sound/time/clock_'+PADL(copy(trim(mas_sound_rejs[ind,1]),1,2),'0',2)+'.mp3|';
          // n минут
          kol_sound_files:=kol_sound_files+1;
          sound_files:=sound_files+'sound/time/minut_'+PADL(copy(trim(mas_sound_rejs[ind,1]),4,2),'0',2)+'.mp3|';
          // Автобус не пойдет в рейс по технической неисправности
          kol_sound_files:=kol_sound_files+1;
          sound_files:=sound_files+'sound/function/break__0.mp3|';
          // Просьба пройти в кассы переоформить билеты
          kol_sound_files:=kol_sound_files+1;
          sound_files:=sound_files+'sound/function/rejsbrk2.mp3|';
        end;
    end;

// 1.3.1 Срыв прибытия
  if (trim(mas_sound_rejs[ind,5])='5') and (trim(mas_sound_rejs[ind,14])='2') then
     begin
       // Сигнал привлечения к сообщению
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/predv/sound1.mp3|';
       // Внимание встречающих !!! Автобус следующий по маршруту
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/function/prib_sr.mp3|';
       // Первый пункт отправления
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/point/'+PADL(trim(mas_sound_rejs[ind,6]),'0',8)+'.mp3|';
       // Последний пункт отправления
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/point/'+PADL(trim(mas_sound_rejs[ind,7]),'0',8)+'.mp3|';
       // Время прибытия n часа
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/time/clock_in_'+PADL(copy(trim(mas_sound_rejs[ind,1]),1,2),'0',2)+'.mp3|';
       // n минут
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/time/minut_'+PADL(copy(trim(mas_sound_rejs[ind,1]),4,2),'0',2)+'.mp3|';
       // отменяется по техническим причинам
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/function/prib_tp.mp3|';
     end;

// 1.4 Разрешается посадка
  if trim(mas_sound_rejs[ind,5])='98' then
     begin
       // Сигнал привлечения к сообщению
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/predv/sound1.mp3|';
       // Уважаемые пассажиры ! Разрешается посадка на атобус по маршруту
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/function/posadka1.mp3|';
       // Первый пункт отправления
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/point/'+PADL(trim(mas_sound_rejs[ind,6]),'0',8)+'.mp3|';
       // Последний пункт отправления
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/point/'+PADL(trim(mas_sound_rejs[ind,7]),'0',8)+'.mp3|';
       // Время отправления n часа
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/time/clock_'+PADL(copy(trim(mas_sound_rejs[ind,1]),1,2),'0',2)+'.mp3|';
       // n минут
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/time/minut_'+PADL(copy(trim(mas_sound_rejs[ind,1]),4,2),'0',2)+'.mp3|';
       // Просьба к пассажирам пройти на посадку
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/function/posadka2.mp3|';
       // Приобретайте багаж
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/function/prim1.wav|';
     end;

  // 1.5 Опоздание отправления
  if (trim(mas_sound_rejs[ind,5])='3') and (trim(mas_sound_rejs[ind,14])='1') then
   begin
     // Сигнал привлечения к сообщению
     kol_sound_files:=kol_sound_files+1;
     sound_files:=sound_files+'sound/predv/sound1.mp3|';
     // Внимание пассажиров !Автобус по маршруту
     kol_sound_files:=kol_sound_files+1;
     sound_files:=sound_files+'sound/function/rejstim0.mp3|';
     // Первый пункт отправления
     kol_sound_files:=kol_sound_files+1;
     sound_files:=sound_files+'sound/point/'+PADL(trim(mas_sound_rejs[ind,6]),'0',8)+'.mp3|';
     // Последний пункт отправления
     kol_sound_files:=kol_sound_files+1;
     sound_files:=sound_files+'sound/point/'+PADL(trim(mas_sound_rejs[ind,7]),'0',8)+'.mp3|';
     // Время отправления n часа
     kol_sound_files:=kol_sound_files+1;
     sound_files:=sound_files+'sound/time/clock_'+PADL(copy(trim(mas_sound_rejs[ind,1]),1,2),'0',2)+'.mp3|';
     // n минут
     kol_sound_files:=kol_sound_files+1;
     sound_files:=sound_files+'sound/time/minut_'+PADL(copy(trim(mas_sound_rejs[ind,1]),4,2),'0',2)+'.mp3|';
     // задерживается. О прибытии автобуса будет объявлено дополнительно.
     kol_sound_files:=kol_sound_files+1;
     sound_files:=sound_files+'sound/function/rejstio3.mp3|';
   end;

  // 1.5.1 Опоздание прибытия
  if (trim(mas_sound_rejs[ind,5])='3') and (trim(mas_sound_rejs[ind,14])='2') then
   begin
     // Сигнал привлечения к сообщению
     kol_sound_files:=kol_sound_files+1;
     sound_files:=sound_files+'sound/predv/sound1.mp3|';
     // Внимание встречающих !Автобус следующий по маршруту
     kol_sound_files:=kol_sound_files+1;
     sound_files:=sound_files+'sound/function/rejstim1.wav|';
     // Первый пункт отправления
     kol_sound_files:=kol_sound_files+1;
     sound_files:=sound_files+'sound/point/'+PADL(trim(mas_sound_rejs[ind,6]),'0',8)+'.mp3|';
     // Последний пункт отправления
     kol_sound_files:=kol_sound_files+1;
     sound_files:=sound_files+'sound/point/'+PADL(trim(mas_sound_rejs[ind,7]),'0',8)+'.mp3|';
     // Время прибытия n часа
     kol_sound_files:=kol_sound_files+1;
     sound_files:=sound_files+'sound/time/clock_in_'+PADL(copy(trim(mas_sound_rejs[ind,1]),1,2),'0',2)+'.mp3|';
     // n минут
     kol_sound_files:=kol_sound_files+1;
     sound_files:=sound_files+'sound/time/minut_'+PADL(copy(trim(mas_sound_rejs[ind,1]),4,2),'0',2)+'.mp3|';
     // задерживается.О прибытии автобуса будет объявлено дополнительно.
     kol_sound_files:=kol_sound_files+1;
     sound_files:=sound_files+'sound/function/rejstio3.mp3|';
   end;

     // 1.6 Свободные места за 15 минут до отправления
  if (trim(mas_sound_rejs[ind,5])='99') and not(trim(mas_sound_rejs[ind,15])='0') then
     begin
       // Сигнал привлечения к сообщению
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/predv/sound1.mp3|';
       // Уважаемые пассажиры ! В кассах автовокзала имеются билеты на автобус следующий по маршруту
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/function/mendown0.mp3|';
       // Первый пункт отправления
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/point/'+PADL(trim(mas_sound_rejs[ind,6]),'0',8)+'.mp3|';
       // Последний пункт отправления
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/point/'+PADL(trim(mas_sound_rejs[ind,7]),'0',8)+'.mp3|';
       // Время отправления n часа
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/time/clock_'+PADL(copy(trim(mas_sound_rejs[ind,1]),1,2),'0',2)+'.mp3|';
       // n минут
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/time/minut_'+PADL(copy(trim(mas_sound_rejs[ind,1]),4,2),'0',2)+'.mp3|';
     end;


     // 1.7 !!!Свободные места до отправления
  if (trim(mas_sound_rejs[ind,15])='80')  then
     begin
       // Сигнал привлечения к сообщению
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/predv/sound1.mp3|';
       // Уважаемые пассажиры ! В кассах автовокзала имеются билеты на автобус следующий по маршруту
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/function/mendown0.mp3|';
       // Первый пункт отправления
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/point/'+PADL(trim(mas_sound_rejs[ind,6]),'0',8)+'.mp3|';
       // Последний пункт отправления
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/point/'+PADL(trim(mas_sound_rejs[ind,7]),'0',8)+'.mp3|';
       // Время отправления n часа
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/time/clock_'+PADL(copy(trim(mas_sound_rejs[ind,1]),1,2),'0',2)+'.mp3|';
       // n минут
       kol_sound_files:=kol_sound_files+1;
       sound_files:=sound_files+'sound/time/minut_'+PADL(copy(trim(mas_sound_rejs[ind,1]),4,2),'0',2)+'.mp3|';
     end;

  //==
  fc:='';
  for n:=1 to kol_sound_files do
    begin
     if n=1 then
        begin
         fc:=UTF8Copy(trim(sound_files),1,UTF8Pos('|',trim(sound_files))-1);
        end;
     if (n>1) and (n<kol_sound_files) then
        begin
         fc:=UTF8Copy(trim(sound_files),Posnext(trim(sound_files),'|',n-1)+1,Posnext(trim(sound_files),'|',n)-Posnext(trim(sound_files),'|',n-1)-1);
        end;
     if (n=kol_sound_files) then
        begin
         fc:=UTF8Copy(trim(UTF8Copy(trim(sound_files),Posnext(trim(sound_files),'|',n-1)+1,200)),1,UTF8Length(trim(UTF8Copy(trim(sound_files),Posnext(trim(sound_files),'|',n-1)+1,200)))-1);
        end;

     // Открываем проигрываемый файл если файл присутствует
     if old_fc=fc then begin   // костыльчик
                         write_log('--v007-- old_fc = fc: '+ fc);
                         old_fc:=fc;
                         continue;
                       end;

     if FileExists((ExtractFilePath(Application.ExeName)+trim(fc))) then
        begin
         form1.Label9.Font.Color:=clRED;
         form1.Label9.Caption:='СОСТОЯНИЕ: ГОВОРЮ';
          application.ProcessMessages;

          stream:= bass_streamCreateFile(false,Pchar(ExtractFilePath(Application.ExeName)+trim(fc)), 0, 0, 0);
          //логировать только содержательный файл
          if n=2 then write_log('--v008-- '+fc);
          // Начать проигрывание
          bass_channelplay(stream,false);
             repeat
               //application.ProcessMessages;
               sleep(10);
             until BASS_ChannelIsActive(stream)=0;

        end
      else write_log('--v009-- нет файла: '+fc);  // кладем в логи ошибочку воспроизведения!
       bass_streamfree(stream);
       form1.Label9.font.Color:=clBlack;
       form1.Label9.Caption:='СОСТОЯНИЕ: МОЛЧУ';
       application.ProcessMessages;

      old_fc:=fc;              // обновление костыльчика
    end;
end;

//Разбор для озвучивания рейсовых операций
procedure play_rejs_oper;
var
  n:integer;
begin
  if length(mas_sound_rejs)=0 then
     begin
       write_log('--v22-- массив операций по рейсам ПУСТ!');
       exit;
     end;

  form1.Label2.Font.Color:=clGreen;

 // =========================ПРИОРИТЕТ 1.1===========================
 for n:=0 to length(mas_sound_rejs)-1 do
   begin
      //ОБЪЯВЛЕНИЕ ОПАЗДЫВАЮЩИМ
     if trim(mas_sound_rejs[n,5])='100' then
       begin
         form1.Label2.Caption:='Состояние рейсов: ОБЪЯВЛЕНИЕ ОПАЗДЫВАЮЩИМ рейс '+mas_sound_rejs[n,1]+' ['+mas_sound_rejs[n,0]+'] в '+trim(mas_sound_rejs[n,11]);
         play_rejs_sound(n);
       end;
   end;

 // =========================ПРИОРИТЕТ 1.2===========================
 // Разбираем дообилечивания рейсов
 for n:=0 to length(mas_sound_rejs)-1 do
   begin
     // Озвучиваем данные по дообилечиванию
     if trim(mas_sound_rejs[n,5])='1' then
       begin
         form1.Label2.Caption:='Состояние рейсов: ДООБИЛЕЧИВАНИЕ рейс '+mas_sound_rejs[n,1]+' ['+mas_sound_rejs[n,0]+'] в '+trim(mas_sound_rejs[n,11]);
         write_log('Состояние рейсов: ДООБИЛЕЧИВАНИЕ рейс '+mas_sound_rejs[n,1]+' ['+mas_sound_rejs[n,0]+'] в '+trim(mas_sound_rejs[n,11]));
         //application.ProcessMessages;
         sostav_rejs(form1.ZConnection1,Form1.Zquery1,n);
         play_rejs_sound(n);
       end;
   end;

 // =========================ПРИОРИТЕТ 1.3===========================
  // Разбираем отправления рейсов
 for n:=0 to length(mas_sound_rejs)-1 do
   begin
     // Озвучиваем данные по отправлению
     if trim(mas_sound_rejs[n,5])='4' then
       begin
         form1.Label2.Caption:='Состояние рейсов: ОТПРАВЛЕНИЕ рейс '+mas_sound_rejs[n,1]+' ['+mas_sound_rejs[n,0]+'] в '+trim(mas_sound_rejs[n,11]);
         //application.ProcessMessages;
         sostav_rejs(form1.ZConnection1,Form1.Zquery1,n);
         play_rejs_sound(n);
       end;
   end;

  // =========================ПРИОРИТЕТ 1.4===========================
 // Разбираем опоздания рейсов
 for n:=0 to length(mas_sound_rejs)-1 do
   begin
     // Озвучиваем данные по опозданию
     if trim(mas_sound_rejs[n,5])='3' then
       begin
         form1.Label2.Caption:='Состояние рейсов: ОПОЗДАНИЕ рейс '+mas_sound_rejs[n,1]+' ['+mas_sound_rejs[n,0]+'] в '+trim(mas_sound_rejs[n,11]);
         write_log('Состояние рейсов: ОПОЗДАНИЕ рейс '+mas_sound_rejs[n,1]+' ['+mas_sound_rejs[n,0]+'] в '+trim(mas_sound_rejs[n,11]));
         play_rejs_sound(n);
       end;
   end;

 // =========================ПРИОРИТЕТ 1.5===========================
 // Разбираем срывы рейсов
 for n:=0 to length(mas_sound_rejs)-1 do
   begin
     // Озвучиваем данные по отправлению
     if trim(mas_sound_rejs[n,5])='5' then
       begin
         form1.Label2.Caption:='Состояние рейсов: РЕЙС СОРВАН '+mas_sound_rejs[n,1]+' ['+mas_sound_rejs[n,0]+'] в '+trim(mas_sound_rejs[n,11]);
         write_log('Состояние рейсов: РЕЙС СОРВАН '+mas_sound_rejs[n,1]+' ['+mas_sound_rejs[n,0]+'] в '+trim(mas_sound_rejs[n,11]));
         play_rejs_sound(n);
       end;
   end;

 // =========================ПРИОРИТЕТ 1.6===========================
 for n:=0 to length(mas_sound_rejs)-1 do
   begin
     // Озвучиваем данные по прибытию
     if trim(mas_sound_rejs[n,5])='98' then
       begin
         form1.Label2.Caption:='Состояние рейсов: РАЗРЕШАЕТСЯ ПОСАДКА рейс '+mas_sound_rejs[n,1]+' ['+mas_sound_rejs[n,0]+'] в '+trim(mas_sound_rejs[n,11]);
         play_rejs_sound(n);
       end;
   end;

  // =========================ПРИОРИТЕТ 1.7===========================
  // прибытие
 for n:=0 to length(mas_sound_rejs)-1 do
   begin
     // Озвучиваем данные по прибытию
     if trim(mas_sound_rejs[n,5])='2' then
       begin
         form1.Label2.Caption:='Состояние рейсов: ПРИБЫЛ РЕЙС '+mas_sound_rejs[n,1]+' ['+mas_sound_rejs[n,0]+'] в '+trim(mas_sound_rejs[n,11]);
         play_rejs_sound(n);
       end;
   end;

  // =========================ПРИОРИТЕТ 1.8===========================
 for n:=0 to length(mas_sound_rejs)-1 do
   begin
     //Свободные места за 15 минут до отправления
     if trim(mas_sound_rejs[n,5])='99' then
       begin
         form1.Label2.Caption:='Состояние рейсов: СВОБОДНЫЕ МЕСТА рейс '+mas_sound_rejs[n,1]+' ['+mas_sound_rejs[n,0]+'] в '+trim(mas_sound_rejs[n,11]);
         play_rejs_sound(n);
         end;
      //Свободные места СРОЧНО
     if trim(mas_sound_rejs[n,5])='80' then
       begin
         form1.Label2.Caption:='Состояние рейсов: СВОБОДНЫЕ МЕСТА рейс '+mas_sound_rejs[n,1]+' ['+mas_sound_rejs[n,0]+'] в '+trim(mas_sound_rejs[n,11]);
         write_log('Состояние рейсов: СРОЧНО! СВОБОДНЫЕ МЕСТА рейс '+mas_sound_rejs[n,1]+' ['+mas_sound_rejs[n,0]+'] в '+trim(mas_sound_rejs[n,11]));
         play_rejs_sound(n);
       end;
   end;

 //вернуть исходные значения
   form1.Label2.Font.Color:=clBlack;
end;

//Разбор для озвучивания информационных сообщений
procedure play_rejs_oper_reklama;
var
  n:integer;
  filename:string;
  filelog:TextFile;
begin
 // =========================ПРИОРИТЕТ 2.0===========================
 // Разбираем информационные сообщения
  if length(mas_reklama)>0 then
    begin
      for n:=0 to length(mas_reklama)-1 do
        begin
        // Озвучиваем данные по информационным сообщениям
        // mas_reklama[n,0] - id
        // mas_reklama[n,1] - level
        // mas_reklama[n,2] - file
        // mas_reklama[n,3] - remark
        // mas_reklama[n,4] - interval
        // mas_reklama[n,5] - status
        // mas_reklama[n,6] - tek time
//   form1.memo1.Lines.Add(mas_reklama[n,2] +' - ' + inttostr(get_min) + ' - ' + mas_reklama[n,6] +' - ' +mas_reklama[n,4]);       // экранные логи
    //пропускать сообщения
    If not form1.CheckBox3.Checked then continue;

    if ((get_min-strtoint(trim(mas_reklama[n,6])))>strtoint(trim(mas_reklama[n,4]))) then                                        // это условие воспроизведения рекламы
      begin
        form1.Label2.Font.Color:=clGreen;
        form1.Label2.Caption:='INFO: '+trim(mas_reklama[n,3]);
        write_log('--v10-- info: '+trim(mas_reklama[n,3]));

        //filename:=ExtractFilePath(Application.ExeName)+'/log/platvoice_R_'+FormatDateTime('dd.mm.yyyy', now())+'.log';
        //AssignFile(filelog,filename);
        //{$I-} // отключение контроля ошибок ввода-вывода
        //if not fileExists(filename) then
        //  begin
        //    Rewrite(filelog); // открытие файла
        //    {$I+} // включение контроля ошибок ввода-вывода
        //    if IOResult<>0 then Exit;
        //    closefile(filelog);
        //  end;
        //Append(filelog);
        //writeln(filelog,FormatDateTime('hh:mm:ss', now())+' -> '+trim(mas_reklama[n,3]));
        //closefile(filelog);
        play_rejs_sound_reklama(n);
        mas_reklama[n,6]:=inttostr(get_min);
        form1.Label2.Font.Color:=clBlack;
        form1.Label2.Caption:='Состояние рейсов:';
      end;
    end;
  end;
end;

//Новые задания по рейсам
function get_new_event_rejs(ZCon:TZConnection; ZQ:TZquery):boolean;
 var
   n:integer;
begin
result:=false;
    //======================== Диспетчерские операции================================
 // -------------------- Соединяемся с локальным сервером ----------------------
 If not(Connect2(Zcon, flagProfile)) then
  begin
   write_log('Соединение с сервером базы данных отсутствует ! --v12--');
   result:=false;
   exit;
  end;
   // Устанавливаем таймаут запроса
  ZQ.SQL.Clear;
  ZQ.sql.add('SET statement_timeout = 2000'); // two second
  try
     ZQ.open;
   except
       ZQ.Close;
       Zcon.disconnect;
       Result:=false;
       exit;
   end;

 form1.Label3.Caption:='Активность данных : '+trim(prev_datetime);
 // Забираем новые диспетчесркие операции
ZQ.SQL.Clear;
ZQ.sql.add('select * from get_sound_rejs('+quotedstr('sound')+','+quotedstr(trim(prev_datetime))+');');
ZQ.sql.add('FETCH ALL IN sound;');
//write_log(ZQ.sql.text);//$
try
     ZQ.open;
 except
     write_log('--v13-- Выполнение команды SQL - ОШИБКА !'+#13+'Команда: '+ZQ.SQL.Text);
       ZQ.Close;
       Zcon.disconnect;
       Result:=false;
       exit;
 end;
 If Zq.RecordCount=0 then
   begin
      ZQ.Close;
      Zcon.disconnect;
      Result:=false;
      exit;
   end;

   // mas_sound_rejs[n,0] id_shedule
  // mas_sound_rejs[n,1] trip_time
  // mas_sound_rejs[n,2] platforma
  // mas_sound_rejs[n,3] ot_id_point
  // mas_sound_rejs[n,4] do_id_point
  // mas_sound_rejs[n,5] trip_flag
  // mas_sound_rejs[n,6] ot_id_locality
  // mas_sound_rejs[n,7] do_id_locality
  // mas_sound_rejs[n,8] ot_order
  // mas_sound_rejs[n,9] do_order
  // mas_sound_rejs[n,10] ot_name
  // mas_sound_rejs[n,11] do_name
  // mas_sound_rejs[n,12] createdate
  // mas_sound_rejs[n,13] createdate1
  // mas_sound_rejs[n,14] napr

  // Кладем все новые операции в массив
  SetLength( mas_sound_rejs,0);
  for n:=0 to ZQ.RecordCount-1 do
    begin
       SetLength(mas_sound_rejs,length(mas_sound_rejs)+1,16);
       if n=0 then prev_datetime:=ZQ.FieldByName('createdt').asString;
       //опаздывающим свободные
       If (ZQ.FieldByName('id_oper').asInteger=100) or (ZQ.FieldByName('id_oper').asInteger=80) then
         begin
            If last_late_time<ZQ.FieldByName('createdate').asDateTime then
              last_late_time:=ZQ.FieldByName('createdate').asDateTime
            else
              begin
                zq.Next;
                continue;
              end;
          end;
       //write_log(ZQ.FieldByName('createdate').asString);
       mas_sound_rejs[length(mas_sound_rejs)-1,0]:=ZQ.FieldByName('id_shedule').asString;
       mas_sound_rejs[length(mas_sound_rejs)-1,1]:=ZQ.FieldByName('trip_time').asString;
       mas_sound_rejs[length(mas_sound_rejs)-1,2]:=ZQ.FieldByName('platforma').asString;
       mas_sound_rejs[length(mas_sound_rejs)-1,3]:=ZQ.FieldByName('ot_id_point').asString;
       mas_sound_rejs[length(mas_sound_rejs)-1,4]:=ZQ.FieldByName('do_id_point').asString;
       mas_sound_rejs[length(mas_sound_rejs)-1,5]:=ZQ.FieldByName('trip_flag').asString;
       mas_sound_rejs[length(mas_sound_rejs)-1,6]:=ZQ.FieldByName('ot_id_locality').asString;
       mas_sound_rejs[length(mas_sound_rejs)-1,7]:=ZQ.FieldByName('do_id_locality').asString;
       mas_sound_rejs[length(mas_sound_rejs)-1,8]:=ZQ.FieldByName('ot_order').asString;
       mas_sound_rejs[length(mas_sound_rejs)-1,9]:=ZQ.FieldByName('do_order').asString;
       mas_sound_rejs[length(mas_sound_rejs)-1,10]:=ZQ.FieldByName('ot_name').asString;
       mas_sound_rejs[length(mas_sound_rejs)-1,11]:=ZQ.FieldByName('do_name').asString;
       mas_sound_rejs[length(mas_sound_rejs)-1,12]:=ZQ.FieldByName('createdate').asString;
       mas_sound_rejs[length(mas_sound_rejs)-1,13]:=ZQ.FieldByName('createdt').asString;
       mas_sound_rejs[length(mas_sound_rejs)-1,14]:=ZQ.FieldByName('napr').asString;
       mas_sound_rejs[length(mas_sound_rejs)-1,15]:=ZQ.FieldByName('id_oper').asString;
       zq.Next;
    end;
  //popytki:=popytki+1;
  //form1.Label2.Caption:='['+inttostr(popytki)+'] '+inttostr(ZQ.RecordCount);
  ZQ.close;
  ZCon.Disconnect;
  //prev_datetime:=now;
  Result:=true;
end;

 //**********************************    Пересчет динамичеких параметров для рейсов в массиве  ************************************
procedure Rascet_mas(ZCon:TZConnection;ZQ:TZquery;priznak:byte);
 // priznak=0 - общий случай  расчета
 // priznak=1 - смена даты - принудительный расчет состояний
var
   flag:byte=0;
   flag_av_trip:boolean=false;
//   flag_av_trip_add:boolean=true;
   n,m,tn,tm,kol_wed:integer;
//   arSezon : array of array of String;
//   myYear,myMonth,myDay,myHour,myMin,mySec,myMilli:Word;
//   flerror : boolean=false;
begin
  // --------------------Соединяемся с локальным сервером----------------------

 If not(Connect2(Zcon, flagProfile)) then
   begin
    write_log('Соединение с сервером базы данных отсутствует ! --v14--');
    exit;
   end;

  flag:=0;
  // Устанавливаем таймаут запроса
  ZQ.SQL.Clear;
  ZQ.sql.add('SET statement_timeout = 2000'); // two second
  try
     ZQ.open;
   except
       ZQ.Close;
       Zcon.disconnect;
       exit;
   end;

// ----------------------------Расчет av_trip--------------------------------
// Забираем MD5 из av_trip
If priznak=0 then
  begin
 ZQ.SQL.Clear;
 ZQ.SQL.Add('select md5(array_to_string(array_agg(md5(av_trip::text)),'+quotedstr('')+')) as md5 from av_trip;');
   try
     ZQ.open;
   except
         write_log('--v15-- Выполнение команды SQL - ОШИБКА !'+#13+'Команда: '+ZQ.SQL.Text);
         ZQ.Close;
         Zcon.disconnect;
         exit;
   end;
  If ZQ.RecordCount=0 then
    begin
      //write_log('Нет данных по списку локальных отрезков расписаний !!!'+#13+'Проведите повторную синхронизацию данных с ЦЕНТРАЛЬНЫМ СЕРВЕРОМ !!!');
      ZQ.Close;
      Zcon.disconnect;
      exit;
    end;

  if md5_av_trip='' then
     begin
        md5_av_trip:=ZQ.FieldByName('md5').asString;
        flag:=1;
     end
  else
    begin
      flag:=0;
      if not(trim(md5_av_trip)=trim(ZQ.FieldByName('md5').asString)) then
        begin
         md5_av_trip:=ZQ.FieldByName('md5').asString;
         flag:=1;
        end;
    end;
end;
    // ----- Если flag=1 то требуется обновление из av_trip
    if (priznak=1) OR (flag=1) then
      begin
        shcnt:=shcnt+1;
        // Запрос к av_trip
        //ZQ.Close;
        ZQ.SQL.Clear;
        //--функция возвращает список регулярных и заказных рейсов с выясненным календарным планом, наличием договора и лицензии
        ZQ.SQL.Add('select get_sound_to_nmin_trip('+quotedstr('shedule_list')+','+quotedstr(datetostr(work_date))+',1); ');
//        form1.memo1.Lines.AddStrings(ZQ.sql);
        ZQ.sql.add('FETCH ALL IN shedule_list;');

        //write_log(ZQ.sql.Text);//$
          try
            ZQ.open;
          except
             write_log('--v16-- Выполнение команды SQL - ОШИБКА !'+#13+'Команда: '+ZQ.SQL.Text);
             ZQ.Close;
             Zcon.disconnect;
             exit;
          end;
           //write_log(timetostr(time-t1));//$
          If ZQ.RecordCount=0 then
              begin
                //write_log('ОШИБКА ! Нет данных по рейсам !'+#13+'Проведите повторную синхронизацию данных с ЦЕНТРАЛЬНЫМ СЕРВЕРОМ !');
                ZQ.Close;
                Zcon.disconnect;
                exit;
              end;

        // Очищаем массив РЕГУЛЯРНЫХ рейсов в массиве из av_trip
        clear_mas(1);

        // ДОБАВЛЯЕМ В МАССИВ РЕГУЛЯРНЫЕ РЕЙСЫ
        for n:=0 to ZQ.RecordCount-1 do
          begin
            If trim(ZQ.FieldByName('id_shedule').asString)='' then continue;
            if (trim(ZQ.FieldByName('napr').asString)='1') and not(trim(ZQ.FieldByName('edet').asString)='0') then
              begin
             SetLength(Full_mas,length(Full_mas)+1,full_mas_size);
             full_mas[length(Full_mas)-1,0]:='1';  //- Тип данных в массиве 1: из av_trip (регулярный) 2: из av_trip_add (заказной)
             full_mas[length(Full_mas)-1,1]:= trim(ZQ.FieldByName('id_shedule').asString);
             full_mas[length(Full_mas)-1,2]:= trim(ZQ.FieldByName('plat').asString);
             full_mas[length(Full_mas)-1,3]:= trim(ZQ.FieldByName('ot_id_point').asString);
             full_mas[length(Full_mas)-1,4]:= trim(ZQ.FieldByName('ot_order').asString);
             full_mas[length(Full_mas)-1,5]:= trim(ZQ.FieldByName('ot_name').asString);
             full_mas[length(Full_mas)-1,6]:= trim(ZQ.FieldByName('do_id_point').asString);
             full_mas[length(Full_mas)-1,7]:= trim(ZQ.FieldByName('do_order').asString);
             full_mas[length(Full_mas)-1,8]:= trim(ZQ.FieldByName('do_name').asString);
             full_mas[length(Full_mas)-1,9]:= trim(ZQ.FieldByName('form').asString);
            full_mas[length(Full_mas)-1,10]:= trim(ZQ.FieldByName('t_o').asString);
            full_mas[length(Full_mas)-1,11]:= trim(ZQ.FieldByName('t_s').asString);
            full_mas[length(Full_mas)-1,12]:= trim(ZQ.FieldByName('t_p').asString);
            full_mas[length(Full_mas)-1,13]:= trim(ZQ.FieldByName('zakaz').asString);
            full_mas[length(Full_mas)-1,14]:= trim(ZQ.FieldByName('date_tarif').asString);
            full_mas[length(Full_mas)-1,15]:= trim(ZQ.FieldByName('id_route').asString);
            full_mas[length(Full_mas)-1,16]:= trim(ZQ.FieldByName('napr').asString);
            full_mas[length(Full_mas)-1,17]:= ZQ.FieldByName('wihod').asString;  //1:выход в рейс в текущий workdate
            full_mas[length(Full_mas)-1,18]:= ZQ.FieldByName('id_kontr').asString; //id перевозчика
            full_mas[length(Full_mas)-1,19]:= ZQ.FieldByName('name_kontr').asString; //наименование перевозчика
            full_mas[length(Full_mas)-1,20]:= ZQ.FieldByName('id_ats').asString; //№ автобуса
            full_mas[length(Full_mas)-1,21]:= ZQ.FieldByName('name_ats').asString; //наименование Автобуса
            full_mas[length(Full_mas)-1,22]:= trim(ZQ.FieldByName('edet').asString);
            full_mas[length(Full_mas)-1,23]:= trim(ZQ.FieldByName('dates').asString);
            full_mas[length(Full_mas)-1,24]:= trim(ZQ.FieldByName('datepo').asString);
            full_mas[length(Full_mas)-1,25]:= ZQ.FieldByName('all_mest').asString;  //мест всего
            full_mas[length(Full_mas)-1,26]:= ZQ.FieldByName('activen').asString;  //наличие договора /лицензии
            full_mas[length(Full_mas)-1,27]:= ZQ.FieldByName('type_ats').asString;  //тип АТС
            full_mas[length(Full_mas)-1,28]:= '0';  //состояние рейса
            full_mas[length(Full_mas)-1,29]:= '0';  //дообилечивания количество ведомостей
            full_mas[length(Full_mas)-1,30]:= '';   //дата операции
            full_mas[length(Full_mas)-1,31]:= '';   //время операции
            full_mas[length(Full_mas)-1,32]:= ''; //пользователь совершивший операцию
            full_mas[length(Full_mas)-1,33]:= ''; //описание операции
            full_mas[length(Full_mas)-1,34]:= ''; //[n,34] - kol_swob //кол-во свободных мест
            full_mas[length(Full_mas)-1,35]:= ''; //[n,35] putevka
            full_mas[length(Full_mas)-1,36]:= ''; //[n,36] driver1
            full_mas[length(Full_mas)-1,37]:= ''; //[n,37] driver2').asString);
            full_mas[length(Full_mas)-1,38]:= ''; //[n,38] driver3').asString);
            full_mas[length(Full_mas)-1,39]:= ''; //[n,39] driver4').asString);
            full_mas[length(Full_mas)-1,40]:= ZQ.FieldByName('dateactive').asString;// [n,40] - dateactive //дата начала работы расписания
            full_mas[length(Full_mas)-1,41]:= ZQ.FieldByName('dog_flag').asString;// [n,41] - dog_flag //флаг наличия договора
            full_mas[length(Full_mas)-1,42]:= ZQ.FieldByName('lic_flag').asString;// [n,42] - lic_flag //флаг наличия лицензии
            full_mas[length(Full_mas)-1,43]:= ZQ.FieldByName('kontr_flag').asString;// [n,43] - kontr_flag //флаг наличия перевозчика
            full_mas[length(Full_mas)-1,44]:= ZQ.FieldByName('ats_flag').asString;// [n,44] - ats_flag //флаг наличия автобуса
            full_mas[length(Full_mas)-1,45]:= ZQ.FieldByName('ot_id_locality').asString;// [n,45]
            full_mas[length(Full_mas)-1,46]:= ZQ.FieldByName('do_id_locality').asString;// [n,46]
            end;
            ZQ.Next;
          end;
       flag:=0;
       flag_av_trip:=true;
      end;
// --------------------------------------------------------------------------
// ----------------------------КОНЕЦ  Расчет av_trip ------------------------------
// --------------------------------------------------------------------------

// --------------------------------------------------------------------------
// ----------------------------Расчет av_trip_add----------------------------
// --------------------------------------------------------------------------
flag:=0;
If (priznak=0) AND not(flag_av_trip=true) then
  begin
// Забираем MD5 из av_trip_add
     //ZQ.Close;

     ZQ.SQL.Clear;
     //ZQ.SQL.Add('select md5(array_to_string(array_agg(md5(av_trip_add::text)),'+quotedstr('')+')) as md5 from av_trip_add;');
     ZQ.SQL.Add('Select max(createdate) as md5 FROM av_trip_add;');
       try
         ZQ.open;
       except
             write_log('--v17-- Выполнение команды SQL - ОШИБКА !'+#13+'Команда: '+ZQ.SQL.Text);
             ZQ.Close;
             Zcon.disconnect;
             exit;
       end;

     If ZQ.RecordCount=0 then
        begin
          flag:=1;
        end;

     If flag=0 then
       begin
         if (md5_av_trip_add='') then
         begin
            md5_av_trip_add:=ZQ.FieldByName('md5').asString;
            flag:=1;
         end;
         if not(md5_av_trip_add='') then
         begin
           if not(trim(md5_av_trip_add)=trim(ZQ.FieldByName('md5').asString)) then
           begin
             md5_av_trip_add:=ZQ.FieldByName('md5').asString;
             flag:=1;
           end;
         end;
       end;
  end;

  // ----- Если flag=1 то требуется обновление из av_trip_add
  if ((priznak=1) AND not flag_av_trip) OR (flag=1) then
     begin
            // Запрос к av_trip_add
            //ZQ.Close;

            ZQ.SQL.Clear;
            ZQ.SQL.Add('select * from av_trip_add where date_trip='+quotedstr(datetostr(work_date))+' order by t_o,t_p;');
//            form1.memo1.Lines.AddStrings(ZQ.sql);
            //write_log(ZQ.SQL.Text);
              try
                ZQ.open;
              except
                write_log('--v18-- Выполнение команды SQL - ОШИБКА !'+#13+'Команда: '+ZQ.SQL.Text);
                ZQ.Close;
                Zcon.disconnect;
                exit;
              end;
          flag:=0;
          If ZQ.RecordCount=0 then
                  begin
                    flag:=1;
                    ZQ.Close;
                  end;

      if flag=0 then
           begin
            // Очищаем массив статических рейсов в массиве из av_trip
            clear_mas(2);

            // ДОБАВЛЯЕМ В МАССИВ ЗАКАЗНЫЕ РЕЙСЫ
            for n:=0 to ZQ.RecordCount-1 do
              begin
               if (trim(ZQ.FieldByName('napr').asString)='1') and (trim(ZQ.FieldByName('active').asString)='1') then
                    begin
                SetLength(Full_mas,length(Full_mas)+1,full_mas_size);
                full_mas[length(Full_mas)-1,0]:='2';
                full_mas[length(Full_mas)-1,1]:= trim(ZQ.FieldByName('id_shedule').asString);
                full_mas[length(Full_mas)-1,2]:= trim(ZQ.FieldByName('plat').asString);
                full_mas[length(Full_mas)-1,3]:= trim(ZQ.FieldByName('ot_id_point').asString);
                full_mas[length(Full_mas)-1,4]:= trim(ZQ.FieldByName('ot_order').asString);
                full_mas[length(Full_mas)-1,5]:= trim(ZQ.FieldByName('ot_name').asString);
                full_mas[length(Full_mas)-1,6]:= trim(ZQ.FieldByName('do_id_point').asString);
                full_mas[length(Full_mas)-1,7]:= trim(ZQ.FieldByName('do_order').asString);
                full_mas[length(Full_mas)-1,8]:= trim(ZQ.FieldByName('do_name').asString);
                full_mas[length(Full_mas)-1,9]:= trim(ZQ.FieldByName('form').asString);
                full_mas[length(Full_mas)-1,10]:= trim(ZQ.FieldByName('t_o').asString);
                full_mas[length(Full_mas)-1,11]:= trim(ZQ.FieldByName('t_s').asString);
                full_mas[length(Full_mas)-1,12]:= trim(ZQ.FieldByName('t_p').asString);
                full_mas[length(Full_mas)-1,13]:= trim(ZQ.FieldByName('zakaz').asString);
                full_mas[length(Full_mas)-1,14]:= trim(ZQ.FieldByName('date_tarif').asString);
                full_mas[length(Full_mas)-1,15]:= trim(ZQ.FieldByName('id_route').asString);
                full_mas[length(Full_mas)-1,16]:= trim(ZQ.FieldByName('napr').asString);
                full_mas[length(Full_mas)-1,17]:= '1';//выход в рейс
                full_mas[length(Full_mas)-1,22]:= trim(ZQ.FieldByName('edet').asString);
                full_mas[length(Full_mas)-1,23]:= trim(ZQ.FieldByName('dates').asString);
                full_mas[length(Full_mas)-1,24]:= trim(ZQ.FieldByName('datepo').asString);
                full_mas[length(Full_mas)-1,25]:= '0';  //мест всего
                full_mas[length(Full_mas)-1,26]:= '1';  //флаг активности опп
                full_mas[length(Full_mas)-1,27]:= '0';  //тип АТС
                full_mas[length(Full_mas)-1,28]:= '0';  //состояние рейса
                full_mas[length(Full_mas)-1,29]:= '0';  //дообилечивания количество ведомостей
                full_mas[length(Full_mas)-1,30]:= '';   //дата операции
                full_mas[length(Full_mas)-1,31]:= '';   //время операции
                full_mas[length(Full_mas)-1,32]:= ''; //пользователь совершивший операцию
                full_mas[length(Full_mas)-1,33]:= ''; //описание операции
                full_mas[length(Full_mas)-1,34]:= ''; //кол-во свободных мест
                full_mas[length(Full_mas)-1,35]:= ''; //[n,35] putevka
                full_mas[length(Full_mas)-1,36]:= ''; //[n,36] driver1
                full_mas[length(Full_mas)-1,37]:= ''; //[n,37] driver2').asString);
                full_mas[length(Full_mas)-1,38]:= ''; //[n,38] driver3').asString);
                full_mas[length(Full_mas)-1,39]:= ''; //[n,39] driver4').asString);
                full_mas[length(Full_mas)-1,40]:= '';// [n,40] - dateactive //дата начала работы расписания
                full_mas[length(Full_mas)-1,41]:= '1';// [n,41] - dog_flag //флаг наличия договора
                full_mas[length(Full_mas)-1,42]:= '1';// [n,42] - lic_flag //флаг наличия лицензии
                full_mas[length(Full_mas)-1,43]:= '1';// [n,43] - kontr_flag //флаг наличия перевозчика
                full_mas[length(Full_mas)-1,44]:= '1';// [n,44] - ats_flag //флаг наличия автобуса
               end;
                ZQ.Next;
            end;
//            flag_av_trip_add:=true;
           end;
      flag:=0;
        end;
// --------------------------------------------------------------------------
// ----------------------------Конец Расчет av_trip_add-----------------------
// ---------------------------------------------------------------------------
// --------------------------------------------------------------------------
// ----------------------------Расчет MD5 для  av_disp_oper -----------------
// --------------------------------------------------------------------------
flag:=0;
If priznak=0 then
  begin
// Забираем MD5 для av_disp_oper
 //ZQ.Close;

 ZQ.SQL.Clear;
 //zq.SQL.Add('select md5(array_to_string(array_agg(md5(av_disp_oper::text)),'''''''')) as md5 from av_disp_oper;');
 ZQ.SQL.Add('Select max(createdate) as md5 FROM av_disp_oper;');
 try
     ZQ.open;
 except
     write_log('--v19-- Выполнение команды SQL - ОШИБКА !'+#13+'Команда: '+ZQ.SQL.Text);
        ZQ.Close;
        Zcon.disconnect;
        exit;
 end;
  If Zq.RecordCount=0 then
   begin
  //    write_log(zq.SQL.Text);
      //write_log('Справочник операций диспетчера пуст  !!!');
      ZQ.Close;
      Zcon.disconnect;
      exit;
   end;

  if md5_operation='' then
     begin
        md5_operation:=trim(ZQ.FieldByName('md5').asString);
        flag:=1;
     end
  else
    begin
      flag:=0;
      if not((md5_operation)=trim(ZQ.FieldByName('md5').asString)) then
        begin
         md5_operation:=ZQ.FieldByName('md5').asString;
         flag:=1;
        end;
    end;
end;

// ----- Если flag=1 или priznak=1 (принудительно) то требуется обновление из av_disp_oper
if (priznak=1) or (flag=1) then
      begin
        dispcnt:=dispcnt+1;

        // Запрос к av_disp_oper
        //ZQ.Close;
        if Zcon.Connected then
         begin
        ZQ.SQL.Clear;
        ZQ.SQL.Add('SELECT a.trip_date,a.vid_sriva,a.remark,a.avto_type,a.avto_seats,a.avto_name,a.atp_name,');
        ZQ.SQL.Add('a.driver4,a.driver3,a.driver2,a.driver1,a.trip_flag,a.putevka,a.platform,a.avto_id,a.trip_id_point,');
        ZQ.SQL.Add('a.point_order,a.id_point_oper,a.trip_time,a.trip_type,a.createdate,a.id_user,a.atp_id,a.id_oper,a.id_shedule,'+quotedstr('')+' as name');
        ZQ.SQL.Add('from av_disp_oper a WHERE a.del=0 AND');
        ZQ.SQL.Add('a.trip_date='+Quotedstr(datetostr(work_date))+' AND a.id_point_oper='+ConnectINI[14]);
        ZQ.SQL.Add('order by a.createdate,a.trip_time;');
//        write_log(zq.SQL.text);
          try
            ZQ.open;
          except
             write_log('--v20-- Выполнение команды SQL - ОШИБКА !'+#13+'Команда: '+ZQ.SQL.Text);
            ZQ.Close;
            Zcon.disconnect;
            exit;
          end;
         end
        else
         begin
          exit;
         end;

//=======================================================
//============  СОСТОЯНИЯ РЕЙСА   =======================
//0 - НЕОПРЕДЕЛЕНО (ОТКРЫТ)
//1 - ДООБИЛЕЧИВАНИЕ (ОТКРЫТ) повторно
//2 - ОТМЕЧЕН КАК ПРИБЫВШИЙ
//3 - ОТМЕЧЕН КАК ОПАЗДЫВАЮЩИЙ (ОТКРЫТ)
//4 - ОТПРАВЛЕН (Закрыт)
//5 - СРЫВ ПО ВИНЕ АТП (ЗАКРЫТ)
//6 - ЗАКРЫТ ПРИНУДИТЕЛЬНО
//====================================================
            // [n,18] - id_kontr
            // [n,19] - name_kontr
            // [n,20] - id_ats
            // [n,21] - name_ats
            // [n,22] - edet
            // [n,23] - dates
            // [n,24] - datepo
            // [n,25] - all_mest
            // [n,26] - activen
            // [n,27] - type_ats
            // [n,28] - trip_flag   //состояние рейса
            // [n,29] - doobil
            // [n,30] - oper_date   //дата операции
            // [n,31] - oper_time   //время операции
            // [n,32] - oper_user   //пользователь совершивший операцию
            // [n,33] - oper_remark //описание операции
         If Zq.RecordCount>0 then
              begin
          For m:=1 to Zq.RecordCount do
            begin
              for n:=low(full_mas) to high(full_mas) do
                begin
                  //находим все рейсы измененного расписания
                  IF (full_mas[n,1]=Zq.FieldByName('id_shedule').AsString) then
                    begin
                   //находим конкретный рейс
                   If (full_mas[n,16]=Zq.FieldByName('trip_type').AsString) then
                    begin
                      //если рейс отправления
                      If  ((Zq.FieldByName('trip_type').AsInteger=1) AND
                          (full_mas[n,10]=Zq.FieldByName('trip_time').AsString) AND
                          (full_mas[n,3]=Zq.FieldByName('trip_id_point').AsString) AND
                          (full_mas[n,4]=Zq.FieldByName('point_order').AsString)) OR
                      //или если рейс прибытия
                           ((Zq.FieldByName('trip_type').AsInteger=2) AND
                           (full_mas[n,12]=Zq.FieldByName('trip_time').AsString) AND
                           (full_mas[n,6]=Zq.FieldByName('trip_id_point').AsString) AND
                           (full_mas[n,7]=Zq.FieldByName('point_order').AsString)) then
                             begin
                                full_mas[n,2] := trim(zq.FieldByName('platform').asString);
                                full_mas[n,18]:= trim(zq.FieldByName('atp_id').asString);
                                full_mas[n,19]:= trim(zq.FieldByName('atp_name').asString);
                                full_mas[n,20]:= trim(zq.FieldByName('avto_id').asString);
                                full_mas[n,21]:= trim(zq.FieldByName('avto_name').asString);
                                full_mas[n,25]:= trim(zq.FieldByName('avto_seats').asString);
                                full_mas[n,27]:= trim(zq.FieldByName('avto_type').asString);
                                full_mas[n,28]:= trim(zq.FieldByName('trip_flag').asString);
                                full_mas[n,30]:= FormatDateTime('dd-mm-yyyy',zq.FieldByName('createdate').AsDateTime);
                                full_mas[n,31]:= FormatDateTime('hh:nn:ss',zq.FieldByName('createdate').AsDateTime);
                                full_mas[n,32]:= trim(zq.FieldByName('name').asString);
                                full_mas[n,33]:= trim(zq.FieldByName('remark').asString);
                                full_mas[n,35]:= trim(zq.FieldByName('putevka').asString);
                                full_mas[n,36]:= trim(zq.FieldByName('driver1').asString);
                                full_mas[n,37]:= trim(zq.FieldByName('driver2').asString);
                                full_mas[n,38]:= trim(zq.FieldByName('driver3').asString);
                                full_mas[n,39]:= trim(zq.FieldByName('driver4').asString);
                             end;
                        //If (full_mas[n,1]='54') AND (full_mas[n,13]='1') then
                          //write_log(full_mas[n,1]+full_mas[n,19]+full_mas[n,21]);
                    end;
//если рейс закрыт или сорван, то связанные рейсы пропускаем
                   IF zq.FieldByName('trip_flag').AsInteger=5 then continue;
                   IF zq.FieldByName('trip_flag').AsInteger=6 then continue;
//если связанный рейс закрыт, пропускаем
                   If full_mas[n,28]='4' then continue;
                   If full_mas[n,28]='5' then continue;
                   If full_mas[n,28]='6' then continue;
//корректируем связанные рейсы
                 tn :=0; //время отправления/прибытия по графику
                 tm :=0; //время отправления/прибытия фактическое
//если рейс отправления
                   If (full_mas[n,16]='1') then
                     begin
                       try
                         tn := strtoint(copy(full_mas[n,10],1,2)+copy(full_mas[n,10],4,2));
                       except
                         on exception: EConvertError do continue;
                       end;
                     end;
//если рейс прибытия
                   If (full_mas[n,16]='2') then
                     begin
//если время прибытия больше, чем в операции
                       try
                         tn := strtoint(copy(full_mas[n,12],1,2)+copy(full_mas[n,12],4,2));
                       except
                         on exception: EConvertError do continue;
                       end;
                      end;
                try
                   tm := strtoint(copy(zq.FieldByName('trip_time').AsString,1,2)+copy(zq.FieldByName('trip_time').AsString,4,2));
                except
                   on exception: EConvertError do continue;
                end;

//если время отправления/прибытия больше, чем в операции
                       If (tn>tm) AND (tn>0) AND (tm>0) then
                         begin
                           full_mas[n,2]:= trim(zq.FieldByName('platform').asString);
                           full_mas[n,18]:= trim(zq.FieldByName('atp_id').asString);
                           full_mas[n,19]:= trim(zq.FieldByName('atp_name').asString);
                           full_mas[n,20]:= trim(zq.FieldByName('avto_id').asString);
                           full_mas[n,21]:= trim(zq.FieldByName('avto_name').asString);
                           full_mas[n,25]:= trim(zq.FieldByName('avto_seats').asString);
                           full_mas[n,27]:= trim(zq.FieldByName('avto_type').asString);
                           full_mas[n,30]:= FormatDateTime('dd-mm-yyyy',zq.FieldByName('createdate').AsDateTime);
                           full_mas[n,31]:= FormatDateTime('hh:nn:ss',zq.FieldByName('createdate').AsDateTime);
                           full_mas[n,32]:= trim(zq.FieldByName('name').asString);
                           full_mas[n,33]:= trim(zq.FieldByName('remark').asString);
                           full_mas[n,35]:= trim(zq.FieldByName('putevka').asString);
                           full_mas[n,36]:= trim(zq.FieldByName('driver1').asString);
                           full_mas[n,37]:= trim(zq.FieldByName('driver2').asString);
                           full_mas[n,38]:= trim(zq.FieldByName('driver3').asString);
                           full_mas[n,39]:= trim(zq.FieldByName('driver4').asString);
                         end;
                    end;
                end;
             zq.Next;
            end;

           // ============================= ПРОСТАВЛЯЕМ ВЕДОМОСТИ ДООБИЛЕЧИВАНИЯ =================================
         // Запрос к av_disp_oper
          //zq.Close;
          zq.SQL.Clear;
          zq.SQL.Add('select * from av_disp_oper WHERE trip_date='+Quotedstr(datetostr(work_date))+' AND id_point_oper='+ConnectINI[14]+' and trip_flag=1 order by trip_time;');
          try
            zq.open;
          except
             write_log('--v21-- Выполнение команды SQL - ОШИБКА !'+#13+'Команда: '+ZQ.SQL.Text);
             zq.Close;
             zcon.disconnect;
             exit;
          end;
          If zq.RecordCount>0 then
              begin
               for n:=0 to length(full_mas)-1 do
            begin
               kol_wed:=0;
               for m:=1 to zq.RecordCount do
                 begin
                   //только рейсы отправления
                   If trim(full_mas[n,16])='1' then
                      begin
                         if (trim(full_mas[n,1])=trim(zq.FieldByName('id_shedule').asstring)) and
                    (trim(zq.FieldByName('trip_time').asstring)=trim(full_mas[n,10]))  then
                       begin
                         kol_wed:=kol_wed+1;
                       end;
                      end;
                   zq.Next;
                 end;
               full_mas[n,29]:=inttostr(kol_wed);

            end;
              end;

      end;
    end;
   // --------------------------------------------------------------------------
   // ----------------------------КОНЕЦ Расчет av_disp_oper -----------------
   // --------------------------------------------------------------------------
   ZQ.Close;
   Zcon.Disconnect;
end;

// Очищаем блоки из full_mas по флагу 1-av_trip 2-av_trip_add full_mas[n,0];
procedure clear_mas(flag_clear:byte);
  var
    n,m:integer;
    //full_mas_temp:array of array of string;
    arrtmp: array of array of string;
begin
   // Если массив пустой то нечего очищать
   if length(full_mas)=0 then exit;
   SetLength(arrtmp,0,0);
   // В цикле добавляем записи которые нужно сохранить во временный массив
   for n:=low(full_mas) to high(full_mas) do
     begin
      if trim(full_mas[n,0])<>inttostr(flag_clear) then
       begin
         SetLength(arrtmp,length(arrtmp)+1,full_mas_size);
            for m:=0 to full_mas_size-1 do
              begin
                arrtmp[length(arrtmp)-1,m]:=full_mas[n,m];
              end;
        end;
     end;
   SetLength(full_mas,0,0);
   If length(arrtmp)=0 then exit;
    //перезаписываем массив
   for n:=low(arrtmp) to high(arrtmp) do
     begin
       SetLength(full_mas,length(full_mas)+1,full_mas_size);
       for m:=0 to full_mas_size-1 do
         begin
           full_mas[length(full_mas)-1,m]:=arrtmp[n,m];
         end;
     end;
   SetLength(arrtmp,0,0);
   arrtmp:=nil;
   write_log('stop');
end;

end.

