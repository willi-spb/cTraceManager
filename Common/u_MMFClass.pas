unit u_MMFClass;
/// проверка одиночности экземпл€ра приложени€ - только Windows!
///  т.к. использован MapFile  -- допускает передачу данных ограниченного размера
///  от одного экземпл€ра в другой в виде строки в команде сообщени€ (только Win)
///
interface

uses  Winapi.Windows, Winapi.messages, SysUtils, Classes;


/// <summary>
///    настройки дл€ отправки данных через файл
/// </summary>
const Def_MemFileSize=127;
      Def_MemMessageID=WM_USER+86;

type
 /// <summary>
 ///   тип записи дл€ отправки через mapFile
 /// </summary>
 TMFRecord=record
   AppHandle:NativeUInt;
   sRegime:integer;
   DataStrPtr:array[0..32767] of WideChar;
 end;
 pTMFRecord=^TMFRecord;


 /// <summary>
 ///   класс работает с экземпл€рами приложени€ (допуска€ запуск только 1 экз.
 ///   и пересыла€ (если оказываетс€, что уже запущено) в другой строку с данными
 ///     (исп. пересылка через TMFRecord - через MapFile - размер строки ограничен 32767)
 /// </summary>
 TMDataHandling=class
  private
   FAppHandle:NativeUInt;
   FinitFlag:Boolean;  // false - если поток не удалось создать / открыть
   FMemFileSize:Integer;
   FMessageID:Cardinal; //
   FMfilename:string;
   /// <summary>
   ///    список имен окон дл€ поиска при отправке сообщений -
   ///    имена дл€ форм Firemonkey  имеют системный префикс FM т.е если глав.форма Main (TMain) -> FMTMain
   /// </summary>
   FWNames:TStrings;
   MemHnd: hWnd;
   /// <summary>
   ///       режим - дл€ декодировки - исп. только в сообщении
   /// </summary>
   FRegime,FRparam:Integer;

   /// <summary>
   ///    указывает на то первый это экземпл€р или последующий
   /// </summary>
   FFirstFlag:Boolean;
  // F_firstBaseRecord:TMFRecord;
  protected
   function FindWindowAndPost(app_Handle:HWND):Boolean;
  public
   LastErrCode:cardinal;
   lpBaseAddress: pTMFRecord;
   ///
   constructor Create(ApHandle:NativeUInt; const mpIdentStr, wndClassNames:string);
   destructor Destroy; override;
   function SendDataStr(const AStr:string):Boolean;
   function GetDataStr:string;  // или пусто - если нет
  ///
  property InitFlag:boolean read FinitFlag;
  property FirstFlag:boolean read FFirstFlag;
  property AppHandle:NativeUInt read FAppHandle;
  property MessageID:Cardinal read FMessageID;
  property Regime:Integer read FRegime write FRegime;
  property RParam:Integer read FRparam write FRparam;
end;


var  MFHandling:TMDataHandling=nil;


implementation

uses System.StrUtils;

function TMDataHandling.FindWindowAndPost(app_Handle:HWND):Boolean;
var il:integer;
    Lwin: hWnd;
 begin
  Result:=False;
  Lwin:=0;
  il:=0;
  while il<FWNames.Count do
   begin
     if Trim(FWNames.Strings[il])<>'' then
              begin
                Lwin:=FindWindowExW(GetAncestor(app_Handle, GA_PARENT), 0,
                  PChar(Trim(FWNames.Strings[il])),nil);
                if Lwin>0 then
                  Break;
              end;
     Inc(il);
    end;
   if Lwin>0 then
    begin
      PostMessageW(LWin,FMessageID,FRegime,FRparam);
      Result:=True;
    end;
 end;

constructor TMDataHandling.Create(ApHandle:NativeUInt; const mpIdentStr, wndClassNames:string);
  begin
    FRegime:=0;
    FRparam:=0;
    FinitFlag:=False;
    FFirstFlag:=False;
    lpBaseAddress:=nil;
    FMemFileSize:=Def_MemFileSize;
    FMessageID:=Def_MemMessageID;
    //
    FAppHandle:=ApHandle;
    if mpIdentStr<>'' then FMfilename:=Trim(mpIdentStr)
    else
     begin
      FMfilename :=ParamStr(0);
      FMfilename := ReplaceText(FMfilename,'\', '/');
     end;
    ///
    FWNames:=TStringList.Create;
    FWNames.CommaText:=wndClassNames;
       if FWNames.Count<=0 then
          FWNames.Append(wndClassNames);
    ///
    MemHnd := CreateFileMapping(hWnd($FFFFFFFF), nil, PAGE_READWRITE, 0,
    FMemFileSize, PChar(FMfilename));
    LastErrCode:=GetLastError;
    if (LastErrCode=ERROR_FILE_INVALID) or (LastErrCode=ERROR_INVALID_HANDLE) or
        (LastErrCode=ERROR_DISK_FULL) then Exit;
    ///
    if MemHnd=0 then Exit;
    ///
    if (LastErrCode <> ERROR_ALREADY_EXISTS) then
     begin
       FFirstFlag:=True;
       lpBaseAddress :=MapViewOfFile(MemHnd, FILE_MAP_ALL_ACCESS, 0, 0, 0);
       if lpBaseAddress <> nil then
        begin
             lpBaseAddress^.AppHandle:=FAppHandle;
          FinitFlag:=True;
        end;
      end
     else
       begin
          lpBaseAddress := MapViewOfFile(MemHnd, FILE_MAP_ALL_ACCESS, 0, 0, 0);
           if lpBaseAddress <> nil then
            begin
              FinitFlag:=True;
            end;
       end;
   { if lpBaseAddress <> nil then
       UnMapViewOfFile(lpBaseAddress);
       }
  end;

 destructor TMDataHandling.Destroy;
  begin
    if lpBaseAddress <> nil then
       UnMapViewOfFile(lpBaseAddress);
    if MemHnd<>0 then CloseHandle(MemHnd);
    FreeAndNil(FWNames);
    inherited Destroy;
  end;

 function TMDataHandling.SendDataStr(const AStr:string):Boolean;
  begin
    Result:=False;
    if (lpBaseAddress <> nil) and (lpBaseAddress^.AppHandle<>0) then
     begin
      // lpBaseAddress^.DataStr;
       StringToWideChar(AStr,lpBaseAddress^.DataStrPtr,SizeOf(lpBaseAddress^.DataStrPtr));
       Sleep(12);
       Result:=FindWindowAndPost(lpBaseAddress^.AppHandle);
     end;
  end;

 function TMDataHandling.GetDataStr:string;  // или пусто - если нет
  begin
    Result:='';
    if (lpBaseAddress <> nil) then
     begin
       Result:=WideCharToString(lpBaseAddress^.DataStrPtr);
     end;
  end;

 initialization

 finalization

 if Assigned(MFHandling) then
    FreeAndNil(MFHandling);

end.
