unit uProcess;

interface

uses
  SysUtils, StrUtils, uConst, uOper, AbsMain, sComboBox;

const
  template = '<b>{{Currency}}</b> - {{method}}' + CR +
    '{{#NewInTop}}Новая &#127381;' + CR + '{{/NewInTop}}' +
    '{{#LongInterval}}Сообщение после перерыва: {{BreakTime}}' + CR + '{{/LongInterval}}' +
    'Amount: <code>{{amount}}</code>' + CR +
    '{{#InTop}}Место: <code>{{Place}}</code> в топ-{{TopCnt}}, зашла в топ {{EnteredToTop}}' + CR + '{{/InTop}}' +
    'За период {{Period}} мин сделок / сумма: ' + CR +
    ' - added liq: <code>{{DealsBuy}}</code> / <code>{{VolumeBuy}}</code>' + CR +
    ' - removed liq: <code>{{DealsSell}}</code> / <code>{{VolumeSell}}</code>' + CR +
    '<a href="{{TokenUrl}}">Transaction Details</a>' + CR +
    '{{AppName}} - {{site}}';

  template2 = '<b>{{Currency}} - {{Currency2}} </b> - {{method}}' + CR +
    '{{#NewInTop}}Новая {{Currency}} &#127381;' + CR + '{{/NewInTop}}' +
    '{{#NewInTop2}}Новая {{Currency2}} &#127381;' + CR + '{{/NewInTop2}}' +
    '{{#LongInterval}}Сообщение после перерыва: {{BreakTime}}' + CR + '{{/LongInterval}}' +
    'Amount {{Currency}}: <code>{{amount}}</code>' + CR +
    'Amount {{Currency2}}: <code>{{amount2}}</code>' + CR +
    'Место {{Currency}}: <code>{{Place}}</code> в топ-{{TopCnt}}, зашла в топ {{EnteredToTop}}' + CR +
    'Место {{Currency2}}: <code>{{Place2}}</code> в топ-{{TopCnt}}, зашла в топ {{EnteredToTop2}}' + CR +
    'За период {{Period}} мин сделок / сумма: ' + CR +
    ' - added liq {{Currency}}: <code>{{DealsBuy}}</code> / <code>{{VolumeBuy}}</code>, {{Currency2}}: <code>{{DealsBuy2}}</code> / <code>{{VolumeBuy2}}</code>'
    + CR +
    ' - removed liq {{Currency}}: <code>{{DealsSell}}</code> / <code>{{VolumeSell}}</code>, {{Currency2}}: <code>{{DealsSell2}}</code> / <code>{{VolumeSell2}}</code>'
    + CR +
    '<a href="{{TokenUrl}}">Transaction Details</a>' + CR +
    '{{AppName}} - {{site}}';

procedure SendSignal(const Opers: TOpArray);
procedure UpdateReturns(tbMemReturns: TAbsTable);
procedure SetupPlaces(CurrencyComboBox: TsComboBox; tbMemBigDeals: TAbsTable);

implementation

uses
  dea.Tools, dea.debug, dea.cl, dea.TelegramHelper, System.Types, dea.Get,
  uAppParam, uCurrency, // uDataModule,
  SynCommons, SynMustache;

// http://www.delphikingdom.ru/asp/answer.asp?IDAnswer=68134
// исправление кодировки некоторых страниц
function FixStringCoding1251(const AData: string): string;
var
  S: RawByteString;
  X: Integer;
begin
  SetLength(S, Length(AData)); // выделили память под ANSI-буфер
  for X := 1 to Length(AData) do // переносим данные из вида 00A400B700E700D5 в A4B7E7D5
    S[X] := AnsiChar(AData[X]);
  SetCodePage(S, 1251, false); // пометим, что данные A4B7E7D5 имеют кодировку Win1251.
  // False указывает на то, что сами данные менять не надо -
  // мы просто указываем, в какой они кодировке
  Result := string(S); // здесь компилятор автоматически преобразует строку из ANSI/Win1251 в unicode
end;

// отправка сигнала - уст. - большие суммы, зашедшие в топ
// UPD просто большие суммы
// вызывается из ProcessOpers
procedure SendSignal(const Opers: TOpArray);
var
  I: Integer;
  P: TCurrencyCargo;
  P2: TCurrencyCargo;
  msg: string;
  LongInterval: Boolean;
  doc: variant;
  mustache: TSynMustache;
  oAdded: TOperType;
  TwoZero: Boolean;
begin
  for I := 0 to high(Opers) do begin
    TwoZero := (Opers[I].amount = 0) and (Opers[I].amount2 = 0);
    if not Opers[I].dupl and Opers[I].IsLiquid { and (Opers[I].amount <> 0) } then begin
      if not TwoZero and (Opers[I].amount < AppParam.MinSum) and (Opers[I].amount2 < AppParam.MinSum) then
        Continue;
      if (AppParam.SignalKind = TSignalKind.added) and not Opers[I].inout then
        Continue;
      if (AppParam.SignalKind = TSignalKind.removed) and Opers[I].inout then
        Continue;
      if (Opers[I].Currency2 = '') and (AppParam.ExcludedCurrencies.IndexOf(Opers[I].Currency) <> -1) then
        Continue; // в списке исключений
      if AppParam.ExcludedCurrencies.IndexOf(Opers[I].Currency + ';' + Opers[I].Currency2) <> -1 then
        Continue;
      if AppParam.ExcludedCurrencies.IndexOf(Opers[I].Currency2 + ';' + Opers[I].Currency) <> -1 then
        Continue;
      if AppParam.ExcludedCurrencies.IndexOf(Opers[I].Currency + ' - ' + Opers[I].Currency2) <> -1 then
        Continue;
      if AppParam.ExcludedCurrencies.IndexOf(Opers[I].Currency2 + ' - ' + Opers[I].Currency) <> -1 then
        Continue;

      P := Currencies.Get(Opers[I].Currency); // не может быть nil
      if Opers[I].Currency2 = '' then
        P2 := nil
      else
        P2 := Currencies.Get(Opers[I].Currency2);

      if true { P.NeedSignal } then begin // сигнал еще не отправлялся и был заход в топ - сказал отправлять все суммы выше пороговой
        if Opers[I].inout then
          oAdded := _added
        else
          oAdded := _removed;
        LongInterval := (P.Tops[oAdded].LastSignal <> 0) and (Now - P.Tops[oAdded].LastSignal >= AppParam.IntervalMins * OneMin);

        TDocVariant.New(doc); // инициализация переменной doc

        doc.method := Opers[I].method;
        doc.Currency := Opers[I].Currency;
        doc.amount := ff(Opers[I].amount);
        doc.NewInTop := P.Tops[oAdded].NewInTop;
        doc.LongInterval := LongInterval;
        doc.BreakTime := TimeToStr(Now - P.Tops[oAdded].LastSignal);
        doc.Place := P.Tops[oAdded].Place;
        doc.TopCnt := AppParam.TopCnt;
        doc.EnteredToTop := TimeToStr(P.Tops[oAdded].EnteredToTop);
        doc.Period := AppParam.Period;
        doc.DealsBuy := P.LastDealsBuy;
        doc.DealsSell := P.LastDealsSell;
        doc.VolumeBuy := P.LastVolumeBuy;
        doc.VolumeSell := P.LastVolumeSell;
        doc.TokenUrl := AppParam.GetTokenUrl(P.LastHash);
        doc.InTop := P.Tops[oAdded].NeedSignal; // выводить информацию по месту в топе
        doc.AppName := AppParam.AppName;
        doc.Site := AppParam.SiteCaption;
        if P2 = nil then
          mustache := TSynMustache.Parse(template)
        else begin
          doc.Currency2 := Opers[I].Currency2;
          doc.amount2 := ff(Opers[I].amount2);
          doc.Place2 := P2.Tops[oAdded].Place;
          doc.NewInTop2 := P2.Tops[oAdded].NewInTop;
          doc.EnteredToTop2 := TimeToStr(P2.Tops[oAdded].EnteredToTop);
          doc.BreakTime2 := TimeToStr(Now - P2.Tops[oAdded].LastSignal);
          doc.InTop2 := P2.Tops[oAdded].NeedSignal; // выводить информацию по месту в топе
          doc.DealsBuy2 := P2.LastDealsBuy;
          doc.DealsSell2 := P2.LastDealsSell;
          doc.VolumeBuy2 := P2.LastVolumeBuy;
          doc.VolumeSell2 := P2.LastVolumeSell;
          mustache := TSynMustache.Parse(template2);
        end;

        msg := UTF8ToString(mustache.Render(doc));

        SendToTelegramHelper(msg, Iif(TwoZero, AppParam.Channel2, AppParam.Channel));

        if AppParam.Channel <> AppParam.Channel2 then begin
          if P.Tops[oAdded].NewInTop or LongInterval then // новые повторить во второй канал, или между сигналами прошло больше ... минут
            SendToTelegramHelper(msg, AppParam.Channel2);
        end;

        P.Tops[oAdded].NeedSignal := false;
        P.Tops[oAdded].LastSignal := Now;
        if P2 <> nil then begin
          P2.Tops[oAdded].NeedSignal := false;
          P2.Tops[oAdded].LastSignal := Now;
        end;
      end;
    end;
  end;
end;

// перерасчет оборотов по каждой валюте в Currencies за указанное число минут - пишет в tbMemReturns
// затем проставляет признаки в Currencies, место не проставляет - еще неизвестны обороты по всем валютам
// вызывается из DoWork
procedure UpdateReturns(tbMemReturns{, tbMemReturns2}: TAbsTable);
var
  I, NewPlace: Integer;
  cur: string;
  P: TCurrencyCargo;
  Return: TReturn;
begin
  // считаем обороты по каждой валюте и заполняем таблицу в памяти для отображения
//  tbMemReturns.DisableControls;
//  tbMemReturns2.DisableControls;
//  try
    tbMemReturns.Close;
    tbMemReturns.EmptyTable;

    tbMemReturns.Open;
    for I := 0 to Currencies.Currencies.Count - 1 do begin
      cur := Currencies.Currencies[I];
      P :=  TCurrencyCargo(Currencies.Currencies.Objects[I]);
      Currencies.GetReturns(cur, AppParam.Period, Return);

      tbMemReturns.Append;
      tbMemReturns.FieldByName('Currency').AsString := cur;
      tbMemReturns.FieldByName('DealsBuy').AsInteger := Return.DealsBuy;
      tbMemReturns.FieldByName('DealsSell').AsInteger := Return.DealsSell;
      tbMemReturns.FieldByName('Deals').AsInteger := Return.Deals;
      tbMemReturns.FieldByName('VolumeBuy').AsFloat := Return.VolumeBuy;
      tbMemReturns.FieldByName('VolumeSell').AsFloat := Return.VolumeSell;
      tbMemReturns.FieldByName('DexLink').AsString := P.DexLink;
      tbMemReturns.FieldByName('LastAddedTime').AsDateTime := P.LastAddedTime;
      tbMemReturns.FieldByName('LastRemovedTime').AsDateTime := P.LastRemovedTime;

      tbMemReturns.Post;
    end;

    // определяем топ - по количеству сделок добавления ликвидности
    Currencies.ResetAllPlaces; // =0

    tbMemReturns.IndexName := 'xDealsBuy';
    tbMemReturns.First;
    for NewPlace := 1 to { nTop } 200 do begin // учитываем первые сотни валют, для скорости отсекаем лузеров
      if tbMemReturns.Eof or (tbMemReturns.FieldByName('DealsBuy').AsInteger = 0) then
        Break;
      Currencies.MarkAsTop( // выставляет признаки InTop
        _added,
        tbMemReturns.FieldByName('Currency').AsString, NewPlace, AppParam.TopCnt,
        tbMemReturns.FieldByName('DealsBuy').AsInteger,
        tbMemReturns.FieldByName('VolumeBuy').AsFloat);
      tbMemReturns.Next;
    end;

    tbMemReturns{2}.IndexName := 'xDealsSell';
    tbMemReturns.First;
    for NewPlace := 1 to { nTop } 200 do begin // учитываем первые сотни валют, для скорости отсекаем лузеров
      if tbMemReturns.Eof or (tbMemReturns.FieldByName('DealsSell').AsInteger = 0) then
        Break;
      Currencies.MarkAsTop( // выставляет признаки InTop
        _removed,
        tbMemReturns.FieldByName('Currency').AsString, NewPlace, AppParam.TopCnt,
        tbMemReturns.FieldByName('DealsSell').AsInteger,
        tbMemReturns.FieldByName('VolumeSell').AsFloat);
      tbMemReturns.Next;
    end;
//  finally
//    tbMemReturns.First;
//    tbMemReturns.EnableControls;
//    tbMemReturns2.Refresh;
//    tbMemReturns2.First;
//    tbMemReturns2.EnableControls;
//  end;
end;

// прописывает валютам в списке валют места в топе и число сделок, на основании tbMemReturn
// затем прописывает места в таблице больших сделок, уже на основании списка валют для скорости
// заодно заполняет комбобокс с валютами (дописывает новые валюты)
// вызывается из ProcessOpers
procedure SetupPlaces(CurrencyComboBox: TsComboBox; tbMemBigDeals: TAbsTable);
var
  I: Integer;
  cur: string;
begin
  // tbMemBigDeals.DisableControls; - в вызывающей процедуре
  CurrencyComboBox.Items.BeginUpdate;
  try
    tbMemBigDeals.IndexName := 'xDateRev';
    tbMemBigDeals.First; // только последние по времени большие сделки
    for I := 1 to 500 do begin
      if tbMemBigDeals.Eof then
        Break;
      cur := tbMemBigDeals.FieldByName('Currency').AsString;
      tbMemBigDeals.Edit;
      tbMemBigDeals.FieldByName('Place').AsInteger := Currencies.GetPlace(_added, cur);
      tbMemBigDeals.FieldByName('Place2').AsInteger := Currencies.GetPlace(_removed, cur);
      tbMemBigDeals.Post;

      if CurrencyComboBox.Items.IndexOf(cur) = -1 then
        CurrencyComboBox.Items.Add(cur);

      tbMemBigDeals.Next;
    end;
  finally
    CurrencyComboBox.Items.EndUpdate;
    // tbMemBigDeals.EnableControls; - в вызывающей процедуре
  end;
end;

end.
