import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../controllers/demanda_controller.dart';
import '../models/relatorio_model.dart';
import '../theme/app_theme.dart';

const List<String> _estadosBrasil = [
  'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
  'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN',
  'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
];

class RelatorioDiarioScreen extends StatefulWidget {
  final DemandaController controller;

  const RelatorioDiarioScreen({super.key, required this.controller});

  @override
  State<RelatorioDiarioScreen> createState() => _RelatorioDiarioScreenState();
}

class _RelatorioDiarioScreenState extends State<RelatorioDiarioScreen> {
  DemandaController get ctrl => widget.controller;

  late RelatorioDiario _relatorio;
  String _filtro = 'todos'; // todos, feitos, naoFeitos, pendentes
  String _busca = '';

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

  @override
  void initState() {
    super.initState();
    _criarOuCarregarRelatorioHoje();
    ctrl.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) {
      // Recarregar o relatório atual (mesmo ID) para refletir mudanças
      final idx = ctrl.relatorios.indexWhere((r) => r.id == _relatorio.id);
      if (idx >= 0) {
        _relatorio = ctrl.relatorios[idx];
      } else {
        _criarOuCarregarRelatorioHoje();
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    ctrl.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _criarOuCarregarRelatorioHoje() {
    final hoje = DateTime.now();
    final hojeStr =
        '${hoje.year}-${hoje.month.toString().padLeft(2, '0')}-${hoje.day.toString().padLeft(2, '0')}';

    // Procurar relatório de hoje
    final idx = ctrl.relatorios.indexWhere((r) {
      final d = r.data;
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}' ==
          hojeStr;
    });

    if (idx >= 0) {
      _relatorio = ctrl.relatorios[idx];
      // Atualizar status dos sites existentes com os dados reais
      _atualizarStatusSites(_relatorio);
    } else {
      // Criar novo relatório com os sites da empresa atual, puxando status real
      _relatorio = RelatorioDiario(
        id: 'rel_${DateTime.now().millisecondsSinceEpoch}',
        data: hoje,
        sites: _criarSitesComStatus(hoje),
      );
    }
  }

  /// Atualiza o status dos sites no relatório existente com base nos dados reais da empresa.
  void _atualizarStatusSites(RelatorioDiario relatorio) {
    if (ctrl.empresaAtual == null) return;

    final sitesMap = {for (final s in ctrl.empresaAtual!.sites) s.siteId: s};

    // Remove itens que já não existem mais na aba Sites.
    relatorio.sites.removeWhere((item) => !sitesMap.containsKey(item.siteId));

    for (final item in relatorio.sites) {
      final site = sitesMap[item.siteId];
      if (site == null) continue;

      if (site.isConcluido && site.dataConclusao != null) {
        item.feito = true;
        item.dataExecucao = site.dataConclusao;
        item.motivo = '';
      } else if (site.isNaoConcluido) {
        item.feito = false;
        item.motivo = site.motivoNaoConcluido;
      }
    }

    // Adicionar sites que existem na empresa mas não estão no relatório
    final idsNoRelatorio = relatorio.sites.map((s) => s.siteId).toSet();
    for (final site in ctrl.empresaAtual!.sites) {
      if (!idsNoRelatorio.contains(site.siteId)) {
        final item = RelatorioSiteItem(siteId: site.siteId);
        if (site.isConcluido && site.dataConclusao != null) {
          item.feito = true;
          item.dataExecucao = site.dataConclusao;
          item.motivo = '';
        } else if (site.isNaoConcluido) {
          item.feito = false;
          item.motivo = site.motivoNaoConcluido;
        }
        relatorio.sites.add(item);
      }
    }
  }

  /// Cria lista de RelatorioSiteItem a partir dos sites da empresa atual,
  /// preenchendo o status real (feito, motivo, data) conforme os dados da página de sites.
  List<RelatorioSiteItem> _criarSitesComStatus(DateTime dataRelatorio) {
    final sites = <RelatorioSiteItem>[];
    if (ctrl.empresaAtual == null) return sites;

    for (final site in ctrl.empresaAtual!.sites) {
      final item = RelatorioSiteItem(siteId: site.siteId);

      if (site.isConcluido && site.dataConclusao != null) {
        item.feito = true;
        item.dataExecucao = site.dataConclusao;
        item.motivo = '';
      } else if (site.isNaoConcluido) {
        item.feito = false;
        item.motivo = site.motivoNaoConcluido;
      }

      sites.add(item);
    }
    return sites;
  }

  void _salvar() {
    ctrl.salvarRelatorioAtual(_relatorio);
  }

  List<RelatorioSiteItem> get sitesFiltrados {
    var lista = _relatorio.sites;

    if (_busca.isNotEmpty) {
      lista = lista
          .where((s) =>
              s.siteId.toLowerCase().contains(_busca.toLowerCase()))
          .toList();
    }

    switch (_filtro) {
      case 'feitos':
        lista = lista.where((s) => s.feito).toList();
        break;
      case 'naoFeitos':
        lista = lista.where((s) => !s.feito && s.motivo.isNotEmpty).toList();
        break;
      case 'pendentes':
        lista = lista.where((s) => !s.feito && s.motivo.isEmpty).toList();
        break;
      default:
        break;
    }

    lista.sort((a, b) {
      final aFeitoComData = a.feito && a.dataExecucao != null;
      final bFeitoComData = b.feito && b.dataExecucao != null;

      if (aFeitoComData && bFeitoComData) {
        return b.dataExecucao!.compareTo(a.dataExecucao!);
      }
      if (aFeitoComData && !bFeitoComData) return -1;
      if (!aFeitoComData && bFeitoComData) return 1;

      return a.siteId.compareTo(b.siteId);
    });

    return lista;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCabecalhoProjeto(),
        _buildBarraAcoes(),
        _buildBarraBusca(),
        _buildFiltros(),
        _buildContador(),
        Expanded(child: _buildListaSites()),
        _buildBotoesAcao(),
      ],
    );
  }

  // === BARRA DE AÇÕES (Histórico, Colar) ===
  Widget _buildBarraAcoes() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: _mostrarHistorico,
            icon: const Icon(Icons.history, size: 16),
            label: const Text('Histórico', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _dialogColarSites,
            icon: const Icon(Icons.content_paste_go, size: 16),
            label: const Text('Colar Sites', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accentColor,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  // === CABEÇALHO: Operadora, Projeto, Fabricante, Região ===
  Widget _buildCabecalhoProjeto() {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings_suggest,
                    color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Configuração do Relatório',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: 'Editar Opções',
                  onPressed: _dialogEditarOpcoes,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDropdownChip(
                  label: 'Operadora',
                  value: _relatorio.operadora,
                  icon: Icons.cell_tower,
                  color: Colors.deepPurple,
                  options: ctrl.relatorioConfig.operadoras,
                  onChanged: (v) => setState(() {
                    _relatorio.operadora = v;
                    _salvar();
                  }),
                ),
                _buildDropdownChip(
                  label: 'Fabricante',
                  value: _relatorio.fabricante,
                  icon: Icons.factory,
                  color: Colors.teal,
                  options: ctrl.relatorioConfig.fabricantes,
                  onChanged: (v) => setState(() {
                    _relatorio.fabricante = v;
                    _salvar();
                  }),
                ),
                _buildDropdownChip(
                  label: 'Projeto',
                  value: _relatorio.projeto,
                  icon: Icons.folder,
                  color: Colors.orange,
                  options: ctrl.relatorioConfig.projetos,
                  onChanged: (v) => setState(() {
                    _relatorio.projeto = v;
                    _salvar();
                  }),
                ),
                _buildDropdownChip(
                  label: 'Região',
                  value: _relatorio.regiao,
                  icon: Icons.location_on,
                  color: Colors.red,
                  options: _estadosBrasil,
                  onChanged: (v) => setState(() {
                    _relatorio.regiao = v;
                    _salvar();
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      itemBuilder: (ctx) => options
          .map((o) => PopupMenuItem<String>(
                value: o,
                child: Row(
                  children: [
                    if (o == value)
                      const Icon(Icons.check, size: 16, color: AppTheme.primaryColor)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(o),
                  ],
                ),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value.isEmpty ? label : value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: value.isEmpty ? color.withAlpha(120) : color,
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  // === BARRA DE BUSCA ===
  Widget _buildBarraBusca() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: TextField(
        onChanged: (v) => setState(() => _busca = v),
        decoration: InputDecoration(
          hintText: 'Filtrar sites...',
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  // === FILTROS ===
  Widget _buildFiltros() {
    final feitos = _relatorio.sites.where((s) => s.feito).length;
    final naoFeitos =
        _relatorio.sites.where((s) => !s.feito && s.motivo.isNotEmpty).length;
    final pendentes =
        _relatorio.sites.where((s) => !s.feito && s.motivo.isEmpty).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildChipFiltro(
              'Todos (${_relatorio.sites.length})', 'todos', Icons.list, AppTheme.primaryColor),
          const SizedBox(width: 6),
          _buildChipFiltro(
              'Feitos ($feitos)', 'feitos', Icons.check_circle, AppTheme.successColor),
          const SizedBox(width: 6),
          _buildChipFiltro(
              'Problema ($naoFeitos)', 'naoFeitos', Icons.error, AppTheme.errorColor),
          const SizedBox(width: 6),
          _buildChipFiltro(
              'Pendentes ($pendentes)', 'pendentes', Icons.hourglass_empty, AppTheme.warningColor),
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
          Icon(icon, size: 14, color: isSelected ? Colors.white : color),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : color,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: color.withAlpha(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      visualDensity: VisualDensity.compact,
      onSelected: (_) => setState(() => _filtro = filtro),
    );
  }

  Widget _buildContador() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: _selecionarData,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF283593)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A237E).withAlpha(40),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_filled, size: 14, color: Colors.cyanAccent),
                  const SizedBox(width: 5),
                  Text(
                    _formatDate(_relatorio.data),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.edit_calendar, size: 12, color: Colors.cyanAccent),
                ],
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withAlpha(15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryColor.withAlpha(40)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cell_tower, size: 13, color: AppTheme.primaryColor.withAlpha(180)),
                const SizedBox(width: 4),
                Text(
                  '${sitesFiltrados.length} sites',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryColor.withAlpha(200),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === LISTA DE SITES ===
  Widget _buildListaSites() {
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final site = items[index];
        return _buildSiteItem(site);
      },
    );
  }

  Widget _buildSiteItem(RelatorioSiteItem site) {
    Color bgColor;
    Color borderColor;
    IconData statusIcon;

    if (site.feito) {
      bgColor = AppTheme.successColor.withAlpha(12);
      borderColor = AppTheme.successColor.withAlpha(60);
      statusIcon = Icons.check_circle;
    } else if (site.motivo.isNotEmpty) {
      bgColor = AppTheme.errorColor.withAlpha(12);
      borderColor = AppTheme.errorColor.withAlpha(60);
      statusIcon = Icons.error;
    } else {
      bgColor = Colors.white;
      borderColor = Colors.grey.withAlpha(40);
      statusIcon = Icons.radio_button_unchecked;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _mostrarDialogoSite(site),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Checkbox interativo
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (site.feito) {
                      // Desmarcar
                      site.feito = false;
                      site.dataExecucao = null;
                    } else {
                      // Marcar como feito com a data do relatório atual
                      site.feito = true;
                      site.motivo = '';
                      site.dataExecucao = _relatorio.data;
                    }
                  });
                  _salvar();
                  ctrl.sincronizarRelatorioParaSites(site);
                  _mostrarAvisoAutoEncerramentoSeHouver();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: site.feito
                        ? AppTheme.successColor
                        : site.motivo.isNotEmpty
                            ? AppTheme.errorColor.withAlpha(30)
                            : Colors.grey.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    statusIcon,
                    color: site.feito
                        ? Colors.white
                        : site.motivo.isNotEmpty
                            ? AppTheme.errorColor
                            : Colors.grey,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Info do site
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site.siteId,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: site.feito
                            ? AppTheme.successColor
                            : site.motivo.isNotEmpty
                                ? AppTheme.errorColor
                                : Colors.black87,
                      ),
                    ),
                    if (site.dataExecucao != null)
                      Text(
                        _formatDate(site.dataExecucao!),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    if (site.motivo.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withAlpha(15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          site.motivo,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.errorColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: site.feito
                      ? AppTheme.successColor.withAlpha(20)
                      : site.motivo.isNotEmpty
                          ? AppTheme.errorColor.withAlpha(20)
                          : AppTheme.warningColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  site.feito
                      ? 'FEITO'
                      : site.motivo.isNotEmpty
                          ? 'PROBLEMA'
                          : 'PENDENTE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: site.feito
                        ? AppTheme.successColor
                        : site.motivo.isNotEmpty
                            ? AppTheme.errorColor
                            : AppTheme.warningColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // === DIÁLOGO DE STATUS DO SITE ===
  void _mostrarDialogoSite(RelatorioSiteItem site) {
    final motivoCtrl = TextEditingController(text: site.motivo);
    DateTime dataSelecionada = site.dataExecucao ?? _relatorio.data;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24, 20, 24,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    site.siteId,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status da vistoria TSSR',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
                        setSheetState(() => dataSelecionada = picked);
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

                  // Marcar como FEITO
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          site.feito = true;
                          site.motivo = '';
                          site.dataExecucao = dataSelecionada;
                        });
                        _salvar();
                        ctrl.sincronizarRelatorioParaSites(site);
                        _mostrarAvisoAutoEncerramentoSeHouver();
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content:
                                Text('✅ ${site.siteId} marcado como FEITO em ${_formatDate(dataSelecionada)}'),
                            backgroundColor: AppTheme.successColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle, size: 22),
                      label: const Text('FEITO - VISTORIA REALIZADA',
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

                  // Problema de acesso
                  const Text('Problema de Acesso / Não Feito:',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: motivoCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Descreva o motivo (ex: portão fechado, sem energia...)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (motivoCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Informe o motivo'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                          return;
                        }
                        setState(() {
                          site.feito = false;
                          site.motivo = motivoCtrl.text.trim();
                          site.dataExecucao = dataSelecionada;
                        });
                        _salvar();
                        ctrl.sincronizarRelatorioParaSites(site);
                        _mostrarAvisoAutoEncerramentoSeHouver();
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '❌ ${site.siteId} - problema registrado'),
                            backgroundColor: AppTheme.errorColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.error_outline, size: 22),
                      label: const Text('REGISTRAR PROBLEMA',
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

                  // Resetar
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          site.feito = false;
                          site.motivo = '';
                          site.dataExecucao = null;
                        });
                        _salvar();
                        ctrl.sincronizarRelatorioParaSites(site);
                        _mostrarAvisoAutoEncerramentoSeHouver();
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.restart_alt, size: 22),
                      label: const Text('Resetar para PENDENTE'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.warningColor,
                        side: const BorderSide(color: AppTheme.warningColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
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

  // === BOTÕES DE AÇÃO (RODAPÉ) ===
  Widget _buildBotoesAcao() {
    final feitos = _relatorio.sitesFeitos.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Resumo
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$feitos de ${_relatorio.sites.length} feitos',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    _formatDate(_relatorio.data),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            // Copiar
            IconButton(
              onPressed: _copiarRelatorio,
              icon: const Icon(Icons.copy, size: 20),
              tooltip: 'Copiar',
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue.withAlpha(20),
                foregroundColor: Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            // Compartilhar WhatsApp
            ElevatedButton.icon(
              onPressed: _compartilharWhatsApp,
              icon: const Icon(Icons.share, size: 18),
              label: const Text('WhatsApp',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === AÇÕES ===
  void _copiarRelatorio() {
    final texto = _relatorio.gerarTextoWhatsApp();
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Relatório copiado!'),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _compartilharWhatsApp() {
    final texto = _relatorio.gerarTextoWhatsApp();
    Share.share(texto, subject: 'Relatório Diário TSSR');
  }

  // === HISTÓRICO ===
  void _mostrarHistorico() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final relatorios = ctrl.relatorios;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Histórico de Relatórios',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: relatorios.isEmpty
                      ? Center(
                          child: Text('Nenhum relatório salvo',
                              style: TextStyle(color: Colors.grey[500])),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: relatorios.length,
                          itemBuilder: (context, index) {
                            final r = relatorios[index];
                            final feitos = r.sitesFeitos.length;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withAlpha(20),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${r.data.day}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  _formatDate(r.data),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '✅ $feitos/${r.sites.length} • ${r.operadora} • ${r.fabricante}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.share,
                                          size: 18, color: Color(0xFF25D366)),
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        final texto = r.gerarTextoWhatsApp();
                                        Share.share(texto);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.open_in_new,
                                          size: 18,
                                          color: AppTheme.primaryColor),
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        setState(() {
                                          _relatorio = r;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  setState(() {
                                    _relatorio = r;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // === COLAR SITES ===
  void _dialogColarSites() {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.content_paste, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Colar Sites'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cole os IDs dos sites (um por linha ou separados por vírgula/espaço):',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textCtrl,
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'BASDR_0001\nBASDR_0002\n...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
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
              final text = textCtrl.text.trim();
              if (text.isEmpty) return;

              // Parse: split por linhas, vírgulas, ou espaços
              final ids = text
                  .split(RegExp(r'[\n,;\s]+'))
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();

              // Adicionar à empresa (lista principal de sites)
              ctrl.adicionarSitesEmMassa(ids);

              final existentes =
                  _relatorio.sites.map((s) => s.siteId).toSet();
              int adicionados = 0;
              for (final id in ids) {
                if (!existentes.contains(id)) {
                  _relatorio.sites
                      .add(RelatorioSiteItem(siteId: id));
                  existentes.add(id);
                  adicionados++;
                }
              }

              setState(() {});
              _salvar();
              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '✅ $adicionados novos sites adicionados (${ids.length - adicionados} já existiam)'),
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

  // === EDITAR OPÇÕES (Operadoras, Fabricantes, Projetos) ===
  void _dialogEditarOpcoes() {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.settings, color: AppTheme.primaryColor),
                  SizedBox(width: 8),
                  Text('Editar Opções'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildListaEditavel(
                      titulo: 'Operadoras',
                      icon: Icons.cell_tower,
                      items: ctrl.relatorioConfig.operadoras,
                      onAdd: (v) {
                        ctrl.adicionarOperadora(v);
                        setDialogState(() {});
                      },
                      onRemove: (i) {
                        setDialogState(() {
                          ctrl.relatorioConfig.operadoras.removeAt(i);
                          ctrl.atualizarRelatorioConfig(ctrl.relatorioConfig);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildListaEditavel(
                      titulo: 'Fabricantes',
                      icon: Icons.factory,
                      items: ctrl.relatorioConfig.fabricantes,
                      onAdd: (v) {
                        ctrl.adicionarFabricante(v);
                        setDialogState(() {});
                      },
                      onRemove: (i) {
                        setDialogState(() {
                          ctrl.relatorioConfig.fabricantes.removeAt(i);
                          ctrl.atualizarRelatorioConfig(ctrl.relatorioConfig);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildListaEditavel(
                      titulo: 'Projetos',
                      icon: Icons.folder,
                      items: ctrl.relatorioConfig.projetos,
                      onAdd: (v) {
                        ctrl.adicionarProjeto(v);
                        setDialogState(() {});
                      },
                      onRemove: (i) {
                        setDialogState(() {
                          ctrl.relatorioConfig.projetos.removeAt(i);
                          ctrl.atualizarRelatorioConfig(ctrl.relatorioConfig);
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor),
                  child: const Text('Fechar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildListaEditavel({
    required String titulo,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String> onAdd,
    required ValueChanged<int> onRemove,
  }) {
    final addCtrl = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text(titulo,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            ...List.generate(items.length, (i) {
              return Chip(
                label: Text(items[i], style: const TextStyle(fontSize: 12)),
                deleteIcon:
                    const Icon(Icons.close, size: 16),
                onDeleted: () => onRemove(i),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: addCtrl,
                decoration: InputDecoration(
                  hintText: 'Adicionar...',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                style: const TextStyle(fontSize: 13),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    onAdd(v.trim());
                    addCtrl.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.add_circle,
                  color: AppTheme.primaryColor, size: 28),
              visualDensity: VisualDensity.compact,
              onPressed: () {
                if (addCtrl.text.trim().isNotEmpty) {
                  onAdd(addCtrl.text.trim());
                  addCtrl.clear();
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  void _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _relatorio.data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      // Verificar se já existe relatório para a data selecionada
      final pickedStr =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      final idx = ctrl.relatorios.indexWhere((r) {
        final d = r.data;
        return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}' ==
            pickedStr;
      });

      setState(() {
        if (idx >= 0) {
          // Carregar relatório existente daquela data
          _relatorio = ctrl.relatorios[idx];
        } else {
          // Criar novo relatório para a data selecionada, puxando status real dos sites
          _relatorio = RelatorioDiario(
            id: 'rel_${DateTime.now().millisecondsSinceEpoch}',
            data: picked,
            sites: _criarSitesComStatus(picked),
          );
          _salvar();
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
