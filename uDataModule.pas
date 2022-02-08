unit uDataModule;

interface

uses
  System.SysUtils, System.Classes, ABSMain, Data.DB;

type
  Tdm = class(TDataModule)
    tbMemBigDeals: TABSTable;
    tbMemBigDealsadate: TDateTimeField;
    tbMemBigDealshash: TStringField;
    tbMemBigDealsinout: TBooleanField;
    tbMemBigDealscurrency: TStringField;
    tbMemBigDealsamount: TFloatField;
    tbMemBigDealsTop: TIntegerField;
    tbMemBigDealsPlace2: TIntegerField;
    ABSDatabase1: TABSDatabase;
    tbDeals: TABSTable;
    tbMemReturns: TABSTable;
    tbMemReturnsCurrency: TStringField;
    tbMemReturnsDealsBuy: TIntegerField;
    tbMemReturnsDealsSell: TIntegerField;
    tbMemReturnsDeals: TIntegerField;
    tbMemReturnsVolumeBuy: TFloatField;
    tbMemReturnsVolumeSell: TFloatField;
    tbMemReturnsDexLink: TStringField;
    tbMemReturnsLastAddedTime: TDateTimeField;
    tbMemReturnsLastRemovedTime: TDateTimeField;
  private

  public
    function FindHash(const hash: string): Boolean;
  end;

var
  dm: Tdm;

implementation

{%CLASSGROUP 'Vcl.Controls.TControl'}

{$R *.dfm}

function Tdm.FindHash(const hash: string): Boolean;
begin
  tbDeals.IndexName := 'xHash'; // ищем хеш в базе
  Result := tbDeals.FindKey([Hash]);
end;

end.
