import 'package:flutter/material.dart';
import '../controllers/demanda_controller.dart';
import '../models/site_model.dart';
import '../models/empresa_model.dart';
import '../theme/app_theme.dart';
import '../utils/currency_utils.dart';

class SitesListScreen extends StatefulWidget {
  final DemandaController controller;

  const SitesListScreen({super.key, required this.controller});

  @override
  State<SitesListScreen> createState() => _SitesListScreenState();
}

class _SitesListScreenState extends State<SitesListScreen> {
  String _filtro = 'todos';
  String _busca = '';

  DemandaController get ctrl => widget.controller;
  EmpresaModel? get emp => ctrl.empresaAtual;

  void _mostrarAvisoAutoEncerramentoSeHouver() {
    final mensagem = ctrl.consumirMensagemSistemaPendente();
    if (mensagem == null || mensagem.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<MapEntry<int, SiteModel>> get sitesFiltrados {
    if (emp == null) return [];
    var indexed = emp!.sites.asMap().entries.toList();

    if (_busca.isNotEmpty) {
      indexed = indexed
          .where(
              (e) => e.value.siteId.toLowerCase().contains(_busca.toLowerCase()))
          .toList();
    }

    switch (_filtro) {
      case 'concluidos':
        indexed = indexed.where((e) => e.value.isConcluido).toList();
        break;
      case 'naoConcluidos':
        indexed = indexed.where((e) => e.value.isNaoConcluido).toList();
        break;
      case 'pendentes':
        indexed = indexed.where((e) => e.value.isPendente).toList();
        break;
      case 'elegiveis':
        indexed = indexed.where((e) => e.value.participaAdiantamento).toList();
        break;
      case 'semAdiantamento':
        indexed = indexed.where((e) => !e.value.participaAdiantamento).toList();
        break;
      default:
        break;
    }

    indexed.sort((a, b) {
      final sa = a.value;
      final sb = b.value;

      final aConcluidoComData = sa.isConcluido && sa.dataConclusao != null;
      final bConcluidoComData = sb.isConcluido && sb.dataConclusao != null;

      if (aConcluidoComData && bConcluidoComData) {
        return sb.dataConclusao!.compareTo(sa.dataConclusao!);
      }
      if (aConcluidoComData && !bConcluidoComData) return -1;
      if (!aConcluidoComData && bConcluidoComData) return 1;

      return sa.siteId.compareTo(sb.siteId);
    });

    return indexed;
  }

  @override
  void initState() {
    super.initState();
    ctrl.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
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
    return Column(
      children: [
        _buildSearchBar(),
        _buildFiltros(),
        _buildContador(),
        Expanded(child: _buildLista()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: TextField(
        onChanged: (v) => setState(() => _busca = v),
        decoration: InputDecoration(
          hintText: 'Buscar Site ID...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _buildChipFiltro('Todos', 'todos', Icons.list, AppTheme.primaryColor),
          const SizedBox(width: 8),
          _buildChipFiltro(
              'Concluídos', 'concluidos', Icons.check_circle, AppTheme.successColor),
          const SizedBox(width: 8),
          _buildChipFiltro(
              'Não Concl.', 'naoConcluidos', Icons.cancel, AppTheme.errorColor),
          const SizedBox(width: 8),
          _buildChipFiltro(
              'Aguardando', 'pendentes', Icons.schedule, AppTheme.warningColor),
          const SizedBox(width: 8),
          _buildChipFiltro(
              'Elegíveis', 'elegiveis', Icons.done_all, Colors.teal),
          const SizedBox(width: 8),
          _buildChipFiltro(
              'Sem adiant.', 'semAdiantamento', Icons.block, Colors.blueGrey),
        ],
      ),
    );
  }

  Widget _buildChipFiltro(
      String label, String filtro, IconData icon, Color color) {
    final isSelected = _filtro == filtro;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : color),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : color,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      backgroundColor: color.withAlpha(25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => setState(() => _filtro = filtro),
    );
  }

  Widget _buildContador() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${sitesFiltrados.length} sites',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            CurrencyUtils.formatBRL(
              sitesFiltrados.where((e) => e.value.isConcluido).length *
                  emp!.valorPorSite,
            ),
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.successColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    final items = sitesFiltrados;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cell_tower, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Nenhum site encontrado',
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length + 1, // +1 para botão adicionar
      itemBuilder: (context, listIndex) {
        if (listIndex == items.length) {
          return _buildBotaoAdicionarSite();
        }
        final entry = items[listIndex];
        final index = entry.key;
        final site = entry.value;
        return Dismissible(
          key: ValueKey('${emp!.id}_${site.siteId}_$index'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppTheme.errorColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Remover Site?'),
                content: Text('Deseja remover ${site.siteId}?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Não'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor),
                    child: const Text('Sim, remover'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) {
            ctrl.removerSite(index);
          },
          child: _buildSiteCard(site, index, listIndex),
        );
      },
    );
  }

  Widget _buildBotaoAdicionarSite() {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.primaryColor.withAlpha(60), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _dialogAdicionarSite,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline,
                  color: AppTheme.primaryColor.withAlpha(160)),
              const SizedBox(width: 8),
              Text(
                'Adicionar Novo Site',
                style: TextStyle(
                  color: AppTheme.primaryColor.withAlpha(160),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _dialogAdicionarSite() {
    final siteIdController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cell_tower, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Novo Site'),
          ],
        ),
        content: TextField(
          controller: siteIdController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Site ID',
            hintText: 'Ex: BASDR_0001',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final id = siteIdController.text.trim();
              if (id.isEmpty) return;
              ctrl.adicionarSite(id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Site $id adicionado!'),
                  backgroundColor: AppTheme.successColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSiteCard(SiteModel site, int index, int listIndex) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (site.status) {
      case SiteStatus.concluido:
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        statusText = 'TSSR CONCLUÍDO';
        break;
      case SiteStatus.naoConcluido:
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.cancel;
        statusText = 'NÃO CONCLUÍDO';
        break;
      case SiteStatus.pendente:
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.schedule;
        statusText = 'AGUARDANDO TSSR';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: statusColor.withAlpha(60), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _mostrarDialogoStatus(index, site),
        onLongPress: () => _confirmarExclusaoSite(index, site),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(statusIcon, color: statusColor, size: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          site.siteId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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
                        CurrencyUtils.formatBRL(emp!.valorPorSite),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: site.isConcluido
                              ? AppTheme.successColor
                              : Colors.grey,
                          decoration: site.isNaoConcluido
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      Text(
                        '#${(listIndex + 1).toString().padLeft(2, '0')}',
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              if (site.isNaoConcluido && site.motivoNaoConcluido.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: AppTheme.errorColor.withAlpha(160)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          site.motivoNaoConcluido,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.errorColor.withAlpha(200),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!site.participaAdiantamento)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.block_flipped,
                          size: 14, color: Colors.blueGrey[700]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Este site nao conta para lote de adiantamento',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blueGrey[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (site.isConcluido && site.dataConclusao != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        'Concluído em: ${_formatDate(site.dataConclusao!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoStatus(int index, SiteModel site) {
    final motivoController =
        TextEditingController(text: site.motivoNaoConcluido);
    DateTime dataSelecionada = site.dataConclusao ?? DateTime.now();
    bool participaAdiantamento = site.participaAdiantamento;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setBottomState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    site.siteId,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Atualizar Status da Atividade TSSR',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Seletor de data
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dataSelecionada,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setBottomState(() => dataSelecionada = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withAlpha(15),
                        border: Border.all(color: AppTheme.primaryColor.withAlpha(60)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20, color: AppTheme.primaryColor),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data da atividade',
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                              ),
                              Text(
                                _formatDate(dataSelecionada),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Icon(Icons.edit_calendar, size: 18, color: AppTheme.primaryColor.withAlpha(120)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Conta para adiantamento',
                        style: TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        participaAdiantamento
                            ? 'Este site entra no lote de adiantamento'
                            : 'Este site fica fora da contagem do lote',
                        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      ),
                      value: participaAdiantamento,
                      onChanged: (v) {
                        setBottomState(() => participaAdiantamento = v);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Botão OK
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ctrl.atualizarParticipacaoAdiantamentoSite(
                            index, participaAdiantamento);
                        ctrl.atualizarStatus(index, SiteStatus.concluido, dataConclusao: dataSelecionada);
                        _mostrarAvisoAutoEncerramentoSeHouver();
                        Navigator.pop(ctx);
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '✅ ${site.siteId} marcado como CONCLUÍDO em ${_formatDate(dataSelecionada)}'),
                            backgroundColor: AppTheme.successColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle, size: 22),
                      label: const Text('OK - TSSR CONCLUÍDO',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
              ),
              const SizedBox(height: 12),
              // Botão NÃO OK
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: ctx,
                      builder: (dialogCtx) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text('Motivo - Não Concluído'),
                        content: TextField(
                          controller: motivoController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText:
                                'Descreva o motivo da não conclusão...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              ctrl.atualizarParticipacaoAdiantamentoSite(
                                  index, participaAdiantamento);
                              ctrl.atualizarStatus(
                                index,
                                SiteStatus.naoConcluido,
                                motivo: motivoController.text,
                              );
                              _mostrarAvisoAutoEncerramentoSeHouver();
                              Navigator.pop(dialogCtx);
                              Navigator.pop(ctx);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '❌ ${site.siteId} marcado como NÃO CONCLUÍDO'),
                                  backgroundColor: AppTheme.errorColor,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.errorColor,
                            ),
                            child: const Text('Confirmar'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.cancel, size: 22),
                  label: const Text('NÃO OK - NÃO CONCLUÍDO',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Botão Resetar para Pendente
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ctrl.atualizarParticipacaoAdiantamentoSite(
                        index, participaAdiantamento);
                    ctrl.atualizarStatus(index, SiteStatus.pendente);
                    _mostrarAvisoAutoEncerramentoSeHouver();
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                  icon: const Icon(Icons.restart_alt, size: 22),
                  label: const Text('Resetar para AGUARDANDO'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.warningColor,
                    side: const BorderSide(color: AppTheme.warningColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
          },
        );
      },
    );
  }

  void _confirmarExclusaoSite(int index, SiteModel site) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: AppTheme.errorColor),
            const SizedBox(width: 8),
            Expanded(child: Text('Excluir ${site.siteId}?')),
          ],
        ),
        content: const Text(
          'Este site será removido permanentemente.\n'
          'Use esta opção quando o site for cancelado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              ctrl.removerSite(index);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🗑️ Site ${site.siteId} removido'),
                  backgroundColor: AppTheme.errorColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.delete_forever),
            label: const Text('Excluir Site'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
