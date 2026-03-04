import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/transaction_model.dart';
import '../../providers/transactions_provider.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/add_transaction_sheet.dart';
import '../simulador/simulador_screen.dart';

class GastosScreen extends ConsumerWidget {
  const GastosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gastos = ref.watch(gastosMesProvider);
    final fixos = gastos.where((t) => t.tipo == TransactionType.fixo).toList();
    final parcelados = gastos.where((t) => t.tipo == TransactionType.parcelado).toList();
    final avulsos = gastos.where((t) => t.tipo == TransactionType.avulso).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos do Mês'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'Simulador',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SimuladorScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _GastoSection(
            title: '📌 Fixos',
            color: AppColors.primary,
            items: fixos,
            ref: ref,
            tipo: TransactionType.fixo,
          ),
          const SizedBox(height: 16),
          _GastoSection(
            title: '🔄 Parcelados',
            color: AppColors.purple,
            items: parcelados,
            ref: ref,
            tipo: TransactionType.parcelado,
          ),
          const SizedBox(height: 16),
          _GastoSection(
            title: '🧾 Avulsos',
            color: AppColors.pink,
            items: avulsos,
            ref: ref,
            tipo: TransactionType.avulso,
          ),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const AddTransactionSheet(tipoInicial: TransactionType.avulso),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _GastoSection extends StatelessWidget {
  final String title;
  final Color color;
  final List items;
  final WidgetRef ref;
  final TransactionType tipo;

  const _GastoSection({
    required this.title, required this.color,
    required this.items, required this.ref, required this.tipo,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.fold(0.0, (s, t) => s + t.valor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
            if (items.isNotEmpty)
              Text('R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Text('Nenhum gasto aqui ainda', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
              const Spacer(),
              GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context, isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => AddTransactionSheet(tipoInicial: tipo),
                ),
                child: Text('+ Adicionar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
              ),
            ]),
          )
        else
          ...items.map((t) => TransactionTile(
            transaction: t,
            onDelete: () => removeTransaction(ref, t.id),
            onEdit: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => AddTransactionSheet(transactionToEdit: t),
            ),
          )),
      ],
    );
  }
}
