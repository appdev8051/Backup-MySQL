program MySQLBkup;

uses
  Vcl.Forms,
  UBkupMain in 'UBkupMain.pas' {frmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
