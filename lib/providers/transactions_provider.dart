import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction_model.dart';
import '../core/firestore/transaction_repository.dart';
import 'auth_provider.dart';

const _uuid = Uuid();

// Stream principal — escuta mudanças em tempo real no Firestore
final transactionsStreamProvider = StreamProvider<List<Transaction>>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return FirebaseFirestore.instance
          .collection('users/${user.uid}/transactions')
          .orderBy('data', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map(Transaction.fromFirestore).toList());
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Helpers de escrita
Future<void> addTransaction(
  WidgetRef ref, {
  required String titulo,
  required double valor,
  required TransactionType tipo,
  required String categoria,
  int? totalParcelas,
  int? parcelaAtual,
}) {
  final t = Transaction(
    id: _uuid.v4(),
    titulo: titulo,
    valor: valor,
    tipo: tipo,
    categoria: categoria,
    data: DateTime.now(),
    totalParcelas: totalParcelas,
    parcelaAtual: parcelaAtual,
  );
  return ref.read(transactionRepositoryProvider).add(t);
}

Future<void> removeTransaction(WidgetRef ref, String id) =>
    ref.read(transactionRepositoryProvider).remove(id);

Future<void> updateTransaction(WidgetRef ref, Transaction updated) =>
    ref.read(transactionRepositoryProvider).add(updated);

// Derivados — filtrados por qualquer mês (family)
final gastosMesDetalhadoProvider =
    Provider.family<List<Transaction>, DateTime>((ref, mes) {
  final all = ref.watch(transactionsStreamProvider).value ?? [];
  return all
      .where((t) =>
          t.isGasto &&
          t.data.month == mes.month &&
          t.data.year == mes.year)
      .toList();
});

final rendasMesDetalhadoProvider =
    Provider.family<List<Transaction>, DateTime>((ref, mes) {
  final all = ref.watch(transactionsStreamProvider).value ?? [];
  return all
      .where((t) =>
          !t.isGasto &&
          t.data.month == mes.month &&
          t.data.year == mes.year)
      .toList();
});

// Derivados — filtrados por mês atual
final gastosMesProvider = Provider<List<Transaction>>((ref) {
  final now = DateTime.now();
  final all = ref.watch(transactionsStreamProvider).value ?? [];
  return all.where((t) =>
    t.isGasto && t.data.month == now.month && t.data.year == now.year
  ).toList();
});

final rendasMesProvider = Provider<List<Transaction>>((ref) {
  final now = DateTime.now();
  final all = ref.watch(transactionsStreamProvider).value ?? [];
  return all.where((t) =>
    !t.isGasto && t.data.month == now.month && t.data.year == now.year
  ).toList();
});

final alimentacaoMesProvider = Provider<double>((ref) {
  final gastos = ref.watch(gastosMesProvider);
  return gastos
      .where((t) => t.categoria == 'Alimentação')
      .fold<double>(0.0, (s, t) => s + t.valor);
});

final totalGastosProvider = Provider<double>((ref) =>
    ref.watch(gastosMesProvider).fold(0.0, (s, t) => s + t.valor));

final totalRendasProvider = Provider<double>((ref) =>
    ref.watch(rendasMesProvider).fold(0.0, (s, t) => s + t.valor));

final saldoProvider = Provider<double>((ref) =>
    ref.watch(totalRendasProvider) - ref.watch(totalGastosProvider));
