unit w_iniSettings;
/// <summary>
///    универсальный (кроссплатформенный) класс хранения настроек в файле в каталоге Roaming/Users
/// </summary>
///
interface

uses  Classes, Types,
     {$IFDEF MSWINDOWS}
       System.IniFiles;
     {$ENDIF}
     {$IFNDEF MSWINDOWS}
       IniFiles;
      // в ПИ! -->   FMX.Overbyte.Android.IniFiles;
     {$ENDIF}


type

 TwiniSettings=class(TObject)
     private
       FKeyWordOffset:integer;
       FKey, FKeyWord:string;
       {$IFDEF MSWINDOWS}
       FiniFile:TMemIniFile;    // ! memIni
       {$ELSE}
        FiniFile:TIniFile;
       {$ENDIF}
       FCurrStringList:TStrings;

       ///
       inner_ModFlag:boolean; /// false - сразу после сохранения - чтобы не перезаписывать сто раз при вызове Save; Save;
                              /// при WriteString становится true - для возможности повторной записи в файл
                              ///  позволяет избегать ситуации многократной записи файла без изменений
       ///
       function getFilename:string;
     protected
      function CycledSave:Boolean; virtual;
      procedure _WriteList(const aSect,aIdent:string; const aList:TStrings; aCodeSign:boolean);
       function _ReadList(const aSect,aIdent:string; const aList:TStrings; aCodeSign:boolean):boolean;
     public

      defSectionName:string;
      constructor Create; virtual;
      function SetParams(const aFilename, aKeyWord:string; aKeyOffset:integer=0):Integer;
      function Save:Boolean; virtual;
      // если ошибка сохранения - то вызвать показ сообщения для user
      function SaveWithMsg(const AMessage,aCaption:string; amType:integer=1):boolean; virtual;
      function Clear:Boolean; virtual;
      destructor Destroy; override;
     ///
       ///  read-write
       function ReadString(const aSect,aIdent,aDef:string):string;
       function WriteString(const aSect,aIdent,aValue:string):Boolean;
       function ReadInteger(const aSect,aIdent:string; aDef:Integer):Integer;
       function WriteInteger(const aSect,aIdent:string; aValue:Integer):Boolean;
       function ReadFloat(const aSect,aIdent:string; aDef:Double):Double;
       function WriteFloat(const aSect,aIdent:string; aValue:Double):Boolean;
       function ReadDatetime(const aSect,aIdent:string; aDef:TDateTime):TDateTime;
       function WriteDatetime(const aSect,aIdent:string; aValue:TDatetime):Boolean;
       function ReadBool(const aSect,aIdent:string; aDef:Boolean):Boolean;
       function WriteBool(const aSect,aIdent:string; aValue:boolean):Boolean;
       function ReadRect(const aSect,aIdent:string; aDef:TRect):TRect;
       function WriteRect(const aSect,aIdent:string; aValue:TRect):Boolean;
       ///
       ///  sections
       function DeleteSection(aSect:string):boolean;
       function RenameSection(oldSectName,newSectname:string):boolean;
       function SectionExists(const aSect:string):boolean;
       ///
       ///  crypt
       ///
       /// <summary>
       ///     если это кодовая строка то true    вид:  234 12 43 55 1 0 22 -2
       /// </summary>
      class function IsCodeString(const aCodeStr:string; averifyLevel:integer=1):boolean;
       procedure WriteCString(const aSect,aIdent,aValue:string);
       function ReadCString(const aSect,aIdent,aDef:string):string;
       ///
       procedure WriteText(const aSect,aIdent,aText:string);
       function ReadText(const aSect,aIdent,aDefText:string):string;
       ///
       ///  dates and adding fields
       /// <summary>
       ///    Renew Value to Field (if it is needed) and Return Old Value from ini
       /// <param name=" aForceFlag"> true - Save (in Place) ini file if Newvalue id Write!
       /// </param>
       /// <param name="aRWSign">
       ///   : if oldValue=aRWSign then Write to ini NewValue  (Default EmptyValue='')
       ///   : if aRWSign = *  then ignore oldValue (in ini-file) and always set aValue to ini
       ///   : if aRWSign=? then not Write (never) newValue in ini
       /// </param>
       ///    <returns>
       ///    Return: (OldValue) - return value from ini-file
       ///  </returns>
       /// </summary>
       function DefineField(const aSect,aIdent,aValue:string;
                               aForceFlag:Boolean;
                            const aRwSign:string=''):string;
       ///
       /// <summary>
       ///    save bs, mail Accaunt Informaton
       ///    'coiner@yandex.ru','smtp.yandex.ru','coiner','mola5fish');
       /// </summary>
        procedure WriteData(const aSect,aIdent:String; const mArr:array of string);
        /// <summary>
        ///   load bs, mail Accaunt Informaton - only - if Data found
       ///    'coiner@yandex.ru','smtp.yandex.ru','coiner','mola5fish');
       ///    return ->  Count read Items
        /// </summary>
        function ReadData(const aSect,aIdent:string; var mArr:array of string):integer;
       /// <summary>
       ///     дополнит. служебная: для преобразования список в массив данных
       /// </summary>
        procedure WriteDataFromList(const aSect,aIdent:String; const mAList:TStrings);
       /// <summary>
       ///     дополнит. служебная: для преобразования массива данных в список
       /// </summary>
        function ReadDataToList(const aSect,aIdent:String; const mAList:TStrings):boolean;

       ///
        procedure WriteList(const aSect,aIdent:string; const aList:TStrings);
        function ReadList(const aSect,aIdent:string; const aList:TStrings):boolean;
        procedure WriteCList(const aSect,aIdent:string; const aList:TStrings);
        function ReadCList(const aSect,aIdent:string; const aList:TStrings):boolean;
        /// <summary>
        ///  получить номер по указанному значению поля  используя Общий префикс
        ///  использовать для выбора по номерам различных пользователей
        ///  -1 не найден  (считывает строки секции и ищет в них по Values)
        /// </summary>
        function GetIndexFromValue(const aSect,aIdentPrefix,aValue:string; aCodeEnabled:boolean):integer;
        /// <summary>
        ///    добавить индекс со значением (если его еще нет) и получить его номер в ответе
        /// </summary>
        function DefineIndexValue(const aSect,aIdentPrefix,aValue:string; aCodeEnabled:boolean; aForceSave:boolean=true):integer;
        /// <summary>
        ///     получить список вида Нoмер=Значение для заданных параметров - исп. напр. для выбора пользователей
        ///     вернуть кол-во (например, пользователей) в списке
        /// </summary>
        function GetIndValuesList(const aSect,aIdentPrefix:string; aCodedFlag:boolean; const aNumValList:TStrings):integer;

       property CurrentKey:string read FKey write FKey;
       /// <summary>
       ///     служебн. слово для кодировки по XOR желат. не длинное
       /// </summary>
       property KeyWord:string read FKeyWord write FKeyWord;
       /// <summary>
       ///     служебн. сдвиг для кодировки по XOR желат небольшое и >0
       /// </summary>
       property KeyWordOffset:integer read FKeyWordOffset write FKeyWordOffset;
       property FileName:string read getFilename;
       {$IFDEF MSWINDOWS}
       property IniFile:TMemIniFile read FiniFile;
       {$ELSE}
       property IniFile:TIniFile read FiniFile;
       {$ENDIF}
       /// <summary>
       ///     тек. результат чтения,записи списка
       /// </summary>
       property CurrStringList:TStrings read FCurrStringList;
  end;

{$IFDEF MSWINDOWS}
function GetValueFromIniFile(const aIniFile,aSect,aName:string):string;
{$ENDIF}
// для before - в динамике открыть закрыть

/// <summary>
///    получить файл с путем в папке (для Win - тек каталог проги -- для ведроид Path
/// </summary>
function GetDocumentsFileName(const aName:string):string;
/// <summary>
///    получить путь в папке настроек
/// </summary>
function GetDocumentsFilePath(const aSubDirName:string):string;
/// <summary>
///      создать папку в Пользователи_Я_Appdata_Roaming_sub - если она не существует
/// </summary>
function CreateAppUserPath(const aSubDir:string):Boolean;
/// <summary>
///      дублирующая u_appParams - для Win=Пользователи_Я_Appdata_Roaming_sub
///      (для Android - ?
/// </summary>
function GetAppUserPath(const aSubDir:string):String;
/// <summary>
///      имя программы без расширения
/// </summary>
function GetAppOnlyFileName:string;

/// <summary>
///    если нет - создать путь (опции) - если есть открыть вернуть путь вида App Local sub
///  CSIDL_LOCAL_APPDATA=28
/// </summary>
function GetAppUserLocalDataPath(const aSubDir:string; aShortRegime:Integer=28; aCreateFlag:Boolean=true):String;

var iniSettings:TwiniSettings=nil;

    iniDataStrDivider:char='|';

implementation

    {$IFDEF MSWINDOWS}
       uses SysUtils, windows,Winapi.SHFolder;
    {$ELSE}
       uses SysUtils, System.IOUtils;
    {$ENDIF}


function GetDocumentsFileName(const aName:string):string;
 begin
   {$IFDEF MSWINDOWS}
      Result:=aName;
      {$ELSE}
       //LFilename:=TPath.GetDocumentsPath + PathDelim + aFileName;
       Result:=TPath.Combine(TPath.GetDocumentsPath,aName);
      {$ENDIF}
 end;

function GetDocumentsFilePath(const aSubDirName:string):string;
 begin
   {$IFDEF MSWINDOWS}
      Result:=IncludeTrailingPathDelimiter(IncludeTrailingPathDelimiter(GetCurrentDir)+aSubDirName);
      {$ELSE}
       //LFilename:=TPath.GetDocumentsPath + PathDelim + aFileName;
       Result:=IncludeTrailingPathDelimiter(TPath.Combine(TPath.GetDocumentsPath,aSubDirName));
      {$ENDIF}
 end;

///////////////////////////////////////////////////////////////////

 function CreateAppUserPath(const aSubDir:string):Boolean;
 var LS:String;
  begin
    Result:=False;
   {$IFDEF MSWINDOWS}
    LS:=GetAppUserPath(aSubDir);
    LS:=ExcludeTrailingPathDelimiter(LS);
    if DirectoryExists(LS)=false then
     try
       ForceDirectories(LS);
      // MkDir(LS);
     except
     end;
   {$ELSE}
   {$ENDIF}
  end;

 function GetAppUserPath(const aSubDir:string):String;
 var LS:String;
  begin
   Result:='';
   {$IFDEF MSWINDOWS}
    LS:=GetHomePath;
    if (Length(LS)>1) and (LS[Length(LS)]<>PathDelim) then LS:=Concat(LS,PathDelim);
    Result:=Concat(LS,aSubDir,PathDelim);
   {$ELSE}
     Result:=GetDocumentsFilePath(aSubDir);
   {$ENDIF}
  end;

 function GetAppOnlyFileName:string;
  begin
    Result:=ChangeFileExt(ExtractFileName(ParamStr(0)),'');
  end;

 function GetAppUserLocalDataPath(const aSubDir:string; aShortRegime:Integer=28; aCreateFlag:Boolean=true):String;
 var LS,LSS,LSub:String;
 {$IFDEF MSWINDOWS}
    var
    LStr: array[0 .. MAX_PATH] of Char;
 {$ENDIF}
begin
  Result:='';
  LS:='';
  LSub:=ExcludeTrailingPathDelimiter(aSubDir);
  {$IFDEF MSWINDOWS}
   SetLastError(ERROR_SUCCESS);
   if SHGetFolderPath(0, aShortRegime, 0, 0, @LStr) = S_OK then
      LS := LStr;
   {$ELSE}
     LS:=GetDocumentsFilePath(aSubDir);
   {$ENDIF}
   LSS:=Concat(IncludeTrailingPathDelimiter(LS),LSub);
   Result:=IncludeTrailingPathDelimiter(LSS);
   if (aCreateFlag=True) and (DirectoryExists(LSS)=false) then
        try
           ForceDirectories(LSS);
           Result:=IncludeTrailingPathDelimiter(LSS);
          except
        end;
  end;

function CodeM1(aEncodeFlag: boolean; const AStr: string; AoffSet:Word=0): string;
var
  il,cL: integer;
  LList: TStrings;
begin
  if aEncodeFlag then
  begin
    Result := '';
    il := Low(AStr);
    while il <= length(AStr) do
    begin
      Result := Concat(Result, ' ', IntToStr(Ord(AStr[il])+Aoffset));
      Inc(il);
    end;
  end
  else
  begin
    Result := '';
    LList := TStringList.Create;
    try
      LList.Delimiter := ' ';
      LList.DelimitedText := AStr;
      il := 0;
      while il < LList.Count do
      begin
        cL:=-100000000;
        TryStrToInt(LList.Strings[il],cL);
        if cl<-100000000 then
           begin
             Result:='';
             break;
           end;
        Result := Concat(Result, Chr(cL-AoffSet));
        Inc(il);
      end;
    finally
      LList.Free;
    end;
  end;
end;



///////////////////////////////////////////////////////////////////////
function TwiniSettings.getFilename:string;
 begin
   if Assigned(FiniFile) then
      Result:=FiniFile.FileName
   else Result:='';
 end;

function TwiniSettings.GetIndexFromValue(const aSect,aIdentPrefix,aValue: string;
   aCodeEnabled:boolean): integer;
var LLIst:TStrings;
    i,j:integer;
    LVal,LS:String;
begin
  Result:=-1;
  if aCodeEnabled then
     LVal:=CodeM1(True,aValue,FKeyWordOffset)
  else LVal:=aValue;
  LVal:=Trim(LVal);
  LLIst:=TStringList.Create;
  try
    FiniFile.ReadSectionValues(aSect,LLIst);
    i:=0;
    while i<LList.Count do
     begin
       j:=Pos(aIdentPrefix,LList.Names[i]);
       if (j=1) and (Trim(LLIst.ValueFromIndex[i])=Lval) then
         begin
           LS:=StringReplace(LList.Names[i],aIdentPrefix,'',[]);
           if LS='' then LS:='0';
           TryStrToInt(LS,Result);
           if Result>=0 then
              break;
         end;
       Inc(i);
     end;
  finally
    LLIst.Free;
  end;
end;

function TwiniSettings.GetIndValuesList(const aSect, aIdentPrefix:string;
  aCodedFlag: boolean; const aNumValList: TStrings): integer;
var LLIst:TStrings;
    i,j,k:integer;
    LVal,LS:String;
begin
  Result:=-0;
  aNumValList.Clear;
  LLIst:=TStringList.Create;
  try
    FiniFile.ReadSectionValues(aSect,LLIst);
    i:=0;
    while i<LList.Count do
     begin
       j:=Pos(aIdentPrefix,LList.Names[i]);
       if (j=1) then
        begin
          k:=-1;
          LS:=StringReplace(LList.Names[i],aIdentPrefix,'',[]);
          if LS='' then LS:='0';
          TryStrToInt(LS,k);
          if (k>=0) then
            begin
               if aCodedFlag then
                  LVal:=CodeM1(False,LLIst.ValueFromIndex[i],FKeyWordOffset)
               else LVal:=LLIst.ValueFromIndex[i];
               aNumValList.Add(Concat(IntToStr(k),'=',Trim(LVal)));
               Result:=Result+1;
            end
        end;
       Inc(i);
     end;
  finally
    LLIst.Free;
  end;
end;

{$IFDEF MSWINDOWS}
function TwiniSettings.CycledSave:Boolean;
   var il:Integer;
     begin
       Result:=False;
       il:=0;
       while (il<10)  do
         begin
          // if Assigned(Application) then
          //    Applicatio.Processmessages;
              Sleep(100);
            try
              FiniFile.UpdateFile;
              il:=-1;
              except
              Inc(il);
            end;
            if il<0 then Break;
         end;
       Result:=(il<0);
     end;
 {$ELSE}
   function TwiniSettings.CycledSave:Boolean;
    begin
     Result:=false;
        try
              FiniFile.UpdateFile;
              Result:=true;
        except
       end;
    end;
 {$ENDIF}

procedure TwiniSettings._WriteList(const aSect,aIdent:string; const aList:TStrings; aCodeSign:boolean);
  begin
    if Assigned(aList)=false then exit;
    if Not(Assigned(FCurrStringList)) then
      FCurrStringList:=TStringList.Create;
    ///
    FCurrStringList.Assign(aList);
    ///
    FCurrStringList.Delimiter:=iniDataStrDivider;
    if aCodeSign=true then
       WriteCString(aSect,aIdent,FCurrStringList.DelimitedText)
    else
       WriteString(aSect,aIdent,FCurrStringList.DelimitedText);
  end;

 function TwiniSettings._ReadList(const aSect,aIdent:string; const aList:TStrings; aCodeSign:boolean):boolean;
 var LS:string;
     i:integer;
  begin
    Result:=false;
   if Not(Assigned(FCurrStringList)) then
      FCurrStringList:=TStringList.Create;
   FCurrStringList.Clear;
   if aCodeSign=true then
      LS:=ReadCString(aSect,aIdent,'')
   else LS:=ReadString(aSect,aIdent,'');
   ///
   if (LS<>'') then
    begin
      FCurrStringList.Delimiter:=iniDataStrDivider;
      FCurrStringList.StrictDelimiter:=True;
      FCurrStringList.DelimitedText:=LS;
    //  LS:=FCurrStringList.Strings[0];
      Result:=true;
      if Assigned(aList) then
         aList.Assign(FCurrStringList);
    end;
  end;

 /////////////////////////////////////////////////////////////////////////////////////////////
   constructor TwiniSettings.Create;
    begin
      inherited Create;
      inner_ModFlag:=true;
      FKey:='';
      defSectionName:='Settings';
      FCurrStringList:=TStringList.Create;
    end;

 function TwiniSettings.DefineIndexValue(const aSect,aIdentPrefix,aValue: string;
      aCodeEnabled:boolean; aForceSave: boolean): integer;
  ///
    var LLIst:TStrings;
    i,j,k,LMax:integer;
    LS,LVal,LTrVal:String;
begin
  Result:=-1;
  LMax:=-1;
  if aValue='' then exit;
  //
  if aCodeEnabled then
     LVal:=CodeM1(True,aValue,FKeyWordOffset)
  else LVal:=aValue;
  LTrVal:=Trim(LVal);
  ///
  LLIst:=TStringList.Create;
  try
    FiniFile.ReadSectionValues(aSect,LLIst);
    i:=0;
    while i<LList.Count do
     begin
       j:=Pos(aIdentPrefix,LList.Names[i]);
       if (j=1) then
        begin
          k:=-1;
          LS:=StringReplace(LList.Names[i],aIdentPrefix,'',[]);
          if LS='' then LS:='0';
          TryStrToInt(LS,k);
          if (k>=0) then
            begin
                 if (Trim(LLIst.ValueFromIndex[i])=LTrVal) then
                   begin
                     Result:=k;
                     break
                   end
                 else
                  if (k>LMax) then LMax:=k;
            end
        end;
       Inc(i);
     end;
  finally
    LLIst.Free;
  end;
  ///
  if Result=-1 then
   begin
    Inc(LMax); // !
    LS:=Concat(aIdentPrefix,IntToStr(LMax));
    WriteString(aSect,LS,LVal); // !
    if aForceSave then
         Save;
    Result:=LMax; // !
   end;
  ///
end;

function TwiniSettings.SectionExists(const aSect: string): boolean;
begin
  Result:=False;
  if Trim(aSect)<>'' then
     Result:=FiniFile.SectionExists(aSect);
end;

function TwiniSettings.SetParams(const aFilename,aKeyWord:string; aKeyOffset:integer=0):Integer;
   var LStream:TFileStream;
       LDir,LFilename:string;
    begin
      Result:=-1;
      FKeyWordOffset:=aKeyOffset;
      FKeyWord:=Trim(aKeyWord);
      ///
      LFilename:=aFilename;
      LDir:=ExtractFileDir(LFileName);
      if (LDir<>'') and (DirectoryExists(LDir)=False) and
         (FileExists(ExtractFileName(LFilename))=true) then
          LFilename:=ExtractFileName(LFilename);
      ///
      if (LFilename<>'') and (FileExists(LFileName)=False) then
       try
        LStream:=nil;
        try
           LStream := TFileStream.Create(LFileName, fmCreate or fmShareDenyWrite);
           except
             begin  LStream:=nil; Result:=10; end;
           end
        finally
          if Assigned(LStream) then LStream.Free;
        end;
      ///
      try
       {$IFDEF MSWINDOWS}
         FiniFile:=TMemIniFile.Create(LFilename);
       {$ELSE}
         FiniFile:=TIniFile.Create(LFilename);
       {$ENDIF}
       Result:=0;
       except
        Result:=-10;
      end;
      inner_ModFlag:=true;
      ///
    end;

   function TwiniSettings.Save:Boolean;
    begin
      Result:=False;
      if inner_ModFlag=false then
       begin
         Result:=true;
         exit;
       end;
      try
       try
         FiniFile.UpdateFile;
         Result:=True;
         except
         Result:=CycledSave;
       end;
      finally
       if Result=true then inner_ModFlag:=false;
      end;
    end;

   function TwiniSettings.SaveWithMsg(const AMessage,aCaption:string; amType:integer=1):boolean;
   var Lcapt:string;
    begin
      Result:=Save;
      if Result=false then
        begin
         if aCaption='' then Lcapt:='Warning';
         {$IFDEF MSWINDOWS}
          MessageBox(0,Pchar(Amessage),Pchar(Lcapt),MB_OK or MB_ICONWARNING);
         {$ENDIF}
        end;
    end;

   function TwiniSettings.Clear:Boolean;
    begin
      Result:=False;
      try
       try
         {$IFDEF MSWINDOWS}
          FiniFile.Clear;
         {$ELSE}
          raise Exception.Create('TwiniSettings.Clear - Android - no Realization!');
         {$ENDIF}
         ///
         inner_ModFlag:=true;
         ///
         Result:=True;
         except
         Result:=CycledSave;
       end;
      finally
      end;
    end;

   destructor TwiniSettings.Destroy;
    begin
      FiniFile.Free;
      if Assigned(FCurrStringList) then
         FreeAndNil(FCurrStringList);
      ///
      inherited Destroy;
    end;
///////////////////////////////////////////////////////////////////////


  function TwiniSettings.ReadString(const aSect,aIdent,aDef:string):string;
  var LSect:string;
  begin
    if aSect='' then LSect:=defSectionName else LSect:=aSect;
    if FKey<>'' then LSect:=Concat(FKey,'_',LSect);
    Result:=FiniFile.ReadString(LSect,aIdent,aDef);
  end;

 function TwiniSettings.WriteString(const aSect,aIdent,aValue:string):Boolean;
 var LSect:string;
  begin
   Result:=False;
   inner_ModFlag:=true;
   if aSect='' then LSect:=defSectionName else LSect:=aSect;
   if FKey<>'' then LSect:=Concat(FKey,'_',LSect);
   try
     FiniFile.WriteString(LSect,aIdent,aValue);
     Result:=True;
    finally
   end;
  end;

 function TwiniSettings.ReadInteger(const aSect,aIdent:string; aDef:Integer):Integer;
 var LS:string;
  begin
    Result:=aDef;
    LS:=ReadString(aSect,aIdent,'');
    if (LS<>'') then TryStrToInt(LS,Result);
  end;

 function TwiniSettings.WriteInteger(const aSect,aIdent:string; aValue:Integer):Boolean;
  begin
     Result:=WriteString(aSect,aIdent,IntToStr(aValue));
  end;

 function TwiniSettings.ReadFloat(const aSect,aIdent:string; aDef:Double):Double;
 var LS:string;
  begin
    Result:=aDef;
    LS:=ReadString(aSect,aIdent,'');
    if (LS<>'') then
     begin
       try
        Result:=StrToFloat(LS);
        except
         begin
           LS:=StringReplace(LS,'.',FormatSettings.DecimalSeparator,[]);
           LS:=StringReplace(LS,',',FormatSettings.DecimalSeparator,[]);
           TryStrToFloat(LS,Result);
         end;
       end;
     end;
  end;

 function TwiniSettings.WriteFloat(const aSect,aIdent:string; aValue:Double):Boolean;
  begin
    Result:=WriteString(aSect,aIdent,FloatToStr(aValue));
  end;

 function TwiniSettings.ReadDatetime(const aSect,aIdent:string; aDef:TDateTime):TDateTime;
   var LS:string;
  begin
    Result:=aDef;
    LS:=ReadString(aSect,aIdent,'');
    if (LS<>'') then
     begin
       try
        Result:=StrToDateTime(LS);
        except
         begin
           TryStrToDateTime(LS,Result); // пока так
         end;
       end;
     end;
  end;

 function TwiniSettings.WriteDatetime(const aSect,aIdent:string; aValue:TDatetime):Boolean;
  begin
    Result:=WriteString(aSect,aIdent,DateTimeToStr(aValue));
  end;

 function TwiniSettings.ReadBool(const aSect,aIdent:string; aDef:Boolean):Boolean;
 var il:integer;
  begin
    Result:=aDef;
    if aDef=True then il:=1 else il:=0;
    il:=ReadInteger(aSect,aIdent,il);
    if il=0 then Result:=False else result:=True;
  end;

 function TwiniSettings.WriteBool(const aSect,aIdent:string; aValue:boolean):Boolean;
 var il:integer;
  begin
   if aValue=True then il:=1 else il:=0;
   Result:=WriteInteger(aSect,aIdent,il);
  end;
 ///
 function TwiniSettings.ReadRect(const aSect,aIdent:string; aDef:TRect):TRect;
 var LS:string;
     LList:TStrings;
     i:integer;
  begin
    Result:=aDef;
    LS:=ReadString(aSect,aIdent,'');
    if LS<>'' then
     begin
       LLIst:=TStringList.Create;
       try
        LList.CommaText:=LS;
        if LList.Count=4 then
         begin
           i:=Result.Left;
           TryStrToInt(LList.Strings[0],i);
           Result.Left:=i;
           i:=Result.Top;
           TryStrToInt(LList.Strings[1],i);
           Result.Top:=i;
           i:=Result.Right;
           TryStrToInt(LList.Strings[2],i);
           Result.Right:=i;
           i:=Result.Bottom;
           TryStrToInt(LList.Strings[3],i);
           Result.Bottom:=i;
         end;
       finally
         LLIst.Free;
       end;
     end;
  end;

 function TwiniSettings.WriteRect(const aSect,aIdent:string; aValue:TRect):Boolean;
 var LS:String;
  begin
    LS:=Concat(IntToStr(aValue.Left),',',IntToStr(aValue.Top),',',IntToStr(aValue.Right),',',IntToStr(aValue.Bottom));
    Result:=WriteString(aSect,aIdent,LS)
  end;

 function TwiniSettings.DeleteSection(aSect:string):boolean;
 var LSect:string;
  begin
    inner_ModFlag:=true;
     if aSect='' then LSect:=defSectionName else LSect:=aSect;
     FiniFile.EraseSection(LSect);
    Result:=true;
  end;

 function TwiniSettings.RenameSection(oldSectName,newSectname:string):boolean;
 var LSect:string;
     LLIst:TSTrings;
     i,j:Integer;
     LS,LId,LV:String;
  begin
    Result:=false;
    if oldSectName='' then LSect:=defSectionName else LSect:=oldSectName;
    if oldSectName=newSectname then begin Result:=true; exit; end;
    inner_ModFlag:=true;
    LS:=Concat('[',LSect,']');
    LLIst:=TStringList.Create;
    try
     {$IFDEF MSWINDOWS}
     FiniFile.GetStrings(LList);
    // LList.SaveToFile('tttt.txt');
     i:=0;
     while i<LList.Count do
      begin
       if LS=Trim(LList.Strings[i]) then
         begin
           LList.Strings[i]:=Concat('[',newSectname,']');
           Result:=true;
           break;
         end;
       Inc(i);
      end;
      // LList.SaveToFile('tttt_new.txt');
      if Result=true then
       begin
         FiniFile.SetStrings(LList);
       end;
     {$ELSE}
      FiniFile.ReadSection(LSect,LList);
      FiniFile.EraseSection(LSect);
      i:=0;
      while i<LList.Count do
       begin
        LS:=LLIst.Strings[i];
        j:=Pos(']',LS);
        if j<=0 then
         begin
          Lid:=LList.Names[i];
          LV:=LList.ValueFromIndex[i];
          if (Lid<>'') then
              FiniFile.WriteString(newSectname,Lid,LV);
         end;
        Inc(i);
       end;

     {$ENDIF}
    finally
      LList.Free;
    end;
  end;

 ////////////////////////////////////////////////////////////////////////////////

 class function TwiniSettings.IsCodeString(const aCodeStr:string; averifyLevel:integer=1):boolean;
 var i:integer;
     LFlag:boolean;
  begin
    i:=1;
    LFlag:=true;
    while i<=Length(aCodeStr) do
     begin
      if (Not(aCodeStr[i] in ['0'..'9'])) and (aCodeStr[i]<>' ') and (aCodeStr[i]<>'-') then
       begin
        LFlag:=false;
        break;
       end;
      Inc(i);
     end;
    Result:=LFlag;
  end;

 procedure TwiniSettings.WriteCString(const aSect,aIdent,aValue:string);
 var LS:String;
  begin
  // if FKeyWord<>'' then LS:=wXorString(aValue,FKeyWord) else LS:=aValue;
   LS:=aValue;
   LS:=CodeM1(True,LS,FKeyWordOffset);
   WriteString(aSect,aIdent,LS);
  end;

 function TwiniSettings.ReadCString(const aSect,aIdent,aDef:string):string;
 var LS:string;
  begin
   LS:=ReadString(aSect,aIdent,'');
  // if (FKeyWord<>'') and (LS<>aDef) then Result:=wXorString(LS,FKeyWord)
   if (LS<>'') and (LS<>aDef) then LS:=CodeM1(false,LS,FKeyWordOffset)
   else LS:=aDef;
   Result:=LS;
  end;

 function _UnQuotedStr(const aSrc: String; aQuotedStr: String='"'): String;
var
   tLen: Integer;
     begin
      Result := aSrc;
      tLen := Length(Result);
      if tLen<2 then Exit;
      if (Result[1]=aQuotedStr) and (Result[tLen]=aQuotedStr) then
         begin
           Delete(Result,tLen,1);
           Delete(Result,1,1);
         end;
end;

 procedure TwiniSettings.WriteText(const aSect,aIdent,aText:string);
 var Ltext,LS:string;
  begin
    LText:=StringReplace(aText,'"','&#34;',[rfReplaceAll]);
    LText:=StringReplace(LText,#13#10,'<br>',[rfReplaceAll]);
    LS:=Utf8ToAnsi(UTF8Encode(LText));
    LS:=Concat('"',LS,'"');
    WriteString(aSect,aIdent,LS);
  end;

 function TwiniSettings.ReadText(const aSect,aIdent,aDefText:string):string;
 var LRead,LS,LDef:string;
  begin
   LDef:='*+*-*';
   LRead:=ReadString(aSect,aIdent,LDef);
   if LRead='*+*-*' then Result:=aDefText
   else
    begin
      LRead:=_UnQuotedStr(LRead);
      LS:=UTF8Decode(AnsiToUtf8(LRead));
      Result:=StringReplace(LS,'<br>',#13#10,[rfReplaceAll]);
      Result:=StringReplace(Result,'&#34;','"',[rfReplaceAll]);
    end;
  end;

 function TwiniSettings.DefineField(const aSect,aIdent,aValue:string;
                                     aForceFlag:Boolean;
                                     const aRwSign:string=''):string;
 var LOldValue:string;
  begin
   LOldValue:=ReadString(aSect,aIdent,'');
   Result:=LOldValue;
   if (aRwSign='*') or (LOldValue=aRwSign) then
    begin
      WriteString(aSect,aIdent,aValue);
      if aForceFlag then
         Save;
    end;
  end;

 procedure TwiniSettings.WriteData(const aSect,aIdent:String; const mArr:array of string);
 var LS:string;
     i,j:integer;
  begin
    j:=0;
    i:=Low(mArr);
    while i<=High(mArr) do
     begin
      if mArr[i]<>'' then
         if LS<>'' then
           LS:=Concat(LS,iniDataStrDivider,mArr[i])
         else LS:=mArr[i];
       Inc(i);
       Inc(J);
     end;
    if LS='' then exit;
    LS:=Concat('COUNT=',IntToStr(j),iniDataStrDivider,LS);
    WriteCString(aSect,aIdent,LS);
  end;

 function TwiniSettings.ReadData(const aSect,aIdent:string; var mArr:array of string):integer;
 var LS:String;
     LLIst:TStrings;
     i,j:integer;
  begin
    Result:=0;
    LS:=ReadCString(aSect,aIdent,'');
    if LS='' then exit;
    LLIst:=TStringList.Create;
    try
      LList.Delimiter:=iniDataStrDivider;
      LList.DelimitedText:=LS;
      j:=0;
      if LLIst.Count>0 then
       begin
         TryStrToInt(LLIst.ValueFromIndex[0],j);
         if j>0 then
          begin
            i:=1;
            j:=Low(mArr);
            while i<LList.Count do
             begin
              if LList.Strings[i]<>'' then
               begin
                // LS:=LList.Strings[i];
                 if j<=High(mArr) then
                   begin
                    mArr[j]:=LList.Strings[i];
                    Inc(j);
                   end;
                 Result:=Result+1;
               end;
               inc(i);
             end;
          end;
       end;
       ///
    finally
      LList.Free;
    end;
  end;

  procedure TwiniSettings.WriteDataFromList(const aSect,aIdent:String; const mAList:TStrings);
  var LArr:array of String;
      i:integer;
   begin
     i:=mAList.Count;
     if i=0 then exit;
     SetLength(LArr,i);
     i:=0;
     while i<mAList.Count do
      begin
        Larr[i]:=mAList.Strings[i];
        Inc(i);
      end;
     WriteData(aSect,aIdent,LArr);
     SetLength(LArr,0);
   end;

  function TwiniSettings.ReadDataToList(const aSect,aIdent:String; const mAList:TStrings):boolean;
  var LS:String;
   begin
     Result:=false;
     LS:=ReadCString(aSect,aIdent,'');
     if (LS='') then exit;
     FCurrStringList.Delimiter:=iniDataStrDivider;
     FCurrStringList.DelimitedText:=LS;
     if FCurrStringList.Count>0 then
        FCurrStringList.Delete(0); // COUNT
     Result:=(FCurrStringList.Count>0);
     if Assigned(mAList) then
        mAList.Assign(FCurrStringList);
   end;


  procedure TwiniSettings.WriteList(const aSect,aIdent:string; const aList:TStrings);
   begin
     _WriteList(aSect,aIdent,aList,false);
   end;

  function TwiniSettings.ReadList(const aSect,aIdent:string; const aList:TStrings):boolean;
   begin
    Result:=_ReadList(aSect,aIdent,aList,false);
   end;

  procedure TwiniSettings.WriteCList(const aSect,aIdent:string; const aList:TStrings);
   begin
     _WriteList(aSect,aIdent,aList,true);
   end;

  function TwiniSettings.ReadCList(const aSect,aIdent:string; const aList:TStrings):boolean;
   begin
     Result:=_ReadList(aSect,aIdent,aList,true);
   end;
 /////////////////////////////////////////////////////////////////////
 {$IFDEF MSWINDOWS}
 function GetValueFromIniFile(const aIniFile,aSect,aName:string):string;
 var L_iniFile:TMemIniFile;
  begin
     Result:='';
     try
      try
       L_iniFile:=TMemIniFile.Create(aIniFile);
       Result:=L_iniFile.ReadString(aSect,aName,'');
       except
        Result:='';
      end;
     finally
       L_iniFile.Free;
     end;
  end;
 {$ENDIF}

initialization

 iniSettings:=nil;

finalization

 if Assigned(iniSettings) then
    FreeAndNil(iniSettings);
///

end.
