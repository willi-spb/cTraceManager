unit u_wmadExcept;
 ///
 ///  Willi   --  Надстройка над madExcept
 ///
 ///     задача класса-переменной - использовать список собственных параметров в сообщении
 ///     параметры содержат Имя, значение, вид логирования - в таком виде они видны в maxEception
 ///     удаление параметра выбрасывает его из списка
 ///
 ///     DT: 25.08.2014 добавил логирование в некий файл - задается командой SetLogParams - режим 0 (по умолч не логировать)
 ///
 ///     Особенность:  если стоит фиксация wTrace по таймеру - нежелательно этот момент логировать,
 ///                   поэтому в каждой точке может отключать логирование в файл (только если оно вообще включено)
 ///
 ///     Использую Generic - список
 ///
 ///    СИНГЛЕТОН!   - должен быть 1 объект
interface

{$IFDEF FMX}
  {$DEFINE RG_FMX}
{$ENDIF}

 uses classes, Windows,
      System.Generics.Collections,
     madExcept;

type

  twTracePoint=record
    trName,trValue:string;
    trTime:TDateTime;
    trLogRegime:Integer;
    trSituation:Integer; //по умолч =0,
               // но для Debug для ситуации  =1 -если это SetPt первый,
               // 2,3 - номер SetPt,        =-1 если это DeletePt
  end;

  twAddAttachmentItem=record
    imIndex:Integer;
    imFilename:UnicodeString;
    imSendFilename:string;
    imzipFile:string;
    imFieldName:string;
  end;

/// <summary>
///     событие по ошибке (например для аналитики и т.д.)
///  trcItemsText - для списка выводим в строку все наборы TracePointToLogStr
///  const exClass,exMessage,trcHeader,trcItemsText:String;
/// </summary>
TwExceptEvent=procedure(TraceObj:TObject; const aData:TStrings) of object;

////////////////////////////////////////////////////////////////////////////////////
///
///   скрытый уведомитель
///
///  (для него запись для хранения настроек)
 T_wExceptDataRecord=record
   d_MailAddr:string;
   d_MailAsSmtpClient:Boolean;
   d_MailAsSmtpServer:Boolean;
   d_SmtpServer:string;
   d_SmtpAccount:string;
   d_SmtpPassword:string;
   ///
   d_SendInBackground,
    // exceptIntf.AutoDelay:=0;
   d_ShowPleaseWaitBox,
   d_AutoShowBugReport,
   d_AutoSendPrgrBox,
   d_AutoContinue:Boolean;
 end;
///
///
  twHiddenTrace=class(TObject)
     private
       currDataRecord:T_wExceptDataRecord;
       MEexept:IMEException;
      FEnabled:Boolean;
      ///
      FMailAddr,FsmtpServer,FsmtpLogin,FsmtpPassStr:string;
      ///
      procedure SetEnabled(value:Boolean);
     protected
      hd_Num:Integer;
      hd_Msg:string; /// для скрытых ошибок при их вызове
     ///
     public
      constructor Create;
      destructor destroy; override;
      procedure SetMailParams(const aMailAddr,asmtpServer,asmtpLogin,asmtpPassStr:string);
      procedure Call;
      property Enabled:Boolean read FEnabled write SetEnabled;
      property MailAddr:string read FmailAddr;
      property smtpServer:string read FsmtpServer;
      property smtpLogin:string read FsmtpLogin;
      property smtpPassStr:string read FsmtpPassStr;
  end;


////////////////////////////////////////////////////////////////////////////////////
///
///   основной
///
  twTrace=class(TObject)
    private
     FHomeTime:TDateTime;
     Frepeated:Boolean; // true - отсылаются ВСЕ ошибки от пользователя -  false - оценивается мин. интервал между ошибками
     FRepeatInterval:integer; ///  в секундах !
     FLogFilename:string;
     FEnabled:boolean;
     procedure SetBugReportName(const Value:string);
     function GetBugReportname:string;
     function getPString:string;
    protected
     fin_exFlag:Boolean;  ///  true - если мы внутри вызова доп. процедуры обработки
     FLogRegime:integer;
     FRTL:TRTLCriticalSection; // только для Лога
     ///
     function AddToLog(const ALogText:string; const ALogClear:Boolean=False):Boolean; virtual;
     /// <summary>
     ///     если DebugRegime>0 то вызывается этот метод (при SetPt)
     /// </summary>
     procedure DebugExecute(Value:twTracePoint);
    public
      FirstExceptFlag:boolean; // исп. при расчете интервала ошибок -- вначале true - т.к. первая ошибка всегда должна посылаться
      LastTickCount:int64;
     ///
     HiddenException:twHiddenTrace;
     ///
     dValue:string;
     items:TList<twTracePoint>;
          /// <summary> список имен файлов - дополнение к репорту 0 - не добавлять (по умолч.) </summary>
     AttachmentItems:TList<twAddAttachmentItem>;
     ///
     /// <summary>
     ///    указатель на событие (или процедуру), которое выполняется
     ///    в момент вызова исключения
     /// </summary>
     exEvent:TwExceptEvent;
     exProc:procedure();
     ///
     /// <summary>
     ///     для дебага >0 значит идет вызов процедуры с параметрами Exception
     /// </summary>
     DebugRegime:Integer;
     ///
     /// <summary>
     ///     записать кратко данные по точке в строку
     /// </summary>
     function TracePointToLogStr(alRegime:Integer; const aTrPt:twTracePoint):string;
     /// <summary>
     ///     записать кратко данные по списку всех точек в длинную строку с заделителем ;
     /// </summary>
     function TracePointsToText(alRegime:Integer; const aDivider:string=';'):string;
     ///
     constructor Create(aregime:integer);
     destructor destroy; override;
     /// задать параметры для логирования 0 - логирование будет выключено
     ///  Рекомендуется вызывать 1 раз
     function SetLogParams(aLogRegime:Integer; const ALogFileName:string; AClearFlag:boolean):Boolean;
       ///  для удобства форматирования - только добавление в ЛОГ
     function AddPairToLog(const apairName,apairValue:string):boolean; virtual;
     ///
     ///  вызов скрытого исключения
     ///  aCaption="" - то используется заголовок от обычного исключения - иначе - строка
     ///  если в ней есть символ * - вместо него подставляем заголовок MESEttings
     procedure HiddenCall(ahType:Integer; const aCaption,aMsg:string);
     ///
     ///
     procedure SetPt(const aptName,aValue:string; apLogFlag:Boolean=true); virtual;
     procedure DeletePt(const aptName:string);  virtual;
     /// если не существует - вернет значение с пустым именем
     function GetPtFromName(const aptName:string):twTracePoint; virtual;
     /// <summary>
     ///     добавление файла в репорт -
     /// (добавляет запись о файле, далее перебор записей на момент возникн. исключения
     ///  false - файла нет
     /// </summary>
     function AddAttachmentItem(const aFileName:string; const ASendname:string=''):Boolean;
     ///
     ///   имя письма - меняется со стандартно-заданного на заданное в программе динамически, например ID+date
     property BugReportName:string read GetBugReportName write SetBugReportname;
     ///  по логам:
     property LogRegime:Integer read FLogRegime write FLogRegime;
     property LogFilename:string read FLogFilename;
     property SendRepeated:boolean read Frepeated write Frepeated default false;
     property RepeatInterval:integer read FRepeatInterval write FRepeatInterval default 5;
     property p_Str:string read getPString;
     property Enabled:boolean read FEnabled write FEnabled default true;
  end;
///////////////////////////////////////////////////////////////////////////////////////////////////////


var wTrace:twTrace;


var  wTrace_FormatMessageSign:integer=1;  /// форматировать ошибку по строчкам или просто выводить текст в строку =0
      ///  используется свойство диалога Mad

//  отключить включить отправку по почте репорта
//  отключить - вызов:  mad_SetReportState(False);
//
procedure mad_SetReportState(aMailSendFlag:Boolean);
//
//  замена настроек почты при отправке (для RunTime)
procedure mad_SetReportMailSMTPSettings(const mAddr,smtpSrvr,aLogin,aPassStr:string; const MESett:IMESettings=nil);
///
///
///   в дополнение
///  Вернуть каталог юзера ( Папка Пользователи и т.д. внутрь)   0 - сообщ ошибок не выводить 1 - в окне диалога
///  при неудаче возвращает ''
function mGetUserDataDirectory(agetRG:integer; const dAppName:string=''):string;

/// доп функционал
///  узнать грин время
  function mLocalTimeToUTC(AValue: TDateTime): TDateTime;
  function mUTCToLocalTime(AValue: TDateTime): TDateTime;
///
///   декодировать дату из строки  поля date/time  формат: 2015-01-12, 18:55:52, 515ms
  function _mExtractDatetimeFromField(const AStr:String):Tdatetime;

implementation

uses Sysutils,
     IOUtils,
     {$IFDEF FMX}
     FMX.Dialogs,System.UITypes;
     {$ELSE}
        VCL.Dialogs;
     {$ENDIF}


function _GetPerformanceTickCount: Int64;
 var
  f: Int64;
  c: Int64;
 begin
  QueryPerformanceFrequency(f);
  QueryPerformanceCounter(c);
  if f>0 then
       Result :=Abs( c div f)
  else Result:=1;
 end;

function mFormatExceptString(const AErrorMessage,aErrorClass:String):string;
var LLIst:TStrings;
    LR:string;
 begin
   Result:=AErrorMessage;
   LLIst:=TStringList.Create;
   try
    LList.LineBreak:='. ';
    LList.Text:=AErrorMessage;
    Result:='';
    /// удалить последнюю точку в тексте ошибки (если она есть)
    try
    if LLIst.Count>0 then begin
      LR:=Trim(LList.Strings[LList.Count-1]);
      if (Length(LR)>0) and (LR[Length(LR)]='.') then
        begin
         LR[Length(LR)]:=' ';
         LList.Strings[LList.Count-1]:=Trim(LR);
        end;
     end;
     except
    end;
    ///
    LList.LineBreak:=Concat('.',#13#10);
    Result:=LList.Text;
    if Result='' then Result:=AErrorMessage;
    ///
    if (aErrorClass<>'') and (aErrorClass='EAccessViolation') and (aErrorClass<>'Exception') then
       Result:=Concat(Result,'(class:',aErrorClass,')');
    ///
   finally
     LList.Free;
   end;
 end;

// дополнит функции
function mLocalTimeToUTC(AValue: TDateTime): TDateTime;
// AValue - локальное время
// Result - время UTC
var
  ST1, ST2: TSystemTime;
  TZ: TTimeZoneInformation;
begin
  // TZ - локальные (Windows) настройки
  GetTimeZoneInformation(TZ);
  // т.к. надо будет делать обратное преобразование - инвертируем bias
  TZ.Bias := -TZ.Bias;
  TZ.StandardBias := -TZ.StandardBias;
  TZ.DaylightBias := -TZ.DaylightBias;

  DateTimeToSystemTime(AValue, ST1);

  // Применение локальных настроек ко времени
  SystemTimeToTzSpecificLocalTime(@TZ, ST1, ST2);

  // Приведение WindowsSystemTime к TDateTime
  Result := SystemTimeToDateTime(ST2);
end;

function mUTCToLocalTime(AValue: TDateTime): TDateTime;
// AValue - время UTC
// Result - время с учётом локального GMT-смещения и правилами перехода на летнее время
var
  ST1, ST2: TSystemTime;
  TZ: TTimeZoneInformation;
begin
  // TZ - локальные настройки Windows
  GetTimeZoneInformation(TZ);
  // Преобразование TDateTime к WindowsSystemTime
  DateTimeToSystemTime(AValue, ST1);
  // Применение локальных настроек ко времени
  SystemTimeToTzSpecificLocalTime(@TZ, ST1, ST2);
  // Приведение SystemTime к TDateTime
  Result := SystemTimeToDateTime(ST2);
end;


function _mExtractDatetimeFromField(const AStr:String):Tdatetime;
var LList:TStrings;
    LS:String;
 begin
   Result:=Now;
   LList:=TStringList.Create;
   try
    LList.CommaText:=Astr;
    if LList.Count=0 then exit;
    LS:=Trim(LList.Strings[0]);
    if LList.Count>1 then LS:=Concat(LS,' ',Trim(LLIst.Strings[1]));
    if LList.Count>2 then LS:=Concat(LS,',',Trim(LLIst.Strings[2]));
    Result:=StrToDateTimeDef(LS,Result);
   finally
    LList.Free;
   end;
 end;

/////////////////////////////////////////////////////////////////////////////////

function mGetUserDataDirectory(agetRG:integer; const dAppName:string=''):string;
var LDir:string;
    LFlag:Boolean;
 begin
  Result:='';
  LFlag:=True;
  LDir := TPath.GetHomePath + TPath.DirectorySeparatorChar + dAppName;
  ForceDirectories(LDir);
  if DirectoryExists(LDir)=False then
     try
        if CreateDir(LDir)=False then
         begin
          // raise Exception.Create('Not Create Directory:'+LDir);
           {$IFDEF RG_FMX}
            if agetRG=1 then
               MessageDlg('Error (in  mGetUserDataDirectory) - not create Directory '+LDir,
                          TMsgDlgType.mtError,
                           [TMsgDlgBtn.mbOk],0);
           {$ELSE}
             if agetRG=1 then MessageDlg('Error (in  mGetUserDataDirectory) - not create Directory '+LDir,mtError,[mbOk],0);
           {$ENDIF}
          LFlag:=False;
         end;
     except  on E : Exception do
      begin
        LFlag:=False;
        {$IFDEF RG_FMX}
          if agetRG=1 then MessageDlg(E.ClassName+' (in  mGetUserDataDirectory) - message: '+E.Message,
                                     TMsgDlgType.mtError,[TMsgDlgBtn.mbOk],0);
        {$ELSE}
       if agetRG=1 then MessageDlg(E.ClassName+' (in  mGetUserDataDirectory) - message: '+E.Message,mtError,[mbOk],0);
        {$ENDIF}
      end;
     end;
  if LFlag=true then
     Result:=LDir;
 end;

 //////////////////////////////////////////////////////////////////

 procedure mad_CopyReportMailSMTPSettings(var aRec:T_wExceptDataRecord);
 begin
  with aRec,MESettings do
   begin
     d_MailAddr:=MailAddr;
     d_MailAsSmtpClient:=MailAsSmtpClient;
     d_MailAsSmtpServer:=MailAsSmtpServer;
     d_SmtpServer:=smtpServer;
     d_SmtpAccount:=SmtpAccount;
     d_SmtpPassword:=SmtpPassword;
     ///
     d_SendInBackground:=SendInBackground;
    // exceptIntf.AutoDelay:=0;
     d_ShowPleaseWaitBox:=ShowPleaseWaitBox;
     d_AutoShowBugReport:=AutoShowBugReport;
     d_AutoSendPrgrBox:=AutoSendPrgrBox;
     d_AutoContinue:=AutoContinue;
   end;
 end;

procedure mad_ResetReportMailSMTPSettings(const aRec:T_wExceptDataRecord);
 begin
  with aRec,MESettings do
   begin
     MailAddr:=d_MailAddr;
     MailAsSmtpClient:=d_MailAsSmtpClient;
     MailAsSmtpServer:=d_MailAsSmtpServer;
     SmtpServer:=d_smtpServer;
     SmtpAccount:=d_SmtpAccount;
     SmtpPassword:=d_SmtpPassword;
     ///
     SendInBackground:=d_SendInBackground;
    // exceptIntf.AutoDelay:=0;
     ShowPleaseWaitBox:=d_ShowPleaseWaitBox;
     AutoShowBugReport:=d_AutoShowBugReport;
     AutoSendPrgrBox:=d_AutoSendPrgrBox;
     AutoContinue:=d_AutoContinue;
   end;
 end;

//////////////////////////////////////////////////////////////////////////////   Event for Hidden
 procedure HiddenHeaderInfo(const exceptIntf : IMEException;
                                      var handled      : boolean);
var il:Integer;
    LS:string;
    LV:twTracePoint;
    LList:TStrings;
begin
 //  exceptIntf.BugReportHeader['command line'] := '';
  if Assigned(wTrace) then
     begin
       exceptIntf.ExceptMessage:=wTrace.HiddenException.hd_Msg;
       exceptIntf.BugReportHeader['w_HTYPE'] :=IntToStr(wTrace.HiddenException.hd_Num);
       exceptIntf.BugReportHeader['w_HIDDEN_Trace'] :='TRUE';
       if wTrace.dValue<>'' then exceptIntf.BugReportHeader['wTrace'] :=wTrace.dvalue;
       ///
       il:=0;
       while il<wTrace.items.Count do
        begin
          LV:=wTrace.items.Items[il];
          exceptIntf.BugReportHeader[LV.trName]:=LV.trValue;
          Inc(il);
        end;
        ///
        if wTrace.fin_exFlag=False then
         begin   ///  условие чтобы убрать рекурсию
           wTrace.fin_exFlag:=True;
           LList:=TStringList.Create;
           try
             LList.Add('class='+exceptIntf.ExceptClass);
             LList.Add('message='+exceptIntf.ExceptMessage);
             LList.Add('subject='+MESettings.MailSubject);
             LList.Add('points='+wTrace.TracePointsToText(1));
             LList.Add('hidden=0');
             ///
             if Assigned(wTrace.exProc) then wTrace.exProc();
             if Assigned(wTrace.exEvent) then
               wTrace.exEvent(wTrace,LList);
            finally
              LList.Free;
              wTrace.fin_exFlag:=False;
           end;
         end;
        ///
        ///
     end;
     exceptIntf.SendInBackground:=true;
    // exceptIntf.AutoDelay:=0;
     exceptIntf.ShowPleaseWaitBox:=False;
     exceptIntf.AutoShowBugReport:=False;
     exceptIntf.AutoSendPrgrBox:=False;
     exceptIntf.AutoContinue:=True;
     ///  настройки
     with wTrace.HiddenException do
        mad_SetReportMailSMTPSettings(MailAddr,smtpServer,smtpLogin,smtpPassStr,exceptIntf);
     ///
     exceptIntf.GetBugReport(true);  /// ждать
     ///
     LS:='';
     il:=0;
     try
        exceptIntf.BugReportSections.Lock;
        while il<exceptIntf.BugReportSections.ItemCount do
          begin
            // LS:=Concat(LS,#13#10, exceptIntf.BugReportSections.Items[il]);
             if il>0 then
               exceptIntf.BugReportSections.Delete(il)
             else
               Inc(il);
          end;
     finally
        exceptIntf.BugReportSections.Unlock;
     end;
     ///
   {  LS:=Concat(IntToStr(exceptIntf.BugReportSections.ItemCount),LS);
     ShowMessage(LS);
     ShowMessage(exceptIntf.BugReportSections.Contents['hardware']);
     }
     exceptIntf.SendBugReport();
     ///
    handled:=True; //  !!
   //  exceptIntf.BugReportHeader['Info1'] :='hhhh';
end;


///////////////////////////////////////////////////////
///
///    twHiddenTrace
///
 constructor twHiddenTrace.Create;
  begin
   FEnabled:=False;
   MEexept:=NIL;
   MEexept:=NewException(etHidden,Self,nil,True,0,0,0,nil,MESettings,esManual,nil,0,'',false,nil);
  // MEexept.ExceptClass:='EHiddenTraceManualException';
  // MEexept.ExceptMessage:='manual call in hiddenException';
  end;

 destructor twHiddenTrace.destroy;
  begin
   inherited Destroy;
  end;

 procedure  twHiddenTrace.SetMailParams(const aMailAddr,asmtpServer,asmtpLogin,asmtpPassStr:string);
  begin
   FMailAddr:=aMailAddr;
   FsmtpServer:=asmtpServer;
   FsmtpLogin:=asmtpLogin;
   FsmtpPassStr:=asmtpPassStr;
  end;

  procedure twHiddenTrace.Call;
   begin
      HandleException(etHidden,MEexept.ExceptObject);
     //  MEexept.SendBugReport();
   end;

  procedure twHiddenTrace.SetEnabled(value:Boolean);
   begin
     if value=true then
      try
        mad_CopyReportMailSMTPSettings(currDataRecord);
        RegisterHiddenExceptionHandler(HiddenHeaderInfo, stDontSync);// stTrySyncCallAlways);
        FEnabled:=True;
      finally
      end
     else
      try
       if UnregisterHiddenExceptionHandler(HiddenHeaderInfo)=True then
          FEnabled:=False;
       mad_ResetReportMailSMTPSettings(currDataRecord);
      finally
      end;
   end;


///////////////////////////////////////////////////////////////////////////////////////////
//
//
//
 procedure twTrace.SetBugReportName(const Value:string);
  begin
    MESettings.MailSubject:=Value;
  end;

 function twTrace.GetBugReportname:string;
  begin
    Result:=MESettings.MailSubject;
  end;

 function twTrace.getPString:string;
  begin
    Result:=MESettings.SmtpPassword;
  end;

function twTrace.AddToLog(const ALogText:string; const ALogClear:Boolean=False):Boolean;
 var
  LStr:AnsiString;
  LFile:TextFile;
begin
  if Not(FEnabled) then exit;
  try
    try
      EnterCriticalSection(FRTL);
      Result:=True;
      LStr:=FLogFilename;
      AssignFile(LFile,LStr);
      if (FileExists(LStr)=True) and (ALogClear=false) then
          Append(LFile)
      else
          Rewrite(LFile);
      if (FLogRegime>=1) then
          LStr:=Format('%s - %s',[FormatDateTime('dd.mm.yy hh:nn:ss.zzz',Now),ALogText]);
      Writeln(LFile,LStr);
    finally
      CloseFile(LFile);
      LeaveCriticalSection(FRTL);
    end;
  except
    Result:=False;
  end;
 end;

 procedure twTrace.DebugExecute(Value:twTracePoint);
 var LS:string;
  begin
     if Not(FEnabled) then exit;
     if DebugRegime=1 then
      begin
        LS:=TracePointToLogStr(DebugRegime,Value);
       {$IFDEF DEBUG}
        OutputDebugString(PWideChar(LS));
        {$ENDIF}
      end;
    {
    if Assigned(DoDebugUpdate) then
       DoDebugUpdate(
    }
  end;

  function twTrace.TracePointToLogStr(alRegime:Integer; const aTrPt:twTracePoint):string;
  var Ls:string;
   begin
    with aTrPt do
     begin
       case trSituation of
        0: Ls:='_' ;
        -1: Ls:='X';
        else LS:=IntToStr(trSituation);
       end;
      case alRegime of
      1: Result:=Concat('wTrace> Pt(',LS,'): ',trName,'=',trValue,'(',TimeToStr(trTime),')');
      else Result:='';
     end;
    end;
   end;

 function twTrace.TracePointsToText(alRegime:Integer; const aDivider:string=';'):string;
 var i:integer;
     LV:twTracePoint;
  begin
    Result:='';
    i:=0;
    while i<wTrace.items.Count do
        begin
          LV:=wTrace.items.Items[i];
          if Result='' then
             Result:=TracePointToLogStr(alRegime,LV)
          else
              Result:=Result+aDivider+TracePointToLogStr(alRegime,LV);
          Inc(i);
        end;
  end;

 constructor twTrace.Create(aregime:integer);
  begin
   FirstExceptFlag:=true;
   FEnabled:=true;
   FHomeTime:=Now;
   DebugRegime:=0;
   LastTickCount:=0;
   items:=TList<twTracePoint>.Create;
   AttachmentItems:=TList<twAddAttachmentItem>.Create;
   FRepeatInterval:=5;
   Frepeated:=false;
//   dValue:='';
   exEvent:=nil;
   exProc:=nil;
   ///
   FLogFilename:='';
   FLogRegime:=0;
    fin_exFlag:=False;
    HiddenException:=twHiddenTrace.Create;
    HiddenException.SetMailParams(MESettings.MailAddr,MESettings.smtpServer,
                                          MESettings.SmtpAccount,MESettings.SmtpPassword);
  end;

 destructor twTrace.destroy;
  begin
    FEnabled:=false;
    exProc:=nil;
    exEvent:=nil;
    items.Free;
    AttachmentItems.Free;
    if FLogRegime>0 then
    begin
     DeleteCriticalSection(FRTL);
    end;
    HiddenException.Free;
    inherited Destroy;
  end;

 function twTrace.SetLogParams(aLogRegime:Integer; const ALogFileName:string; AClearFlag:boolean):Boolean;
  begin
   Result:=False;
   FLogFilename:=Trim(ALogFileName);
   FLogRegime:=aLogRegime;
   if FLogFilename='' then FLogRegime:=0; // !
   if FLogRegime>0 then
    begin
     InitializeCriticalSection(FRTL);
    // Sleep(18);
      Result:=AddToLog('wTrace_log=start',True);
    end
   else begin
         FLogFilename:='';
         DeleteCriticalSection(FRTL);
         Result:=True;
   end;
  end;

 function twTrace.AddPairToLog(const apairName,apairValue:string):boolean;
  begin
   Result:=False;
   if Not(FEnabled) then exit;
   if FLogRegime>0 then
        Result:=AddToLog(Concat(apairName,'=',apairValue));
  end;

procedure twTrace.HiddenCall(ahType:Integer; const aCaption,aMsg:string);
var LS,LCapt:string;
    rFlag:boolean;
 begin
   if Not(FEnabled) then exit;
   HiddenException.hd_Num:=ahType;
   if Trim(aMsg)<>'' then
      HiddenException.hd_Msg:=aMsg
   else  HiddenException.hd_Msg:='manual call in hiddenException';
   ///
   LS:=MESettings.MailSubject;
   rFlag:=false;
   if (acaption<>'') and (aCaption<>'*') then
    begin
      Lcapt:=StringReplace(aCaption,'*',LS,[]);
      MESettings.MailSubject:=Lcapt;
      rFlag:=true;
    end;
   HiddenException.Enabled:=True;
   try
    HiddenException.Call;
    finally
      HiddenException.Enabled:=False;
      if rFlag then MESettings.MailSubject:=LS;

    end;
 end;

//////////////////////////////////////////////

  procedure twTrace.SetPt(const aptName,aValue:string; apLogFlag:Boolean=true);
  var il:Integer;
      LFlag:Boolean;
      LV:twTracePoint;
   begin
     LFlag:=False;
     if Not(FEnabled) then exit;
     il:=0;
     try
       while il<items.Count do begin
          LV:=items.Items[il];
         if LV.trName=aptName then
            begin
              LFlag:=True;
              LV:=items.Items[il];
              LV.trValue:=aValue;
              LV.trTime:=Now-FHomeTime;
              LV.trSituation:=LV.trSituation+1;
              if apLogFlag=false then
                   LV.trLogRegime:=0
              else LV.trLogRegime:=1;
              items.Items[il]:=LV;
              Break;
            end;
         Inc(il);
       end;
       if LFlag=false then
         begin
             LV.trName:=aptName;
             LV.trValue:=aValue;
              LV.trTime:=Now-FHomeTime;
              LV.trSituation:=1;
              if (FLogRegime=0) or (apLogFlag=false) then
                   LV.trLogRegime:=0
              else LV.trLogRegime:=1;
            items.Add(LV);
         end;
        ///
        if DebugRegime>0 then
         begin
           DebugExecute(LV);
         end;
        ///
      except     // ! пусто
        LV.trSituation:=-11;
     end;
     if (FLogRegime<>0) and (apLogFlag=True) then
        AddPairToLog(aptName,aValue);
   end;

 procedure twTrace.DeletePt(const aptName:string);
 var il:Integer;
     LV:twTracePoint;
     LLogFlag:Boolean;
     L_DelFlag:Boolean;
   begin
     if Not(FEnabled) then exit;
     LLogFlag:=False;
     L_DelFlag:=False;
     il:=0;
     try
     while il<items.Count do begin
         if items.Items[il].trName=aptName then
            begin
              LV:=items.Items[il];
              LV.trSituation:=-1;
              LV.trTime:=Now-FHomeTime;
              LLogFlag:=(LV.trLogRegime<>0);
              items.Delete(il);
              L_DelFlag:=True;
              Break;
            end;
         Inc(il);
       end;
       ///
        if (DebugRegime>0) and (L_DelFlag=True) then
         begin
           DebugExecute(LV);
         end;
      except
     end;
     if (FLogRegime<>0) and (LLogFlag) then
        AddPairToLog(aptName,'DELETE');
  end;

 function twTrace.GetPtFromName(const aptName:string):twTracePoint;
 var il:Integer;
  begin
    Result.trName:='';
    Result.trValue:='';
    Result.trLogRegime:=0;
    Result.trSituation:=0;
    il:=0;
    try
     while il<items.Count do begin
       if items.Items[il].trName=aptName then
          begin
            Result:=items.Items[il];
            Break;
          end;
       Inc(il);
     end;
    except
    end;
  end;

 function twTrace.AddAttachmentItem(const aFileName:string; const ASendname:string=''):Boolean;
 var LItem:twAddAttachmentItem;
     i:integer;
  begin
    Result:=False;
    if FileExists(aFileName)=false then Exit;
    LItem.imIndex:=0;
    LItem.imFilename:=aFileName;
    LItem.imSendFilename:=ASendname;
    LItem.imzipFile:='';
    LItem.imFieldName:='';
    i:=AttachmentItems.Add(LItem);
    Result:=(i>=0);
  end;

//////////////////////////////////////////////////////////////////////////////
///
  procedure RemoveCommandLineHeaderInfo(const exceptIntf : IMEException;
                                      var handled      : boolean);
var il:Integer;
    LV:twTracePoint;
    LTCount:int64;
    LLIst:TStrings;
   // LAA:twAddAttachmentItem;
begin
 //  exceptIntf.BugReportHeader['command line'] := '';
  if Assigned(wTrace) then
     begin
       if Not(wTrace.Enabled) then exit;
       if wTrace.dValue<>'' then  exceptIntf.BugReportHeader['wTrace'] :=wTrace.dvalue;
       ///
       il:=0;
       while il<wTrace.items.Count do
        begin
          LV:=wTrace.items.Items[il];
          exceptIntf.BugReportHeader[LV.trName]:=LV.trValue;
          Inc(il);
        end;
        ///
         if wTrace.fin_exFlag=False then
         begin   ///  условие чтобы убрать рекурсию
           wTrace.fin_exFlag:=True;
           LList:=TStringList.Create;
           try
             LList.Add('class='+exceptIntf.ExceptClass);
             LList.Add('message='+exceptIntf.ExceptMessage);
             LList.Add('subject='+MESettings.MailSubject);
             LList.Add('points='+wTrace.TracePointsToText(1));
             LList.Add('hidden=0');
             ///
             if Assigned(wTrace.exProc) then
                wTrace.exProc();
             if Assigned(wTrace.exEvent) then
               wTrace.exEvent(wTrace,LList);
            finally
              LList.Free;
              wTrace.fin_exFlag:=False;
           end;
         end;
        ///
        case  wTrace_FormatMessageSign of
         0: MESettings.ExceptMsg:=exceptIntf.ExceptMessage;
         1: MESettings.ExceptMsg:=mFormatExceptString(exceptIntf.ExceptMessage,exceptIntf.ExceptClass);
         else ;
        end;
       ///
       ///  доп. вложения репорта - если есть
       if (wTrace.AttachmentItems.Count>0) then
        begin
          MESettings.AdditionalAttachments.Clear;
          il:=0;
          while il<wTrace.AttachmentItems.Count do
           begin
             if wTrace.AttachmentItems[il].imFilename<>'' then
              begin
                MESettings.AdditionalAttachments.Add(
                   wTrace.AttachmentItems[il].imFilename,
                   wTrace.AttachmentItems[il].imSendFilename,
                   wTrace.AttachmentItems[il].imzipFile,
                   wTrace.AttachmentItems[il].imFieldName);
              end;
             Inc(il);
           end;
        end;
       ///
       if MESettings.AutoSend=false then MESettings.AutoSend:=true;
       if (wTrace.SendRepeated=false) then
        begin
          LTCount:=_GetPerformanceTickCount;
          if (wTrace.FirstExceptFlag=false) and
           (Abs(0.001*(LTCount-wTrace.LastTickCount))<wTrace.RepeatInterval) then
               MESettings.AutoSend:=false;
          wTrace.LastTickCount:=LTCount;
          wTrace.FirstExceptFlag:=false;
        end;
       ///
     end;
   //  exceptIntf.BugReportHeader['Info1'] :='hhhh';
end;


procedure mad_SetReportState(aMailSendFlag:Boolean);
 begin
  MESettings.AutoSend:=aMailSendFlag;
  MESettings.MailAsSmtpServer:=aMailSendFlag;
  MESettings.SendInBackground:=aMailSendFlag;
 end;

procedure mad_SetReportMailSMTPSettings(const mAddr,smtpSrvr,aLogin,aPassStr:string; const MESett:IMESettings=nil);
var LSet:IMESettings;
 begin
   if MESett=nil then LSet:=MESettings else LSet:=MESett;
   LSet.MailAddr:=mAddr;
   LSet.MailAsSmtpClient:=True;
   LSet.MailAsSmtpServer:=False;
   LSet.SmtpServer:=smtpSrvr;
   LSet.SmtpAccount:=aLogin;
   LSet.SmtpPassword:=aPassStr;
 end;

initialization
  ///
 /// MESettings.SmtpPassword:='qmola112';
  RegisterExceptionHandler(RemoveCommandLineHeaderInfo, stDontSync);
   wTrace:=twTrace.Create(0);

finalization

 if (wTrace<>nil) and (Assigned(wTrace)=True) then
  begin
   wTrace.Free;
   wTrace:=nil;
  end;

end.
