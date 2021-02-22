object dm: Tdm
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 196
  Width = 461
  object conMAS: TADOConnection
    ConnectionString = 'FILE NAME=C:\Mas\Services\LeakTestProcessService\MAS.UDL'
    LoginPrompt = False
    Provider = 'C:\Mas\Services\LeakTestProcessService\MAS.UDL'
    Left = 72
    Top = 32
  end
  object conMASProd: TADOConnection
    ConnectionString = 'FILE NAME=C:\Mas\Services\LeakTestProcessService\MAS-PROD.UDL'
    LoginPrompt = False
    Provider = 'C:\Mas\Services\LeakTestProcessService\MAS-PROD.UDL'
    Left = 144
    Top = 32
  end
end
