object MasLeakTestIntegrationService: TMasLeakTestIntegrationService
  OldCreateOrder = False
  OnCreate = ServiceCreate
  DisplayName = 'MasLeakTestIntegrationService'
  OnExecute = ServiceExecute
  Height = 224
  Width = 502
  object TimerServis: TTimer
    Enabled = False
    Interval = 15000
    OnTimer = TimerServisTimer
    Left = 88
    Top = 40
  end
  object IdHTTP1: TIdHTTP
    AllowCookies = True
    ProxyParams.BasicAuthentication = False
    ProxyParams.ProxyPort = 0
    Request.ContentLength = -1
    Request.ContentRangeEnd = -1
    Request.ContentRangeStart = -1
    Request.ContentRangeInstanceLength = -1
    Request.Accept = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    Request.BasicAuthentication = False
    Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
    Request.Ranges.Units = 'bytes'
    Request.Ranges = <>
    HTTPOptions = [hoForceEncodeParams]
    Left = 224
    Top = 40
  end
  object myMemTable: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 357
    Top = 40
    object myMemTableM: TIntegerField
      FieldName = 'M'
    end
    object myMemTableT: TIntegerField
      FieldName = 'T'
    end
    object myMemTableV: TIntegerField
      FieldName = 'V'
    end
    object myMemTableD: TStringField
      FieldName = 'D'
      Size = 150
    end
    object myMemTableMC: TStringField
      FieldName = 'MC'
    end
  end
end
