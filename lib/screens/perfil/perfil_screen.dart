import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../configuracoes/configuracoes_screen.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card do usuário
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user?.displayName ?? 'Usuário',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card Configurações + Sobre
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.tune_rounded, color: AppColors.primary),
                  title: const Text('Configurações',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  subtitle: const Text('Limites de gastos',
                      style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textGrey),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ConfiguracoesScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.primary),
                  title: const Text('Versão',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  trailing: const Text('v1.0.0',
                      style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.code, color: AppColors.primary),
                  title: const Text('Tecnologia',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  subtitle: const Text('Flutter & Firebase',
                      style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Botão logout
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => ref.read(authServiceProvider).signOut(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Sair da conta',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
