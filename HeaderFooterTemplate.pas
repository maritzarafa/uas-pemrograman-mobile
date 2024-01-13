unit HeaderFooterTemplate;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, IdHTTP, IdSSLOpenSSL,
  IdMultipartFormData, IdGlobal, IdURI, IdHeaderList, System.JSON, FMX.Objects,
  FMX.ListBox, FMX.Edit, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.Layouts,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.ListView;

type
    THeaderFooterForm = class(TForm)
    Header: TToolBar;
    Footer: TToolBar;
    HeaderLabel: TLabel;
    Button1: TButton;
    DProvinceOrigin: TComboBox;
    TLabelProvince: TText;
    DCityOrigin: TComboBox;
    TLabelCity: TText;
    DCourier: TComboBox;
    TLabelCourier: TText;
    TLabelWeight: TText;
    EWeight: TEdit;
    Text1: TText;
    DProvinceDestionation: TComboBox;
    Text2: TText;
    DCityDestination: TComboBox;
    ListBox1: TListBox;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure DProvinceOnChangeOrigin(Sender: TObject);
    procedure DCityOriginOnChange(Sender: TObject);
    procedure DCourierOnChange(Sender: TObject);
    procedure  DCityDestinationOnChange(Sender: TObject);
    procedure DProvinceOnChangeDestination(Sender: TObject);
    procedure EWeightChange(Sender: TObject);

//    procedure TEditChange(Sender: TObject);
  private
    { Private declarations }
    procedure PopulateProvinces;
    procedure GotCity(provinceId: string; DCityComponent: TComboBox);
    procedure AddPersonToListBox(Service, Cost, Description: string);
    procedure MakeApiRequest;

  public
    { Public declarations }
  end;

var
  HeaderFooterForm: THeaderFooterForm;

var
  selectedOrigin: string;
  selectedDestination: string;
  selectedWeight: Double;
  selectedCourier: string;

implementation

{$R *.fmx}

procedure THeaderFooterForm.MakeApiRequest;
var
  HTTP: TIdHTTP;
  Params: TStringList;
  Response: string;
var
    Json: TJSONObject;
    RajaOngkir: TJSONObject;
    Results: TJSONArray;
    Costs: TJSONArray;
    Cost: TJSONObject;
    ICosts: Integer;
    ICost:Integer;
    CstArr: TJSONArray;
    ServiceObj: TJSONObject;
begin
  HTTP := TIdHTTP.Create;
  Params := TStringList.Create;

  try
    HTTP.IOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
    HTTP.Request.ContentType := 'application/x-www-form-urlencoded';
    HTTP.Request.CustomHeaders.AddValue('key', '92d0d74f5b78987830d14b212f949109');

    Params.Add('origin=' + selectedOrigin);
    Params.Add('destination=' + selectedDestination);
    Params.Add('weight=' + FloatToStr(selectedWeight));
    Params.Add('courier='+ selectedCourier);

    try
      Response := HTTP.Post('http://api.rajaongkir.com/starter/cost', Params);
      Json := TJSONObject.ParseJSONValue(Response) as TJsonObject;
      RajaOngkir := Json.GetValue('rajaongkir') as TJSONObject;
      Results := RajaOngkir.GetValue('results') as TJSONArray;

        // Populate ComboBox with provinces
       for ICosts := 0 to Results.Count - 1 do
       begin
          Cost := Results.Items[ICosts] as TJSONObject;
          CstArr := Cost.GetValue('costs') as TJSONArray;
          for ICost := 0 to CstArr.Count - 1 do
            begin
                ServiceObj := CstArr.Items[ICost] as TJSONObject;
                var gotCostArr : TJSONArray;
                var gotCostObj : TJSONObject;
                gotCostArr := ServiceObj.GetValue('cost') as TJSONArray;
                gotCostObj :=   gotCostArr.Items[0] as TJSONObject;
                AddPersonToListBox(ServiceObj.GetValue('service').Value,
                  gotCostObj.GetValue('value').Value,
                  ServiceObj.GetValue('description').Value);
            end;
       end;
    except
      on E: Exception do
        ShowMessage('Error: ' + E.Message);
    end;
  finally
    HTTP.Free;
    Params.Free;
  end;
end;



procedure GotProvince();
var
  HTTP: TIdHTTP;
  Response: string;
begin
  HTTP := TIdHTTP.Create;
  try
    HTTP.IOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
//    HTTP.Request.ContentType := 'application/x-www-form-urlencoded';
    HTTP.Request.CustomHeaders.AddValue('key', '92d0d74f5b78987830d14b212f949109');

    try
      Response := HTTP.Get('http://api.rajaongkir.com/starter/province');
      ShowMessage(Response);
    except
      on E: Exception do
        ShowMessage('Error: ' + E.Message);
    end;
  finally
    HTTP.Free;
  end;
end;


procedure THeaderFooterForm.Button1Click(Sender: TObject);
begin
  //MakeApiRequest;
    ListBox1.Clear();
    ListBox1.Items.Add('Service' + #9 + #9 + 'Cost' + #9 + #9 + 'Description');
    MakeApiRequest;
end;


procedure THeaderFooterForm.FormCreate(Sender: TObject);
begin
    //first load for exec
    ListBox1.Items.Add('Service' + #9 + #9 + 'Cost' + #9 + #9 + 'Description');

    PopulateProvinces;
    DCourier.Items.Add('jne');
    DCourier.Items.Add('pos');
    DCourier.Items.Add('tiki');
    if DCourier.Items.Count > 0 then
        DCourier.ItemIndex := 0;

end;

procedure THeaderFooterForm.PopulateProvinces;
  var
    Json: TJSONObject;
    RajaOngkir: TJSONObject;
    Results: TJSONArray;
    Province: TJSONObject;
    I: Integer;
begin
  Json := TJSONObject.ParseJSONValue(
    '{ "rajaongkir": { "results": [ {"province_id": "1", "province": "Bali"}, '
  + '{"province_id": "2", "province": "Bangka Belitung"}, {"province_id": "3", "province": "Banten"}, '
  + '{"province_id": "4", "province": "Bengkulu"}, {"province_id": "5", "province": "DI Yogyakarta"}, '
  + '{"province_id": "6", "province": "DKI Jakarta"}, {"province_id": "7", "province": "Gorontalo"}, '
  + '{"province_id": "8", "province": "Jambi"}, {"province_id": "9", "province": "Jawa Barat"}, '
  + '{"province_id": "10", "province": "Jawa Tengah"}, {"province_id": "11", "province": "Jawa Timur"}, '
  + '{"province_id": "12", "province": "Kalimantan Barat"}, {"province_id": "13", "province": "Kalimantan Selatan"}, '
  + '{"province_id": "14", "province": "Kalimantan Tengah"}, {"province_id": "15", "province": "Kalimantan Timur"}, '
  + '{"province_id": "16", "province": "Kalimantan Utara"}, {"province_id": "17", "province": "Kepulauan Riau"}, '
  + '{"province_id": "18", "province": "Lampung"}, {"province_id": "19", "province": "Maluku"}, '
  + '{"province_id": "20", "province": "Maluku Utara"}, {"province_id": "21", "province": "Nanggroe Aceh Darussalam (NAD)"}, '
  + '{"province_id": "22", "province": "Nusa Tenggara Barat (NTB)"}, {"province_id": "23", "province": "Nusa Tenggara Timur (NTT)"}, '
  + '{"province_id": "24", "province": "Papua"}, {"province_id": "25", "province": "Papua Barat"}, {"province_id": "26", "province": "Riau"}, '
  + '{"province_id": "27", "province": "Sulawesi Barat"}, {"province_id": "28", "province": "Sulawesi Selatan"}, '
  + '{"province_id": "29", "province": "Sulawesi Tengah"}, {"province_id": "30", "province": "Sulawesi Tenggara"}, '
  + '{"province_id": "31", "province": "Sulawesi Utara"}, {"province_id": "32", "province": "Sumatera Barat"}, '
  + '{"province_id": "33", "province": "Sumatera Selatan"}, {"province_id": "34", "province": "Sumatera Utara"} ] }}'
  ) as TJSONObject;


  try
    // Extract provinces array
    RajaOngkir := Json.GetValue('rajaongkir') as TJSONObject;
    Results := RajaOngkir.GetValue('results') as TJSONArray;

    // Populate ComboBox with provinces
    for I := 0 to Results.Count - 1 do
    begin
      Province := Results.Items[I] as TJSONObject;
      DProvinceOrigin.Items.AddObject(Province.GetValue('province').Value,
          TObject(StrToInt(Province.GetValue('province_id').Value)));
      DProvinceDestionation.Items.AddObject(Province.GetValue('province').Value,
          TObject(StrToInt(Province.GetValue('province_id').Value)));
    end;
  finally
    Json.Free;
  end;
end;

procedure THeaderFooterForm.DProvinceOnChangeOrigin(Sender: TObject);
var
  SelectedProvinceId: Integer;
begin
  // Get the province_id associated with the selected province
  if DProvinceOrigin.ItemIndex <> -1 then
  begin
    SelectedProvinceId := Integer(DProvinceOrigin.Items.Objects[DProvinceOrigin.ItemIndex]);
    GotCity(IntToStr(SelectedProvinceId), DCityOrigin);
  end;
end;

procedure THeaderFooterForm.EWeightChange(Sender: TObject);
var
  Kilograms: Double;
  Grams: Double;
  begin
    //Validate user input
    if TryStrToFloat(EWeight.Text, Kilograms) then
      begin
        //Convert kilograms to grams
        Grams := Kilograms * 1000;
        selectedWeight := Grams;
      end
    else
      begin
        //Handle invalid input
        ShowMessage('Invalid input. Please enter a valid number.');
      end;
end;

procedure THeaderFooterForm.DProvinceOnChangeDestination(Sender: TObject);
var
  SelectedProvinceId: Integer;
begin
  // Get the province_id associated with the selected province
  if DProvinceDestionation.ItemIndex <> -1 then
  begin
    SelectedProvinceId := Integer(DProvinceDestionation.Items.Objects[DProvinceDestionation.ItemIndex]);
    GotCity(IntToStr(SelectedProvinceId), DCityDestination);
  end;
end;


procedure THeaderFooterForm.GotCity(provinceId: string; DCityComponent: TComboBox);
var
  HTTP: TIdHTTP;
  Response: string;
  Json: TJSONObject;
  RajaOngkir: TJSONObject;
  Results: TJSONArray;
  City: TJSONObject;
  I: Integer;
begin
  HTTP := TIdHTTP.Create;

  try
    HTTP.IOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
    HTTP.Request.CustomHeaders.AddValue('key', '92d0d74f5b78987830d14b212f949109');


    try
      Response := HTTP.Get('http://api.rajaongkir.com/starter/city?province=' + provinceId);
      Json := TJSONObject.ParseJSONValue(Response) as TJsonObject;
      RajaOngkir := Json.GetValue('rajaongkir') as TJSONObject;
      Results := RajaOngkir.GetValue('results') as TJSONArray;
      DCityComponent.Items.Clear();
    // Populate ComboBox with city
      for I := 0 to Results.Count - 1 do
      begin
        City := Results.Items[I] as TJSONObject;
        DCityComponent.Items.AddObject(City.GetValue('type').Value + ' ' +
        City.GetValue('city_name').Value,
        TObject(StrToInt(City.GetValue('city_id').Value)));
      end;
    except
      on E: Exception do
        ShowMessage('Error: ' + E.Message);
    end;
  finally
    HTTP.Free;
//    Json.Free;
  end;
end;


procedure THeaderFooterForm.DCityOriginOnChange(Sender: TObject);
var
  SelectedCityId: Integer;
begin
  // Get the province_id associated with the selected province
  if DCityOrigin.ItemIndex <> -1 then
  begin
    SelectedCityId := Integer(DCityOrigin.Items.Objects[DCityOrigin.ItemIndex]);
    selectedOrigin := IntToStr(SelectedCityId);
  end;
end;

procedure THeaderFooterForm.DCityDestinationOnChange(Sender: TObject);
var
  SelectedCityId: Integer;
begin
  // Get the province_id associated with the selected province
  if DCityDestination.ItemIndex <> -1 then
  begin
    SelectedCityId := Integer(DCityDestination.Items.Objects[DCityDestination.ItemIndex]);
    selectedDestination := IntToStr(SelectedCityId);
  end;
end;


procedure THeaderFooterForm.DCourierOnChange(Sender: TObject);
var
  SelectedValue: string;
begin
  if DCourier.ItemIndex <> -1 then
      selectedCourier := DCourier.Items[DCourier.ItemIndex]
  else
    ShowMessage('No item selected');
end;


procedure THeaderFooterForm.AddPersonToListBox(Service, Cost, Description: string);
begin
  ListBox1.Items.Add(Service + #9 + #9 + Cost + #9 + #9 + Description);
end;
end.
