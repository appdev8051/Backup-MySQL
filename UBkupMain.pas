unit UBkupMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.Buttons, RzShellDialogs,
  RzButton,inifiles, System.ImageList, Vcl.ImgList, RzLabel, AbUnzper, AbBase, AbBrowse, AbZBrows,
  AbZipper, AbMeter,UCIT_Base,SEP_Base;

type
  TfrmMain = class(TForm)
    PageControlMain: TPageControl;
    tsBackup: TTabSheet;
    tsRestore: TTabSheet;
    tsService: TTabSheet;
    tsConfig: TTabSheet;
    Label1: TLabel;
    edtConfigSoftware: TEdit;
    Label2: TLabel;
    edtConfigDBFolder: TEdit;
    btnConfigDBFolder: TSpeedButton;
    folder_dlg_config: TRzSelectFolderDialog;
    btnConfigSave: TRzBitBtn;
    Label3: TLabel;
    edtConfigMySQLSName: TEdit;
    Label4: TLabel;
    edtBackupNewName: TEdit;
    Label5: TLabel;
    edtBackupPath: TEdit;
    btnBackupPath: TSpeedButton;
    btnBackupNewName: TSpeedButton;
    Label6: TLabel;
    btnBackup: TRzBitBtn;
    ImageList1: TImageList;
    lblBkuplblStopSvc: TRzLabel;
    lblBkuplblMakebkup: TRzLabel;
    lblBkuplblStartSvc: TRzLabel;
    Label7: TLabel;
    edtRestoreFileName: TEdit;
    btnRestoreFileName: TSpeedButton;
    btnRestore: TRzBitBtn;
    RzLabel4: TRzLabel;
    RzLabel5: TRzLabel;
    RzLabel6: TRzLabel;
    dbZipper: TAbZipper;
    dbUnzipper: TAbUnZipper;
    AbMeter1: TAbMeter;
    AbMeter2: TAbMeter;
    Label8: TLabel;
    edtConfigWatchDog: TEdit;
    procedure btnConfigDBFolderClick(Sender: TObject);
    procedure btnConfigSaveClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnBackupPathClick(Sender: TObject);
    procedure btnBackupNewNameClick(Sender: TObject);
    procedure btnBackupClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.btnBackupClick(Sender: TObject);
var
  ss : tstrings;
  I: Integer;
begin
    if SEP_ServiceStatus('',edtConfigMySQLSName.Text)=ssUnInstalled then
    begin
      Application.MessageBox(pchar('Database service ('+edtConfigMySQLSName.Text+') Not found.'),'Warning',MB_OK or MB_ICONWARNING);
      exit;
    end;
    lblBkuplblStopSvc.Blinking := true;
    SEP_ServiceStop('',edtConfigWatchDog.Text);
    Sleep(1000);
    SEP_ServiceStop('',edtConfigMySQLSName.Text);
    Sleep(2000);
    if SEP_ServiceStatus('',edtConfigMySQLSName.Text)<>ssStopped then
    begin
      SEP_ServiceStop('',edtConfigMySQLSName.Text);
      Sleep(2000);
    end;
    if SEP_ServiceStatus('',edtConfigMySQLSName.Text)<>ssStopped then
    begin
      Application.MessageBox(pchar('Database service ('+edtConfigMySQLSName.Text+
          ') could not stop. please stop it manually and try to backup again.'),'Warning',MB_OK or MB_ICONWARNING);
      exit;
    end;
    lblBkuplblStopSvc.Blinking := false;
    lblBkuplblMakebkup.Blinking := true ;
    if edtBackupPath.Text[length(edtBackupPath.Text)] <> '\' then
      edtBackupPath.Text := edtBackupPath.Text + '\';
    if not DirectoryExists(edtBackupPath.Text) then
    begin
      Application.MessageBox(pchar('Backup directory ('+edtBackupPath.Text+
                             ') Not found. Please select valid path.'),'Warning',MB_OK or MB_ICONWARNING);
      exit;
    end;
    if not DirectoryExists(edtConfigDBFolder.Text) then
    begin
      Application.MessageBox(pchar('Database directory ('+edtConfigDBFolder.Text+
                             ') Not found. Please select valid path.'),'Warning',MB_OK or MB_ICONWARNING);
      exit;
    end;
    ss := TStringList.Create;
    ss.Clear;
    if DirectoryList(edtConfigDBFolder.Text,'*.*',ss) <= 0 then
    begin
      Application.MessageBox(pchar('Database directory ('+edtConfigDBFolder.Text+
                             ') is empty !.'),'Warning',MB_OK or MB_ICONWARNING);
      exit;
    end;

    dbZipper.FileName := edtBackupPath.Text+edtBackupNewName.Text+'.zip';
    for I := 0 to ss.Count-1 do
      begin
        dbZipper.AddFiles(edtConfigDBFolder.Text+'\'+ss[i],0);
        Application.ProcessMessages;
      end;
    dbZipper.CloseArchive;
    lblBkuplblMakebkup.Blinking := false;
    lblBkuplblStartSvc.Blinking := true ;
    SEP_ServiceStart('',edtConfigMySQLSName.Text);
    lblBkuplblStartSvc.Blinking := false ;
    Application.MessageBox(pchar('Backup saved successfully in ('+edtBackupPath.Text+edtBackupNewName.Text+'.zip'+
                             ') '),'Backup successfully',MB_OK or MB_ICONINFORMATION);

end;

procedure TfrmMain.btnBackupNewNameClick(Sender: TObject);
var
 dt : String;
begin
 dt := FormatDateTime('yyyymmdd-hhnn',now);
 edtBackupNewName.Text := edtConfigSoftware.Text+'-'+dt;
end;

procedure TfrmMain.btnBackupPathClick(Sender: TObject);
var
  ini     : TIniFile;
  inipath : String;
begin
  folder_dlg_config.Title := 'Select Backup path';
  if folder_dlg_config.Execute then begin
    edtBackupPath.Text := folder_dlg_config.SelectedPathName;

    inipath := ExtractFileDir(Application.ExeName);
    if inipath[length(inipath)]<>'\' then inipath := inipath + '\' ;
    inipath := inipath + 'DBBkup.ini';
    ini := TIniFile.Create(inipath);
    try
      ini.WriteString('Backup','Path',edtBackupPath.Text);
      Application.MessageBox('Backup path saved in Configs successfully.','Configuration saved',mb_ok or MB_ICONINFORMATION);
    finally
      ini.Free;
    end;

  end;
end;

procedure TfrmMain.btnConfigDBFolderClick(Sender: TObject);
begin
  folder_dlg_config.Title := 'Select Databse files path';
  if folder_dlg_config.Execute then begin
    edtConfigDBFolder.Text := folder_dlg_config.SelectedPathName;
  end;
end;

procedure TfrmMain.btnConfigSaveClick(Sender: TObject);
var
  ini     : TIniFile;
  inipath : String;
begin
  inipath := ExtractFileDir(Application.ExeName);
  if inipath[length(inipath)]<>'\' then inipath := inipath + '\' ;
  inipath := inipath + 'DBBkup.ini';
  ini := TIniFile.Create(inipath);
  try
    ini.WriteString('Config','Software',edtConfigSoftware.Text);
    ini.WriteString('Config','DBPath',edtConfigDBFolder.Text);
    ini.WriteString('Config','MySQLSName',edtConfigMySQLSName.Text);
    ini.WriteString('Config','WatchDogSName',edtConfigWatchDog.Text);
    ini.WriteString('Config','LastConfUpdate',DateTimeToStr(now));
    Application.MessageBox('Configs Saved successfully.','Configuration saved',mb_ok or MB_ICONINFORMATION);
  finally
    ini.Free;
  end;

end;

procedure TfrmMain.FormShow(Sender: TObject);
var
  ini     : TIniFile;
  inipath : String;
begin
  inipath := ExtractFileDir(Application.ExeName);
  if inipath[length(inipath)]<>'\' then inipath := inipath + '\' ;
  inipath := inipath + 'DBBkup.ini';
  if FileExists(inipath) then
  begin
    ini := TIniFile.Create(inipath);
    try
      edtConfigSoftware.Text    := ini.ReadString('Config','Software','');
      edtConfigDBFolder.Text    := ini.ReadString('Config','DBPath','');
      edtConfigMySQLSName.Text  := ini.ReadString('Config','MySQLSName','');
      edtBackupPath.Text        := ini.ReadString('Backup','Path','c:\');
      edtConfigWatchDog.Text    := ini.ReadString('Config','WatchDogSName','');
      if length(trim(edtConfigSoftware.Text))>0 then
        Caption := caption + ' - ('+edtConfigSoftware.Text+')';
    finally
      ini.Free;
    end;
  end;
  PageControlMain.ActivePageIndex :=0;
  btnBackupNewNameClick(btnBackupNewName);
end;

end.
