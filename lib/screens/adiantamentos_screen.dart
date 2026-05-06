import 'package:flutter/material.dart';
import '../controllers/demanda_controller.dart';
import '../models/empresa_model.dart';
import '../models/lancamento_financeiro_model.dart';
import '../theme/app_theme.dart';

class AdiantamentosScreen extends StatefulWidget {
  final DemandaController controller;

  const AdiantamentosScreen({super.key, required this.controller});

  @override
  State<AdiantamentosScreen> createState() => _AdiantamentosScreenState();
}

class _AdiantamentosScreenState extends State<AdiantamentosScreen> {
  DemandaController get ctrl => widget.controller;
  EmpresaModel? get emp => ctrl.empresaAtual;

  @override
  void initState() {
    super.initState();
    ctrl.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  bool get _visualizacaoFinanceiraEstaNoPadrao {
    return ctrl.filtroLancamentosEmpresaAtual == 'todos' &&
        ctrl.ordenacaoLancamentosEmpresaAtual == 'data_desc' &&
        ctrl.filtroPlanosParcelamentoEmpresaAtual == 'todos';
  }

  bool get _visualizacaoFinanceiraTemFiltrosAtivos =>
      !_visualizacaoFinanceiraEstaNoPadrao;

  Color get _corAcaoLimparVisualizacao =>
      _visualizacaoFinanceiraTemFiltrosAtivos
          ? AppTheme.warningColor
          : AppTheme.primaryColor;

  String _tituloPresetVisualizacao(String presetId) {
    switch (presetId) {
      case 'fechamento_semanal':
        return 'Fechamento semanal';
      case 'planejamento_previstos':
        return 'Planejamento previstos';
      case 'auditoria':
        return 'Auditoria';
      case 'custom':
        return 'Customizado';
      case 'padrao':
      default:
        return 'Padrão';
    }
  }

  String _descricaoPresetVisualizacao(String presetId) {
    switch (presetId) {
      case 'fechamento_semanal':
        return 'Foca recebidos e prioriza maiores valores pendentes de fechamento.';
      case 'planejamento_previstos':
        return 'Mostra previstos em ordem cronológica para planejar entradas.';
      case 'auditoria':
        return 'Organiza por tipo para conferência financeira detalhada.';
      case 'custom':
        return 'Combinação ajustada manualmente nesta empresa.';
      case 'padrao':
      default:
        return 'Visualização completa padrão para acompanhamento geral.';
    }
  }

  String _tituloPresetVisualizacaoCurto(String presetId) {
    switch (presetId) {
      case 'fechamento_semanal':
        return 'Semanal';
      case 'planejamento_previstos':
        return 'Previstos';
      case 'auditoria':
        return 'Auditoria';
      case 'custom':
        return 'Custom';
      case 'padrao':
      default:
        return 'Padrão';
    }
  }

  Color _corPresetVisualizacao(String presetId) {
    switch (presetId) {
      case 'custom':
        return AppTheme.warningColor;
      case 'padrao':
        return AppTheme.primaryColor;
      default:
        return AppTheme.accentColor;
    }
  }

  void _aplicarPresetVisualizacaoComFeedback(String presetId) {
    ctrl.aplicarPresetVisualizacaoFinanceiraEmpresaAtual(presetId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Preset aplicado: ${_tituloPresetVisualizacao(ctrl.presetVisualizacaoFinanceiraEmpresaAtual)}.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _aplicarPresetRapido(String presetId) {
    final jaAtivo = ctrl.presetVisualizacaoFinanceiraEmpresaAtual == presetId;
    if (jaAtivo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Preset ${_tituloPresetVisualizacao(presetId)} já está ativo.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _aplicarPresetVisualizacaoComFeedback(presetId);
  }

  Widget _buildControleAtalhosPresets() {
    final mostrar = ctrl.mostrarAtalhosPresetsEmpresaAtual;
    return Row(
      children: [
        Icon(
          Icons.bolt_outlined,
          size: 14,
          color: Colors.grey[700],
        ),
        const SizedBox(width: 6),
        Text(
          'Atalhos de presets',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () {
            ctrl.atualizarMostrarAtalhosPresetsEmpresaAtual(!mostrar);
          },
          icon: Icon(
            mostrar ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 16,
          ),
          label: Text(mostrar ? 'Ocultar' : 'Mostrar'),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAtalhosPresetsRapidos() {
    final telaEstreita = MediaQuery.of(context).size.width < 420;
    final presets = ['fechamento_semanal', 'planejamento_previstos', 'auditoria'];

    String label(String id) {
      if (!telaEstreita) {
        return _tituloPresetVisualizacao(id);
      }
      switch (id) {
        case 'fechamento_semanal':
          return 'Semanal';
        case 'planejamento_previstos':
          return 'Previstos';
        case 'auditoria':
          return 'Auditoria';
        default:
          return _tituloPresetVisualizacaoCurto(id);
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.map((id) {
        final selecionado = ctrl.presetVisualizacaoFinanceiraEmpresaAtual == id;
        final cor = _corPresetVisualizacao(id);
        return ChoiceChip(
          selected: selecionado,
          label: Text(label(id)),
          selectedColor: cor.withAlpha(35),
          backgroundColor: cor.withAlpha(15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          labelStyle: TextStyle(
            color: selecionado ? cor : cor.withAlpha(210),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          onSelected: (_) => _aplicarPresetRapido(id),
        );
      }).toList(),
    );
  }

  List<PopupMenuEntry<String>> _buildPresetMenuItems() {
    Widget itemTexto(String id) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tituloPresetVisualizacao(id),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            _descricaoPresetVisualizacao(id),
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return [
      CheckedPopupMenuItem(
        value: 'padrao',
        checked: ctrl.presetVisualizacaoFinanceiraEmpresaAtual == 'padrao',
        child: itemTexto('padrao'),
      ),
      CheckedPopupMenuItem(
        value: 'fechamento_semanal',
        checked: ctrl.presetVisualizacaoFinanceiraEmpresaAtual ==
            'fechamento_semanal',
        child: itemTexto('fechamento_semanal'),
      ),
      CheckedPopupMenuItem(
        value: 'planejamento_previstos',
        checked: ctrl.presetVisualizacaoFinanceiraEmpresaAtual ==
            'planejamento_previstos',
        child: itemTexto('planejamento_previstos'),
      ),
      CheckedPopupMenuItem(
        value: 'auditoria',
        checked: ctrl.presetVisualizacaoFinanceiraEmpresaAtual == 'auditoria',
        child: itemTexto('auditoria'),
      ),
    ];
  }

  List<String> _opcoesComAtivoPrimeiro(List<String> base, String ativo) {
    final lista = List<String>.from(base);
    lista.sort((a, b) {
      if (a == ativo && b != ativo) return -1;
      if (b == ativo && a != ativo) return 1;
      return base.indexOf(a).compareTo(base.indexOf(b));
    });
    return lista;
  }

  String _rotuloFiltroLancamentosResumo(String valor, {bool compacto = false}) {
    switch (valor) {
      case 'recebidos':
        return compacto ? 'Rec' : 'Recebidos';
      case 'previstos':
        return compacto ? 'Prev' : 'Previstos';
      default:
        return compacto ? 'Todos' : 'Todos';
    }
  }

  String _rotuloOrdenacaoResumo(String valor, {bool compacto = false}) {
    switch (valor) {
      case 'data_asc':
        return compacto ? 'Dt+' : 'Data asc';
      case 'valor_desc':
        return compacto ? 'R\$-' : 'Valor desc';
      case 'valor_asc':
        return compacto ? 'R\$+' : 'Valor asc';
      case 'tipo':
        return compacto ? 'Tipo' : 'Tipo';
      case 'data_desc':
      default:
        return compacto ? 'Dt-' : 'Data desc';
    }
  }

  String _rotuloFiltroPlanosResumo(String valor, {bool compacto = false}) {
    switch (valor) {
      case 'abertos':
        return compacto ? 'Pl abertos' : 'Planos abertos';
      case 'concluidos':
        return compacto ? 'Pl concl' : 'Planos concluidos';
      default:
        return compacto ? 'Pl todos' : 'Todos os planos';
    }
  }

  String _resumoFiltrosAtivos({bool compacto = false}) {
    final partes = <String>[];
    if (ctrl.filtroLancamentosEmpresaAtual != 'todos') {
      partes.add(_rotuloFiltroLancamentosResumo(
        ctrl.filtroLancamentosEmpresaAtual,
        compacto: compacto,
      ));
    }
    if (ctrl.ordenacaoLancamentosEmpresaAtual != 'data_desc') {
      partes.add(_rotuloOrdenacaoResumo(
        ctrl.ordenacaoLancamentosEmpresaAtual,
        compacto: compacto,
      ));
    }
    if (ctrl.filtroPlanosParcelamentoEmpresaAtual != 'todos') {
      partes.add(_rotuloFiltroPlanosResumo(
        ctrl.filtroPlanosParcelamentoEmpresaAtual,
        compacto: compacto,
      ));
    }
    return partes.join(' + ');
  }

  Widget _buildBadgeFiltrosAtivos() {
    if (!_visualizacaoFinanceiraTemFiltrosAtivos) {
      return const SizedBox.shrink();
    }

    final telaEstreita = MediaQuery.of(context).size.width < 420;
    final resumoCompleto = _resumoFiltrosAtivos();
    final resumoExibido = telaEstreita
        ? _resumoFiltrosAtivos(compacto: true)
        : resumoCompleto;

    return Tooltip(
      message: resumoCompleto,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: AppTheme.warningColor.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          resumoExibido,
          style: const TextStyle(
            color: AppTheme.warningColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildBadgePresetAtual() {
    final presetId = ctrl.presetVisualizacaoFinanceiraEmpresaAtual;
    final telaEstreita = MediaQuery.of(context).size.width < 420;
    final tituloCompleto = _tituloPresetVisualizacao(presetId);
    final tituloExibido = telaEstreita
        ? _tituloPresetVisualizacaoCurto(presetId)
        : tituloCompleto;
    final cor = _corPresetVisualizacao(presetId);

    return Tooltip(
      message: 'Preset atual: $tituloCompleto',
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: cor.withAlpha(22),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Preset: $tituloExibido',
          style: TextStyle(
            color: cor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _limparVisualizacaoFinanceiraComFeedback() {
    final filtroAnterior = ctrl.filtroLancamentosEmpresaAtual;
    final ordenacaoAnterior = ctrl.ordenacaoLancamentosEmpresaAtual;
    final filtroPlanosAnterior = ctrl.filtroPlanosParcelamentoEmpresaAtual;
    final jaEstaNoPadrao =
        filtroAnterior == 'todos' &&
            ordenacaoAnterior == 'data_desc' &&
            filtroPlanosAnterior == 'todos';

    if (jaEstaNoPadrao) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Os filtros já estão no padrão.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ctrl.resetarPreferenciasVisualizacaoFinanceiraEmpresaAtual();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Filtros e ordenação redefinidos.'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () {
            ctrl.atualizarFiltroLancamentosEmpresaAtual(filtroAnterior);
            ctrl.atualizarOrdenacaoLancamentosEmpresaAtual(ordenacaoAnterior);
            ctrl.atualizarFiltroPlanosParcelamentoEmpresaAtual(
              filtroPlanosAnterior,
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    ctrl.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (emp == null) {
      return const Center(child: Text('Nenhuma empresa selecionada'));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResumoAdiantamento(),
          const SizedBox(height: 16),
          _buildBotaoNovoAdiantamento(),
          const SizedBox(height: 16),
          _buildListaAdiantamentos(),
          const SizedBox(height: 16),
          _buildResumoFinanceiroLancamentos(),
          const SizedBox(height: 16),
          _buildListaPlanosParcelamento(),
          const SizedBox(height: 16),
          _buildListaLancamentosFinanceiros(),
        ],
      ),
    );
  }

  Widget _buildPainelVisualizacaoFinanceira() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Visualização Financeira',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                Flexible(child: _buildBadgeFiltrosAtivos()),
                Flexible(child: _buildBadgePresetAtual()),
                PopupMenuButton<String>(
                  tooltip: 'Aplicar preset de visualização',
                  initialValue: ctrl.presetVisualizacaoFinanceiraEmpresaAtual,
                  onSelected: _aplicarPresetVisualizacaoComFeedback,
                  itemBuilder: (context) => _buildPresetMenuItems(),
                  icon: const Icon(
                    Icons.tune,
                    size: 20,
                    color: AppTheme.accentColor,
                  ),
                ),
                IconButton(
                  onPressed: _limparVisualizacaoFinanceiraComFeedback,
                  tooltip: 'Limpar filtros e ordenação',
                  icon: Icon(
                    Icons.filter_alt_off_outlined,
                    color: _corAcaoLimparVisualizacao,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _buildControleAtalhosPresets(),
            if (ctrl.mostrarAtalhosPresetsEmpresaAtual) ...[
              const SizedBox(height: 8),
              _buildAtalhosPresetsRapidos(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResumoAdiantamento() {
    final e = emp!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Adiantamentos - ${e.nome}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                e.tipoAdiantamentoDescricao,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentColor,
                ),
              ),
            ),
            const Divider(height: 24),
            _buildItemResumo(
              'Sites Concluídos',
              '${e.sitesConcluidos} de ${e.totalSites}',
              Icons.check_circle_outline,
              AppTheme.successColor,
            ),
            _buildItemResumo(
              'Adiantamentos Realizados',
              '${e.adiantamentos.length}',
              Icons.receipt_long,
              AppTheme.primaryColor,
            ),
            _buildItemResumo(
              'Total Adiantado',
              _formatCurrency(e.totalAdiantamentos),
              Icons.payments,
              Colors.blue,
            ),
            _buildItemResumo(
              'Valor Ganho Total',
              _formatCurrency(e.valorGanho),
              Icons.monetization_on,
              AppTheme.successColor,
            ),
            const Divider(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.successGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Text(
                    'VALOR A RECEBER',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(e.valorReceberComAdiantamento),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '(Descontando adiantamentos)',
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Text(
                    'VALOR SEM DESCONTO DE ADIANTAMENTO',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(e.valorReceberSemAdiantamento),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (e.precisaSolicitarAdiantamento)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.warningColor.withAlpha(80),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: AppTheme.warningColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '⚠️ Você completou ${e.sitesConcluidosElegiveisAdiantamento} sites elegíveis! Solicite um novo adiantamento.',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemResumo(
      String label, String valor, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Text(
            valor,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoNovoAdiantamento() {
    if (emp!.tipoAdiantamento == TipoAdiantamento.semAdiantamento) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _dialogNovoAdiantamento,
        icon: const Icon(Icons.add_circle_outline, size: 22),
        label: const Text(
          'REGISTRAR NOVO ADIANTAMENTO',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  void _dialogNovoAdiantamento() {
    final e = emp!;
    double sugestao;
    switch (e.tipoAdiantamento) {
      case TipoAdiantamento.percentualPorLote:
        sugestao = e.valorAdiantamentoLote;
        break;
      case TipoAdiantamento.valorFixoSemanal:
      case TipoAdiantamento.valorFixoUnico:
        sugestao = e.valorAdiantamentoFixo;
        break;
      case TipoAdiantamento.semAdiantamento:
        sugestao = 0;
        break;
    }

    final valorController = TextEditingController(
      text: sugestao.toStringAsFixed(2),
    );
    final identificacaoController = TextEditingController();
    final obsController = TextEditingController();
    final loteController = TextEditingController(
      text: e.sitesPorLote.toString(),
    );
    DateTime dataSelecionada = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.payments, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text('Novo Adiantamento'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (e.tipoAdiantamento == TipoAdiantamento.percentualPorLote) ...[
                      TextField(
                        controller: loteController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Qtd de sites do lote',
                          prefixIcon: const Icon(Icons.cell_tower, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (_) {
                          final lote = int.tryParse(loteController.text) ?? e.sitesPorLote;
                          final novoValor = lote * e.valorPorSite * e.percentualAdiantamento;
                          setDialogState(() {
                            valorController.text = novoValor.toStringAsFixed(2);
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: identificacaoController,
                      decoration: InputDecoration(
                        labelText: 'Identificação do adiantamento',
                        hintText: 'Ex: CPS_434_SVY',
                        prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: valorController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Valor (R\$)',
                        prefixText: 'R\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dataSelecionada,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() => dataSelecionada = picked);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Data: ${_formatDate(dataSelecionada)}',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: obsController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Observação (opcional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final valor =
                        double.tryParse(valorController.text.replaceAll(',', '.'));
                    if (valor == null || valor <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Informe um valor válido'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                      return;
                    }
                    final lote = int.tryParse(loteController.text) ?? e.sitesPorLote;
                    ctrl.adicionarAdiantamento(
                      valor,
                      dataSelecionada,
                      identificacao: identificacaoController.text,
                      observacao: obsController.text,
                      sitesPorLote: lote,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '✅ Adiantamento de ${_formatCurrency(valor)} registrado!'),
                        backgroundColor: AppTheme.successColor,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Registrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildListaAdiantamentos() {
    final e = emp!;
    final totalPendentesPagamento =
        e.adiantamentos.where((a) => !a.foiPago).length;
    if (e.adiantamentos.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.payments_outlined,
                    size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  'Nenhum adiantamento registrado',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    double acumulado = 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Histórico de Adiantamentos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: totalPendentesPagamento > 0
                      ? _dialogMarcarTodosPendentesComoPago
                      : null,
                  icon: const Icon(Icons.done_all, size: 18),
                  label: Text(
                    totalPendentesPagamento > 0
                        ? 'Pagar pendentes ($totalPendentesPagamento)'
                        : 'Tudo pago',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: totalPendentesPagamento > 0
                        ? AppTheme.successColor
                        : Colors.grey,
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(e.adiantamentos.length, (i) {
              final a = e.adiantamentos[i];
              final concluidosNoAdiantamento = ctrl.sitesConcluidosNoAdiantamento(i);
              final totalConsiderado =
                  a.encerrado ? (a.sitesConcluidosNoEncerramento ?? a.sitesPorLote) : concluidosNoAdiantamento;
              final valorBrutoCps = totalConsiderado * e.valorPorSite;
              final valorReceberCps = valorBrutoCps - a.valor;
              final previsao = a.previsaoRecebimento;
              final diasPrevisao = previsao != null
                  ? previsao.difference(DateTime.now()).inDays
                  : 0;
              acumulado += a.valor;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: a.foiPago ? AppTheme.successColor.withAlpha(15) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: a.foiPago
                        ? AppTheme.successColor.withAlpha(80)
                        : Colors.grey.withAlpha(40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '#${i + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.identificacao.isNotEmpty
                                    ? a.identificacao
                                    : 'Adiantamento ${i + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatCurrency(a.valor),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              Text(
                                _formatDate(a.data),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'Lote: ${a.sitesPorLote} sites',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                              Text(
                                'Andamento: $totalConsiderado/${a.sitesPorLote} sites',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: a.encerrado
                                      ? AppTheme.successColor
                                      : AppTheme.warningColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Acumulado',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[500]),
                            ),
                            Text(
                              _formatCurrency(acumulado),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _dialogEditarIdentificacao(i, a.identificacao),
                            icon: const Icon(Icons.edit_note, size: 18),
                            label: const Text('Identificação'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: a.encerrado
                              ? OutlinedButton.icon(
                                  onPressed: () => ctrl.reabrirAdiantamento(i),
                                  icon: const Icon(Icons.lock_open, size: 18),
                                  label: const Text('Reabrir'),
                                )
                              : ElevatedButton.icon(
                                  onPressed: () => _dialogEncerrarAdiantamento(
                                      i, a, concluidosNoAdiantamento),
                                  icon: const Icon(Icons.task_alt, size: 18),
                                  label: const Text('Encerrar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accentColor,
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: a.encerrado
                            ? AppTheme.successColor.withAlpha(15)
                            : AppTheme.warningColor.withAlpha(15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.encerrado
                                ? 'Fechado em ${_formatDate(a.dataEncerramento ?? a.data)}'
                                : 'Aberto: complete ${a.sitesPorLote} sites para fechar',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: a.encerrado
                                  ? AppTheme.successColor
                                  : AppTheme.warningColor,
                            ),
                          ),
                          if (a.encerrado && a.encerradoParcial)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Encerramento parcial registrado.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.warningColor,
                                ),
                              ),
                            ),
                          if (previsao != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                diasPrevisao >= 0
                                    ? 'Previsão de recebimento: ${_formatDate(previsao)} (${diasPrevisao + 1} dias)'
                                    : 'Prazo de 30 dias vencido em ${_formatDate(previsao)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withAlpha(10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Valor a receber deste CPS: ${_formatCurrency(valorReceberCps)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          if (a.foiPago)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Valor pago registrado: ${_formatCurrency(a.valorPago > 0 ? a.valorPago : valorReceberCps)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.successColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Status de pagamento
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              if (a.foiPago) {
                                ctrl.desmarcarAdiantamentoPago(i);
                              } else {
                                await _dialogMarcarPagamentoAdiantamento(
                                  i,
                                  valorReceberCps,
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: a.foiPago
                                    ? AppTheme.successColor.withAlpha(25)
                                    : AppTheme.warningColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    a.foiPago
                                        ? Icons.check_circle
                                        : Icons.hourglass_empty,
                                    size: 16,
                                    color: a.foiPago
                                        ? AppTheme.successColor
                                        : AppTheme.warningColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    a.foiPago
                                        ? 'PAGO${a.dataPagamento != null ? ' em ${_formatDate(a.dataPagamento!)}' : ''}'
                                        : 'AGUARDANDO PAGAMENTO',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: a.foiPago
                                          ? AppTheme.successColor
                                          : AppTheme.warningColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppTheme.errorColor, size: 20),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Remover Adiantamento?'),
                                content: Text(
                                    'Deseja remover o adiantamento de ${_formatCurrency(a.valor)}?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Não'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      ctrl.removerAdiantamento(i);
                                      Navigator.pop(ctx);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.errorColor,
                                    ),
                                    child: const Text('Sim, remover'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    if (a.observacao.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.note,
                                size: 14, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                a.observacao,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoFinanceiroLancamentos() {
    final e = emp!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo Financeiro Avançado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            _buildItemResumo(
              'Lançamentos descontáveis',
              _formatCurrency(e.totalLancamentosDescontaveis),
              Icons.remove_circle_outline,
              AppTheme.errorColor,
            ),
            _buildItemResumo(
              'Lançamentos não descontáveis',
              _formatCurrency(e.totalLancamentosNaoDescontaveis),
              Icons.add_circle_outline,
              AppTheme.successColor,
            ),
            _buildItemResumo(
              'Lançamentos previstos',
              _formatCurrency(e.totalLancamentosPrevistos),
              Icons.schedule,
              AppTheme.warningColor,
            ),
            _buildItemResumo(
              'Total de lançamentos',
              _formatCurrency(e.totalLancamentosFinanceiros),
              Icons.receipt_long,
              AppTheme.primaryColor,
            ),
            const Divider(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saldo considerando lançamentos',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(e.saldoFinanceiroComLancamentos),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Saldo previsto: ${_formatCurrency(e.saldoFinanceiroPrevistoComLancamentos)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoNovoLancamentoFinanceiro() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _dialogNovoLancamentoFinanceiro,
        icon: const Icon(Icons.post_add, size: 22),
        label: const Text(
          'REGISTRAR LANÇAMENTO FINANCEIRO',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          side: const BorderSide(color: AppTheme.primaryColor),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildBotaoNovoPlanoParcelado() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _dialogNovoPlanoParcelado,
        icon: const Icon(Icons.view_timeline_outlined, size: 22),
        label: const Text(
          'CRIAR PLANO DE PARCELAMENTO',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildListaPlanosParcelamento() {
    final e = emp!;
    final telaEstreita = MediaQuery.of(context).size.width < 420;
    final parcelados = e.lancamentosFinanceiros
        .asMap()
        .entries
        .where((entry) => entry.value.eParcela)
        .toList();

    if (parcelados.isEmpty) {
      return const SizedBox.shrink();
    }

    final grupos = <String, List<MapEntry<int, LancamentoFinanceiroModel>>>{};
    for (final entry in parcelados) {
      final chave = entry.value.grupoParcelaId ?? 'sem_grupo';
      grupos.putIfAbsent(chave, () => []).add(entry);
    }

    final chaves = grupos.keys.toList()
      ..sort((a, b) {
        final da = grupos[a]!
            .map((e) => e.value.data)
            .reduce((m, n) => m.isBefore(n) ? m : n);
        final db = grupos[b]!
            .map((e) => e.value.data)
            .reduce((m, n) => m.isBefore(n) ? m : n);
        return db.compareTo(da);
      });

    bool planoConcluido(String chave) {
      final itens = grupos[chave]!;
      final exemplo = itens.first.value;
      final totalParcelas = exemplo.parcelasTotal ?? itens.length;
      final recebidas = itens.where((e) => e.value.recebido).length;
      return recebidas >= totalParcelas;
    }

    final totalConcluidos = chaves.where(planoConcluido).length;
    final totalAbertos = chaves.length - totalConcluidos;
    final ordemFiltrosPlanos = telaEstreita
        ? _opcoesComAtivoPrimeiro(
            ['abertos', 'concluidos', 'todos'],
            ctrl.filtroPlanosParcelamentoEmpresaAtual,
          )
        : ['todos', 'abertos', 'concluidos'];

    final chavesFiltradas = chaves.where((chave) {
      final concluido = planoConcluido(chave);
      switch (ctrl.filtroPlanosParcelamentoEmpresaAtual) {
        case 'abertos':
          return !concluido;
        case 'concluidos':
          return concluido;
        default:
          return true;
      }
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Planos de Parcelamento',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...ordemFiltrosPlanos.map((valor) {
                  switch (valor) {
                    case 'abertos':
                      return _buildChipFiltroPlano(
                        telaEstreita ? 'Abertos' : 'Em aberto',
                        'abertos',
                        AppTheme.warningColor,
                        totalAbertos,
                      );
                    case 'concluidos':
                      return _buildChipFiltroPlano(
                        telaEstreita ? 'Concl.' : 'Concluídos',
                        'concluidos',
                        AppTheme.successColor,
                        totalConcluidos,
                      );
                    case 'todos':
                    default:
                      return _buildChipFiltroPlano(
                        'Todos',
                        'todos',
                        AppTheme.primaryColor,
                        chaves.length,
                      );
                  }
                }),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Exibindo ${chavesFiltradas.length} de ${chaves.length} planos.',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (chavesFiltradas.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Nenhum plano para o filtro selecionado.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ...chavesFiltradas.map((chave) {
              final itens = grupos[chave]!;
              itens.sort((a, b) =>
                  (a.value.parcelaNumero ?? 0).compareTo(b.value.parcelaNumero ?? 0));
              final exemplo = itens.first.value;
              final totalParcelas = exemplo.parcelasTotal ?? itens.length;
              final lancadas = itens.length;
              final totalLancado =
                  itens.fold<double>(0.0, (sum, e) => sum + e.value.valor);
              final desconto = exemplo.descontaNoFinal;
                final recebidas =
                  itens.where((e) => e.value.recebido).length;
              final progresso = totalParcelas > 0 ? lancadas / totalParcelas : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: desconto
                      ? AppTheme.errorColor.withAlpha(10)
                      : AppTheme.successColor.withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: desconto
                        ? AppTheme.errorColor.withAlpha(40)
                        : AppTheme.successColor.withAlpha(40),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.view_timeline_outlined,
                            color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            exemplo.referencia.isNotEmpty
                                ? exemplo.referencia.split(' - Parcela').first
                                : 'Plano ${chave.substring(0, chave.length > 18 ? 18 : chave.length)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppTheme.errorColor, size: 20),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Remover plano parcelado?'),
                                content: Text(
                                  'Deseja remover todas as $lancadas parcelas deste plano?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Não'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      ctrl.removerPlanoParcelamento(chave);
                                      Navigator.pop(ctx);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.errorColor,
                                    ),
                                    child: const Text('Sim, remover'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Text(
                      '${_tituloTipoLancamento(exemplo.tipo)} • ${desconto ? 'Desconta no final' : 'Não desconta no final'}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Parcelas lançadas: $lancadas/$totalParcelas • Recebidas: $recebidas',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progresso > 1 ? 1 : progresso,
                        minHeight: 10,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total lançado: ${_formatCurrency(totalLancado)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildChipFiltroPlano(String label, String valor, Color color, int total) {
    final selecionado = ctrl.filtroPlanosParcelamentoEmpresaAtual == valor;
    return FilterChip(
      selected: selecionado,
      label: Text('$label ($total)'),
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selecionado ? Colors.white : color,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      backgroundColor: color.withAlpha(25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      onSelected: (_) => ctrl.atualizarFiltroPlanosParcelamentoEmpresaAtual(valor),
    );
  }

  Widget _buildListaLancamentosFinanceiros() {
    final e = emp!;
    final telaEstreita = MediaQuery.of(context).size.width < 420;
    final totalLancamentos = e.lancamentosFinanceiros.length;
    final totalRecebidos =
        e.lancamentosFinanceiros.where((l) => l.recebido).length;
    final totalPrevistos = totalLancamentos - totalRecebidos;
    final ordemFiltrosLancamentos = telaEstreita
      ? _opcoesComAtivoPrimeiro(
        ['recebidos', 'previstos', 'todos'],
        ctrl.filtroLancamentosEmpresaAtual,
        )
      : ['todos', 'recebidos', 'previstos'];
    final ordemOrdenacaoLancamentos = telaEstreita
      ? _opcoesComAtivoPrimeiro(
        ['valor_desc', 'data_desc', 'data_asc', 'valor_asc', 'tipo'],
        ctrl.ordenacaoLancamentosEmpresaAtual,
        )
      : ['data_desc', 'data_asc', 'valor_desc', 'valor_asc', 'tipo'];

    final lancamentosFiltrados = e.lancamentosFinanceiros
        .asMap()
        .entries
        .where((entry) {
          switch (ctrl.filtroLancamentosEmpresaAtual) {
            case 'recebidos':
              return entry.value.recebido;
            case 'previstos':
              return !entry.value.recebido;
            default:
              return true;
          }
        })
        .toList();
    lancamentosFiltrados.sort(_compararLancamentos);

    if (e.lancamentosFinanceiros.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 44, color: Colors.grey[350]),
                const SizedBox(height: 10),
                Text(
                  'Nenhum lançamento financeiro registrado',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Lançamentos Financeiros',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...ordemFiltrosLancamentos.map((valor) {
                  switch (valor) {
                    case 'recebidos':
                      return _buildChipFiltroLancamento(
                        telaEstreita ? 'Rec' : 'Recebidos',
                        'recebidos',
                        AppTheme.successColor,
                        totalRecebidos,
                      );
                    case 'previstos':
                      return _buildChipFiltroLancamento(
                        telaEstreita ? 'Prev' : 'Previstos',
                        'previstos',
                        AppTheme.warningColor,
                        totalPrevistos,
                      );
                    case 'todos':
                    default:
                      return _buildChipFiltroLancamento(
                        'Todos',
                        'todos',
                        AppTheme.primaryColor,
                        totalLancamentos,
                      );
                  }
                }),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Exibindo ${lancamentosFiltrados.length} de $totalLancamentos lançamentos.',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...ordemOrdenacaoLancamentos.map((valor) {
                  switch (valor) {
                    case 'data_desc':
                      return _buildChipOrdenacaoLancamento(
                        telaEstreita ? 'Dt ↓' : 'Data ↓',
                        'data_desc',
                      );
                    case 'data_asc':
                      return _buildChipOrdenacaoLancamento(
                        telaEstreita ? 'Dt ↑' : 'Data ↑',
                        'data_asc',
                      );
                    case 'valor_desc':
                      return _buildChipOrdenacaoLancamento(
                        telaEstreita ? 'R\$ ↓' : 'Valor ↓',
                        'valor_desc',
                      );
                    case 'valor_asc':
                      return _buildChipOrdenacaoLancamento(
                        telaEstreita ? 'R\$ ↑' : 'Valor ↑',
                        'valor_asc',
                      );
                    case 'tipo':
                    default:
                      return _buildChipOrdenacaoLancamento('Tipo', 'tipo');
                  }
                }),
              ],
            ),
            const SizedBox(height: 12),
            if (lancamentosFiltrados.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Nenhum lançamento para o filtro selecionado.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ...List.generate(lancamentosFiltrados.length, (idx) {
              final entry = lancamentosFiltrados[idx];
              final i = entry.key;
              final l = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: l.descontaNoFinal
                      ? AppTheme.errorColor.withAlpha(10)
                      : AppTheme.successColor.withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: l.descontaNoFinal
                        ? AppTheme.errorColor.withAlpha(40)
                        : AppTheme.successColor.withAlpha(40),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _iconeTipoLancamento(l.tipo),
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _tituloTipoLancamento(l.tipo),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            _formatDate(l.data),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (l.eParcela)
                            Text(
                              'Parcela ${l.parcelaNumero}/${l.parcelasTotal}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (l.referencia.isNotEmpty)
                            Text(
                              l.referencia,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                              ),
                            ),
                          if (l.descricao.isNotEmpty)
                            Text(
                              l.descricao,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: l.recebido
                                  ? AppTheme.successColor.withAlpha(20)
                                  : AppTheme.warningColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l.recebido
                                  ? 'Recebido${l.dataRecebimento != null ? ' em ${_formatDate(l.dataRecebimento!)}' : ''}'
                                  : 'Previsto',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: l.recebido
                                    ? AppTheme.successColor
                                    : AppTheme.warningColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatCurrency(l.valor),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          l.descontaNoFinal
                              ? 'Desconta no final'
                              : 'Não desconta',
                          style: TextStyle(
                            fontSize: 10,
                            color: l.descontaNoFinal
                                ? AppTheme.errorColor
                                : AppTheme.successColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        l.recebido ? Icons.undo : Icons.check_circle_outline,
                        color: l.recebido
                            ? AppTheme.warningColor
                            : AppTheme.successColor,
                        size: 20,
                      ),
                      tooltip: l.recebido
                          ? 'Marcar como previsto'
                          : 'Marcar como recebido',
                      onPressed: () {
                        if (l.recebido) {
                          ctrl.desmarcarLancamentoFinanceiroRecebido(i);
                        } else {
                          ctrl.marcarLancamentoFinanceiroRecebido(i);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppTheme.errorColor,
                        size: 20,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Remover lançamento?'),
                            content: Text(
                              'Deseja remover ${_tituloTipoLancamento(l.tipo)} de ${_formatCurrency(l.valor)}?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Não'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  ctrl.removerLancamentoFinanceiro(i);
                                  Navigator.pop(ctx);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.errorColor,
                                ),
                                child: const Text('Sim, remover'),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildChipFiltroLancamento(
      String label, String valor, Color color, int total) {
    final selecionado = ctrl.filtroLancamentosEmpresaAtual == valor;
    return FilterChip(
      selected: selecionado,
      label: Text('$label ($total)'),
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selecionado ? Colors.white : color,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      backgroundColor: color.withAlpha(25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      onSelected: (_) => ctrl.atualizarFiltroLancamentosEmpresaAtual(valor),
    );
  }

  Widget _buildChipOrdenacaoLancamento(String label, String valor) {
    final selecionado = ctrl.ordenacaoLancamentosEmpresaAtual == valor;
    return FilterChip(
      selected: selecionado,
      label: Text(label),
      selectedColor: AppTheme.accentColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selecionado ? Colors.white : AppTheme.accentColor,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      backgroundColor: AppTheme.accentColor.withAlpha(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      onSelected: (_) => ctrl.atualizarOrdenacaoLancamentosEmpresaAtual(valor),
    );
  }

  int _compararLancamentos(
    MapEntry<int, LancamentoFinanceiroModel> a,
    MapEntry<int, LancamentoFinanceiroModel> b,
  ) {
    switch (ctrl.ordenacaoLancamentosEmpresaAtual) {
      case 'data_asc':
        return a.value.data.compareTo(b.value.data);
      case 'valor_desc':
        return b.value.valor.compareTo(a.value.valor);
      case 'valor_asc':
        return a.value.valor.compareTo(b.value.valor);
      case 'tipo':
        final tipo = _tituloTipoLancamento(a.value.tipo)
            .compareTo(_tituloTipoLancamento(b.value.tipo));
        if (tipo != 0) return tipo;
        return b.value.data.compareTo(a.value.data);
      case 'data_desc':
      default:
        return b.value.data.compareTo(a.value.data);
    }
  }

  void _dialogNovoLancamentoFinanceiro() {
    TipoLancamentoFinanceiro tipo =
        TipoLancamentoFinanceiro.adiantamentoDescontavel;
    final valorController = TextEditingController();
    final referenciaController = TextEditingController();
    final descricaoController = TextEditingController();
    final parcelaNumeroController = TextEditingController();
    final parcelasTotalController = TextEditingController();
    bool descontaNoFinal = true;
    bool recebido = true;
    DateTime dataSelecionada = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.post_add, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Novo lançamento financeiro'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<TipoLancamentoFinanceiro>(
                  value: tipo,
                  decoration: InputDecoration(
                    labelText: 'Tipo de lançamento',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: TipoLancamentoFinanceiro.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(_tituloTipoLancamento(t)),
                    );
                  }).toList(),
                  onChanged: (novoTipo) {
                    if (novoTipo == null) return;
                    setDialogState(() {
                      tipo = novoTipo;
                      descontaNoFinal = _descontoPadraoTipo(tipo);
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valorController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Valor (R\$)',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: referenciaController,
                  decoration: InputDecoration(
                    labelText: 'Referência (opcional)',
                    hintText: 'Ex: Semana 2 / Lote 3',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: parcelaNumeroController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Parcela nº',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: parcelasTotalController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Total parcelas',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dataSelecionada,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setDialogState(() => dataSelecionada = picked);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Data: ${_formatDate(dataSelecionada)}'),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Desconta no valor final'),
                  contentPadding: EdgeInsets.zero,
                  value: descontaNoFinal,
                  onChanged: (v) => setDialogState(() => descontaNoFinal = v),
                ),
                SwitchListTile(
                  title: const Text('Já recebido'),
                  contentPadding: EdgeInsets.zero,
                  value: recebido,
                  onChanged: (v) => setDialogState(() => recebido = v),
                ),
                TextField(
                  controller: descricaoController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Descrição (opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final valor =
                    double.tryParse(valorController.text.replaceAll(',', '.'));
                if (valor == null || valor <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Informe um valor válido para o lançamento.'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }

                final parcelaNumero = int.tryParse(parcelaNumeroController.text);
                final parcelasTotal = int.tryParse(parcelasTotalController.text);
                String? grupoParcelaId;

                if ((parcelaNumero != null && parcelasTotal == null) ||
                    (parcelaNumero == null && parcelasTotal != null) ||
                    (parcelaNumero != null && parcelaNumero <= 0) ||
                    (parcelasTotal != null && parcelasTotal <= 0) ||
                    (parcelaNumero != null && parcelasTotal != null && parcelaNumero > parcelasTotal)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Parcela inválida. Revise número e total de parcelas.'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }

                if (parcelaNumero != null && parcelasTotal != null) {
                  grupoParcelaId =
                      'grp_${dataSelecionada.millisecondsSinceEpoch}_${tipo.index}';
                }

                ctrl.adicionarLancamentoFinanceiro(
                  tipo: tipo,
                  valor: valor,
                  data: dataSelecionada,
                  descricao: descricaoController.text,
                  descontaNoFinal: descontaNoFinal,
                  referencia: referenciaController.text,
                  recebido: recebido,
                  dataRecebimento: recebido ? dataSelecionada : null,
                  grupoParcelaId: grupoParcelaId,
                  parcelaNumero: parcelaNumero,
                  parcelasTotal: parcelasTotal,
                );

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✅ Lançamento ${_tituloTipoLancamento(tipo)} registrado.',
                    ),
                    backgroundColor: AppTheme.successColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }

  void _dialogNovoPlanoParcelado() {
    TipoLancamentoFinanceiro tipo =
        TipoLancamentoFinanceiro.adiantamentoDescontavel;
    final valorTotalController = TextEditingController();
    final totalParcelasController = TextEditingController(text: '4');
    final intervaloController = TextEditingController(text: '7');
    final referenciaController = TextEditingController();
    final descricaoController = TextEditingController();
    bool descontaNoFinal = true;
    DateTime primeiraData = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.view_timeline_outlined, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Novo plano parcelado'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<TipoLancamentoFinanceiro>(
                  value: tipo,
                  decoration: InputDecoration(
                    labelText: 'Tipo financeiro',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: TipoLancamentoFinanceiro.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(_tituloTipoLancamento(t)),
                    );
                  }).toList(),
                  onChanged: (novoTipo) {
                    if (novoTipo == null) return;
                    setDialogState(() {
                      tipo = novoTipo;
                      descontaNoFinal = _descontoPadraoTipo(tipo);
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valorTotalController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Valor total (R\$)',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: totalParcelasController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Qtde parcelas',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: intervaloController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Intervalo (dias)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: primeiraData,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setDialogState(() => primeiraData = picked);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Primeira parcela: ${_formatDate(primeiraData)}'),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: referenciaController,
                  decoration: InputDecoration(
                    labelText: 'Referência do plano',
                    hintText: 'Ex: Adiantamento Abril/2026',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Desconta no valor final'),
                  contentPadding: EdgeInsets.zero,
                  value: descontaNoFinal,
                  onChanged: (v) => setDialogState(() => descontaNoFinal = v),
                ),
                TextField(
                  controller: descricaoController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Descrição (opcional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final valorTotal = double.tryParse(
                    valorTotalController.text.replaceAll(',', '.'));
                final totalParcelas = int.tryParse(totalParcelasController.text);
                final intervalo = int.tryParse(intervaloController.text) ?? 7;

                if (valorTotal == null || valorTotal <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Informe um valor total válido.'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }
                if (totalParcelas == null || totalParcelas <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Informe uma quantidade de parcelas válida.'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }
                if (intervalo <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Intervalo de dias deve ser maior que zero.'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }

                ctrl.criarPlanoParcelamento(
                  tipo: tipo,
                  valorTotal: valorTotal,
                  totalParcelas: totalParcelas,
                  primeiraData: primeiraData,
                  intervaloDias: intervalo,
                  referenciaBase: referenciaController.text,
                  descricao: descricaoController.text,
                  descontaNoFinal: descontaNoFinal,
                );

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '✅ Plano criado com $totalParcelas parcelas.'),
                    backgroundColor: AppTheme.successColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Criar plano'),
            ),
          ],
        ),
      ),
    );
  }

  bool _descontoPadraoTipo(TipoLancamentoFinanceiro tipo) {
    switch (tipo) {
      case TipoLancamentoFinanceiro.adiantamentoDescontavel:
      case TipoLancamentoFinanceiro.ajudaCustoDescontavel:
      case TipoLancamentoFinanceiro.pagamentoFinal:
        return true;
      case TipoLancamentoFinanceiro.ajudaCustoNaoDescontavel:
      case TipoLancamentoFinanceiro.ajuste:
        return false;
    }
  }

  String _tituloTipoLancamento(TipoLancamentoFinanceiro tipo) {
    switch (tipo) {
      case TipoLancamentoFinanceiro.adiantamentoDescontavel:
        return 'Adiantamento descontável';
      case TipoLancamentoFinanceiro.ajudaCustoNaoDescontavel:
        return 'Ajuda de custo (não descontável)';
      case TipoLancamentoFinanceiro.ajudaCustoDescontavel:
        return 'Ajuda de custo (descontável)';
      case TipoLancamentoFinanceiro.pagamentoFinal:
        return 'Pagamento final';
      case TipoLancamentoFinanceiro.ajuste:
        return 'Ajuste financeiro';
    }
  }

  IconData _iconeTipoLancamento(TipoLancamentoFinanceiro tipo) {
    switch (tipo) {
      case TipoLancamentoFinanceiro.adiantamentoDescontavel:
        return Icons.account_balance_wallet_outlined;
      case TipoLancamentoFinanceiro.ajudaCustoNaoDescontavel:
      case TipoLancamentoFinanceiro.ajudaCustoDescontavel:
        return Icons.volunteer_activism_outlined;
      case TipoLancamentoFinanceiro.pagamentoFinal:
        return Icons.price_check_outlined;
      case TipoLancamentoFinanceiro.ajuste:
        return Icons.tune;
    }
  }

  String _formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _dialogEditarIdentificacao(int index, String identificacaoAtual) {
    final controller = TextEditingController(text: identificacaoAtual);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Identificação do adiantamento'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ex: CPS_434_SVY',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ctrl.atualizarIdentificacaoAdiantamento(index, controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _dialogEncerrarAdiantamento(
    int index,
    dynamic adiantamento,
    int concluidosAtuais,
  ) {
    final defaultConcluidos = concluidosAtuais > adiantamento.sitesPorLote
        ? adiantamento.sitesPorLote
        : concluidosAtuais;
    final qtdController = TextEditingController(
      text: defaultConcluidos.toString(),
    );
    DateTime dataFechamento = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Encerrar adiantamento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Informe quantos sites foram concluídos neste adiantamento (pode ser parcial).',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtdController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Sites concluídos',
                    helperText: 'Máximo: ${adiantamento.sitesPorLote}',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dataFechamento,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setDialogState(() => dataFechamento = picked);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Data do fechamento: ${_formatDate(dataFechamento)}'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final qtd = int.tryParse(qtdController.text);
                if (qtd == null || qtd < 0 || qtd > adiantamento.sitesPorLote) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Informe uma quantidade válida de sites.'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }
                ctrl.encerrarAdiantamento(
                  index,
                  sitesConcluidos: qtd,
                  dataEncerramento: dataFechamento,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Confirmar fechamento'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dialogMarcarPagamentoAdiantamento(
    int index,
    double valorReceberCps,
  ) async {
    DateTime dataPagamento = DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Marcar CPS como pago'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Valor a receber deste CPS: ${_formatCurrency(valorReceberCps)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dataPagamento,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setDialogState(() => dataPagamento = picked);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Data do pagamento: ${_formatDate(dataPagamento)}'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                ctrl.marcarAdiantamentoPago(
                  index,
                  dataPagamento: dataPagamento,
                  valorPago: valorReceberCps,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Confirmar pagamento'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dialogMarcarTodosPendentesComoPago() async {
    DateTime dataPagamento = DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Marcar pendentes como pago'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esta ação marca todos os CPS pendentes como pagos com a mesma data.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dataPagamento,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setDialogState(() => dataPagamento = picked);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Data do pagamento: ${_formatDate(dataPagamento)}'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final total = ctrl.marcarTodosAdiantamentosPendentesComoPago(
                  dataPagamento: dataPagamento,
                );
                Navigator.pop(ctx);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$total CPS marcados como pagos.'),
                    backgroundColor: AppTheme.successColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }
}
