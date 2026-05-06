import 'dart:convert';

class AdiantamentoModel {
  final double valor;
  final DateTime data;
  final String identificacao;
  final String observacao;
  final int sitesPorLote;
  bool foiPago;
  DateTime? dataPagamento;
  double valorPago;
  bool encerrado;
  DateTime? dataEncerramento;
  int? sitesConcluidosNoEncerramento;

  AdiantamentoModel({
    required this.valor,
    required this.data,
    this.identificacao = '',
    this.observacao = '',
    this.sitesPorLote = 20,
    this.foiPago = false,
    this.dataPagamento,
    this.valorPago = 0.0,
    this.encerrado = false,
    this.dataEncerramento,
    this.sitesConcluidosNoEncerramento,
  });

  bool get encerradoParcial {
    if (!encerrado) return false;
    final concluidos = sitesConcluidosNoEncerramento ?? sitesPorLote;
    return concluidos < sitesPorLote;
  }

  DateTime? get previsaoRecebimento {
    if (dataEncerramento == null) return null;
    return dataEncerramento!.add(const Duration(days: 30));
  }

  Map<String, dynamic> toJson() => {
        'valor': valor,
        'data': data.toIso8601String(),
      'identificacao': identificacao,
        'observacao': observacao,
        'sitesPorLote': sitesPorLote,
        'foiPago': foiPago,
        'dataPagamento': dataPagamento?.toIso8601String(),
        'valorPago': valorPago,
      'encerrado': encerrado,
      'dataEncerramento': dataEncerramento?.toIso8601String(),
      'sitesConcluidosNoEncerramento': sitesConcluidosNoEncerramento,
      };

  factory AdiantamentoModel.fromJson(Map<String, dynamic> json) =>
      AdiantamentoModel(
        valor: (json['valor'] as num).toDouble(),
        data: DateTime.parse(json['data']),
        identificacao: json['identificacao'] ?? '',
        observacao: json['observacao'] ?? '',
        sitesPorLote: json['sitesPorLote'] ?? 20,
        foiPago: json['foiPago'] ?? false,
        dataPagamento: json['dataPagamento'] != null
            ? DateTime.parse(json['dataPagamento'])
            : null,
        valorPago: (json['valorPago'] as num?)?.toDouble() ?? 0.0,
        encerrado: json['encerrado'] ?? false,
        dataEncerramento: json['dataEncerramento'] != null
          ? DateTime.parse(json['dataEncerramento'])
          : null,
        sitesConcluidosNoEncerramento:
          (json['sitesConcluidosNoEncerramento'] as num?)?.toInt(),
      );

  static String encodeList(List<AdiantamentoModel> list) =>
      jsonEncode(list.map((a) => a.toJson()).toList());

  static List<AdiantamentoModel> decodeList(String jsonStr) =>
      (jsonDecode(jsonStr) as List)
          .map((e) => AdiantamentoModel.fromJson(e))
          .toList();
}
