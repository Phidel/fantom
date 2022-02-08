unit uCurrency;
// TCurrencies = список валют (TStringList) + база в памяти с операциями по каждой валюте
// к каждой паре присоединен объект TCurrencyCargo, который в частности
// содержит tbMem (для подсчета оборотов за последние минуты).
// tbMem обрезается до MAX_RECS записей
// повторные операции по одному хешу не добавляются и такие хеши не учитываются в оборотах

interface

uses
  AbsMain, Classes, SysUtils, StrUtils, DateUtils, uOper;

type
  // результаты подсчета оборотов за период N минут
  TReturn = record
    DealsBuy: Integer; // количество сделок на покупку (добавление ликвидности)
    DealsSell: Integer; // сделок на продажу (удаление ликвидности)
    VolumeBuy: Double; // объем сделок на покупку
    VolumeSell: Double; // объем сделок на продажу
    // LastPrice: Double; цены нет в этом проекте
    function Deals: Integer; // разница DealsBuy - DealsSell
    procedure Clear;
  end;

type
  TOperType = (_added, _removed);

  // объект, прицепленный к каждой валюте
  TCurrencyCargo = class
  type
    TTopRec = record
      EnteredToTop: TDateTime; // когда последний раз зашла в топ
      InTop: Boolean; // сейчас в топе?
      NewInTop: Boolean; // первый раз зашла в топ
      NeedSignal: Boolean; // сигнал отправляется только раз при вхождении в топ и появлении сделки на покупку более пороговой суммы
      LastSignal: TDateTime; // время последнего сигнала
      Place: Integer; // место в таблице на отображения на вкладке BigDeals
    end;
  public
    Name: string; // currency
    LastDealTime: TDateTime; // время последней сделки, используется в cleanup
    LastAddedTime: TDateTime; // время последнего добавления ликвидности
    LastRemovedTime: TDateTime; // - убавления
    LastHash: string; // хеш последней транзакции, исп при отправе сигнала - ссылка
    LastDealsBuy: Integer; // сделок за последний оборотный период, для вывода в сообщение
    LastDealsSell: Integer; // аналогично
    LastVolumeBuy: Double; // объем за последний оборотный период, для вывода в сообщение
    LastVolumeSell: Double; // аналогично

    Tops: array [TOperType] of TTopRec; // два топа - добавления и убирания ликвидности

    tbMem: TABSTable; // отобранные операции в памяти для подсчета оборотов по валюте, с отсечением по времени
    DexLink: string; // ссылка на страницу валюты на dexscreener.com
    constructor Create(const ACurrency, ALink: string);
    destructor Destroy; override;
    function AppendMemOper(CurrencyNo: Integer; Op: TOper; tbMemBigDeals: TABSTable; MinSum: Double): Boolean;
    // возвращает обороты за последние Mins минут
    procedure GetReturns(Mins: Double; var AReturn: TReturn);
  end;

  TCurrencies = class
  private
    function SetIfAbsent(const ACurrency, ADexLink: string): TCurrencyCargo;
  public
    Currencies: TStringList;

    constructor Create;
    destructor Destroy; override;
    procedure ClearCurrencies;
    procedure Cleanup(MinDeals: Integer = 3);
    function AppendMemOper(Op: TOper; tbMemBigDeals: TABSTable; MinSum: Double): Boolean;
    // возвращает обороты за последние Mins минут
    procedure GetReturns(const ACurrency: string; Mins: Double; var AReturn: TReturn);
    procedure MarkAsTop(oAdded: TOperType; const ACurrency: string; NewPlace, nTop: Integer; ADeals: Integer; AVolume: Double);
    // procedure SetPlace(const ACurrency: string; Place: Integer);
    function GetPlace(oAdded: TOperType; const ACurrency: string): Integer; // ищет валюту в списке и возвращает место в топе
    procedure ResetAllPlaces;
    function Get(const ACurrency: string): TCurrencyCargo;
  end;

  // названия валют могут быть произвольными - включать пробелы, амперсанды и т.п.
  // создает валидное имя таблицы по названию валюты
function NormalizeCurrency(const ACurrency: string): string;

const
  MAX_RECS = 6000;

var
  Currencies: TCurrencies; // валюта + объект - база в памяти

implementation

uses
  dea.tools, dea.abs, Data.DB, uConst,
  {dea.TelegramHelper,} dea.Get;

procedure TCurrencies.ClearCurrencies;
begin
  Currencies.Clear;
end;

constructor TCurrencies.Create;
begin
  inherited;
  Currencies := TStringList.Create; // к каждой паре присоединен объект tbMem
  Currencies.Sorted := true;
  Currencies.Duplicates := dupIgnore;
  Currencies.OwnsObjects := true;
end;

destructor TCurrencies.Destroy;
begin
  ClearCurrencies;
  Currencies.Free;
  inherited;
end;

function NormalizeCurrency(const ACurrency: string): string;
begin
  Result := ReplaceStr(ACurrency, ' ', '_');
  Result := ReplaceStr(Result, ';', '_');
  Result := ReplaceStr(Result, '&', '_');
end;

// добавляет запись в таблицу в памяти, приаттаченную к валюте
// также, если превышен порог, добавляет в таблицу больших транзакций (общая для всех валют)
// возвращает истину если сделка большая
function TCurrencyCargo.AppendMemOper(CurrencyNo: Integer; Op: TOper; tbMemBigDeals: TABSTable; MinSum: Double): Boolean;
var
  currency: string;
  amount: Double;
begin
  if CurrencyNo = 2 then begin
    currency := Op.currency2;
    amount := Op.amount2;
  end
  else begin
    currency := Op.currency;
    amount := Op.amount;
  end;
  LastDealTime := Now;
  LastHash := Op.hash;
  // обрезание
  if tbMem.RecordCount <= MAX_RECS then
    tbMem.Append
  else begin
    tbMem.IndexName := 'xDate';
    tbMem.First; // затираем самую первую
    tbMem.Edit;
  end;
  if Op.inout then
    LastAddedTime := LastDealTime
  else
    LastRemovedTime := LastDealTime;
  tbMem.FieldByName('adate').AsDateTime := Op.adate;
  tbMem.FieldByName('hash').AsString := Op.hash;
  tbMem.FieldByName('inout').AsBoolean := Op.inout;
  tbMem.FieldByName('amount').AsFloat := amount;
  tbMem.Post;

  Result := amount >= MinSum;
  if Result then begin
    tbMemBigDeals.Append;
    tbMemBigDeals.FieldByName('currency').AsString := currency;
    tbMemBigDeals.FieldByName('adate').AsDateTime := Op.adate;
    tbMemBigDeals.FieldByName('hash').AsString := Op.hash;
    tbMemBigDeals.FieldByName('inout').AsBoolean := Op.inout;
    tbMemBigDeals.FieldByName('amount').AsFloat := amount;
    tbMemBigDeals.FieldByName('Place').AsInteger := 0; // Place; - место еще неизвестно
    tbMemBigDeals.Post;
  end;
end;

// вовзращает указатель на валюту
// если нет такой валюты - создает и добавляет в список
function TCurrencies.SetIfAbsent(const ACurrency, ADexLink: string): TCurrencyCargo;
var
  nPos: Integer;
begin
  nPos := Currencies.IndexOf(ACurrency);
  if nPos = -1 then begin // не нашли - создаем таблицу и добавляем в список
    Result := TCurrencyCargo.Create(ACurrency, ADexLink);
    Currencies.AddObject(ACurrency, Result);
  end
  else
    Result := TCurrencyCargo(Currencies.Objects[nPos]);

  if Result = nil then begin // не бывает
    log('! SetIfAbsent nil');
  end;
end;

// На входе - операция.
// ищет валюту в списке, если не находит - добавляет ее в список
// добавляет операцию в таблицу в памяти по валюте, и в общую таблицу в памяти больших сделок
// возвращает истину если сделка большая
function TCurrencies.AppendMemOper(Op: TOper; tbMemBigDeals: TABSTable; MinSum: Double): Boolean;
var
  P: TCurrencyCargo;
begin
  Result := false;
  try
    P := SetIfAbsent(Op.currency, Op.GetDexScreenerLink(false));
    Result := P.AppendMemOper(1, Op, tbMemBigDeals, MinSum);

    if Op.currency2 <> '' then begin
      P := SetIfAbsent(Op.currency2, Op.GetDexScreenerLink2(false));
      Result := P.AppendMemOper(2, Op, tbMemBigDeals, MinSum) or Result; // важно or в конце
    end;
  except
    on E: Exception do
      log('!AppendMemOper: ' + E.Message + ' ' + Op.hash);
  end;
end;

function TReturn.Deals: Integer;
begin
  Result := DealsBuy - DealsSell;
end;

procedure TReturn.Clear;
begin
  DealsBuy := 0;
  DealsSell := 0;
  VolumeBuy := 0;
  VolumeSell := 0;
end;

procedure TCurrencyCargo.GetReturns(Mins: Double; var AReturn: TReturn);
var
  Start, Finish: TDateTime;
  Volume: Double;
begin
  try
    AReturn.Clear;

    Finish := NowUTC;
    Start := Finish - Mins * OneMin;

    tbMem.IndexName := 'xDate';
    tbMem.SetRange([Start], [Finish]); // важен хронологический порядок
    tbMem.First;
    while not tbMem.Eof do begin
      Volume := tbMem.FieldByName('Amount').AsFloat; // * tbMem.FieldByName('Price').AsFloat;
      if tbMem.FieldByName('inout').AsBoolean then begin
        AReturn.DealsBuy := AReturn.DealsBuy + 1;
        AReturn.VolumeBuy := AReturn.VolumeBuy + Volume;
      end else begin
        AReturn.DealsSell := AReturn.DealsSell + 1;
        AReturn.VolumeSell := AReturn.VolumeSell + Volume;
      end;

      tbMem.Next;
    end;

    tbMem.CancelRange;
  except
    on E: Exception do
      log('! GetReturns: ' + E.Message + ' ' + name);
  end;
end;

procedure TCurrencies.ResetAllPlaces;
var
  P: TCurrencyCargo;
  I: Integer;
begin
  try
    for I := 0 to Currencies.Count - 1 do begin
      P := TCurrencyCargo(Currencies.Objects[I]);
      P.Tops[_added].Place := 0;
      P.Tops[_removed].Place := 0;
    end;
  except
    on E: Exception do
      log('! ResetAllPlaces: ' + E.Message);
  end;
end;

function TCurrencies.GetPlace(oAdded: TOperType; const ACurrency: string): Integer;
var
  P: TCurrencyCargo;
  I: Integer;
begin
  Result := 0;
  I := Currencies.IndexOf(ACurrency);
  if I = -1 then
    exit;
  try
    P := TCurrencyCargo(Currencies.Objects[I]);
    Result := P.Tops[oAdded].Place;
  except
    on E: Exception do
      log('! GetPlace: ' + E.Message);
  end;
end;

// возвращает обороты за последние Mins минут
procedure TCurrencies.GetReturns(const ACurrency: string; Mins: Double; var AReturn: TReturn);
var
  P: TCurrencyCargo;
  I: Integer;
begin
  AReturn.Clear;
  I := Currencies.IndexOf(ACurrency);
  if I = -1 then
    exit;

  try
    P := TCurrencyCargo(Currencies.Objects[I]);
    P.GetReturns(Mins, AReturn);
  except
    on E: Exception do
      log('! GetReturns: ' + E.Message);
  end;
end;

// оставляем топ валют, остальные неинтересны, большой расход памяти
// удаляем те, у которых меньше MinDeals сделок
procedure TCurrencies.Cleanup(MinDeals: Integer = 3);
var
  I: Integer;
  P: TCurrencyCargo;
begin
  if (Currencies.Count < 300) or (MinDeals > 6) { antiloop } then // ждем пока накопится какое-то число валют, до этого чистить рано
    exit;
  log('Cleanup ' + MinDeals.ToString + ': ' + Currencies.Count.ToString);
  I := 0;
  while I <= Currencies.Count - 1 do begin // t o d o - наверное не нужно
    P := TCurrencyCargo(Currencies.Objects[I]); // дадим шанс новым валютам, но если за последние 15 минут не было сделок - на выход
    if (P.tbMem.RecordCount < MinDeals) and ((P.LastDealTime > 0) or (Now - P.LastDealTime >= 15 * OneMin)) then begin
      Currencies.Delete(I);
    end else begin
      Inc(I);
    end;
  end;
  log(' -> ' + Currencies.Count.ToString);

  // если слишком много валют осталось - повторяем с более высоким порогом
  Cleanup(MinDeals + 1);
end;

constructor TCurrencyCargo.Create(const ACurrency, ALink: string);
begin
  inherited Create;

  name := ACurrency;
  DexLink := ALink;
  // Created := Now;
  Tops[_added].InTop := false;
  Tops[_added].NewInTop := false;
  Tops[_added].EnteredToTop := 0;
  Tops[_added].NeedSignal := false;
  Tops[_added].LastSignal := 0;
  Tops[_removed].InTop := false;
  Tops[_removed].NewInTop := false;
  Tops[_removed].EnteredToTop := 0;
  Tops[_removed].NeedSignal := false;
  Tops[_removed].LastSignal := 0;
  LastDealsBuy := 0;
  LastDealsSell := 0;
  LastVolumeBuy := 0;
  LastVolumeSell := 0;
  tbMem := NewAbsTableInMemory('T' + NormalizeCurrency(ACurrency));
  with tbMem do begin
    FieldDefs.Add('id', ftAutoInc, 0, false);
    // FieldDefs.Add('Currency', ftString, 30, False);
    // BWT(&#128118;⬜️&#128047;) 6 = бывают такие валюты со значками внутри
    FieldDefs.Add('hash', ftString, 80, false);
    FieldDefs.Add('inout', ftBoolean, 0, false);
    FieldDefs.Add('ADate', ftDateTime, 0, false);
    FieldDefs.Add('Amount', ftFloat, 0, false);
    // FieldDefs.Add('a1', ftString, 100, false);
    // FieldDefs.Add('a2', ftString, 100, false);

    IndexDefs.Add('xId', 'id', [ixPrimary]);
    IndexDefs.Add('xDate', 'adate', []);
    // ixUnique, ixCaseInsensitive, ixDescending

    CreateTable;
    Open;
    IndexName := 'xDate';
  end;
end;

destructor TCurrencyCargo.Destroy;
begin
  tbMem.Close;
  tbMem.DeleteTable;
  tbMem.Free;
  inherited;
end;

// помечает валюту как входящую в топ из nTop валют, на NewPlace-м месте
procedure TCurrencies.MarkAsTop(oAdded: TOperType; const ACurrency: string; NewPlace, nTop: Integer;
  ADeals: Integer; AVolume: Double);
var
  P: TCurrencyCargo;
  I: Integer;
begin
  I := Currencies.IndexOf(ACurrency);
  if I = -1 then // не бывает
    exit;

  try
    P := TCurrencyCargo(Currencies.Objects[I]);
    if (P = nil) or (NewPlace = 0) then // не бывает
      exit;

    if NewPlace <= nTop then begin // вошел в топ
      if not P.Tops[oAdded].InTop then begin // не было в топе до этого прохода
        P.Tops[oAdded].NewInTop := (P.Tops[oAdded].EnteredToTop = 0); // новая, вообще не была в топе ни разу
        P.Tops[oAdded].EnteredToTop := Now; // снова зашла в топ, время захода
        P.Tops[oAdded].NeedSignal := true; // отправить сигнал если будет подходящая сделка
      end;
      // в противном случае оставляем флажок NeedSignal как был
      P.Tops[oAdded].InTop := true;
    end
    else begin // валюта вышла из топа (или не была в нем)
      P.Tops[oAdded].InTop := false; // строку выше поднимать нельзя, нужно старое значение
      P.Tops[oAdded].NeedSignal := false;
    end;
    P.Tops[oAdded].Place := NewPlace;
    if oAdded = _added then begin
      P.LastDealsBuy := ADeals;
      P.LastVolumeBuy := AVolume;
    end
    else begin
      P.LastDealsSell := ADeals;
      P.LastVolumeSell := AVolume;
    end;
  except
    on E: Exception do
      log('! MarkAsTop: ' + E.Message);
  end;
end;

function TCurrencies.Get(const ACurrency: string): TCurrencyCargo;
var
  I: Integer;
begin
  Result := nil;
  I := Currencies.IndexOf(ACurrency);
  if I = -1 then
    exit;
  try
    Result := TCurrencyCargo(Currencies.Objects[I]);
  except
    on E: Exception do
      log('! TCurrencies.Get: ' + E.Message);
  end;
end;

end.
