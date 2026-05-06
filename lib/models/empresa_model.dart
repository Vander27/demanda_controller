import 'dart:convert';
import 'site_model.dart';
import 'adiantamento_model.dart';
import 'lancamento_financeiro_model.dart';

enum TipoAdiantamento {
  percentualPorLote,   // Ex: Prencell - 40% a cada 20 sites
  valorFixoSemanal,    // Acordo de valor fixo por semana
  valorFixoUnico,      // Um valor único de adiantamento
  semAdiantamento,     // Sem adiantamento
}

class EmpresaModel {
  String id;
  String nome;
  double valorPorSite;
  List<SiteModel> sites;
  List<AdiantamentoModel> adiantamentos;
  List<LancamentoFinanceiroModel> lancamentosFinanceiros;

  // Configuração de adiantamento
  TipoAdiantamento tipoAdiantamento;
  double percentualAdiantamento; // Ex: 0.40 (40%)
  int sitesPorLote;              // Ex: 20 sites por lote
  double valorAdiantamentoFixo;  // Para tipo fixo semanal/único

  // Status de pagamento final
  bool foiPago;
  DateTime? dataPagamento;
  double valorPago;

  EmpresaModel({
    required this.id,
    required this.nome,
    this.valorPorSite = 600.0,
    List<SiteModel>? sites,
    List<AdiantamentoModel>? adiantamentos,
    List<LancamentoFinanceiroModel>? lancamentosFinanceiros,
    this.tipoAdiantamento = TipoAdiantamento.percentualPorLote,
    this.percentualAdiantamento = 0.40,
    this.sitesPorLote = 20,
    this.valorAdiantamentoFixo = 0.0,
    this.foiPago = false,
    this.dataPagamento,
    this.valorPago = 0.0,
  })  : sites = sites ?? [],
        adiantamentos = adiantamentos ?? [],
        lancamentosFinanceiros = lancamentosFinanceiros ?? [];

  // Cálculos
  int get totalSites => sites.length;
  int get sitesConcluidos => sites.where((s) => s.isConcluido).length;
  int get sitesConcluidosElegiveisAdiantamento =>
      sites.where((s) => s.isConcluido && s.participaAdiantamento).length;
  int get sitesNaoConcluidos => sites.where((s) => s.isNaoConcluido).length;
  int get sitesPendentes => sites.where((s) => s.isPendente).length;

  double get estimativaTotal => totalSites * valorPorSite;
  double get valorGanho => sitesConcluidos * valorPorSite;
  double get valorPerdido => sitesNaoConcluidos * valorPorSite;
  double get valorPendente => sitesPendentes * valorPorSite;

  double get totalAdiantamentos =>
      adiantamentos.fold(0.0, (sum, a) => sum + a.valor);

  double get totalLancamentosFinanceiros => lancamentosFinanceiros
      .where((l) => l.recebido)
      .fold(0.0, (sum, l) => sum + l.valor);

  double get totalLancamentosDescontaveis => lancamentosFinanceiros
      .where((l) => l.descontaNoFinal && l.recebido)
      .fold(0.0, (sum, l) => sum + l.valor);

  double get totalLancamentosNaoDescontaveis => lancamentosFinanceiros
      .where((l) => !l.descontaNoFinal && l.recebido)
      .fold(0.0, (sum, l) => sum + l.valor);

  double get totalLancamentosPrevistos => lancamentosFinanceiros
      .where((l) => !l.recebido)
      .fold(0.0, (sum, l) => sum + l.valor);

  double get totalLancamentosPrevistosDescontaveis => lancamentosFinanceiros
      .where((l) => l.descontaNoFinal && !l.recebido)
      .fold(0.0, (sum, l) => sum + l.valor);

  double get totalLancamentosPrevistosNaoDescontaveis => lancamentosFinanceiros
      .where((l) => !l.descontaNoFinal && !l.recebido)
      .fold(0.0, (sum, l) => sum + l.valor);

  int get totalSitesCobertosAdiantamentos => adiantamentos.fold(0, (sum, a) {
        if (a.encerrado) {
          return sum + (a.sitesConcluidosNoEncerramento ?? a.sitesPorLote);
        }
        return sum + a.sitesPorLote;
      });

  double get valorReceberComAdiantamento => valorGanho - totalAdiantamentos;
  double get valorReceberSemAdiantamento => valorGanho;

  double get saldoFinanceiroComLancamentos =>
      valorGanho + totalLancamentosNaoDescontaveis - totalAdiantamentos - totalLancamentosDescontaveis;

    double get saldoFinanceiroPrevistoComLancamentos =>
      valorGanho +
      (totalLancamentosNaoDescontaveis + totalLancamentosPrevistosNaoDescontaveis) -
      totalAdiantamentos -
      (totalLancamentosDescontaveis + totalLancamentosPrevistosDescontaveis);

  // Cálculo por lote (referência)
  double get valorTotalLote => sitesPorLote * valorPorSite;
  double get valorAdiantamentoLote =>
      tipoAdiantamento == TipoAdiantamento.percentualPorLote
          ? valorTotalLote * percentualAdiantamento
          : valorAdiantamentoFixo;
  double get valorReceberLote => valorTotalLote - valorAdiantamentoLote;

  // Calcula quantos sites de lotes anteriores já foram totalmente concluídos
  // Percorre os adiantamentos acumulando sitesPorLote até encontrar o lote atual
  int get _sitesLotesAnterioresConcluidos {
    int acumulado = 0;
    final concluidosElegiveis = sitesConcluidosElegiveisAdiantamento;
    for (final a in adiantamentos) {
      if (acumulado + a.sitesPorLote <= concluidosElegiveis) {
        acumulado += a.sitesPorLote;
      } else {
        break;
      }
    }
    return acumulado;
  }

  // sitesPorLote do lote em que estamos trabalhando atualmente
  int get sitesPorLoteAtual {
    int acumulado = 0;
    final concluidosElegiveis = sitesConcluidosElegiveisAdiantamento;
    for (final a in adiantamentos) {
      if (acumulado + a.sitesPorLote <= concluidosElegiveis) {
        acumulado += a.sitesPorLote;
      } else {
        return a.sitesPorLote;
      }
    }
    return sitesPorLote; // fallback padrão
  }

  // Quantos sites foram concluídos no lote atual
  int get sitesNoLoteAtual =>
      sitesConcluidosElegiveisAdiantamento - _sitesLotesAnterioresConcluidos;

  // Verificar se precisa solicitar novo adiantamento
  // (todos os lotes cobertos por adiantamentos já foram concluídos)
  bool get precisaSolicitarAdiantamento {
    if (tipoAdiantamento == TipoAdiantamento.semAdiantamento) return false;
    if (tipoAdiantamento == TipoAdiantamento.percentualPorLote) {
      final totalCoberto = totalSitesCobertosAdiantamentos;
      return sitesConcluidosElegiveisAdiantamento >= totalCoberto;
    }
    return false;
  }

  int get sitesAteLoteAtual {
    if (tipoAdiantamento != TipoAdiantamento.percentualPorLote) return 0;
    return sitesPorLoteAtual - sitesNoLoteAtual;
  }

  double get progressoGeral =>
      totalSites > 0 ? sitesConcluidos / totalSites : 0.0;

  double get progressoLote {
    if (tipoAdiantamento != TipoAdiantamento.percentualPorLote ||
        sitesPorLoteAtual <= 0) {
      return 0.0;
    }
    return sitesNoLoteAtual / sitesPorLoteAtual;
  }

  String get tipoAdiantamentoDescricao {
    switch (tipoAdiantamento) {
      case TipoAdiantamento.percentualPorLote:
        return '${(percentualAdiantamento * 100).toStringAsFixed(0)}% a cada $sitesPorLote sites';
      case TipoAdiantamento.valorFixoSemanal:
        return 'R\$ ${valorAdiantamentoFixo.toStringAsFixed(2).replaceAll('.', ',')} por semana';
      case TipoAdiantamento.valorFixoUnico:
        return 'R\$ ${valorAdiantamentoFixo.toStringAsFixed(2).replaceAll('.', ',')} (valor único)';
      case TipoAdiantamento.semAdiantamento:
        return 'Sem adiantamento';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'valorPorSite': valorPorSite,
        'sites': sites.map((s) => s.toJson()).toList(),
        'adiantamentos': adiantamentos.map((a) => a.toJson()).toList(),
        'lancamentosFinanceiros':
          lancamentosFinanceiros.map((l) => l.toJson()).toList(),
        'tipoAdiantamento': tipoAdiantamento.index,
        'percentualAdiantamento': percentualAdiantamento,
        'sitesPorLote': sitesPorLote,
        'valorAdiantamentoFixo': valorAdiantamentoFixo,
        'foiPago': foiPago,
        'dataPagamento': dataPagamento?.toIso8601String(),
        'valorPago': valorPago,
      };

  factory EmpresaModel.fromJson(Map<String, dynamic> json) => EmpresaModel(
        id: json['id'],
        nome: json['nome'],
        valorPorSite: (json['valorPorSite'] as num).toDouble(),
        sites: (json['sites'] as List)
            .map((s) => SiteModel.fromJson(s))
            .toList(),
        adiantamentos: (json['adiantamentos'] as List)
            .map((a) => AdiantamentoModel.fromJson(a))
            .toList(),
        lancamentosFinanceiros: (json['lancamentosFinanceiros'] as List?)
            ?.map((l) => LancamentoFinanceiroModel.fromJson(l))
            .toList() ??
          [],
        tipoAdiantamento: TipoAdiantamento.values[json['tipoAdiantamento']],
        percentualAdiantamento:
            (json['percentualAdiantamento'] as num).toDouble(),
        sitesPorLote: json['sitesPorLote'],
        valorAdiantamentoFixo:
            (json['valorAdiantamentoFixo'] as num).toDouble(),
        foiPago: json['foiPago'] ?? false,
        dataPagamento: json['dataPagamento'] != null
            ? DateTime.parse(json['dataPagamento'])
            : null,
        valorPago: (json['valorPago'] as num?)?.toDouble() ?? 0.0,
      );

  static String encodeList(List<EmpresaModel> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<EmpresaModel> decodeList(String jsonStr) =>
      (jsonDecode(jsonStr) as List)
          .map((e) => EmpresaModel.fromJson(e))
          .toList();
}
