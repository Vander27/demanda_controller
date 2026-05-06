import 'dart:convert';

import 'empresa_model.dart';
import 'relatorio_model.dart';

class DemandaGeralModel {
  String id;
  String nome;
  DateTime dataConclusao;
    String responsavelFechamento;
    String observacaoFechamento;
  List<EmpresaModel> empresas;
  List<RelatorioDiario> relatorios;

  DemandaGeralModel({
    required this.id,
    required this.nome,
    required this.dataConclusao,
        this.responsavelFechamento = '',
        this.observacaoFechamento = '',
    List<EmpresaModel>? empresas,
    List<RelatorioDiario>? relatorios,
  })  : empresas = empresas ?? [],
        relatorios = relatorios ?? [];

  int get totalSites => empresas.fold(0, (sum, e) => sum + e.totalSites);
  int get sitesConcluidos =>
      empresas.fold(0, (sum, e) => sum + e.sitesConcluidos);
    bool get todasEmpresasPagas =>
            empresas.isNotEmpty && empresas.every((e) => e.foiPago);

    String get statusProfissional {
        if (todasEmpresasPagas) return 'Paga';
        if (totalSites > 0 && sitesConcluidos >= totalSites) return 'Concluída';
        if (sitesConcluidos > 0) return 'Parcial';
        return 'Em aberto';
    }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'dataConclusao': dataConclusao.toIso8601String(),
                'responsavelFechamento': responsavelFechamento,
                'observacaoFechamento': observacaoFechamento,
        'empresas': empresas.map((e) => e.toJson()).toList(),
        'relatorios': relatorios.map((r) => r.toJson()).toList(),
      };

  factory DemandaGeralModel.fromJson(Map<String, dynamic> json) =>
      DemandaGeralModel(
        id: json['id'],
        nome: json['nome'] ?? '',
        dataConclusao: DateTime.parse(json['dataConclusao']),
        responsavelFechamento: json['responsavelFechamento'] ?? '',
        observacaoFechamento: json['observacaoFechamento'] ?? '',
        empresas: (json['empresas'] as List? ?? [])
            .map((e) => EmpresaModel.fromJson(e))
            .toList(),
        relatorios: (json['relatorios'] as List? ?? [])
            .map((r) => RelatorioDiario.fromJson(r))
            .toList(),
      );

  static String encodeList(List<DemandaGeralModel> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<DemandaGeralModel> decodeList(String jsonStr) =>
      (jsonDecode(jsonStr) as List)
          .map((e) => DemandaGeralModel.fromJson(e))
          .toList();
}
