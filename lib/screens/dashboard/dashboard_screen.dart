import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/transaction_model.dart';
import '../../providers/transactions_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/add_transaction_sheet.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _mes = DateFormat('MMMM yyyy', 'pt_BR');

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gastos = ref.watch(gastosMesProvider);
    final rendas = ref.watch(rendasMesProvider);
    final totalGastos = ref.watch(totalGastosProvider);
    final totalRendas = ref.watch(totalRendasProvider);
    final saldo = ref.watch(saldoProvider);
    final porcentagem = totalRendas > 0 ? (totalGastos / totalRendas).clamp(0.0, 1.0) : 0.0;

    final fixos = gastos.where((t) => t.tipo == TransactionType.fixo).fold(0.0, (s, t) => s + t.valor);
    final parcelados = gastos.where((t) => t.tipo == TransactionType.parcelado).fold(0.0, (s, t) => s + t.valor);
    final avulsos = gastos.where((t) => t.tipo == TransactionType.avulso).fold(0.0, (s, t) => s + t.valor);
    final limiteGeralExcedido = ref.watch(limiteGeralExcedidoProvider);
    final limiteAlimExcedido = ref.watch(limiteAlimentacaoExcedidoProvider);
    final nomeUsuario = ref.watch(authStateProvider).value?.displayName?.split(' ').first ?? 'você';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header azul
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.primary,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Bom dia,',
                              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                            Text('$nomeUsuario 👋',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _mes.format(DateTime.now()),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(_brl.format(saldo),
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: porcentagem,
                      backgroundColor: Colors.white24,
                      color: saldo < 0 ? Colors.red[300] : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(height: 4),
                    Text('${(porcentagem * 100).toStringAsFixed(0)}% do orçamento utilizado',
                      style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mini cards
                  Row(
                    children: [
                      _MiniCard(
                        label: 'Entradas', emoji: '📈',
                        value: _brl.format(totalRendas),
                        color: AppColors.cyan, valueColor: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      _MiniCard(
                        label: 'Gastos', emoji: '📉',
                        value: _brl.format(totalGastos),
                        color: AppColors.pink.withOpacity(0.15), valueColor: AppColors.pink,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Banner de limite excedido
                  if (limiteGeralExcedido)
                    _LimiteWarning(mensagem: '⚠️ Limite mensal de gastos ultrapassado!'),
                  if (limiteAlimExcedido)
                    _LimiteWarning(mensagem: '⚠️ Limite de Alimentação ultrapassado!'),
                  if (limiteGeralExcedido || limiteAlimExcedido)
                    const SizedBox(height: 16),

                  // Gráfico de barras
                  if (totalGastos > 0) ...[
                    _SectionTitle('Distribuição de Gastos'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 120,
                            child: BarChart(BarChartData(
                              barTouchData: BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) {
                                      const labels = ['Fixos', 'Parcelas', 'Avulsos'];
                                      return Text(labels[v.toInt()],
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textGrey));
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: false),
                              barGroups: [
                                _bar(0, fixos, AppColors.primary),
                                _bar(1, parcelados, AppColors.pink),
                                _bar(2, avulsos, AppColors.cyan),
                              ],
                            )),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Transações recentes
                  _SectionTitle('Transações do Mês'),
                  const SizedBox(height: 8),

                  if (gastos.isEmpty && rendas.isEmpty)
                    _EmptyState()
                  else
                    ...[ ...rendas, ...gastos].take(10).map((t) =>
                      TransactionTile(
                        transaction: t,
                        onDelete: () => removeTransaction(ref, t.id),
                        onEdit: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => AddTransactionSheet(transactionToEdit: t),
                        ),
                      ),
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const AddTransactionSheet(),
        ),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  BarChartGroupData _bar(int x, double y, Color color) => BarChartGroupData(
    x: x,
    barRods: [BarChartRodData(
      toY: y, color: color, width: 36,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
    )],
  );
}

class _MiniCard extends StatelessWidget {
  final String label, emoji, value;
  final Color color, valueColor;
  const _MiniCard({required this.label, required this.emoji, required this.value, required this.color, required this.valueColor});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              color: AppColors.textGrey, letterSpacing: 0.5)),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: valueColor)),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark));
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: const Center(
      child: Column(children: [
        Text('💸', style: TextStyle(fontSize: 48)),
        SizedBox(height: 12),
        Text('Nenhuma transação ainda', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textGrey)),
        Text('Toque no + para adicionar', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
      ]),
    ),
  );
}

class _LimiteWarning extends StatelessWidget {
  final String mensagem;
  const _LimiteWarning({required this.mensagem});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      children: [
        Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            mensagem,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.red.shade700,
            ),
          ),
        ),
      ],
    ),
  );
}
