import 'package:flutter/material.dart';
import '../controllers/demanda_controller.dart';
import '../models/demanda_geral_model.dart';
import '../theme/app_theme.dart';

/// Tela de histórico de demandas arquivadas.
/// - Filtra por empresa (chip por empresa cadastrada no histórico)
/// - Filtra por status e busca por nome
/// - ExpansionTile: vários registros podem ficar abertos ao mesmo tempo
/// - Modo de seleção múltipla para ações em lote (reabrir/duplicar/excluir)
class HistoricoDemandasScreen extends StatefulWidget {
  final DemandaController controller;

  const HistoricoDemandasScreen({super.key, required this.controller});

  @override
  State<HistoricoDemandasScreen> createState() =>
      _HistoricoDemandasScreenState();
}

class _HistoricoDemandasScreenState extends State<HistoricoDemandasScreen> {
  String? _filtroEmpresa; // null = todas
  String _filtroStatus = 'todos';
  String _busca = '';
  String _ordenacao = 'mais_recente';

  final Set<String> _selecionados = {};
  bool _modoSelecao = false;

  // IDs dos tiles expandidos
  final Set<String> _expandidos = {};

  DemandaController get ctrl => widget.controller;

  // ─── filtro ──────────────────────────────────────────────────────────────

  List<DemandaGeralModel> get _demandasFiltradas {
    var list = ctrl.demandasArquivadasPorStatus(_filtroStatus);

    if (_filtroEmpresa != null) {
      list = list
          .where((d) => d.empresas.any((e) => e.nome == _filtroEmpresa))
          .toList();
    }

    if (_busca.trim().isNotEmpty) {
      final q = _busca.toLowerCase();
      list = list.where((d) => d.nome.toLowerCase().contains(q)).toList();
    }

    list.sort((a, b) {
      switch (_ordenacao) {
        case 'mais_antiga':
          return a.dataConclusao.compareTo(b.dataConclusao);
        case 'nome_az':
          return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
        case 'nome_za':
          return b.nome.toLowerCase().compareTo(a.nome.toLowerCase());
        case 'progresso':
          final pa =
              a.totalSites == 0 ? 0.0 : a.sitesConcluidos / a.totalSites;
          final pb =
              b.totalSites == 0 ? 0.0 : b.sitesConcluidos / b.totalSites;
          return pb.compareTo(pa);
        default:
          return b.dataConclusao.compareTo(a.dataConclusao);
      }
    });

    return list;
  }

  // ─── helpers ─────────────────────────────────────────────────────────────

  Color _corStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paga':
        return AppTheme.successColor;
      case 'concluída':
        return Colors.blue;
      case 'parcial':
        return AppTheme.warningColor;
      default:
        return Colors.grey;
    }
  }

  IconData _iconeStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paga':
        return Icons.verified;
      case 'concluída':
        return Icons.task_alt;
      case 'parcial':
        return Icons.timelapse;
      default:
        return Icons.pending_actions;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ─── ações ───────────────────────────────────────────────────────────────

  Future<void> _reabrir(DemandaGeralModel demanda) async {
    bool manterDatas = true;
    DateTime novaDataBase = DateTime.now();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.restore_page, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Reabrir Demanda'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Restaurar "${demanda.nome}"?\n\nOs dados atuais serão substituídos.'),
                const SizedBox(height: 14),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: manterDatas,
                  onChanged: (v) => setS(() => manterDatas = v),
                  title: const Text('Manter datas originais'),
                  subtitle: const Text(
                      'Sites, relatórios e fechamentos restaurados com as datas gravadas.'),
                ),
                if (!manterDatas)
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: novaDataBase,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) setS(() => novaDataBase = picked);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Nova data base: ${_formatDate(novaDataBase)}'),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.restore_page, size: 18),
              label: const Text('Reabrir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true || !mounted) return;

    final ok = await ctrl.reabrirDemandaGeral(
      demanda.id,
      manterDatasOriginais: manterDatas,
      novaDataBase: manterDatas ? null : novaDataBase,
    );
    if (!mounted || !ok) return;

    Navigator.pop(context); // volta para o dashboard
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demanda "${demanda.nome}" reaberta com sucesso.'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _duplicar(DemandaGeralModel demanda) async {
    final ok =
        await ctrl.duplicarDemandaArquivadaParaNovoCiclo(demanda.id);
    if (!mounted || !ok) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Novo ciclo criado a partir de "${demanda.nome}".'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _excluir(DemandaGeralModel demanda) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Excluir Demanda'),
          ],
        ),
        content: Text(
            'Excluir permanentemente "${demanda.nome}" do histórico?\n\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Excluir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    await ctrl.excluirDemandaArquivada(demanda.id);
    if (mounted) setState(() => _selecionados.remove(demanda.id));
  }

  Future<void> _excluirSelecionados() async {
    final ids = Set<String>.from(_selecionados);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Excluir Selecionadas'),
          ],
        ),
        content: Text(
            'Excluir permanentemente ${ids.length} demanda(s) do histórico?\n\nEsta ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Excluir'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    for (final id in ids) {
      await ctrl.excluirDemandaArquivada(id);
    }
    if (mounted) setState(() => _selecionados.clear());
  }

  // ─── build principal ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final demandas = _demandasFiltradas;
        final empresas = ctrl.empresasNoHistorico;

        return Scaffold(
          backgroundColor: AppTheme.surfaceColor,
          appBar: AppBar(
            backgroundColor: const Color(0xFF0D1642),
            foregroundColor: Colors.white,
            title: _modoSelecao
                ? Text('${_selecionados.length} selecionada(s)')
                : const Text('Histórico de Demandas'),
            actions: _modoSelecao
                ? [
                    IconButton(
                      icon: const Icon(Icons.select_all),
                      tooltip: 'Selecionar todas',
                      onPressed: () => setState(() {
                        if (_selecionados.length == demandas.length) {
                          _selecionados.clear();
                        } else {
                          _selecionados
                              .addAll(demandas.map((d) => d.id));
                        }
                      }),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red),
                      tooltip: 'Excluir selecionadas',
                      onPressed: _selecionados.isEmpty
                          ? null
                          : _excluirSelecionados,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Cancelar seleção',
                      onPressed: () => setState(() {
                        _modoSelecao = false;
                        _selecionados.clear();
                      }),
                    ),
                  ]
                : [
                    IconButton(
                      icon: const Icon(Icons.checklist_outlined),
                      tooltip: 'Selecionar múltiplos',
                      onPressed: () =>
                          setState(() => _modoSelecao = true),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Ordenar',
                      onSelected: (v) =>
                          setState(() => _ordenacao = v),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: 'mais_recente',
                            child: Text('Mais recente')),
                        PopupMenuItem(
                            value: 'mais_antiga',
                            child: Text('Mais antiga')),
                        PopupMenuItem(
                            value: 'nome_az',
                            child: Text('Nome A-Z')),
                        PopupMenuItem(
                            value: 'nome_za',
                            child: Text('Nome Z-A')),
                        PopupMenuItem(
                            value: 'progresso',
                            child: Text('Maior progresso')),
                      ],
                      icon: const Icon(Icons.sort),
                    ),
                  ],
          ),
          body: Column(
            children: [
              // ── filtro de empresa ────────────────────────────────────
              if (empresas.isNotEmpty)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Empresa',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _chipEmpresa('Todas', null),
                            ...empresas.map(
                                (nome) => _chipEmpresa(nome, nome)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // ── filtro de status ─────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 4),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _chipStatus('Todos', 'todos'),
                          _chipStatus('Paga', 'paga'),
                          _chipStatus('Concluída', 'concluída'),
                          _chipStatus('Parcial', 'parcial'),
                          _chipStatus('Em aberto', 'em aberto'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── busca ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: TextField(
                  onChanged: (v) => setState(() => _busca = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar demanda por nome...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                  ),
                ),
              ),

              // ── contador ─────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${demandas.length} demanda(s)',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (_filtroEmpresa != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withAlpha(18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _filtroEmpresa!,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Divider(height: 1),

              // ── lista de demandas ────────────────────────────────────
              Expanded(
                child: demandas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined,
                                size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              'Nenhuma demanda para este filtro.',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
                        itemCount: demandas.length,
                        itemBuilder: (_, i) =>
                            _buildDemandaTile(demandas[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── chip helpers ─────────────────────────────────────────────────────────

  Widget _chipEmpresa(String label, String? valor) {
    final sel = _filtroEmpresa == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: sel ? Colors.white : AppTheme.primaryColor)),
        selected: sel,
        selectedColor: AppTheme.primaryColor,
        backgroundColor: AppTheme.primaryColor.withAlpha(12),
        side: BorderSide.none,
        onSelected: (_) =>
            setState(() => _filtroEmpresa = valor),
      ),
    );
  }

  Widget _chipStatus(String label, String valor) {
    final sel = _filtroStatus == valor;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: sel ? Colors.white : AppTheme.primaryColor)),
        selected: sel,
        selectedColor: AppTheme.primaryColor,
        backgroundColor: AppTheme.primaryColor.withAlpha(12),
        side: BorderSide.none,
        onSelected: (_) =>
            setState(() => _filtroStatus = valor),
      ),
    );
  }

  // ─── tile de demanda ─────────────────────────────────────────────────────

  Widget _buildDemandaTile(DemandaGeralModel d) {
    final statusColor = _corStatus(d.statusProfissional);
    final expandido = _expandidos.contains(d.id);
    final selecionado = _selecionados.contains(d.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selecionado
            ? const BorderSide(color: AppTheme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: Theme(
        // Remove o divisor interno do ExpansionTile
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey(d.id),
          initiallyExpanded: expandido,
          onExpansionChanged: (v) =>
              setState(() => v ? _expandidos.add(d.id) : _expandidos.remove(d.id)),
          // ── leading: checkbox ou ícone status ─────────────────────
          leading: _modoSelecao
              ? Checkbox(
                  value: selecionado,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selecionados.add(d.id);
                    } else {
                      _selecionados.remove(d.id);
                    }
                  }),
                )
              : Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_iconeStatus(d.statusProfissional),
                      color: statusColor, size: 20),
                ),
          // ── título ────────────────────────────────────────────────
          title: GestureDetector(
            onLongPress: () {
              if (!_modoSelecao) {
                setState(() {
                  _modoSelecao = true;
                  _selecionados.add(d.id);
                });
              }
            },
            child: Text(
              d.nome,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          // ── subtítulo ─────────────────────────────────────────────
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    d.statusProfissional,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_formatDate(d.dataConclusao)} • ${d.empresas.length} empresa(s)',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // ── conteúdo expandido ────────────────────────────────────
          children: [
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Infos gerais
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _infoChip(Icons.business_outlined,
                          '${d.empresas.length} empresa(s)'),
                      _infoChip(
                          Icons.cell_tower, '${d.totalSites} sites'),
                      _infoChip(Icons.check_circle_outline,
                          '${d.sitesConcluidos} concluídos'),
                      _infoChip(Icons.article_outlined,
                          '${d.relatorios.length} relatório(s)'),
                    ],
                  ),

                  // Responsável / observação
                  if (d.responsavelFechamento.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _detalheRow(
                        Icons.person_outline, d.responsavelFechamento),
                  ],
                  if (d.observacaoFechamento.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _detalheRow(
                        Icons.notes, d.observacaoFechamento),
                  ],

                  // Empresas da demanda
                  const SizedBox(height: 10),
                  const Text('Empresas',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  ...d.empresas.map((e) => Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(e.nome,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ),
                            Text(
                              '${e.sitesConcluidos}/${e.totalSites}',
                              style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      )),

                  // Botões de ação
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _excluir(d),
                        icon: const Icon(Icons.delete_outline,
                            size: 16, color: Colors.red),
                        label: const Text('Excluir',
                            style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _duplicar(d),
                        icon: const Icon(Icons.copy_all_outlined,
                            size: 16),
                        label: const Text('Duplicar'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _reabrir(d),
                        icon: const Icon(Icons.restore_page, size: 16),
                        label: const Text('Reabrir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey[600]),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  Widget _detalheRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ),
      ],
    );
  }
}
