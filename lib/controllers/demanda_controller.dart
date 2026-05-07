import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/drive_backup_service.dart';
import '../models/site_model.dart';
import '../models/adiantamento_model.dart';
import '../models/empresa_model.dart';
import '../models/lancamento_financeiro_model.dart';
import '../models/demanda_geral_model.dart';
import '../models/demanda_evento_model.dart';
import '../models/relatorio_model.dart';
import '../utils/currency_utils.dart';

class DemandaController extends ChangeNotifier {
  final DriveBackupService _driveBackupService = DriveBackupService();
  List<EmpresaModel> _empresas = [];
  int _empresaSelecionadaIndex = 0;
  List<RelatorioDiario> _relatorios = [];
  List<DemandaGeralModel> _demandasArquivadas = [];
  List<DemandaEventoModel> _eventosDemanda = [];
  RelatorioConfig _relatorioConfig = RelatorioConfig();
  String? _mensagemSistemaPendente;
  String? _nomeDemandaSugerido;
  String? _responsavelFechamentoSugerido;
  String? _demandaReabertaId;
  Map<String, String> _ordenacaoLancamentosPorEmpresa = {};
    Map<String, String> _filtroLancamentosPorEmpresa = {};
  Map<String, String> _filtroPlanosPorEmpresa = {};
  Map<String, String> _presetVisualizacaoFinanceiraPorEmpresa = {};
  Map<String, bool> _mostrarAtalhosPresetsPorEmpresa = {};
  Timer? _autoBackupDebounce;
  bool _autoBackupEmAndamento = false;

  @override
  void dispose() {
    _autoBackupDebounce?.cancel();
    super.dispose();
  }

  static const String _ordenacaoLancamentosKey =
      'ordenacao_lancamentos_por_empresa_v1';
    static const String _filtroLancamentosKey =
      'filtro_lancamentos_por_empresa_v1';
      static const String _filtroPlanosKey =
        'filtro_planos_por_empresa_v1';
        static const String _presetVisualizacaoFinanceiraKey =
          'preset_visualizacao_financeira_por_empresa_v1';
  static const String _mostrarAtalhosPresetsKey =
      'mostrar_atalhos_presets_por_empresa_v1';

  static const List<String> siteIdsPrEncell = [
    'BASDR_0002', 'BASDR_0310', 'BASDR_0050', 'BASDR_0162', 'BASDR_0190',
    'BASDR_0164', 'BASDR_0916', 'BASDR_0227', 'BASDR_0126', 'BASDR_0417',
    'BASDR_0028', 'BASDR_0374', 'BASDR_0059', 'BASDR_0097', 'BASDR_0134',
    'BASDR_0420', 'BASDR_0447', 'BASDR_0732', 'BASDR_0115', 'BASDR_0790',
    'BASDR_0806', 'BASDR_0003', 'BASDR_0005', 'BASDR_0053', 'BASDR_0119',
    'BASDR_0129', 'BASDR_0130', 'BASDR_0136', 'BASDR_0159', 'BASDR_0192',
    'BASDR_0244', 'BASDR_0657', 'BASDR_0716', 'BASDR_0983', 'BASDR_0004',
    'BASDR_0109', 'BASDR_0113', 'BASDR_0765', 'BASDR_0797', 'BASDR_0740',
  ];

  List<EmpresaModel> get empresas => _empresas;
  int get empresaSelecionadaIndex => _empresaSelecionadaIndex;
  List<RelatorioDiario> get relatorios => _relatorios;
  List<DemandaGeralModel> get demandasArquivadas => _demandasArquivadas;
  List<DemandaEventoModel> get eventosDemanda => _eventosDemanda;
  RelatorioConfig get relatorioConfig => _relatorioConfig;
  bool get temDemandaAtiva => _empresas.isNotEmpty || _relatorios.isNotEmpty;
  String? get nomeDemandaSugerido => _nomeDemandaSugerido;
  String? get responsavelFechamentoSugerido => _responsavelFechamentoSugerido;

  String? consumirMensagemSistemaPendente() {
    final msg = _mensagemSistemaPendente;
    _mensagemSistemaPendente = null;
    return msg;
  }

  EmpresaModel? get empresaAtual =>
      _empresas.isNotEmpty ? _empresas[_empresaSelecionadaIndex] : null;

  String get ordenacaoLancamentosEmpresaAtual {
    final emp = empresaAtual;
    if (emp == null) return 'data_desc';
    final valor = _ordenacaoLancamentosPorEmpresa[emp.id];
    return _ordenacaoValida(valor) ? valor! : 'data_desc';
  }

  String get filtroLancamentosEmpresaAtual {
    final emp = empresaAtual;
    if (emp == null) return 'todos';
    final valor = _filtroLancamentosPorEmpresa[emp.id];
    return _filtroValido(valor) ? valor! : 'todos';
  }

  String get filtroPlanosParcelamentoEmpresaAtual {
    final emp = empresaAtual;
    if (emp == null) return 'todos';
    final valor = _filtroPlanosPorEmpresa[emp.id];
    return _filtroPlanoValido(valor) ? valor! : 'todos';
  }

  String get presetVisualizacaoFinanceiraEmpresaAtual {
    final emp = empresaAtual;
    if (emp == null) return 'padrao';
    final valor = _presetVisualizacaoFinanceiraPorEmpresa[emp.id];
    return _presetVisualizacaoValido(valor) ? valor! : 'padrao';
  }

  bool get mostrarAtalhosPresetsEmpresaAtual {
    final emp = empresaAtual;
    if (emp == null) return true;
    return _mostrarAtalhosPresetsPorEmpresa[emp.id] ?? true;
  }

  // Totais globais (todas as empresas)
  int get totalSitesGlobal =>
      _empresas.fold(0, (sum, e) => sum + e.totalSites);
  int get sitesConcluidosGlobal =>
      _empresas.fold(0, (sum, e) => sum + e.sitesConcluidos);
  double get valorGanhoGlobal =>
      _empresas.fold(0.0, (sum, e) => sum + e.valorGanho);
  double get estimativaTotalGlobal =>
      _empresas.fold(0.0, (sum, e) => sum + e.estimativaTotal);
  double get totalAdiantamentosGlobal =>
      _empresas.fold(0.0, (sum, e) => sum + e.totalAdiantamentos);
    double get totalLancamentosDescontaveisGlobal =>
      _empresas.fold(0.0, (sum, e) => sum + e.totalLancamentosDescontaveis);
    double get totalLancamentosNaoDescontaveisGlobal =>
      _empresas.fold(0.0, (sum, e) => sum + e.totalLancamentosNaoDescontaveis);
      double get totalLancamentosPrevistosGlobal =>
        _empresas.fold(0.0, (sum, e) => sum + e.totalLancamentosPrevistos);
  double get valorReceberGlobal =>
      _empresas.fold(0.0, (sum, e) => sum + e.valorReceberPendenteComAdiantamento);
    double get valorReceberGlobalComLancamentos =>
      _empresas.fold(0.0, (sum, e) => sum + e.saldoFinanceiroPendenteComLancamentos);
  double get valorReceberHistoricoGlobalComLancamentos =>
      _demandasArquivadas
          .where((d) => d.id != _demandaReabertaId)
          .fold(0.0, (sumDemandas, demanda) {
        final pendenteDemanda = demanda.empresas
            .fold(0.0, (sumEmpresas, empresa) {
          final pendente = empresa.saldoFinanceiroPendenteComLancamentos;
          return sumEmpresas + (pendente > 0 ? pendente : 0.0);
        });
        return sumDemandas + pendenteDemanda;
      });
  double get valorReceberTotalComHistorico =>
      valorReceberGlobalComLancamentos + valorReceberHistoricoGlobalComLancamentos;

  String _normalizarNomeEmpresa(String nome) {
    var normalizado = nome.trim().toLowerCase();
    normalizado = normalizado.replaceAll(RegExp(r'\s*\(novo ciclo.*\)'), '');
    normalizado = normalizado.replaceAll(RegExp(r'\s+'), ' ');
    return normalizado.trim();
  }

  double valorReceberEmpresaComHistoricoPorNome(String nomeEmpresa) {
    final nomeNormalizado = _normalizarNomeEmpresa(nomeEmpresa);

    final totalAtivo = _empresas
        .where((e) => _normalizarNomeEmpresa(e.nome) == nomeNormalizado)
        .fold(0.0, (sum, e) => sum + e.saldoFinanceiroPendenteComLancamentos);

    final totalHistorico = _demandasArquivadas
        .where((d) => d.id != _demandaReabertaId)
        .fold(0.0, (sumDemandas, demanda) {
      final subtotal = demanda.empresas
          .where((e) => _normalizarNomeEmpresa(e.nome) == nomeNormalizado)
          .fold(0.0, (sumEmpresas, e) => sumEmpresas + e.saldoFinanceiroPendenteComLancamentos);
      return sumDemandas + subtotal;
    });

    return totalAtivo + totalHistorico;
  }

  String _assinaturaDemanda({
    required List<EmpresaModel> empresas,
    required List<RelatorioDiario> relatorios,
  }) {
    return jsonEncode({
      'empresas': empresas.map((e) => e.toJson()).toList(),
      'relatorios': relatorios.map((r) => r.toJson()).toList(),
    });
  }

  void _reconciliarSugestoesDemandaReaberta() {
    if (_empresas.isEmpty && _relatorios.isEmpty) {
      _nomeDemandaSugerido = null;
      _responsavelFechamentoSugerido = null;
      _demandaReabertaId = null;
      return;
    }

    final nomeAtual = (_nomeDemandaSugerido ?? '').trim();
    final responsavelAtual = (_responsavelFechamentoSugerido ?? '').trim();

    if (_demandaReabertaId != null) {
      final demandaPorId = _demandasArquivadas.where((d) => d.id == _demandaReabertaId);
      if (demandaPorId.isNotEmpty) {
        final d = demandaPorId.first;
        if (nomeAtual.isEmpty) {
          _nomeDemandaSugerido = d.nome;
        }
        if (responsavelAtual.isEmpty && d.responsavelFechamento.trim().isNotEmpty) {
          _responsavelFechamentoSugerido = d.responsavelFechamento.trim();
        }
        return;
      }
    }

    if (nomeAtual.isNotEmpty && responsavelAtual.isNotEmpty) {
      return;
    }

    final assinaturaAtiva = _assinaturaDemanda(
      empresas: _empresas,
      relatorios: _relatorios,
    );

    for (final demanda in _demandasArquivadas) {
      final assinaturaHistorico = _assinaturaDemanda(
        empresas: demanda.empresas,
        relatorios: demanda.relatorios,
      );
      if (assinaturaAtiva == assinaturaHistorico) {
        _demandaReabertaId = demanda.id;
        if (nomeAtual.isEmpty) {
          _nomeDemandaSugerido = demanda.nome;
        }
        if (responsavelAtual.isEmpty && demanda.responsavelFechamento.trim().isNotEmpty) {
          _responsavelFechamentoSugerido = demanda.responsavelFechamento.trim();
        }
        return;
      }
    }
  }

  void selecionarEmpresa(int index) {
    if (index >= 0 && index < _empresas.length) {
      _empresaSelecionadaIndex = index;
      notifyListeners();
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final empresasJson = prefs.getString('empresas_v2');
    _nomeDemandaSugerido = prefs.getString('nome_demanda_sugerido');
    _responsavelFechamentoSugerido = prefs.getString('responsavel_fechamento_sugerido');
    _demandaReabertaId = prefs.getString('demanda_reaberta_id');

    if (empresasJson != null) {
      _empresas = EmpresaModel.decodeList(empresasJson);
    } else {
      // Migrar dados antigos. Se não houver legado, iniciar vazio.
      final sitesJson = prefs.getString('sites');
      final adiantamentosJson = prefs.getString('adiantamentos');

      if (sitesJson != null || adiantamentosJson != null) {
        final sites = sitesJson != null
            ? SiteModel.decodeList(sitesJson)
            : <SiteModel>[];
        final adiantamentos = adiantamentosJson != null
            ? AdiantamentoModel.decodeList(adiantamentosJson)
            : <AdiantamentoModel>[];

        _empresas = [
          EmpresaModel(
            id: 'empresa_migrada_001',
            nome: 'Empresa Migrada',
            valorPorSite: 600.0,
            sites: sites,
            adiantamentos: adiantamentos,
            tipoAdiantamento: TipoAdiantamento.percentualPorLote,
            percentualAdiantamento: 0.40,
            sitesPorLote: 20,
          ),
        ];
      } else {
        _empresas = [];
      }
    }

    if (_empresaSelecionadaIndex >= _empresas.length) {
      _empresaSelecionadaIndex = 0;
    }

    // Carregar relatórios diários
    final relatoriosJson = prefs.getString('relatorios_v1');
    if (relatoriosJson != null) {
      _relatorios = RelatorioDiario.decodeList(relatoriosJson);
    }

    // Carregar histórico de demandas gerais concluídas
    final demandasJson = prefs.getString('demandas_arquivadas_v1');
    if (demandasJson != null) {
      _demandasArquivadas = DemandaGeralModel.decodeList(demandasJson);
    }

    // Carregar eventos de auditoria
    final eventosJson = prefs.getString('demanda_eventos_v1');
    if (eventosJson != null) {
      _eventosDemanda = DemandaEventoModel.decodeList(eventosJson);
    }

    // Carregar config de relatórios
    final configJson = prefs.getString('relatorio_config');
    if (configJson != null) {
      _relatorioConfig = RelatorioConfig.decode(configJson);
    }

    // Carregar preferências de ordenação dos lançamentos por empresa
    final ordenacaoJson = prefs.getString(_ordenacaoLancamentosKey);
    if (ordenacaoJson != null && ordenacaoJson.trim().isNotEmpty) {
      try {
        final raw = jsonDecode(ordenacaoJson);
        if (raw is Map<String, dynamic>) {
          _ordenacaoLancamentosPorEmpresa = raw.map((key, value) {
            final v = value?.toString();
            return MapEntry(
              key,
              _ordenacaoValida(v) ? v! : 'data_desc',
            );
          });
        }
      } catch (_) {
        _ordenacaoLancamentosPorEmpresa = {};
      }
    }

    // Carregar preferências de filtro dos lançamentos por empresa
    final filtroJson = prefs.getString(_filtroLancamentosKey);
    if (filtroJson != null && filtroJson.trim().isNotEmpty) {
      try {
        final raw = jsonDecode(filtroJson);
        if (raw is Map<String, dynamic>) {
          _filtroLancamentosPorEmpresa = raw.map((key, value) {
            final v = value?.toString();
            return MapEntry(
              key,
              _filtroValido(v) ? v! : 'todos',
            );
          });
        }
      } catch (_) {
        _filtroLancamentosPorEmpresa = {};
      }
    }

    // Carregar preferências de filtro dos planos parcelados por empresa
    final filtroPlanosJson = prefs.getString(_filtroPlanosKey);
    if (filtroPlanosJson != null && filtroPlanosJson.trim().isNotEmpty) {
      try {
        final raw = jsonDecode(filtroPlanosJson);
        if (raw is Map<String, dynamic>) {
          _filtroPlanosPorEmpresa = raw.map((key, value) {
            final v = value?.toString();
            return MapEntry(
              key,
              _filtroPlanoValido(v) ? v! : 'todos',
            );
          });
        }
      } catch (_) {
        _filtroPlanosPorEmpresa = {};
      }
    }

    // Carregar preset de visualização financeira por empresa
    final presetJson = prefs.getString(_presetVisualizacaoFinanceiraKey);
    if (presetJson != null && presetJson.trim().isNotEmpty) {
      try {
        final raw = jsonDecode(presetJson);
        if (raw is Map<String, dynamic>) {
          _presetVisualizacaoFinanceiraPorEmpresa = raw.map((key, value) {
            final v = value?.toString();
            return MapEntry(
              key,
              _presetVisualizacaoValido(v) ? v! : 'padrao',
            );
          });
        }
      } catch (_) {
        _presetVisualizacaoFinanceiraPorEmpresa = {};
      }
    }

    // Carregar visibilidade dos atalhos de presets por empresa
    final atalhosJson = prefs.getString(_mostrarAtalhosPresetsKey);
    if (atalhosJson != null && atalhosJson.trim().isNotEmpty) {
      try {
        final raw = jsonDecode(atalhosJson);
        if (raw is Map<String, dynamic>) {
          _mostrarAtalhosPresetsPorEmpresa = raw.map((key, value) {
            final boolValor = value is bool
                ? value
                : value?.toString().toLowerCase() == 'true';
            return MapEntry(key, boolValor);
          });
        }
      } catch (_) {
        _mostrarAtalhosPresetsPorEmpresa = {};
      }
    }

    _reconciliarSugestoesDemandaReaberta();

    // Reconciliar lotes antigos usando datas reais dos sites concluidos elegiveis.
    var houveReconciliacao = false;
    for (final emp in _empresas) {
      final mudou = _recalcularFechamentoAdiantamentosPorDatas(emp);
      if (mudou) houveReconciliacao = true;

      final corrigiuPagoLegado = _corrigirPagamentosCpsAutomaticosLegado(emp);
      if (corrigiuPagoLegado) houveReconciliacao = true;
    }
    if (houveReconciliacao) {
      await _salvar();
    }

    notifyListeners();
  }

  bool _mesmaDataCalendario(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _corrigirPagamentosCpsAutomaticosLegado(EmpresaModel emp) {
    var alterou = false;
    for (final ad in emp.adiantamentos) {
      if (!ad.foiPago) continue;

      final observacaoLegado = ad.observacao.trim().startsWith('1° Adiantamento');
      final dataPagamentoIgualCadastro = ad.dataPagamento != null &&
          _mesmaDataCalendario(ad.dataPagamento!, ad.data);
      final valorPagoIgualAoAdiantamento = (ad.valorPago - ad.valor).abs() < 0.01;

      if (observacaoLegado && dataPagamentoIgualCadastro && valorPagoIgualAoAdiantamento) {
        ad.foiPago = false;
        alterou = true;
      }
    }
    return alterou;
  }

  Future<void> _salvar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('empresas_v2', EmpresaModel.encodeList(_empresas));
    if (_nomeDemandaSugerido != null) {
      await prefs.setString('nome_demanda_sugerido', _nomeDemandaSugerido!);
    } else {
      await prefs.remove('nome_demanda_sugerido');
    }
    if (_responsavelFechamentoSugerido != null) {
      await prefs.setString(
        'responsavel_fechamento_sugerido',
        _responsavelFechamentoSugerido!,
      );
    } else {
      await prefs.remove('responsavel_fechamento_sugerido');
    }
    if (_demandaReabertaId != null) {
      await prefs.setString('demanda_reaberta_id', _demandaReabertaId!);
    } else {
      await prefs.remove('demanda_reaberta_id');
    }
    _agendarAutoBackupNuvem();
  }

  void _agendarAutoBackupNuvem() {
    _autoBackupDebounce?.cancel();
    _autoBackupDebounce = Timer(const Duration(seconds: 2), () async {
      if (_autoBackupEmAndamento) return;

      _autoBackupEmAndamento = true;
      try {
        final backupJson = gerarBackupJson();
        await _driveBackupService.salvarBackupNoDrive(
          backupJson,
          interativo: false,
        );
      } catch (_) {
        // Falhas de rede/autenticação não devem bloquear o fluxo local.
      } finally {
        _autoBackupEmAndamento = false;
      }
    });
  }

  // === EMPRESAS ===

  void adicionarEmpresa(EmpresaModel empresa) {
    _empresas.add(empresa);
    _salvar();
    notifyListeners();
  }

  void atualizarEmpresa(int index, EmpresaModel empresa) {
    final idAnterior = _empresas[index].id;
    final preferenciaAnterior = _ordenacaoLancamentosPorEmpresa[idAnterior];
    final filtroAnterior = _filtroLancamentosPorEmpresa[idAnterior];
    final filtroPlanoAnterior = _filtroPlanosPorEmpresa[idAnterior];
    final presetAnterior = _presetVisualizacaoFinanceiraPorEmpresa[idAnterior];
    final atalhosAnteriores = _mostrarAtalhosPresetsPorEmpresa[idAnterior];
    _empresas[index] = empresa;

    if (idAnterior != empresa.id) {
      _ordenacaoLancamentosPorEmpresa.remove(idAnterior);
      _filtroLancamentosPorEmpresa.remove(idAnterior);
      _filtroPlanosPorEmpresa.remove(idAnterior);
      _presetVisualizacaoFinanceiraPorEmpresa.remove(idAnterior);
      _mostrarAtalhosPresetsPorEmpresa.remove(idAnterior);
      if (preferenciaAnterior != null &&
          !_ordenacaoLancamentosPorEmpresa.containsKey(empresa.id)) {
        _ordenacaoLancamentosPorEmpresa[empresa.id] = preferenciaAnterior;
      }
      if (filtroAnterior != null &&
          !_filtroLancamentosPorEmpresa.containsKey(empresa.id)) {
        _filtroLancamentosPorEmpresa[empresa.id] = filtroAnterior;
      }
      if (filtroPlanoAnterior != null &&
          !_filtroPlanosPorEmpresa.containsKey(empresa.id)) {
        _filtroPlanosPorEmpresa[empresa.id] = filtroPlanoAnterior;
      }
      if (presetAnterior != null &&
          !_presetVisualizacaoFinanceiraPorEmpresa.containsKey(empresa.id)) {
        _presetVisualizacaoFinanceiraPorEmpresa[empresa.id] = presetAnterior;
      }
      if (atalhosAnteriores != null &&
          !_mostrarAtalhosPresetsPorEmpresa.containsKey(empresa.id)) {
        _mostrarAtalhosPresetsPorEmpresa[empresa.id] = atalhosAnteriores;
      }
      _salvarPreferenciasOrdenacaoLancamentos();
      _salvarPreferenciasFiltroLancamentos();
      _salvarPreferenciasFiltroPlanos();
      _salvarPresetsVisualizacaoFinanceira();
      _salvarVisibilidadeAtalhosPresets();
    }

    _salvar();
    notifyListeners();
  }

  void removerEmpresa(int index) {
    final idRemovido = _empresas[index].id;
    _empresas.removeAt(index);
    _ordenacaoLancamentosPorEmpresa.remove(idRemovido);
    _filtroLancamentosPorEmpresa.remove(idRemovido);
    _filtroPlanosPorEmpresa.remove(idRemovido);
    _presetVisualizacaoFinanceiraPorEmpresa.remove(idRemovido);
    _mostrarAtalhosPresetsPorEmpresa.remove(idRemovido);
    _salvarPreferenciasOrdenacaoLancamentos();
    _salvarPreferenciasFiltroLancamentos();
    _salvarPreferenciasFiltroPlanos();
    _salvarPresetsVisualizacaoFinanceira();
    _salvarVisibilidadeAtalhosPresets();
    if (_empresaSelecionadaIndex >= _empresas.length) {
      _empresaSelecionadaIndex = _empresas.isEmpty ? 0 : _empresas.length - 1;
    }
    _salvar();
    notifyListeners();
  }

  void atualizarOrdenacaoLancamentosEmpresaAtual(String ordenacao) {
    if (!_ordenacaoValida(ordenacao)) return;
    final emp = empresaAtual;
    if (emp == null) return;
    final atual = _ordenacaoLancamentosPorEmpresa[emp.id] ?? 'data_desc';
    if (atual == ordenacao) return;

    _ordenacaoLancamentosPorEmpresa[emp.id] = ordenacao;
    _presetVisualizacaoFinanceiraPorEmpresa[emp.id] = 'custom';
    _salvarPreferenciasOrdenacaoLancamentos();
    _salvarPresetsVisualizacaoFinanceira();
    notifyListeners();
  }

  void atualizarFiltroLancamentosEmpresaAtual(String filtro) {
    if (!_filtroValido(filtro)) return;
    final emp = empresaAtual;
    if (emp == null) return;
    final atual = _filtroLancamentosPorEmpresa[emp.id] ?? 'todos';
    if (atual == filtro) return;

    _filtroLancamentosPorEmpresa[emp.id] = filtro;
    _presetVisualizacaoFinanceiraPorEmpresa[emp.id] = 'custom';
    _salvarPreferenciasFiltroLancamentos();
    _salvarPresetsVisualizacaoFinanceira();
    notifyListeners();
  }

  void atualizarFiltroPlanosParcelamentoEmpresaAtual(String filtro) {
    if (!_filtroPlanoValido(filtro)) return;
    final emp = empresaAtual;
    if (emp == null) return;
    final atual = _filtroPlanosPorEmpresa[emp.id] ?? 'todos';
    if (atual == filtro) return;

    _filtroPlanosPorEmpresa[emp.id] = filtro;
    _presetVisualizacaoFinanceiraPorEmpresa[emp.id] = 'custom';
    _salvarPreferenciasFiltroPlanos();
    _salvarPresetsVisualizacaoFinanceira();
    notifyListeners();
  }

  void aplicarPresetVisualizacaoFinanceiraEmpresaAtual(String presetId) {
    if (!_presetVisualizacaoValido(presetId)) return;
    final emp = empresaAtual;
    if (emp == null) return;

    String filtroLancamentos = 'todos';
    String ordenacao = 'data_desc';
    String filtroPlanos = 'todos';

    switch (presetId) {
      case 'fechamento_semanal':
        filtroLancamentos = 'recebidos';
        ordenacao = 'valor_desc';
        filtroPlanos = 'abertos';
        break;
      case 'planejamento_previstos':
        filtroLancamentos = 'previstos';
        ordenacao = 'data_asc';
        filtroPlanos = 'abertos';
        break;
      case 'auditoria':
        filtroLancamentos = 'todos';
        ordenacao = 'tipo';
        filtroPlanos = 'todos';
        break;
      case 'padrao':
      default:
        filtroLancamentos = 'todos';
        ordenacao = 'data_desc';
        filtroPlanos = 'todos';
        break;
    }

    _filtroLancamentosPorEmpresa[emp.id] = filtroLancamentos;
    _ordenacaoLancamentosPorEmpresa[emp.id] = ordenacao;
    _filtroPlanosPorEmpresa[emp.id] = filtroPlanos;
    _presetVisualizacaoFinanceiraPorEmpresa[emp.id] = presetId;

    _salvarPreferenciasFiltroLancamentos();
    _salvarPreferenciasOrdenacaoLancamentos();
    _salvarPreferenciasFiltroPlanos();
    _salvarPresetsVisualizacaoFinanceira();
    notifyListeners();
  }

  void atualizarMostrarAtalhosPresetsEmpresaAtual(bool mostrar) {
    final emp = empresaAtual;
    if (emp == null) return;
    final atual = _mostrarAtalhosPresetsPorEmpresa[emp.id] ?? true;
    if (atual == mostrar) return;

    _mostrarAtalhosPresetsPorEmpresa[emp.id] = mostrar;
    _salvarVisibilidadeAtalhosPresets();
    notifyListeners();
  }

  void resetarPreferenciasVisualizacaoFinanceiraEmpresaAtual() {
    final emp = empresaAtual;
    if (emp == null) return;

    final id = emp.id;
    var houveMudanca = false;

    if ((_filtroLancamentosPorEmpresa[id] ?? 'todos') != 'todos') {
      _filtroLancamentosPorEmpresa[id] = 'todos';
      houveMudanca = true;
    }

    if ((_ordenacaoLancamentosPorEmpresa[id] ?? 'data_desc') != 'data_desc') {
      _ordenacaoLancamentosPorEmpresa[id] = 'data_desc';
      houveMudanca = true;
    }

    if ((_filtroPlanosPorEmpresa[id] ?? 'todos') != 'todos') {
      _filtroPlanosPorEmpresa[id] = 'todos';
      houveMudanca = true;
    }

    if ((_presetVisualizacaoFinanceiraPorEmpresa[id] ?? 'padrao') !=
        'padrao') {
      _presetVisualizacaoFinanceiraPorEmpresa[id] = 'padrao';
      houveMudanca = true;
    }

    if (!houveMudanca) return;

    _salvarPreferenciasFiltroLancamentos();
    _salvarPreferenciasOrdenacaoLancamentos();
    _salvarPreferenciasFiltroPlanos();
    _salvarPresetsVisualizacaoFinanceira();
    notifyListeners();
  }

  Future<void> _salvarPreferenciasOrdenacaoLancamentos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _ordenacaoLancamentosKey,
      jsonEncode(_ordenacaoLancamentosPorEmpresa),
    );
  }

  Future<void> _salvarPreferenciasFiltroLancamentos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _filtroLancamentosKey,
      jsonEncode(_filtroLancamentosPorEmpresa),
    );
  }

  Future<void> _salvarPreferenciasFiltroPlanos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _filtroPlanosKey,
      jsonEncode(_filtroPlanosPorEmpresa),
    );
  }

  Future<void> _salvarPresetsVisualizacaoFinanceira() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _presetVisualizacaoFinanceiraKey,
      jsonEncode(_presetVisualizacaoFinanceiraPorEmpresa),
    );
  }

  Future<void> _salvarVisibilidadeAtalhosPresets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _mostrarAtalhosPresetsKey,
      jsonEncode(_mostrarAtalhosPresetsPorEmpresa),
    );
  }

  bool _ordenacaoValida(String? valor) {
    return valor == 'data_desc' ||
        valor == 'data_asc' ||
        valor == 'valor_desc' ||
        valor == 'valor_asc' ||
        valor == 'tipo';
  }

  bool _filtroValido(String? valor) {
    return valor == 'todos' || valor == 'recebidos' || valor == 'previstos';
  }

  bool _filtroPlanoValido(String? valor) {
    return valor == 'todos' || valor == 'abertos' || valor == 'concluidos';
  }

  bool _presetVisualizacaoValido(String? valor) {
    return valor == 'padrao' ||
        valor == 'fechamento_semanal' ||
        valor == 'planejamento_previstos' ||
      valor == 'auditoria' ||
        valor == 'custom';
  }

  // === SITES (empresa atual) ===

  void adicionarSite(String siteId) {
    final emp = empresaAtual;
    if (emp == null) return;
    emp.sites.add(SiteModel(siteId: siteId));
    _salvar();
    notifyListeners();
  }

  /// Adiciona múltiplos sites de uma vez, ignorando IDs já existentes.
  /// Retorna a quantidade de sites efetivamente adicionados.
  int adicionarSitesEmMassa(List<String> siteIds) {
    final emp = empresaAtual;
    if (emp == null) return 0;
    final existentes = emp.sites.map((s) => s.siteId).toSet();
    int adicionados = 0;
    for (final id in siteIds) {
      if (!existentes.contains(id)) {
        emp.sites.add(SiteModel(siteId: id));
        existentes.add(id);
        adicionados++;
      }
    }
    if (adicionados > 0) {
      _salvar();
      notifyListeners();
    }
    return adicionados;
  }

  void removerSite(int index) {
    final emp = empresaAtual;
    if (emp == null) return;
    final siteIdRemovido = emp.sites[index].siteId;
    emp.sites.removeAt(index);
    _removerSiteDosRelatorios(siteIdRemovido);
    _salvar();
    notifyListeners();
  }

  void _removerSiteDosRelatorios(String siteId) {
    for (final relatorio in _relatorios) {
      relatorio.sites.removeWhere((s) => s.siteId == siteId);
    }
    _salvarRelatorios();
  }

  void atualizarStatus(int index, SiteStatus status,
      {String motivo = '', DateTime? dataConclusao}) {
    final emp = empresaAtual;
    if (emp == null) return;
    emp.sites[index].status = status;
    if (status == SiteStatus.concluido) {
      final data = dataConclusao ?? DateTime.now();
      emp.sites[index].dataConclusao = DateTime(data.year, data.month, data.day);
      emp.sites[index].motivoNaoConcluido = '';
    } else if (status == SiteStatus.naoConcluido) {
      emp.sites[index].motivoNaoConcluido = motivo;
      emp.sites[index].dataConclusao = null;
    } else {
      emp.sites[index].motivoNaoConcluido = '';
      emp.sites[index].dataConclusao = null;
    }
    _salvar();

    _encerrarAutomaticamenteAdiantamentoAtual(
      dataBase: emp.sites[index].dataConclusao,
    );

    // Sincronizar com o relatório diário de hoje
    _sincronizarComRelatorio(emp.sites[index]);

    notifyListeners();
  }

  /// Sincroniza o status de um site com o relatório da data correspondente.
  /// Usa a dataConclusao do site para encontrar o relatório correto.
  /// Cria o relatório se não existir.
  void _sincronizarComRelatorio(SiteModel site) {
    // Usar a data do site para concluídos, ou hoje para outros status
    final dataAlvo = site.status == SiteStatus.concluido && site.dataConclusao != null
        ? site.dataConclusao!
        : DateTime.now();
    final dataAlvoStr =
        '${dataAlvo.year}-${dataAlvo.month.toString().padLeft(2, '0')}-${dataAlvo.day.toString().padLeft(2, '0')}';

    // Procurar relatório da data alvo
    var idx = _relatorios.indexWhere((r) {
      final d = r.data;
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}' ==
          dataAlvoStr;
    });

    // Se não existe, criar relatório para a data alvo com todos os sites e status real
    if (idx < 0) {
      final sites = <RelatorioSiteItem>[];
      if (empresaAtual != null) {
        final dataAlvoStrCheck = dataAlvoStr;
        for (final s in empresaAtual!.sites) {
          final item = RelatorioSiteItem(siteId: s.siteId);
          if (s.status == SiteStatus.concluido && s.dataConclusao != null) {
            final dc = s.dataConclusao!;
            final dcStr =
                '${dc.year}-${dc.month.toString().padLeft(2, '0')}-${dc.day.toString().padLeft(2, '0')}';
            if (dcStr == dataAlvoStrCheck) {
              item.feito = true;
              item.dataExecucao = s.dataConclusao;
            }
          } else if (s.status == SiteStatus.naoConcluido) {
            item.motivo = s.motivoNaoConcluido;
          }
          sites.add(item);
        }
      }
      final novoRelatorio = RelatorioDiario(
        id: 'rel_${DateTime.now().millisecondsSinceEpoch}',
        data: dataAlvo,
        sites: sites,
      );
      _relatorios.insert(0, novoRelatorio);
      idx = 0;
    }

    final relatorio = _relatorios[idx];

    // Encontrar o site correspondente no relatório
    final siteRelIdx =
        relatorio.sites.indexWhere((s) => s.siteId == site.siteId);

    if (siteRelIdx >= 0) {
      final item = relatorio.sites[siteRelIdx];
      if (site.status == SiteStatus.concluido) {
        item.feito = true;
        item.motivo = '';
        item.dataExecucao = site.dataConclusao ?? DateTime.now();
      } else if (site.status == SiteStatus.naoConcluido) {
        item.feito = false;
        item.motivo = site.motivoNaoConcluido;
        item.dataExecucao = null;
      } else {
        item.feito = false;
        item.motivo = '';
        item.dataExecucao = null;
      }
    } else {
      // Site não existe no relatório, adicionar
      relatorio.sites.add(RelatorioSiteItem(
        siteId: site.siteId,
        feito: site.status == SiteStatus.concluido,
        motivo: site.status == SiteStatus.naoConcluido
            ? site.motivoNaoConcluido
            : '',
        dataExecucao: site.status == SiteStatus.concluido
            ? (site.dataConclusao ?? DateTime.now())
            : null,
      ));
    }

    _salvarRelatorios();
  }

  /// Sincroniza alterações feitas no relatório de volta para a lista de sites.
  /// Quando o usuário muda o status na página de relatório, atualiza o site correspondente.
  void sincronizarRelatorioParaSites(RelatorioSiteItem relatorioItem) {
    final emp = empresaAtual;
    if (emp == null) return;

    final siteIdx =
        emp.sites.indexWhere((s) => s.siteId == relatorioItem.siteId);
    if (siteIdx < 0) return;

    final site = emp.sites[siteIdx];

    if (relatorioItem.feito) {
      site.status = SiteStatus.concluido;
      site.dataConclusao = relatorioItem.dataExecucao ?? DateTime.now();
      site.motivoNaoConcluido = '';
    } else if (relatorioItem.motivo.isNotEmpty) {
      site.status = SiteStatus.naoConcluido;
      site.motivoNaoConcluido = relatorioItem.motivo;
      site.dataConclusao = null;
    } else {
      site.status = SiteStatus.pendente;
      site.motivoNaoConcluido = '';
      site.dataConclusao = null;
    }

    _salvar();

    _encerrarAutomaticamenteAdiantamentoAtual(
      dataBase: site.dataConclusao,
    );

    notifyListeners();
  }

  // === ADIANTAMENTOS (empresa atual) ===

  int sitesConcluidosNoAdiantamento(int index) {
    final emp = empresaAtual;
    if (emp == null || index < 0 || index >= emp.adiantamentos.length) {
      return 0;
    }

    int restantesConcluidos = emp.sitesConcluidosElegiveisAdiantamento;

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
        restantesConcluidos -= (ad.sitesConcluidosNoEncerramento ?? ad.sitesPorLote);
      } else {
        restantesConcluidos -= concluidosNeste;
      }
    }

    return 0;
  }

  int? _indexPrimeiroAdiantamentoAberto([EmpresaModel? empRef]) {
    final emp = empRef ?? empresaAtual;
    if (emp == null) return null;
    final idx = emp.adiantamentos.indexWhere((a) => !a.encerrado);
    return idx >= 0 ? idx : null;
  }

  List<DateTime> _datasConclusaoElegiveisOrdenadasAsc(EmpresaModel emp) {
    final datas = emp.sites
        .where((s) => s.isConcluido && s.participaAdiantamento && s.dataConclusao != null)
        .map((s) {
          final d = s.dataConclusao!;
          return DateTime(d.year, d.month, d.day);
        })
        .toList()
      ..sort((a, b) => a.compareTo(b));
    return datas;
  }

  bool _recalcularFechamentoAdiantamentosPorDatas(
    EmpresaModel emp, {
    bool gerarMensagemNovosFechamentos = false,
  }) {
    final mensagens = <String>[];
    var houveMudanca = false;
    final datasOrdenadas = _datasConclusaoElegiveisOrdenadasAsc(emp);
    var concluidosConsumidos = 0;

    for (int i = 0; i < emp.adiantamentos.length; i++) {
      final ad = emp.adiantamentos[i];
      final eraEncerrado = ad.encerrado;
      final anteriorDataEnc = ad.dataEncerramento;
      final anteriorConcluidos = ad.sitesConcluidosNoEncerramento;

      final encerradoParcialManual = ad.encerrado &&
          ad.sitesConcluidosNoEncerramento != null &&
          ad.sitesConcluidosNoEncerramento! > 0 &&
          ad.sitesConcluidosNoEncerramento! < ad.sitesPorLote;

      if (encerradoParcialManual) {
        final concluidosParcial = ad.sitesConcluidosNoEncerramento!;
        if (datasOrdenadas.length >= concluidosConsumidos + concluidosParcial) {
          final dataParcial = datasOrdenadas[concluidosConsumidos + concluidosParcial - 1];
          final dataNormalizada = DateTime(
            dataParcial.year,
            dataParcial.month,
            dataParcial.day,
          );
          if (anteriorDataEnc != dataNormalizada) {
            ad.dataEncerramento = dataNormalizada;
            houveMudanca = true;
          }
        }
        concluidosConsumidos += concluidosParcial;
        continue;
      }

      final necessarioParaEncerrar = concluidosConsumidos + ad.sitesPorLote;
      if (datasOrdenadas.length >= necessarioParaEncerrar) {
        final dataFechamento = datasOrdenadas[necessarioParaEncerrar - 1];
        final dataNormalizada = DateTime(
          dataFechamento.year,
          dataFechamento.month,
          dataFechamento.day,
        );

        ad.encerrado = true;
        ad.sitesConcluidosNoEncerramento = ad.sitesPorLote;
        ad.dataEncerramento = dataNormalizada;

        if (!eraEncerrado && gerarMensagemNovosFechamentos) {
          mensagens.add(
            'Lote de ${ad.sitesPorLote} sites concluido. Adiantamento #${i + 1} encerrado automaticamente; os proximos sites ja contam no novo ciclo.',
          );
        }

        if (!eraEncerrado ||
            anteriorConcluidos != ad.sitesPorLote ||
            anteriorDataEnc != dataNormalizada) {
          houveMudanca = true;
        }

        concluidosConsumidos += ad.sitesPorLote;
      } else {
        if (ad.encerrado || ad.dataEncerramento != null || ad.sitesConcluidosNoEncerramento != null) {
          ad.encerrado = false;
          ad.dataEncerramento = null;
          ad.sitesConcluidosNoEncerramento = null;
          houveMudanca = true;
        }
      }
    }

    if (mensagens.isNotEmpty) {
      _mensagemSistemaPendente = mensagens.join('\n');
    }

    return houveMudanca;
  }

  void _encerrarAutomaticamenteAdiantamentoAtual({DateTime? dataBase}) {
    final emp = empresaAtual;
    if (emp == null) return;
    final mudou = _recalcularFechamentoAdiantamentosPorDatas(
      emp,
      gerarMensagemNovosFechamentos: true,
    );
    if (mudou) {
      _salvar();
    }
  }

  void atualizarParticipacaoAdiantamentoSite(int index, bool participa) {
    final emp = empresaAtual;
    if (emp == null) return;
    if (index < 0 || index >= emp.sites.length) return;
    emp.sites[index].participaAdiantamento = participa;
    _salvar();

    if (participa && emp.sites[index].isConcluido) {
      _encerrarAutomaticamenteAdiantamentoAtual(
        dataBase: emp.sites[index].dataConclusao,
      );
    }

    notifyListeners();
  }

  void adicionarAdiantamento(double valor, DateTime data,
      {String observacao = '', int? sitesPorLote, String identificacao = ''}) {
    final emp = empresaAtual;
    if (emp == null) return;
    emp.adiantamentos.add(AdiantamentoModel(
      valor: valor,
      data: data,
      identificacao: identificacao.trim(),
      observacao: observacao,
      sitesPorLote: sitesPorLote ?? emp.sitesPorLote,
    ));

    _encerrarAutomaticamenteAdiantamentoAtual(dataBase: data);

    _salvar();
    notifyListeners();
  }

  void registrarPrimeiroAdiantamento(double valor, DateTime data,
      {int? sitesPorLote, String identificacao = ''}) {
    final emp = empresaAtual;
    if (emp == null) return;
    final lote = sitesPorLote ?? emp.sitesPorLote;
    emp.adiantamentos.add(AdiantamentoModel(
      valor: valor,
      data: data,
      identificacao: identificacao.trim(),
      observacao: '1° Adiantamento (${(emp.percentualAdiantamento * 100).toStringAsFixed(0)}%)',
      sitesPorLote: lote,
    ));

    _encerrarAutomaticamenteAdiantamentoAtual(dataBase: data);

    _salvar();
    notifyListeners();
  }

  void removerAdiantamento(int index) {
    final emp = empresaAtual;
    if (emp == null) return;
    emp.adiantamentos.removeAt(index);
    _salvar();
    notifyListeners();
  }

  void atualizarIdentificacaoAdiantamento(int index, String identificacao) {
    final emp = empresaAtual;
    if (emp == null) return;
    final atual = emp.adiantamentos[index];
    emp.adiantamentos[index] = AdiantamentoModel(
      valor: atual.valor,
      data: atual.data,
      identificacao: identificacao.trim(),
      observacao: atual.observacao,
      sitesPorLote: atual.sitesPorLote,
      foiPago: atual.foiPago,
      dataPagamento: atual.dataPagamento,
      valorPago: atual.valorPago,
      encerrado: atual.encerrado,
      dataEncerramento: atual.dataEncerramento,
      sitesConcluidosNoEncerramento: atual.sitesConcluidosNoEncerramento,
    );
    _salvar();
    notifyListeners();
  }

  void encerrarAdiantamento(int index,
      {required int sitesConcluidos, DateTime? dataEncerramento}) {
    final emp = empresaAtual;
    if (emp == null) return;
    if (index < 0 || index >= emp.adiantamentos.length) return;

    final ad = emp.adiantamentos[index];
    final validado = sitesConcluidos.clamp(0, ad.sitesPorLote);
    ad.encerrado = true;
    ad.sitesConcluidosNoEncerramento = validado;
    final data = dataEncerramento ?? DateTime.now();
    ad.dataEncerramento = DateTime(data.year, data.month, data.day);
    _salvar();
    notifyListeners();
  }

  void reabrirAdiantamento(
    int index, {
    bool manterDataAtual = true,
    DateTime? novaDataCps,
  }) {
    final emp = empresaAtual;
    if (emp == null) return;
    if (index < 0 || index >= emp.adiantamentos.length) return;
    final atual = emp.adiantamentos[index];
    final dataFinal = manterDataAtual
        ? atual.data
        : DateTime(
            (novaDataCps ?? atual.data).year,
            (novaDataCps ?? atual.data).month,
            (novaDataCps ?? atual.data).day,
          );

    emp.adiantamentos[index] = AdiantamentoModel(
      valor: atual.valor,
      data: dataFinal,
      identificacao: atual.identificacao,
      observacao: atual.observacao,
      sitesPorLote: atual.sitesPorLote,
      foiPago: false,
      dataPagamento: null,
      valorPago: 0.0,
      encerrado: false,
      dataEncerramento: null,
      sitesConcluidosNoEncerramento: null,
    );
    _salvar();
    notifyListeners();
  }

  void marcarAdiantamentoPago(
    int index, {
    DateTime? dataPagamento,
    double? valorPago,
  }) {
    final emp = empresaAtual;
    if (emp == null) return;
    if (index < 0 || index >= emp.adiantamentos.length) return;

    final ad = emp.adiantamentos[index];
    final concluidosNoAdiantamento = ad.encerrado
        ? (ad.sitesConcluidosNoEncerramento ?? ad.sitesPorLote)
        : sitesConcluidosNoAdiantamento(index);
    final valorPadraoPago = (concluidosNoAdiantamento * emp.valorPorSite) - ad.valor;

    ad.foiPago = true;
    final data = dataPagamento ?? DateTime.now();
    ad.dataPagamento = DateTime(data.year, data.month, data.day);
    ad.valorPago = valorPago ?? valorPadraoPago;
    _salvar();
    notifyListeners();
  }

  void desmarcarAdiantamentoPago(int index) {
    final emp = empresaAtual;
    if (emp == null) return;
    if (index < 0 || index >= emp.adiantamentos.length) return;
    emp.adiantamentos[index].foiPago = false;
    _salvar();
    notifyListeners();
  }

  int marcarTodosAdiantamentosPendentesComoPago({DateTime? dataPagamento}) {
    final emp = empresaAtual;
    if (emp == null) return 0;

    final data = dataPagamento ?? DateTime.now();
    final dataNormalizada = DateTime(data.year, data.month, data.day);
    int totalMarcados = 0;

    for (int i = 0; i < emp.adiantamentos.length; i++) {
      final ad = emp.adiantamentos[i];
      if (ad.foiPago) continue;

      final concluidosNoAdiantamento = ad.encerrado
          ? (ad.sitesConcluidosNoEncerramento ?? ad.sitesPorLote)
          : sitesConcluidosNoAdiantamento(i);
      final valorPadraoPago =
          (concluidosNoAdiantamento * emp.valorPorSite) - ad.valor;

      ad.foiPago = true;
      ad.dataPagamento = dataNormalizada;
      ad.valorPago = valorPadraoPago;
      totalMarcados++;
    }

    if (totalMarcados > 0) {
      _salvar();
      notifyListeners();
    }

    return totalMarcados;
  }

  // === LANCAMENTOS FINANCEIROS (empresa atual) ===

  void adicionarLancamentoFinanceiro({
    required TipoLancamentoFinanceiro tipo,
    required double valor,
    required DateTime data,
    String descricao = '',
    bool descontaNoFinal = false,
    String referencia = '',
    bool recebido = true,
    DateTime? dataRecebimento,
    String? grupoParcelaId,
    int? parcelaNumero,
    int? parcelasTotal,
  }) {
    final emp = empresaAtual;
    if (emp == null) return;

    emp.lancamentosFinanceiros.add(
      LancamentoFinanceiroModel(
        id: 'lf_${DateTime.now().millisecondsSinceEpoch}',
        tipo: tipo,
        valor: valor,
        data: data,
        descricao: descricao.trim(),
        descontaNoFinal: descontaNoFinal,
        referencia: referencia.trim(),
        recebido: recebido,
        dataRecebimento: recebido ? (dataRecebimento ?? data) : null,
        grupoParcelaId: grupoParcelaId,
        parcelaNumero: parcelaNumero,
        parcelasTotal: parcelasTotal,
      ),
    );

    _salvar();
    notifyListeners();
  }

  void removerLancamentoFinanceiro(int index) {
    final emp = empresaAtual;
    if (emp == null) return;
    if (index < 0 || index >= emp.lancamentosFinanceiros.length) return;
    emp.lancamentosFinanceiros.removeAt(index);
    _salvar();
    notifyListeners();
  }

  void removerPlanoParcelamento(String grupoParcelaId) {
    final emp = empresaAtual;
    if (emp == null || grupoParcelaId.trim().isEmpty) return;
    emp.lancamentosFinanceiros
        .removeWhere((l) => l.grupoParcelaId == grupoParcelaId);
    _salvar();
    notifyListeners();
  }

  void marcarLancamentoFinanceiroRecebido(int index, {DateTime? dataRecebimento}) {
    final emp = empresaAtual;
    if (emp == null) return;
    if (index < 0 || index >= emp.lancamentosFinanceiros.length) return;
    final l = emp.lancamentosFinanceiros[index];
    l.recebido = true;
    l.dataRecebimento = dataRecebimento ?? DateTime.now();
    _salvar();
    notifyListeners();
  }

  void desmarcarLancamentoFinanceiroRecebido(int index) {
    final emp = empresaAtual;
    if (emp == null) return;
    if (index < 0 || index >= emp.lancamentosFinanceiros.length) return;
    final l = emp.lancamentosFinanceiros[index];
    l.recebido = false;
    l.dataRecebimento = null;
    _salvar();
    notifyListeners();
  }

  void criarPlanoParcelamento({
    required TipoLancamentoFinanceiro tipo,
    required double valorTotal,
    required int totalParcelas,
    required DateTime primeiraData,
    int intervaloDias = 7,
    String referenciaBase = '',
    String descricao = '',
    bool? descontaNoFinal,
  }) {
    final emp = empresaAtual;
    if (emp == null) return;
    if (valorTotal <= 0 || totalParcelas <= 0) return;

    final valorBase = (valorTotal / totalParcelas);
    final grupoParcelaId = 'grp_${DateTime.now().millisecondsSinceEpoch}_${tipo.index}';
    final desconto = descontaNoFinal ?? _descontoPadraoTipo(tipo);
    double acumulado = 0.0;

    for (int i = 1; i <= totalParcelas; i++) {
      final valorParcela =
          i == totalParcelas ? (valorTotal - acumulado) : valorBase;
      acumulado += valorParcela;

      final dataParcela = primeiraData.add(Duration(days: (i - 1) * intervaloDias));
      final referencia = referenciaBase.trim().isEmpty
          ? 'Plano $grupoParcelaId'
          : '${referenciaBase.trim()} - Parcela $i/$totalParcelas';

      emp.lancamentosFinanceiros.add(
        LancamentoFinanceiroModel(
          id: 'lf_${DateTime.now().millisecondsSinceEpoch}_$i',
          tipo: tipo,
          valor: valorParcela,
          data: dataParcela,
          descricao: descricao.trim(),
          descontaNoFinal: desconto,
          recebido: false,
          dataRecebimento: null,
          referencia: referencia,
          grupoParcelaId: grupoParcelaId,
          parcelaNumero: i,
          parcelasTotal: totalParcelas,
        ),
      );
    }

    _salvar();
    notifyListeners();
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

  // === PAGAMENTO FINAL ===

  void marcarEmpresaPaga(double valorPago, DateTime dataPagamento) {
    final emp = empresaAtual;
    if (emp == null) return;
    emp.foiPago = true;
    emp.valorPago = valorPago;
    emp.dataPagamento = dataPagamento;
    _salvar();
    notifyListeners();
  }

  void desmarcarEmpresaPaga() {
    final emp = empresaAtual;
    if (emp == null) return;
    emp.foiPago = false;
    emp.valorPago = 0.0;
    emp.dataPagamento = null;
    _salvar();
    notifyListeners();
  }

  // === RELATÓRIOS DIÁRIOS ===

  Future<void> _salvarRelatorios() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'relatorios_v1', RelatorioDiario.encodeList(_relatorios));
    _agendarAutoBackupNuvem();
  }

  Future<void> _salvarRelatorioConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('relatorio_config', _relatorioConfig.encode());
    _agendarAutoBackupNuvem();
  }

  Future<void> _salvarDemandasArquivadas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'demandas_arquivadas_v1',
      DemandaGeralModel.encodeList(_demandasArquivadas),
    );
    _agendarAutoBackupNuvem();
  }

  Future<void> _salvarEventosDemanda() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'demanda_eventos_v1',
      DemandaEventoModel.encodeList(_eventosDemanda),
    );
    _agendarAutoBackupNuvem();
  }

  void _registrarEventoDemanda(
    String demandaId,
    String acao,
    String descricao,
  ) {
    _eventosDemanda.insert(
      0,
      DemandaEventoModel(
        id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
        demandaId: demandaId,
        acao: acao,
        descricao: descricao,
        dataHora: DateTime.now(),
      ),
    );
    _salvarEventosDemanda();
  }

  void adicionarRelatorio(RelatorioDiario relatorio) {
    _relatorios.insert(0, relatorio);
    _salvarRelatorios();
    notifyListeners();
  }

  void atualizarRelatorio(int index, RelatorioDiario relatorio) {
    _relatorios[index] = relatorio;
    _salvarRelatorios();
    notifyListeners();
  }

  void removerRelatorio(int index) {
    _relatorios.removeAt(index);
    _salvarRelatorios();
    notifyListeners();
  }

  void salvarRelatorioAtual(RelatorioDiario relatorio) {
    final idx = _relatorios.indexWhere((r) => r.id == relatorio.id);
    if (idx >= 0) {
      _relatorios[idx] = relatorio;
    } else {
      _relatorios.insert(0, relatorio);
    }
    _salvarRelatorios();
    notifyListeners();
  }

  void atualizarRelatorioConfig(RelatorioConfig config) {
    _relatorioConfig = config;
    _salvarRelatorioConfig();
    notifyListeners();
  }

  void adicionarOperadora(String operadora) {
    if (!_relatorioConfig.operadoras.contains(operadora)) {
      _relatorioConfig.operadoras.add(operadora);
      _salvarRelatorioConfig();
      notifyListeners();
    }
  }

  void adicionarFabricante(String fabricante) {
    if (!_relatorioConfig.fabricantes.contains(fabricante)) {
      _relatorioConfig.fabricantes.add(fabricante);
      _salvarRelatorioConfig();
      notifyListeners();
    }
  }

  void adicionarProjeto(String projeto) {
    if (!_relatorioConfig.projetos.contains(projeto)) {
      _relatorioConfig.projetos.add(projeto);
      _salvarRelatorioConfig();
      notifyListeners();
    }
  }

  // === DEMANDA GERAL (CICLO) ===

  Future<bool> concluirDemandaGeral({
    String? nome,
    String responsavel = '',
    String observacao = '',
    bool usarNomeSugerido = false,
  }) async {
    final now = DateTime.now();
    final existeConteudo = _empresas.isNotEmpty || _relatorios.isNotEmpty;
    if (!existeConteudo) return false;

    final nomeInformado = nome?.trim() ?? '';
    final sugestaoValida = (_nomeDemandaSugerido ?? '').trim();
    final nomeFinal = nomeInformado.isNotEmpty
        ? nomeInformado
        : (usarNomeSugerido && sugestaoValida.isNotEmpty)
            ? sugestaoValida
            : '';
    if (nomeFinal.isEmpty) return false;

    final empresasSnapshot = EmpresaModel.decodeList(
      EmpresaModel.encodeList(_empresas),
    );
    final relatoriosSnapshot = RelatorioDiario.decodeList(
      RelatorioDiario.encodeList(_relatorios),
    );

    final demanda = DemandaGeralModel(
      id: _demandaReabertaId ?? 'dem_${now.millisecondsSinceEpoch}',
      nome: nomeFinal,
      dataConclusao: now,
      responsavelFechamento: responsavel.trim(),
      observacaoFechamento: observacao.trim(),
      empresas: empresasSnapshot,
      relatorios: relatoriosSnapshot,
    );

    final indexExistente = _demandaReabertaId == null
        ? -1
        : _demandasArquivadas.indexWhere((d) => d.id == _demandaReabertaId);
    if (indexExistente >= 0) {
      _demandasArquivadas[indexExistente] = demanda;
      _demandasArquivadas.sort(
        (a, b) => b.dataConclusao.compareTo(a.dataConclusao),
      );
    } else {
      _demandasArquivadas.insert(0, demanda);
    }
    _registrarEventoDemanda(
      demanda.id,
      indexExistente >= 0 ? 'atualizar' : 'concluir',
      indexExistente >= 0
          ? 'Demanda atualizada e arquivada novamente.'
          : (responsavel.trim().isNotEmpty
              ? 'Demanda concluída por ${responsavel.trim()}.'
              : 'Demanda concluída e arquivada.'),
    );

    _empresas = [];
    _relatorios = [];
    _empresaSelecionadaIndex = 0;
    _nomeDemandaSugerido = null;
    _responsavelFechamentoSugerido = null;
    _demandaReabertaId = null;

    await _salvar();
    await _salvarRelatorios();
    await _salvarDemandasArquivadas();
    notifyListeners();
    return true;
  }

  Future<bool> reabrirDemandaGeral(
    String demandaId, {
    bool manterDatasOriginais = true,
    DateTime? novaDataBase,
  }) async {
    final demanda = _demandasArquivadas.where((d) => d.id == demandaId);
    if (demanda.isEmpty) return false;
    final selecionada = demanda.first;

    _empresas = EmpresaModel.decodeList(
      EmpresaModel.encodeList(selecionada.empresas),
    );
    _relatorios = RelatorioDiario.decodeList(
      RelatorioDiario.encodeList(selecionada.relatorios),
    );

    if (!manterDatasOriginais) {
      final base = novaDataBase ?? DateTime.now();
      final dataNormalizada = DateTime(base.year, base.month, base.day);

      for (final empresa in _empresas) {
        for (final site in empresa.sites) {
          if (site.isConcluido) {
            site.dataConclusao = dataNormalizada;
          }
        }

        for (final adiantamento in empresa.adiantamentos) {
          if (adiantamento.encerrado) {
            adiantamento.dataEncerramento = dataNormalizada;
          }
          if (adiantamento.foiPago) {
            adiantamento.dataPagamento = dataNormalizada;
          }
        }

        _recalcularFechamentoAdiantamentosPorDatas(empresa);
      }

      for (final relatorio in _relatorios) {
        relatorio.data = dataNormalizada;
        for (final item in relatorio.sites) {
          if (item.feito) {
            item.dataExecucao = dataNormalizada;
          }
        }
      }
    }

    _empresaSelecionadaIndex = _empresas.isEmpty ? 0 : 0;
    _nomeDemandaSugerido = selecionada.nome;
    _responsavelFechamentoSugerido =
      selecionada.responsavelFechamento.trim().isNotEmpty
        ? selecionada.responsavelFechamento.trim()
        : null;
    _demandaReabertaId = selecionada.id;
    _registrarEventoDemanda(
      selecionada.id,
      'reabrir',
      'Demanda reaberta para edição.',
    );

    await _salvar();
    await _salvarRelatorios();
    notifyListeners();
    return true;
  }

  Future<bool> duplicarDemandaArquivadaParaNovoCiclo(
    String demandaId, {
    String? sufixoNome,
  }) async {
    final encontrada = _demandasArquivadas.where((d) => d.id == demandaId);
    if (encontrada.isEmpty) return false;
    final base = encontrada.first;
    _registrarEventoDemanda(
      base.id,
      'duplicar',
      'Novo ciclo criado a partir desta demanda arquivada.',
    );

    final novasEmpresas = base.empresas.map((e) {
      final sitesNovos = e.sites
          .map((s) => SiteModel(siteId: s.siteId))
          .toList();

      return EmpresaModel(
        id: '${e.id}_${DateTime.now().millisecondsSinceEpoch}',
        nome: sufixoNome != null && sufixoNome.trim().isNotEmpty
            ? '${e.nome} ${sufixoNome.trim()}'
            : '${e.nome} (Novo ciclo)',
        valorPorSite: e.valorPorSite,
        sites: sitesNovos,
        adiantamentos: [],
        tipoAdiantamento: e.tipoAdiantamento,
        percentualAdiantamento: e.percentualAdiantamento,
        sitesPorLote: e.sitesPorLote,
        valorAdiantamentoFixo: e.valorAdiantamentoFixo,
        foiPago: false,
        valorPago: 0.0,
        dataPagamento: null,
      );
    }).toList();

    _empresas = novasEmpresas;
    _relatorios = [];
    _empresaSelecionadaIndex = _empresas.isEmpty ? 0 : 0;
    _nomeDemandaSugerido = null;
    _responsavelFechamentoSugerido = null;
    _demandaReabertaId = null;

    await _salvar();
    await _salvarRelatorios();
    notifyListeners();
    return true;
  }

  Future<bool> excluirDemandaArquivada(String demandaId) async {
    final index = _demandasArquivadas.indexWhere((d) => d.id == demandaId);
    if (index < 0) return false;

    _demandasArquivadas.removeAt(index);
    _eventosDemanda.removeWhere((e) => e.demandaId == demandaId);
    if (_demandaReabertaId == demandaId) {
      _demandaReabertaId = null;
      _nomeDemandaSugerido = null;
      _responsavelFechamentoSugerido = null;
    }

    await _salvarDemandasArquivadas();
    await _salvarEventosDemanda();
    notifyListeners();
    return true;
  }

  List<DemandaEventoModel> eventosDaDemanda(String demandaId) {
    return _eventosDemanda
        .where((e) => e.demandaId == demandaId)
        .toList()
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
  }

  List<DemandaGeralModel> demandasArquivadasPorStatus(String status) {
    if (status == 'todos') return _demandasArquivadas;
    return _demandasArquivadas
        .where((d) => d.statusProfissional.toLowerCase() == status.toLowerCase())
        .toList();
  }

  /// Nomes únicos de empresas presentes em qualquer demanda arquivada.
  List<String> get empresasNoHistorico {
    final nomes = <String>{};
    for (final d in _demandasArquivadas) {
      for (final e in d.empresas) {
        if (e.nome.isNotEmpty) nomes.add(e.nome);
      }
    }
    return nomes.toList()..sort();
  }

  /// Demandas arquivadas que contêm a empresa com [nomeEmpresa].
  List<DemandaGeralModel> demandasArquivadasPorEmpresa(String nomeEmpresa) {
    return _demandasArquivadas
        .where((d) => d.empresas.any((e) => e.nome == nomeEmpresa))
        .toList();
  }

  Future<bool> verificarConexaoDrive() => _driveBackupService.verificarConexao();
  Future<bool> conectarDriveInterativo() => _driveBackupService.conectarInterativo();

  // === BACKUP E RESTAURAÇÃO ===

  String gerarBackupJson() {
    final backup = {
      'versao': 1,
      'dataBackup': DateTime.now().toIso8601String(),
      'empresas': _empresas.map((e) => e.toJson()).toList(),
      'relatorios': _relatorios.map((r) => r.toJson()).toList(),
      'demandasArquivadas': _demandasArquivadas.map((d) => d.toJson()).toList(),
      'eventosDemanda': _eventosDemanda.map((e) => e.toJson()).toList(),
      'relatorioConfig': _relatorioConfig.toJson(),
      if (_nomeDemandaSugerido != null) 'nomeDemandaSugerido': _nomeDemandaSugerido,
      if (_responsavelFechamentoSugerido != null)
        'responsavelFechamentoSugerido': _responsavelFechamentoSugerido,
      if (_demandaReabertaId != null) 'demandaReabertaId': _demandaReabertaId,
    };
    return jsonEncode(backup);
  }

  Future<bool> restaurarBackupJson(String jsonStr) async {
    try {
      final backup = jsonDecode(jsonStr) as Map<String, dynamic>;

      final empresas = (backup['empresas'] as List)
          .map((e) => EmpresaModel.fromJson(e))
          .toList();

      List<RelatorioDiario> relatorios = [];
      if (backup['relatorios'] != null) {
        relatorios = (backup['relatorios'] as List)
            .map((r) => RelatorioDiario.fromJson(r))
            .toList();
      }

      List<DemandaGeralModel> demandasArquivadas = [];
      if (backup['demandasArquivadas'] != null) {
        demandasArquivadas = (backup['demandasArquivadas'] as List)
        .map((d) => DemandaGeralModel.fromJson(d))
        .toList();
      }

      List<DemandaEventoModel> eventosDemanda = [];
      if (backup['eventosDemanda'] != null) {
        eventosDemanda = (backup['eventosDemanda'] as List)
            .map((e) => DemandaEventoModel.fromJson(e))
            .toList();
      }

      RelatorioConfig config = RelatorioConfig();
      if (backup['relatorioConfig'] != null) {
        config = RelatorioConfig.fromJson(backup['relatorioConfig']);
      }

      _empresas = empresas;
      _relatorios = relatorios;
      _demandasArquivadas = demandasArquivadas;
      _eventosDemanda = eventosDemanda;
      _relatorioConfig = config;
      _empresaSelecionadaIndex = 0;
      _nomeDemandaSugerido = backup['nomeDemandaSugerido'] as String?;
        _responsavelFechamentoSugerido =
          backup['responsavelFechamentoSugerido'] as String?;
      _demandaReabertaId = backup['demandaReabertaId'] as String?;
        _reconciliarSugestoesDemandaReaberta();

      await _salvar();
      await _salvarRelatorios();
      await _salvarDemandasArquivadas();
      await _salvarEventosDemanda();
      await _salvarRelatorioConfig();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> limparDadosLocaisCompletos() async {
    final prefs = await SharedPreferences.getInstance();
    _autoBackupDebounce?.cancel();
    _autoBackupEmAndamento = false;

    await prefs.remove('empresas_v2');
    await prefs.remove('sites');
    await prefs.remove('adiantamentos');
    await prefs.remove('relatorios_v1');
    await prefs.remove('demandas_arquivadas_v1');
    await prefs.remove('demanda_eventos_v1');
    await prefs.remove('relatorio_config');
    await prefs.remove('nome_demanda_sugerido');
    await prefs.remove('responsavel_fechamento_sugerido');
    await prefs.remove('demanda_reaberta_id');
    await prefs.remove(_ordenacaoLancamentosKey);
    await prefs.remove(_filtroLancamentosKey);
    await prefs.remove(_filtroPlanosKey);
    await prefs.remove(_presetVisualizacaoFinanceiraKey);
    await prefs.remove(_mostrarAtalhosPresetsKey);

    _empresas = [];
    _relatorios = [];
    _demandasArquivadas = [];
    _eventosDemanda = [];
    _relatorioConfig = RelatorioConfig();
    _empresaSelecionadaIndex = 0;
    _nomeDemandaSugerido = null;
    _responsavelFechamentoSugerido = null;
    _demandaReabertaId = null;
    _ordenacaoLancamentosPorEmpresa = {};
    _filtroLancamentosPorEmpresa = {};
    _filtroPlanosPorEmpresa = {};
    _presetVisualizacaoFinanceiraPorEmpresa = {};
    _mostrarAtalhosPresetsPorEmpresa = {};
    notifyListeners();
  }

  // === TEXTO PARA COMPARTILHAR ===

  String gerarTextoCompartilhamento() {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('📊 RELATÓRIO DE DEMANDA - TSSR');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('Data: ${_formatDate(DateTime.now())}');
    buffer.writeln('');

    for (final emp in _empresas) {
      var descricaoAdiantamento = emp.tipoAdiantamentoDescricao;
      if (emp.tipoAdiantamento == TipoAdiantamento.percentualPorLote &&
          emp.adiantamentos.isNotEmpty) {
        final lotesHistorico = emp.adiantamentos
            .map((a) => a.sitesPorLote)
            .toSet()
            .toList()
          ..sort();
        final lotesStr = lotesHistorico.join(', ');
        descricaoAdiantamento =
            '${(emp.percentualAdiantamento * 100).toStringAsFixed(0)}% por lote (histórico: $lotesStr sites)';
      }

      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('🏢 EMPRESA: ${emp.nome.toUpperCase()}');
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('💲 Valor por Site: ${_formatCurrency(emp.valorPorSite)}');
      buffer.writeln('📋 Adiantamento: $descricaoAdiantamento');
      buffer.writeln(
          emp.foiPago ? "✅ PAGO" : "⏳ AGUARDANDO PAGAMENTO");
      buffer.writeln('');
      buffer.writeln('📍 Total de Sites: ${emp.totalSites}');
      buffer.writeln('✅ Concluídos: ${emp.sitesConcluidos}');
        buffer.writeln('🎯 Concluídos Elegíveis (adiant.): ${emp.sitesConcluidosElegiveisAdiantamento}');
      buffer.writeln('❌ Não Concluídos: ${emp.sitesNaoConcluidos}');
      buffer.writeln('⏳ Pendentes: ${emp.sitesPendentes}');
      buffer.writeln('');
      buffer.writeln(
          '💰 Estimativa Total: ${_formatCurrency(emp.estimativaTotal)}');
      buffer.writeln(
          '✅ Valor Ganho: ${_formatCurrency(emp.valorGanho)}');
      buffer.writeln(
          '💵 Total Adiantamentos: ${_formatCurrency(emp.totalAdiantamentos)}');
      buffer.writeln(
          '📉 Lançamentos Descontáveis: ${_formatCurrency(emp.totalLancamentosDescontaveis)}');
      buffer.writeln(
          '📈 Lançamentos Não Descontáveis: ${_formatCurrency(emp.totalLancamentosNaoDescontaveis)}');
        buffer.writeln(
          '🗓️ Lançamentos Previstos: ${_formatCurrency(emp.totalLancamentosPrevistos)}');
      buffer.writeln(
          '💰 A Receber: ${_formatCurrency(emp.valorReceberComAdiantamento)}');
      buffer.writeln(
          '💼 Saldo com Lançamentos: ${_formatCurrency(emp.saldoFinanceiroComLancamentos)}');
      buffer.writeln('');

      for (final site in emp.sites) {
        String statusIcon;
        String statusText;
        switch (site.status) {
          case SiteStatus.concluido:
            statusIcon = '✅';
            statusText = 'TSSR CONCLUÍDO';
            break;
          case SiteStatus.naoConcluido:
            statusIcon = '❌';
            statusText = 'NÃO CONCLUÍDO';
            break;
          case SiteStatus.pendente:
            statusIcon = '🔄';
            statusText = 'AGUARDANDO TSSR';
            break;
        }
        final tagAdiant = site.participaAdiantamento ? '' : ' [SEM ADIANT.]';
        buffer.writeln('$statusIcon ${site.siteId}$tagAdiant - $statusText');
        if (site.isConcluido && site.dataConclusao != null) {
          buffer.writeln('   Data: ${_formatDate(site.dataConclusao!)}');
        }
        if (site.isNaoConcluido && site.motivoNaoConcluido.isNotEmpty) {
          buffer.writeln('   📝 Motivo: ${site.motivoNaoConcluido}');
        }
      }

      if (emp.adiantamentos.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('💳 ADIANTAMENTOS:');
        for (int i = 0; i < emp.adiantamentos.length; i++) {
          final a = emp.adiantamentos[i];
          final pago = a.foiPago ? '✅ PAGO' : '⏳ PENDENTE';
          final nomeLote = a.identificacao.trim().isNotEmpty
              ? a.identificacao.trim()
              : 'Lote ${i + 1}';
          final sitesNoLote = a.encerrado
              ? (a.sitesConcluidosNoEncerramento ?? a.sitesPorLote)
              : a.sitesPorLote;
          final valorBrutoLote = sitesNoLote * emp.valorPorSite;
          final valorReceberLote = valorBrutoLote - a.valor;
          final fechamento = a.encerrado
              ? _formatDate(a.dataEncerramento ?? a.data)
              : 'Em aberto';

          buffer.writeln(
              '  ${i + 1}. $nomeLote - ${_formatCurrency(a.valor)} - ${_formatDate(a.data)} [$pago]');
          buffer.writeln('     📦 Lote: $sitesNoLote sites');
          buffer.writeln('     📅 Fechamento: $fechamento');
          buffer.writeln('     💰 A receber no lote: ${_formatCurrency(valorReceberLote)}');
          if (a.observacao.isNotEmpty) {
            buffer.writeln('     📝 ${a.observacao}');
          }
        }
      }

      if (emp.lancamentosFinanceiros.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('🧾 LANÇAMENTOS FINANCEIROS:');
        for (int i = 0; i < emp.lancamentosFinanceiros.length; i++) {
          final l = emp.lancamentosFinanceiros[i];
          final desconto = l.descontaNoFinal ? 'DESCONTA' : 'NÃO DESCONTA';
          final tipo = switch (l.tipo) {
            TipoLancamentoFinanceiro.adiantamentoDescontavel => 'Adiantamento descontável',
            TipoLancamentoFinanceiro.ajudaCustoNaoDescontavel => 'Ajuda custo não descontável',
            TipoLancamentoFinanceiro.ajudaCustoDescontavel => 'Ajuda custo descontável',
            TipoLancamentoFinanceiro.pagamentoFinal => 'Pagamento final',
            TipoLancamentoFinanceiro.ajuste => 'Ajuste financeiro',
          };
          buffer.writeln(
              '  ${i + 1}. $tipo - ${_formatCurrency(l.valor)} - ${_formatDate(l.data)} [$desconto]');
          if (l.eParcela) {
            buffer.writeln('     📦 Parcela ${l.parcelaNumero}/${l.parcelasTotal}');
          }
          if (l.referencia.isNotEmpty) {
            buffer.writeln('     🔖 ${l.referencia}');
          }
          if (l.descricao.isNotEmpty) {
            buffer.writeln('     📝 ${l.descricao}');
          }
        }
      }
      buffer.writeln('');
    }

    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('📊 RESUMO GLOBAL');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('🏢 Total Empresas: ${_empresas.length}');
    buffer.writeln('📍 Total Sites: $totalSitesGlobal');
    buffer.writeln('✅ Concluídos: $sitesConcluidosGlobal');
    buffer.writeln(
        '💰 Valor Ganho Total: ${_formatCurrency(valorGanhoGlobal)}');
    buffer.writeln(
        '💵 Adiantamentos Total: ${_formatCurrency(totalAdiantamentosGlobal)}');
    buffer.writeln(
        '📉 Lançamentos Descontáveis Total: ${_formatCurrency(totalLancamentosDescontaveisGlobal)}');
    buffer.writeln(
        '📈 Lançamentos Não Descontáveis Total: ${_formatCurrency(totalLancamentosNaoDescontaveisGlobal)}');
    buffer.writeln(
      '🗓️ Lançamentos Previstos Total: ${_formatCurrency(totalLancamentosPrevistosGlobal)}');
    buffer.writeln(
        '💰 A Receber Total: ${_formatCurrency(valorReceberGlobal)}');
    buffer.writeln(
      '💼 Saldo Total com Lançamentos: ${_formatCurrency(valorReceberGlobalComLancamentos)}');
    buffer.writeln('');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('⚡ *DEMANDA CONTROLLER*  ·  v1.0');
    buffer.writeln('🔧 VJC Technology — Soluções em Telecom');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return buffer.toString();
  }

  String _formatCurrency(double value) {
    return CurrencyUtils.formatBRL(value);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
