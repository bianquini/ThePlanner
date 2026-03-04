import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/transaction_model.dart';
import '../../providers/transactions_provider.dart';
import '../../providers/budget_provider.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _mesFormat = DateFormat('MMM/yy', 'pt_BR');

const _categories = [
  'Moradia', 'Alimentação', 'Transporte', 'Saúde',
  'Educação', 'Lazer', 'Roupas', 'Tecnologia', 'Outros',
];

class _Linha {
  final DateTime mes;
  final double base;
  final double parcela;
  _Linha(this.mes, this.base, this.parcela);
  double get total => base + parcela;
}

class SimuladorScreen extends ConsumerStatefulWidget {
  const SimuladorScreen({super.key});

  @override
  ConsumerState<SimuladorScreen> createState() => _SimuladorScreenState();
}

class _SimuladorScreenState extends ConsumerState<SimuladorScreen> {
  final _valorCtrl = TextEditingController();
  final _parcelasCtrl = TextEditingController(text: '2');
  final _descCtrl = TextEditingController();
  TransactionType _tipo = TransactionType.avulso;
  String _categoria = _categories[0];

  List<_Linha>? _projecao;
  bool _confirmando = false;

  @override
  void dispose() {
    _valorCtrl.dispose();
    _parcelasCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _simular() {
    final valor = double.tryParse(_valorCtrl.text.replaceAll(',', '.'));
    if (valor == null || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um valor válido')),
      );
      return;
    }
    if (_tipo == TransactionType.parcelado) {
      final p = int.tryParse(_parcelasCtrl.text);
      if (p == null || p < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe pelo menos 2 parcelas')),
        );
        return;
      }
    }

    final gastos = ref.read(gastosMesProvider);
    final totalAtual = gastos.fold<double>(0.0, (s, t) => s + t.valor);
    final fixosBase = gastos
        .where((t) => t.tipo == TransactionType.fixo)
        .fold<double>(0.0, (s, t) => s + t.valor);

    final now = DateTime.now();
    final linhas = <_Linha>[];

    if (_tipo == TransactionType.avulso) {
      linhas.add(_Linha(now, totalAtual, valor));
    } else {
      final nParcelas = int.parse(_parcelasCtrl.text);
      for (int i = 0; i < nParcelas; i++) {
        final mes = DateTime(now.year, now.month + i, 1);
        final base = i == 0 ? totalAtual : fixosBase;
        linhas.add(_Linha(mes, base, valor));
      }
    }

    setState(() => _projecao = linhas);
  }

  Future<void> _confirmar() async {
    final valor = double.tryParse(_valorCtrl.text.replaceAll(',', '.'));
    if (valor == null) return;

    setState(() => _confirmando = true);
    await addTransaction(
      ref,
      titulo: _descCtrl.text.trim().isEmpty ? 'Simulado' : _descCtrl.text.trim(),
      valor: valor,
      tipo: _tipo,
      categoria: _categoria,
      totalParcelas: _tipo == TransactionType.parcelado
          ? int.tryParse(_parcelasCtrl.text)
          : null,
      parcelaAtual: _tipo == TransactionType.parcelado ? 1 : null,
    );
    setState(() => _confirmando = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final limite = ref.watch(budgetProvider).value?.limiteMensal;

    return Scaffold(
      appBar: AppBar(title: const Text('Simulador')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formulário
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nova conta',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
                  const SizedBox(height: 14),

                  // Tipo
                  Row(
                    children: [
                      _Chip(
                        label: 'Avulso',
                        selected: _tipo == TransactionType.avulso,
                        onTap: () => setState(() {
                          _tipo = TransactionType.avulso;
                          _projecao = null;
                        }),
                      ),
                      const SizedBox(width: 8),
                      _Chip(
                        label: 'Parcelado',
                        selected: _tipo == TransactionType.parcelado,
                        onTap: () => setState(() {
                          _tipo = TransactionType.parcelado;
                          _projecao = null;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _descCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Descrição (opcional)'),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _valorCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _tipo == TransactionType.parcelado
                          ? 'Valor por parcela (R\$)'
                          : 'Valor (R\$)',
                      prefixText: 'R\$ ',
                    ),
                    onChanged: (_) => setState(() => _projecao = null),
                  ),
                  const SizedBox(height: 10),

                  if (_tipo == TransactionType.parcelado) ...[
                    TextField(
                      controller: _parcelasCtrl,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Número de parcelas'),
                      onChanged: (_) => setState(() => _projecao = null),
                    ),
                    const SizedBox(height: 10),
                  ],

                  DropdownButtonFormField<String>(
                    value: _categoria,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: _categories
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _categoria = v!),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _simular,
                      icon: const Icon(Icons.calculate_outlined, size: 18),
                      label: const Text('Simular',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Projeção
            if (_projecao != null) ...[
              const SizedBox(height: 20),
              const Text('PROJEÇÃO',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textGrey,
                      letterSpacing: 1.2)),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Cabeçalho
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: const [
                          Expanded(
                              flex: 2,
                              child: Text('Mês',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textGrey))),
                          Expanded(
                              flex: 3,
                              child: Text('Base atual',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textGrey),
                                  textAlign: TextAlign.center)),
                          Expanded(
                              flex: 2,
                              child: Text('+ Novo',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textGrey),
                                  textAlign: TextAlign.center)),
                          Expanded(
                              flex: 3,
                              child: Text('Total',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textGrey),
                                  textAlign: TextAlign.right)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ..._projecao!.asMap().entries.map((e) {
                      final i = e.key;
                      final linha = e.value;
                      final excede =
                          limite != null && linha.total > limite;
                      final quase = limite != null &&
                          !excede &&
                          linha.total > limite * 0.8;
                      final cor = excede
                          ? Colors.red.shade50
                          : quase
                              ? Colors.orange.shade50
                              : Colors.green.shade50;
                      final textCor = excede
                          ? Colors.red.shade700
                          : quase
                              ? Colors.orange.shade700
                              : AppColors.income;

                      return Column(
                        children: [
                          if (i > 0) const Divider(height: 1),
                          Container(
                            color: cor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    _mesFormat.format(linha.mes),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    _brl.format(linha.base),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textGrey),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    _brl.format(linha.parcela),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.pink),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    _brl.format(linha.total),
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: textCor),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),

                    if (limite != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 14, color: AppColors.textGrey),
                            const SizedBox(width: 6),
                            Text(
                              'Limite mensal: ${_brl.format(limite)}',
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.textGrey),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.textGrey),
                      ),
                      child: const Text('Cancelar',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textGrey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _confirmando ? null : _confirmar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _confirmando
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Confirmar e Adicionar',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.purple : AppColors.background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textGrey,
            ),
          ),
        ),
      );
}
