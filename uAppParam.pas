unit uAppParam;
{$M+}

interface

uses
  Winapi.Windows, Vcl.Forms, SysUtils, StrUtils, Classes;

type
  // ���������� ������ ������ �� ���������� �����������, �� ��������, ��� �� ��� �������
  TSignalKind = (added, removed, both);

  TAppParams = class
  private
    FBeginUpdates: Integer;
  private
    FSite: Integer; // ����
    FDelay: Integer; // �������� ����� ���������, ��
    FChannel: Integer; // ����� ��������
    FChannel2: Integer; // ����� �������� 2
    FPeriod: Integer; // �������� �� ... �����
    FTopCnt: Integer; // ������� ����� � ���
    FMinSum: Integer; // �����, ���� �������� ����� ��������� Big Deal
    FIntervalMins: Double; // ������ ���� ������ �� ���������� ... �����
    FFilter: Boolean; // ������ �������
    FCurrencyFilter: string; // ������ �� ������
    FJump: Boolean; // ������� �� ����� ������
    FSignalKind: TSignalKind;
    function GetInUpdate: Boolean;
  public
    ExcludedCurrencies: TStringList; // ������ ����������

    fs: TFormatSettings; // ������ ��� yyyy-mm-dd, ������ ����� - � ������������ �����
    class function AppName: string; static; // �������� ���������� � ������

  const
    BuildNo = {$I BuildNo.inc};
    class var BuildNoAsString: string;

    constructor Create; // ��������� �������� �� ���������
    function AsJson: string; // ��������� ����� ���������
    procedure BeginUpdate; // ����� �������� ������������� ������������� ��������� ��� �������� �����
    procedure EndUpdate;
    property InUpdate: Boolean read GetInUpdate;
    procedure DoSleep(Times: Integer = 1); // �������� �� Delay ms
    // � ����������� �� �������� Site:
    function SiteUrl: string;
    function GetTokenUrl(const hash: string): string;
    function GetShortTokenUrl(const hash: string): string;
    function GetDexUrl: string;
    function SiteCaption: string;
    function NeedZeroSum: Boolean;
  published
    property Site: Integer read FSite write FSite;
    property Delay: Integer read FDelay write FDelay;
    property Channel: Integer read FChannel write FChannel;
    property Channel2: Integer read FChannel2 write FChannel2;
    property Period: Integer read FPeriod write FPeriod;
    property TopCnt: Integer read FTopCnt write FTopCnt;
    property MinSum: Integer read FMinSum write FMinSum;
    property IntervalMins: Double read FIntervalMins write FIntervalMins;
    property Filter: Boolean read FFilter write FFilter;
    property CurrencyFilter: string read FCurrencyFilter write FCurrencyFilter;
    property Jump: Boolean read FJump write FJump;
    property SignalKind: TSignalKind read FSignalKind write FSignalKind;
  end;

var
  AppParam: TAppParams;

const // Site:
  S_FANTOM = 0; // 'ftmscan.com' Fantom
  S_AVAX = 1; // 'snowtrace.io' AVAX, Avalanche
  S_BSC = 2; // 'bscscan.com'

implementation

class function TAppParams.AppName: string;
begin
  if BuildNoAsString = '' then
    BuildNoAsString := FormatFloat('0.0#', BuildNo);
  Result := 'Fantom, ' + BuildNoAsString;
end;

constructor TAppParams.Create;
begin
  Channel := 0;
  FDelay := 250;
  Jump := true;
  Period := 15;
  TopCnt := 3;
  MinSum := 5000;
  IntervalMins := 60;
  Filter := false;
  CurrencyFilter := '';
  SignalKind := both;
  Site := 0;

  fs := TFormatSettings.Create('en-US');
  fs.DecimalSeparator := '.';
  fs.ThousandSeparator := ',';
  fs.ShortTimeFormat := 'hh:nn:ss';
  fs.ShortDateFormat := 'yyyy-mm-dd';

  ExcludedCurrencies := TStringList.Create;
  ExcludedCurrencies.Sorted := true;
  ExcludedCurrencies.Duplicates := dupIgnore;
end;

function TAppParams.AsJson: string;
begin
  Result := '{' +
    '"AppName":"' + AppName + '", ' +
    '"SiteUrl":"' + SiteUrl + '", ' +
    '"SiteCaption":"' + SiteCaption + '", ' +
    '"Channel":' + Channel.ToString + ', ' +
    '"Channel2":' + Channel2.ToString + ', ' +
    '"Mins":' + Period.ToString + ', ' +
    '"TopCnt":' + TopCnt.ToString + ', ' +
    '"MinSum":' + MinSum.ToString + ', ' +
    '"IntervalMins":' + IntervalMins.ToString + ', ' +
    '"Filter":' + IfThen(Filter, 'true', 'false') + ', ' +
    '"CurrencyFilter":"' + CurrencyFilter + '", ' +
    '"Jump":' + IfThen(Jump, 'true', 'false') + ', ' +
    '"SignalKind":"' + IfThen(SignalKind = both, 'both', IfThen(SignalKind = added, 'added', 'removed')) + '", ' +
    '"ExcludedCurrencies":"' + ExcludedCurrencies.Text + '", ' +
    '"FDelay":' + FDelay.ToString +
    '}';
end;

function TAppParams.GetInUpdate: Boolean;
begin
  Result := FBeginUpdates > 0;
end;

procedure TAppParams.BeginUpdate;
begin
  Inc(FBeginUpdates);
end;

procedure TAppParams.EndUpdate;
begin
  Dec(FBeginUpdates);
end;

procedure MySleep(ms: cardinal);
var
  TickCount: LongWord;
begin
  TickCount := GetTickCount + ms;
  repeat
    Sleep(100);
    Application.ProcessMessages;
  until GetTickCount > TickCount;
end;

procedure TAppParams.DoSleep(Times: Integer = 1);
begin
  if FDelay > 0 then
    MySleep(FDelay * Times);
end;

function TAppParams.SiteCaption: string;
const
  Sites: array [0 .. 2] of string = (
    'ftmscan.com', // Fantom
    'snowtrace.io', // AVAX, Avalanche
    'bscscan.com'
    );
begin
  Result := Sites[Site];
end;

// �������� �������� �� ������� ����������
function TAppParams.SiteUrl: string;
const
  Sites: array [0 .. 2] of string = (
    'https://ftmscan.com/txs?p=1',
    'https://snowtrace.io/txs',
    'https://bscscan.com/txs?p=1');
begin
  Result := Sites[Site];
end;

// �������� ����������
function TAppParams.GetTokenUrl(const hash: string): string;
const
  Sites: array [0 .. 2] of string = (
    'https://ftmscan.com/tx/0x',
    'https://snowtrace.io/tx/0x',
    'https://bscscan.com/tx/0x');
begin
  Result := Sites[Site] + hash;
end;

// ������� ���������� �� ����������, ����� ������ ������ �� ������ �������
// �������� �� ����� �� ��������� ����� �� ������ ���������� �� �������� ��������
function TAppParams.GetShortTokenUrl(const hash: string): string;
const
  Sites: array [0 .. 2] of string = (
    'https://ftmscan.com/',
    'https://snowtrace.io/',
    'https://bscscan.com/');
begin
  Result := Sites[Site] + 'txsHandler.ashx?strSearchVal=0x' + hash + '&toggleAction=popover&actionParam=txs';
end;

function TAppParams.GetDexUrl: string;
const
  Sites: array [0 .. 2] of string = (
    'https://dexscreener.com/fantom/',
    'https://dexscreener.com/avalanche/',
    'https://dexscreener.com/bsc/'
    );
begin
  Result := Sites[Site];
end;

// �������� �� � ���������� ��������� ������ �������� �������� � �������� �������
function TAppParams.NeedZeroSum: Boolean;
begin
  Result := true; // Site = 1; // ������ AVAX
end;

end.
