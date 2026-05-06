import 'dart:io';
import 'package:flutter/material.dart' hide Border, BorderStyle;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../controllers/demanda_controller.dart';
import '../services/cloud_backup_service.dart';
import '../services/auth_service.dart';
import '../services/drive_backup_service.dart';
import '../models/empresa_model.dart';
import '../models/site_model.dart';
import '../models/relatorio_model.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ExportarScreen extends StatelessWidget {
  final DemandaController controller;

  const ExportarScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar Relatório'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
      ),
      backgroundColor: AppTheme.surfaceColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: AppTheme.primaryColor.withAlpha(40)),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withAlpha(18),
                      Colors.white,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.analytics_outlined,
                            color: AppTheme.primaryColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Central de Relatórios',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Visualize e compartilhe os dados da demanda com um padrão profissional.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildResumoChip(
                          icon: Icons.business_outlined,
                          label: '${controller.empresas.length} empresa(s)',
                        ),
                        _buildResumoChip(
                          icon: Icons.cell_tower_outlined,
                          label: '${controller.totalSitesGlobal} sites',
                        ),
                        _buildResumoChip(
                          icon: Icons.event_available_outlined,
                          label: _formatDate(DateTime.now()),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildOpcaoExportar(
              context,
              icon: Icons.picture_as_pdf,
              titulo: 'Exportar PDF',
              descricao: 'Relatório completo em formato PDF profissional',
              cor: Colors.red,
              onTap: () => _exportarPdf(context),
            ),
            const SizedBox(height: 12),
            _buildOpcaoExportar(
              context,
              icon: Icons.copy,
              titulo: 'Copiar para Área de Transferência',
              descricao: 'Relatório formatado para colar em qualquer lugar',
              cor: Colors.blue,
              onTap: () => _copiarTexto(context),
            ),
            const SizedBox(height: 12),
            _buildOpcaoExportar(
              context,
              icon: Icons.share,
              titulo: 'Compartilhar via WhatsApp',
              descricao: 'Escolha compartilhar relatório completo ou somente CPS',
              cor: const Color(0xFF25D366),
              onTap: () => _compartilharWhatsApp(context),
            ),
            const SizedBox(height: 28),
            Text(
              'Backup & Restauração',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Salve seus dados antes de atualizar o app',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            _buildOpcaoExportar(
              context,
              icon: Icons.backup,
              titulo: 'Fazer Backup',
              descricao: 'Salvar todos os dados em um arquivo para restaurar depois',
              cor: Colors.indigo,
              onTap: () => _exportarBackup(context),
            ),
            const SizedBox(height: 12),
            _buildOpcaoExportar(
              context,
              icon: Icons.cloud_upload_outlined,
              titulo: 'Backup no Google Drive',
              descricao: 'Salvar dados no Drive da conta Google do usuário',
              cor: Colors.teal,
              onTap: () => _backupNuvem(context),
            ),
            const SizedBox(height: 12),
            _buildOpcaoExportar(
              context,
              icon: Icons.restore,
              titulo: 'Restaurar Backup',
              descricao: 'Importar dados de um backup anterior',
              cor: Colors.orange,
              onTap: () => _importarBackup(context),
            ),
            const SizedBox(height: 12),
            _buildOpcaoExportar(
              context,
              icon: Icons.cloud_download_outlined,
              titulo: 'Restaurar do Google Drive',
              descricao: 'Recuperar os dados salvos no Drive da conta Google',
              cor: Colors.blueGrey,
              onTap: () => _restaurarDaNuvem(context),
            ),
            const SizedBox(height: 12),
            _buildOpcaoExportar(
              context,
              icon: Icons.delete_forever,
              titulo: 'Excluir Conta e Dados',
              descricao:
                  'Remove conta, backup na nuvem e dados locais deste dispositivo',
              cor: AppTheme.errorColor,
              onTap: () => _excluirContaEDados(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcaoExportar(
    BuildContext context, {
    required IconData icon,
    required String titulo,
    required String descricao,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cor.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: cor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descricao,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha(14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportarPdf(BuildContext context) async {
    // Carregar imagens dos assets
    final logoBytes = await rootBundle.load('assets/images/logo_vc.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    final devIconBytes = await rootBundle.load('assets/images/icon_dev.png');
    final devIconImage = pw.MemoryImage(devIconBytes.buffer.asUint8List());

    final pdf = pw.Document();

    // === PÁGINAS DE CONTEÚDO ===
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Column(
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Image(logoImage, width: 40, height: 40),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'DEMANDA CONTROLLER',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.indigo900,
                            letterSpacing: 1,
                          ),
                        ),
                        pw.Text(
                          'Relatório de Demanda TSSR',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.indigo50,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.indigo200),
                    ),
                    child: pw.Text(
                      _formatDate(DateTime.now()),
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                height: 3,
                decoration: const pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    colors: [PdfColors.indigo900, PdfColors.blue400, PdfColors.indigo900],
                  ),
                ),
              ),
            ],
          ),
        ),
        build: (context) {
          final widgets = <pw.Widget>[];

          // Resumo global
          widgets.add(_pdfSecao('RESUMO GLOBAL', PdfColors.indigo900));
          widgets.add(pw.Row(
            children: [
              _pdfCard('Empresas', '${controller.empresas.length}', PdfColors.indigo),
              pw.SizedBox(width: 8),
              _pdfCard('Total Sites', '${controller.totalSitesGlobal}', PdfColors.blue800),
              pw.SizedBox(width: 8),
              _pdfCard('Concluídos', '${controller.sitesConcluidosGlobal}', PdfColors.green800),
              pw.SizedBox(width: 8),
              _pdfCard('Aguardando', '${controller.totalSitesGlobal - controller.sitesConcluidosGlobal}', PdfColors.amber800),
            ],
          ));
          widgets.add(pw.SizedBox(height: 12));
          widgets.add(_pdfLinhaValor('Valor Ganho Total', controller.valorGanhoGlobal, PdfColors.green800));
          widgets.add(_pdfLinhaValor('Total Adiantamentos', controller.totalAdiantamentosGlobal, PdfColors.blue800));
          widgets.add(_pdfLinhaValor('Lançamentos descontáveis', controller.totalLancamentosDescontaveisGlobal, PdfColors.red800));
          widgets.add(_pdfLinhaValor('Lançamentos não descontáveis', controller.totalLancamentosNaoDescontaveisGlobal, PdfColors.teal800));
          widgets.add(_pdfLinhaValor('Lançamentos previstos', controller.totalLancamentosPrevistosGlobal, PdfColors.amber800));
          widgets.add(pw.Divider(color: PdfColors.grey300));
          widgets.add(_pdfLinhaValorDestaque('A Receber Total', controller.valorReceberGlobal));
          widgets.add(pw.SizedBox(height: 6));
          widgets.add(_pdfLinhaValorDestaque('Saldo total com lançamentos', controller.valorReceberGlobalComLancamentos));
          widgets.add(pw.SizedBox(height: 24));

          // Cada empresa
          for (final emp in controller.empresas) {
            widgets.add(_pdfSecao('EMPRESA: ${emp.nome.toUpperCase()}', PdfColors.indigo900));

            // Info da empresa com badge
            widgets.add(pw.Container(
              padding: const pw.EdgeInsets.all(12),
              margin: const pw.EdgeInsets.only(bottom: 10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey200),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _pdfLinhaInfoCompact('Valor por Site', _formatCurrency(emp.valorPorSite)),
                      pw.SizedBox(height: 4),
                      _pdfLinhaInfoCompact('Adiantamento', emp.tipoAdiantamentoDescricao),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: emp.foiPago ? PdfColors.green100 : PdfColors.amber100,
                      borderRadius: pw.BorderRadius.circular(12),
                      border: pw.Border.all(
                        color: emp.foiPago ? PdfColors.green800 : PdfColors.amber800,
                      ),
                    ),
                    child: pw.Text(
                      emp.foiPago ? 'PAGO' : 'AGUARDANDO',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: emp.foiPago ? PdfColors.green900 : PdfColors.amber900,
                      ),
                    ),
                  ),
                ],
              ),
            ));

            widgets.add(pw.Row(
              children: [
                _pdfCard('Sites', '${emp.totalSites}', PdfColors.indigo),
                pw.SizedBox(width: 8),
                _pdfCard('OK', '${emp.sitesConcluidos}', PdfColors.green800),
                pw.SizedBox(width: 8),
                _pdfCard('OK Elegiveis', '${emp.sitesConcluidosElegiveisAdiantamento}', PdfColors.teal800),
                pw.SizedBox(width: 8),
                _pdfCard('Não OK', '${emp.sitesNaoConcluidos}', PdfColors.red800),
                pw.SizedBox(width: 8),
                _pdfCard('Aguard.', '${emp.sitesPendentes}', PdfColors.amber800),
              ],
            ));
            widgets.add(pw.SizedBox(height: 10));

            widgets.add(_pdfLinhaValor('Estimativa Total', emp.estimativaTotal, PdfColors.indigo));
            widgets.add(_pdfLinhaValor('Valor Ganho', emp.valorGanho, PdfColors.green800));
            widgets.add(_pdfLinhaValor('Valor Perdido', emp.valorPerdido, PdfColors.red800));
            widgets.add(_pdfLinhaValor('Total Adiantamentos', emp.totalAdiantamentos, PdfColors.blue800));
            widgets.add(_pdfLinhaValor('Lançamentos descontáveis', emp.totalLancamentosDescontaveis, PdfColors.red800));
            widgets.add(_pdfLinhaValor('Lançamentos não descontáveis', emp.totalLancamentosNaoDescontaveis, PdfColors.teal800));
            widgets.add(_pdfLinhaValor('Lançamentos previstos', emp.totalLancamentosPrevistos, PdfColors.amber800));
            widgets.add(pw.Divider(color: PdfColors.grey300));
            widgets.add(_pdfLinhaValorDestaque('A Receber', emp.valorReceberComAdiantamento));
            widgets.add(pw.SizedBox(height: 6));
            widgets.add(_pdfLinhaValorDestaque('Saldo com lançamentos', emp.saldoFinanceiroComLancamentos));
            widgets.add(pw.SizedBox(height: 12));

            // Legenda de status
            widgets.add(_pdfLegenda());
            widgets.add(pw.SizedBox(height: 6));

            // Tabela de sites profissional
            widgets.add(pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(28),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1.3),
                4: const pw.FlexColumnWidth(1.5),
                5: const pw.FlexColumnWidth(2.5),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.indigo900,
                    borderRadius: pw.BorderRadius.only(
                      topLeft: const pw.Radius.circular(6),
                      topRight: const pw.Radius.circular(6),
                    ),
                  ),
                  children: [
                    _pdfHeaderCell('#'),
                    _pdfHeaderCell('Site ID'),
                    _pdfHeaderCell('Status'),
                    _pdfHeaderCell('Valor'),
                    _pdfHeaderCell('Data'),
                    _pdfHeaderCell('Observação'),
                  ],
                ),
                ...List.generate(emp.sites.length, (i) {
                  final s = emp.sites[i];
                  PdfColor bgColor;
                  PdfColor accentColor;
                  PdfColor statusTextColor;
                  String statusText;
                  String statusIcon;

                  switch (s.status) {
                    case SiteStatus.concluido:
                      bgColor = const PdfColor.fromInt(0xFFE8F5E9);
                      accentColor = PdfColors.green800;
                      statusTextColor = PdfColors.green900;
                      statusText = 'CONCLUIDO';
                      statusIcon = '[OK]';
                      break;
                    case SiteStatus.naoConcluido:
                      bgColor = const PdfColor.fromInt(0xFFFFEBEE);
                      accentColor = PdfColors.red700;
                      statusTextColor = PdfColors.red900;
                      statusText = 'NAO CONCL.';
                      statusIcon = '[X]';
                      break;
                    case SiteStatus.pendente:
                      bgColor = const PdfColor.fromInt(0xFFFFF8E1);
                      accentColor = PdfColors.amber700;
                      statusTextColor = PdfColors.amber900;
                      statusText = 'AGUARDANDO';
                      statusIcon = '[...]';
                      break;
                  }

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: bgColor,
                      border: pw.Border(
                        left: pw.BorderSide(color: accentColor, width: 3),
                      ),
                    ),
                    children: [
                      _pdfDataCell('${i + 1}', align: pw.Alignment.center),
                      _pdfDataCell(
                        s.participaAdiantamento ? s.siteId : '${s.siteId} [SEM ADIANT.]',
                        bold: true,
                        color: s.participaAdiantamento ? PdfColors.black : PdfColors.blueGrey900,
                      ),
                      _pdfStatusBadge(statusIcon, statusText, accentColor, statusTextColor),
                      _pdfDataCell(
                        s.isConcluido ? _formatCurrency(emp.valorPorSite) : '-',
                        color: s.isConcluido ? PdfColors.green900 : PdfColors.grey500,
                        bold: s.isConcluido,
                      ),
                      _pdfDataCell(
                        s.dataConclusao != null ? _formatDate(s.dataConclusao!) : '-',
                        color: PdfColors.grey700,
                      ),
                      _pdfDataCell(
                        s.motivoNaoConcluido.isNotEmpty ? s.motivoNaoConcluido : '',
                        color: s.isNaoConcluido ? PdfColors.red800 : PdfColors.grey600,
                        italic: s.isNaoConcluido,
                      ),
                    ],
                  );
                }),
              ],
            ));

            // Adiantamentos da empresa
            if (emp.adiantamentos.isNotEmpty) {
              widgets.add(pw.SizedBox(height: 12));
              widgets.add(_pdfSecaoInline('ADIANTAMENTOS'));
              widgets.add(pw.SizedBox(height: 4));
              widgets.add(pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
                cellStyle: const pw.TextStyle(fontSize: 8),
                headerPadding: const pw.EdgeInsets.all(6),
                cellPadding: const pw.EdgeInsets.all(5),
                headers: ['#', 'Valor', 'Data', 'Status', 'Observação'],
                data: List.generate(emp.adiantamentos.length, (i) {
                  final a = emp.adiantamentos[i];
                  return [
                    '${i + 1}',
                    _formatCurrency(a.valor),
                    _formatDate(a.data),
                    a.foiPago ? '[OK] PAGO' : '[...] AGUARDANDO',
                    a.observacao,
                  ];
                }),
              ));
            }

            widgets.add(pw.SizedBox(height: 24));
          }

          // === RELATÓRIO DIÁRIO (mais recente) ===
          if (controller.relatorios.isNotEmpty) {
            final relatorio = controller.relatorios.first;
            final feitos = relatorio.sitesFeitos;
            final naoFeitos = relatorio.sitesNaoFeitos;
            final pendentes = relatorio.sites.where((s) => !s.feito && s.motivo.isEmpty).length;

            widgets.add(_pdfSecao('RELATÓRIO DIÁRIO - ${_formatDate(relatorio.data)}', PdfColors.teal900));

            // Info do relatório
            if (relatorio.operadora.isNotEmpty || relatorio.fabricante.isNotEmpty || relatorio.projeto.isNotEmpty || relatorio.regiao.isNotEmpty) {
              widgets.add(pw.Container(
                padding: const pw.EdgeInsets.all(10),
                margin: const pw.EdgeInsets.only(bottom: 10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.teal200),
                ),
                child: pw.Row(
                  children: [
                    if (relatorio.operadora.isNotEmpty)
                      _pdfLinhaInfoCompact('Operadora', relatorio.operadora),
                    if (relatorio.fabricante.isNotEmpty) ...[pw.SizedBox(width: 16), _pdfLinhaInfoCompact('Fabricante', relatorio.fabricante)],
                    if (relatorio.projeto.isNotEmpty) ...[pw.SizedBox(width: 16), _pdfLinhaInfoCompact('Projeto', relatorio.projeto)],
                    if (relatorio.regiao.isNotEmpty) ...[pw.SizedBox(width: 16), _pdfLinhaInfoCompact('Região', relatorio.regiao)],
                  ],
                ),
              ));
            }

            widgets.add(pw.Row(
              children: [
                _pdfCard('Total', '${relatorio.sites.length}', PdfColors.teal),
                pw.SizedBox(width: 8),
                _pdfCard('Feitos', '${feitos.length}', PdfColors.green800),
                pw.SizedBox(width: 8),
                _pdfCard('Problemas', '${naoFeitos.length}', PdfColors.red800),
                pw.SizedBox(width: 8),
                _pdfCard('Pendentes', '$pendentes', PdfColors.amber800),
              ],
            ));
            widgets.add(pw.SizedBox(height: 10));

            // Legenda de status do relatório
            widgets.add(_pdfLegendaRelatorio());
            widgets.add(pw.SizedBox(height: 6));

            // Tabela de sites do relatório diário
            widgets.add(pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(28),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(3),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.teal900,
                    borderRadius: pw.BorderRadius.only(
                      topLeft: const pw.Radius.circular(6),
                      topRight: const pw.Radius.circular(6),
                    ),
                  ),
                  children: [
                    _pdfHeaderCell('#'),
                    _pdfHeaderCell('Site ID'),
                    _pdfHeaderCell('Status'),
                    _pdfHeaderCell('Data'),
                    _pdfHeaderCell('Motivo / Observação'),
                  ],
                ),
                ...List.generate(relatorio.sites.length, (i) {
                  final s = relatorio.sites[i];
                  PdfColor bgColor;
                  PdfColor accentColor;
                  PdfColor statusTextColor;
                  String statusText;
                  String statusIcon;

                  if (s.feito) {
                    bgColor = const PdfColor.fromInt(0xFFE8F5E9);
                    accentColor = PdfColors.green800;
                    statusTextColor = PdfColors.green900;
                    statusText = 'FEITO';
                    statusIcon = '[OK]';
                  } else if (s.motivo.isNotEmpty) {
                    bgColor = const PdfColor.fromInt(0xFFFFEBEE);
                    accentColor = PdfColors.red700;
                    statusTextColor = PdfColors.red900;
                    statusText = 'PROBLEMA';
                    statusIcon = '[X]';
                  } else {
                    bgColor = const PdfColor.fromInt(0xFFFFF8E1);
                    accentColor = PdfColors.amber700;
                    statusTextColor = PdfColors.amber900;
                    statusText = 'PENDENTE';
                    statusIcon = '[...]';
                  }

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: bgColor,
                      border: pw.Border(
                        left: pw.BorderSide(color: accentColor, width: 3),
                      ),
                    ),
                    children: [
                      _pdfDataCell('${i + 1}', align: pw.Alignment.center),
                      _pdfDataCell(s.siteId, bold: true),
                      _pdfStatusBadge(statusIcon, statusText, accentColor, statusTextColor),
                      _pdfDataCell(
                        s.dataExecucao != null ? _formatDate(s.dataExecucao!) : '-',
                        color: PdfColors.grey700,
                      ),
                      _pdfDataCell(
                        s.motivo.isNotEmpty ? s.motivo : '',
                        color: s.motivo.isNotEmpty ? PdfColors.red800 : PdfColors.grey600,
                        italic: s.motivo.isNotEmpty,
                      ),
                    ],
                  );
                }),
              ],
            ));
            widgets.add(pw.SizedBox(height: 24));
          }

          return widgets;
        },
        footer: (context) => pw.Container(
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.indigo200, width: 1.5)),
          ),
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(3),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.indigo200, width: 0.5),
                ),
                child: pw.Image(devIconImage, width: 16, height: 16),
              ),
              pw.SizedBox(width: 6),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'VJC TECHNOLOGY',
                    style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900, letterSpacing: 1),
                  ),
                  pw.Text(
                    'Soluções Inteligentes em Telecom',
                    style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey600),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Text(
                  'v1.0',
                  style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo900,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Relatorio_Demanda_TSSR_${_formatDateFile(DateTime.now())}.pdf',
    );
  }

  pw.Widget _pdfSecao(String titulo, PdfColor cor) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: cor,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        titulo,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          letterSpacing: 1,
        ),
      ),
    );
  }

  pw.Widget _pdfSecaoInline(String titulo) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Text(
        titulo,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
    );
  }

  pw.Widget _pdfLinhaInfoCompact(String label, String valor) {
    return pw.Row(
      children: [
        pw.Text('$label: ', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.Text(valor, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  pw.Widget _pdfCard(String label, String valor, PdfColor cor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: cor,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.white)),
            pw.SizedBox(height: 3),
            pw.Text(valor, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
          ],
        ),
      ),
    );
  }

  pw.Widget _pdfLinhaValor(String label, double valor, PdfColor cor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
          pw.Text(
            _formatCurrency(valor),
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: cor),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfLinhaValorDestaque(String label, double valor) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 4),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.green800),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Text(
            _formatCurrency(valor),
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  EXCEL — ESTILOS PROFISSIONAIS
  // ═══════════════════════════════════════════════════════════

  static final _darkNavy = ExcelColor.fromHexString('#FF0D1642');
  static final _indigo = ExcelColor.fromHexString('#FF1A237E');
  static final _accentBlue = ExcelColor.fromHexString('#FF42A5F5');
  static final _accentGold = ExcelColor.fromHexString('#FFFFD54F');
  static final _greenBg = ExcelColor.fromHexString('#FFE8F5E9');
  static final _greenText = ExcelColor.fromHexString('#FF2E7D32');
  static final _redBg = ExcelColor.fromHexString('#FFFFEBEE');
  static final _redText = ExcelColor.fromHexString('#FFC62828');
  static final _amberBg = ExcelColor.fromHexString('#FFFFF8E1');
  static final _amberText = ExcelColor.fromHexString('#FFF57F17');
  static final _lightGrey = ExcelColor.fromHexString('#FFF5F5F5');
  static final _medGrey = ExcelColor.fromHexString('#FFE0E0E0');
  static final _darkText = ExcelColor.fromHexString('#FF212121');
  static final _subText = ExcelColor.fromHexString('#FF616161');

  static final _thinBorder = Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.fromHexString('#FFE0E0E0'));
  static final _mediumBorder = Border(borderStyle: BorderStyle.Medium, borderColorHex: ExcelColor.fromHexString('#FF1A237E'));

  CellStyle _xlsTitleStyle() => CellStyle(
    fontFamily: 'Calibri',
    fontSize: 18,
    bold: true,
    fontColorHex: ExcelColor.white,
    backgroundColorHex: _darkNavy,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  CellStyle _xlsSubtitleStyle() => CellStyle(
    fontFamily: 'Calibri',
    fontSize: 11,
    fontColorHex: _accentBlue,
    backgroundColorHex: _darkNavy,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  CellStyle _xlsSectionStyle() => CellStyle(
    fontFamily: 'Calibri',
    fontSize: 13,
    bold: true,
    fontColorHex: ExcelColor.white,
    backgroundColorHex: _indigo,
    horizontalAlign: HorizontalAlign.Left,
    verticalAlign: VerticalAlign.Center,
    bottomBorder: _mediumBorder,
  );

  CellStyle _xlsHeaderStyle() => CellStyle(
    fontFamily: 'Calibri',
    fontSize: 10,
    bold: true,
    fontColorHex: ExcelColor.white,
    backgroundColorHex: _indigo,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    topBorder: _thinBorder,
    bottomBorder: Border(borderStyle: BorderStyle.Medium, borderColorHex: _accentGold),
    leftBorder: _thinBorder,
    rightBorder: _thinBorder,
  );

  CellStyle _xlsLabelStyle() => CellStyle(
    fontFamily: 'Calibri',
    fontSize: 10,
    bold: true,
    fontColorHex: _darkText,
    backgroundColorHex: _lightGrey,
    horizontalAlign: HorizontalAlign.Left,
    verticalAlign: VerticalAlign.Center,
    leftBorder: _mediumBorder,
    bottomBorder: _thinBorder,
    rightBorder: _thinBorder,
  );

  CellStyle _xlsValueStyle({ExcelColor? bgColor, ExcelColor? fontColor, bool bold = false, HorizontalAlign align = HorizontalAlign.Center}) => CellStyle(
    fontFamily: 'Calibri',
    fontSize: 10,
    bold: bold,
    fontColorHex: fontColor ?? _darkText,
    backgroundColorHex: bgColor ?? ExcelColor.none,
    horizontalAlign: align,
    verticalAlign: VerticalAlign.Center,
    bottomBorder: _thinBorder,
    leftBorder: _thinBorder,
    rightBorder: _thinBorder,
  );

  CellStyle _xlsMoneyStyle({ExcelColor? bgColor, ExcelColor? fontColor, bool bold = false}) => CellStyle(
    fontFamily: 'Calibri',
    fontSize: 10,
    bold: bold,
    fontColorHex: fontColor ?? _darkText,
    backgroundColorHex: bgColor ?? ExcelColor.none,
    horizontalAlign: HorizontalAlign.Right,
    verticalAlign: VerticalAlign.Center,
    bottomBorder: _thinBorder,
    leftBorder: _thinBorder,
    rightBorder: _thinBorder,
    numberFormat: NumFormat.standard_2,
  );

  CellStyle _xlsHighlightStyle() => CellStyle(
    fontFamily: 'Calibri',
    fontSize: 11,
    bold: true,
    fontColorHex: ExcelColor.white,
    backgroundColorHex: ExcelColor.fromHexString('#FF1B5E20'),
    horizontalAlign: HorizontalAlign.Right,
    verticalAlign: VerticalAlign.Center,
    topBorder: Border(borderStyle: BorderStyle.Medium, borderColorHex: _accentGold),
    bottomBorder: Border(borderStyle: BorderStyle.Medium, borderColorHex: _accentGold),
    leftBorder: _thinBorder,
    rightBorder: _thinBorder,
    numberFormat: NumFormat.standard_2,
  );

  CellStyle _xlsHighlightLabelStyle() => CellStyle(
    fontFamily: 'Calibri',
    fontSize: 11,
    bold: true,
    fontColorHex: ExcelColor.white,
    backgroundColorHex: ExcelColor.fromHexString('#FF1B5E20'),
    horizontalAlign: HorizontalAlign.Left,
    verticalAlign: VerticalAlign.Center,
    topBorder: Border(borderStyle: BorderStyle.Medium, borderColorHex: _accentGold),
    bottomBorder: Border(borderStyle: BorderStyle.Medium, borderColorHex: _accentGold),
    leftBorder: _mediumBorder,
    rightBorder: _thinBorder,
  );

  CellStyle _xlsFooterStyle() => CellStyle(
    fontFamily: 'Calibri',
    fontSize: 8,
    italic: true,
    fontColorHex: _subText,
    backgroundColorHex: _lightGrey,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
  );

  void _xlsApplyRowStyle(Sheet sheet, int row, int cols, CellStyle style) {
    for (int c = 0; c < cols; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
      cell.cellStyle = style;
    }
  }

  void _xlsSetColumnWidths(Sheet sheet, List<double> widths) {
    for (int i = 0; i < widths.length; i++) {
      sheet.setColumnWidth(i, widths[i]);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  EXCEL — GERADOR PRINCIPAL
  // ═══════════════════════════════════════════════════════════

  Future<void> _exportarExcel(BuildContext context) async {
    final excel = Excel.createExcel();
    final now = DateTime.now();

    // ─── ABA: RESUMO GLOBAL ───────────────────────────────
    final resumo = excel['RESUMO GLOBAL'];
    _xlsSetColumnWidths(resumo, [5, 30, 18, 18, 18, 18]);
    resumo.setDefaultRowHeight(22);

    // Header Band (row 0-1)
    int r = 0;
    resumo.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('F1'),
        customValue: TextCellValue('DEMANDA CONTROLLER'));
    resumo.setRowHeight(r, 40);
    _xlsApplyRowStyle(resumo, r, 6, _xlsTitleStyle());
    r++;

    resumo.merge(CellIndex.indexByString('A2'), CellIndex.indexByString('F2'),
        customValue: TextCellValue('Relatorio de Demanda TSSR  |  ${_formatDate(now)}  |  VJC Technology'));
    resumo.setRowHeight(r, 24);
    _xlsApplyRowStyle(resumo, r, 6, _xlsSubtitleStyle());
    r++;

    // Spacer
    resumo.setRowHeight(r, 10);
    r++;

    // Section: RESUMO GLOBAL
    resumo.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r), CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: r),
        customValue: TextCellValue('  RESUMO GLOBAL'));
    resumo.setRowHeight(r, 28);
    _xlsApplyRowStyle(resumo, r, 6, _xlsSectionStyle());
    r++;

    // KPIs - 4 cards side by side
    resumo.setRowHeight(r, 14);
    r++;

    // KPI Headers
    final kpiHeaders = ['EMPRESAS', 'TOTAL SITES', 'CONCLUIDOS', 'A RECEBER'];
    final kpiValues = [
      '${controller.empresas.length}',
      '${controller.totalSitesGlobal}',
      '${controller.sitesConcluidosGlobal}',
      _formatCurrency(controller.valorReceberGlobal),
    ];
    final kpiColors = [_indigo, _accentBlue, _greenText, ExcelColor.fromHexString('#FF1B5E20')];

    for (int i = 0; i < 4; i++) {
      final col = i + 1;
      final headerCell = resumo.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: r));
      headerCell.value = TextCellValue(kpiHeaders[i]);
      headerCell.cellStyle = CellStyle(
        fontFamily: 'Calibri', fontSize: 8, bold: true,
        fontColorHex: ExcelColor.white, backgroundColorHex: kpiColors[i],
        horizontalAlign: HorizontalAlign.Center, verticalAlign: VerticalAlign.Center,
        topBorder: _thinBorder, leftBorder: _thinBorder, rightBorder: _thinBorder,
      );
    }
    resumo.setRowHeight(r, 20);
    r++;

    for (int i = 0; i < 4; i++) {
      final col = i + 1;
      final valCell = resumo.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: r));
      valCell.value = TextCellValue(kpiValues[i]);
      valCell.cellStyle = CellStyle(
        fontFamily: 'Calibri', fontSize: 14, bold: true,
        fontColorHex: kpiColors[i], backgroundColorHex: _lightGrey,
        horizontalAlign: HorizontalAlign.Center, verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Medium, borderColorHex: kpiColors[i]),
        leftBorder: _thinBorder, rightBorder: _thinBorder,
      );
    }
    resumo.setRowHeight(r, 30);
    r++;

    // Spacer
    resumo.setRowHeight(r, 10);
    r++;

    // Financial Details
    final financialData = [
      ['Valor Ganho Total', controller.valorGanhoGlobal, _greenText],
      ['Total Adiantamentos', controller.totalAdiantamentosGlobal, _accentBlue],
      ['Lançamentos descontáveis', controller.totalLancamentosDescontaveisGlobal, _redText],
      ['Lançamentos não descontáveis', controller.totalLancamentosNaoDescontaveisGlobal, _greenText],
      ['Lançamentos previstos', controller.totalLancamentosPrevistosGlobal, _amberText],
    ];

    for (final item in financialData) {
      final labelCell = resumo.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r));
      labelCell.value = TextCellValue(item[0] as String);
      labelCell.cellStyle = _xlsLabelStyle();

      resumo.merge(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r), CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r),
          customValue: DoubleCellValue(item[1] as double));
      final valCell = resumo.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r));
      valCell.cellStyle = _xlsMoneyStyle(fontColor: item[2] as ExcelColor, bold: true);

      resumo.setRowHeight(r, 22);
      r++;
    }

    // Highlight: A RECEBER
    final lblCell = resumo.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r));
    lblCell.value = TextCellValue('A RECEBER TOTAL');
    lblCell.cellStyle = _xlsHighlightLabelStyle();

    resumo.merge(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r), CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r),
        customValue: DoubleCellValue(controller.valorReceberGlobal));
    final highlightCell = resumo.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r));
    highlightCell.cellStyle = _xlsHighlightStyle();
    resumo.setRowHeight(r, 28);
    r++;

    final lblSaldo = resumo.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r));
    lblSaldo.value = TextCellValue('SALDO COM LANCAMENTOS');
    lblSaldo.cellStyle = _xlsHighlightLabelStyle();

    resumo.merge(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r), CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r),
      customValue: DoubleCellValue(controller.valorReceberGlobalComLancamentos));
    final saldoCell = resumo.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r));
    saldoCell.cellStyle = _xlsHighlightStyle();
    resumo.setRowHeight(r, 28);
    r++;

    // Spacer
    resumo.setRowHeight(r, 10);
    r++;

    // Table: per company summary
    resumo.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r), CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: r),
        customValue: TextCellValue('  DETALHAMENTO POR EMPRESA'));
    resumo.setRowHeight(r, 28);
    _xlsApplyRowStyle(resumo, r, 6, _xlsSectionStyle());
    r++;

    final compHeaders = ['EMPRESA', 'SITES', 'CONCL.', 'VALOR GANHO', 'ADIANT.', 'SALDO COM LANCAMENTOS'];
    for (int c = 0; c < compHeaders.length; c++) {
      final cell = resumo.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r));
      cell.value = TextCellValue(compHeaders[c]);
      cell.cellStyle = _xlsHeaderStyle();
    }
    resumo.setRowHeight(r, 24);
    r++;

    for (int i = 0; i < controller.empresas.length; i++) {
      final emp = controller.empresas[i];
      final isEven = i % 2 == 0;
      final bg = isEven ? _lightGrey : ExcelColor.none;

      final rowData = [
        TextCellValue(emp.nome),
        IntCellValue(emp.totalSites),
        IntCellValue(emp.sitesConcluidos),
        DoubleCellValue(emp.valorGanho),
        DoubleCellValue(emp.totalAdiantamentos),
        DoubleCellValue(emp.saldoFinanceiroComLancamentos),
      ];

      for (int c = 0; c < rowData.length; c++) {
        final cell = resumo.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r));
        cell.value = rowData[c];
        if (c == 0) {
          cell.cellStyle = _xlsValueStyle(bgColor: bg, bold: true, align: HorizontalAlign.Left);
        } else if (c >= 3) {
          cell.cellStyle = _xlsMoneyStyle(bgColor: bg, fontColor: c == 5 ? _greenText : null, bold: c == 5);
        } else {
          cell.cellStyle = _xlsValueStyle(bgColor: bg);
        }
      }
      resumo.setRowHeight(r, 22);
      r++;
    }

    // Spacer
    r++;
    resumo.setRowHeight(r, 10);
    r++;

    // Footer
    resumo.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r), CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: r),
        customValue: TextCellValue('DEMANDA CONTROLLER v1.0  |  VJC Technology - Solucoes em Telecom  |  Gerado em ${_formatDate(now)}'));
    _xlsApplyRowStyle(resumo, r, 6, _xlsFooterStyle());
    resumo.setRowHeight(r, 18);

    // ─── ABA POR EMPRESA ──────────────────────────────────
    for (final emp in controller.empresas) {
      final sheet = excel[emp.nome];
      _xlsSetColumnWidths(sheet, [5, 22, 18, 16, 14, 14, 26]);
      sheet.setDefaultRowHeight(20);

      int row = 0;

      // Header
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row), CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row),
          customValue: TextCellValue(emp.nome.toUpperCase()));
      sheet.setRowHeight(row, 36);
      _xlsApplyRowStyle(sheet, row, 7, _xlsTitleStyle());
      row++;

      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row), CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row),
          customValue: TextCellValue('R\$ ${emp.valorPorSite.toStringAsFixed(2).replaceAll('.', ',')}/site  |  ${emp.tipoAdiantamentoDescricao}  |  ${emp.foiPago ? "PAGO" : "AGUARDANDO PAGAMENTO"}'));
      sheet.setRowHeight(row, 22);
      _xlsApplyRowStyle(sheet, row, 7, _xlsSubtitleStyle());
      row++;

      sheet.setRowHeight(row, 8);
      row++;

      // KPI Cards
      final empKpiH = ['TOTAL', 'CONCLUIDOS', 'NAO CONCL.', 'AGUARDANDO'];
      final empKpiV = ['${emp.totalSites}', '${emp.sitesConcluidos}', '${emp.sitesNaoConcluidos}', '${emp.sitesPendentes}'];
      final empKpiC = [_indigo, _greenText, _redText, _amberText];

      for (int i = 0; i < 4; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i + 1, rowIndex: row));
        cell.value = TextCellValue(empKpiH[i]);
        cell.cellStyle = CellStyle(
          fontFamily: 'Calibri', fontSize: 8, bold: true,
          fontColorHex: ExcelColor.white, backgroundColorHex: empKpiC[i],
          horizontalAlign: HorizontalAlign.Center, verticalAlign: VerticalAlign.Center,
          topBorder: _thinBorder, leftBorder: _thinBorder, rightBorder: _thinBorder,
        );
      }
      sheet.setRowHeight(row, 18);
      row++;

      for (int i = 0; i < 4; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i + 1, rowIndex: row));
        cell.value = TextCellValue(empKpiV[i]);
        cell.cellStyle = CellStyle(
          fontFamily: 'Calibri', fontSize: 16, bold: true,
          fontColorHex: empKpiC[i], backgroundColorHex: _lightGrey,
          horizontalAlign: HorizontalAlign.Center, verticalAlign: VerticalAlign.Center,
          bottomBorder: Border(borderStyle: BorderStyle.Medium, borderColorHex: empKpiC[i]),
          leftBorder: _thinBorder, rightBorder: _thinBorder,
        );
      }
      sheet.setRowHeight(row, 32);
      row++;

      sheet.setRowHeight(row, 8);
      row++;

      // Financial Summary
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row), CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row),
          customValue: TextCellValue('  FINANCEIRO'));
      sheet.setRowHeight(row, 26);
      _xlsApplyRowStyle(sheet, row, 7, _xlsSectionStyle());
      row++;

      final finItems = [
        ['Estimativa Total', emp.estimativaTotal, _darkText],
        ['Valor Ganho', emp.valorGanho, _greenText],
        ['Valor Perdido', emp.valorPerdido, _redText],
        ['Total Adiantamentos', emp.totalAdiantamentos, _accentBlue],
        ['Lançamentos descontáveis', emp.totalLancamentosDescontaveis, _redText],
        ['Lançamentos não descontáveis', emp.totalLancamentosNaoDescontaveis, _greenText],
        ['Lançamentos previstos', emp.totalLancamentosPrevistos, _amberText],
      ];

      for (final item in finItems) {
        final lbl = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
        lbl.value = TextCellValue(item[0] as String);
        lbl.cellStyle = _xlsLabelStyle();

        sheet.merge(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row), CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
            customValue: DoubleCellValue(item[1] as double));
        final val = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));
        val.cellStyle = _xlsMoneyStyle(fontColor: item[2] as ExcelColor, bold: true);
        sheet.setRowHeight(row, 22);
        row++;
      }

      // Highlight A Receber
      final aRecLbl = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
      aRecLbl.value = TextCellValue('A RECEBER');
      aRecLbl.cellStyle = _xlsHighlightLabelStyle();
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row), CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
          customValue: DoubleCellValue(emp.valorReceberComAdiantamento));
      final aRecVal = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));
      aRecVal.cellStyle = _xlsHighlightStyle();
      sheet.setRowHeight(row, 28);
      row++;

        final saldoLbl = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
        saldoLbl.value = TextCellValue('SALDO COM LANCAMENTOS');
        saldoLbl.cellStyle = _xlsHighlightLabelStyle();
        sheet.merge(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row), CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
          customValue: DoubleCellValue(emp.saldoFinanceiroComLancamentos));
        final saldoVal = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));
        saldoVal.cellStyle = _xlsHighlightStyle();
        sheet.setRowHeight(row, 28);
        row++;

      sheet.setRowHeight(row, 8);
      row++;

      // Sites Table
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row), CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row),
          customValue: TextCellValue('  SITES'));
      sheet.setRowHeight(row, 26);
      _xlsApplyRowStyle(sheet, row, 7, _xlsSectionStyle());
      row++;

      final siteHeaders = ['#', 'SITE ID', 'STATUS', 'VALOR (R\$)', 'DATA', 'PROGRESSO', 'OBSERVACAO'];
      for (int c = 0; c < siteHeaders.length; c++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
        cell.value = TextCellValue(siteHeaders[c]);
        cell.cellStyle = _xlsHeaderStyle();
      }
      sheet.setRowHeight(row, 24);
      row++;

      for (int i = 0; i < emp.sites.length; i++) {
        final s = emp.sites[i];
        String status;
        ExcelColor statusBg;
        ExcelColor statusFg;
        String progress;

        switch (s.status) {
          case SiteStatus.concluido:
            status = 'CONCLUIDO';
            statusBg = _greenBg;
            statusFg = _greenText;
            progress = '>>>>>>>>>>  100%';
            break;
          case SiteStatus.naoConcluido:
            status = 'NAO CONCLUIDO';
            statusBg = _redBg;
            statusFg = _redText;
            progress = 'XXXXXXXXXX  FAIL';
            break;
          case SiteStatus.pendente:
            status = 'AGUARDANDO';
            statusBg = _amberBg;
            statusFg = _amberText;
            progress = '..........  0%';
            break;
        }

        final rowValues = <CellValue>[
          IntCellValue(i + 1),
          TextCellValue(s.participaAdiantamento ? s.siteId : '${s.siteId} [SEM ADIANT.]'),
          TextCellValue(status),
          DoubleCellValue(s.isConcluido ? emp.valorPorSite : 0.0),
          TextCellValue(s.dataConclusao != null ? _formatDate(s.dataConclusao!) : '-'),
          TextCellValue(progress),
          TextCellValue(s.motivoNaoConcluido),
        ];

        for (int c = 0; c < rowValues.length; c++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
          cell.value = rowValues[c];

          if (c == 2) {
            // Status cell with colored bg
            cell.cellStyle = CellStyle(
              fontFamily: 'Calibri', fontSize: 9, bold: true,
              fontColorHex: statusFg, backgroundColorHex: statusBg,
              horizontalAlign: HorizontalAlign.Center, verticalAlign: VerticalAlign.Center,
              bottomBorder: _thinBorder, leftBorder: _thinBorder, rightBorder: _thinBorder,
            );
          } else if (c == 3) {
            cell.cellStyle = _xlsMoneyStyle(
              bgColor: i % 2 == 0 ? _lightGrey : ExcelColor.none,
              fontColor: s.isConcluido ? _greenText : _subText,
              bold: s.isConcluido,
            );
          } else if (c == 5) {
            // Progress bar cell
            cell.cellStyle = CellStyle(
              fontFamily: 'Consolas', fontSize: 8,
              fontColorHex: statusFg, backgroundColorHex: i % 2 == 0 ? _lightGrey : ExcelColor.none,
              horizontalAlign: HorizontalAlign.Center, verticalAlign: VerticalAlign.Center,
              bottomBorder: _thinBorder, leftBorder: _thinBorder, rightBorder: _thinBorder,
            );
          } else if (c == 1) {
            cell.cellStyle = _xlsValueStyle(bgColor: i % 2 == 0 ? _lightGrey : ExcelColor.none, bold: true, align: HorizontalAlign.Left);
          } else {
            cell.cellStyle = _xlsValueStyle(bgColor: i % 2 == 0 ? _lightGrey : ExcelColor.none);
          }
        }
        sheet.setRowHeight(row, 22);
        row++;
      }

      // Adiantamentos
      if (emp.adiantamentos.isNotEmpty) {
        sheet.setRowHeight(row, 8);
        row++;

        sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row), CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row),
            customValue: TextCellValue('  ADIANTAMENTOS'));
        sheet.setRowHeight(row, 26);
        _xlsApplyRowStyle(sheet, row, 7, _xlsSectionStyle());
        row++;

        final adHeaders = ['#', 'VALOR (R\$)', 'DATA', 'STATUS', 'OBSERVACAO'];
        for (int c = 0; c < adHeaders.length; c++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row));
          cell.value = TextCellValue(adHeaders[c]);
          cell.cellStyle = _xlsHeaderStyle();
        }
        sheet.setRowHeight(row, 24);
        row++;

        for (int i = 0; i < emp.adiantamentos.length; i++) {
          final a = emp.adiantamentos[i];
          final isEven = i % 2 == 0;
          final bg = isEven ? _lightGrey : ExcelColor.none;

          final cell0 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
          cell0.value = IntCellValue(i + 1);
          cell0.cellStyle = _xlsValueStyle(bgColor: bg);

          final cell1 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
          cell1.value = DoubleCellValue(a.valor);
          cell1.cellStyle = _xlsMoneyStyle(bgColor: bg, bold: true);

          final cell2 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));
          cell2.value = TextCellValue(_formatDate(a.data));
          cell2.cellStyle = _xlsValueStyle(bgColor: bg);

          final cell3 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));
          cell3.value = TextCellValue(a.foiPago ? 'PAGO' : 'PENDENTE');
          cell3.cellStyle = CellStyle(
            fontFamily: 'Calibri', fontSize: 9, bold: true,
            fontColorHex: a.foiPago ? _greenText : _amberText,
            backgroundColorHex: a.foiPago ? _greenBg : _amberBg,
            horizontalAlign: HorizontalAlign.Center, verticalAlign: VerticalAlign.Center,
            bottomBorder: _thinBorder, leftBorder: _thinBorder, rightBorder: _thinBorder,
          );

          final cell4 = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row));
          cell4.value = TextCellValue(a.observacao);
          cell4.cellStyle = _xlsValueStyle(bgColor: bg, align: HorizontalAlign.Left);

          sheet.setRowHeight(row, 22);
          row++;
        }
      }

      // Footer
      row++;
      sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row), CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row),
          customValue: TextCellValue('DEMANDA CONTROLLER v1.0  |  VJC Technology  |  ${_formatDate(now)}'));
      _xlsApplyRowStyle(sheet, row, 7, _xlsFooterStyle());
      sheet.setRowHeight(row, 18);
    }

    // Remover sheet padrao
    excel.delete('Sheet1');

    final bytes = excel.save();
    if (bytes == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'Relatorio_Demanda_TSSR_${_formatDateFile(DateTime.now())}.xlsx';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    if (context.mounted) {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Relatório TSSR',
      );
    }
  }

  void _copiarTexto(BuildContext context) {
    final texto = controller.gerarTextoCompartilhamento();
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Relatório copiado para área de transferência!'),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _compartilharWhatsApp(BuildContext context) async {
    final tipo = await showModalBottomSheet<_TipoCompartilhamento>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const Text(
                'Como deseja compartilhar?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.description_outlined,
                    color: AppTheme.primaryColor),
                title: const Text('Relatório completo'),
                subtitle: const Text('Resumo geral com empresas e sites'),
                onTap: () => Navigator.pop(ctx, _TipoCompartilhamento.relatorio),
              ),
              ListTile(
                leading: const Icon(Icons.filter_1,
                    color: AppTheme.accentColor),
                title: const Text('Somente um CPS (lote específico)'),
                subtitle: const Text('Escolha o lote que deseja enviar'),
                onTap: () => Navigator.pop(ctx, _TipoCompartilhamento.cpsUnico),
              ),
              ListTile(
                leading: const Icon(Icons.layers_outlined,
                    color: AppTheme.successColor),
                title: const Text('Todos os CPS'),
                subtitle: const Text('Envia todos os lotes de todas as empresas'),
                onTap: () => Navigator.pop(ctx, _TipoCompartilhamento.cpsTodos),
              ),
            ],
          ),
        ),
      ),
    );

    if (tipo == null) return;

    if (tipo == _TipoCompartilhamento.relatorio) {
      final texto = controller.gerarTextoCompartilhamento();
      Share.share(texto, subject: 'Relatório Demanda TSSR');
      return;
    }

    final lotesDisponiveis = _listarLotesCpsDisponiveis();
    if (lotesDisponiveis.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Não há CPS/lotes registrados para compartilhar.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    if (tipo == _TipoCompartilhamento.cpsTodos) {
      final texto = _gerarTextoCpsTodosLotes();
      Share.share(texto, subject: 'CPS - Todos os Lotes');
      return;
    }

    final loteSelecionado = await showDialog<_CpsLoteOpcao>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selecionar CPS'),
        content: SizedBox(
          width: 420,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: lotesDisponiveis.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final lote = lotesDisponiveis[i];
              return ListTile(
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primaryColor.withAlpha(20),
                  child: Text(
                    '${lote.posicao + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                title: Text('${lote.empresaNome} • ${lote.titulo}'),
                subtitle: Text(
                  'A receber: ${_formatCurrency(lote.valorReceber)}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                onTap: () => Navigator.pop(ctx, lote),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (loteSelecionado == null) return;

    final texto = _gerarTextoCpsLote(loteSelecionado);
    Share.share(texto, subject: 'CPS ${loteSelecionado.titulo}');
  }

  List<_CpsLoteOpcao> _listarLotesCpsDisponiveis() {
    final lotes = <_CpsLoteOpcao>[];

    for (int empresaIndex = 0;
        empresaIndex < controller.empresas.length;
        empresaIndex++) {
      final emp = controller.empresas[empresaIndex];
      for (int adIndex = 0; adIndex < emp.adiantamentos.length; adIndex++) {
        final ad = emp.adiantamentos[adIndex];
        final sitesNoLote = _calcularSitesNoAdiantamento(emp, adIndex);
        final valorBruto = sitesNoLote * emp.valorPorSite;
        final valorReceber = valorBruto - ad.valor;
        final titulo = ad.identificacao.trim().isNotEmpty
            ? ad.identificacao.trim()
            : 'CPS ${adIndex + 1}';

        lotes.add(
          _CpsLoteOpcao(
            empresaIndex: empresaIndex,
            posicao: adIndex,
            empresaNome: emp.nome,
            titulo: titulo,
            valorReceber: valorReceber,
          ),
        );
      }
    }

    return lotes;
  }

  int _calcularSitesNoAdiantamento(EmpresaModel emp, int index) {
    if (index < 0 || index >= emp.adiantamentos.length) return 0;

    int restantesConcluidos =
        emp.sites.where((s) => s.isConcluido && s.participaAdiantamento).length;

    for (int i = 0; i < emp.adiantamentos.length; i++) {
      final ad = emp.adiantamentos[i];
      final limite = ad.encerrado
          ? (ad.sitesConcluidosNoEncerramento ?? ad.sitesPorLote)
          : ad.sitesPorLote;
      final concluidosNeste = restantesConcluidos <= 0
          ? 0
          : (restantesConcluidos >= limite ? limite : restantesConcluidos);

      if (i == index) {
        if (ad.encerrado) {
          return ad.sitesConcluidosNoEncerramento ?? concluidosNeste;
        }
        return concluidosNeste;
      }

      if (ad.encerrado) {
        restantesConcluidos -=
            (ad.sitesConcluidosNoEncerramento ?? ad.sitesPorLote);
      } else {
        restantesConcluidos -= concluidosNeste;
      }
    }

    return 0;
  }

  String _gerarTextoCpsLote(_CpsLoteOpcao lote) {
    final emp = controller.empresas[lote.empresaIndex];
    final ad = emp.adiantamentos[lote.posicao];
    final sitesNoLote = _calcularSitesNoAdiantamento(emp, lote.posicao);
    final valorBruto = sitesNoLote * emp.valorPorSite;
    final valorReceber = valorBruto - ad.valor;

    final buffer = StringBuffer();
    buffer.writeln('📦 CPS - LOTE ESPECÍFICO');
    buffer.writeln('');
    buffer.writeln('Empresa: ${emp.nome}');
    buffer.writeln('Lote: ${lote.titulo}');
    buffer.writeln('Data do adiantamento: ${_formatDate(ad.data)}');
    buffer.writeln('Sites no lote: $sitesNoLote/${ad.sitesPorLote}');
    buffer.writeln('Valor bruto do lote: ${_formatCurrency(valorBruto)}');
    buffer.writeln('Adiantamento: ${_formatCurrency(ad.valor)}');
    buffer.writeln('Valor a receber: ${_formatCurrency(valorReceber)}');
    buffer.writeln(
      'Status: ${ad.foiPago ? 'PAGO${ad.dataPagamento != null ? ' em ${_formatDate(ad.dataPagamento!)}' : ''}' : 'AGUARDANDO PAGAMENTO'}',
    );
    if (ad.foiPago) {
      buffer.writeln('Valor pago: ${_formatCurrency(ad.valorPago > 0 ? ad.valorPago : valorReceber)}');
    }
    if (ad.observacao.trim().isNotEmpty) {
      buffer.writeln('Observação: ${ad.observacao.trim()}');
    }
    buffer.writeln('');
    buffer.writeln('Gerado em ${_formatDate(DateTime.now())}');

    return buffer.toString();
  }

  String _gerarTextoCpsTodosLotes() {
    final buffer = StringBuffer();
    buffer.writeln('📦 CPS - TODOS OS LOTES');
    buffer.writeln('');

    for (final emp in controller.empresas) {
      if (emp.adiantamentos.isEmpty) continue;

      buffer.writeln('🏢 ${emp.nome}');
      for (int i = 0; i < emp.adiantamentos.length; i++) {
        final ad = emp.adiantamentos[i];
        final sitesNoLote = _calcularSitesNoAdiantamento(emp, i);
        final valorBruto = sitesNoLote * emp.valorPorSite;
        final valorReceber = valorBruto - ad.valor;
        final titulo = ad.identificacao.trim().isNotEmpty
            ? ad.identificacao.trim()
            : 'CPS ${i + 1}';

        final status = ad.foiPago
            ? 'PAGO${ad.dataPagamento != null ? ' em ${_formatDate(ad.dataPagamento!)}' : ''}'
            : 'AGUARDANDO';
        final valorPago = ad.foiPago
            ? ad.valorPago > 0
                ? ad.valorPago
                : valorReceber
            : 0.0;

        buffer.writeln('• $titulo (${_formatDate(ad.data)})');
        buffer.writeln('  Sites: $sitesNoLote/${ad.sitesPorLote}');
        buffer.writeln('  Adiant.: ${_formatCurrency(ad.valor)} | A receber: ${_formatCurrency(valorReceber)}');
        buffer.writeln('  Status: $status');
        if (ad.foiPago) {
          buffer.writeln('  Valor pago: ${_formatCurrency(valorPago)}');
        }
      }
      buffer.writeln('');
    }

    buffer.writeln('Gerado em ${_formatDate(DateTime.now())}');
    return buffer.toString();
  }

  Future<void> _exportarBackup(BuildContext context) async {
    try {
      final jsonStr = controller.gerarBackupJson();
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'backup_demanda_${_formatDateFile(DateTime.now())}.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonStr);

      if (context.mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Backup Demanda Controller',
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('Backup gerado! Salve o arquivo em um local seguro.')),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erro ao gerar backup: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _importarBackup(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Restaurar Backup'),
          ],
        ),
        content: const Text(
          'Ao restaurar um backup, todos os dados atuais serão substituídos pelos dados do arquivo. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Restaurar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final jsonStr = await file.readAsString();

      final sucesso = await controller.restaurarBackupJson(jsonStr);

      if (context.mounted) {
        if (sucesso) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('Backup restaurado com sucesso!')),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('Arquivo de backup inválido ou corrompido.')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Erro ao restaurar: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Future<void> _backupNuvem(BuildContext context) async {
    final driveBackupService = DriveBackupService();

    try {
      final backupJson = controller.gerarBackupJson();
      final ok = await driveBackupService.salvarBackupNoDrive(
        backupJson,
        interativo: true,
      );

      if (!ok) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Conecte uma conta Google para salvar no Drive.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Backup salvo com sucesso no Google Drive.'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar backup na nuvem: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _restaurarDaNuvem(BuildContext context) async {
    final driveBackupService = DriveBackupService();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Restaurar da nuvem'),
        content: const Text(
          'Os dados atuais serão substituídos pelo backup salvo na nuvem. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final backupJson = await driveBackupService.carregarBackupDoDrive(
        interativo: true,
      );
      if (backupJson == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Nenhum backup encontrado no Google Drive desta conta.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }

      final sucesso = await controller.restaurarBackupJson(backupJson);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sucesso
                ? 'Backup restaurado do Google Drive com sucesso.'
                : 'Falha ao restaurar backup do Google Drive.',
          ),
          backgroundColor: sucesso ? AppTheme.successColor : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao restaurar do Google Drive: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _excluirContaEDados(BuildContext context) async {
    final authService = AuthService();
    final cloudBackupService = CloudBackupService();
    final user = authService.usuarioAtual;

    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Não há conta autenticada para excluir.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final senhaController = TextEditingController();
    final confirmaController = TextEditingController();
    bool confirmacaoAtiva = false;

    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Excluir conta e dados'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conta: ${user.email}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Esta ação é irreversível e apagará seus dados locais e em nuvem.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: senhaController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha atual',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirmaController,
                  decoration: const InputDecoration(
                    labelText: 'Digite EXCLUIR para confirmar',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    setDialogState(() {
                      confirmacaoAtiva = v.trim().toUpperCase() == 'EXCLUIR';
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: confirmacaoAtiva ? () => Navigator.pop(ctx, true) : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
              child: const Text('Excluir definitivamente'),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true) {
      senhaController.dispose();
      confirmaController.dispose();
      return;
    }

    if (senhaController.text.trim().isEmpty) {
      senhaController.dispose();
      confirmaController.dispose();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Informe a senha atual para excluir a conta.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      await authService.reautenticarComSenhaAtual(senhaController.text.trim());
      await cloudBackupService.excluirDadosNuvemDoUsuarioAtual();
      await authService.excluirContaAtual();
      await controller.limparDadosLocaisCompletos();

      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen(controller: controller)),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Conta e dados excluídos com sucesso.'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível excluir a conta: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      senhaController.dispose();
      confirmaController.dispose();
    }
  }

  // === HELPERS PARA TABELAS PROFISSIONAIS DO PDF ===

  pw.Widget _pdfHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget _pdfDataCell(
    String text, {
    bool bold = false,
    bool italic = false,
    PdfColor color = PdfColors.black,
    pw.Alignment align = pw.Alignment.centerLeft,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Align(
        alignment: align,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
            color: color,
          ),
          maxLines: 2,
        ),
      ),
    );
  }

  pw.Widget _pdfStatusBadge(
    String icon,
    String text,
    PdfColor bgColor,
    PdfColor textColor,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Center(
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
      ),
    );
  }

  pw.Widget _pdfLegenda() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text('Legenda:  ', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
          _pdfLegendaItem('Concluído', PdfColors.green800),
          pw.SizedBox(width: 16),
          _pdfLegendaItem('Não Concluído', PdfColors.red700),
          pw.SizedBox(width: 16),
          _pdfLegendaItem('Aguardando', PdfColors.amber700),
        ],
      ),
    );
  }

  pw.Widget _pdfLegendaRelatorio() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text('Legenda:  ', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
          _pdfLegendaItem('Feito', PdfColors.green800),
          pw.SizedBox(width: 16),
          _pdfLegendaItem('Problema', PdfColors.red700),
          pw.SizedBox(width: 16),
          _pdfLegendaItem('Pendente', PdfColors.amber700),
        ],
      ),
    );
  }

  pw.Widget _pdfLegendaItem(String label, PdfColor color) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 10,
          height: 10,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(3),
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(label, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateFile(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }
}

enum _TipoCompartilhamento {
  relatorio,
  cpsUnico,
  cpsTodos,
}

class _CpsLoteOpcao {
  final int empresaIndex;
  final int posicao;
  final String empresaNome;
  final String titulo;
  final double valorReceber;

  const _CpsLoteOpcao({
    required this.empresaIndex,
    required this.posicao,
    required this.empresaNome,
    required this.titulo,
    required this.valorReceber,
  });
}
