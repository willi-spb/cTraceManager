unit wAppEnvironClass;

interface

uses System.Classes,
     ServiceClasses,
     System.Generics.Collections,
     u_AppLogClass,
 {$IFDEF MSWINDOWS}
   wMessagesHook,
  {$IFDEF FMX}
    FMX.Platform.Win,
  {$ENDIF}
    u_MMFClass,
 {$ENDIF}
 w_iniSettings;

type
 /// <summary>
 ///    структура для инициализации (вначале главн. модуля) параметров приложения -
 ///             название, ID, класс глав окна и прочее...
 ///    (исп. для инициализации)
 /// </summary>
 TwAppEnvironParams=record
   Id:Integer; // в списке например InstallTraffic
   guIDStr:string;  /// GUID строка
   ///
   /// <summary>
   ///     краткое название программы (если есть) - определяет оно Name
   /// </summary>
   ShortName:string;
   /// <summary>
   ///     полное название программы - если пусто берем из краткого...
   ///      обычно латинское название в пику руссому в заголовке
   ///    (оно же для определения в InsallTraffiс или как имя проекта
   /// </summary>
   Name:string;
   ///
   Caption:string;  /// заголовок глав. окна
   /// <summary>
   ///      для MMFClass: хендл приложения
   /// </summary>
   /// <summary>
   ///     для различных окон - левая састь заголовка - до символа "-" или целиком
   /// </summary>
   CaptionLeftPart:string;
   /// <summary>
   ///    точность версии для показа
   /// </summary>
   versionVisPrecision:integer;
   ///
   ApHandle:NativeUInt;
   /// <summary>
   ///     для MMFClass: юник и имя класса окна вида FMTMainForm  с префиксом FM
   /// </summary>
   mpIdentStr,wndClassNames:string;
   /// <summary>
   ///     посылать строку по умолчанию в дубль программы (см. Verify...)
   /// </summary>
   winSendRStr:string;
   winSendRegime:Integer; // тип команды - вспомогат...
   /// <summary>
   ///    true - то проверять прямо при создании класса на предмет второго запуска
   ///    (требуется, чтобы был уже определен объект типа Application для получения handle
   ///  only Windows
   /// </summary>
   winHomeRVerifyFlag:Boolean;
   /// <summary>
   ///    флаг автоматического подключения Hook для приложения и окна - только Windows!
   /// </summary>
   winAutoHookFlag:boolean;
   /// <summary>
   ///    имя ini файла программы (без путиЮ но с расширением) -- если пустое - то <app>.ini
   /// </summary>
   iniFileName:string;
   /// <summary>
   ///    кодовое слово для кодирования в ini-файле записей  рекоменд. длина от 4 до 12
   /// </summary>
   iniCodeKey:string;
   /// <summary>
   ///   сдвиг - на сколько сдвигать прикодировании ini-файл  1..24 или ~~
   /// </summary>
   iniShift:Integer;
   /// <summary>
   ///     кусок MyApp  для пути вида \software\MyApp\ для работы с реестром - исп. в Updater
   /// </summary>
   runAppName:string;
   ///
   CopyRightStr,PublisherStr:string;
   /// <summary>
   ///     строка краткого (лучше лат.) Названия компании для создания подкаталога в Документы
   /// </summary>
   CompanyDirectoryPart:string;
   /// <summary>
   ///    справочно - название компании
   /// </summary>
   CompanyName:string;
 end;



 TwAppEnvironment=class(TObject)
  private
   _CreateFlag,_DestroyFlag:Boolean;
   FParams:TwAppEnvironParams;
   FAppPath:string;
   FAppFileName:string;
   FFullAppName:string;
   FUserPath:string;
   FRegime,FAppState:integer;
   FAutoRunFlag:Boolean;
   FTickCount:Cardinal;
   FBugReportCaption:string;
   procedure SetRegime(Value:Integer);
   procedure SetAppState(Value:Integer);
   procedure SetAutoRunFlag(Value:Boolean);
   function GetEnabledMessageHooks:boolean;
   ///
   function GetGlobalDataStr(Index:String):string;
   procedure SetGlobalDataStr(Index,Value:String);
   function GetGlobalDataFlag(Index:String):boolean;
   procedure SetGlobalDataFlag(Index:string; Value:boolean);
   function GetGlobalDataInt(Index:String):Integer;
   procedure SetGlobalDataInt(Index:string; Value:integer);

   procedure SetBugReportCaption(Value:string);
  private
   FStartDT:TDateTime;
  protected
   /// <summary>
  ///    словарик с глобальными параметрами (строки)
  ///    (строка может содержать любые символы (с переносом строк), поэтому использование StringList нежелательно
  ///    (см. свойство GlobalDataString)
  /// </summary>
   GlobalData:TDictionary<String,String>;
  ///
   /// <summary>
   ///       событие записи/изменения лога в списке логов - привязано к AppLogItems
   ///       отправлять данные по логу еще куда-то, например в madExcept объект:
   ///  Arec.LogRegime=0  - это новая запись лога  =1 - это операция модификации записи лога
   ///  ARec.State=0  - лог необработан  =1 обработан(отправлен)
   /// </summary>
 //  procedure DoSetLogData(const ARec:TAppLoggingItem);
  /// <summary>
  ///     событие добавления JointItem  или удаления
  ///     (Joint используется в TAppLoggingItems - это коллекция меток без логирования по умолч.)
  /// </summary>
  // procedure DoJointOperation(aOpSign:Integer; const ARec:TJointRecord);
  public
  MadExceptEnabled:Boolean;
  ///
  /// <summary>
  ///   информация о компьютере ОС и т.п. - кроссплатформ.
  /// </summary>
  ServiceInfo:TFMServiceClass;
  ///
  /// <summary>
  ///    коллекция с методами доступа для логирования - сама ничего не сохраняет
  /// </summary>
  AppLogItems:TAppLoggingItems; // ссылка на глобальный объект для логирования-
 ///   объект создается здесь в конструкторе
  ///
  {$IFDEF MSWINDOWS}
    /// <summary>
    ///    ссылка на обработчик Message (только Win)
    /// </summary>
     InstAppMsgr:TMDataHandling; // ссылка на глобальную переменную
  {$ENDIF}
  ///
  /// <summary>
  ///    ссылка на глобальный объект класса-надстройки  ini-файла для различных платформ
  ///    файл хранится для win в папке пользователя
  /// </summary>
  Ini:TwiniSettings;
  /// <summary>
   ///     тек. индекс пользователя в Ini-файле (для сокращения опросов)
   /// </summary>
  iniUserIndex:integer;
   /// <summary>
   ///     тек. имя пользователя в Ini-файле (справочно)
   /// </summary>
   iniUserLogin:string;
   /// <summary>
   ///    id - тек. пользователя программы (обычно из базы) - для промежут. хранения - неотрицат.
   /// </summary>
   iniUserId:Cardinal;
  ///
   constructor Create(const App_Params:TwAppEnvironParams);
   destructor Destroy; override;
  ///
  /// <summary>
  ///   сервис - логирование без непосредственной записи вне (если найдено "=" Action - слева от него LabelDesc-справа)
  ///  -------- (добавлено для упрощения работы)
  /// </summary>
   procedure setLog(const aActionAndLabelDesc:string; aLvl:integer=1; aValue:Double=1);
  ///
   /// <summary>
   ///     сервис - просто упростить обращение для внутр. логов
   /// </summary>
   procedure SetJoint(const aJntName,aJntdata:string);
   /// <summary>
   ///    сервис - упростить удаление точки внутр. лога
   /// </summary>
   procedure ClearJoint(const aJntName:string);
  ///
  {$IFDEF MSWINDOWS}
  /// <summary>
  ///     Проверка на предмет дублирования программы в Windows -
  /// если дубль - то вернем false   можно послать строку команды и тип команды
  /// </summary>
  function VerifyRepetition(const ASendStr:string; sendRegimeSign:Integer=4):Boolean;
  ///
   ///  сервис
   /// <summary>
   ///  Windows  -  прицепить (создать) обработик - hook для окна и приложения
   /// </summary>
    procedure InitMessageHook;
   /// <summary>
    ///    Windows - убрать обработчкик событий
    /// </summary>
    procedure ClearMessageHook;
    /// <summary>
    ///    зацепить хуки:
    /// </summary>
    procedure SetMessEvent(App_Event:TAppMsgEvent; Wind_Event:TWinMessageEvent);
   ///
  {$ELSE}
   ///
   function VerifyRepetition(const ASendStr:string; sendRegimeSign:Integer=4):Boolean;
   procedure InitMessageHook;
   procedure ClearMessageHook;
   ///
  {$ENDIF}
    /// <summary>
    ///    сервис - доступ к iniSettings
    /// <param name="aShortRegime">
    ///   28 - папка пользователя(1C)    26 - папка пользователя (Roaming)
    ///   35 - папка всех пользователей (C:/ProgramData)
    ///   5 - мои документы(05)
    ///   46 - общие документы(2e)
    ///
    /// </param>
    /// <param name="aCreateFlag">
    ///     создавать или нет - если нет
    /// </param>
    /// </summary>
   class function GetUserSpecPath(const aSubDir:string; aShortRegime:Integer; aCreateFlag:Boolean=true):String;
  /// <summary>
  ///    связать событие аналитики (если есть объект) с обработчиком исключений класса wtTRace
  ///    (если нет MadExcept - то пересавить обработчик для Application.DoException
  ///  ПРИМЕР:
  ///  {IFDEF ANALYTICS_ACCESS}
  ///    if (Assigned(Ancs)) then
  ///       begin
  ///          Ancs.AbbApplicationInfo:=AGlParams;
  ///          Ancs.RedirectExceptions;
  ///       end;
  //// {ENDIF}
  /// </summary>
  ///  procedure AssignExceptionToAnalytics(const AGlParams:string);
  /// <summary>
  ///     сохранить в ini-файл данные, полученные с ServiceInfo с типовыми полями
  /// </summary>
  procedure SaveServiceInfoToIni(aSaveRegime:Integer=1);
  ///
  /// <summary>
  ///    сбросить точку времени в текущий момент
  /// </summary>
  procedure SetTime;
  /// <summary>
  ///     разница времени от загрузки (вначале) или от указанного момента в процедуре SetTime;
  /// </summary>
  function GetDeltaTime:TDateTime;
  ///
  ///
  /// <summary>
  ///      сервис - послать event в аналитику
  ///  ПРИМЕР:
  ///   procedure TwAppEnvironment.SendTrackEvent(const ACategory,aAction,aLabel:string; aValue:single; ARegime:integer=0);
  /// begin
  ///   {IFDEF ANALYTICS_ACCESS}
  ///      if Assigned(Ancs) then
  ///        Ancs.TrackEvent(ACategory,aAction,aLabel,aValue,ARegime);
  ///   {ENDIF}
  /// end;
  /// </summary>
  ///  procedure SendTrackEvent(const ACategory,aAction,aLabel:string; aValue:single; ARegime:integer=0);
  ///
  property Params:TwAppEnvironParams read FParams;
  ///
  /// <summary>
  ///    время создания класса в программе - справочно для времени входа в программу
  /// </summary>
  property StartDateTime:TDateTime read FStartDT;
  /// <summary>
  ///   путь к программе - (для Android путь к DocumentPath проги
  /// </summary>
  property AppPath:string read FAppPath;
  /// <summary>
  ///     имя файла приложения без пути и без расширения файла
  /// </summary>
  property AppFileName:string read FAppFileName;
  /// <summary>
  ///     путь и имя программы - сервис (нежелат использовать не в Win)
  /// </summary>
  property FullAppName:string read FFullAppName;
  /// <summary>
  ///    путь для настроек пользователя (кталог Roaming имф программы)
  /// </summary>
  property UserPath:string read FUserPath;
  property Regime:integer read FRegime write SetRegime;
  /// <summary>
  ///    служебн. дополнительное поле -- состояние приложения (можно исп. в логировании)
  /// </summary>
  property AppState:integer read FAppState write SetAppState;
  property AutoRunFlag:Boolean read FAutoRunFlag write SetAutoRunFlag;
  /// <summary>
  ///    проверить - была ли проведена активания хуков
  /// </summary>
  property EnabledMessageHooks:boolean read GetEnabledMessageHooks;
  /// <summary>
  ///    свойство - для вспомогательных переменных для глобального хранения во время работы
  ///    (храним только текст - переменные приводим к нему - текст может быть многолинейным)
  /// </summary>
  property globalDataString[Index:string]:string read GetGlobalDataStr write SetGlobalDataStr;
  /// <summary>
  ///    см. globalDataString - глоб. словарь  строк
  /// </summary>
  property globalDataFlag[Index:string]:Boolean read GetGlobalDataFlag write SetGlobalDataFlag;
    /// <summary>
  ///    см. globalDataString - глоб. словарь  строк
  /// </summary>
  property globalDataInt[Index:string]:integer read GetGlobalDataInt write SetGlobalDataInt;
  /// <summary>
  ///     свойство только для TRace - сервис - назначить имя для bugReport
  /// </summary>
  property BugReportCaption:string read FBugReportCaption write SetBugReportCaption;
 end;


implementation

 uses
  {$IFNDEF FMX}
    Vcl.Forms,
  {$ENDIF}
   System.SysUtils;

 procedure TwAppEnvironment.SetRegime(Value:Integer);
  begin
   if Value<>FRegime then
    begin
     FRegime:=Value;
     SetJoint('rg',IntToStr(FRegime));
    end;
  end;

procedure TwAppEnvironment.SetAppState(Value: Integer);
begin
    if Value<>FAppState then
    begin
     FAppState:=Value;
     SetJoint('appState',IntToStr(FAppState));
    end;
end;

procedure TwAppEnvironment.SetAutoRunFlag(Value:Boolean);
  begin
   if Value<>FAutoRunFlag then
     FAutoRunFlag:=Value;
   if FAutoRunFlag then SetJoint('Auto','1')
   else SetJoint('Auto','0');
  end;

 function TwAppEnvironment.GetEnabledMessageHooks:boolean;
  begin
    ///
    Result:=false;
    {$IFDEF MSWINDOWS}
      Result:=(TMessageHook.Hook>0);
    {$ENDIF}
  end;

  function TwAppEnvironment.GetGlobalDataFlag(Index: String): boolean;
  var LV:string;
begin
 Result:=False;
 if Index='' then exit;
 GlobalData.TryGetValue(Index,LV);
 result:=(UpperCase(LV)='TRUE') or (LV='1');
end;

function TwAppEnvironment.GetGlobalDataInt(Index: String): Integer;
  var LV:string;
begin
 Result:=-1;
 if Index='' then exit;
 GlobalData.TryGetValue(Index,LV);
 TryStrToInt(LV,Result);
end;

function TwAppEnvironment.GetGlobalDataStr(Index:String):string;
   begin
    Result:='';
    if Index='' then exit;
    GlobalData.TryGetValue(Index,Result);
   end;

  class function TwAppEnvironment.GetUserSpecPath(const aSubDir: string;
  aShortRegime: Integer; aCreateFlag: Boolean): String;
  var LSubDir:string;
begin
  LSubDir:=IncludeTrailingPathDelimiter(aSubDir);
  Result:=GetAppUserLocalDataPath(LSubDir,aShortRegime,aCreateFlag);
end;

procedure TwAppEnvironment.SetGlobalDataFlag(Index:string; Value: boolean);
begin
  if Index='' then exit;
  GlobalData.AddOrSetValue(Index,BoolToStr(Value,True));
end;

procedure TwAppEnvironment.SetGlobalDataInt(Index: string; Value: integer);
begin
  if Index='' then exit;
  GlobalData.AddOrSetValue(Index,IntToStr(Value));
end;

procedure TwAppEnvironment.SetGlobalDataStr(Index,Value:String);
   begin
     if Index='' then exit;
     GlobalData.AddOrSetValue(Index,Value);
   end;

 procedure TwAppEnvironment.SetBugReportCaption(Value:string);
  begin
    FBugReportCaption:=Value;
  end;



 constructor TwAppEnvironment.Create(const App_Params:TwAppEnvironParams);
 var i,j:Integer;
  begin
   if _CreateFlag then Exit;
   inherited Create;
   _CreateFlag:=True;
   _DestroyFlag:=False;
   ///
   FStartDT:=Now;
   ///
   GlobalData:=TDictionary<String,String>.Create;
   iniUserIndex:=0;
   iniUserLogin:='';
   iniUserId:=0;
   ///
   FTickCount:=TThread.GetTickCount;
   ///
    Assert((App_Params.Id>0),'TwAppEnvironment.Create - not define AppParams fields!');
    inherited Create;
    FParams:=App_Params;
    if (FParams.Name='') then
       FParams.Name:=FParams.ShortName;
    ///
    if FParams.iniFileName='' then
       FParams.iniFileName:=Concat(GetAppOnlyFileName,'.ini');
    if FParams.iniCodeKey='' then
       FParams.iniCodeKey:=Concat('M','1','18','5');
    if (FParams.iniShift<1) or (FParams.iniShift>99) then
        FParams.iniShift:=5;
    if FParams.winSendRegime<=0 then FParams.winSendRegime:=4;
    FAppPath:=ExtractFilePath(ParamStr(0));
    ///
    /// сначала создадим лог и - если подключен MadExcept - то создадим его тоже
    AppLogCreate('DefD');
    AppLogItems:=AppLog;
    AppLogItems.OnSetData:=nil;
   // AppLogItems.OnSetData:=DoSetLogData;
    AppLogItems.OnSetJoint:=nil;
    ///
    MadExceptEnabled:=False;
    ///  создать и заполнить поля -- версия App, OS и прочее...
    ServiceInfo:=TFMServiceClass.Create;
    /// заполним строку части заголовка - если она пустая вначале
    if FParams.CaptionLeftPart='' then
       begin
         i:=Pos(' - ',FParams.Caption);
         if i<=0 then FParams.CaptionLeftPart:=FParams.Caption
         else
             FParams.CaptionLeftPart:=Copy(FParams.Caption,1,i);
         // добавим номер версии
         if ServiceInfo.appVersionStr<>'' then
          begin
           //FParams.CaptionLeftPart:=Concat(FParams.CaptionLeftPart,' (v.',ServiceInfo.appVersionStr,')');
         { FParams.CaptionLeftPart:=Concat(FParams.CaptionLeftPart,' ',
              ServiceInfo.GetAppVersionString(FParams.versionVisPrecision));
              }
          end;
       end;
    ///
    ///  выставим поля для логов исходя из полученной по версии и OS информации
    AppLogItems.DescInformation:=ServiceInfo.appVersionAbb+','+ServiceInfo.DevInfoDesc;
    ///
    ///  аналитика - предварит. подключение (требует 2 компонента TAppAnalytics для связки)
   // Ancs:=TwAnalytics.Create(nil);
   // Ancs.LogItems:=AppLogItems; // ! привязка логов к аналитике - т.е. вызывать через аналитику
    ///
    /// проверка Instance
    {$IFDEF MSWINDOWS}
      if FParams.winHomeRVerifyFlag=true then
       begin
         // внутри создание и напр. глобального объекта
         // -->  InstAppMsgr:=MFHandling;
         VerifyRepetition(FParams.winSendRStr,FParams.winSendRegime);
       end;
     /// начальные хуки - если стоит автофлаг для них
     InstAppMsgr:=nil;
     if FParams.winAutoHookFlag then
       begin
           InitMessageHook;
       end;
    {$ENDIF}
    ///
    if Assigned(iniSettings)=false then
       iniSettings:=TwIniSettings.Create;
    Self.Ini:=iniSettings; // !
    // вызов функций определения пути для файла настроек и т.п.  - из модуля w_iniSettings
    FappFileName:=GetAppOnlyFileName;
    /// странно, но ParamStr(0) как-то работает и в ведроиде тоже...  %
    FFullAppName:=ParamStr(0);
    ///
    /// если нет каталога в общей папке - создать его по имени программы
    CreateAppUserPath(FAppFileName);
    /// выставить путь на каталог с настройками и прочим
    FUserPath:=GetAppUserPath(FAppFileName);
    ///
    ///

    ///  установим параметры для Trace -- имя письма или описание
   // Trace.BugReportName:=Concat(ServiceInfo.appVersionStr,'|',ServiceInfo.userName,'|',
   //                      DateTimeToStr(Now));
   // Trace.SetPt('aAppEnv','initTrace',False); // служебн. метка
    /// задать параметры для файла настроек
    iniSettings.SetParams(FUserPath+FParams.iniFileName,FParams.iniCodeKey,FParams.iniShift);
    ///
    FRegime:=0;
    {$IFDEF MSWINDOWS}
        try
        if (ParamCount >= 1) and (ParamStr(1)<>'') then
         begin
          i:=Pos('UNINSTALL',Uppercase(ParamStr(1)));
          j:=Pos('INSTALL',Uppercase(ParamStr(1)));
          if ((i=1) or (i=2)) and (Pos('.',ParamStr(1))<=0) then FRegime:=-1
          else
            if ((j=1) or (j=2)) and (Pos('.',ParamStr(1))<=0) then FRegime:=1
            else FRegime:=0;
        end;
       except
       end;
    {$ENDIF}
    ///
  end;

 destructor TwAppEnvironment.Destroy;
  begin
    if _DestroyFlag=true then Exit;
    _DestroyFlag:=True;
     if Assigned(Self.Ini) then
      begin
        if Self.Ini=iniSettings then iniSettings:=nil;
        Self.Ini.Free;
      end;
    {$IFDEF MSWINDOWS}
        ClearMessageHook;
     ///
     if Assigned(InstAppMsgr) then
                   begin
                     if InstAppMsgr=MFHandling then MFHandling:=nil;
                     InstAppMsgr.Free;
                   end;
    {$ENDIF}
    ///
     GlobalData.Free;
    ///
    if Assigned(AppLogItems) then
       AppLogFree;
    AppLogItems:=nil;
    if Assigned(ServiceInfo) then ServiceInfo.Free;
    ///
    inherited Destroy;
  end;

  procedure TwAppEnvironment.setLog(const aActionAndLabelDesc:string; aLvl:integer=1; aValue:Double=1);
  var j,k:integer;
      LAction,Ldesc:string;
   begin
      if Assigned(AppLogItems) then
       begin
         k:=Length(aActionAndLabelDesc);
         j:=Pos('=',aActionAndLabelDesc);
         LAction:='LA';
         Ldesc:=aActionAndLabelDesc;
         if (j>0) and (j<k-1) then
          begin
            LAction:=Copy(aActionAndLabelDesc,1,j);
            Ldesc:=Copy(aActionAndLabelDesc,j+1,k-j-1);
          end;
         j:=AppLogItems.PDataEx('Logs',LAction,Ldesc,aLvl,aValue);
         if j<0 then
          begin
            /// не записалось в лог
          end;
       end;
   end;

   procedure TwAppEnvironment.SetJoint(const aJntName,aJntdata:string);
    begin
      if Assigned(AppLogItems) then
         AppLogItems.Joint[aJntName]:=aJntdata;
    end;

   procedure TwAppEnvironment.ClearJoint(const aJntName:string);
     begin
        if Assigned(AppLogItems) then
         AppLogItems.DeleteJoint(aJntName);
     end;


 {$IFDEF MSWINDOWS}
 function TwAppEnvironment.VerifyRepetition(const ASendStr:string; sendRegimeSign:Integer=4):Boolean;
 var LSendStr:string;
  begin
    Result:=False;
    Assert(not(Assigned(MFHandling)),'TwAppEnvironment.VerifyRepetition - MFHandling is Assigned - not correct!');
    if FParams.ApHandle=0 then
      begin
       {$IFDEF FMX}
        FParams.ApHandle:=FMX.Platform.Win.ApplicationHWND;
       {$ELSE}
         FParams.ApHandle:=Application.Handle;
       {$ENDIF}
      end;
    Assert(FParams.ApHandle<>0,'TwAppEnvironment.VerifyRepetition: not Define Params.ApHandle=0!');
    LSendStr:=ASendStr;
    if LSendStr='' then
       LSendStr:=FParams.winSendRStr;
    ///
    MFHandling:=TMDataHandling.Create(FParams.ApHandle,FParams.mpIdentStr,
                                         FParams.wndClassNames);
    InstAppMsgr:=MFHandling;
    Result:=MFHandling.FirstFlag;
    if (Result=false) and (LSendStr<>'') then /// значит это второй запуск - про
     begin
        MFHandling.lpBaseAddress^.sRegime:=sendRegimeSign;
        InstAppMsgr.SendDataStr(ASendStr);
     end;
    ///
  end;

   procedure TwAppEnvironment.InitMessageHook;
    begin
         TMessageHook.InitMsgHook;
    end;

   procedure TwAppEnvironment.ClearMessageHook;
    begin
         TMessageHook.Clear;
    end;

   procedure TwAppEnvironment.SetMessEvent(App_Event:TAppMsgEvent; Wind_Event:TWinMessageEvent);
    begin
      if @Wind_Event<>nil then
         Active_WinUserMessageEvent:=Wind_Event;
      if @App_Event<>nil then
         Active_AppMsgEvent:=App_Event;
    end;


 {$ELSE}
 function TwAppEnvironment.VerifyRepetition(const ASendStr:string; sendRegimeSign:Integer=4):Boolean;
  begin
   Result:=true;
  end;

 procedure TwAppEnvironment.InitMessageHook;
  begin
   //
  end;
 ///
 procedure TwAppEnvironment.ClearMessageHook;
  begin
   //
  end;
 {$ENDIF}

 procedure TwAppEnvironment.SaveServiceInfoToIni(aSaveRegime:Integer=1);
 const L_sect='Info';
  begin
    if Assigned(ServiceInfo)=false then Exit;
    if Assigned(Ini) then
     try
      Ini.WriteString(L_sect,'USER',ServiceInfo.UserName);
      Ini.WriteString(L_sect,'USER_CAT',ServiceInfo.UserCategoryAbb);
      Ini.WriteInteger(L_sect,'USER',ServiceInfo.UserCatType);
      except
     end;
  end;

procedure TwAppEnvironment.SetTime;
 begin
   FTickCount:=TThread.GetTickCount;
 end;

function TwAppEnvironment.GetDeltaTime:TDateTime;
var LCount:Cardinal;
 begin
   LCount:=TThread.GetTickCount;
   Result:=(LCount-FTickCount)/MSecsPerSec/SecsPerDay;
 end;

end.
