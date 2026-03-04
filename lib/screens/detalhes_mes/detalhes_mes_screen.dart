import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/transaction_model.dart';
import '../../providers/transactions_provider.dart';

final _brl = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
final _mesNomeFmt = DateFormat('MMMM yyyy', 'pt_BR');
final _mesAbrevFmt = DateFormat('MMM', 'pt_BR');

const _categoryIcons = <String, String>{
  'Moradia': '🏠', 'Alimentação': '🛒', 'Transporte': '🚗',
  'Saúde': '💊', 'Educação': '📚', 'Lazer': '🎮',
  'Roupas': '👕', 'Tecnologia': '📱', 'Outros': '📦',
  'Salário': '💰', 'Freelance': '💻', 'Investimentos': '📈',
  'Reserva de Emergência': '🏦',
};

class DetalheMesScreen extends ConsumerStatefulWidget {
  final DateTime mes;
  const DetalheMesScreen({super.key, required this.mes});

  @override
  ConsumerState<DetalheMesScreen> createState() => _DetalheMesScreenState();
}

class _DetalheMesScreenState extends ConsumerState<DetalheMesScreen> {
  late DateTime _mes;

  @override
  void initState() {
    super.initState();
    _mes = DateTime(widget.mes.year, widget.mes.month, 1);
  }

  void _mudarMes(int delta) => setState(() {
    _mes = DateTime(_mes.year, _mes.month + delta, 1);
  });

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final mesAtual = DateTime(now.year, now.month, 1);
    final isAtual = _mes.year == mesAtual.year && _mes.month == mesAtual.month;
    final isFuturo = _mes.isAfter(mesAtual);
    final mesOffset =
        (_mes.year - mesAtual.year) * 12 + (_mes.month - mesAtual.month);

    // ── Dados reais do mês selecionado ──────────────────────────────────────
    final gastosReais = ref.watch(gastosMesDetalhadoProvider(_mes));
    final rendasReais = ref.watch(rendasMesDetalhadoProvider(_mes));

    // ── Dados do mês atual (para projeções futuras) ──────────────────────────
    final gastosMesAtual = ref.watch(gastosMesProvider);
    final fixosMesAtual =
        gastosMesAtual.where((t) => t.tipo == TransactionType.fixo).toList();
    final parceladosMesAtual =
        gastosMesAtual.where((t) => t.tipo == TransactionType.parcelado).toList();
    final totalRendasAtual = ref.watch(totalRendasProvider);

    // ── Para meses futuros: calcular quais parcelados ainda estão ativos ─────
    final parceladosAtivosNesteMes = isFuturo
        ? parceladosMesAtual
            .where((t) =>
                mesOffset <= ((t.totalParcelas ?? 0) - (t.parcelaAtual ?? 0)))
            .toList()
        : gastosReais
            .where((t) => t.tipo == TransactionType.parcelado)
            .toList();

    // ── Lista de gastos efetiva ──────────────────────────────────────────────
    final gastos = isFuturo
        ? [...fixosMesAtual, ...parceladosAtivosNesteMes]
        : gastosReais;

    final totalGastos = gastos.fold<double>(0.0, (s, t) => s + t.valor);
    final totalRendas =
        isFuturo ? totalRendasAtual : rendasReais.fold<double>(0.0, (s, t) => s + t.valor);
    final saldo = totalRendas - totalGastos;

    // ── Breakdown por tipo ───────────────────────────────────────────────────
    final fixos = gastos
        .where((t) => t.tipo == TransactionType.fixo)
        .fold<double>(0.0, (s, t) => s + t.valor);
    final parcelados = gastos
        .where((t) => t.tipo == TransactionType.parcelado)
        .fold<double>(0.0, (s, t) => s + t.valor);
    final avulsos = gastos
        .where((t) => t.tipo == TransactionType.avulso)
        .fold<double>(0.0, (s, t) => s + t.valor);

    // ── Breakdown por categoria ──────────────────────────────────────────────
    final Map<String, double> porCategoria = {};
    for (final t in gastos) {
      porCategoria[t.categoria] = (porCategoria[t.categoria] ?? 0) + t.valor;
    }
    final cats = porCategoria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // ── Badge ────────────────────────────────────────────────────────────────
    final String badgeLabel;
    final Color badgeColor;
    if (isAtual) {
      badgeLabel = 'Atual';
      badgeColor = AppColors.primary;
    } else if (isFuturo) {
      badgeLabel = 'Projeção';
      badgeColor = AppColors.pink;
    } else {
      badgeLabel = 'Histórico';
      badgeColor = AppColors.textGrey;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Mês'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _mudarMes(-1),
            tooltip: 'Mês anterior',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _mudarMes(1),
            tooltip: 'Próximo mês',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Cabeçalho do mês ──────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _capitalize(_mesNomeFmt.format(_mes)),
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                      letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Aviso de projeção ─────────────────────────────────────────────
          if (isFuturo) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.pink.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.pink.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Text('🔮', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Valores estimados com base nos gastos fixos e parcelas ativas',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pink),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Cards resumo ──────────────────────────────────────────────────
          Row(
            children: [
              _ResumoCard(
                  emoji: '📈',
                  label: 'Entradas',
                  valor: totalRendas,
                  corValor: AppColors.income),
              const SizedBox(width: 8),
              _ResumoCard(
                  emoji: '📉',
                  label: 'Gastos',
                  valor: totalGastos,
                  corValor: AppColors.expense,
                  prefixo: isFuturo ? '~' : ''),
              const SizedBox(width: 8),
              _ResumoCard(
                emoji: '💰',
                label: 'Saldo',
                valor: saldo,
                corValor:
                    saldo >= 0 ? AppColors.income : AppColors.expense,
                prefixo: isFuturo
                    ? '~'
                    : (saldo >= 0 ? '+' : ''),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Breakdown por tipo ────────────────────────────────────────────
          const _SectionTitle('Tipo de Gasto'),
          const SizedBox(height: 8),
          Row(
            children: [
              _TipoChip(label: 'Fixos', valor: fixos, cor: AppColors.primary),
              const SizedBox(width: 8),
              _TipoChip(
                  label: 'Parcelas', valor: parcelados, cor: AppColors.purple),
              const SizedBox(width: 8),
              _TipoChip(
                  label: 'Avulsos',
                  valor: avulsos,
                  cor: AppColors.pink,
                  inativo: isFuturo),
            ],
          ),
          const SizedBox(height: 16),

          // ── Por categoria ─────────────────────────────────────────────────
          if (cats.isNotEmpty) ...[
            const _SectionTitle('Por Categoria'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  // Donut centralizado
                  SizedBox(
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sections: cats.asMap().entries.map((e) {
                              final color = AppColors.categoryColors[
                                  e.key % AppColors.categoryColors.length];
                              return PieChartSectionData(
                                value: e.value.value,
                                color: color,
                                radius: 44,
                                showTitle: false,
                              );
                            }).toList(),
                            centerSpaceRadius: 38,
                            sectionsSpace: 2,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'R\$${_fmtCompacto(totalGastos)}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark),
                            ),
                            const Text('total',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textGrey,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, thickness: 1, color: AppColors.background),
                  const SizedBox(height: 16),
                  // Lista detalhada
                  ...cats.asMap().entries.map((e) {
                    final color = AppColors.categoryColors[
                        e.key % AppColors.categoryColors.length];
                    final emoji = _categoryIcons[e.value.key] ?? '📦';
                    final pct =
                        totalGastos > 0 ? e.value.value / totalGastos : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10)),
                            child: Center(
                                child: Text(emoji,
                                    style: const TextStyle(fontSize: 16))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.value.key,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textDark)),
                                    Text(_brl.format(e.value.value),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textDark)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: pct,
                                    minHeight: 5,
                                    backgroundColor: AppColors.background,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Parcelas do mês ───────────────────────────────────────────────
          if (parceladosAtivosNesteMes.isNotEmpty ||
              (!isFuturo &&
                  gastosReais
                      .any((t) => t.tipo == TransactionType.parcelado))) ...[
            _SectionTitle(
              isFuturo
                  ? 'Parcelas Ativas em ${_mesAbrevFmt.format(_mes)}'
                  : 'Parcelas do Mês',
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: parceladosAtivosNesteMes.asMap().entries.map((e) {
                  final idx = e.key;
                  final t = e.value;
                  final total = t.totalParcelas ?? 1;
                  final parcelaNum = isFuturo
                      ? ((t.parcelaAtual ?? 0) + mesOffset).clamp(0, total)
                      : (t.parcelaAtual ?? 0);
                  final progress =
                      total > 0 ? (parcelaNum / total).clamp(0.0, 1.0) : 0.0;
                  final emoji = _categoryIcons[t.categoria] ?? '📦';
                  final isLast = idx == parceladosAtivosNesteMes.length - 1;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10)),
                            child: Center(
                                child: Text(emoji,
                                    style: const TextStyle(fontSize: 18))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(t.titulo,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textDark),
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '- ${_brl.format(t.valor)}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.expense),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 6,
                                          backgroundColor: AppColors.background,
                                          valueColor: AlwaysStoppedAnimation(
                                            progress >= 1.0
                                                ? AppColors.income
                                                : AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$parcelaNum/$total',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textGrey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!isLast) const Divider(height: 16),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Estado vazio ──────────────────────────────────────────────────
          if (gastos.isEmpty && rendasReais.isEmpty && !isFuturo)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
              child: const Column(
                children: [
                  Text('📭', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 10),
                  Text('Sem transações neste mês',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textGrey)),
                ],
              ),
            ),

          // ── Rodapé de projeção ────────────────────────────────────────────
          if (isFuturo)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'ℹ️ Gastos avulsos não são projetados',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textGrey),
                ),
              ),
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  static String _fmtCompacto(double v) {
    final abs = v.abs();
    if (abs >= 1000) return '${(abs / 1000).toStringAsFixed(1)}k';
    return abs.toStringAsFixed(0);
  }
}

// ════════════════════════════════ Sub-widgets ════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textGrey,
            letterSpacing: 0.8),
      );
}

class _ResumoCard extends StatelessWidget {
  final String emoji, label, prefixo;
  final double valor;
  final Color corValor;

  const _ResumoCard({
    required this.emoji,
    required this.label,
    required this.valor,
    required this.corValor,
    this.prefixo = '',
  });

  static String _fmt(double v) {
    final abs = v.abs();
    if (abs >= 1000) return 'R\$${(abs / 1000).toStringAsFixed(1)}k';
    return 'R\$${abs.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textGrey,
                      letterSpacing: 0.3)),
              const SizedBox(height: 2),
              Text(
                '$prefixo${_fmt(valor)}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: corValor),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
}

class _TipoChip extends StatelessWidget {
  final String label;
  final double valor;
  final Color cor;
  final bool inativo;

  const _TipoChip({
    required this.label,
    required this.valor,
    required this.cor,
    this.inativo = false,
  });

  static String _fmt(double v) {
    if (v >= 1000) return 'R\$${(v / 1000).toStringAsFixed(1)}k';
    return 'R\$${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: inativo ? AppColors.textGrey : cor,
                    shape: BoxShape.circle),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textGrey)),
              const SizedBox(height: 2),
              Text(
                inativo ? '—' : _fmt(valor),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: inativo ? AppColors.textGrey : AppColors.textDark),
              ),
            ],
          ),
        ),
      );
}
