program kNesExport;

uses
  Vcl.Forms,
  main in 'main.pas' {MainForm},
  rom in 'rom.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
