unit uProcess;

interface

uses
  SysUtils, StrUtils, uConst, uOper, AbsMain, sComboBox;

const
  template = '<b>{{Currency}}</b> - {{method}}' + CR +
    '{{#NewInTop}}����� &#127381;' + CR + '{{/NewInTop}}' +
    '{{#LongInterval}}��������� ����� ��������: {{BreakTime}}' + CR + '{{/LongInterval}}' +
    'Amount: <code>{{amount}}</code>' + CR +
    '{{#InTop}}�����: <code>{{Place}}</code> � ���-{{TopCnt}}, ����� � ��� {{EnteredToTop}}' + CR + '{{/InTop}}' +
    '�� ������ {{Period}} ��� ������ / �����: ' + CR +
    ' - added liq: <code>{{DealsBuy}}</code> / <code>{{VolumeBuy}}</code>' + CR +
    ' - removed liq: <code>{{DealsSell}}</code> / <code>{{VolumeSell}}</code>' + CR +
    '<a href="{{TokenUrl}}">Transaction Details</a>' + CR +
    '{{AppName}} - {{site}}';

  template2 = '<b>{{Currency}} - {{Currency2}} </b> - {{method}}' + CR +
    '{{#NewInTop}}����� {{Currency}} &#127381;' + CR + '{{/NewInTop}}' +
    '{{#NewInTop2}}����� {{Currency2}} &#127381;' + CR + '{{/NewInTop2}}' +
    '{{#LongInterval}}��������� ����� ��������: {{BreakTime}}' + CR + '{{/LongInterval}}' +
    'Amount {{Currency}}: <code>{{amount}}</code>' + CR +
    'Amount {{Currency2}}: <code>{{amount2}}</code>' + CR +
    '����� {{Currency}}: <code>{{Place}}</code> � ���-{{TopCnt}}, ����� � ��� {{EnteredToTop}}' + CR +
    '����� {{Currency2}}: <code>{{Place2}}</code> � ���-{{TopCnt}}, ����� � ��� {{EnteredToTop2}}' + CR +
    '�� ������ {{Period}} ��� ������ / �����: ' + CR +
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
// ����������� ��������� ��������� �������
function FixStringCoding1251(const AData: string): string;
var
  S: RawByteString;
  X: Integer;
begin
  SetLength(S, Length(AData)); // �������� ������ ��� ANSI-�����
  for X := 1 to Length(AData) do // ��������� ������ �� ���� 00A400B700E700D5 � A4B7E7D5
    S[X] := AnsiChar(AData[X]);
  SetCodePage(S, 1251, false); // �������, ��� ������ A4B7E7D5 ����� ��������� Win1251.
  // False ��������� �� ��, ��� ���� ������ ������ �� ���� -
  // �� ������ ���������, � ����� ��� ���������
  Result := string(S); // ����� ���������� ������������� ����������� ������ �� ANSI/Win1251 � unicode
end;

// �������� ������� - ���. - ������� �����, �������� � ���
// UPD ������ ������� �����
// ���������� �� ProcessOpers
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
        Continue; // � ������ ����������
      if AppParam.ExcludedCurrencies.IndexOf(Opers[I].Currency + ';' + Opers[I].Currency2) <> -1 then
        Continue;
      if AppParam.ExcludedCurrencies.IndexOf(Opers[I].Currency2 + ';' + Opers[I].Currency) <> -1 then
        Continue;
      if AppParam.ExcludedCurrencies.IndexOf(Opers[I].Currency + ' - ' + Opers[I].Currency2) <> -1 then
        Continue;
      if AppParam.ExcludedCurrencies.IndexOf(Opers[I].Currency2 + ' - ' + Opers[I].Currency) <> -1 then
        Continue;

      P := Currencies.Get(Opers[I].Currency); // �� ����� ���� nil
      if Opers[I].Currency2 = '' then
        P2 := nil
      else
        P2 := Currencies.Get(Opers[I].Currency2);

      if true { P.NeedSignal } then begin // ������ ��� �� ����������� � ��� ����� � ��� - ������ ���������� ��� ����� ���� ���������
        if Opers[I].inout then
          oAdded := _added
        else
          oAdded := _removed;
        LongInterval := (P.Tops[oAdded].LastSignal <> 0) and (Now - P.Tops[oAdded].LastSignal >= AppParam.IntervalMins * OneMin);

        TDocVariant.New(doc); // ������������� ���������� doc

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
        doc.InTop := P.Tops[oAdded].NeedSignal; // �������� ���������� �� ����� � ����
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
          doc.InTop2 := P2.Tops[oAdded].NeedSignal; // �������� ���������� �� ����� � ����
          doc.DealsBuy2 := P2.LastDealsBuy;
          doc.DealsSell2 := P2.LastDealsSell;
          doc.VolumeBuy2 := P2.LastVolumeBuy;
          doc.VolumeSell2 := P2.LastVolumeSell;
          mustache := TSynMustache.Parse(template2);
        end;

        msg := UTF8ToString(mustache.Render(doc));

        SendToTelegramHelper(msg, Iif(TwoZero, AppParam.Channel2, AppParam.Channel));

        if AppParam.Channel <> AppParam.Channel2 then begin
          if P.Tops[oAdded].NewInTop or LongInterval then // ����� ��������� �� ������ �����, ��� ����� ��������� ������ ������ ... �����
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

// ���������� �������� �� ������ ������ � Currencies �� ��������� ����� ����� - ����� � tbMemReturns
// ����� ����������� �������� � Currencies, ����� �� ����������� - ��� ���������� ������� �� ���� �������
// ���������� �� DoWork
procedure UpdateReturns(tbMemReturns{, tbMemReturns2}: TAbsTable);
var
  I, NewPlace: Integer;
  cur: string;
  P: TCurrencyCargo;
  Return: TReturn;
begin
  // ������� ������� �� ������ ������ � ��������� ������� � ������ ��� �����������
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

    // ���������� ��� - �� ���������� ������ ���������� �����������
    Currencies.ResetAllPlaces; // =0

    tbMemReturns.IndexName := 'xDealsBuy';
    tbMemReturns.First;
    for NewPlace := 1 to { nTop } 200 do begin // ��������� ������ ����� �����, ��� �������� �������� �������
      if tbMemReturns.Eof or (tbMemReturns.FieldByName('DealsBuy').AsInteger = 0) then
        Break;
      Currencies.MarkAsTop( // ���������� �������� InTop
        _added,
        tbMemReturns.FieldByName('Currency').AsString, NewPlace, AppParam.TopCnt,
        tbMemReturns.FieldByName('DealsBuy').AsInteger,
        tbMemReturns.FieldByName('VolumeBuy').AsFloat);
      tbMemReturns.Next;
    end;

    tbMemReturns{2}.IndexName := 'xDealsSell';
    tbMemReturns.First;
    for NewPlace := 1 to { nTop } 200 do begin // ��������� ������ ����� �����, ��� �������� �������� �������
      if tbMemReturns.Eof or (tbMemReturns.FieldByName('DealsSell').AsInteger = 0) then
        Break;
      Currencies.MarkAsTop( // ���������� �������� InTop
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

// ����������� ������� � ������ ����� ����� � ���� � ����� ������, �� ��������� tbMemReturn
// ����� ����������� ����� � ������� ������� ������, ��� �� ��������� ������ ����� ��� ��������
// ������ ��������� ��������� � �������� (���������� ����� ������)
// ���������� �� ProcessOpers
procedure SetupPlaces(CurrencyComboBox: TsComboBox; tbMemBigDeals: TAbsTable);
var
  I: Integer;
  cur: string;
begin
  // tbMemBigDeals.DisableControls; - � ���������� ���������
  CurrencyComboBox.Items.BeginUpdate;
  try
    tbMemBigDeals.IndexName := 'xDateRev';
    tbMemBigDeals.First; // ������ ��������� �� ������� ������� ������
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
    // tbMemBigDeals.EnableControls; - � ���������� ���������
  end;
end;

end.
