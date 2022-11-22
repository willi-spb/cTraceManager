unit fm_CTraceManager;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, IdUDPServer,
  IdGlobal, IdSocketHandle, FMX.Controls.Presentation, FMX.ScrollBox, FMX.Memo,
  IdUDPClient, IdBaseComponent, IdComponent, IdUDPBase, FMX.StdCtrls,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.ListView, System.ImageList, FMX.ImgList, FMX.TreeView, FMX.Layouts,
  u_wCodeTrace, wAppEnvironClass, FMX.ListBox, System.Actions, FMX.ActnList,
  FMX.Menus, FMX.Edit, FMX.ComboEdit, FMX.TabControl, FMX.Memo.Types,
  FMX.EditBox, FMX.NumberBox;

type
  TCTrForm = class(TForm)
    Timer1: TTimer;
    IdUDPServer1: TIdUDPServer;
    tv_Trace: TTreeView;
    TreeViewItem1: TTreeViewItem;
    TreeViewItem2: TTreeViewItem;
    TreeViewItem3: TTreeViewItem;
    TreeViewItem4: TTreeViewItem;
    TreeViewItem5: TTreeViewItem;
    TreeViewItem6: TTreeViewItem;
    TreeViewItem7: TTreeViewItem;
    ImageList1: TImageList;
    TreeViewItem8: TTreeViewItem;
    Timer_Idle: TTimer;
    ActionList1: TActionList;
    actClear: TAction;
    actCopy: TAction;
    actCopyData: TAction;
    actScroll: TAction;
    actOnlyJS: TAction;
    actHTest: TAction;
    pnl1: TPanel;
    ComboBox1: TComboBox;
    mm1: TMainMenu;
    treeItem: TMenuItem;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    addingItem: TMenuItem;
    MenuItem7: TMenuItem;
    lbl1: TLabel;
    btnSPFind: TSpeedButton;
    chkFinfFromCurrPos: TCheckBox;
    cbe_Find: TComboEdit;
    actSearch: TAction;
    tbcDirect: TTabControl;
    tbtmTree: TTabItem;
    tbtmData: TTabItem;
    mmoData: TMemo;
    lyt_top1: TLayout;
    btn1: TSpeedButton;
    lbl_port: TLabel;
    nmbrbx_port: TNumberBox;
    lbl_defPort: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure IdUDPServer1UDPRead(AThread: TIdUDPListenerThread;
      const AData: TIdBytes; ABinding: TIdSocketHandle);
    procedure Timer1Timer(Sender: TObject);
    procedure Timer_IdleTimer(Sender: TObject);
    procedure cb_OnlyJSClick(Sender: TObject);
    procedure actClearExecute(Sender: TObject);
    procedure actCopyExecute(Sender: TObject);
    procedure actCopyDataExecute(Sender: TObject);
    procedure actHTestExecute(Sender: TObject);
    procedure actScrollExecute(Sender: TObject);
    procedure cbe_FindChange(Sender: TObject);
    procedure actSearchUpdate(Sender: TObject);
    procedure actSearchExecute(Sender: TObject);
    procedure tbcDirectChange(Sender: TObject);
    procedure nmbrbx_portExit(Sender: TObject);
  private
    { Private declarations }
    FLastItem:TTreeViewItem;
    F_FindItemIndex:Integer;
    procedure FillComboBox;
    function SetClientPort(aPort:integer):Boolean;
  public
    { Public declarations }
    LTList:TThreadList;
    /// <summary>
    ///     тек. индекс (прочитанный) для списка
    /// </summary>
    LT_ApplyIndex:integer;
    ///
    function AddCTItem(ATrView:TTreeView; const AItem:TCodeTraceItem):TTreeViewItem;
    ///
  end;

var
  CTrForm: TCTrForm;

  const def_portNum=25678;

implementation

{$R *.fmx}

uses Rtti,FMX.Platform, FMX.DialogService,
     wAppEnviron;

///  Clipboard -- from Inet
function TryGetClipboardService(out _clp: IFMXClipboardService): boolean;
begin
  Result := TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService);
  if Result then
    _clp := IFMXClipboardService(TPlatformServices.Current.GetPlatformService(IFMXClipboardService));
end;

procedure StringToClipboard(const _s: string);
var
  clp: IFMXClipboardService;
begin
  if TryGetClipboardService(clp) then
    clp.SetClipboard(_s);
end;

procedure StringFromClipboard(out _s: string);
var
  clp: IFMXClipboardService;
  Value: TValue;
  s: string;
begin
  if TryGetClipboardService(clp) then begin
    Value := clp.GetClipboard;
    if not Value.TryAsType(_s) then
      _s := '';
  end;
end;
///////////////////////////////////////////
///


type
  TwCodeTraceViewItem=class(TTreeViewItem)
   private
    FItem:TCodeTraceItem;
   protected
   public
    constructor Create(AOwner: TComponent; ATreeView:TTreeView; ALastItem:TTreeViewItem; const AData:TCodeTraceItem);
    destructor Destroy; override;
    property DataItem:TCodeTraceItem read FItem;
  end;




procedure TCTrForm.actClearExecute(Sender: TObject);
begin
  tv_Trace.Clear;
  mmoData.Lines.Clear;
end;

procedure TCTrForm.actCopyDataExecute(Sender: TObject);
begin
 if (Assigned(tv_Trace.Selected)) and (tv_Trace.Selected is TwCodeTraceViewItem) then
   begin
    StringToClipboard(TwCodeTraceViewItem(tv_Trace.Selected).DataItem.GetCommandParams);
   end;
end;

procedure TCTrForm.actCopyExecute(Sender: TObject);
begin
   if (Assigned(tv_Trace.Selected)) and (tv_Trace.Selected is TwCodeTraceViewItem) then
   begin
    StringToClipboard(TwCodeTraceViewItem(tv_Trace.Selected).DataItem.MessData);
   end;
end;

procedure TCTrForm.actHTestExecute(Sender: TObject);
var LLIst:TStringList;
    I,j,LCount:integer;
    LItem:TCodeTraceItem;
    Lnew:TTreeViewItem;
    LL:TList;
begin
  LLIst:=TStringList.Create;
  LLIst.Add('note: DResList_Count=8 DATE=13:06:13.216,');
  LLIst.Add('note: htmlItems_Count=13 DATE=13:06:13.227');
    LLIst.Add('note: State=,loading DATE=13:06:13.237');
    LLIst.Add('note: Start=http://kilotor.com/ DATE=13:06:13.424');
    //LLIst.Add('not_Found: http://fonts.googleapis.com/css?family=Noto+Sans&subset=cyrillic,latin DATE=13:06:13.426
    // not_Found: https://fonts.googleapis.com/css?family=Lato:400,700,400italic DATE=13:06:13.683
    LLIst.Add('enter: 1 DATE=13:06:13.896');
     LLIst.Add('warn: JS=updateOnlineStatus (http://kilotor.com/local/js/verify.js:32:2);DATA=[b_Check_Offline] DATE=13:06:13.897');
     LLIst.Add('enter: 2 updateOnlineStatus:L=updateOnlineStatus (http://kilotor.com/local/js/verify.js:25:25) DATE=13:06:13.896');
   { LLIst.Add('warn: L=updateOnlineStatus (http://kilotor.com/local/js/verify.js:32:2);DATA=[b_Check_Offline] DATE=13:06:13.897');
    LLIst.Add('warn: L=checkOfflineStatus (http://kilotor.com/local/js/verify.js:74:32);DATA=[CheckStatus=up] DATE=13:06:13.899');
    }
     LLIst.Add('note: JS=htmlItems_Count=177 DATE=13:06:13.227');
    LLIst.Add('exit: updateOnlineStatus:L=updateOnlineStatus (http://kilotor.com/local/js/verify.js:78:4);DATA=[f_connect] DATE=13:06:13.900');
     LLIst.Add('exit: updateOnlineStatus:L=updateOnlineStatus (http://kilotor.com/local/js/verify.js:78:4);DATA=[f_connect] DATE=13:06:13.900');
      LLIst.Add('exit: updateOnlineStatus:L=updateOnlineStatus (http://kilotor.com/local/js/verify.js:78:4);DATA=[f_connect] DATE=13:06:13.900');
    LLIst.Add('note: htmlItems_Count=177 DATE=13:06:13.227');
   tv_Trace.BeginUpdate;
   tv_Trace.Content.BeginUpdate;
  try
   LCount:=0;
   i:=0;
   for j :=1 to 22 do
    begin
      i:=0;
       while i<LList.Count do
        begin
          LItem:=TCodeTraceItem.CreateFromString(LLIst.Strings[i]);
          if LItem.IsEmpty=false then
              try
                LL:=LTList.LockList;
                LL.Add(LItem);
                Inc(LCount);
               finally
                LTList.UnlockList;
              end;
         Inc(i);
        end;
    end;
  finally
    LLIst.Free;
    tv_Trace.Content.EndUpdate;
    tv_Trace.EndUpdate;
  end;
end;

procedure TCTrForm.actScrollExecute(Sender: TObject);
begin
  ///
end;

procedure TCTrForm.actSearchExecute(Sender: TObject);
 var i,j:integer;
    L_Item:TwCodeTraceViewItem;
    L_FoundFlag:Boolean;
begin
 cbe_Find.OnChange(cbe_Find);
 if (F_FindItemIndex>=tv_Trace.GlobalCount-1) then
    i:=0
 else
    i:=F_FindItemIndex+1;
  //
  L_FoundFlag:=False;
  while i<tv_Trace.GlobalCount do
  begin
   if tv_Trace.ItemByGlobalIndex(i) is TwCodeTraceViewItem then
    begin
       L_Item:=TwCodeTraceViewItem(tv_Trace.ItemByGlobalIndex(i));
        begin
          if Pos(cbe_Find.Text,L_Item.Text)>0 then
             begin
               F_FindItemIndex:=i;
               actScroll.Checked:=False;
               L_Item.Select;
               L_FoundFlag:=True;
               j:=cbe_Find.Items.IndexOf(cbe_Find.Text);
               if j<0 then
                  cbe_Find.Items.Append(cbe_Find.Text);
               Break;
             end;
        end;
    end;
   Inc(i);
  end;
 if not(L_FoundFlag) then
     TDialogService.MessageDialog('<'+cbe_Find.Text+'> Not Found!',TMsgDlgType.mtWarning,[TMsgDlgBtn.mbOK],TMsgDlgBtn.mbOK,0,nil);
end;

procedure TCTrForm.actSearchUpdate(Sender: TObject);
begin
 TAction(Sender).Enabled:=(Trim(cbe_Find.Text)<>'');
end;

function TCTrForm.AddCTItem(ATrView: TTreeView; const AItem:TCodeTraceItem): TTreeViewItem;
 ///
 var L_New:TTreeViewItem;
begin
  Result:=nil;
  if (aItem.IsEmpty) then
       exit
  else
   begin
     if AtrView.Count<=0 then FLastItem:=nil;
      L_New:=TwCodeTraceViewItem.Create(ATrView.Owner,ATrView,FLastItem,aItem);
      if Pos('app: ',L_New.Text)=1 then
         begin
             L_New.StyledSettings:=L_New.StyledSettings-[TStyledSetting.FontColor];
             L_New.TextSettings.FontColor:=TAlphaColorRec.Green;
         end
      else
        if Pos(' JS=',L_New.Text)>0 then
           begin
             L_New.StyledSettings:=L_New.StyledSettings-[TStyledSetting.FontColor];
             L_New.TextSettings.FontColor:=TAlphaColorRec.Red;
          end;

      Result:=L_New;
      FLastItem:=Result;
      L_New.IsExpanded:=true;
   end;
end;

procedure TCTrForm.cb_OnlyJSClick(Sender: TObject);
var L_Item:TwCodeTraceViewItem;
    i:integer;
begin
 i:=0;
 while i<tv_Trace.GlobalCount do
  begin
   if tv_Trace.ItemByGlobalIndex(i) is TwCodeTraceViewItem then
    begin
       L_Item:=TwCodeTraceViewItem(tv_Trace.ItemByGlobalIndex(i));
       if (actOnlyJS.Checked=true) then
        begin
          if Pos(' JS=',L_Item.Text)>0 then
             L_Item.Visible:=true
          else L_Item.Visible:=false;
        end
       else L_Item.Visible:=true;
    end;
   Inc(i);
  end;
end;

procedure TCTrForm.cbe_FindChange(Sender: TObject);
begin
  if (chkFinfFromCurrPos.IsChecked=True) and (Assigned(tv_Trace.Selected)) then
     F_FindItemIndex:=tv_Trace.Selected.GlobalIndex
  else F_FindItemIndex:=0;
end;

procedure TCTrForm.FillComboBox;
var i,LCount:integer;
    LItem:TListBoxItem;
begin
  ComboBox1.Items.Clear;
  LCount:=ct_FillCommandsList(1,ComboBox1.Items);
  if LCount<=0 then exit;
  i:=0;
  while i<ComboBox1.Items.Count do
   begin
    if i<ComboBox1.Images.Count then
     ComboBox1.ListItems[i].ImageIndex:=i
    else
     ComboBox1.ListItems[i].ImageIndex:=0;
     Inc(i);
   end;
end;

procedure TCTrForm.FormCreate(Sender: TObject);
var LRect:TRect;
    LS:string;
   L_port:integer;
begin
  F_FindItemIndex:=0;
  lbl_defPort.Text:='default port: '+IntToStr(def_portNum);
  LRect.Left:=-1;
  LRect:=appEnv.Ini.ReadRect('SETTINGS','PosRECT',LRect);
  if Lrect.Left<>-1 then
   SetBounds(Lrect);
  Caption:=appEnv.Params.CaptionLeftPart+' v.'+appEnv.ServiceInfo.GetAppVersionString(2);
  ///
  LT_ApplyIndex:=-1;
  LTList:=TThreadList.Create;
  ///
  L_port:=wCode.Socket.UdpClient.Port;
  if wCode.Socket.UdpClient.Tag<>1 then
     L_port:=appEnv.Ini.ReadInteger('SETTINGS','port',L_port);
  ///
  SetClientPort(L_port);
  ///
  ///
  tv_Trace.Clear;
  ///
  FillComboBox;
  nmbrbx_port.Value:=L_port;
end;

procedure TCTrForm.FormDestroy(Sender: TObject);
var LL:TList;
    i:integer;
    LRect:TRect;
    L_port:integer;
begin
   try
    L_port:=Trunc(nmbrbx_port.Value);
    except L_port:=0;
   end;
   if L_port<=0 then
      L_port:=def_portNum;
   appEnv.Ini.WriteInteger('SETTINGS','port',L_port);
   LRect:=GetBounds;
   if LRect.Left<>-1 then
    begin
      appEnv.Ini.WriteRect('SETTINGS','PosRECT',LRect);
    end;
   appEnv.Ini.Save;
   try
    LL:=LTList.LockList;
    i:=0;
    while i<LL.Count do
     begin
       TObject(LL.Items[i]).Free;
       Inc(i);
     end;
  finally
    LTList.UnlockList;
  end;
  LTList.Free;
end;

procedure TCTrForm.IdUDPServer1UDPRead(AThread: TIdUDPListenerThread;
  const AData: TIdBytes; ABinding: TIdSocketHandle);
var i:Integer;
      s:String;
      LItem:TCodeTraceItem;
      LL:TList;
begin
  s := '';
  try
    s:=BytesToString(AData,IndyTextEncoding(encUTF8));
    if s<>'' then
     begin
       LItem:=TCodeTraceItem.CreateFromString(s);
      { if LItem.CommandName='exclam:' then
          i:=i;
        }
       if LItem.IsEmpty=false then
         try
            LL:=LTList.LockList;
            LL.Add(LItem);
          finally
           LTList.UnlockList;
         end;
     end;
  finally
  end;
end;

procedure TCTrForm.nmbrbx_portExit(Sender: TObject);
var LPort:integer;
begin
 if (nmbrbx_port.Text='') or (nmbrbx_port.Value<1) then
    nmbrbx_port.Value:=def_portNum;
  LPort:=Trunc(nmbrbx_port.Value);
  // if (Trunc(nmbrbx_port.Value)<>wCode.Socket.UdpClient.Port) then
  SetClientPort(Lport);
  ///
  nmbrbx_port.Value:=wCode.Socket.UdpClient.Port;
end;

function TCTrForm.SetClientPort(aPort:integer): Boolean;
var i:integer;
begin
 Result:=false;
 if aPort>0 then
    try
     wCode.ResetSocket('',aPort);
     Result:=true;
    except on E:Exception do
     MessageDlg('TCTrForm.SetClientPort:  '+E.ClassName+' : '+E.Message,TMsgDlgType.mtError,
     [TMsgDlgBtn.mbOk],0);
   end;
  if Result then
   try
    Result:=false;
    IdUDPServer1.Active:=False;
    IdUDPServer1.DefaultPort:=aPort;
   // IdUDPServer1.Bindings.Items[0].IP:=
    if IdUDPServer1.Bindings.Count>0 then
     for i:=0 to IdUDPServer1.Bindings.Count-1 do
      begin
       IdUDPServer1.Bindings.Items[i].Port:= aPort;
      end
    else
      IdUDPServer1.Bindings.Add.Port:=aPort;
    ///
    IdUDPServer1.Active:=true;
     except on E:Exception do
      MessageDlg('TCTrForm.SetClientPort UDPServer1: '+E.ClassName+' : '+E.Message,TMsgDlgType.mtError,
      [TMsgDlgBtn.mbOk],0);
   end;
end;

procedure TCTrForm.tbcDirectChange(Sender: TObject);
begin
  case tbcDirect.TabIndex of
  0: begin
       actCopy.Enabled:=true;
       actCopyData.Enabled:=true;
       actOnlyJS.Enabled:=true;
       actHTest.Enabled:=true;
       actSearch.Enabled:=true;
     end;
  1: begin
       actCopy.Enabled:=false;
       actCopyData.Enabled:=false;
       actOnlyJS.Enabled:=false;
       actHTest.Enabled:=false;
       actSearch.Enabled:=false;
     end;
  end;
end;

procedure TCTrForm.Timer1Timer(Sender: TObject);
 var LL:TList;
    i,iprev:integer;
    LItem:TCodeTraceItem;
    LS:string;
begin
  try
    LL:=LTList.LockList;
     ///
     i:=LT_ApplyIndex+1;
     iPrev:=i;
     while i<LL.Count do
       begin
         LItem:=TCodeTraceItem(LL.Items[i]);
         if LItem.CommandName='clear:' then
          begin
            tv_Trace.Clear;
            mmoData.Lines.Clear;
          end
         else
          if LItem.CommandName='data:' then
           try
            mmoData.BeginUpdate;
             mmoData.Lines.Add('---'+LItem.GetCommandParams+'>'+TimeToStr(LItem.DTime)+'---');
            // mmoData.Lines.Add(LItem.GetDataPart(false));
             if actScroll.Checked=true then
                mmoData.GoToTextEnd;
            finally
            mmoData.EndUpdate;
           end
          else
            try
              tv_Trace.BeginUpdate;
             // tv_Trace.Content.BeginUpdate;
              AddCTItem(tv_Trace,LItem);
            finally
             // tv_Trace.Content.EndUpdate;
              tv_Trace.EndUpdate;
            end;
         Inc(i);
       end;
     LT_ApplyIndex:=LL.Count-1;
     Timer_Idle.Enabled:=(actScroll.Checked=true) and (iPrev=i)
                                                 and (i>2);
     ///
     finally
    LTList.UnlockList;
  end;
end;


procedure TCTrForm.Timer_IdleTimer(Sender: TObject);
begin
  Timer_Idle.Enabled:=false;
  if (tv_Trace.Count>0) and (Assigned(FLastItem)) then
    begin
     tv_Trace.Selected:=FLastItem;
    end;
end;

{ TwCodeTraceReportItem }

constructor TwCodeTraceViewItem.Create(AOwner: TComponent; ATreeView:TTreeView; ALastItem:TTreeViewItem; const AData:TCodeTraceItem);
var L_List:TCustomImageList;
    L_LastItem:TwCodeTraceViewItem;
    LS:string;
begin
  inherited Create(AOwner);
  L_LastItem:=nil;
 { if Pos('htmlItems_Count=177',AData.MessData)>0 then
    begin
      L_LastItem:=nil;
    end;
    }
  FItem:=TCodeTraceItem.CreateFrom(AData);
  if (ALastItem<>nil) and (ALastItem is TwCodeTraceViewItem) then
   begin
     L_LastItem:=TwCodeTraceViewItem(ALastItem);
     LS:=L_LastItem.FItem.MessData;
     ///
     if (FItem.CommandRegime<>2) and (L_LastItem.DataItem.CommandRegime=1) then
       begin
         if (ALastItem<>nil) then
                 Parent:=ALastItem
         else
              Parent:=ATreeView;
       end
     else
       if (FItem.CommandRegime=2) and (L_LastItem.DataItem.CommandRegime<>1) then
        begin
         if (L_LastItem.ParentItem<>nil) and (L_LastItem.ParentItem is TTreeViewItem) then
           begin
             if (L_LastItem.ParentItem.ParentItem<>nil) and (L_LastItem.ParentItem.ParentItem is TTreeViewItem) then
                 Parent:=L_LastItem.ParentItem.ParentItem
             else Parent:=ATreeView;
           end
         else Parent:=ATreeView
        end
      else
       if (L_LastItem.ParentItem<>nil) and (L_LastItem.ParentItem is TTreeViewItem) then
             Parent:=L_LastItem.ParentItem
         else Parent:=ATreeView;
   end
  else
     Parent:=ATreeView;
  ///
  L_List:=ATreeView.Images;
  if (Assigned(L_List)) and (FItem.CommandRegime>=0) and (FItem.CommandRegime<L_List.Count) then
     ImageIndex:=FItem.CommandRegime;
  ///
  Text:=FItem.DataToString(1);
end;

destructor TwCodeTraceViewItem.Destroy;
begin
  if Assigned(FItem) then
   begin
     FItem.Free;
     FItem:=nil;
   end;
  inherited;
end;

end.
