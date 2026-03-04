import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { fixo, parcelado, avulso, renda }

class Transaction {
  final String id;
  final String titulo;
  final double valor;
  final TransactionType tipo;
  final String categoria;
  final DateTime data;
  final int? totalParcelas;
  final int? parcelaAtual;

  Transaction({
    required this.id,
    required this.titulo,
    required this.valor,
    required this.tipo,
    required this.categoria,
    required this.data,
    this.totalParcelas,
    this.parcelaAtual,
  });

  bool get isGasto => tipo != TransactionType.renda;

  Transaction copyWith({
    String? titulo,
    double? valor,
    TransactionType? tipo,
    String? categoria,
    int? totalParcelas,
    int? parcelaAtual,
  }) => Transaction(
    id: id,
    titulo: titulo ?? this.titulo,
    valor: valor ?? this.valor,
    tipo: tipo ?? this.tipo,
    categoria: categoria ?? this.categoria,
    data: data,
    totalParcelas: totalParcelas ?? this.totalParcelas,
    parcelaAtual: parcelaAtual ?? this.parcelaAtual,
  );

  String get tipoLabel {
    switch (tipo) {
      case TransactionType.fixo: return 'Fixo';
      case TransactionType.parcelado: return '$parcelaAtual/$totalParcelas';
      case TransactionType.avulso: return 'Avulso';
      case TransactionType.renda: return 'Renda';
    }
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'titulo': titulo,
    'valor': valor,
    'tipo': tipo.name,
    'categoria': categoria,
    'data': Timestamp.fromDate(data),
    'totalParcelas': totalParcelas,
    'parcelaAtual': parcelaAtual,
  };

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: map['id'] as String,
      titulo: map['titulo'] as String,
      valor: (map['valor'] as num).toDouble(),
      tipo: TransactionType.values.firstWhere((e) => e.name == map['tipo']),
      categoria: map['categoria'] as String,
      data: (map['data'] as Timestamp).toDate(),
      totalParcelas: map['totalParcelas'] as int?,
      parcelaAtual: map['parcelaAtual'] as int?,
    );
  }
}
