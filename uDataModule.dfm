object dm: Tdm
  OldCreateOrder = False
  Height = 203
  Width = 390
  object tbMemBigDeals: TABSTable
    CurrentVersion = '7.90 '
    DatabaseName = 'MEMORY'
    InMemory = True
    ReadOnly = False
    StoreDefs = True
    IndexDefs = <
      item
        Name = 'xDateRev'
        DescFields = 'adate'
        Fields = 'adate'
        Options = [ixDescending]
      end>
    TableName = 'MemBigDeals'
    Exclusive = False
    Left = 40
    Top = 40
    object tbMemBigDealsadate: TDateTimeField
      FieldName = 'adate'
    end
    object tbMemBigDealshash: TStringField
      FieldName = 'hash'
      Size = 84
    end
    object tbMemBigDealsinout: TBooleanField
      FieldName = 'inout'
    end
    object tbMemBigDealscurrency: TStringField
      FieldName = 'currency'
      Size = 32
    end
    object tbMemBigDealsamount: TFloatField
      FieldName = 'amount'
    end
    object tbMemBigDealsTop: TIntegerField
      FieldName = 'Place'
    end
    object tbMemBigDealsPlace2: TIntegerField
      FieldName = 'Place2'
    end
  end
  object ABSDatabase1: TABSDatabase
    CurrentVersion = '7.90 '
    DatabaseName = 'db_main'
    Exclusive = False
    Password = '123'
    MaxConnections = 400
    MultiUser = True
    SessionName = 'Default'
    Left = 153
    Top = 38
  end
  object tbDeals: TABSTable
    CurrentVersion = '7.90 '
    DatabaseName = 'db_main'
    InMemory = False
    ReadOnly = False
    TableName = 'Deals'
    Exclusive = False
    Left = 113
    Top = 128
  end
  object tbMemReturns: TABSTable
    CurrentVersion = '7.90 '
    DatabaseName = 'MEMORY'
    InMemory = True
    ReadOnly = False
    StoreDefs = True
    IndexDefs = <
      item
        Name = 'xCurrency'
        Fields = 'Currency'
      end
      item
        Name = 'xDeals'
        DescFields = 'Deals'
        Fields = 'Deals;Currency'
        Options = [ixDescending]
      end
      item
        Name = 'xDealsBuy'
        DescFields = 'DealsBuy;VolumeBuy'
        Fields = 'DealsBuy;VolumeBuy'
        Options = [ixDescending]
      end
      item
        Name = 'xDealsSell'
        DescFields = 'DealsSell;VolumeSell'
        Fields = 'DealsSell;VolumeSell'
        Options = [ixDescending]
      end
      item
        Name = 'xVolumeBuy'
        DescFields = 'VolumeBuy'
        Fields = 'VolumeBuy'
        Options = [ixDescending]
      end
      item
        Name = 'xVolumeSell'
        DescFields = 'VolumeSell'
        Fields = 'VolumeSell'
        Options = [ixDescending]
      end
      item
        Name = 'xLastAddedTime'
        DescFields = 'LastAddedTime;VolumeBuy'
        Fields = 'LastAddedTime;VolumeBuy'
        Options = [ixDescending]
      end
      item
        Name = 'xLastRemovedTime'
        DescFields = 'LastRemovedTime;VolumeSell'
        Fields = 'LastRemovedTime;VolumeSell'
        Options = [ixDescending]
      end>
    FieldDefs = <
      item
        Name = 'Currency'
        DataType = ftString
        Size = 32
      end
      item
        Name = 'DealsBuy'
        DataType = ftInteger
      end
      item
        Name = 'DealsSell'
        DataType = ftInteger
      end
      item
        Name = 'Deals'
        DataType = ftInteger
      end
      item
        Name = 'VolumeBuy'
        DataType = ftFloat
      end
      item
        Name = 'VolumeSell'
        DataType = ftFloat
      end
      item
        Name = 'DexLink'
        DataType = ftString
        Size = 100
      end>
    TableName = 'MemReturns'
    Exclusive = False
    Left = 288
    Top = 48
    object tbMemReturnsCurrency: TStringField
      FieldName = 'Currency'
      Size = 32
    end
    object tbMemReturnsDealsBuy: TIntegerField
      FieldName = 'DealsBuy'
    end
    object tbMemReturnsDealsSell: TIntegerField
      FieldName = 'DealsSell'
    end
    object tbMemReturnsDeals: TIntegerField
      FieldName = 'Deals'
    end
    object tbMemReturnsVolumeBuy: TFloatField
      FieldName = 'VolumeBuy'
    end
    object tbMemReturnsVolumeSell: TFloatField
      FieldName = 'VolumeSell'
    end
    object tbMemReturnsDexLink: TStringField
      FieldName = 'DexLink'
      Size = 100
    end
    object tbMemReturnsLastAddedTime: TDateTimeField
      FieldName = 'LastAddedTime'
    end
    object tbMemReturnsLastRemovedTime: TDateTimeField
      FieldName = 'LastRemovedTime'
    end
  end
end
