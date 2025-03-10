unit Kafka.FMX.Form.Topics;
interface
uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Generics.Collections,System.Rtti,

  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Memo.Types,
  FMX.Edit, FMX.StdCtrls, FMX.ScrollBox, FMX.Memo, FMX.Controls.Presentation, FMX.Layouts,
  FMX.Grid.Style, FMX.Grid,

  Kafka.Lib,
  Kafka.Factory,
  Kafka.Interfaces,
  Kafka.Helper,
  Kafka.Types,

  Kafka.FMX.Helper;

type
  TfrmTopics = class(TForm)
    btnStart: TButton;
    btnStop: TButton;
    tmrUpdate: TTimer;
    lblStatus: TLabel;
    Label1: TLabel;
    memKafkaConfig: TMemo;
    grdMessages: TGrid;
    colPartition: TStringColumn;
    colKey: TStringColumn;
    colPayload: TStringColumn;
    Label2: TLabel;
    memLog: TMemo;
    btnCheckTopicExists: TButton;
    btnCreateTopic: TButton;
    edTopicName: TEdit;
    btnRefreshList: TButton;
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure tmrUpdateTimer(Sender: TObject);
    procedure grdMessagesGetValue(Sender: TObject; const ACol, ARow: Integer; var Value: TValue);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnRefreshListClick(Sender: TObject);
    procedure btnCheckTopicExistsClick(Sender: TObject);
    procedure btnCreateTopicClick(Sender: TObject);
  private
    FKafkaProducer: IKafkaProducer;
    FKafkaServers: String;
    FStringEncoding: TEncoding;
    FTopics: TStringList;

    procedure Log(aStr: string; aArgs: array of const);
    procedure UpdateStatus;
    procedure Start;
    procedure Stop;
    procedure UpdateTopicList;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Execute(const KafkaServers: String);
  end;

var
  frmTopics: TfrmTopics;

implementation

{$R *.fmx}

procedure TfrmTopics.btnCheckTopicExistsClick(Sender: TObject);
begin
  if FKafkaProducer.TopicExists(edTopicName.Text) then
    Log('Topic "%s" exists', [edTopicName.Text])
  else
    Log('Topic "%s" not found', [edTopicName.Text]);
end;

procedure TfrmTopics.btnCreateTopicClick(Sender: TObject);
begin
  if FKafkaProducer.TopicCreate(edTopicName.Text) then
    Log('Topic "%s" created', [edTopicName.Text])
  else
    Log('Topic "%s" failed to create', [edTopicName.Text]);
end;

procedure TfrmTopics.btnRefreshListClick(Sender: TObject);
begin
  UpdateTopicList;
end;

procedure TfrmTopics.btnStartClick(Sender: TObject);
begin
  Start;
  UpdateTopicList;
end;

procedure TfrmTopics.btnStopClick(Sender: TObject);
begin
  Stop;
end;

constructor TfrmTopics.Create(AOwner: TComponent);
begin
  inherited;

  FStringEncoding := TEncoding.UTF8;

  FTopics := TStringList.Create;
  FTopics.Sorted := True;

  UpdateStatus;
end;

destructor TfrmTopics.Destroy;
begin
  FreeAndNil(FTopics);

  inherited;
end;

procedure TfrmTopics.Execute(const KafkaServers: String);
begin
  FKafkaServers := KafkaServers;

  memKafkaConfig.Lines.Add('bootstrap.servers=' + KafkaServers);

  Show;
end;

procedure TfrmTopics.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
end;

procedure TfrmTopics.grdMessagesGetValue(Sender: TObject; const ACol, ARow: Integer; var Value: TValue);
begin
  case ACol of
    0: Value := FTopics[ARow];
    1: Value := '';
    2: Value := '';
  end;
end;

procedure TfrmTopics.Log(aStr: string; aArgs: array of const);
begin
  memLog.Lines.Append(Format(aStr, aArgs));
end;

procedure TfrmTopics.Start;
var
  Names, Values: TArray<String>;
begin
  if FKafkaProducer = nil then
  begin
    TKafkaUtils.StringsToConfigArrays(memKafkaConfig.Lines, Names, Values);

    FKafkaProducer := TKafkaFactory.NewProducer(Names, Values);
  end;
end;

procedure TfrmTopics.Stop;
begin
  FKafkaProducer := nil;
end;

procedure TfrmTopics.tmrUpdateTimer(Sender: TObject);
begin
  UpdateStatus;
end;

procedure TfrmTopics.UpdateStatus;
var
  statusStr: String;
begin
  if FKafkaProducer = nil then
  begin
    statusStr := 'idle';
  end
  else
  begin
    statusStr := Format('topic count = %d', [FKafkaProducer.TopicCount]);
  end;

  lblStatus.Text := Format('Status: %s', [statusStr]);

  btnStart.Enabled := FKafkaProducer = nil;
  btnRefreshList.Enabled := FKafkaProducer <> nil;
  btnCheckTopicExists.Enabled := FKafkaProducer <> nil;
  btnCreateTopic.Enabled := FKafkaProducer <> nil;
  btnStop.Enabled := FKafkaProducer <> nil;

  memKafkaConfig.Enabled := FKafkaProducer = nil;
end;

procedure TfrmTopics.UpdateTopicList;
var
  topicList: TArray<string>;
  I: Integer;
begin
  FTopics.Clear;
  if FKafkaProducer = nil then Exit;

  topicList := FKafkaProducer.TopicList;

  for I := 0 to High(topicList) do
    FTopics.Add(topicList[I]);

  TFMXHelper.SetGridRowCount(grdMessages, FTopics.Count);
end;

end.
