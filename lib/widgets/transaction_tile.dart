import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../core/theme/app_theme.dart';
import '../models/transaction_model.dart';

const _categoryIcons = <String, String>{
  'Moradia': '🏠', 'Alimentação': '🛒', 'Transporte': '🚗',
  'Saúde': '💊', 'Educação': '📚', 'Lazer': '🎮',
  'Roupas': '👕', 'Tecnologia': '📱', 'Outros': '📦',
  'Salário': '💰', 'Freelance': '💻', 'Investimentos': '📈',
  'Reserva de Emergência': '🏦',
};

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isRenda = !transaction.isGasto;
    final emoji = _categoryIcons[transaction.categoria] ?? '📦';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Slidable(
          key: ValueKey(transaction.id),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.44,
            children: [
              SlidableAction(
                onPressed: (_) => onEdit?.call(),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                icon: Icons.edit_outlined,
                label: 'Editar',
              ),
              SlidableAction(
                onPressed: (_) => onDelete?.call(),
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                icon: Icons.delete_outline,
                label: 'Excluir',
              ),
            ],
          ),
          child: Container(
            color: Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isRenda
                      ? AppColors.income.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20))),
              ),
              title: Text(
                transaction.titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
              subtitle: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      transaction.tipoLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                ],
              ),
              trailing: Text(
                '${isRenda ? '+' : '-'} R\$ ${transaction.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: isRenda ? AppColors.income : AppColors.expense,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
