import 'dart:convert';

class RelatorioSiteItem {
  String siteId;
  bool feito;
  String motivo; // motivo se não foi feito
  DateTime? dataExecucao;

  RelatorioSiteItem({
    required this.siteId,
    this.feito = false,
    this.motivo = '',
    this.dataExecucao,
  });

  Map<String, dynamic> toJson() => {
        'siteId': siteId,
        'feito': feito,
        'motivo': motivo,
        'dataExecucao': dataExecucao?.toIso8601String(),
      };

  factory RelatorioSiteItem.fromJson(Map<String, dynamic> json) =>
      RelatorioSiteItem(
        siteId: json['siteId'],
        feito: json['feito'] ?? false,
        motivo: json['motivo'] ?? '',
        dataExecucao: json['dataExecucao'] != null
            ? DateTime.parse(json['dataExecucao'])
            : null,
      );
}

class RelatorioDiario {
  String id;
  DateTime data;
  String operadora;
  String projeto;
  String fabricante;
  String regiao;
  List<RelatorioSiteItem> sites;

  RelatorioDiario({
    required this.id,
    required this.data,
    this.operadora = '',
    this.projeto = '',
    this.fabricante = '',
    this.regiao = '',
    List<RelatorioSiteItem>? sites,
  }) : sites = sites ?? [];

  List<RelatorioSiteItem> get sitesFeitos =>
      sites.where((s) => s.feito).toList();

  List<RelatorioSiteItem> get sitesNaoFeitos =>
      sites.where((s) => !s.feito && s.motivo.isNotEmpty).toList();

  String gerarTextoWhatsApp() {
    final buffer = StringBuffer();
    buffer.writeln('📊 *RELATÓRIO DIÁRIO TSSR*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(
        '${_diaEmoji(data.day)} Data: ${_formatDate(data)}');
    if (operadora.isNotEmpty) {
      buffer.writeln('📡 Operadora: *$operadora*');
    }
    if (projeto.isNotEmpty) {
      buffer.writeln('📋 Projeto: *$projeto*');
    }
    if (fabricante.isNotEmpty) {
      buffer.writeln('🏭 Fabricante: *$fabricante*');
    }
    if (regiao.isNotEmpty) {
      buffer.writeln('📍 Região: *$regiao*');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('');

    final feitos = sitesFeitos
      ..sort((a, b) {
        if (a.dataExecucao == null && b.dataExecucao == null) return 0;
        if (a.dataExecucao == null) return 1;
        if (b.dataExecucao == null) return -1;
        return b.dataExecucao!.compareTo(a.dataExecucao!);
      });
    if (feitos.isNotEmpty) {
      buffer.writeln(
          '✅ *SITES CONCLUÍDOS (${feitos.length}):*');
      for (final s in feitos) {
        final dataStr = s.dataExecucao != null
            ? ' - ${_formatDate(s.dataExecucao!)}'
            : '';
        buffer.writeln('  ✅ ${s.siteId}$dataStr');
      }
      buffer.writeln('');
    }

    final naoFeitos = sitesNaoFeitos
      ..sort((a, b) {
        if (a.dataExecucao == null && b.dataExecucao == null) return 0;
        if (a.dataExecucao == null) return 1;
        if (b.dataExecucao == null) return -1;
        return b.dataExecucao!.compareTo(a.dataExecucao!);
      });
    if (naoFeitos.isNotEmpty) {
      buffer.writeln(
          '❌ *SITES COM PROBLEMA (${naoFeitos.length}):*');
      for (final s in naoFeitos) {
        final dataStr = s.dataExecucao != null
            ? ' - ${_formatDate(s.dataExecucao!)}'
            : '';
        buffer.writeln('  ❌ ${s.siteId}$dataStr');
        if (s.motivo.isNotEmpty) {
          buffer.writeln('     📝 Motivo: ${s.motivo}');
        }
      }
      buffer.writeln('');
    }

    final pendentes =
        sites.where((s) => !s.feito && s.motivo.isEmpty).length;
    if (pendentes > 0) {
      buffer.writeln('⏳ Sites a Vistoriar: $pendentes');
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln(
        '📋 *RESUMO:* ${sites.length} Sites | ✅ ${feitos.length} | ❌ ${naoFeitos.length} | ⏳ $pendentes');
    buffer.writeln('');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('⚡ *DEMANDA CONTROLLER*  ·  v1.0');
    buffer.writeln('🔧 VJC Technology — Soluções em Telecom');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return buffer.toString();
  }

  static const _keycaps = ['0️⃣','1️⃣','2️⃣','3️⃣','4️⃣','5️⃣','6️⃣','7️⃣','8️⃣','9️⃣'];

  String _diaEmoji(int dia) {
    final str = dia.toString().padLeft(2, '0');
    return '${_keycaps[int.parse(str[0])]}${_keycaps[int.parse(str[1])]}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'data': data.toIso8601String(),
        'operadora': operadora,
        'projeto': projeto,
        'fabricante': fabricante,
        'regiao': regiao,
        'sites': sites.map((s) => s.toJson()).toList(),
      };

  factory RelatorioDiario.fromJson(Map<String, dynamic> json) =>
      RelatorioDiario(
        id: json['id'],
        data: DateTime.parse(json['data']),
        operadora: json['operadora'] ?? '',
        projeto: json['projeto'] ?? '',
        fabricante: json['fabricante'] ?? '',
        regiao: json['regiao'] ?? '',
        sites: (json['sites'] as List)
            .map((s) => RelatorioSiteItem.fromJson(s))
            .toList(),
      );

  static String encodeList(List<RelatorioDiario> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<RelatorioDiario> decodeList(String jsonStr) =>
      (jsonDecode(jsonStr) as List)
          .map((e) => RelatorioDiario.fromJson(e))
          .toList();
}

class RelatorioConfig {
  List<String> operadoras;
  List<String> fabricantes;
  List<String> projetos;

  RelatorioConfig({
    List<String>? operadoras,
    List<String>? fabricantes,
    List<String>? projetos,
  })  : operadoras = operadoras ?? ['Vivo', 'Tim', 'Claro'],
        fabricantes = fabricantes ?? ['Huawei', 'Ericsson', 'Nokia'],
        projetos = projetos ?? ['TSSR'];

  Map<String, dynamic> toJson() => {
        'operadoras': operadoras,
        'fabricantes': fabricantes,
        'projetos': projetos,
      };

  factory RelatorioConfig.fromJson(Map<String, dynamic> json) =>
      RelatorioConfig(
        operadoras: (json['operadoras'] as List?)
            ?.map((e) => e.toString())
            .toList(),
        fabricantes: (json['fabricantes'] as List?)
            ?.map((e) => e.toString())
            .toList(),
        projetos:
            (json['projetos'] as List?)?.map((e) => e.toString()).toList(),
      );

  String encode() => jsonEncode(toJson());

  static RelatorioConfig decode(String jsonStr) =>
      RelatorioConfig.fromJson(jsonDecode(jsonStr));
}
