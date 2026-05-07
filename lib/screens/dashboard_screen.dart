import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../controllers/demanda_controller.dart';
import '../models/demanda_geral_model.dart';
import '../models/empresa_model.dart';
import '../models/site_model.dart';
import '../theme/app_theme.dart';
import 'sites_list_screen.dart';
import 'adiantamentos_screen.dart';
import 'exportar_screen.dart';
import 'empresa_form_screen.dart';
import 'relatorio_diario_screen.dart';
import 'login_screen.dart';
import '../utils/currency_utils.dart';
import 'historico_demandas_screen.dart';

class DashboardScreen extends StatefulWidget {
  final DemandaController controller;

  const DashboardScreen({super.key, required this.controller});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _driveConectado = false;

  DemandaController get ctrl => widget.controller;
  EmpresaModel? get emp => ctrl.empresaAtual;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    ctrl.addListener(_onUpdate);
    _verificarStatusDrive();
  }

  Future<void> _verificarStatusDrive() async {
    final conectado = await ctrl.verificarConexaoDrive();
    if (mounted) setState(() => _driveConectado = conectado);
  }

  Future<void> _alternarConexaoDrive() async {
    if (_driveConectado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.cloud_done, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Drive conectado. Backup automático ativo.'),
            ],
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final ok = await ctrl.conectarDriveInterativo();
    if (mounted) {
      setState(() => _driveConectado = ok);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                ok ? Icons.cloud_done : Icons.cloud_off,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(ok
                  ? 'Drive conectado! Backup automático ativo.'
                  : 'Não foi possível conectar ao Drive.'),
            ],
          ),
          backgroundColor: ok ? AppTheme.successColor : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ctrl.removeListener(_onUpdate);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(innerBoxIsScrolled),
        ],
        body: ctrl.empresas.isEmpty
            ? _buildEmptyState()
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboardTab(),
                  SitesListScreen(controller: ctrl),
                  AdiantamentosScreen(controller: ctrl),
                  RelatorioDiarioScreen(controller: ctrl),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Nenhuma empresa cadastrada',
              style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _abrirFormEmpresa(),
            icon: const Icon(Icons.add_business),
            label: const Text('Cadastrar Empresa'),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(bool innerBoxIsScrolled) {
    return SliverAppBar(
      toolbarHeight: 88,
      floating: false,
      pinned: true,
      forceElevated: innerBoxIsScrolled,
      backgroundColor: const Color(0xFF0D1642),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1642), Color(0xFF1A237E), Color(0xFF283593)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.secondaryColor.withAlpha(70),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/logo_vc.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DEMANDA CONTROLLER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'TSSR • ${ctrl.empresas.isNotEmpty ? ctrl.empresaAtual?.nome ?? '' : 'Sem empresa'}',
                  style: TextStyle(
                    color: AppTheme.secondaryColor.withAlpha(230),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_business),
          tooltip: 'Nova Empresa',
          onPressed: () => _abrirFormEmpresa(),
        ),
        IconButton(
          icon: Icon(
            _driveConectado ? Icons.cloud_done : Icons.cloud_off,
            color: _driveConectado
                ? AppTheme.successColor
                : Colors.white54,
            size: 22,
          ),
          tooltip: _driveConectado
              ? 'Drive conectado'
              : 'Conectar ao Drive',
          onPressed: _alternarConexaoDrive,
        ),
        IconButton(
          icon: const Icon(Icons.file_download),
          tooltip: 'Exportar',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ExportarScreen(controller: ctrl),
            ),
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'Mais opções',
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onSelected: (value) {
            switch (value) {
              case 'concluir_demanda_geral':
                _concluirDemandaGeral();
                break;
              case 'historico_demandas':
                _abrirHistoricoDemandas();
                break;
              case 'compartilhar':
                _compartilhar();
                break;
              case 'restaurar':
                _restaurarBackup();
                break;
              case 'excluir_conta':
                _abrirExcluirContaEDados();
                break;
              case 'sair':
                _sair();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'concluir_demanda_geral',
              enabled: ctrl.temDemandaAtiva,
              child: Row(
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 20,
                    color: ctrl.temDemandaAtiva ? Colors.green[700] : Colors.grey[500],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    ctrl.temDemandaAtiva
                        ? 'Concluir Demanda Geral'
                        : 'Concluir Demanda (sem dados ativos)',
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'historico_demandas',
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 20, color: Colors.blueGrey[700]),
                  const SizedBox(width: 12),
                  const Text('Histórico de Demandas'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'compartilhar',
              child: Row(
                children: [
                  Icon(Icons.share, size: 20, color: Colors.grey[700]),
                  const SizedBox(width: 12),
                  const Text('Compartilhar'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'restaurar',
              child: Row(
                children: [
                  Icon(Icons.cloud_download_rounded, size: 20, color: Colors.orange[700]),
                  const SizedBox(width: 12),
                  const Text('Restaurar Backup'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'excluir_conta',
              child: Row(
                children: [
                  Icon(Icons.delete_forever, size: 20, color: Colors.red[700]),
                  const SizedBox(width: 12),
                  Text('Excluir Conta e Dados', style: TextStyle(color: Colors.red[700])),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'sair',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red[700]),
                  const SizedBox(width: 12),
                  Text('Sair', style: TextStyle(color: Colors.red[700])),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1642).withAlpha(200),
            border: Border(
              top: BorderSide(
                color: AppTheme.secondaryColor.withAlpha(40),
                width: 0.5,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.secondaryColor,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: AppTheme.secondaryColor,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
            tabs: const [
              Tab(icon: Icon(Icons.dashboard_rounded, size: 20), text: 'Dashboard'),
              Tab(icon: Icon(Icons.cell_tower_rounded, size: 20), text: 'Sites'),
              Tab(icon: Icon(Icons.account_balance_wallet_rounded, size: 20), text: 'Adiant.'),
              Tab(icon: Icon(Icons.assignment_rounded, size: 20), text: 'Relatório'),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirFormEmpresa({int? editIndex}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmpresaFormScreen(
          controller: ctrl,
          editIndex: editIndex,
        ),
      ),
    );
  }

  Future<void> _confirmarExcluirEmpresa(int index) async {
    if (index < 0 || index >= ctrl.empresas.length) return;
    final empresa = ctrl.empresas[index];

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir empresa?'),
        content: Text(
          'Deseja excluir a empresa "${empresa.nome}"? Todos os sites, adiantamentos e lançamentos dela serão removidos da demanda ativa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    ctrl.removerEmpresa(index);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Empresa "${empresa.nome}" excluída com sucesso.'),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _abrirExcluirContaEDados() async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExportarScreen(controller: ctrl),
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Na tela de Exportar, use a opção "Excluir Conta e Dados".',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sair() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja sair da conta? Precisará fazer login novamente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(controller: widget.controller),
      ),
      (_) => false,
    );
  }

  Future<void> _restaurarBackup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.cloud_download_rounded, color: Colors.orange, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Restaurar Backup', style: TextStyle(fontSize: 18)),
                  Text('Importar dados salvos', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal)),
                ],
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.orange.withAlpha(10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withAlpha(40)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Todos os dados atuais serão substituídos pelos dados do arquivo de backup.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[600], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selecione o arquivo .json gerado pelo "Fazer Backup" na tela de Exportar.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.cloud_download_rounded, size: 18),
            label: const Text('Selecionar Arquivo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final jsonStr = await file.readAsString();

      final sucesso = await ctrl.restaurarBackupJson(jsonStr);

      if (mounted) {
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
              duration: const Duration(seconds: 3),
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
      if (mounted) {
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

  void _compartilhar() {
    final texto = ctrl.gerarTextoCompartilhamento();
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Relatório copiado! Cole no WhatsApp.'),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _concluirDemandaGeral() async {
    if (!ctrl.temDemandaAtiva) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sem demanda ativa para concluir.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final nomeCtrl = TextEditingController();
    final responsavelCtrl = TextEditingController();
    final observacaoCtrl = TextEditingController();
    final nomeSugerido = (ctrl.nomeDemandaSugerido ?? '').trim();
    final responsavelSugerido =
        (ctrl.responsavelFechamentoSugerido ?? '').trim();
    bool usarMesmoNome = nomeSugerido.isNotEmpty;
    String? nomeErro;
    if (usarMesmoNome) {
      nomeCtrl.text = nomeSugerido;
    }
    if (responsavelSugerido.isNotEmpty) {
      responsavelCtrl.text = responsavelSugerido;
    }
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.task_alt, color: Colors.green),
              SizedBox(width: 8),
              Text('Concluir Demanda Geral'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'A demanda atual será arquivada com todos os dados e as abas serão limpas para iniciar uma nova.',
              ),
              if (nomeSugerido.isNotEmpty) ...[
                const SizedBox(height: 10),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: usarMesmoNome,
                  onChanged: (v) {
                    setDialogState(() {
                      usarMesmoNome = v ?? false;
                      if (usarMesmoNome) {
                        nomeCtrl.text = nomeSugerido;
                        nomeErro = null;
                      }
                    });
                  },
                  title: const Text('Concluir com o mesmo nome'),
                  subtitle: Text(nomeSugerido),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: nomeCtrl,
                enabled: !usarMesmoNome,
                onChanged: (_) => setDialogState(() => nomeErro = null),
                decoration: InputDecoration(
                  labelText: 'Nome da demanda',
                  hintText: 'Ex: PRCELL Abril/2026',
                  errorText: nomeErro,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: responsavelCtrl,
                decoration: InputDecoration(
                  labelText: 'Responsável pelo fechamento',
                  hintText: 'Ex: Vanderlei',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: observacaoCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Observação final',
                  hintText: 'Resumo do ciclo, pendências, notas...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final nomeDigitado = usarMesmoNome ? nomeSugerido : nomeCtrl.text.trim();
                if (nomeDigitado.isEmpty) {
                  setDialogState(() => nomeErro = 'Informe um nome para a demanda');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Concluir e Limpar'),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true) return;

    final concluiu = await ctrl.concluirDemandaGeral(
      nome: nomeCtrl.text,
      responsavel: responsavelCtrl.text,
      observacao: observacaoCtrl.text,
      usarNomeSugerido: usarMesmoNome,
    );
    if (!concluiu) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um nome para concluir e arquivar a demanda.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _tabController.animateTo(0);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Demanda concluída e arquivada. Pronto para iniciar uma nova demanda.',
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _abrirHistoricoDemandas() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoricoDemandasScreen(controller: ctrl),
      ),
    );
  }

  void _abrirHistoricoDemandasLegado() {
    String filtroStatus = 'todos';
    String busca = '';
    String ordenacao = 'mais_recente';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            var demandas = ctrl.demandasArquivadasPorStatus(filtroStatus);
            if (busca.trim().isNotEmpty) {
              final q = busca.toLowerCase();
              demandas = demandas
                  .where((d) => d.nome.toLowerCase().contains(q))
                  .toList();
            }

            demandas.sort((a, b) {
              switch (ordenacao) {
                case 'mais_antiga':
                  return a.dataConclusao.compareTo(b.dataConclusao);
                case 'nome_az':
                  return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
                case 'nome_za':
                  return b.nome.toLowerCase().compareTo(a.nome.toLowerCase());
                case 'progresso':
                  final pa = a.totalSites == 0 ? 0.0 : a.sitesConcluidos / a.totalSites;
                  final pb = b.totalSites == 0 ? 0.0 : b.sitesConcluidos / b.totalSites;
                  return pb.compareTo(pa);
                case 'mais_recente':
                default:
                  return b.dataConclusao.compareTo(a.dataConclusao);
              }
            });

            final demandasFiltradas = demandas;

            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.3,
              maxChildSize: 0.92,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Demandas Arquivadas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (v) => setModalState(() => busca = v),
                              decoration: InputDecoration(
                                hintText: 'Buscar demanda por nome...',
                                prefixIcon: const Icon(Icons.search, size: 18),
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            tooltip: 'Ordenar',
                            onSelected: (v) => setModalState(() => ordenacao = v),
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'mais_recente', child: Text('Mais recente')),
                              PopupMenuItem(value: 'mais_antiga', child: Text('Mais antiga')),
                              PopupMenuItem(value: 'nome_az', child: Text('Nome A-Z')),
                              PopupMenuItem(value: 'nome_za', child: Text('Nome Z-A')),
                              PopupMenuItem(value: 'progresso', child: Text('Maior progresso')),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withAlpha(15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.sort, color: AppTheme.primaryColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            tooltip: 'Exportar filtro',
                            onSelected: (v) async {
                              if (v == 'pdf') {
                                await _exportarHistoricoFiltradoPdf(demandasFiltradas);
                              } else if (v == 'excel') {
                                await _exportarHistoricoFiltradoExcel(demandasFiltradas);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'pdf', child: Text('Exportar PDF')),
                              PopupMenuItem(value: 'excel', child: Text('Exportar Excel')),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor.withAlpha(15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.file_download, color: AppTheme.successColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          _buildFiltroHistorico('Todos', 'todos', filtroStatus,
                              () => setModalState(() => filtroStatus = 'todos')),
                          _buildFiltroHistorico('Paga', 'paga', filtroStatus,
                              () => setModalState(() => filtroStatus = 'paga')),
                          _buildFiltroHistorico('Concluída', 'concluída', filtroStatus,
                              () => setModalState(() => filtroStatus = 'concluída')),
                          _buildFiltroHistorico('Parcial', 'parcial', filtroStatus,
                              () => setModalState(() => filtroStatus = 'parcial')),
                          _buildFiltroHistorico('Em aberto', 'em aberto', filtroStatus,
                              () => setModalState(() => filtroStatus = 'em aberto')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: demandas.isEmpty
                          ? Center(
                              child: Text(
                                'Nenhuma demanda para este filtro.',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: demandas.length,
                              itemBuilder: (context, index) {
                                final d = demandas[index];
                                final statusColor = _statusDemandaColor(d.statusProfissional);
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    leading: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: statusColor.withAlpha(18),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        _statusDemandaIcon(d.statusProfissional),
                                        color: statusColor,
                                      ),
                                    ),
                                    title: Text(
                                      d.nome,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_formatDate(d.dataConclusao)} • ${d.empresas.length} empresa(s) • ${d.totalSites} sites • ${d.sitesConcluidos} concluídos',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: statusColor.withAlpha(20),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            d.statusProfissional,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.visibility_outlined, color: AppTheme.primaryColor),
                                          tooltip: 'Detalhes',
                                          onPressed: () => _abrirDetalhesDemanda(d, ctx),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy_all_outlined, color: AppTheme.primaryColor),
                                          tooltip: 'Duplicar como novo ciclo',
                                          onPressed: () => _duplicarDemandaDoHistorico(d.id, d.nome, ctx),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.restore_page, color: AppTheme.primaryColor),
                                          tooltip: 'Reabrir esta demanda',
                                          onPressed: () => _reabrirDemandaDoHistorico(d.id, d.nome, ctx),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          tooltip: 'Excluir demanda arquivada',
                                          onPressed: () => _excluirDemandaDoHistorico(d.id, d.nome, ctx),
                                        ),
                                      ],
                                    ),
                                    onTap: () => _abrirDetalhesDemanda(d, ctx),
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
      },
    );
  }

  Widget _buildFiltroHistorico(
      String label, String value, String atual, VoidCallback onTap) {
    final selected = value == atual;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        backgroundColor: AppTheme.primaryColor.withAlpha(15),
      ),
    );
  }

  void _abrirDetalhesDemanda(DemandaGeralModel demanda, BuildContext sheetContext) {
    showDialog(
      context: context,
      builder: (ctx) {
        final statusColor = _statusDemandaColor(demanda.statusProfissional);
        final eventos = ctrl.eventosDaDemanda(demanda.id).take(8).toList();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(demanda.nome),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  demanda.statusProfissional,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fechada em: ${_formatDate(demanda.dataConclusao)}'),
                  const SizedBox(height: 4),
                  Text('Empresas: ${demanda.empresas.length}'),
                  Text('Sites: ${demanda.totalSites}'),
                  Text('Concluídos: ${demanda.sitesConcluidos}'),
                  Text('Relatórios salvos: ${demanda.relatorios.length}'),
                  if (demanda.responsavelFechamento.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Responsável',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(demanda.responsavelFechamento),
                  ],
                  if (demanda.observacaoFechamento.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Observação final',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(demanda.observacaoFechamento),
                  ],
                  const SizedBox(height: 12),
                  const Text(
                    'Empresas da demanda',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  ...demanda.empresas.map((e) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.nome,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              '${e.sitesConcluidos}/${e.totalSites}',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )),
                  if (eventos.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Eventos de auditoria',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    ...eventos.map((ev) => Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withAlpha(12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.event_note, size: 16, color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ev.descricao,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      '${ev.acao.toUpperCase()} • ${_formatDateTime(ev.dataHora)}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fechar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _reabrirDemandaDoHistorico(demanda.id, demanda.nome, sheetContext);
              },
              icon: const Icon(Icons.restore_page),
              label: const Text('Reabrir'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _duplicarDemandaDoHistorico(demanda.id, demanda.nome, sheetContext);
              },
              icon: const Icon(Icons.copy_all_outlined),
              label: const Text('Duplicar ciclo'),
            ),
          ],
        );
      },
    );
  }

  Color _statusDemandaColor(String status) {
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

  IconData _statusDemandaIcon(String status) {
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

  Future<void> _reabrirDemandaDoHistorico(
      String demandaId, String nomeDemanda, BuildContext sheetContext) async {
    bool manterDatasOriginais = true;
    DateTime novaDataBase = DateTime.now();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  'Deseja restaurar a demanda "$nomeDemanda"?\n\nOs dados atuais serão substituídos pelos dados desta demanda.',
                ),
                const SizedBox(height: 14),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: manterDatasOriginais,
                  onChanged: (value) {
                    setDialogState(() => manterDatasOriginais = value);
                  },
                  title: const Text('Manter datas originais'),
                  subtitle: const Text('Sites, relatórios e fechamentos serão restaurados com as datas gravadas.'),
                ),
                if (!manterDatasOriginais)
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: novaDataBase,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setDialogState(() => novaDataBase = picked);
                      }
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
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.restore_page, size: 18),
              label: const Text('Reabrir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true || !mounted) return;

    Navigator.pop(sheetContext);
    final ok = await ctrl.reabrirDemandaGeral(
      demandaId,
      manterDatasOriginais: manterDatasOriginais,
      novaDataBase: manterDatasOriginais ? null : novaDataBase,
    );
    if (!mounted || !ok) return;

    _tabController.animateTo(0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demanda "$nomeDemanda" reaberta com sucesso.'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _duplicarDemandaDoHistorico(
      String demandaId, String nomeDemanda, BuildContext sheetContext) async {
    Navigator.pop(sheetContext);
    final ok = await ctrl.duplicarDemandaArquivadaParaNovoCiclo(demandaId);
    if (!mounted || !ok) return;

    _tabController.animateTo(0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Novo ciclo criado a partir de "$nomeDemanda".'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _excluirDemandaDoHistorico(
      String demandaId, String nomeDemanda, BuildContext sheetContext) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Excluir Demanda'),
          ],
        ),
        content: Text(
          'Deseja excluir permanentemente "$nomeDemanda" do histórico?\n\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
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

    final ok = await ctrl.excluirDemandaArquivada(demandaId);
    if (!mounted || !ok) return;

    Navigator.pop(sheetContext);
    _abrirHistoricoDemandas();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demanda "$nomeDemanda" removida do histórico.'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _exportarHistoricoFiltradoPdf(
      List<DemandaGeralModel> demandas) async {
    if (demandas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não há dados para exportar neste filtro.')),
      );
      return;
    }

    final pdf = pw.Document();
    final now = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          pw.Text(
            'Historico de Demandas (filtrado)',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Gerado em ${_formatDateTime(now)}'),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.6),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _pdfCell('Demanda', header: true),
                  _pdfCell('Status', header: true),
                  _pdfCell('Data', header: true),
                  _pdfCell('Empresas', header: true),
                  _pdfCell('Concluidos', header: true),
                ],
              ),
              ...demandas.map((d) => pw.TableRow(
                    children: [
                      _pdfCell(d.nome),
                      _pdfCell(d.statusProfissional),
                      _pdfCell(_formatDate(d.dataConclusao)),
                      _pdfCell('${d.empresas.length}'),
                      _pdfCell('${d.sitesConcluidos}/${d.totalSites}'),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/historico_demandas_filtrado_${now.millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Historico de Demandas (PDF)',
      text: 'Exportacao PDF do historico filtrado de demandas.',
    );
  }

  Future<void> _exportarHistoricoFiltradoExcel(
      List<DemandaGeralModel> demandas) async {
    if (demandas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não há dados para exportar neste filtro.')),
      );
      return;
    }

    final excel = ex.Excel.createExcel();
    final sheet = excel['Historico'];

    sheet.cell(ex.CellIndex.indexByString('A1')).value =
      ex.TextCellValue('Demanda');
    sheet.cell(ex.CellIndex.indexByString('B1')).value =
      ex.TextCellValue('Status');
    sheet.cell(ex.CellIndex.indexByString('C1')).value =
      ex.TextCellValue('Data');
    sheet.cell(ex.CellIndex.indexByString('D1')).value =
      ex.TextCellValue('Empresas');
    sheet.cell(ex.CellIndex.indexByString('E1')).value =
      ex.TextCellValue('Sites');
    sheet.cell(ex.CellIndex.indexByString('F1')).value =
      ex.TextCellValue('Concluidos');
    sheet.cell(ex.CellIndex.indexByString('G1')).value =
      ex.TextCellValue('Responsavel');

    for (int i = 0; i < demandas.length; i++) {
      final row = i + 2;
      final d = demandas[i];
        sheet.cell(ex.CellIndex.indexByString('A$row')).value =
          ex.TextCellValue(d.nome);
        sheet.cell(ex.CellIndex.indexByString('B$row')).value =
          ex.TextCellValue(d.statusProfissional);
        sheet.cell(ex.CellIndex.indexByString('C$row')).value =
          ex.TextCellValue(_formatDate(d.dataConclusao));
        sheet.cell(ex.CellIndex.indexByString('D$row')).value =
          ex.IntCellValue(d.empresas.length);
        sheet.cell(ex.CellIndex.indexByString('E$row')).value =
          ex.IntCellValue(d.totalSites);
        sheet.cell(ex.CellIndex.indexByString('F$row')).value =
          ex.IntCellValue(d.sitesConcluidos);
        sheet.cell(ex.CellIndex.indexByString('G$row')).value =
          ex.TextCellValue(d.responsavelFechamento);
    }

    final bytes = excel.encode();
    if (bytes == null) return;

    final now = DateTime.now();
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/historico_demandas_filtrado_${now.millisecondsSinceEpoch}.xlsx',
    );
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Historico de Demandas (Excel)',
      text: 'Exportacao Excel do historico filtrado de demandas.',
    );
  }

  pw.Widget _pdfCell(String text, {bool header = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDashboardTab() {
    if (emp == null) return const SizedBox();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seletor de empresa
          _buildEmpresaSelector(),
          const SizedBox(height: 12),

          // Botão colar sites
          _buildBotaoColarSites(),
          const SizedBox(height: 12),

          // Status de pagamento
          _buildStatusPagamento(),
          const SizedBox(height: 12),

          // Cards de resumo
          _buildResumoCards(),
          const SizedBox(height: 20),

          // Gráfico
          _buildGraficoProgresso(),
          const SizedBox(height: 20),

          // Valores financeiros
          _buildValoresFinanceiros(),
          const SizedBox(height: 20),

          // Referência por lote
          if (emp!.tipoAdiantamento == TipoAdiantamento.percentualPorLote)
            _buildReferenciaLote(),
          if (emp!.tipoAdiantamento == TipoAdiantamento.percentualPorLote)
            const SizedBox(height: 20),

          // Progresso do lote
          _buildProgressoLote(),
          const SizedBox(height: 20),

          // Resumo global
          if (ctrl.empresas.length > 1) _buildResumoGlobal(),
          if (ctrl.empresas.length > 1) const SizedBox(height: 20),

          // Ações da demanda
          _buildAcoesDemanda(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildAcoesDemanda() {
    final podeConcluir = ctrl.temDemandaAtiva;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings_applications, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Gerenciar Demanda',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _abrirHistoricoDemandas,
                    icon: const Icon(Icons.inventory_2_outlined, size: 18),
                    label: const Text('Ver Histórico'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: podeConcluir ? _concluirDemandaGeral : null,
                    icon: const Icon(Icons.task_alt, size: 18),
                    label: const Text('Concluir e Arquivar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: podeConcluir ? Colors.green[700] : Colors.grey[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            if (!podeConcluir) ...[
              const SizedBox(height: 8),
              Text(
                'Sem dados ativos para concluir agora.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmpresaSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.business, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Empresa',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () =>
                      _abrirFormEmpresa(editIndex: ctrl.empresaSelecionadaIndex),
                  tooltip: 'Editar empresa',
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: ctrl.empresas.length,
                itemBuilder: (context, index) {
                  final e = ctrl.empresas[index];
                  final isSelected = index == ctrl.empresaSelecionadaIndex;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onLongPress: () => _confirmarExcluirEmpresa(index),
                      child: ChoiceChip(
                        label: Text(e.nome),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: AppTheme.primaryColor.withAlpha(20),
                        onSelected: (_) => ctrl.selecionarEmpresa(index),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Dica: pressione e segure uma empresa para excluir.',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      '${emp!.tipoAdiantamentoDescricao} • ${_formatCurrency(emp!.valorPorSite)}/site',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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

  Widget _buildStatusPagamento() {
    final temAdiantamento = emp!.adiantamentos.isNotEmpty;
    LinearGradient gradient;
    IconData statusIcon;
    String titulo;
    String? subtitulo;

    if (emp!.foiPago) {
      gradient = AppTheme.successGradient;
      statusIcon = Icons.check_circle;
      titulo = 'PAGO';
      if (emp!.dataPagamento != null) {
        subtitulo = 'Pago em ${_formatDate(emp!.dataPagamento!)} - ${_formatCurrency(emp!.valorPago)}';
      }
    } else if (!temAdiantamento && emp!.tipoAdiantamento != TipoAdiantamento.semAdiantamento) {
      gradient = AppTheme.warningGradient;
      statusIcon = Icons.rocket_launch;
      titulo = 'INICIAR 1° ADIANTAMENTO (${(emp!.percentualAdiantamento * 100).toStringAsFixed(0)}%)';
      subtitulo = 'Toque para registrar: ${_formatCurrency(emp!.valorAdiantamentoLote)}';
    } else if (emp!.precisaSolicitarAdiantamento) {
      gradient = AppTheme.warningGradient;
      statusIcon = Icons.rocket_launch;
      final numAdiant = emp!.adiantamentos.length + 1;
      final sitesSemCobertura = emp!.sitesElegiveisSemCoberturaAdiantamento;
      titulo = 'SOLICITAR $numAdiant° ADIANTAMENTO';
      subtitulo = sitesSemCobertura == emp!.sitesPorLote
          ? 'Lote de ${emp!.sitesPorLote} sites concluído! Toque para registrar: ${_formatCurrency(emp!.valorAdiantamentoLote)}'
          : '$sitesSemCobertura ${sitesSemCobertura == 1 ? 'site novo sem cobertura' : 'sites novos sem cobertura'} • Toque para registrar: ${_formatCurrency(emp!.valorAdiantamentoLote)}';
    } else if (temAdiantamento && emp!.tipoAdiantamento == TipoAdiantamento.percentualPorLote) {
      final semCobertura = emp!.sitesElegiveisSemCoberturaAdiantamento;
      if (semCobertura == 0) {
        gradient = AppTheme.successGradient;
        statusIcon = Icons.verified;
        titulo = 'TODOS OS CPS COBERTOS';
        subtitulo = 'Nao ha lote pendente no momento. Aguarde novos sites concluidos.';
      } else {
        gradient = AppTheme.accentGradient;
        statusIcon = Icons.trending_up;
        final sitesNoLote = emp!.sitesNoLoteAtual;
        final loteTamanho = emp!.sitesPorLoteAtual;
        final faltam = emp!.sitesAteLoteAtual;
        titulo = 'EM ANDAMENTO — $sitesNoLote/$loteTamanho SITES NO LOTE';
        subtitulo = faltam > 0
            ? 'Faltam $faltam sites • Toque para novo adiantamento'
            : 'Toque para novo adiantamento ou pagamento';
      }
    } else {
      gradient = AppTheme.primaryGradient;
      statusIcon = Icons.work;
      titulo = 'EM ANDAMENTO';
      subtitulo = '${emp!.sitesConcluidos}/${emp!.totalSites} sites concluídos';
    }

    return InkWell(
      onTap: _dialogPagamento,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(statusIcon, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitulo != null)
                    Text(
                      subtitulo,
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.touch_app, color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }

  void _dialogPagamento() {
    if (emp!.foiPago) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Status de Pagamento'),
          content: const Text('Deseja desmarcar como pago?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Não'),
            ),
            ElevatedButton(
              onPressed: () {
                ctrl.desmarcarEmpresaPaga();
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
              child: const Text('Desmarcar'),
            ),
          ],
        ),
      );
    } else if (emp!.adiantamentos.isEmpty && emp!.tipoAdiantamento != TipoAdiantamento.semAdiantamento) {
      _mostrarDialogAdiantamento(
        numero: 1,
        descricao: 'Ao iniciar o projeto, você recebe ${(emp!.percentualAdiantamento * 100).toStringAsFixed(0)}% do valor do lote (${emp!.sitesPorLote} sites) como adiantamento.',
        isPrimeiro: true,
      );
    } else if (emp!.precisaSolicitarAdiantamento) {
      final numAdiant = emp!.adiantamentos.length + 1;
      final sitesSemCobertura = emp!.sitesElegiveisSemCoberturaAdiantamento;
      _mostrarDialogAdiantamento(
        numero: numAdiant,
        descricao: sitesSemCobertura == emp!.sitesPorLote
            ? 'Lote de ${emp!.sitesPorLote} sites concluído! Registre o $numAdiant° adiantamento de ${(emp!.percentualAdiantamento * 100).toStringAsFixed(0)}% do lote.'
            : 'Existem $sitesSemCobertura ${sitesSemCobertura == 1 ? 'site novo sem cobertura' : 'sites novos sem cobertura'}. Registre o $numAdiant° adiantamento para cobrir esse novo lote operacional.',
        isPrimeiro: false,
      );
    } else {
      _mostrarDialogPagamentoFinal();
    }
  }

  void _mostrarDialogPagamentoFinal() {
      final valorAReceber = emp!.saldoFinanceiroComLancamentos;
      final valorPreenchido = valorAReceber > 0 ? valorAReceber : emp!.valorGanho;
      final valorCtrl = TextEditingController(
        text: valorPreenchido.toStringAsFixed(2),
      );
      DateTime dataSel = DateTime.now();

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setSt) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.payment, color: AppTheme.successColor),
                SizedBox(width: 8),
                Text('Confirmar Pagamento'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _buildResumoLinhaPagamento('Valor Ganho (${emp!.sitesConcluidos} sites)', emp!.valorGanho),
                      _buildResumoLinhaPagamento('Adiantamentos recebidos', -emp!.totalAdiantamentos),
                      _buildResumoLinhaPagamento('Lançamentos descontáveis', -emp!.totalLancamentosDescontaveis),
                      _buildResumoLinhaPagamento('Lançamentos não descontáveis', emp!.totalLancamentosNaoDescontaveis),
                      const Divider(height: 12),
                      _buildResumoLinhaPagamento('Saldo a receber', valorAReceber, destaque: true),
                    ],
                  ),
                ),
                TextField(
                  controller: valorCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Valor Recebido (R\$)',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dataSel,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setSt(() => dataSel = picked);
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
                        Text('Data: ${_formatDate(dataSel)}'),
                      ],
                    ),
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
                  final v = double.tryParse(valorCtrl.text.replaceAll(',', '.'));
                  if (v != null && v >= 0) {
                    ctrl.marcarEmpresaPaga(v, dataSel);
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
                child: const Text('Confirmar Pago'),
              ),
            ],
          ),
        ),
      );
  }

  void _mostrarDialogAdiantamento({
    required int numero,
    required String descricao,
    required bool isPrimeiro,
  }) {
    int loteSites = emp!.sitesPorLote;
    final valorSugerido = loteSites * emp!.valorPorSite * emp!.percentualAdiantamento;
    final valorCtrlAdiant = TextEditingController(
      text: valorSugerido.toStringAsFixed(2),
    );
    final loteCtrl = TextEditingController(
      text: loteSites.toString(),
    );
    DateTime dataSel = DateTime.now();
    bool valorEditadoManualmente = false;
    bool atualizandoValorProgramaticamente = false;

    void recalcularValor(StateSetter setSt) {
      final loteTexto = loteCtrl.text.trim();
      final parsedLote = int.tryParse(loteTexto);
      final novoLote = (parsedLote != null && parsedLote > 0) ? parsedLote : 0;
      final novoValor = novoLote * emp!.valorPorSite * emp!.percentualAdiantamento;
      final deveAtualizarValor =
          !valorEditadoManualmente || valorCtrlAdiant.text.trim().isEmpty;
      if (deveAtualizarValor) {
        atualizandoValorProgramaticamente = true;
        valorCtrlAdiant.text = novoValor.toStringAsFixed(2);
        atualizandoValorProgramaticamente = false;
      }
      setSt(() => loteSites = novoLote);
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSt) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.rocket_launch, color: AppTheme.warningColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$numero° Adiantamento (${(emp!.percentualAdiantamento * 100).toStringAsFixed(0)}%)',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  descricao,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: loteCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Qtd de sites do lote',
                  prefixIcon: const Icon(Icons.cell_tower, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  helperText: 'Valor por site: ${_formatCurrency(emp!.valorPorSite)}',
                ),
                onChanged: (_) => recalcularValor(setSt),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: valorCtrlAdiant,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Valor do Adiantamento (R\$)',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  helperText: '${(emp!.percentualAdiantamento * 100).toStringAsFixed(0)}% de ${_formatCurrency(loteSites * emp!.valorPorSite)}',
                ),
                onChanged: (_) {
                  if (!atualizandoValorProgramaticamente) {
                    valorEditadoManualmente = true;
                  }
                },
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dataSel,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setSt(() => dataSel = picked);
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
                      Text('Data: ${_formatDate(dataSel)}'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final v = double.tryParse(valorCtrlAdiant.text.replaceAll(',', '.'));
                final lote = int.tryParse(loteCtrl.text);
                if (v != null && v > 0 && lote != null && lote > 0) {
                  if (isPrimeiro) {
                    ctrl.registrarPrimeiroAdiantamento(v, dataSel, sitesPorLote: lote);
                  } else {
                    ctrl.adicionarAdiantamento(v, dataSel,
                        observacao: '$numero° Adiantamento (${(emp!.percentualAdiantamento * 100).toStringAsFixed(0)}%) - $lote sites',
                        sitesPorLote: lote);
                  }
                  Navigator.pop(ctx);
                  _tabController.animateTo(2);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ $numero° Adiantamento de ${_formatCurrency(v)} ($lote sites) registrado!'),
                      backgroundColor: AppTheme.successColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.rocket_launch),
              label: const Text('Registrar Adiantamento'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertaAdiantamento() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.warningGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.warningColor.withAlpha(80),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.notification_important, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ SOLICITAR NOVO ADIANTAMENTO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${emp!.nome}: ${emp!.sitesConcluidos} sites concluídos!',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _tabController.animateTo(2),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.warningColor,
            ),
            child: const Text('Solicitar'),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildCardResumo('Total Sites', '${emp!.totalSites}', Icons.cell_tower, AppTheme.primaryGradient, onTap: () => _mostrarSitesFiltrados('Total Sites', emp!.sites)),
        _buildCardResumo('Concluídos', '${emp!.sitesConcluidos}', Icons.check_circle, AppTheme.successGradient, onTap: () => _mostrarSitesFiltrados('Concluídos', emp!.sites.where((s) => s.isConcluido).toList())),
        _buildCardResumo('Não Concluídos', '${emp!.sitesNaoConcluidos}', Icons.cancel, AppTheme.dangerGradient, onTap: () => _mostrarSitesFiltrados('Não Concluídos', emp!.sites.where((s) => s.isNaoConcluido).toList())),
        _buildCardResumo('Aguardando', '${emp!.sitesPendentes}', Icons.schedule, AppTheme.warningGradient, onTap: () => _mostrarSitesFiltrados('Aguardando', emp!.sites.where((s) => s.isPendente).toList())),
      ],
    );
  }

  Widget _buildCardResumo(String titulo, String valor, IconData icon, LinearGradient gradient, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: gradient.colors.first.withAlpha(60), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(titulo, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500))),
                  Icon(icon, color: Colors.white54, size: 24),
                ],
              ),
              Text(valor, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarSitesFiltrados(String titulo, List<SiteModel> sites) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${sites.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: sites.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[300]),
                                const SizedBox(height: 8),
                                Text('Nenhum site', style: TextStyle(color: Colors.grey[500])),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: sites.length,
                            separatorBuilder: (_, indexSeparator) => const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final site = sites[index];
                              IconData statusIcon;
                              Color statusColor;
                              String statusLabel;

                              if (site.isConcluido) {
                                statusIcon = Icons.check_circle;
                                statusColor = AppTheme.successColor;
                                statusLabel = 'Concluído';
                              } else if (site.isNaoConcluido) {
                                statusIcon = Icons.cancel;
                                statusColor = AppTheme.errorColor;
                                statusLabel = 'Não Concluído';
                              } else {
                                statusIcon = Icons.schedule;
                                statusColor = AppTheme.warningColor;
                                statusLabel = 'Aguardando';
                              }

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: statusColor.withAlpha(15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: statusColor.withAlpha(40)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(statusIcon, color: statusColor, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        site.siteId,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                    ),
                                    Text(
                                      statusLabel,
                                      style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              );
                            },
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

  Widget _buildGraficoProgresso() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progresso - ${emp!.nome}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(value: emp!.sitesConcluidos.toDouble(), color: AppTheme.successColor, title: '${emp!.sitesConcluidos}', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), radius: 50),
                        PieChartSectionData(value: emp!.sitesNaoConcluidos.toDouble(), color: AppTheme.errorColor, title: '${emp!.sitesNaoConcluidos}', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), radius: 50),
                        PieChartSectionData(value: emp!.sitesPendentes.toDouble(), color: AppTheme.warningColor, title: '${emp!.sitesPendentes}', titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), radius: 50),
                      ],
                    )),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem('Concluídos', AppTheme.successColor),
                        const SizedBox(height: 8),
                        _buildLegendItem('Não Concl.', AppTheme.errorColor),
                        const SizedBox(height: 8),
                        _buildLegendItem('Aguardando', AppTheme.warningColor),
                      ],
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: const TextStyle(fontSize: 12))),
      ],
    );
  }

  Widget _buildValoresFinanceiros() {
    final totalAdiantamentos = emp!.totalAdiantamentos;
    final receberComAdiantSobreConcluidos = emp!.valorReceberComAdiantamento;
    final projecaoFinalComAdiant =
        (emp!.estimativaTotal - totalAdiantamentos) > 0
            ? (emp!.estimativaTotal - totalAdiantamentos)
            : 0.0;
    final saldoLiquidoAtual = emp!.valorReceberPendenteComAdiantamento;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.monetization_on, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text('Financeiro - ${emp!.nome}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            ]),
            const Divider(height: 24),
            _buildLinhaValorDestaque(
              'Valor total de todos os sites',
              emp!.estimativaTotal,
              AppTheme.accentGradient,
            ),
            const SizedBox(height: 8),
            _buildLinhaValorDestaque(
              'Valor sem desconto de adiantamento',
              emp!.valorReceberSemAdiantamento,
              AppTheme.successGradient,
            ),
            const SizedBox(height: 14),
            _buildLinhaValor('Valor Ganho (Concluídos)', emp!.valorGanho, Icons.check_circle_outline, AppTheme.successColor),
            _buildLinhaValor('Valor Perdido (Não Concl.)', emp!.valorPerdido, Icons.cancel_outlined, AppTheme.errorColor),
            _buildLinhaValor('Valor Aguardando', emp!.valorPendente, Icons.schedule, AppTheme.warningColor),
            const Divider(height: 24),
            _buildLinhaValor('Total de adiantamentos (solicitados)', totalAdiantamentos, Icons.payments, Colors.blue),
            _buildLinhaValorDestaque('A receber sobre concluídos (com adiant.)', receberComAdiantSobreConcluidos, AppTheme.successGradient),
            const SizedBox(height: 8),
            _buildLinhaValorDestaque('Projeção final\n(todos os sites - adiant.)', projecaoFinalComAdiant, AppTheme.accentGradient),
            const SizedBox(height: 8),
            _buildLinhaValorDestaque('Saldo líquido atual\n(desconta CPS recebidos)', saldoLiquidoAtual, AppTheme.primaryGradient),
          ],
        ),
      ),
    );
  }

  Widget _buildLinhaValor(String label, double valor, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(_formatCurrency(valor), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Widget _buildLinhaValorDestaque(String label, double valor, LinearGradient gradient) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13))),
          Text(_formatCurrency(valor), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildReferenciaLote() {
    final lotesHistoricos = emp!.adiantamentos
        .map((a) => a.sitesPorLote)
        .where((lote) => lote > 0)
        .toSet()
        .toList()
      ..sort();
    final lotesTexto = lotesHistoricos.isEmpty
        ? 'Nenhum CPS registrado ainda'
        : lotesHistoricos.map((lote) => '$lote').join(', ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.calculate, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text('Referência atual: Lote de ${emp!.sitesPorLote} sites',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            ]),
            const SizedBox(height: 6),
            Text(
              'Lotes já registrados nos CPS: $lotesTexto',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const Divider(height: 24),
            _buildInfoTile('Valor Total (${emp!.sitesPorLote} × ${_formatCurrency(emp!.valorPorSite)})',
                _formatCurrency(emp!.valorTotalLote), Icons.attach_money),
            _buildInfoTile('Adiantamento ${(emp!.percentualAdiantamento * 100).toStringAsFixed(0)}%',
                _formatCurrency(emp!.valorAdiantamentoLote), Icons.money_off),
            _buildInfoTile('Valor a Receber (após adiant.)',
                _formatCurrency(emp!.valorReceberLote), Icons.account_balance_wallet, destaque: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String valor, IconData icon, {bool destaque = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: destaque ? AppTheme.successColor.withAlpha(25) : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: destaque ? Border.all(color: AppTheme.successColor.withAlpha(80)) : null,
      ),
      child: Row(children: [
        Icon(icon, color: destaque ? AppTheme.successColor : Colors.grey[600], size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        Text(valor, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: destaque ? AppTheme.successColor : AppTheme.primaryColor)),
      ]),
    );
  }

  Widget _buildProgressoLote() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.trending_up, color: AppTheme.primaryColor, size: 24),
              SizedBox(width: 8),
              Text('Progresso', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            ]),
            const SizedBox(height: 16),
            _buildBarraProgresso('Progresso Geral', emp!.progressoGeral, AppTheme.primaryColor),
            const SizedBox(height: 16),
            if (emp!.tipoAdiantamento == TipoAdiantamento.percentualPorLote) ...[
              if (emp!.sitesElegiveisSemCoberturaAdiantamento == 0) ...[
                _buildBarraProgresso('Lote p/ Próximo Adiantamento', 1.0, AppTheme.successColor),
                const SizedBox(height: 6),
                const Text(
                  'Todos os lotes atuais estao cobertos por CPS registrados.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else ...[
                _buildBarraProgresso('Lote p/ Próximo Adiantamento', emp!.progressoLote, AppTheme.secondaryColor),
                const SizedBox(height: 6),
                Text(
                  emp!.sitesAteLoteAtual > 0
                      ? 'Faltam ${emp!.sitesAteLoteAtual} sites para o próximo adiantamento'
                      : '🎉 Lote completo! Solicite o adiantamento.',
                  style: TextStyle(
                    fontSize: 12,
                    color: emp!.sitesAteLoteAtual > 0 ? Colors.grey[600] : AppTheme.successColor,
                    fontWeight: emp!.sitesAteLoteAtual > 0 ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBarraProgresso(String label, double valor, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text('${(valor * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: valor,
            minHeight: 12,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildResumoGlobal() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.summarize, color: AppTheme.primaryColor, size: 24),
              SizedBox(width: 8),
              Text('Resumo Global (Todas Empresas)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            ]),
            const Divider(height: 24),
            _buildLinhaValor('Total Sites', ctrl.totalSitesGlobal.toDouble(), Icons.cell_tower, AppTheme.primaryColor),
            _buildLinhaValor('Sites Concluídos', ctrl.sitesConcluidosGlobal.toDouble(), Icons.check_circle, AppTheme.successColor),
            _buildLinhaValor('Estimativa Total', ctrl.estimativaTotalGlobal, Icons.trending_up, AppTheme.primaryColor),
            _buildLinhaValor('Valor Ganho Total', ctrl.valorGanhoGlobal, Icons.monetization_on, AppTheme.successColor),
            _buildLinhaValor('Adiantamentos Total', ctrl.totalAdiantamentosGlobal, Icons.payments, Colors.blue),
            _buildLinhaValor('Lançamentos descontáveis', ctrl.totalLancamentosDescontaveisGlobal, Icons.remove_circle_outline, AppTheme.errorColor),
            _buildLinhaValor('Lançamentos não descontáveis', ctrl.totalLancamentosNaoDescontaveisGlobal, Icons.add_circle_outline, AppTheme.successColor),
            _buildLinhaValor('Lançamentos previstos', ctrl.totalLancamentosPrevistosGlobal, Icons.schedule, AppTheme.warningColor),
            _buildLinhaValor('Pendente no histórico', ctrl.valorReceberHistoricoGlobalComLancamentos, Icons.history, Colors.deepOrange),
            const Divider(height: 20),
            _buildLinhaValorDestaque('A Receber Total', ctrl.valorReceberGlobal, AppTheme.successGradient),
            const SizedBox(height: 8),
            _buildLinhaValorDestaque('Saldo total com lançamentos (ativas)', ctrl.valorReceberGlobalComLancamentos, AppTheme.primaryGradient),
            const SizedBox(height: 8),
            _buildLinhaValorDestaque('Saldo total incluindo histórico', ctrl.valorReceberTotalComHistorico, AppTheme.accentGradient),
            const SizedBox(height: 12),
            ...ctrl.empresas.map((e) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(e.foiPago ? Icons.check_circle : Icons.pending, size: 18,
                    color: e.foiPago ? AppTheme.successColor : AppTheme.warningColor),
                const SizedBox(width: 8),
                Expanded(child: Text(e.nome, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
                Text(_formatCurrency(e.saldoFinanceiroComLancamentos),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor)),
              ]),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoLinhaPagamento(String label, double valor, {bool destaque = false}) {
    final isNegativo = valor < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: 12,
            fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
            color: destaque ? AppTheme.primaryColor : Colors.grey[700],
          )),
          Text(
            '${isNegativo ? "- " : ""}${_formatCurrency(valor.abs())}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: destaque
                  ? (valor >= 0 ? AppTheme.successColor : AppTheme.errorColor)
                  : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoColarSites() {
    return InkWell(
      onTap: _dialogColarSites,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withAlpha(15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primaryColor.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.content_paste, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Colar Sites',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Text(
                    'Adicionar múltiplos Site IDs de uma vez',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppTheme.primaryColor, size: 16),
          ],
        ),
      ),
    );
  }

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

              final ids = text
                  .split(RegExp(r'[\n,;\s]+'))
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();

              final adicionados = ctrl.adicionarSitesEmMassa(ids);

              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '$adicionados novos sites adicionados (${ids.length - adicionados} já existiam)'),
                  backgroundColor: AppTheme.successColor,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  String _formatCurrency(double value) {
    return CurrencyUtils.formatBRL(value);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
