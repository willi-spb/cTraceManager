unit u_wCodeSite;
////////////////////////////////////////
///
///
///  Willi  ранее была надстройка над CodeSite - потом добавил CUSTOM_TRACE
///
///   выбор логировать или нет, режим логирования,
///   глобальная ссылка на CodeSite
///    wCodeSite
///
interface



// SmartInspect
///  трассировка через свой
{$DEFINE CUSTOM_TRACE}

////////////////

 {$IFNDEF CUSTOM_TRACE}
uses CodeSiteLogging;

var
  wCodeSite: TCodeSiteLogger;
  /// удалять файл каждый запуск или дописывать в старый
var
  wCurrDest: TCodeSiteDestination = nil;
 {$ELSE}
   uses u_wCodeTrace,SysUtils;

   var wCode:TCodeTraceManager;

 {$ENDIF}

var
  wCodeSiteRegime: integer; ///   1 - использовать просмотровщик
                            ///   0 - ничего не использовать (без логир)
                            ///   2- использовать запись в файл с послед. просмотром

var
  wCodeSiteClearFlag: boolean = true;


  /// if Aregime<0 then --> wCodeSiteRegime
  ///
  ///  выставить режим логирования и параметры - вначале программы
procedure w_InitCodeSite(aRegime: integer; const aLogFilename: string);
 ///  узнать - включено ли логирование
function w_CodeSiteEnabled: boolean;
///
///  выставить внутри программы режим логировать или нет
procedure w_CodeSiteState(aNewState:Boolean);
/// <summary>
///     выдать инфу в зависисмости от команды
/// </summary>
procedure w_CodeSiteSendCommand(const aCommand,aMsgData:String);
///
/// <summary>
///      логировать с командами вида enter exit mote warn err
/// </summary>
 procedure wLog(const aCommand,aMsgData:String);

 procedure wLogE(const aPlaceStr:string; aE:Exception);

 /// <summary>
 ///    логировать только для указанного флага (флагов) - через ','
 /// </summary>
 procedure wLogSign(const aSignNames,aCommand,aMsgData:String);
 /// <summary>
 ///     выставить указанный флаг логирования
 /// </summary>
 procedure wLogSetSign(const ASignNames:String; AState:boolean);
 /// <summary>
 ///     проверить true - если флаг логирования включен (иначе нет)
 /// </summary>
 function wLogEnabled(const ASignNames:String):boolean;
 ///
 type
   TwTraceLogEvent=procedure(const aCommand,aMsgData:String) of object;
 ///
 /// <summary>
 ///    выдать событие для внешнего логирования или nil
 /// </summary>
 function wGetExtLogEvent(aEnabled:Boolean):TwTraceLogEvent;

implementation

uses System.Classes, System.Generics.Collections;


type

  TwLogSigns=class(TDictionary<String,Boolean>)
   private
    FEnabled:boolean;
   public
    constructor Create;
    property Enabled:boolean read FEnabled write FEnabled;
  end;

var wLogSigns:TwLogSigns;

procedure w_InitCodeSite(aRegime: integer; const aLogFilename: string);
var
  LRegime: integer;
begin
  {$IFNDEF CUSTOM_TRACE}
  if aRegime < 0 then
    LRegime := wCodeSiteRegime
  else
    LRegime := aRegime;
 // wCodeSiteRegime:=LRegime;
  if LRegime = 0 then
  begin
    CodeSite.Enabled := false;
    exit;
  end;
  if LRegime = 2 then
  begin
    //
    if wCodeSiteClearFlag = true then
      DeleteFile(aLogFilename);
    //
    CodeSite.Enabled := true;
    wCurrDest := TCodeSiteDestination.Create(nil);
    wCurrDest.LogFile.FilePath := ExtractFilePath(aLogFilename);
    wCurrDest.LogFile.FileName := ExtractFileName(aLogFilename);
    wCurrDest.LogFile.Active := true;
    CodeSite.Destination := wCurrDest;
  end;
  {$ENDIF}
end;

function w_CodeSiteEnabled: boolean;
begin
  Result := (wCodeSiteRegime > 0) and (wCodeSiteRegime <= 100);
end;

procedure w_CodeSiteState(aNewState:Boolean);
 begin
  {$IFNDEF CUSTOM_TRACE}
   if Assigned(wCodeSite) then
      wCodeSite.Enabled:=aNewState;
  {$ELSE}
    if Assigned(wCode) then
       wCode.Enabled:=aNewState;
  {$ENDIF}
 end;


procedure w_CodeSiteSendCommand(const aCommand,aMsgData:String);
var i,LSign:integer;
    LFlag:boolean;
    LComm:string;
 begin
   if wCodeSiteRegime=0 then exit;
   LFlag:=false;
   LSign:=0;

   {$IFNDEF CUSTOM_TRACE}
       LComm:=Lowercase(Trim(aCommand));
       i:=POs('enter:',LComm);
       if i=1 then
               begin
                LSign:=1;
                wCodeSite.EnterMethod(Copy(LComm,7,Length(LComm)-6))
               end
       else
           begin
             i:=POs('exit:',LComm);
             if i=1 then
                  LSign:=2;
           end;
       try
         if (LFlag=false) then
          begin
           i:=Pos('warn',LComm);
           if (i>0) then
            begin
              wCodeSite.SendWarning(aMsgData);
              LFlag:=true;
            end;
          end;
         if (LFlag=false) then
          begin
           i:=Pos('err',LComm);
           if (i>0) then
            begin
              wCodeSite.SendError(aMsgData);
              LFlag:=true;
            end;
          end;
         if (LFlag=false) then
          begin
           i:=Pos('note',LComm);
           if (i>0) then
            begin
              wCodeSite.SendNote(aMsgData);
              LFlag:=true;
            end;
          end;
        if (LFlag=false) and (aMsgData<>'') then
          begin
              wCodeSite.SendMsg(aMsgData);
              LFlag:=true;
          end;
       ///
       finally
         if LSign=2 then
            wCodeSite.ExitMethod(Copy(LComm,6,Length(LComm)-5));
       end;
    {$ELSE}
      LComm:=Trim(aCommand);
      if LComm='' then LComm:='user:'
      else if LComm[Length(LComm)]<>':' then
              LComm:=Concat(LComm,':');
      wCode.SendCommand(LComm,aMsgData);
    {$ENDIF}
 end;

procedure wLog(const aCommand,aMsgData:String);
 begin
   w_CodeSiteSendCommand(aCommand,aMsgData);
 end;

procedure wLogE(const aPlaceStr:string; aE:Exception);
 begin
   w_CodeSiteSendCommand('error:',aPlaceStr+': Class='+aE.ClassName+'; '+aE.Message+' '+aE.StackTrace);
 end;

 procedure wLogSign(const aSignNames,aCommand,aMsgData:String);
 var LLIst:TStringList;
     i:integer;
     LS:String;
     LFlag:boolean;
  begin
    if (Assigned(wLogSigns)=false) or (wLogSigns.Enabled=false) then
     begin
       wLog(aCommand,aMsgData);
       exit;
     end;
    LFlag:=false;
    LLIst:=TStringList.Create;
    try
      LList.CommaText:=aSignNames;
      i:=0;
      while i<LList.Count do
       begin
         LS:=Trim(lowerCase(LList.Strings[i]));
         if (LS<>'') and (wLogSigns.ContainsKey(LS)) and (wLogSigns.Items[LS]=true) then
            begin
              LFlag:=true;
              break;
            end;
         Inc(i);
       end;
      ///
    finally
      LList.Free;
    end;
    ///
    if LFlag then
       wLog(aCommand,aMsgData); // !
    ///
  end;

procedure wLogSetSign(const ASignNames:String; AState:boolean);
var LLIst:TStringList;
    i:integer;
    LS:string;
 begin
  if Assigned(wLogSigns)=false then exit;
  LLIst:=TStringList.Create;
    try
      LList.CommaText:=aSignNames;
      i:=0;
      while i<LList.Count do
       begin
         LS:=Trim(lowerCase(LList.Strings[i]));
         if (LS<>'') then
              wLogSigns.AddOrSetValue(LS,AState);
         Inc(i);
       end;
      ///
    finally
      LList.Free;
    end;
 end;

function wLogEnabled(const ASignNames:String):boolean;
var LLIst:TStringList;
    i:integer;
    LS:string;
 begin
  Result:=false;
  if Assigned(wLogSigns)=false then exit;
   LLIst:=TStringList.Create;
    try
      LList.CommaText:=aSignNames;
      i:=0;
      while i<LList.Count do
       begin
         LS:=Trim(lowerCase(LList.Strings[i]));
         if (LS<>'') and (wLogSigns.ContainsKey(LS)) then
           begin
              if wLogSigns.Items[LS]=false then
               begin
                Result:=false;
                break;
               end
              else Result:=true;
           end;
         Inc(i);
       end;
      ///
    finally
      LList.Free;
    end;
 end;

function wGetExtLogEvent(aEnabled:Boolean):TwTraceLogEvent;
 begin
   Result:=nil;
   {$IFDEF CUSTOM_TRACE}
    if aEnabled then
       Result:=wCode.SendCommand
    else Result:=nil;
    {$ENDIF}
 end;


{ TwLogSigns }

constructor TwLogSigns.Create;
begin
  inherited Create;
  FEnabled:=true;
end;

initialization

wLogSigns:=TwLogSigns.Create;



{$IFNDEF CUSTOM_TRACE}
wCodeSite := CodeSite; //  !!
if Assigned(CodeSite) then;
// CodeSite.Enabled:=false;
{$ELSE}

  wCode:=TCodeTraceManager.Create(0);     // !

{$ENDIF}


finalization

{$IFNDEF CUSTOM_TRACE}
if (Assigned(wCurrDest) = true) then
  wCurrDest.Free;
{$ELSE}
  if (Assigned(wCode) = true) then
  wCode.Free;
{$ENDIF}

if Assigned(wLogSigns) then
   FreeAndNil(wLogSigns);

end.

