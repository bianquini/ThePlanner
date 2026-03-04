import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/gastos/gastos_screen.dart';
import 'screens/rendas/rendas_screen.dart';
import 'screens/planejamento/planejamento_screen.dart';
import 'screens/perfil/perfil_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await initializeDateFormatting('pt_BR', null);
  runApp(const ProviderScope(child: ThePlannerApp()));
}

class ThePlannerApp extends StatelessWidget {
  const ThePlannerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ThePlanner',
    theme: AppTheme.theme,
    debugShowCheckedModeBanner: false,
    home: const AuthGate(),
  );
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) => user != null ? const MainNavigation() : const LoginScreen(),
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, __) => const LoginScreen(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  final _screens = const [
    DashboardScreen(),
    GastosScreen(),
    RendasScreen(),
    PlanejamentoScreen(),
    PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: _index, children: _screens),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _index,
      onTap: (i) => setState(() => _index = i),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Início'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Gastos'),
        BottomNavigationBarItem(icon: Icon(Icons.trending_up_rounded), label: 'Rendas'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Planos'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Perfil'),
      ],
    ),
  );
}
