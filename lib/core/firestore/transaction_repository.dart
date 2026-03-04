import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';

class TransactionRepository {
  final String uid;

  TransactionRepository(this.uid);

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('users/$uid/transactions');

  Future<void> add(Transaction t) => _col.doc(t.id).set(t.toMap());

  Future<void> update(Transaction t) => _col.doc(t.id).set(t.toMap());

  Future<void> remove(String id) => _col.doc(id).delete();
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) throw Exception('Usuário não autenticado');
  return TransactionRepository(user.uid);
});
