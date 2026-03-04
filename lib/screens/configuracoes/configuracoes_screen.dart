import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/firestore/budget_repository.dart';
import '../../models/budget_model.dart';
import '../../providers/budget_provider.dart';

class ConfiguracoesScreen extends ConsumerStatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  ConsumerState<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends ConsumerState<ConfiguracoesScreen> {
  final _geralCtrl = TextEditingController();
  final _alimentacaoCtrl = TextEditingController();
  bool _iniciado = false;
  bool _salvando = false;

  @override
  void dispose() {
    _geralCtrl.dispose();
    _alimentacaoCtrl.dispose();
    super.dispose();
  }

  void _preencherControllers(Budget budget) {
    if (!_iniciado) {
      _iniciado = true;
      _geralCtrl.text = budget.limiteMensal != null
          ? budget.limiteMensal!.toStringAsFixed(2).replaceAll('.', ',')
          : '';
      _alimentacaoCtrl.text = budget.limiteAlimentacao != null
          ? budget.limiteAlimentacao!.toStringAsFixed(2).replaceAll('.', ',')
          : '';
    }
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      final geralText = _geralCtrl.text.trim().replaceAll(',', '.');
      final alimentacaoText = _alimentacaoCtrl.text.trim().replaceAll(',', '.');

      final budget = Budget(
        limiteMensal: geralText.isEmpty ? null : double.tryParse(geralText),
        limiteAlimentacao:
            alimentacaoText.isEmpty ? null : double.tryParse(alimentacaoText),
      );

      // Fire-and-forget: salva no cache local imediatamente,
      // sincroniza com o servidor quando houver rede.
      ref.read(budgetRepositoryProvider).save(budget).catchError((_) {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Limites salvos!'),
            backgroundColor: AppColors.income,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetAsync = ref.watch(budgetProvider);
    budgetAsync.whenData(_preencherControllers);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'LIMITES MENSAIS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textGrey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _geralCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Limite geral de gastos',
                      prefixText: 'R\$ ',
                      hintText: 'Ex: 3000,00',
                    ),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: TextField(
                    controller: _alimentacaoCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Limite de Alimentação',
                      prefixText: 'R\$ ',
                      hintText: 'Ex: 500,00',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Deixe em branco para não definir limite.',
            style: TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _salvando ? null : _salvar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _salvando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Salvar',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
