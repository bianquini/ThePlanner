class Budget {
  final double? limiteMensal;
  final double? limiteAlimentacao;

  const Budget({this.limiteMensal, this.limiteAlimentacao});

  static const empty = Budget();

  Map<String, dynamic> toMap() => {
    'limiteMensal': limiteMensal,
    'limiteAlimentacao': limiteAlimentacao,
  };

  factory Budget.fromMap(Map<String, dynamic> m) => Budget(
    limiteMensal: (m['limiteMensal'] as num?)?.toDouble(),
    limiteAlimentacao: (m['limiteAlimentacao'] as num?)?.toDouble(),
  );
}
