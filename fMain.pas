unit fMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  PropFilerEh, PropStorageEh, sSkinManager, sSkinProvider,
  System.UITypes, Cromis.SimpleLog, System.StrUtils,
  uConst, uAppParam, dea.Status,
  uCurrency, uOper,
  Vcl.StdCtrls, sButton, Vcl.ExtCtrls, sPanel, Vcl.ComCtrls, sStatusBar, acProgressBar,
  System.Actions, Vcl.ActnList, sPageControl, sComboBox, ABSMain, Data.DB, scControls, scGPControls, sCheckBox, sEdit, sSpinEdit, sBevel,
  sMemo, sLabel, Vcl.Menus, DBGridEhGrouping, ToolCtrlsEh, DBGridEhToolCtrls, DynVarsEh, EhLibVCL, GridsEh, DBAxisGridsEh, DBGridEh,
  sGroupBox, System.ImageList, Vcl.ImgList, acAlphaImageList;

type
  TMainForm = class(TForm)
    sSkinProvider1: TsSkinProvider;
    sSkinManager1: TsSkinManager;
    PropStorageEh1: TPropStorageEh;
    TopPanel: TsPanel;
    StartButton: TsButton;
    StopButton: TsButton;
    ProgressBar2: TsProgressBar;
    StatusBar1: TsStatusBar;
    ActionList1: TActionList;
    sPageControl: TsPageControl;
    tsSettings: TsTabSheet;
    tsLog: TsTabSheet;
    tsMain: TsTabSheet;
    TelegramNoComboBox: TsComboBox;
    TestTelegramButton: TsButton;
    DelayEdit: TsDecimalSpinEdit;
    TelegramNo2ComboBox: TsComboBox;
    tsBigDeals: TsTabSheet;
    MinsEdit: TsDecimalSpinEdit;
    TopCntEdit: TsDecimalSpinEdit;
    MinSumEdit: TsDecimalSpinEdit;
    IntervalMinsEdit: TsDecimalSpinEdit;
    JumpCheckBox: TsCheckBox;
    FilterCheckBox: TscGPCheckBox;
    CurrencyComboBox: TsComboBox;
    sBevel1: TsBevel;
    LogMemo: TsMemo;
    SendLogsLabel: TsWebLabel;
    SendSettingsLabel: TsWebLabel;
    dsReturns: TDataSource;
    BigPopupMenu: TPopupMenu;
    NFilter: TMenuItem;
    NClearFilter: TMenuItem;
    dsMemBigDeals: TDataSource;
    tbMemBigDealsView: TABSTable;
    DateTimeField1: TDateTimeField;
    StringField1: TStringField;
    BooleanField1: TBooleanField;
    StringField2: TStringField;
    FloatField2: TFloatField;
    IntegerField1: TIntegerField;
    ReturnsGrid: TDBGridEh;
    BigGrid: TDBGridEh;
    SignalKindRadio: TsRadioGroup;
    sBevel2: TsBevel;
    N1: TMenuItem;
    NOpenLink: TMenuItem;
    ReturnsPopupMenu: TPopupMenu;
    NOpenReturnsLink: TMenuItem;
    ExcludeCurrenciesMemo: TsMemo;
    NAddtoExcludes: TMenuItem;
    NAddtoexcludesFromBig: TMenuItem;
    N2: TMenuItem;
    NCopyLink: TMenuItem;
    NCopyLinkBig: TMenuItem;
    N3: TMenuItem;
    CharImageList: TsCharImageList;
    dsReturns2: TDataSource;
    tsTopRemoved: TsTabSheet;
    Returns2Grid: TDBGridEh;
    tbMemBigDealsViewPlace2: TIntegerField;
    Returns2PopupMenu: TPopupMenu;
    NOpenReturns2Link: TMenuItem;
    NCopy2Link: TMenuItem;
    MenuItem3: TMenuItem;
    NAddtoExcludes2: TMenuItem;
    SiteComboBox: TsComboBox;
    SaveSettingsButton: TsButton;
    tbMemReturnsView: TABSTable;
    tbMemReturnsViewCurrency: TStringField;
    tbMemReturnsViewDealsBuy: TIntegerField;
    tbMemReturnsViewDealsSell: TIntegerField;
    tbMemReturnsViewDeals: TIntegerField;
    tbMemReturnsViewVolumeBuy: TFloatField;
    tbMemReturnsViewVolumeSell: TFloatField;
    tbMemReturnsViewDexLink: TStringField;
    tbMemReturns2View: TABSTable;
    tbMemReturns2ViewCurrency: TStringField;
    tbMemReturnsDeals2Buy: TIntegerField;
    tbMemReturns2ViewDealsSell: TIntegerField;
    tbMemReturns2ViewDeals: TIntegerField;
    tbMemReturns2ViewVolumeBuy: TFloatField;
    tbMemReturns2ViewVolumeSell: TFloatField;
    tbMemReturns2ViewDexLink: TStringField;
    BottomPanel: TsPanel;
    SortAddedRadio: TsRadioGroup;
    Bottom2Panel: TsPanel;
    SortRemovedRadio: TsRadioGroup;
    tbMemReturnsViewLastAddedTime: TDateTimeField;
    tbMemReturnsViewLastRemovedTime: TDateTimeField;
    tbMemReturns2ViewLastAddedTime: TDateTimeField;
    tbMemReturns2ViewLastRemovedTime: TDateTimeField;
    procedure BigGridColumns5CellDataLinkClick(Grid: TCustomDBGridEh; Column: TColumnEh);
    procedure BigGridGetCellParams(Sender: TObject; Column: TColumnEh; AFont:
      TFont; var Background: TColor; State: TGridDrawState);
    procedure BigPopupMenuPopup(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure StartButtonClick(Sender: TObject);
    procedure StopButtonClick(Sender: TObject);
    procedure ChangeControls(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure NAddtoExcludesClick(Sender: TObject);
    procedure NAddtoexcludesFromBigClick(Sender: TObject);
    procedure NOpenLinkClick(Sender: TObject);
    procedure NClearFilterClick(Sender: TObject);
    procedure NCopyLinkBigClick(Sender: TObject);
    procedure NCopyLinkClick(Sender: TObject);
    procedure NFilterClick(Sender: TObject);
    procedure NOpenReturnsLinkClick(Sender: TObject);
    procedure PropStorageEh1AfterLoadProps(Sender: TObject);
    procedure Returns2GridGetCellParams(Sender: TObject; Column: TColumnEh; AFont:
      TFont; var Background: TColor; State: TGridDrawState);
    procedure ReturnsGridColumns0CellDataLinkClick(Grid: TCustomDBGridEh; Column: TColumnEh);
    procedure ReturnsGridGetCellParams(Sender: TObject; Column: TColumnEh; AFont:
      TFont; var Background: TColor; State: TGridDrawState);
    procedure ReturnsPopupMenuPopup(Sender: TObject);
    procedure SaveSettingsButtonClick(Sender: TObject);
    procedure SendLogsToTelegramButtonClick(Sender: TObject);
    procedure SendSettingsToTelegramButtonClick(Sender: TObject);
    procedure SortAddedRadioClick(Sender: TObject);
    procedure SortRemovedRadioClick(Sender: TObject);
    procedure TestTelegramButtonClick(Sender: TObject);
  private
    AlreadyRun: Boolean;
    procedure EnableButtons(AEnable: Boolean);
    procedure DoWork;
    procedure UpdateParams(Sender: TObject = nil);
    procedure ProcessOpers(const Opers: TOpArray);
    procedure GoTransactionLink;
    procedure GoDexCurrencyLink(tbMemTable: TABSTable);
    procedure AddtoExcludes(tbMemTable: TABSTable);
    procedure CopyCurrencyBigLink;
    procedure CopyCurrencyLink(tbMemTable: TABSTable);
    function IsAddedMenu(Sender: TObject): Boolean;
    procedure xLog(const s: string; toLog: Boolean = false);
  public
  end;

var
  MainForm: TMainForm;

implementation

uses
  dea.Tools, dea.debug, dea.cl, dea.TelegramHelper, System.Types, dea.Get,
  Winapi.ShellAPI, Vcl.Clipbrd,
  Rest.Json,
  SynCommons, SynMustache, uProcess, uDataModule;

{$R *.dfm}


procedure TMainForm.NOpenLinkClick(Sender: TObject);
begin
  GoTransactionLink;
end;

procedure TMainForm.NOpenReturnsLinkClick(Sender: TObject);
begin
  if IsAddedMenu(Sender) then
    GoDexCurrencyLink(tbMemReturnsView)
  else
    GoDexCurrencyLink(tbMemReturns2View);
end;

procedure TMainForm.NCopyLinkClick(Sender: TObject);
begin
  if IsAddedMenu(Sender) then
    CopyCurrencyLink(tbMemReturnsView)
  else
    CopyCurrencyLink(tbMemReturns2View);
end;

procedure TMainForm.CopyCurrencyLink(tbMemTable: TABSTable);
var
  Link: string;
begin
  Link := tbMemTable.FieldByName('DexLink').AsString;

  Clipboard.AsText := Link;
end;

procedure TMainForm.CopyCurrencyBigLink;
var
  Hash: string;
begin
  Hash := tbMemBigDealsView.FieldByName('hash').AsString;
  Clipboard.AsText := AppParam.GetTokenUrl(Hash);
end;

function TMainForm.IsAddedMenu(Sender: TObject): Boolean;
begin
  result := (Sender as TMenuItem).GetParentMenu.Tag = 100;
end;

procedure TMainForm.NAddtoExcludesClick(Sender: TObject);
begin
  if IsAddedMenu(Sender) then
    AddtoExcludes(tbMemReturnsView)
  else
    AddtoExcludes(tbMemReturns2View);
end;

procedure TMainForm.NAddtoexcludesFromBigClick(Sender: TObject);
begin
  AddtoExcludes(tbMemBigDealsView);
end;

procedure TMainForm.ReturnsGridColumns0CellDataLinkClick(Grid: TCustomDBGridEh;
  Column: TColumnEh);
begin
  GoDexCurrencyLink(Grid.DataSource.DataSet as TABSTable);
end;

procedure TMainForm.BigGridColumns5CellDataLinkClick(Grid: TCustomDBGridEh;
  Column: TColumnEh);
begin
  GoTransactionLink;
end;

procedure TMainForm.BigGridGetCellParams(Sender: TObject; Column: TColumnEh;
  AFont: TFont; var Background: TColor; State: TGridDrawState);
var
  Place: Integer;
begin
  if tbMemBigDealsView.FieldByName('InOut').AsBoolean and (Column.FieldName <> 'hash') then begin
    AFont.Color := clGreen; // scDarkGreen;
    Background := scLightGreen;
  end;
  if (Column.FieldName = 'Place') or (Column.FieldName = 'Place2') then begin // фиксированные пороги, чтобы отрисовка не тормозила
    Place := tbMemBigDealsView.FieldByName(Column.FieldName).AsInteger;
    if Place <= 5 then begin
      AFont.Style := [fsBold];
      AFont.Color := scDarkBlue;
    end
    else if Place > 30 then
      AFont.Size := 8
    else if Place > 50 then
      AFont.Size := 7;
  end;
end;

procedure TMainForm.BigPopupMenuPopup(Sender: TObject);
var
  Currency, Hash: string;
begin
  Currency := tbMemBigDealsView.FieldByName('Currency').AsString;
  Hash := tbMemBigDealsView.FieldByName('hash').AsString;
  NOpenLink.Enabled := Hash <> '';
  NOpenLink.Caption := 'Открыть ссылку на транзакцию';
  NCopyLinkBig.Enabled := Hash <> '';
  NCopyLinkBig.Caption := 'Копировать ссылку';
  NAddtoexcludesFromBig.Enabled := tbMemBigDealsView.FieldByName('Currency').AsString <> '';
  NAddtoexcludesFromBig.Caption := 'Добавить валюту ' + tbMemBigDealsView.FieldByName('Currency').AsString + ' в исключения';
end;

procedure TMainForm.ReturnsPopupMenuPopup(Sender: TObject);
begin
  if (Sender as TPopupMenu).Tag = 100 then begin
    NOpenReturnsLink.Enabled := tbMemReturnsView.FieldByName('DexLink').AsString <> '';
    NOpenReturnsLink.Caption := 'Открыть dex-ссылку на ' + tbMemReturnsView.FieldByName('Currency').AsString;
    NCopyLink.Enabled := tbMemReturnsView.FieldByName('DexLink').AsString <> '';
    NCopyLink.Caption := 'Копировать dex-ссылку';
    NAddtoExcludes.Enabled := tbMemReturnsView.FieldByName('Currency').AsString <> '';
    NAddtoExcludes.Caption := 'Добавить валюту ' + tbMemReturnsView.FieldByName('Currency').AsString + ' в исключения';
  end
  else begin
    NOpenReturns2Link.Enabled := tbMemReturns2View.FieldByName('DexLink').AsString <> '';
    NOpenReturns2Link.Caption := 'Открыть dex-ссылку на ' + tbMemReturns2View.FieldByName('Currency').AsString;
    NCopy2Link.Enabled := tbMemReturns2View.FieldByName('DexLink').AsString <> '';
    NCopy2Link.Caption := 'Копировать dex-ссылку';
    NAddtoExcludes2.Enabled := tbMemReturns2View.FieldByName('Currency').AsString <> '';
    NAddtoExcludes2.Caption := 'Добавить валюту ' + tbMemReturns2View.FieldByName('Currency').AsString + ' в исключения';
  end;
end;

procedure TMainForm.EnableButtons(AEnable: Boolean);
begin
  StartButton.Enabled := AEnable;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  AppParam := TAppParams.Create;
  AppParam.BeginUpdate;

  Application.UpdateFormatSettings := false;
  FormatSettings.DecimalSeparator := '.';
  utc_offset := OffsetUTC2;
  AlreadyRun := false;

  MainForm.Caption := AppParam.AppName;

  SimpleLog.RegisterLog('log', WorkingPath + main_log, 2000, 5, [lpTimestamp, lpType]);
  SimpleLog.LockType := ltProcess; // ltMachine, ltNone;
  Log('start ' + AppParam.AppName + ' - - - - - - - - - - - - -');

  StopButton.Visible := false;
  ProgressBar2.Position := 0;
  ProgressBar2.Step := 1;
  Status.Bind(StatusBar1, StopButton, 1);
  Status.Bind(StatusBar1, ProgressBar2, 2);
{$WARN SYMBOL_PLATFORM OFF}
  // SaveStringOn := DebugHook <> 0;
{$WARN SYMBOL_PLATFORM ON}
  Currencies := TCurrencies.Create; // к каждой валюте присоединен объект tbMem

  dm.ABSDatabase1.DatabaseFileName := WorkingPath + 'data.abs';
  dm.tbDeals.Open;
  dm.tbDeals.IndexName := 'xHash';
  dm.tbDeals.First;

  dm.tbMemReturns.CreateTable;
  dm.tbMemReturns.Open;
  dm.tbMemReturns.IndexName := 'xCurrency';

//  dm.tbMemReturns2.Open;
//  dm.tbMemReturns2.IndexName := 'xCurrency';

  tbMemReturnsView.Open;
  tbMemReturnsView.IndexName := 'xDealsBuy';
  tbMemReturns2View.Open;
  tbMemReturns2View.IndexName := 'xDealsSell';

  dm.tbMemBigDeals.CreateTable;
  dm.tbMemBigDeals.Open;
  dm.tbMemBigDeals.IndexName := 'xDateRev';

  tbMemBigDealsView.Open;
  tbMemBigDealsView.IndexName := 'xDateRev';
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  Log('finish');
  Currencies.Free;
  AppParam.Free;
  dm.ABSDatabase1.CloseDataSets;
end;

procedure TMainForm.PropStorageEh1AfterLoadProps(Sender: TObject);
begin
  AppParam.EndUpdate;
  UpdateParams;
end;

procedure TMainForm.StartButtonClick(Sender: TObject);
begin
  Status.Stopped := false;
  EnableButtons(false);
  StopButton.Visible := true;
  ProgressBar2.Position := 0;
  ProgressBar2.Visible := true;
  try
    UpdateParams(StartButton);
    Log('AppParam = ' + AppParam.AsJson);
    DoWork;
  finally
    Status.Update('ok');
    ProgressBar2.Visible := false;
    StopButton.Visible := false;
    EnableButtons(true);
  end;
end;

procedure TMainForm.StopButtonClick(Sender: TObject);
begin
  Status.Stopped := true;
  StopButton.Visible := false;
  Log('Прервано пользователем');
end;

procedure TMainForm.ChangeControls(Sender: TObject);
begin
  UpdateParams(Sender);
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  Status.Stopped := true;
  CanClose := true;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  RunTelegramHelper;
end;

procedure TMainForm.NClearFilterClick(Sender: TObject);
begin
  FilterCheckBox.Checked := false;
end;

procedure TMainForm.NFilterClick(Sender: TObject);
var
  Currency: string;
begin
  Currency := tbMemBigDealsView.FieldByName('Currency').AsString;
  if Currency <> '' then begin
    AppParam.BeginUpdate;
    CurrencyComboBox.Text := Currency;
    FilterCheckBox.Checked := true;
    AppParam.EndUpdate;
    UpdateParams;
  end;
end;

procedure TMainForm.SendSettingsToTelegramButtonClick(Sender: TObject);
begin
  SendToTelegramHelper(AppParam.AsJson + CR + AppParam.AppName, TelegramGroupCrypto);
end;

procedure TMainForm.SendLogsToTelegramButtonClick(Sender: TObject);
begin
  TelegramHelperSendLogs(AppParam.AppName, TelegramGroupCrypto);
end;

procedure TMainForm.TestTelegramButtonClick(Sender: TObject);
begin
  TestTelegramHelper(AppParam.AppName, TelegramNoComboBox.ItemIndex);
end;

procedure TMainForm.UpdateParams(Sender: TObject = nil);
begin
  if AppParam.InUpdate then
    exit;

  AppParam.Site := SiteComboBox.ItemIndex;
  AppParam.Channel := TelegramNoComboBox.ItemIndex;
  AppParam.Channel2 := TelegramNo2ComboBox.ItemIndex;
  AppParam.Delay := Trunc(DelayEdit.Value);
  if AppParam.Delay < 0 then
    AppParam.Delay := 0;
  AppParam.Period := Trunc(MinsEdit.Value);
  AppParam.TopCnt := Trunc(TopCntEdit.Value);
  AppParam.MinSum := Trunc(MinSumEdit.Value);
  AppParam.IntervalMins := IntervalMinsEdit.Value;
  AppParam.Jump := JumpCheckBox.Checked;
  AppParam.SignalKind := TSignalKind(SignalKindRadio.ItemIndex);

  AppParam.Filter := FilterCheckBox.Checked;
  AppParam.CurrencyFilter := CurrencyComboBox.Text;

  if AppParam.Filter then
    tbMemBigDealsView.Filter := 'Currency="' + AppParam.CurrencyFilter + '"'
  else
    tbMemBigDealsView.Filter := '';
  tbMemBigDealsView.Filtered := AppParam.Filter;
  if AppParam.TopCnt <= 0 then
    AppParam.TopCnt := 3;
  AppParam.ExcludedCurrencies.Assign(ExcludeCurrenciesMemo.Lines);
end;

procedure TMainForm.GoTransactionLink;
var
  Hash: string;
begin
  Hash := tbMemBigDealsView.FieldByName('hash').AsString;
  if Hash <> '' then
    ShellExecute(Application.Handle, 'Open', PChar(AppParam.GetTokenUrl(Hash)), nil, nil, SW_SHOWNORMAL);
end;

procedure TMainForm.GoDexCurrencyLink(tbMemTable: TABSTable);
var
  Link: string;
begin
  Link := tbMemTable.FieldByName('DexLink').AsString;
  if Link <> '' then
    ShellExecute(Application.Handle, 'Open', PChar(Link), nil, nil, SW_SHOWNORMAL);
end;

procedure TMainForm.AddtoExcludes(tbMemTable: TABSTable);
var
  Currency: string;
begin
  Currency := tbMemTable.FieldByName('Currency').AsString;
  if Currency <> '' then
    ExcludeCurrenciesMemo.Lines.Add(Currency);
end;

procedure TMainForm.NCopyLinkBigClick(Sender: TObject);
begin
  CopyCurrencyBigLink;
end;

procedure TMainForm.Returns2GridGetCellParams(Sender: TObject; Column:
  TColumnEh; AFont: TFont; var Background: TColor; State: TGridDrawState);
begin
  if tbMemReturns2View.FieldByName('DealsSell').AsInteger = 0 then
    AFont.Color := clGrayText;
end;

procedure TMainForm.ReturnsGridGetCellParams(Sender: TObject; Column:
  TColumnEh; AFont: TFont; var Background: TColor; State: TGridDrawState);
begin
  if tbMemReturnsView.FieldByName('DealsBuy').AsInteger = 0 then
    AFont.Color := clGrayText;
end;

// обработка сделок текущего прохода, определение мест в топе, отправка сообщений
procedure TMainForm.ProcessOpers(const Opers: TOpArray);
var
  I, cntBig: Integer;
begin
  cntBig := 0; // считаем большие сделки (>= MinSum), чтобы знать обновлять ли BigDealsView
  BigGrid.SaveVertPos('hash');
  ReturnsGrid.SaveVertPos('currency');
  Returns2Grid.SaveVertPos('currency');
  dm.tbMemBigDeals.DisableControls;
  tbMemReturnsView.DisableControls;
  tbMemReturns2View.DisableControls;
  try
    for I := 0 to high(Opers) do begin
      if not Opers[I].dupl and Opers[I].IsLiquid then begin // повторные операции по хешу не учитывать
        // добавляем в список валют и таблицу операций по валюте. Истина если сделка большая
        if Currencies.AppendMemOper(Opers[I], dm.tbMemBigDeals, AppParam.MinSum) then
          Inc(cntBig); // считаем сделки добавленные на вкладку BigDeals
      end;
    end;
    UpdateReturns(dm.tbMemReturns{, dm.tbMemReturns2}); // посчитать обороты и обновить первую вкладку
    SetupPlaces(CurrencyComboBox, dm.tbMemBigDeals); // здесь обновляется tbMemBigDeals
  finally
    if JumpCheckBox.Checked then begin
      if cntBig > 0 then
        tbMemBigDealsView.First;
    end
    else begin
      tbMemBigDealsView.Refresh;
      BigGrid.RestoreVertPos('hash');
    end;

    tbMemReturnsView.Refresh;
    tbMemReturns2View.Refresh;
    if not JumpCheckBox.Checked then begin
      ReturnsGrid.RestoreVertPos('currency');
      Returns2Grid.RestoreVertPos('currency');
    end;

    dm.tbMemBigDeals.EnableControls;
    tbMemReturnsView.EnableControls;
    tbMemReturns2View.EnableControls;
  end;

  SendSignal(Opers); // обязательно после распределения мест
end;

procedure TMainForm.DoWork;
var
  Op: TOper;
  Rows: TRowsArray;
  Cells: TRowsArray;
  I, cntAdded, cntRepeat, cntError: Integer;
  s: string;
  // NewOper: TStringDynArray; // хеши добавленные в этом проходе
  Opers: TOpArray; // операции добавленные в этом проходе (50 операций на странице, без повторов по хешу и без лишних операций)

  (* function FindHash(Hash: string): Boolean;
    var
    I: Integer;
    begin
    result := false;
    for I := 0 to high(NewOper) do begin
    if NewOper[I] = Hash then
    exit(true);
    end;
    end;


    // проверяет на уникальность и добавляет в массив операций данного прохода
    procedure AddToOpers;
    begin
    // если вместо названия адрес кошелька - не берем
    // if  StartsStr('0x', tbDeals.FieldByName('t1').AsString) or
    // StartsStr('0x', tbDeals.FieldByName('t2').AsString) then
    // exit; // операция не для нас
    if FindHashAndMarkAsDupl(Op.Hash, Opers) then
    exit; // ничего добавлять не надо, повторная операция по хешу
    Opers := Opers + [Op];
    end;
  *)
begin
  if AlreadyRun then
    exit;
  AlreadyRun := true;
  dm.tbDeals.DisableControls;
  try
    repeat
      Application.ProcessMessages;
      if Status.Stopped then
        Break;
      try
        // считываем основную страницу, на ней транзакции
        // в апи не нашла такой команды, приходится парсить
        s := xGet(AppParam.SiteUrl, '', nil); // StringSaveToFile(s, 'full.html');
      except
        on E: Exception do begin
          Log('!xget ' + E.Message);
          Sleep(200);
          Continue;
        end;
      end;
      cntAdded := 0;
      cntRepeat := 0;
      cntError := 0;

      Rows := reprepTable(reprep(s, '<tbody>', '</tbody>')); // таблица
      if Length(Rows) = 0 then begin
        xLog('!!! не найдены транзакции', true);
        // <h1 class="h2 font-weight-normal">Sorry, our servers are currently busy</h1>
        if AppParam.Delay < 900 then begin // адаптивно увеличить задержку
          AppParam.Delay := AppParam.Delay + 25;
          DelayEdit.Value := AppParam.Delay;
          Log('AppParam.Delay = ', AppParam.Delay);
        end;
        AppParam.DoSleep(4); // 4-кратная задержка
        Inc(cntError);
      end;

      if Status.Stopped then
        Break;

      // NewOper := nil;
      Opers := nil;
      for I := 0 to high(Rows) do begin // цикл по строкам основного адреса - 50 штук
        Cells := reprepCells(Rows[I], '<td'); // ячейки одной строки
        Op.ParseRow(Cells); // парсим строку таблицы в переменную op

        if Op.error or not Op.IsLiquid or
          (not AppParam.NeedZeroSum and (Op.amount = 0)) then // учитываем только операции по ликвидности
          Continue;

        if not dm.FindHash(Op.Hash) then begin // ищем хеш в базе - новый хеш
          Op.ParseStep2; // допарсить валюту и сумму
          if Op.Currency = '' then begin
            Inc(cntError);
            AppParam.DoSleep;
          end
          else begin
            Op.AppendLine(dm.tbDeals); // добавляет в базу tbDeals на диске, с обрезанием
            // NewOper := NewOper + [Op.Hash];
            // добавляет в массив операций прохода
            if not FindHashAndMarkAsDupl(Op.Hash, Opers) then // ничего добавлять не надо, повторная операция по хешу
              Opers := Opers + [Op]; // эта проверка скорее всего лишняя для ликвидности

            Inc(cntAdded);
          end
        end else begin
          Inc(cntRepeat);
        end;
        // такой хеш есть, минимум один. Ищем полное совпадение
        // if Op.Find(dm.tbDeals) then begin // совпали - пропускаем, уже есть эта операция
        /// flag := 0;
        /// if FindHash(Op.Hash) then begin // если две одинаковых операции в текущем проходе - ошибка
        /// Inc(cntError);
        /// Log('Повторная операция !!!! ' + Op.Hash);
        /// end;
        // end else begin // строки не совпали - добавляем - думаю, для ликвидности не реально
        /// flag := 1;
        // Log('Повторный хеш !!!! ' + Op.Hash);
        // Op.AppendLine(dm.tbDeals);
        // Inc(cntChanged);
        // if not FindHash(Op.Hash) then // хеш из предыдущих проходов
        // Inc(cntChanged2);
        // AddToOpers; // добавляет в массив операций прохода
        // end;
        // end;
        // Log(flag.ToString + ' : ' + Op.LogLine);
      end;

      xLog('[' + TimeToStr(Now) + '] Новых: ' + cntAdded.ToString +
        ' / ' + Length(Opers).ToString + ' / ' + Length(Rows).ToString +
        IfThen(cntRepeat > 0, ', повторов: ' + cntRepeat.ToString, '') + CR +
        '   ошибок: ' + cntError.ToString
        );

      // добавить операции в таблицу в памяти (кроме хешей-повторов)
      ProcessOpers(Opers); // тут же проставляются места и отсылаются сообщения

      // Currencies.Cleanup;    пока не надо

      AppParam.DoSleep;
    until false;

  finally
    AlreadyRun := false;
    dm.tbDeals.EnableControls;
  end;
end;

procedure TMainForm.SaveSettingsButtonClick(Sender: TObject);
begin
  PropStorageEh1.SaveProperties;
end;

procedure TMainForm.SortAddedRadioClick(Sender: TObject);
begin
  if SortAddedRadio.ItemIndex = 0 then
    tbMemReturnsView.IndexName := 'xDealsBuy'
  else
  if SortAddedRadio.ItemIndex = 1 then
    tbMemReturnsView.IndexName := 'xVolumeBuy'
  else
    tbMemReturnsView.IndexName := 'xLastAddedTime';
end;

procedure TMainForm.SortRemovedRadioClick(Sender: TObject);
begin
  if SortRemovedRadio.ItemIndex = 0 then
    tbMemReturns2View.IndexName := 'xDealsSell'
  else
  if SortRemovedRadio.ItemIndex = 1 then
    tbMemReturns2View.IndexName := 'xVolumeSell'
  else
    tbMemReturns2View.IndexName := 'xLastRemovedTime';
end;

procedure TMainForm.xLog(const s: string; toLog: Boolean = false);
begin
  if LogMemo.Lines.Count > 1000 then
    LogMemo.Lines.Clear;
  LogMemo.Lines.Add(s);
  if toLog then
    Log(s);
end;

initialization

SetDefStorage;

end.
