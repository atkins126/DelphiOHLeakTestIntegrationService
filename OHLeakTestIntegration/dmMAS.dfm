object dm: Tdm
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 150
  Width = 362
  object conMAS: TADOConnection
    ConnectionString = 'FILE NAME=C:\Mas\Services\LeakTestProcessService\MAS.UDL'
    LoginPrompt = False
    Provider = 'C:\Mas\Services\LeakTestProcessService\MAS.UDL'
    Left = 72
    Top = 32
  end
end
