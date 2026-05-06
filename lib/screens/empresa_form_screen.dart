import 'package:flutter/material.dart';
import '../controllers/demanda_controller.dart';
import '../models/adiantamento_model.dart';
import '../models/empresa_model.dart';
import '../models/site_model.dart';
import '../theme/app_theme.dart';

class EmpresaFormScreen extends StatefulWidget {
  final DemandaController controller;
  final int? editIndex;

  const EmpresaFormScreen({
    super.key,
    required this.controller,
    this.editIndex,
  });

  @override
  State<EmpresaFormScreen> createState() => _EmpresaFormScreenState();
}

class _EmpresaFormScreenState extends State<EmpresaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeCtrl;
  late TextEditingController _valorSiteCtrl;
  late TextEditingController _percentualCtrl;
  late TextEditingController _sitesPorLoteCtrl;
  late TextEditingController _valorFixoCtrl;
  late TextEditingController _sitesCtrl;

  TipoAdiantamento _tipoAdiantamento = TipoAdiantamento.percentualPorLote;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.editIndex != null;

    if (_isEditing) {
      final emp = widget.controller.empresas[widget.editIndex!];
      _nomeCtrl = TextEditingController(text: emp.nome);
      _valorSiteCtrl =
          TextEditingController(text: emp.valorPorSite.toStringAsFixed(2));
      _percentualCtrl = TextEditingController(
          text: (emp.percentualAdiantamento * 100).toStringAsFixed(0));
      _sitesPorLoteCtrl =
          TextEditingController(text: emp.sitesPorLote.toString());
      _valorFixoCtrl = TextEditingController(
          text: emp.valorAdiantamentoFixo.toStringAsFixed(2));
      _tipoAdiantamento = emp.tipoAdiantamento;
      _sitesCtrl = TextEditingController(
          text: emp.sites.map((s) => s.siteId).join('\n'));
    } else {
      _nomeCtrl = TextEditingController();
      _valorSiteCtrl = TextEditingController(text: '600.00');
      _percentualCtrl = TextEditingController(text: '40');
      _sitesPorLoteCtrl = TextEditingController(text: '20');
      _valorFixoCtrl = TextEditingController(text: '0.00');
      _sitesCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _valorSiteCtrl.dispose();
    _percentualCtrl.dispose();
    _sitesPorLoteCtrl.dispose();
    _valorFixoCtrl.dispose();
    _sitesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Empresa' : 'Nova Empresa'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
      ),
      backgroundColor: AppTheme.surfaceColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.business,
                            color: AppTheme.primaryColor, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing
                                  ? 'Editar Empresa'
                                  : 'Cadastrar Nova Empresa',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Configure os dados do contrato',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Nome da empresa
              _buildSectionTitle('Dados da Empresa', Icons.info_outline),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nomeCtrl,
                decoration: _inputDecoration('Nome da Empresa', Icons.business),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _valorSiteCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    _inputDecoration('Valor por Site (R\$)', Icons.attach_money),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe o valor';
                  if (double.tryParse(v.replaceAll(',', '.')) == null) {
                    return 'Valor inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Tipo de adiantamento
              _buildSectionTitle(
                  'Configuração de Adiantamento', Icons.payments),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: RadioGroup<TipoAdiantamento>(
                    groupValue: _tipoAdiantamento,
                    onChanged: (v) =>
                        setState(() => _tipoAdiantamento = v!),
                    child: Column(
                      children: TipoAdiantamento.values.map((tipo) {
                        return RadioListTile<TipoAdiantamento>(
                          value: tipo,
                          title: Text(
                            _tipoLabel(tipo),
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 14),
                          ),
                          subtitle: Text(_tipoDescricao(tipo),
                              style: const TextStyle(fontSize: 12)),
                          activeColor: AppTheme.primaryColor,
                          dense: true,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Campos conforme tipo
              if (_tipoAdiantamento == TipoAdiantamento.percentualPorLote) ...[
                TextFormField(
                  controller: _percentualCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      _inputDecoration('Percentual (%)', Icons.percent),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _sitesPorLoteCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                      'Sites por Lote', Icons.format_list_numbered),
                ),
              ],
              if (_tipoAdiantamento == TipoAdiantamento.valorFixoSemanal ||
                  _tipoAdiantamento == TipoAdiantamento.valorFixoUnico) ...[
                TextFormField(
                  controller: _valorFixoCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration(
                      'Valor do Adiantamento (R\$)', Icons.money),
                ),
              ],
              const SizedBox(height: 24),

              // Sites
              _buildSectionTitle('Sites (IDs)', Icons.cell_tower),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Digite um Site ID por linha:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _sitesCtrl,
                        maxLines: 10,
                        decoration: InputDecoration(
                          hintText:
                              'BASDR_0001\nBASDR_0002\nBASDR_0003\n...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _contarSites(),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Botão salvar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _salvar,
                  icon: Icon(_isEditing ? Icons.save : Icons.add_business,
                      size: 22),
                  label: Text(
                    _isEditing ? 'SALVAR ALTERAÇÕES' : 'CADASTRAR EMPRESA',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String titulo, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withAlpha(50)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
    );
  }

  String _tipoLabel(TipoAdiantamento tipo) {
    switch (tipo) {
      case TipoAdiantamento.percentualPorLote:
        return 'Percentual por Lote';
      case TipoAdiantamento.valorFixoSemanal:
        return 'Valor Fixo Semanal';
      case TipoAdiantamento.valorFixoUnico:
        return 'Valor Fixo Único';
      case TipoAdiantamento.semAdiantamento:
        return 'Sem Adiantamento';
    }
  }

  String _tipoDescricao(TipoAdiantamento tipo) {
    switch (tipo) {
      case TipoAdiantamento.percentualPorLote:
        return 'Ex: Prencell - 40% a cada 20 sites concluídos';
      case TipoAdiantamento.valorFixoSemanal:
        return 'Acordo de valor fixo recebido por semana';
      case TipoAdiantamento.valorFixoUnico:
        return 'Um único valor de adiantamento para todo o contrato';
      case TipoAdiantamento.semAdiantamento:
        return 'Pagamento somente após conclusão dos sites';
    }
  }

  String _contarSites() {
    final linhas = _sitesCtrl.text
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    return '${linhas.length} sites informados';
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    final siteIds = _sitesCtrl.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    if (siteIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe pelo menos um Site ID'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final valorSite =
        double.parse(_valorSiteCtrl.text.replaceAll(',', '.'));
    final percentual =
        (double.tryParse(_percentualCtrl.text) ?? 40) / 100;
    final sitesPorLote =
        int.tryParse(_sitesPorLoteCtrl.text) ?? 20;
    final valorFixo =
        double.tryParse(_valorFixoCtrl.text.replaceAll(',', '.')) ?? 0;

    List<SiteModel> sites;
    List<AdiantamentoModel> adiantamentos;

    if (_isEditing) {
      final empExistente =
          widget.controller.empresas[widget.editIndex!];
      // Manter status existente de sites que já estavam
      final existingMap = {
        for (final s in empExistente.sites) s.siteId: s
      };
      sites = siteIds.map((id) {
        return existingMap[id] ?? SiteModel(siteId: id);
      }).toList();
      adiantamentos = empExistente.adiantamentos;
    } else {
      sites = siteIds.map((id) => SiteModel(siteId: id)).toList();
      adiantamentos = [];
    }

    final empresa = EmpresaModel(
      id: _isEditing
          ? widget.controller.empresas[widget.editIndex!].id
          : 'emp_${DateTime.now().millisecondsSinceEpoch}',
      nome: _nomeCtrl.text.trim(),
      valorPorSite: valorSite,
      sites: sites,
      adiantamentos: adiantamentos,
      tipoAdiantamento: _tipoAdiantamento,
      percentualAdiantamento: percentual,
      sitesPorLote: sitesPorLote,
      valorAdiantamentoFixo: valorFixo,
      foiPago: _isEditing
          ? widget.controller.empresas[widget.editIndex!].foiPago
          : false,
      dataPagamento: _isEditing
          ? widget.controller.empresas[widget.editIndex!].dataPagamento
          : null,
      valorPago: _isEditing
          ? widget.controller.empresas[widget.editIndex!].valorPago
          : 0.0,
    );

    if (_isEditing) {
      widget.controller.atualizarEmpresa(widget.editIndex!, empresa);
    } else {
      widget.controller.adicionarEmpresa(empresa);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing
            ? '✅ ${empresa.nome} atualizada!'
            : '✅ ${empresa.nome} cadastrada com ${sites.length} sites!'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
