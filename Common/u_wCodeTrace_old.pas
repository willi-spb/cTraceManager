unit u_wCodeTrace;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Generics.Collections,
  idUdpClient, IdGlobal, IdException;

type

 TCodeTraceItem=class(TPersistent)
  public
  /// <summary>
  ///      имя команды
  /// </summary>
   CommandName:String;
  /// <summary>
  ///     режим отработки
  /// </summary>
   CommandRegime:Integer;
   MessData:string;
   DTime:TDatetime;
  public
    class function GetCommandRegime(const aComName:String):integer;
    class function GetCommandName(aComRegime:integer):string;
    function GetCommandParams(const aParamsIdent:String='DATA'):string;
    /// <summary>
    ///    получить часть сообщения команды до первого "=" или после него
    /// </summary>
    function GetDataPart(aLeftFlag:Boolean; const aDiv:string='='):string;
    function ExtractDataFromString(const aDataStr:String):boolean;
    /// <summary>
    ///    получить описание в виде строки для отчета
    /// </summary>
    function DataToString(agetDataRegime:integer=1):string;
    procedure Assign(Source: TPersistent); override;
    constructor Create(const aCommand,aMsgData:String);
    constructor CreateFromString(const aData:String);
    /// <summary>
    ///     создание с помощью копии
    /// </summary>
    constructor CreateFrom(const aSource:TCodeTraceItem);
    function IsEmpty:boolean;
 end;
//////////////////////////////////////
///
///  with Indy
///
TUdpCodeTraceSocket=class(TObject)
  private
   FLastErrorStr:string;
   FUdpRegime:integer;
   FUdpClient:TIdUdpClient;
  public
   constructor Create(udp_Regime:integer);
   destructor Destroy; override;
   function SendString(const AStr:String):boolean;
end;

///////////////////////////////////////
 TCodeTraceManager=class(TObject)
  private
   FItemsEnabled:boolean;
   Socket:TUDpCodeTraceSocket;
   Items:TObjectList<TCodeTraceItem>;
   FEnabled:boolean;
   procedure SetItemsEnabled(Value:boolean);
  public
   procedure SendCommand(const aCommand,aMsgData:String);
    constructor Create(aTrRegime:integer);
    destructor Destroy; override;
   property Enabled:boolean read FEnabled write FEnabled;
   property ItemsEnabled:boolean read FItemsEnabled write SetItemsEnabled;
 end;

 /// <summary>
 ///     заполнить список из предустановленных команд - сервис
 ///     (вернет кол-во команд)
 /// </summary>
 function ct_FillCommandsList(aRegime:integer; const aItems:TStrings):integer;

implementation

uses System.Variants, DateUtils;

{ TCodeTraceItem }

const wct_Commands='user:,enter:,exit:,warn:,err:,note:,req:,info:,exclam:,opt:,app:,next:,prev:,clear:,minus:,plus:,quit:,data:';


function ct_FillCommandsList(aRegime:integer; const aItems:TStrings):integer;
 begin
  Result:=-1;
  if Assigned(aItems)=false then exit;
  if aRegime in [0,1] then
     aItems.CommaText:=wct_Commands;
  Result:=aItems.Count;
 end;

procedure TCodeTraceItem.Assign(Source: TPersistent);
var LSrc:TCodeTraceItem;
begin
  if (Assigned(Source)=false) and (Source is TCodeTraceItem=false) then exit;
  LSrc:=TCodeTraceItem(Source);
  CommandName:=LSrc.CommandName;
  CommandRegime:=LSrc.CommandRegime;
  MessData:=LSrc.MessData;
  DTime:=LSrc.DTime;
end;

constructor TCodeTraceItem.Create(const aCommand, aMsgData: String);
begin
  inherited Create;
  CommandRegime:=TCodeTraceItem.GetCommandRegime(aCommand);
  CommandName:=TCodeTraceItem.GetCommandName(CommandRegime);
  MessData:=Trim(aMsgData);
  DTime:=Now;
end;

constructor TCodeTraceItem.CreateFrom(const aSource: TCodeTraceItem);
begin
  inherited Create;
  CommandRegime:=-1;
  CommandName:='empty:';
  DTime:=Now;
  MessData:='';
  Assign(aSource);
end;

function TCodeTraceItem.IsEmpty:boolean;
 begin
   Result:=(CommandRegime=-1) or (CommandName='') or ((CommandName='empty:') and (MessData=''));
 end;

constructor TCodeTraceItem.CreateFromString(const aData:String);
 begin
   inherited Create;
   ExtractDataFromString(aData);
   DTime:=Now;
 end;

function TCodeTraceItem.DataToString(agetDataRegime: integer): string;
begin
  FormatSettings.LongTimeFormat:='hh:nn:ss.zzz';
  Result:=Concat(CommandName,' ',MessData,' TIME=',TimeToStr(DTime,FormatSettings));
end;

function TCodeTraceItem.ExtractDataFromString(const aDataStr: String): boolean;
var LCom,LDs,LS:string;
    i:integer;
begin
  LDS:='';
  i:=Pos(':',aDataStr);
  if (i>1) then
   begin
     LCom:=Copy(aDataStr,1,i);
     if i<Length(aDataStr) then
        LDs:=Copy(aDataStr,i+1,Length(aDataStr)-i);
   end
  else begin
        LCom:='user:';
        LDs:=aDataStr;
  end;
  ///
  CommandRegime:=TCodeTraceItem.GetCommandRegime(LCom);
  CommandName:=TCodeTraceItem.GetCommandName(CommandRegime);
  i:=Pos(' TIME=',LDs);
  if (i>0) and (i<Length(LDs)-6) then
    begin
      LS:=Copy(LDs,i+6,Length(LDs)-6-i);
      LDs:=Trim(Copy(LDs,1,i));
      TryStrToDateTime(LS,DTime);
    end;
  MessData:=LDs;
end;

function TCodeTraceItem.GetDataPart(aLeftFlag: Boolean; const aDiv: string='='): string;
var i,j,k:Integer;
begin
  i:=Pos(aDiv,MessData);
  j:=Length(MessData);
  k:=Length(aDiv);
  if (i>1) and (i<=j-k) then
     if aLeftFlag then
        Result:=Copy(MessData,1,i-1)
     else
        Result:=Copy(MessData,i+k,j-i-k+1)
  else
   if aLeftFlag then Result:=''
   else Result:=MessData;
 Result:=Trim(Result);
end;

class function TCodeTraceItem.GetCommandName(aComRegime: integer): string;
var LList:TStrings;
begin
  Result:='';
  LLIst:=TStringList.Create;
  try
    LList.CommaText:=wct_Commands;
    if (aComRegime>=0) and (aComRegime<LList.Count) then
       Result:=LList.Strings[aComRegime];
  finally
    LLIst.Free;
  end;
end;

function TCodeTraceItem.GetCommandParams(const aParamsIdent:String='DATA'): string;
var i,j,LL,iL:integer;
    LIdentStr:String;
begin
 Result:='';
 j:=0;
 LIdentStr:=Concat(aParamsIdent,'=[');
 LL:=Length(LIdentStr);
 i:=Pos(LIdentStr,MessData);
 if i>0 then
   begin
     iL:=Length(MessData);
     while iL>i+LL do
      begin
        if MessData[iL]=']' then
          begin
           j:=iL;
           break;
          end;
        Dec(iL);
      end;
   end;
 if (i>0) and (j>i+LL) then
   Result:=Copy(MessData,i+LL,j-i-LL);
end;

class function TCodeTraceItem.GetCommandRegime(const aComName: String): integer;
var LCommand:string;
    LChar:Char;
    LList:TStrings;
    i:integer;
begin
  Result:=-1;
  LCommand:=Trim(lowerCase(aComName));
  if LCommand='' then exit;
  /// нач. замена
  LChar:=LCommand[1];
  if Length(LCommand)=1 then
      case LChar of
       'e': LCommand:='err';
       'w': LCommand:='warn';
       '!': LCommand:='exclam';
       'i': LCommand:='info';
       'c','a': LCommand:='app';
       '>': LCommand:='enter';
       '<': LCommand:='exit';
       '?','r': LCommand:='req';
       'l','n': LCommand:='note';
       '+': LCommand:='plus';
       '-': LCommand:='minus';
       'o': LCommand:='opt';
       '.',',': LCommand:='user';
       'q':  LCommand:='quit';
       'd','D': LCommand:='data';
      end;
  /// синонимы
  if (Pos('error',LCommand)=1) then
     LCommand:='err'
  else if (Pos('warning',LCommand)=1) then
       LCommand:='warn'
       else
         if (Pos('exc',LCommand)=1) then
             LCommand:='exclam'
         else if (Pos('command',LCommand)=1) then
               LCommand:='app';
  //
  if LCommand[Length(LCommand)]<>':' then
     LCommand:=Concat(LCommand,':');
  ///
  LLIst:=TStringList.Create;
  try
    LList.CommaText:=wct_Commands;
    i:=0;
    while i<LList.Count do
     begin
       if POs(LList.Strings[i],LCommand)=1 then
         begin
           Result:=i;
           break;
         end;
       Inc(i);
     end;
  finally
    LLIst.Free;
  end;
end;



{ TCodeTraceManager }

constructor TCodeTraceManager.Create(aTrRegime: integer);
begin
 inherited Create;
 FEnabled:=true;
 FItemsEnabled:=false;
 Items:=TObjectList<TCodeTraceItem>.Create(true);
 Socket:=TUdpCodeTraceSocket.Create(0);
end;

destructor TCodeTraceManager.Destroy;
begin
  Items.Free;
  Socket.Free;
  inherited;
end;

procedure TCodeTraceManager.SendCommand(const aCommand, aMsgData: String);
var LItem:TCodeTraceItem;
    L_AddItemFlag:Boolean;
   // LS:string;
begin
 if FEnabled=false then exit;
 LItem:=TCodeTraceItem.Create(aCommand,aMsgData);
 try
  if LItem.CommandName='' then
   begin
    // для неописанных команд (или некорректных)
     LItem.CommandName:='user:';
     LItem.MessData:=Concat('(',aCommand,')> ',LItem.MessData);
   end;
  L_AddItemFlag:=false;
  if (FItemsEnabled) and (LItem.CommandName<>'data') then
   begin
     Items.Add(LItem);
     L_AddItemFlag:=true;
   end;
   // send
  if Socket.FUdpClient.Connected=false then
     Socket.FUdpClient.Connect;
  ///  в сокет идут уже команды со скорректированным именем и данными
  if Socket.FUdpClient.Connected=true then
   begin
      Socket.SendString(LItem.DataToString(0));
     { LS:=Wide(LItem.MessData);
      Socket.SendString(Concat(LItem.CommandName,LS));
      }
   end;
   ///
 finally
  if L_AddItemFlag=false then
     LItem.Free;
 end;
end;

procedure TCodeTraceManager.SetItemsEnabled(Value: boolean);
begin
 if Value=false then
   Items.Clear;
 FItemsEnabled:=Value;
end;

{ TUdpCodeTraceSocket }

constructor TUdpCodeTraceSocket.Create(udp_Regime: integer);
begin
  inherited Create;
  FUdpRegime:=udp_Regime;
  FUdpClient:=TIdUdpClient.Create(nil);
  FUdpClient.Port:=25678;
  FUdpClient.Host:='127.0.0.1';
  FUdpClient.Host:='localhost';
  FUdpClient.Active:=true;
 // FUdpClient.ReceiveTimeout:=5000;
end;

destructor TUdpCodeTraceSocket.Destroy;
begin
  FUdpClient.Disconnect;
  FreeAndNil(FUdpClient);
  inherited;
end;

function TUdpCodeTraceSocket.SendString(const AStr: String): boolean;
begin
 Result:=false;
 try
   FUdpClient.Send(Astr,IndyTextEncoding(encUTF8));
   Result:=true;
   except
         // may generate EIdPackageSizeTooBig exception if the message is too long
     on e:EIdPackageSizeTooBig do begin
            FLastErrorStr := e.Message ;
         end ;
  end;
end;

end.
