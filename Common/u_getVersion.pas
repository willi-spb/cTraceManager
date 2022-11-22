unit u_getVersion;
///
///
///   Определение версии и выделение в строку до нужной точности например 1.2
///
///   функции


interface

/////////////////////////////////////////////////////////////////////////////
///
///   Внимание - для получения данных файла необходимы нужные права на PC!
///

 procedure wa_GetFileVersion(FileName: string;
    var Major1, Major2, Minor1, Minor2: integer);

function wa_GetFileVersionToStr(const aFileName: string;
    const aDelim: string = '.'): string;

function wa_GetFileVersionShortStr(const aFileName: string;
    aNum:Integer; const aDelim: string = '.'): string;

///  true -- if versions equal  else false
function wa_VerifyNewVersionFromStr(const aFileVers,aSitevers:string):Boolean;
///
///
///  Определить версию Application - права не важны
///
 function GetAppVersion(aMaxNum:Integer): string;  //  вернет пусто - если нет ресурса
 // номер отвечает за точность версии   2    12.14     4   1.2.3.4  - максимум 4
 ///
 ///  извлечь номера
 function ExtractVersion(const aStr:string; var aNums:array of Integer):integer;

implementation

 uses windows,SysUtils, Classes;

 procedure wa_GetFileVersion(FileName: string;
    var Major1, Major2, Minor1, Minor2: integer);
  { Helper function to get the actual file version information }
  var
    Info: Pointer;
    InfoSize: DWORD;
    FileInfo: PVSFixedFileInfo;
    FileInfoSize: DWORD;
    Tmp: DWORD;
  begin
    // Get the size of the FileVersionInformatioin
    InfoSize := GetFileVersionInfoSize(PChar(FileName), Tmp);
    // If InfoSize = 0, then the file may not exist, or
    // it may not have file version information in it.
    if InfoSize = 0 then
      raise Exception.Create
        ('wa_GetFileVersion - Can''t get file version information for ' +
        FileName);
    // Allocate memory for the file version information
    GetMem(Info, InfoSize);
    try
      // Get the information
      GetFileVersionInfo(PChar(FileName), 0, InfoSize, Info);
      // Query the information for the version
      VerQueryValue(Info, '\', Pointer(FileInfo), FileInfoSize);
      // Now fill in the version information
      Major1 := FileInfo.dwFileVersionMS shr 16;
      Major2 := FileInfo.dwFileVersionMS and $FFFF;
      Minor1 := FileInfo.dwFileVersionLS shr 16;
      Minor2 := FileInfo.dwFileVersionLS and $FFFF;
    finally
      FreeMem(Info, FileInfoSize);
    end;
  end;

  function wa_GetFileVersionToStr(const aFileName: string;
    const aDelim: string = '.'): string;
  var
    Major1, Major2, Minor1, Minor2: integer;
  begin
    wa_GetFileVersion(aFileName, Major1, Major2, Minor1, Minor2);
    Result := Concat(IntToStr(Major1), aDelim, IntToStr(Major2), aDelim,
      IntToStr(Minor1), aDelim, IntToStr(Minor2));
  end;

  function wa_GetFileVersionShortStr(const aFileName: string;
    aNum:Integer; const aDelim: string = '.'): string;
    var
    Major1, Major2, Minor1, Minor2: integer;
    begin
        wa_GetFileVersion(aFileName, Major1, Major2, Minor1, Minor2);
        Result :=IntToStr(Major1);
        if aNum>1 then Result:=Concat(Result,aDelim,IntToStr(Major2));
        if aNum>2 then Result:=Concat(Result,aDelim,IntToStr(Minor1));
        if aNum>3 then Result:=Concat(Result,aDelim,IntToStr(Minor2));
    end;

 function wa_VerifyNewVersionFromStr(const aFileVers,aSitevers:string):Boolean;
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
//////////////////////////////////////////////////////////
///
///
///    App
///
type
 TVer = packed record
   data: record case integer of
       0: (All: UInt64);
       1: (Minor,Major,Build,Release : Word);
    end;
  end;

 function GetAppVersion(aMaxNum:Integer): string;
    var
      HR: HRSRC;
      H: THandle;
      C: TVer;
    begin
     result:='';
     try
      try
          HR:=FindResource(MainInstance, '#1', rt_Version);
          if HR=0 then exit;
          H:=LoadResource(MainInstance, HR);
          if h<>0 then begin
            C:=TVer(PUInt64( Integer(LockResource(H))+48)^);
            Result:=IntToStr(c.data.Major);
            if aMaxNum>1 then
               Result:=Concat(Result,'.',IntToStr(c.data.Minor));
            if aMaxNum>2 then
               Result:=Concat(Result,'.',IntToStr(c.data.Release));
             if aMaxNum>3 then
               Result:=Concat(Result,'.',IntToStr(c.data.Build));
            UnlockResource(H);
            FreeResource(H);
          end;
      except
        raise Exception.Create('GetAppVersion Error');
      end;
     finally
     end;
    end;


 function ExtractVersion(const aStr:string; var aNums:array of Integer):integer;
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
      while (il<L_Sver.Count) and (il<High(aNums)) do
       begin
         L_F:=-1;
         TryStrToInt(L_Sver.Strings[il],L_F);
         if (L_F>=0) then aNums[il]:=L_F else aNums[il]:=0;
         Inc(il);
       end;
     Result:=L_Sver.Count;
    finally
     L_Sver.Free;
    end;
  end;

end.
