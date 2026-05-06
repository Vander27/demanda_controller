import 'dart:convert';

enum SiteStatus { pendente, concluido, naoConcluido }

class SiteModel {
  final String siteId;
  SiteStatus status;
  String motivoNaoConcluido;
  DateTime? dataConclusao;
  bool participaAdiantamento;

  SiteModel({
    required this.siteId,
    this.status = SiteStatus.pendente,
    this.motivoNaoConcluido = '',
    this.dataConclusao,
    this.participaAdiantamento = true,
  });

  static const double valorPorSite = 600.0;

  bool get isConcluido => status == SiteStatus.concluido;
  bool get isNaoConcluido => status == SiteStatus.naoConcluido;
  bool get isPendente => status == SiteStatus.pendente;

  Map<String, dynamic> toJson() => {
        'siteId': siteId,
        'status': status.index,
        'motivoNaoConcluido': motivoNaoConcluido,
        'dataConclusao': dataConclusao?.toIso8601String(),
        'participaAdiantamento': participaAdiantamento,
      };

  factory SiteModel.fromJson(Map<String, dynamic> json) => SiteModel(
        siteId: json['siteId'],
        status: SiteStatus.values[json['status']],
        motivoNaoConcluido: json['motivoNaoConcluido'] ?? '',
        dataConclusao: json['dataConclusao'] != null
            ? DateTime.parse(json['dataConclusao'])
            : null,
        participaAdiantamento: json['participaAdiantamento'] ?? true,
      );

  static String encodeList(List<SiteModel> sites) =>
      jsonEncode(sites.map((s) => s.toJson()).toList());

  static List<SiteModel> decodeList(String jsonStr) =>
      (jsonDecode(jsonStr) as List)
          .map((e) => SiteModel.fromJson(e))
          .toList();
}
