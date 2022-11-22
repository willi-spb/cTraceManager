unit wAppEnviron;

///  очень желательно добавлять модуль последним в список модулей проекта
///  (чтобы освобождение глобального объекта настроек происходило после всех)

interface

uses System.Classes, wAppEnvironClass;

var appEnv:TwAppEnvironment=nil;
    appParams:TwAppEnvironParams;

/// <summary>
///      чтобы не вызывать напрямую конструктор - исп. создание глоб. объекта с глоб параметрами
/// </summary>
procedure appEnvironCreateWithParams;

/// <summary>
///     для глобального объекта удалить и выставить указатель в nil
///     (этот важный момент если есть логирование с потоками и ошибками)
/// </summary>
procedure appEnvironFree;

 /// <summary>
 ///      логирование доп. сущностей - для локализации ошибок
 ///      добавить точку прохода apCommand='' -нет логирования - иначе 'log' - только внутр. или команда лога
 /// </summary>
 procedure appSetPt(const aptName,aValue:string; const apCommand:string='');
 /// <summary>
 ///      логирование доп. сущностей - для локализации ошибок
 ///     убрать точку прохода из логов
 /// </summary>
 procedure appDeletePt(const aptName:string);
 /// <summary>
 ///      добавил для удобства работы с точкой -аналог appSetPt
 /// <param name="aDeleteFlag">
 ///     true - тут же удалить точку (только логирование операции)
 /// </param>
 /// </summary>
 procedure appPt(const aptName,aValue:string; const apCommand:string=''; aDeleteFlag:Boolean=false);
 /// <summary>
 ///    включить выключить логирования по ошибкам
 ///   (возм. использование отключения, если закрывается окно, но идет поток с выполнением)
 /// </summary>
 procedure appTraceState(aNewState:boolean);
 ///
 /// <summary>
 ///    задать начальные установки для madExcept из параметров appEnv
 /// </summary>
 procedure appInitDefaultTrace(const addPrx:string='');
 ///
 /// <summary>
 ///     тип события для логирования
 /// </summary>
 type
  TTraceExternalLogEvent=procedure(const aCommand,aMsgData:String) of object;
 /// <summary>
 ///     выставить указатель по заданному событию
 /// </summary>
 procedure appDefineTraceLogEvent(AEvent:TTraceExternalLogEvent);

implementation

{$IFDEF madExcept}
 uses System.SysUtils, u_wMadExcept;
{$ENDIF}

///////////////////////////////////////////////////////////////////////
////
///
procedure appEnvironCreateWithParams;
 begin
  Assert(Assigned(appEnv)=false,'appCreateWithParams - repeat Create Singleton!');
  Assert(appParams.Id<>0,'appCreateWithParams - not fiill appParams - Id=0!');
  appEnv:=TwAppEnvironment.Create(appParams);
  /// a теперь главное!  хотя спрашивать параметры следует через свойство
  appParams:=appEnv.Params; // !
 end;

procedure appEnvironFree;
 begin
  if (Assigned(appEnv)=false) then
      appEnv:=nil
  else
   try
     appEnv.Free;
    finally
     appEnv:=nil;
   end;
 end;


 procedure appSetPt(const aptName,aValue:string; const apCommand:string='');
  begin
    {$IFDEF madExcept}
     { if (Assigned(appEnv)) and (Assigned(wTrace)) and (wTrace.Enabled=true) then
         wTrace.SetPt(aptName,aValue,apLogFlag)
      else
      }
       if Assigned(wTrace) then
          wtrace.SetPt(aptName,aValue,apCommand);
    {$ENDIF}
  end;

 procedure appDeletePt(const aptName:string);
  begin
    {$IFDEF madExcept}
     { if (Assigned(appEnv)) and (Assigned(wTrace)) and (wTrace.Enabled=true) then
         wTrace.DeletePt(aptName)
      else
      }
       if Assigned(wTrace) then
          wtrace.DeletePt(aptName);
    {$ENDIF}
  end;

procedure appPt(const aptName,aValue:string; const apCommand:string=''; aDeleteFlag:Boolean=false);
 begin
   appSetPt(aptName,aValue,apCommand);
   if aDeleteFlag=true then
      appDeletePt(aptName); // в этом случае - смысл вызова appSetPt - только в логировании, точка удалается
 end;

 procedure appTraceState(aNewState:boolean);
  begin
    {$IFDEF madExcept}
     { if (Assigned(appEnv)) and (Assigned(wTrace)) then
         wTrace.Enabled:=aNewState
      else
      }
       if Assigned(wTrace) then
          wTrace.Enabled:=aNewState;
    {$ENDIF}
  end;


 procedure appInitDefaultTrace(const addPrx:string='');
  begin
    {$IFDEF madExcept}
      if (Assigned(appEnv)) and (Assigned(wTrace)) then
        begin
          ///
          wTrace.BugReportName:=Concat(addPrx,appEnv.ServiceInfo.appVersionStr,
                         '|',appEnv.ServiceInfo.userName,'|',
                          DateTimeToStr(Now));
          wTrace.SetPt('aAppEnv','initTrace',''); // служебн. метка
        end;
    {$ENDIF}
  end;

procedure appDefineTraceLogEvent(AEvent:TTraceExternalLogEvent);
 begin
   {$IFDEF madExcept}
      if (Assigned(wTrace)) then
        begin
           wTrace.OnExternalLogEvent:=AEvent;
        end;
    {$ENDIF}
 end;

initialization

  appEnv:=nil;
  appParams.Id:=0;
  appParams.CaptionLeftPart:='';
  appParams.winSendRStr:='';
  appParams.ApHandle:=0;
  appParams.versionVisPrecision:=3; // !
  appParams.winHomeRVerifyFlag:=False;
  appParams.mpIdentStr:='COMCOMBODEFAULT';
  appParams.CompanyDirectoryPart:='';
  appParams.CompanyName:='';

finalization

// !
  appEnvironFree;

end.
