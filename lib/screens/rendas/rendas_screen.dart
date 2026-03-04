import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/transaction_model.dart';
import '../../providers/transactions_provider.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/add_transaction_sheet.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

class RendasScreen extends ConsumerWidget {
  const RendasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rendas = ref.watch(rendasMesProvider);
    final total = ref.watch(totalRendasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rendas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card total
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.income, Color(0xFF27AE60)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total de Entradas',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(_brl.format(total),
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('${rendas.length} fonte(s) de renda',
                  style: const TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (rendas.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: const Column(children: [
                Text('💰', style: TextStyle(fontSize: 40)),
                SizedBox(height: 10),
                Text('Nenhuma renda cadastrada', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textGrey)),
                Text('Toque no + para adicionar', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
              ]),
            )
          else
            ...rendas.map((t) => TransactionTile(
              transaction: t,
              onDelete: () => removeTransaction(ref, t.id),
              onEdit: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddTransactionSheet(transactionToEdit: t),
              ),
            )),

          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.income,
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const AddTransactionSheet(tipoInicial: TransactionType.renda),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
