import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/budget_model.dart';
import '../../providers/auth_provider.dart';

class BudgetRepository {
  final String uid;

  BudgetRepository(this.uid);

  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.doc('users/$uid/config/budgets');

  Stream<Budget> stream() => _doc.snapshots().map(
        (snap) => snap.exists ? Budget.fromMap(snap.data()!) : Budget.empty,
      );

  Future<void> save(Budget b) => _doc.set(b.toMap());
}

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) throw Exception('Não autenticado');
  return BudgetRepository(user.uid);
});
