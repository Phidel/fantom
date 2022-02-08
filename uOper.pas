unit uOper;
// операция и массив операций текущего прохода.
// Каждый хеш в массиве только один раз. Повторные операции по хешу высталяют признак dupl
// поиск заданного хеша в массиве

interface

uses
  AbsMain, SysUtils, StrUtils, DateUtils, dea.tools;

type
  TOper = record
  private
    procedure GetInfoPageAndParse;
    procedure GetTransactionPageAndParse;
    procedure GetParseTransactionPageAvax;
  public
    inout: Boolean; // добавление/удаление ликвидности
    adate: TDateTime;
    hash: string;
    method: string;
    // addr1, addr2: string;
    currency: string; { название валюты }
    currencyAddress: string; { хеш валюты /token/0x7... }
    amount: double; // Сумма на основной странице списка транзакций, м.б.= 0, здесь цена не нужна
    // но для авакса берется сумма из списка операций
    currency2: string; { для авакса две валюты }
    currencyAddress2: string;
    amount2: double;
    dupl: Boolean;
    error: Boolean;

    function LogLine: string;
    function IsLiquid: Boolean;
    procedure AppendLine(tbDeals: TABSTable);
    // function Find(tbDeals: TABSTable): Boolean;
    procedure ParseRow(const Cells: TRowsArray); // парсинг одной строки первого адреса
    procedure ParseStep2; // допарсим сумму и другие параметры из страницы транзакции (если надо)
    function GetDexScreenerLink(htmlTags: Boolean = true): string; // ссылка на страницу валюты на https://dexscreener.com
    function GetDexScreenerLink2(htmlTags: Boolean = true): string;
  end;

  TOpArray = array of TOper; // массив операций текущего прохода

function FindHashAndMarkAsDupl(const Ahash: string; const Opers: TOpArray): Boolean;
procedure LogOpers(const Opers: TOpArray);

implementation

uses
  uConst, dea.get, uAppParam, System.Classes;

procedure DeleteByIndex(var A: TRowsArray; const Index: Cardinal);
var
  ALength: Cardinal;
  i: Cardinal;
begin
  ALength := Length(A);
  if (index >= ALength) or (ALength = 0) then
    exit;
  for i := index + 1 to ALength - 1 do
    A[i - 1] := A[i];
  SetLength(A, ALength - 1);
end;

function TOper.LogLine: string;
begin
  Result := hash + #9 +
    DateTimeToStr(adate) + #9 +
    ifthen(dupl, '*', ' ') + #9 +
    ifthen(inout, 'Added liq.', 'Removed lid.') + #9 +
    PadR(currency, 12) + #9 +
    currencyAddress + #9 +
    amount.ToString + #9 +
    PadR(currency2, 12) + #9 +
    currencyAddress2 + #9 +
    amount2.ToString;
end;

const
  MAX_RECORDS = 30000;

procedure TOper.AppendLine(tbDeals: TABSTable);
begin // сейчас интересует только хеш, остальные поля в базе не используются
  if tbDeals.RecordCount <= MAX_RECORDS then
    tbDeals.Append
  else begin
    tbDeals.IndexName := 'xDate';
    tbDeals.First; // затираем самую первую
    tbDeals.Edit;
  end;

  tbDeals.FieldByName('created').AsDateTime := NowUTC;
  tbDeals.FieldByName('adate').AsDateTime := adate;
  tbDeals.FieldByName('hash').AsString := hash;
  tbDeals.FieldByName('currency').AsString := currency;
  // currencyAddress в базе не храню (пока не нужен)

  tbDeals.FieldByName('inout').AsBoolean := inout;
  tbDeals.FieldByName('amount').AsFloat := amount;
  tbDeals.Post;
end;

// ищет такую же операцию в базе, возвращает истину, если нашел
(*
  function TOper.Find(tbDeals: TABSTable): Boolean;
  begin
  Result := False;
  tbDeals.IndexName := 'xHash';
  tbDeals.SetRange([hash], [hash]);
  tbDeals.First;
  while not tbDeals.Eof do begin
  if (tbDeals.FieldByName('inout').AsBoolean = inout) and
  (tbDeals.FieldByName('amount').AsFloat = amount) and
  (tbDeals.FieldByName('adate').AsDateTime = adate) and
  (tbDeals.FieldByName('hash').AsString = hash)
  then begin // строки полностью совпали
  Result := true;
  break;
  end;
  tbDeals.Next;
  end;
  tbDeals.CancelRange;
  end; *)

function TOper.IsLiquid: Boolean;
begin
  Result := StartsStr('Add Liquidity', method)
    or StartsStr('Remove Liquidity', method)
end;

// на входе Cells - ячейки одной строки
procedure TOper.ParseRow(const Cells: TRowsArray);
var
  link, st: string;
begin
  // 0 - кнопка с вопросиком
  // 1 - hash <a href='/tx/0x5b8ef...' class. Здесь же бывает воскл. знак разных цветов : fa-exclamation-circle - status fail or reverted
  // 2 - method - <td><span ... title="" data-original-title="Add Liquidity ETH">Add Liquidity ET...</span></td>
  // - - - - -или <td><span ... title="" data-original-title="Remove Liquidity ETH With Permit">Remove Liquidity...</span></td>
  // 3 - block
  // 4 - age - <span ... title='6 secs ago'>2022-01-18 22:45:43</span></td>
  // 5 - age - title='2022-01-18 22:45:43'>6 secs ago</span></td>
  // 6 - from - <a href='/address/0x20f15...'>0x20f15...</a></span>
  // 7 - стрелка - rounded-circle
  // 8 - to - <span ...><i class="far ..." data-toggle='tooltip'
  // title='Contract'></i> <a class='hash...' href='/address/0x163...' data-toggle='tooltip'
  // title='SpiritSwap: Router&#10;(0x163...)'>SpiritSwap: Router</a>
  // вариант: <span class="hash..." data-toggle="tooltip" title=""
  // data-original-title="0xfc80..."><a href="/address/0xfc80...">0xfc80...</a></span>
  // 9 - value - <td>0 FTM</td> или <td>99<b>.</b><span class='text-secondary'>99</span> FTM</td>
  // вариант <td>7<b>.</b><span class="text-secondary">241505634981155</span> FTM</td>
  // 10 - fee

  dupl := False;
  error := Pos('fa-exclamation-circle', Cells[1]) > 0;

  st := reprep(Cells[4], '<span*>', '</span>'); // UTC date-time
  adate := StrYYYY_MM_DDToDateTime(st); // дата

  st := trim(HTMLStrip(StrAfterPos('>', Cells[9])));
  if Pos(' ', st) > 0 then // в конце название валюты сайта, например, для фантома FTM
    st := StrBeforeLastPos(' ', st);
  amount := StrToFloatDef(st, 0);

  link := reprep(Cells[1], 'href=''', ''''); // /tx/0x4833063e8170eb19003b30dea52d60df693d59a441f1
  hash := StripFirstStr(link, '/tx/0x'); // в начале каждого хеша 0x - в базе не храню

  method := trim(reprep(Cells[2], 'original-title="', '"'));
  if method = '' then
    method := trim(reprep(Cells[2], 'title="', '"'));
  if method = '' then
    log('!!! method - empty'); // todo

  inout := StartsStr('Add Liquidity', method);

  // addr1 := reprep(Cells[6], 'href=''', ''''); не нужно
  // addr2 := reprep(Cells[8], 'href=''', '''');
end;

procedure TOper.ParseStep2; // допарсим сумму и другие параметры из страницы транзакции (если надо)
begin
  if error or not IsLiquid then
    exit;
//  if AppParam.Site = S_FANTOM then
//    if inout then
//      GetInfoPageAndParse
//    else
//      GetTransactionPageAndParse
//  else
//    if AppParam.Site = S_AVAX then
    GetParseTransactionPageAvax;
end;

// парсит страничку, которая открывается по клику на вопросик слева от строки строки транзакции
// определяет currency и currencyAddress
// из первой строки из всех операций
procedure TOper.GetInfoPageAndParse;
var
  link, st, s: string;
  nPos: Integer;
begin
  currency := '';
  currencyAddress := '';
  if error or (amount = 0) or not IsLiquid then
    exit;

  link := AppParam.GetShortTokenUrl(hash);
  try
    AppParam.DoSleep;
    st := xget(link);
  except
    on E: Exception do begin
      log('!xget GetCurrencyAndParse ' + hash + ' ' + E.Message);
      Sleep(200);
      exit;
    end;
  end;

  nPos := Pos('Token Transfer:', st);
  s := reprep(st, '<div class=''d-flex''><', '<div class=''d-flex''', nPos); // первая строка из всех операций
  if s <> '' then begin // ...href='/token/0x7a6e4e3cc2ac9924605dca4ba31d1831c84b44ae'>2OMB</a>
    currencyAddress := reprep(s, 'href=''', '''');
    currency := trim(HTMLStrip(reprep(s, 'href=*>', '</a')));
    if EndsStr('...', currency) and (reprep(s, 'data-toggle=''tooltip'' title=''', '''') <> '') then begin
      currency := reprep(s, 'data-toggle=''tooltip'' title=''', '''')
    end;
  end;

  if currency = '' then
    log('!!! currency - empty ' + hash); // todo
end;

// парсит страницу транзакции, нужно только для убирания ликвидности
// определяет currency, currencyAddress и
// amount - сумму берем из последней строки
procedure TOper.GetTransactionPageAndParse;
var
  link, st, s, tmp: string;
  List: TStringList;
  nPos, Len: Integer;
  samount: string;
begin
  currency := '';
  currencyAddress := '';
  amount := 0; // сумму берем из последней строки
  if error or not IsLiquid then
    exit;

  link := AppParam.GetTokenUrl(hash);
  try
    AppParam.DoSleep;
    st := xget(link);
  except
    on E: Exception do begin
      log('!xget GetTransactionPageAndParse ' + hash + ' ' + E.Message);
      Sleep(200);
      exit;
    end;
  end;

  nPos := Pos('Tokens Transferred:', st);

  s := reprep(st, '<ul ', '</ul>', nPos); // последняя строка из всех операций
  List := TStringList.Create;
  ReprepList(s, '<li', '</li', List);
  Len := List.Count;

  if Len > 1 then begin
    currencyAddress := reprepLast(List[Len - 2], 'href=''', ''''); // предпоследняя ссылка из трех
    currency := trim(HTMLStrip(reprepLast(List[Len - 2], 'href=*>', '</a>')));
    if (currency = '') or (StartsStr('0x', currency)) then begin
      currency := trim(HTMLStrip(reprepLast(List[Len - 2], 'title=''', '''')));
    end;
    tmp := reprep(currency, '(', ')');
    if tmp <> '' then
      if not EndsStr('...', tmp) then
        currency := tmp
      else
        currency := trim(StrBeforePos('(', currency));
    // data-original-title="Current Price : $2.28 / WFTM">76.928591914670303152 ($175.40)</span>
    samount := reprep(List[Len - 1], '<b>For</b>*Current Price :', '</span');
    amount := reprepFloat(samount, '>', '(');
    if amount = 0 then
      amount := reprepFloat(samount, '>', '<');
  end;
  if currency = '' then
    log('!!! currency 2 - empty ' + hash); // todo
  List.Free;
end;

// парсит страницу транзакции для Avax
// определяет две валюты currency, currencyAddress и amount
procedure TOper.GetParseTransactionPageAvax;
var
  link, st, s, tmp: string;
  List: TStringList;
  nPos, i, flag: Integer;
  samount: string;
  function parseCurrency(const s: string; var currency, currencyAddress: string): Boolean;
  begin
    currencyAddress := reprepLast(List[i], 'href=''', ''''); // предпоследняя ссылка из трех
    currency := trim(HTMLStrip(reprepLast(List[i], 'href=*>', '</a>')));
    if (currency = '') or (StartsStr('0x', currency)) then begin
      currency := trim(HTMLStrip(reprepLast(List[i], 'title=''', '''')));
    end;
    tmp := reprep(currency, '(', ')');
    if tmp <> '' then
      if not EndsStr('...', tmp) then
        currency := tmp
      else
        currency := trim(StrBeforePos('(', currency));
    Result := (currency <> 'JLP') and (currency <> 'PGL') and
      (currency <> 'Lydia LPs');
  end;
  function parseAmount(const s: string; var amount: double): Boolean;
  begin
    // data-original-title="Current Price : $2.28 / WFTM">76.928591914670303152 ($175.40)</span>
    samount := reprep(List[i], '<b>For</b>*Current Price :', '</span');
    tmp := ReplaceStr(reprep(samount, '($', ')'), ',', '');
    amount := iStrToFloat(tmp);
    Result := amount <> 0;
  end;

begin
  currency := '';
  currencyAddress := '';
  amount := 0;
  currency2 := '';
  currencyAddress2 := '';
  amount2 := 0;
  if error or not IsLiquid then
    exit;

  link := AppParam.GetTokenUrl(hash);
  try
    AppParam.DoSleep;
    st := xget(link);
  except
    on E: Exception do begin
      log('!xget GetParseTransactionPageAvax ' + hash + ' ' + E.Message);
      Sleep(200);
      exit;
    end;
  end;

  nPos := Pos('Tokens Transferred:', st);

  s := reprep(st, '<ul ', '</ul>', nPos);
  List := TStringList.Create;
  ReprepList(s, '<li', '</li', List);

  flag := 0;
  for i := 0 to List.Count - 1 do begin
    if flag = 0 then begin
      if parseCurrency(List[i], currency, currencyAddress) then begin // парсим валюту
        parseAmount(List[i], amount); // парсим сумму
        flag := 1;
      end
    end
    else begin
      if parseCurrency(List[i], currency2, currencyAddress2) and (currency2 <> currency)
      then begin // парсим вторую валюту, дубли пропускаем
        parseAmount(List[i], amount2); // парсим сумму
        break; // должно быть только две разные валюты
      end;
    end;
  end;

  if (amount = 0) and (amount2 <> 0) then
    amount := amount2
  else
    if (amount2 = 0) and (amount <> 0) then
    amount2 := amount;

  if currency = '' then
    log('!!! currency 3 - empty ' + hash);
  List.Free;
end;

// ищет хеш в массиве, возвращает истину, если находит
// выставляет признак dupl в истину, если находит
// при добавлении хеша делается проверка на уникальность, поэтому хеш может быть в массиве только один раз
function FindHashAndMarkAsDupl(const Ahash: string; const Opers: TOpArray): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to high(Opers) do begin
    if Opers[i].hash = Ahash then begin
      Opers[i].dupl := true;
      Result := true;
      exit; // ничего добавлять не надо, повторная операция по хешу
    end;
  end;
end;

procedure LogOpers(const Opers: TOpArray);
var
  i: Integer;
begin
  for i := 0 to high(Opers) do begin
    log(Opers[i].LogLine);
  end;
end;

function TOper.GetDexScreenerLink(htmlTags: Boolean = true): string;
begin
  if currencyAddress = '' then // /token/0x7...
    Result := ''
  else begin
    Result := AppParam.GetDexUrl + StrAfterPos('/token/', currencyAddress);
    if htmlTags then
      Result := '<a href="' + Result + '">dexscreener.com</a>';
  end;
end;

function TOper.GetDexScreenerLink2(htmlTags: Boolean = true): string;
begin
  if currencyAddress2 = '' then // /token/0x7...
    Result := ''
  else begin
    Result := AppParam.GetDexUrl + StrAfterPos('/token/', currencyAddress2);
    if htmlTags then
      Result := '<a href="' + Result + '">dexscreener.com</a>';
  end;
end;

end.
