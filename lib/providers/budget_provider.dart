import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget_model.dart';
import '../core/firestore/budget_repository.dart';
import 'auth_provider.dart';
import 'transactions_provider.dart';

final budgetProvider = StreamProvider<Budget>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user == null
        ? Stream.value(Budget.empty)
        : ref.read(budgetRepositoryProvider).stream(),
    loading: () => Stream.value(Budget.empty),
    error: (_, __) => Stream.value(Budget.empty),
  );
});

final limiteGeralExcedidoProvider = Provider<bool>((ref) {
  final total = ref.watch(totalGastosProvider);
  final limite = ref.watch(budgetProvider).value?.limiteMensal;
  return limite != null && total > limite;
});

final limiteAlimentacaoExcedidoProvider = Provider<bool>((ref) {
  final total = ref.watch(alimentacaoMesProvider);
  final limite = ref.watch(budgetProvider).value?.limiteAlimentacao;
  return limite != null && total > limite;
});
