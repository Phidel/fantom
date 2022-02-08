program Fantom;

uses
  Vcl.Forms,
  fMain in 'fMain.pas' {MainForm},
  uConst in 'uConst.pas',
  uCurrency in 'uCurrency.pas',
  uOper in 'uOper.pas',
  uAppParam in 'uAppParam.pas',
  uProcess in 'uProcess.pas',
  uDataModule in 'uDataModule.pas' {dm: TDataModule};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(Tdm, dm);
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
