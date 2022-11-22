program cTraceManager;

uses
  System.StartUpCopy,
  FMX.Forms,
  fm_CTraceManager in 'fm_CTraceManager.pas' {CTrForm},
  ServiceClasses in 'Common\ServiceClasses.pas',
  u_AppLogClass in 'Common\u_AppLogClass.pas',
  u_appParamsFuncs in 'Common\u_appParamsFuncs.pas',
  u_getVersion in 'Common\u_getVersion.pas',
  u_MMFClass in 'Common\u_MMFClass.pas',
  w_iniSettings in 'Common\w_iniSettings.pas',
  wAppEnviron in 'Common\wAppEnviron.pas',
  wAppEnvironClass in 'Common\wAppEnvironClass.pas',
  wMessagesHook in 'Common\wMessagesHook.pas',
  u_wCodeTrace in 'Common\u_wCodeTrace.pas';

{$R *.res}

var Lg_port:Integer;

begin


///
with appParams do
   begin
    guIDStr:='C89F9EF0-BFDB-4612-8328-270D8B625E13';
    Id:=888; // об€зательно - т.к. провер€етс€ при создании объекта настроек
    versionVisPrecision:=2; // точность версии
    Caption:='Ћогирование - CodeTrace';
    winSendRStr:='Double';
    iniCodeKey:='TRACED';
    iniShift:=5;
    mpIdentStr:='TRACEMANAGER';
    wndClassNames:='FMTCTrForm';
    ShortName:='TraceManager';
    winAutoHookFlag:=true;
    runAppName:='cTraceManager';
    PublisherStr:='Willi SPb';
    CopyRightStr:='CopyRight © 2022 by '+PublisherStr;
   end;
  ///
  appEnvironCreateWithParams;
   Application.Initialize;
   ///
   if appEnv.VerifyRepetition('')=false then
    begin // это второй экземпл€р программы
     wCode.Socket.UdpClient.Active:=False;
     Lg_port:=def_portNum;
     Lg_port:=appEnv.Ini.ReadInteger('SETTINGS','port',Lg_port);
     wCode.Socket.UdpClient.Port:=Trunc(Lg_port+1);
     wCode.Socket.UdpClient.Tag:=1;
    end;
   /// сам себ€ не ловит!
  // w_CodeSiteState(false);
   ///
   ///
   {$IFDEF DEBUG}
     ReportMemoryLeaksOnShutdown:=true;
   {$ENDIF}
  {$IFDEF ANALYTICS_ACCESS}
     Application.CreateForm(TCAnalytics_DM, CAnalytics_DM);
  {$ENDIF}
  /// FMX.def_baseData
    Application.CreateForm(TCTrForm, CTrForm);
  Application.Run;
end.
