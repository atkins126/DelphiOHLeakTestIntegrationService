unit MasLeakTestIntegrationServiceUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.SvcMgr, Vcl.Dialogs,
  Vcl.ExtCtrls, System.IniFiles, ADODB, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, IdHTTP, StrUtils, DateUtils, System.JSON, Data.DB, REST.Response.Adapter,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, System.Variants;

type
  TMasLeakTestIntegrationService = class(TService)
    TimerServis: TTimer;
    IdHTTP1: TIdHTTP;
    myMemTable: TFDMemTable;
    myMemTableM: TIntegerField;
    myMemTableT: TIntegerField;
    myMemTableV: TIntegerField;
    myMemTableD: TStringField;
    myMemTableMC: TStringField;
    procedure ServiceCreate(Sender: TObject);
    procedure ServiceExecute(Sender: TService);
    procedure TimerServisTimer(Sender: TObject);
  private
    { Private declarations }
    Durum:Boolean;
    procedure Servis;
    procedure DosyaLogYaz(aMesaj: String);
    procedure HttpPost(aUrlPage, aParamString: String);
    function DateConvert(aDateString: string): TDateTime;
    function DateConvertStr(aDateString: string): String;
  public
    plcIP:String;
    function GetServiceController: TServiceController; override;
    procedure JsonToDataset(aDataset :TDataset; aJson : string);
    { Public declarations }
  end;

var
  MasLeakTestIntegrationService: TMasLeakTestIntegrationService;

implementation

{$R *.dfm}

uses dmMAS;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  MasLeakTestIntegrationService.Controller(CtrlCode);
end;

function TMasLeakTestIntegrationService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TMasLeakTestIntegrationService.ServiceCreate(Sender: TObject);
var
  qry:TADOQuery;
  IniDosya: TIniFile;
  SorguYenilemeSn:Integer;

begin

  try
    try
      IniDosya := TIniFile.Create('C:\MAS\Services\LeakTestProcessService\PLCWebRequestParam.ini');

      plcIP := IniDosya.ReadString('AYAR', 'PlcIp', '192.168.11.111');

      SorguYenilemeSn := IniDosya.ReadInteger('AYAR','SorguYenilemeSn',15);

      iniDosya.Free;

      TimerServis.Enabled := False;

      TimerServis.Interval := SorguYenilemeSn * 1000;


    except on E:Exception do

    end;

  finally


  end;

end;

procedure TMasLeakTestIntegrationService.ServiceExecute(Sender: TService);
begin
  TimerServis.Enabled := True;

  while not Terminated do
    ServiceThread.ProcessRequests(True); // wait for termination

  TimerServis.Enabled := False;
end;

procedure TMasLeakTestIntegrationService.JsonToDataset(aDataset: TDataset; aJson: string);
var
  JObj: TJSONArray;
  vConv : TCustomJSONDataSetAdapter;
begin
  if (aJSON = EmptyStr) then
  begin
    Exit;
  end;

  JObj := TJSONObject.ParseJSONValue(aJSON) as TJSONArray;
  vConv := TCustomJSONDataSetAdapter.Create(Nil);

  try
    vConv.Dataset := aDataset;
    vConv.UpdateDataSet(JObj);
  finally
    vConv.Free;
    JObj.Free;
  end;
end;

function TMasLeakTestIntegrationService.DateConvert(aDateString: string): TDateTime;
var
  str:String;
  myDateTime:TDateTime;
  fmt     : TFormatSettings;
begin
  try
    str:= AnsiMidStr(aDateString,10,44);
    str:= StringReplace(str,'&#x2d;','/',[rfReplaceAll, rfIgnoreCase]);
    str:= StringReplace(str,'&#x3a;',':',[rfReplaceAll, rfIgnoreCase]);
    str:= StuffString(str,11,1,' ');

    fmt.ShortDateFormat:='yyyy/mm/dd';
    fmt.DateSeparator  :='/';
    fmt.LongTimeFormat :='hh:nn:ss';
    fmt.TimeSeparator  :=':';
    myDateTime:=StrToDateTime(str,Fmt);

    Result := myDateTime;
  finally
  end;

end;

function TMasLeakTestIntegrationService.DateConvertStr(aDateString: string): String;
var
  str,strMili,strLast:String;
  myDateTime:TDateTime;
  fmt     : TFormatSettings;
begin
  try
    str:= AnsiMidStr(aDateString,10,48);
    str:= StringReplace(str,'&#x2d;','/',[rfReplaceAll, rfIgnoreCase]);
    str:= StringReplace(str,'&#x3a;',':',[rfReplaceAll, rfIgnoreCase]);
    str:= StuffString(str,11,1,' ');
    strMili := AnsiMidStr(str,20,4);

    fmt.ShortDateFormat:='yyyy/mm/dd';
    fmt.DateSeparator  :='/';
    fmt.LongTimeFormat :='hh:nn:ss.zzz';
    fmt.TimeSeparator  :=':';
    myDateTime:= StrToDateTime(str,Fmt);
    strLast:=DateTimeToStr(myDateTime)+strMili;

    Result := strLast;
  finally
  end;

end;

procedure TMasLeakTestIntegrationService.Servis;
var
  qrySorgu,qryIslem,qrySorguProd: TADOQuery;
  FileName:string;
  HttpReturn:String;
  workCenterCode:String;
  realDateTimeStr:String;
  productionMasterId:Integer;
  machineID,dataTypeID,actualValue,lastValue,recCount:Integer;
  realDateTime:TDateTime;
  ProcessTimeSn:Integer;
begin
  qrySorgu := TADOQuery.Create(nil);
  qrySorgu.Connection := dm.conMAS;

  qrySorguProd := TADOQuery.Create(nil);
  qrySorguProd.Connection := dm.conMASProd;

  qryIslem := TADOQuery.Create(nil);
  qryIslem.Connection := dm.conMAS;

  try
    try

      HttpReturn:=IdHTTP1.Get('http://192.168.11.111/awp/myApp/LeakTestProcessData.htm');
      JsonToDataset(myMemTable,HttpReturn);

      while not myMemTable.Eof do begin
        myMemTable.Edit;
        machineID:= 0;
        dataTypeID:= 0;
        actualValue:= -1;
        productionMasterId:= 0;

        machineID:=myMemTable.Fields[0].AsInteger;
        dataTypeID:=myMemTable.Fields[1].AsInteger;
        actualValue:=myMemTable.Fields[2].AsInteger;
        realDateTime:=DateConvert(myMemTable.Fields[3].AsString);
        realDateTimeStr:=DateConvertStr(myMemTable.Fields[3].AsString);
        workCenterCode := myMemTable.Fields[4].AsString;


        with qrySorgu do
        Begin
          Close;
          SQL.Clear;
          SQL.Add(' SELECT TOP 1 Value FROM [Orhan].[LeakTestProcessData] WITH(NOLOCK) ');
          SQL.Add(' Where WorkCenterId=:WorkCenterId and DataTypeId=:DataTypeId  ORDER BY Id desc');
          Parameters.ParamByName('WorkCenterId').Value  := machineID;
          Parameters.ParamByName('DataTypeId').Value    := dataTypeID;
          Open;

          recCount := RecordCount;
          if recCount > 0 then lastValue := FieldByName('Value').AsInteger;
        End;

        with qrySorguProd do
        Begin
          Close;
          SQL.Clear;
          SQL.Add(' SELECT TOP 1 PM.Id FROM [Production].[ProductionMaster] AS PM WITH(NOLOCK)');
          SQL.Add(' LEFT JOIN [Organization].[WorkCenter] AS WC WITH(NOLOCK) ON PM.WorkCenterId = WC.Id ');
          SQL.Add(' WHERE PM.EndDateTime IS NULL AND WC.Code=:WorkCenterCode ');
          Parameters.ParamByName('WorkCenterCode').Value := workCenterCode;
          Open;

          if RecordCount > 0 then productionMasterId := FieldByName('Id').AsInteger;
        End;

        if (actualValue <> lastValue) or (recCount = 0) then
        Begin
          with qryIslem do
          Begin
            Close;
            SQL.Clear;
            SQL.Add('INSERT INTO [Orhan].[LeakTestProcessData] ');
            SQL.Add('([WorkCenterId],[DataTypeId],[Value],[RealTimeStamp],[RealTimeStampStr],[RecordTimeStamp],[ProductionMasterId]) VALUES ');
            SQL.Add('(:WorkCenterId, :DataTypeId, :Value, :RealTimeStamp, :RealTimeStampStr, :RecordTimeStamp, :ProductionMasterId) ');
            Parameters.ParamByName('WorkCenterId').Value          := machineID;
            Parameters.ParamByName('DataTypeId').Value            := dataTypeID;
            Parameters.ParamByName('Value').Value                 := actualValue;
            Parameters.ParamByName('RealTimeStamp').Value         := realDateTime;
            Parameters.ParamByName('RealTimeStampStr').Value      := realDateTimeStr;
            Parameters.ParamByName('RecordTimeStamp').Value       := Now;
            if productionMasterId > 0 then
             Parameters.ParamByName('ProductionMasterId').Value   := productionMasterId
            else
              Parameters.ParamByName('ProductionMasterId').Value  := null;
            ExecSQL;
          End;

        End;

        myMemTable.Next;

      end;


    except on e:Exception do
      begin
        DosyaLogYaz(DateTimeToStr(now)+'PLC Web Servisten Ýþleminde Hata Oluþtu');
        Durum:= False;

      end;
    end;
  finally
    qrySorgu.Close;
    FreeAndNil(qrySorgu);
    qryIslem.Close;
    FreeAndNil(qryIslem);

  end;

end;

procedure TMasLeakTestIntegrationService.TimerServisTimer(Sender: TObject);
begin
  Durum:= True;
  TimerServis.Enabled:= False;
  try
    try
      Servis;

      if Durum = False then
      begin
        //dm.DataModuleCreate(Sender);
        dm.conMAS.Close;
        dm.conMAS.Open;
      end;

    except
      //dm.conMAS.Close;
      //dm.conMAS.Open;
      //TimerServis.Enabled := False;
      //TimerServis.Enabled := True;
    end;
  finally
    TimerServis.Enabled:= True;
  end;

end;

procedure TMasLeakTestIntegrationService.DosyaLogYaz(aMesaj:String);
var
Dosya: Textfile;
begin
  if (FileExists('C:\Services\LeakTestProcessService\LeakTestProcessServiceLog.txt')=false) then
  Begin
    AssignFile(Dosya, 'C:\Services\LeakTestProcessService\LeakTestProcessServiceLog.txt');
    ReWrite(Dosya);
  End;

  AssignFile(Dosya, 'C:\Services\LeakTestProcessService\LeakTestProcessServiceLog.txt');
  Reset(Dosya);
  Append(Dosya);
  Writeln(Dosya, aMesaj);
  Closefile(Dosya);
end;

procedure TMasLeakTestIntegrationService.HttpPost(aUrlPage: String; aParamString:String);
var
  myData : TStringStream;
begin

  try
    try
      //ParamString :=  "M1020.0"=1'
      myData := TStringStream.Create(aParamString, TEncoding.UTF8);

      IdHTTP1.Request.ContentType := 'application/json';
      IdHTTP1.Request.CharSet     := 'utf-8';
      IdHTTP1.Post(aUrlPage, myData);

    except on E:Exception do
      DosyaLogYaz(DateTimeToStr(now)+' PLC Web Servere Veri Gönderilirken Hata Oluþtu.Gönderilen Veri: '+aParamString);
    end;

  finally
  end;
end;
end.
