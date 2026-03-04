import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/transactions_provider.dart';
import '../../models/transaction_model.dart';
import '../detalhes_mes/detalhes_mes_screen.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _mesAbrev = DateFormat('MMM', 'pt_BR');

class PlanejamentoScreen extends ConsumerStatefulWidget {
  const PlanejamentoScreen({super.key});

  @override
  ConsumerState<PlanejamentoScreen> createState() => _PlanejamentoScreenState();
}

class _PlanejamentoScreenState extends ConsumerState<PlanejamentoScreen> {
  @override
  Widget build(BuildContext context) {
    final gastos = ref.watch(gastosMesProvider);
    final totalRendas = ref.watch(totalRendasProvider);
    final totalGastos = ref.watch(totalGastosProvider);
    final saldo = ref.watch(saldoProvider);

    final fixos = gastos.where((t) => t.tipo == TransactionType.fixo).fold<double>(0.0, (s, t) => s + t.valor);
    final parcelados = gastos.where((t) => t.tipo == TransactionType.parcelado).fold<double>(0.0, (s, t) => s + t.valor);
    final avulsos = gastos.where((t) => t.tipo == TransactionType.avulso).fold<double>(0.0, (s, t) => s + t.valor);

    final economia = totalRendas > 0 ? ((saldo / totalRendas) * 100).clamp(0.0, 100.0) : 0.0;
    final porcentagem = totalRendas > 0 ? (totalGastos / totalRendas).clamp(0.0, 1.0) : 0.0;

    // Lista dos parcelados do mês atual (para calcular parcelas futuras)
    final parceladosList = gastos.where((t) => t.tipo == TransactionType.parcelado).toList();

    // Para o mês futuro com offset `i` (1=próximo mês, 2=daqui a 2, etc.),
    // soma somente as parcelas que ainda não acabaram:
    // uma parcela ainda ativa em +i se: parcelaAtual + i <= totalParcelas
    double parceladosRestantesEm(int i) => parceladosList
        .where((t) => i <= ((t.totalParcelas ?? 0) - (t.parcelaAtual ?? 0)))
        .fold<double>(0.0, (s, t) => s + t.valor);

    // Projeção: mês atual (dados reais) + próximos 5 meses
    // Meses futuros = fixos + parcelas que ainda estarão ativas
    final now = DateTime.now();
    final projecaoMeses = List.generate(6, (i) => DateTime(now.year, now.month + i, 1));
    final projecaoGastos = List.generate(6, (i) {
      if (i == 0) return totalGastos; // mês atual: dados reais
      return fixos + parceladosRestantesEm(i);
    });
    final projecaoRendas = projecaoMeses.map((_) => totalRendas).toList();
    final maxY = [...projecaoGastos, ...projecaoRendas].fold<double>(0, (m, v) => v > m ? v : m);

    return Scaffold(
      appBar: AppBar(title: const Text('Planejamento')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Resumo geral
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Resumo do Mês',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 16),
                _ResumoRow('Total de Rendas', _brl.format(totalRendas), AppColors.income),
                const Divider(height: 20),
                _ResumoRow('Gastos Fixos', _brl.format(fixos), AppColors.primary),
                const SizedBox(height: 8),
                _ResumoRow('Parcelamentos', _brl.format(parcelados), AppColors.purple),
                const SizedBox(height: 8),
                _ResumoRow('Avulsos', _brl.format(avulsos), AppColors.pink),
                const Divider(height: 20),
                _ResumoRow('Total Gasto', _brl.format(totalGastos), AppColors.expense),
                const SizedBox(height: 8),
                _ResumoRow(
                  'Saldo Disponível',
                  _brl.format(saldo),
                  saldo >= 0 ? AppColors.income : Colors.red,
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Gráfico projeção próximos 6 meses
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Projeção — Próximos 6 Meses',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 4),
                const Text('Mês atual: dados reais  ·  Futuros: base nos gastos fixos',
                  style: TextStyle(fontSize: 11, color: AppColors.textGrey)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: maxY == 0
                    ? const Center(
                        child: Text(
                          'Adicione rendas e gastos para ver a projeção',
                          style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxY * 1.3,
                          barTouchData: BarTouchData(
                            touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
                              if (event is FlTapUpEvent && response?.spot != null) {
                                final i = response!.spot!.touchedBarGroupIndex;
                                if (i >= 0 && i < projecaoMeses.length) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DetalheMesScreen(
                                        mes: projecaoMeses[i],
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final label = rodIndex == 0 ? 'Entradas' : 'Saídas';
                                return BarTooltipItem(
                                  '$label\n${_brl.format(rod.toY)}',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  final i = v.toInt();
                                  if (i < 0 || i >= projecaoMeses.length) return const SizedBox();
                                  final isNow = i == 0;
                                  final label = _mesAbrev.format(projecaoMeses[i]);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      isNow ? '$label ●' : label,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isNow ? AppColors.primary : AppColors.textGrey,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => const FlLine(
                              color: AppColors.background,
                              strokeWidth: 1,
                            ),
                          ),
                          barGroups: List.generate(6, (i) => BarChartGroupData(
                            x: i,
                            barsSpace: 4,
                            barRods: [
                              BarChartRodData(
                                toY: projecaoRendas[i],
                                color: AppColors.income,
                                width: 13,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                              BarChartRodData(
                                toY: projecaoGastos[i],
                                color: AppColors.pink,
                                width: 13,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ],
                          )),
                        ),
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Legenda(cor: AppColors.income, label: 'Entradas'),
                    const SizedBox(width: 24),
                    _Legenda(cor: AppColors.pink, label: 'Saídas'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Taxa de economia
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Taxa de Economia',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${economia.toStringAsFixed(1)}% economizado',
                            style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800,
                              color: economia >= 20 ? AppColors.income : AppColors.expense,
                            )),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: porcentagem,
                              minHeight: 8,
                              backgroundColor: AppColors.background,
                              color: saldo >= 0 ? AppColors.primary : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            economia >= 20
                                ? '✅ Ótimo! Meta de 20% atingida'
                                : '⚠️ Meta: economizar pelo menos 20%',
                            style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: economia >= 20 ? AppColors.income : AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dica financeira
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getDica(economia, porcentagem),
                    style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.primary, height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _getDica(double economia, double porcentagem) {
    if (porcentagem > 0.9) return 'Atenção! Você está gastando quase toda sua renda. Tente reduzir os gastos avulsos.';
    if (economia >= 30) return 'Excelente! Você está economizando mais de 30%. Continue assim e considere investir o excedente.';
    if (economia >= 20) return 'Ótimo trabalho! Você atingiu a meta de 20% de economia.';
    if (porcentagem < 0.5) return 'Você tem saldo sobrando. Que tal definir uma meta de investimento mensal?';
    return 'Tente manter os gastos abaixo de 80% da sua renda para garantir uma reserva de emergência.';
  }
}

class _Legenda extends StatelessWidget {
  final Color cor;
  final String label;
  const _Legenda({required this.cor, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textGrey,
      )),
    ],
  );
}

class _ResumoRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool bold;
  const _ResumoRow(this.label, this.value, this.color, {this.bold = false});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(
        fontSize: bold ? 14 : 13,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        color: bold ? AppColors.textDark : AppColors.textGrey,
      )),
      Text(value, style: TextStyle(
        fontSize: bold ? 15 : 13,
        fontWeight: FontWeight.w800,
        color: color,
      )),
    ],
  );
}
