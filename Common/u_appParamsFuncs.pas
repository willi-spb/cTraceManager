
unit u_appParamsFuncs;

interface

function wa_Local_GetSpecialFolderPath(afolder: integer): string;
function wa_Local_CreateAppCurrentUserDirectory(const nAppName:string; var aResultDir:string; aRegime:Integer=0):Integer;

function wa1_IsAdmin: boolean;
function wa1_getUserName: String;
function wa1_UserIsAdminsGroup: boolean;
//
/// Внимание ! переделка 15/12/2015 - логика: в win10 не определяется
///                                           версия - пишет 6.2,///
///    переписаны эти функции
{ function wa_GetWindowsVersionNum:Integer;
  function wa_Local_GetWindowsVersionStr(aRegime:integer=1):string;
 }
function wa_GetWindowsVersionNum:Integer;
function wa_Local_GetWindowsVersionStr:string;
///
function _Is64bits: Boolean;
///
function CompleteUserInfoStrWithData(acompRG:integer; var aUserGroup:integer):string;
procedure CompleteUserInfo(var aUserGroupType:Integer; var aUserGroupAbb,AUsername,ACompleteStr:string);
function CompleteUserInfoStr(acompRG:integer):string;
function CompleteWinVersionInfoStr(aCompRg:integer):String;

///
implementation

{$IFDEF MSWINDOWS}
uses Sysutils,
    ///// u_getVersion,
     System.IOUtils,
     Winapi.Windows,
     Winapi.ShlObj;
{$ELSE}
  uses System.Classes, System.Variants, System.SysUtils;
{$ENDIF}

/////////////////////////////////////////////////////////////////////////////////////////////
////
///   1. Files

function wa_Local_GetSpecialFolderPath(afolder: integer): string;
const
  SHGFP_TYPE_CURRENT = 0;
  MAX_PATH = 260;
var
  path: array [0 .. MAX_PATH] of char;
   function L_Succeeded(Res: HResult): Boolean;
      begin
        Result := Res and $80000000 = 0;
      end;
begin
  if L_SUCCEEDED(SHGetFolderPath(0, afolder, 0, SHGFP_TYPE_CURRENT, @path[0]))
  then
    Result := path
  else
    Result := '';
end;


 function wa_Local_CreateAppCurrentUserDirectory(const nAppName:string; var aResultDir:string; aRegime:Integer=0):Integer;
var LS:string;
    LFlag:Boolean;
 // const CSIDL_LOCAL_APPDATA=28;
 begin
  Result:=-1;
  Assert(nAppName<>'','CreateAppCurrentUserDirectory: application name is empty!');
  try
   LS:=Tpath.GetHomePath;
   except LS:='';
  end;
  if LS='' then
   try
     LS:=wa_Local_GetSpecialFolderPath(CSIDL_LOCAL_APPDATA);
    except
      LS:='';
   end;
  ///
  if LS='' then begin Result:=-100; Exit; end;
  //
  LS:=Concat(LS,TPath.DirectorySeparatorChar,nAppName);
  try
   LFlag:=False;
   LFlag:=ForceDirectories(LS);
   except
    begin
     Result:=100;
     Exit;
    end;
  end;
  if LFlag=false then begin Result:=10; Exit; end;
  ///
  Result:=0; // !
  aResultDir:=LS;
 end;

///////////////////////////////////////////////////////////////////////////////
///
///  2.  User Admins
const
  SECURITY_NT_AUTHORITY: TSIDIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 5));
  SECURITY_BUILTIN_DOMAIN_RID = $00000020;
  DOMAIN_ALIAS_RID_ADMINS = $00000220;

function wa1_IsAdmin: boolean;
var
  hAccessToken: THandle;
  ptgGroups: PTokenGroups;
  dwInfoBufferSize: winapi.Windows.DWORD;
  psidAdministrators: PSID;
  x: integer;
  bSuccess: BOOL;
begin
  Result := false;
  bSuccess := OpenThreadToken(GetCurrentThread, TOKEN_QUERY, true,
    hAccessToken);
  if not bSuccess then
  begin
    if GetLastError = ERROR_NO_TOKEN then
      bSuccess := OpenProcessToken(GetCurrentProcess, TOKEN_QUERY,
        hAccessToken);
  end;
  if bSuccess then
  begin
    GetMem(ptgGroups, 1024);
    bSuccess := GetTokenInformation(hAccessToken, TokenGroups, ptgGroups, 1024,
      dwInfoBufferSize);
    CloseHandle(hAccessToken);
    if bSuccess then
    begin
      AllocateAndInitializeSid(SECURITY_NT_AUTHORITY, 2,
        SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0,
        psidAdministrators);
{$R-}
      for x := 0 to ptgGroups.GroupCount - 1 do
        if EqualSid(psidAdministrators, ptgGroups.Groups[x].Sid) then
        begin
          Result := true;
          Break;
        end;
{$R+}
      FreeSid(psidAdministrators);
    end;
    FreeMem(ptgGroups);
  end;
end;

{ function wa1_getUserName: String;
  var
  Buffer: PChar;
  BufSize: DWord;
  begin
  BufSize := 1024;
  SetLength(Result, BufSize);
  if GetUserName(PChar(Buffer), BufSize) then
  SetLength(Result, BufSize-1)
  else
  RaiseLastOSError;
  end;
}
function wa1_getUserName: String;
var
  BufSize: DWORD;
  Buffer: PChar;
begin
  BufSize := 1024;
  Buffer := StrAlloc(BufSize);
  try
    if GetUserName(Buffer, BufSize) then
      SetString(Result, Buffer, BufSize - 1)
    else
      RaiseLastOSError;
  finally
    StrDispose(Buffer);
  end;
end;

/// //////////////////////////////////////////////////////////
///
///
Const
  // SECURITY_NT_AUTHORITY: TSIDIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 5));
  // SECURITY_BUILTIN_DOMAIN_RID = $00000020;
  // DOMAIN_ALIAS_RID_ADMINS     = $00000220;
  DOMAIN_ALIAS_RID_USERS = $00000221;
  DOMAIN_ALIAS_RID_GUESTS = $00000222;
  DOMAIN_ALIAS_RID_POWER_USERS = $00000223;

function CheckTokenMembership(TokenHandle: THandle; SidToCheck: PSID;
  var IsMember: BOOL): BOOL; stdcall; external advapi32;

function UserInGroup(Group: DWORD): boolean;
var
  pIdentifierAuthority: TSIDIdentifierAuthority;
  PSID: Winapi.Windows.PSID;
  IsMember: BOOL;
begin
  pIdentifierAuthority := SECURITY_NT_AUTHORITY;
  Result := AllocateAndInitializeSid(pIdentifierAuthority, 2,
    SECURITY_BUILTIN_DOMAIN_RID, Group, 0, 0, 0, 0, 0, 0, PSID);
  try
    if Result then
      if not CheckTokenMembership(0, PSID, IsMember) then
      // passing 0 means which the function will be use the token of the calling thread.
        Result := false
      else
        Result := IsMember;
  finally
    FreeSid(PSID);
  end;
end;

type
  TGetNativeSystemInfo1 = procedure (var lpSystemInfo: TSystemInfo); stdcall;

function wa1_UserIsAdminsGroup: boolean;
begin
  Result := UserInGroup(DOMAIN_ALIAS_RID_ADMINS);
end;

///////////////////////////////////////////////////////////////////////
////
///  вставка из Инета
///
type
  PPEB=^PEB;
  PEB = record
    InheritedAddressSpace: Boolean;
    ReadImageFileExecOptions: Boolean;
    BeingDebugged: Boolean;
    Spare: Boolean;
    Mutant: Cardinal;
    ImageBaseAddress: Pointer;
    LoaderData: Pointer;
    ProcessParameters: Pointer; //PRTL_USER_PROCESS_PARAMETERS;
    SubSystemData: Pointer;
    ProcessHeap: Pointer;
    FastPebLock: Pointer;
    FastPebLockRoutine: Pointer;
    FastPebUnlockRoutine: Pointer;
    EnvironmentUpdateCount: Cardinal;
    KernelCallbackTable: PPointer;
    EventLogSection: Pointer;
    EventLog: Pointer;
    FreeList: Pointer; //PPEB_FREE_BLOCK;
    TlsExpansionCounter: Cardinal;
    TlsBitmap: Pointer;
    TlsBitmapBits: array[0..1] of Cardinal;
    ReadOnlySharedMemoryBase: Pointer;
    ReadOnlySharedMemoryHeap: Pointer;
    ReadOnlyStaticServerData: PPointer;
    AnsiCodePageData: Pointer;
    OemCodePageData: Pointer;
    UnicodeCaseTableData: Pointer;
    NumberOfProcessors: Cardinal;
    NtGlobalFlag: Cardinal;
    Spare2: array[0..3] of Byte;
    CriticalSectionTimeout: LARGE_INTEGER;
    HeapSegmentReserve: Cardinal;
    HeapSegmentCommit: Cardinal;
    HeapDeCommitTotalFreeThreshold: Cardinal;
    HeapDeCommitFreeBlockThreshold: Cardinal;
    NumberOfHeaps: Cardinal;
    MaximumNumberOfHeaps: Cardinal;
    ProcessHeaps: Pointer;
    GdiSharedHandleTable: Pointer;
    ProcessStarterHelper: Pointer;
    GdiDCAttributeList: Pointer;
    LoaderLock: Pointer;
    OSMajorVersion: Cardinal;
    OSMinorVersion: Cardinal;
    OSBuildNumber: Cardinal;
    OSPlatformId: Cardinal;
    ImageSubSystem: Cardinal;
    ImageSubSystemMajorVersion: Cardinal;
    ImageSubSystemMinorVersion: Cardinal;
    GdiHandleBuffer: array [0..33] of Cardinal;
    PostProcessInitRoutine: Cardinal;
    TlsExpansionBitmap: Cardinal;
    TlsExpansionBitmapBits: array [0..127] of Byte;
    SessionId: Cardinal;
  end;

  //Get PEB block current win32 process
function GetPDB: PPEB; stdcall;
asm
  MOV EAX, DWORD PTR FS:[30h]
end;

//Detect true windows wersion
{  Win32MajorVersionReal := GetPDB^.OSMajorVersion;
  Win32MinorVersionReal := GetPDB^.OSMinorVersion;
 }

//////////////////////////////////////////////////////////////////////////////
//////////
//////////


////////////////////////////////////////////////////
////
///  3. Windows version
function wa_GetWindowsVersionNum:Integer;
var L:longint;
    L_Major, L_Minor: integer;
 begin
    Result:=0;
    L := GetVersion;
    L_Major := LoByte(LoWord(l));
    L_Minor := HiByte(LoWord(l));
     case L_Major of
      1..5: Result:=L_Major;
      6: case L_Minor of
               0:  Result:=6;
               1:  Result:=7;
               else Result:=8;
              end;
      10: Result:=10;  // win 10
     end;
    ///
    if (L_Major=6) and (L_Minor>1) then
     begin
       Result:=GetPDB^.OSMajorVersion;
     end;
    ///
 end;

 function wa_Local_GetWindowsVersionStr:string;
  var L_Major, L_Minor,ilR: integer;
      LS:string;
      L:longint;
   begin
     Result:='';
     LS:='';
    L_Major:=0; L_Minor:=0;
   { L_Major
     Windows 95 - 4
     Windows 98 - 4
     Windows Me - 4
     Windows NT 3.51 - 3
     Windows NT 4.0 - 4
     Windows 2000 - 5
     Windows XP - 5
     ///
     L_minor
     Windows 95 - 0
     Windows 98 - 10
     Windows Me - 90
     Windows NT 3.51 - 51
     Windows NT 4.0 - 0
     Windows 2000 - 0
     Windows XP - 1
     }
     L := GetVersion;
     L_Major := LoByte(LoWord(l));
     L_Minor := HiByte(LoWord(l));
        case L_Major of
          3:  case L_Minor of
               51:   LS:='win351';
               else LS:='win3';
              end;
          4:  case L_Minor of
               0:   LS:='win95';
               10:  LS:='win98';
               90:  LS:='winME';
               else LS:='win9';
              end;
          5: case L_Minor of
               0:   LS:='win2000';
               1:  LS:='winXP';
               else LS:='winXP';
              end;
           6: case L_Minor of
               0:   LS:='winVISTA';
               1:  LS:='win7';
               else
                begin
                  ilR:=GetPDB^.OSMajorVersion;
                  LS:='win'+IntToStr(ilR);
                end;
              end;
          10: LS:='win10';
        end;
      Result:=LS;
   end;

///
function _Is64bits: Boolean;
 var
  h: THandle;
  si: TSystemInfo;
  getinfo: TGetNativeSystemInfo1;
 begin
  Result := False;
  H := GetModuleHandle('kernel32.dll');
  try
    ZeroMemory(@SI, SizeOf(SI));
    getinfo := TGetNativeSystemInfo1(GetProcAddress(h, 'GetNativeSystemInfo'));
    if not Assigned(@getinfo) then
      Exit;
    getinfo(SI);
    if SI.wProcessorArchitecture in
       [PROCESSOR_ARCHITECTURE_AMD64, PROCESSOR_ARCHITECTURE_IA64] then
      Result := True;
  finally
    FreeLibrary(H);
  end;
end;


///////////////////////////////////////////////////////////////
///
///
function CompleteUserInfoStrWithData(acompRG:integer; var aUserGroup:integer):string;
var LUserType:integer;
    LuserTypeStr,LUsername:string;
 begin
    Result:='';
   LuserType:=0;
   aUserGroup:=0;
   try
   if wa1_IsAdmin then LuserType:=1;
   if wa1_UserIsAdminsGroup then LuserType:=2;
   case LuserType of
    0: LuserTypeStr:='user';
    1: LuserTypeStr:='puser';
    2: LuserTypeStr:='admin';
    else LuserTypeStr:='ghost';
   end;
    except Lusertype:=-1;
   end;
   if Lusertype=-1 then LuserTypeStr:='errUser';
   LUserName:='unknown';
   try
    LuserName:=wa1_getUserName;
   except LuserName:='err_getUser';
   end;
   //
   case acompRG of
    0,1: Result:=Concat('USER:',LUsername,' cat:',LuserTypeStr);
   end;
   aUserGroup:=LUserType;
 end;

procedure CompleteUserInfo(var aUserGroupType:Integer; var aUserGroupAbb,AUsername,ACompleteStr:string);
 var LUserType:integer;
    LuserTypeStr,LUsername:string;
 begin
   LuserType:=0;
   aUserGroupType:=0;
   try
   if wa1_IsAdmin then LuserType:=1;
   if wa1_UserIsAdminsGroup then LuserType:=2;
   case LuserType of
    0: LuserTypeStr:='user';
    1: LuserTypeStr:='puser';
    2: LuserTypeStr:='admin';
    else LuserTypeStr:='ghost';
   end;
    except Lusertype:=-1;
   end;
   if Lusertype=-1 then LuserTypeStr:='errUser';
   LUserName:='unknown';
   try
    LuserName:=wa1_getUserName;
   except LuserName:='err_getUser';
   end;
   //
   aUserGroupAbb:=LuserTypeStr;
   AUsername:=LUsername;
   aUserGroupType:=LUserType;
   ACompleteStr:=Concat('USER:',LUsername,' cat:',LuserTypeStr);
 end;

function CompleteUserInfoStr(acompRG:integer):string;
var LL:Integer;
begin
 LL:=0;
 Result:=CompleteUserInfoStrWithData(acompRG,LL);
end;

 function CompleteWinVersionInfoStr(aCompRg:integer):String;
 var LWinAbb,Lis64:string;
  begin
    Result:='';
    Lwinabb:=wa_Local_GetWindowsVersionStr;
    if _Is64bits then
       Lis64:='64'
    else Lis64:='32';
    case acompRG of
    0,1: Result:=Concat('WIN:',LwinAbb,' arch:',Lis64);
   end;
  end;

end.
