import 'dart:convert';

class DemandaEventoModel {
  String id;
  String demandaId;
  String acao;
  String descricao;
  DateTime dataHora;

  DemandaEventoModel({
    required this.id,
    required this.demandaId,
    required this.acao,
    required this.descricao,
    required this.dataHora,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'demandaId': demandaId,
        'acao': acao,
        'descricao': descricao,
        'dataHora': dataHora.toIso8601String(),
      };

  factory DemandaEventoModel.fromJson(Map<String, dynamic> json) =>
      DemandaEventoModel(
        id: json['id'],
        demandaId: json['demandaId'] ?? '',
        acao: json['acao'] ?? '',
        descricao: json['descricao'] ?? '',
        dataHora: DateTime.parse(json['dataHora']),
      );

  static String encodeList(List<DemandaEventoModel> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<DemandaEventoModel> decodeList(String jsonStr) =>
      (jsonDecode(jsonStr) as List)
          .map((e) => DemandaEventoModel.fromJson(e))
          .toList();
}
