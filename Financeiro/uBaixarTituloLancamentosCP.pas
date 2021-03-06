unit uBaixarTituloLancamentosCP;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Data.DB, Vcl.Grids,
  Vcl.DBGrids, Vcl.StdCtrls, Data.Win.ADODB, uTiposPagamentoCadastrados,
  uContasCorrenteCadastradas, uClassLancamentosCP;

type
  TfrmBaixarTituloLancamentosCP = class(TForm)
    PageControl1: TPageControl;
    tbsBaixaTitulo: TTabSheet;
    tbsLancamentos: TTabSheet;
    btnVoltar: TButton;
    Label1: TLabel;
    dtpDataPagamento: TDateTimePicker;
    Label2: TLabel;
    edtTipoPagamento: TEdit;
    btnSelecionarTipoPagamento: TButton;
    Label3: TLabel;
    edtContaCorrente: TEdit;
    btnSelecionarConta: TButton;
    btnSalvar: TButton;
    DBGrid1: TDBGrid;
    Label4: TLabel;
    edtValorPago: TEdit;
    Label5: TLabel;
    mmObservacao: TMemo;
    edtIdContaCorrente: TEdit;
    Label6: TLabel;
    edtIdTipoPagamento: TEdit;
    Label7: TLabel;
    edtSaldoDevedor: TEdit;
    Label8: TLabel;
    ADOCommand1: TADOCommand;
    Label9: TLabel;
    mmObservacaoPagamento: TMemo;
    ADOQuery1: TADOQuery;
    DataSource1: TDataSource;
    ADOConnection1: TADOConnection;
    ADOQuery1DatadoPagamento: TWideStringField;
    ADOQuery1ContaCorrrente: TWideStringField;
    ADOQuery1TipodePagamento: TWideStringField;
    ADOQuery1ValorPago: TFloatField;
    btnVoltar2: TButton;
    ADOQuery2: TADOQuery;
    procedure btnVoltarClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnSelecionarTipoPagamentoClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure btnSelecionarContaClick(Sender: TObject);
    procedure btnVoltar2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    lancamentoCP : ClassLancamentosCP;
    tipo_pagamento : TfrmTiposPagamentoCadastrados;
    contas_corrente : TfrmContasCorrenteCadastradas;
    procedure SalvarPagamento;
    procedure PegarDados;
    function VerificarCamposNulos : boolean;
    procedure AtualizarValorPago;
    //abaixo a fuction verifica se o valor pago � maior do que o valor devido
    function VerificarValorPago : boolean;
    //abaixo a procedure verifica se o valor pago quitou totalmente a conta
    procedure VerificarQuita��o;
    procedure AtualizarSaldoDevedor;
    procedure AtualizarContaCorrente;
    function PegarSaldoContaCorrente : double;
    procedure LimparCampos;
  public
    idconta_pagar : string;
    valor_a_pagar : double;
  end;

var
  frmBaixarTituloLancamentosCP: TfrmBaixarTituloLancamentosCP;

implementation

{$R *.dfm}


procedure TfrmBaixarTituloLancamentosCP.btnSalvarClick(Sender: TObject);
begin
  if self.VerificarCamposNulos = true then
    Application.MessageBox('Os campos com * n�o podem ser nulos!', 'Aten��o',
      MB_OK + MB_ICONEXCLAMATION)
  else if self.VerificarValorPago = true then
    Application.MessageBox('O valor pago n�o pode ser maior do que o valor devido!',
      'Aten��o', MB_OK + MB_ICONEXCLAMATION)
  else
  begin
    try
      self.SalvarPagamento;

      self.AtualizarValorPago;

      self.VerificarQuita��o;

      self.AtualizarSaldoDevedor;

      self.AtualizarContaCorrente;

      self.LimparCampos;

      Application.MessageBox('Pagamento cadastrado com sucesso!', 'Conclu�do',
        MB_OK + MB_ICONINFORMATION);

      btnVoltar.SetFocus;

      self.ADOQuery1.Active := false;
      self.ADOQuery1.Active := true;
    except
      on e : Exception do
        Application.MessageBox('N�o foi poss�vel cadastrar o pagamento!',
          'Erro ao cadastrar', MB_OK + MB_ICONSTOP);
    end;
  end;
end;

procedure TfrmBaixarTituloLancamentosCP.SalvarPagamento;
begin
  self.PegarDados;

  ADOCommand1.CommandText := 'insert into lancamento values(null, ' +
    idconta_pagar + ', "' +
    self.lancamentoCP.getDataPagamento + '", ' +
    IntToStr(self.lancamentoCP.getIdContaCorrente) + ', ' +
    IntToStr(self.lancamentoCP.getIdTipoPagamento) + ', ' +
    FloatToStr(self.lancamentoCP.getValorPago) + ', "' +
    self.lancamentoCP.getObservacao + '");';

  ADOCommand1.Execute;
end;


procedure TfrmBaixarTituloLancamentosCP.PegarDados;
begin
  self.lancamentoCP.setIdContaPagar(StrToInt(self.idconta_pagar));
  self.lancamentoCP.setDataPagamento(FormatDateTime('yyyy-mm-dd', self.dtpDataPagamento.Date));
  self.lancamentoCP.setIdContaCorrente(StrToInt(self.edtIdContaCorrente.Text));
  self.lancamentoCP.setIdTipoPagamento(StrToInt(self.edtIdTipoPagamento.Text));
  self.lancamentoCP.setValorPago(StrToFloat(self.edtValorPago.Text));
  self.lancamentoCP.setObservacao(self.mmObservacao.Text);
end;


procedure TfrmBaixarTituloLancamentosCP.AtualizarValorPago;
begin
  ADOCommand1.CommandText := '';
  ADOCommand1.CommandText := 'update contas_pagar set valor_pago=valor_pago + ' +
    self.edtValorPago.Text + ' where idconta_pagar=' + self.idconta_pagar;

  ADOCommand1.Execute;
end;


procedure TfrmBaixarTituloLancamentosCP.VerificarQuita��o;
begin
  //caso tiver conclu�do totalmente o pagamento, cadastra a data do �ltimo pagamento
  if (StrToFloat(self.edtSaldoDevedor.Text)) = (StrToFloat(self.edtValorPago.Text)) then
  begin
    ADOCommand1.CommandText := '';
    ADOCommand1.CommandText := 'update contas_pagar set pago_em="' +
      FormatDateTime('yyyy-mm-dd', self.dtpDataPagamento.Date) +
      '" where idconta_pagar=' + self.idconta_pagar + ';';

    ADOCommand1.Execute;

    self.btnSalvar.Enabled := false;
  end;
end;


procedure TfrmBaixarTituloLancamentosCP.AtualizarSaldoDevedor;
begin
  //atualiza o edit "Saldo Devedor"
  self.edtSaldoDevedor.Text :=
    FloatTOStr(StrToFloat(self.edtSaldoDevedor.Text) - StrToFloat(self.edtValorPago.Text));
end;


procedure TfrmBaixarTituloLancamentosCP.AtualizarContaCorrente;
var
  saldo : double;
begin
  saldo := self.PegarSaldoContaCorrente;

  //atualiza a conta corrente com o novo saldo
  saldo := saldo - self.lancamentoCP.getValorPago;

  self.ADOCommand1.CommandText := '';
  self.ADOCommand1.CommandText := 'update conta_corrente set saldo=' +
    FloatToStr(saldo) + ' where idconta_corrente=' +
    IntToStr(self.lancamentoCP.getIdContaCorrente) + ';';
  self.ADOCommand1.Execute;
end;


function TfrmBaixarTituloLancamentosCP.PegarSaldoContaCorrente;
var
  saldo_contacorrente : double;
begin
  self.ADOQuery2.SQL.Clear;
  self.ADOQuery2.SQL.Add('select saldo from conta_corrente where idconta_corrente=' +
    IntToStr(self.lancamentoCP.getIdContaCorrente) + ';');
  self.ADOQuery2.Active := true;
  saldo_contacorrente := StrToFloat(self.ADOQuery2.Fields[0].AsString);

  result := saldo_contacorrente;
end;


function TfrmBaixarTituloLancamentosCP.VerificarCamposNulos;
begin
  if (edtTipoPagamento.Text = '') or (edtValorPago.Text = '') or
      (StrToFloat(self.edtValorPago.Text) = 0) then
    result := true
  else
    result := false;
end;



function TfrmBaixarTituloLancamentosCP.VerificarValorPago;
begin
  if (StrToFloat(self.edtValorPago.Text)) > StrToFloat(self.edtSaldoDevedor.Text) then
    result := true
  else
    result := false;
end;


procedure TfrmBaixarTituloLancamentosCP.btnSelecionarContaClick(
  Sender: TObject);
begin
  self.contas_corrente := TfrmContasCorrenteCadastradas.Create(nil);
  self.contas_corrente.selecionar := true;
  self.contas_corrente.ShowModal;

  self.edtContaCorrente.Text := self.contas_corrente.nome_conta_corrente;
  self.edtIdContaCorrente.Text := IntToStr(self.contas_corrente.idconta_corrente);

  self.contas_corrente.Destroy;
end;

procedure TfrmBaixarTituloLancamentosCP.btnSelecionarTipoPagamentoClick(
  Sender: TObject);
begin
  self.tipo_pagamento := TfrmTiposPagamentoCadastrados.Create(nil);
  self.tipo_pagamento.selecionar := true;
  self.tipo_pagamento.ShowModal;

  self.edtIdTipoPagamento.Text := self.tipo_pagamento.idtipo_pagamentoS;
  self.edtTipoPagamento.Text := self.tipo_pagamento.tipo_pagamentoS;
  self.tipo_pagamento.selecionar := false;

  self.tipo_pagamento.Destroy;
end;

procedure TfrmBaixarTituloLancamentosCP.btnVoltarClick(Sender: TObject);
begin
  self.Close;
end;

procedure TfrmBaixarTituloLancamentosCP.btnVoltar2Click(Sender: TObject);
begin
  self.Close;
end;

procedure TfrmBaixarTituloLancamentosCP.FormActivate(Sender: TObject);
begin
  self.lancamentoCP := ClassLancamentosCP.cLancamentosCP;
  self.ADOQuery1.Parameters.ParamByName('idconta_especifica').Value := self.idconta_pagar;
  self.ADOQuery1.Active := false;
  self.ADOQuery1.Active := true;
end;

procedure TfrmBaixarTituloLancamentosCP.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  self.lancamentoCP.dLancamentosCP;
end;

procedure TfrmBaixarTituloLancamentosCP.FormCreate(Sender: TObject);
begin
  dtpDataPagamento.Date := now;
end;


procedure TfrmBaixarTituloLancamentosCP.LimparCampos;
begin
  self.dtpDataPagamento.Date := now;
  self.edtIdTipoPagamento.Text := '';
  self.edtTipoPagamento.Text := '';
  self.edtContaCorrente.Text := '';
  self.edtIdContaCorrente.Text := '';
  self.edtValorPago.Text := '';
  mmObservacao.Text := '';
end;


end.
