unit ServiceClasses;
/// <summary>
///   FMX:  универсальный класс опроса версии ПО и системы
///      Важно:  опрос системы и т.п. происходит в конструкторе
///              большинство свойств - доступно только по чтению
/// </summary>
interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
{$IFDEF FMX}
  FMX.Types,
{$ENDIF}
{$IFDEF ANDROID}
  Androidapi.JNI.JavaTypes, FMX.Helpers.Android,
  Androidapi.JNI,
   androidapi.JNI.Os,
   Androidapi.Helpers,
  Androidapi.JNI.GraphicsContentViewText,
{$ENDIF}
{$IFDEF MSWINDOWS}
 windows, u_getVersion,
 u_appParamsFuncs,
{$ENDIF}
{$IFDEF FMX}
  FMX.Objects,
{$ENDIF}
System.Variants;

 const ver_winOrderNumber=3; // 1.2.3.4 - это порядок чисел для Win-версии

type

 TFMServiceClass=class(TObject)
  private
   Fis64:Boolean; // only for Win
   FstrX:string;  // '' if not Win
   FwinNumRegime:Integer;
   _FullName,FappName,FappVersionStr,FappVersionAbb:string;
   FappVersion:Integer;
   FMj1,FMj2,FMi1,FMi2:Integer;
   F_OS,FDeviceModel,FPlatformStr,FPlatformAbb:string;
   FUserCatType:Integer;
   FUserCatAbb,FUserCatName,FUserName:string;
   /// <summary>
   ///  внутр. функция - номер с учетом заданного режима
   /// </summary>
   function GetAppVersion:Integer;
   function GetDeviceInfoDesc:string;
   function GetAppVersionCode3:Integer;
  protected
   {$IFDEF ANDROID}
    PackageManager: JPackageManager;
    VersionPackage,PackageName: JString;
   {$ENDIF}
  public
   constructor Create; virtual;
   destructor destroy; override;
   /// <summary>
   ///   проверить версию по строке с версией true - требуется обновление
   /// </summary>
   function VerifyAppVersion(const aVerStr:string):Boolean;
   /// <summary>
   ///     вспомогат. получить номера версии
   /// </summary>
   procedure GetVersionNumbers(var aMajor,aMinor:integer);
   /// <summary>
   ///  получить строку с заданной точностью версии  1..3
   /// </summary>
   function GetAppVersionString(aPrecisionNum:integer):string;
   ///
   property Is64:boolean read Fis64;
   /// <summary>
   ///     x64 или x86  или что-то еще или пусто
   /// </summary>
   property strX:string read FstrX;
   /// <summary>
   ///      например 1002003   это 1.2.3.
   /// </summary>
   property appVersionCode3:Integer read GetAppVersionCode3;
   property appVersionStr:string read FappVersionStr;
   /// <summary>
   ///    без точек
   /// </summary>
   property appVersionAbb:string read FappVersionAbb;
   property appName:string read Fappname;
   ///
   property OS:string read F_OS;
   /// <summary>
   ///      для андроида - модель телефона
   /// </summary>
   property DeviceModel:string read FDeviceModel;
   property DevInfoDesc:string read GetDeviceInfoDesc;
   ///
   property UserCategoryAbb:string read FUserCatAbb;
   property UserName:string read FUserName;
   property UserCatType:integer read FUserCatType;
   property PlatformAbb:string read FPlatformAbb;
   ///
 end;

implementation

////////////////////////////////////////////////////////////////////
///
///  достать из строки номера
function ExtractVersion(const aStr:string; var am1,am2,ai1,ai2:integer):integer;
 var L_Sver:TStrings;
     il,L_F:integer;
  begin
    Result:=0;
    L_Sver:=TStringList.Create;
    try
      L_Sver.Delimiter:='.';
      L_Sver.DelimitedText:=aStr;
      ///
      il:=0;
      while (il<L_Sver.Count) and (il<4) do
       begin
         L_F:=-1;
         TryStrToInt(L_Sver.Strings[il],L_F);
         if L_F<0 then L_F:=0;
         case il of
          0: am1:=L_F;
          1: am2:=L_F;
          2: ai1:=L_F;
          3: ai2:=L_F;
         end;
         Inc(il);
       end;
     Result:=L_Sver.Count;
    finally
     L_Sver.Free;
    end;
  end;

 /////////////////////////////////////////////////////////////////////////////
 ///
 ///   копия из u_getVersion  - данный модуль втыкается только для win - поэтому
 ///   скопировал процедуру сюда
function _VerifyNewVersionFromStr(const aFileVers,aSitevers:string):Boolean;
 var L_Fver,L_Sver:TStringList;
     il,L_F,L_S:Integer;
  begin
    Result:=False;
    L_Fver:=TStringList.Create;
    L_Sver:=TStringList.Create;
    try
      L_Fver.Delimiter:='.';
      L_Fver.DelimitedText:=aFileVers;
      L_Sver.Delimiter:='.';
      L_Sver.DelimitedText:=aSitevers;
      ///
      il:=0;
      while (il>=0) and (il<L_Fver.Count) and (il<L_Sver.Count) do
       begin
         L_F:=-1;
         TryStrToInt(L_Fver.Strings[il],L_F);
         L_S:=-1;
         TryStrToInt(L_Sver.Strings[il],L_S);
         if (L_F>=0) and (L_S>=0) then
          begin
            if (L_F>L_S) then  begin
                                 // il:=-100; Result:=false; break; Exit;
                                 Break; // !
                               end; // ситуация отладки
            if (L_S>L_F) then
             begin
               Result:=True;
               Break;
             end;
          end;
         Inc(il);
       end;
       ///
       if il<=-10 then
          raise Exception.Create(Concat('Error compare versions strings! file=',aFileVers,' site=',aSitevers));
       ///
       ///
     finally
     L_Fver.Free;
     L_Sver.Free;
    end;
  end;

//////////////////////////////////////////////////////////////////////////
////   вспомогат. функции
function _getPlatform(aRegime:integer):string;
 begin
  if aRegime=1 then
      case TOSVersion.Platform of
       pfWindows:  Result:='WINDOWS';
       pfMacOS:    Result:='MACOS';
       pfiOS:      Result:='iOS';
       pfAndroid:  Result:='ANDROID';
       pfWinRT:    Result:='WINRT';
       pfLinux:    Result:='LINUX';
       else Result:='UNKNOWN';
      end;
  if aRegime=0 then
      case TOSVersion.Platform of
       pfWindows:  Result:='WIN';
       pfMacOS:    Result:='MACOS';
       pfiOS:      Result:='iOS';
       pfAndroid:  Result:='ANDR';
       pfWinRT:    Result:='WINRT';
       pfLinux:    Result:='LINUX';
       else Result:='UNK';
      end;
 end;

 /// Определить разрядность win
  ///
  /// /////
 {$IFDEF MSWINDOWS}
  function _IsWow64: bool;
  type
    TIsWow64Process = function(hProcess: THandle; var Wow64Process: bool)
      : bool; stdcall;
  var
    IsWow64Process: TIsWow64Process;
  begin
    Result := false;
    @IsWow64Process := GetProcAddress(GetModuleHandle(kernel32),
      'IsWow64Process');
    if Assigned(@IsWow64Process) then
      IsWow64Process(GetCurrentProcess, Result);
  end;
 {$ENDIF}


//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

  function TFMServiceClass.GetAppVersion:Integer;
   begin
   {$IFDEF MSWINDOWS}
    begin
    end;
    {$ELSE}
     Result:=FappVersion;
     if (FappVersionStr<>'') then
      begin
        FMi2:=0; // file  version 1.2.3  (not 4)
        if ExtractVersion(FappVersionStr,FMj1,FMj2,FMi1,FMi2)<3 then
         begin
          ///
         end;
      end;
    {$ENDIF}
     case FwinNumRegime of
       1: Result:=FMj1;
       2: Result:=FMj2;
       3: Result:=FMi1;
       4: Result:=FMi2;
       else Result:=-1;
     end;
   end;

  function TFMServiceClass.GetDeviceInfoDesc:string;
  var L64:string;
   begin
     if Fis64 then L64:='64' else L64:='';
     Result:=Concat(FDeviceModel,',',FPlatformAbb,L64,',',F_OS);
   end;

  function TFMServiceClass.GetAppVersionCode3:Integer;
   begin
     Result:=FMj1*1000000+FMj2*1000+FMi1;
   end;

  constructor TFMServiceClass.Create;
   {$IFDEF MSWINDOWS}
   // var si: TSystemInfo;
   {$ENDIF}
   begin
     inherited;
     Fis64:=False;
     FstrX:='';
     FappName:='';
     FappVersionStr:='';
     FappVersion:=-1;
     FwinNumRegime:=ver_winOrderNumber; // !
     {$IFDEF MSWINDOWS}
        _FullName:=ParamStr(0);
        FappName:=ExtractFileName(_FullName);
        FappVersionStr:=wa_GetFileVersionShortStr(_FullName,3);
        wa_GetFileVersion(_FullName,FMj1,FMj2,FMi1,FMi2);
       // GetSystemInfo(si);
        FDeviceModel:='PC';
        Fis64:=_IsWow64;
        if Fis64=true then FstrX:='x64' else FstrX:='x32';
        ///
     {$ENDIF}
     ///
     {$IFDEF ANDROID}
       PackageManager := SharedActivity.getPackageManager;
       PackageName := SharedActivityContext.getPackageName;
       VersionPackage := PackageManager.getPackageInfo(PackageName, 0).versionName;
       FappVersionStr:=JStringToString(VersionPackage);
       FappName:=JStringToString(VersionPackage);
       FDeviceModel:=JStringToString(TJBuild.JavaClass.MODEL);
      // FDeviceModel:=JStringToString(TJBuild.JavaClass.MODEL);
     {$ENDIF}
     ///
     F_OS:=TOSVersion.Name;
     FPlatformStr:=_getPlatform(1);
     FPlatformAbb:=_getPlatform(0);
     FappVersionAbb:=StringReplace(FappVersionStr,'.','',[rfReplaceAll]);
     ///
     FUserCatType:=1;
     FUserCatAbb:='user';
     FUserName:='';
     {$IFDEF MSWINDOWS}
        CompleteUserInfo(FUserCatType,FUserCatAbb,FUserName,FUserCatName);
     {$ENDIF}
     ///
   end;

  destructor TFMServiceClass.destroy;
   begin
     ///
     inherited;
   end;

  function TFMServiceClass.VerifyAppVersion(const aVerStr:string):Boolean;
   begin
     if aVerStr='' then Result:=false
     else
        Result:=_VerifyNewVersionFromStr(FappVersionStr,aVerStr);
   end;

   procedure TFMServiceClass.GetVersionNumbers(var aMajor,aMinor:integer);
    begin
      aMajor:=FMj1;
      aMinor:=FMi1;
    end;

function TFMServiceClass.GetAppVersionString(aPrecisionNum: integer): string;
var i,LPrec:integer;
const L_verSep='.';
begin
  Result:='';
  if (aPrecisionNum<0) or (aPrecisionNum>4) then LPrec:=3
  else LPrec:=aPrecisionNum;
  i:=0;
  while i<aPrecisionNum do
    begin
      case i of
         0: Result:=IntToStr(FMj1);
         1: Result:=Concat(Result,L_verSep,IntToStr(FMj2));
         2: Result:=Concat(Result,L_verSep,IntToStr(FMi1));
         3: Result:=Concat(Result,L_verSep,IntToStr(FMi2));
      end;
      Inc(i);
    end;
  if Result='' then Result:=FappVersionStr;
end;

end.
