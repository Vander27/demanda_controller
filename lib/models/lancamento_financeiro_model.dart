import 'dart:convert';

enum TipoLancamentoFinanceiro {
  adiantamentoDescontavel,
  ajudaCustoNaoDescontavel,
  ajudaCustoDescontavel,
  pagamentoFinal,
  ajuste,
}

class LancamentoFinanceiroModel {
  final String id;
  final TipoLancamentoFinanceiro tipo;
  final double valor;
  final DateTime data;
  final String descricao;
  final bool descontaNoFinal;
  final String referencia;
  bool recebido;
  DateTime? dataRecebimento;
  final String? grupoParcelaId;
  final int? parcelaNumero;
  final int? parcelasTotal;

  LancamentoFinanceiroModel({
    required this.id,
    required this.tipo,
    required this.valor,
    required this.data,
    this.descricao = '',
    this.descontaNoFinal = false,
    this.referencia = '',
    this.recebido = true,
    this.dataRecebimento,
    this.grupoParcelaId,
    this.parcelaNumero,
    this.parcelasTotal,
  });

  bool get eParcela =>
      grupoParcelaId != null &&
      grupoParcelaId!.isNotEmpty &&
      parcelaNumero != null &&
      parcelasTotal != null;

  bool get previsto => !recebido;

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipo': tipo.index,
        'valor': valor,
        'data': data.toIso8601String(),
        'descricao': descricao,
        'descontaNoFinal': descontaNoFinal,
        'referencia': referencia,
        'recebido': recebido,
        'dataRecebimento': dataRecebimento?.toIso8601String(),
        'grupoParcelaId': grupoParcelaId,
        'parcelaNumero': parcelaNumero,
        'parcelasTotal': parcelasTotal,
      };

  factory LancamentoFinanceiroModel.fromJson(Map<String, dynamic> json) {
    final tipoIndex = (json['tipo'] as num?)?.toInt() ?? 0;
    final tipoSeguro =
        tipoIndex >= 0 && tipoIndex < TipoLancamentoFinanceiro.values.length
            ? TipoLancamentoFinanceiro.values[tipoIndex]
            : TipoLancamentoFinanceiro.ajuste;

    return LancamentoFinanceiroModel(
      id: json['id'] ?? '',
      tipo: tipoSeguro,
      valor: (json['valor'] as num).toDouble(),
      data: DateTime.parse(json['data']),
      descricao: json['descricao'] ?? '',
      descontaNoFinal: json['descontaNoFinal'] ?? false,
      referencia: json['referencia'] ?? '',
        recebido: json['recebido'] ?? true,
        dataRecebimento: json['dataRecebimento'] != null
          ? DateTime.parse(json['dataRecebimento'])
          : null,
      grupoParcelaId: json['grupoParcelaId'],
      parcelaNumero: (json['parcelaNumero'] as num?)?.toInt(),
      parcelasTotal: (json['parcelasTotal'] as num?)?.toInt(),
    );
  }

  static String encodeList(List<LancamentoFinanceiroModel> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<LancamentoFinanceiroModel> decodeList(String jsonStr) =>
      (jsonDecode(jsonStr) as List)
          .map((e) => LancamentoFinanceiroModel.fromJson(e))
          .toList();
}
