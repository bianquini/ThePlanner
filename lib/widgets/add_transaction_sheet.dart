import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../models/transaction_model.dart';
import '../providers/transactions_provider.dart';
import '../providers/budget_provider.dart';

const _categories = [
  'Moradia', 'Alimentação', 'Transporte', 'Saúde',
  'Educação', 'Lazer', 'Roupas', 'Tecnologia',
  'Reserva de Emergência', 'Outros',
];
const _incomeCategories = [
  'Salário', 'Freelance', 'Investimentos',
  'Reserva de Emergência', 'Outros',
];

class AddTransactionSheet extends ConsumerStatefulWidget {
  final TransactionType? tipoInicial;
  final Transaction? transactionToEdit;

  const AddTransactionSheet({super.key, this.tipoInicial, this.transactionToEdit});

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _parcelasCtrl = TextEditingController(text: '2');

  TransactionType _tipo = TransactionType.avulso;
  String _categoria = _categories[0];
  bool _isRenda = false;

  bool get _isEditing => widget.transactionToEdit != null;

  @override
  void initState() {
    super.initState();
    final t = widget.transactionToEdit;
    if (t != null) {
      // Modo edição: pré-preencher todos os campos
      _isRenda = t.tipo == TransactionType.renda;
      _tipo = t.tipo;
      _tituloCtrl.text = t.titulo;
      _valorCtrl.text = t.valor.toStringAsFixed(2).replaceAll('.', ',');
      if (t.totalParcelas != null) _parcelasCtrl.text = t.totalParcelas.toString();
      _categoria = t.categoria;
    } else if (widget.tipoInicial != null) {
      _tipo = widget.tipoInicial!;
      _isRenda = _tipo == TransactionType.renda;
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _valorCtrl.dispose();
    _parcelasCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final valor = double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0;
    final tipo = _isRenda ? TransactionType.renda : _tipo;

    // Verificar limite apenas para novos gastos (não edição)
    if (!_isRenda && !_isEditing) {
      final budget = ref.read(budgetProvider).value;
      final totalAtual = ref.read(totalGastosProvider);
      final alimentacaoAtual = ref.read(alimentacaoMesProvider);

      String? aviso;
      if (budget?.limiteMensal != null &&
          totalAtual + valor > budget!.limiteMensal!) {
        aviso =
            'Este gasto vai ultrapassar seu limite mensal de ${_fmtLimite(budget.limiteMensal!)}.';
      } else if (budget?.limiteAlimentacao != null &&
          _categoria == 'Alimentação' &&
          alimentacaoAtual + valor > budget!.limiteAlimentacao!) {
        aviso =
            'Este gasto vai ultrapassar seu limite de Alimentação de ${_fmtLimite(budget.limiteAlimentacao!)}.';
      }

      if (aviso != null) {
        final confirmar = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('⚠️ Limite ultrapassado'),
            content: Text('$aviso\n\nDeseja continuar mesmo assim?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar',
                    style: TextStyle(color: AppColors.pink)),
              ),
            ],
          ),
        );
        if (confirmar != true) return;
      }
    }

    if (_isEditing) {
      // Atualizar transação existente
      final existing = widget.transactionToEdit!;
      final updated = existing.copyWith(
        titulo: _tituloCtrl.text.trim(),
        valor: valor,
        tipo: tipo,
        categoria: _categoria,
        totalParcelas: tipo == TransactionType.parcelado
            ? int.tryParse(_parcelasCtrl.text)
            : null,
        parcelaAtual: tipo == TransactionType.parcelado
            ? existing.parcelaAtual
            : null,
      );
      await updateTransaction(ref, updated);
    } else {
      // Criar nova transação
      addTransaction(
        ref,
        titulo: _tituloCtrl.text.trim(),
        valor: valor,
        tipo: tipo,
        categoria: _categoria,
        totalParcelas:
            _tipo == TransactionType.parcelado ? int.tryParse(_parcelasCtrl.text) : null,
        parcelaAtual: _tipo == TransactionType.parcelado ? 1 : null,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  String _fmtLimite(double v) =>
      'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

  @override
  Widget build(BuildContext context) {
    final cats = _isRenda ? _incomeCategories : _categories;
    if (!cats.contains(_categoria)) _categoria = cats[0];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isEditing ? 'Editar transação' : 'Nova transação',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Tipo toggle (Gasto / Renda)
            Row(
              children: [
                _TypeChip(label: 'Gasto', selected: !_isRenda, color: AppColors.pink,
                  onTap: () => setState(() { _isRenda = false; _tipo = TransactionType.avulso; })),
                const SizedBox(width: 8),
                _TypeChip(label: 'Renda', selected: _isRenda, color: AppColors.income,
                  onTap: () => setState(() { _isRenda = true; _tipo = TransactionType.renda; })),
              ],
            ),
            const SizedBox(height: 12),

            // Subtipo de gasto
            if (!_isRenda) ...[
              Row(
                children: [
                  _TypeChip(label: 'Avulso', selected: _tipo == TransactionType.avulso,
                    color: AppColors.primary,
                    onTap: () => setState(() => _tipo = TransactionType.avulso)),
                  const SizedBox(width: 8),
                  _TypeChip(label: 'Fixo', selected: _tipo == TransactionType.fixo,
                    color: AppColors.primary,
                    onTap: () => setState(() => _tipo = TransactionType.fixo)),
                  const SizedBox(width: 8),
                  _TypeChip(label: 'Parcelado', selected: _tipo == TransactionType.parcelado,
                    color: AppColors.primary,
                    onTap: () => setState(() => _tipo = TransactionType.parcelado)),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Título
            TextFormField(
              controller: _tituloCtrl,
              decoration: const InputDecoration(labelText: 'Descrição'),
              validator: (v) => v == null || v.isEmpty ? 'Informe a descrição' : null,
            ),
            const SizedBox(height: 10),

            // Valor
            TextFormField(
              controller: _valorCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor (R\$)', prefixText: 'R\$ '),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe o valor';
                if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Valor inválido';
                return null;
              },
            ),
            const SizedBox(height: 10),

            // Parcelas (só para parcelado)
            if (_tipo == TransactionType.parcelado) ...[
              TextFormField(
                controller: _parcelasCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Número de parcelas'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe o número de parcelas';
                  if (int.tryParse(v) == null || int.parse(v) < 2) return 'Mínimo 2 parcelas';
                  return null;
                },
              ),
              const SizedBox(height: 10),
            ],

            // Categoria
            DropdownButtonFormField<String>(
              value: _categoria,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _categoria = v!),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRenda ? AppColors.income : AppColors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _isEditing ? 'Salvar alterações' : 'Adicionar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _TypeChip({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.background,
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
}
