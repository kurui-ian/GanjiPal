import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'presentation/providers/app_state.dart';
import 'presentation/screens/analytics_screen.dart';
import 'presentation/screens/budgets_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/transactions_screen.dart';

class GanjiPalApp extends StatelessWidget {
  final AppState appState;

  const GanjiPalApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'GanjiPal',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: appState.themeMode,
          home: SplashScreen(
            appState: appState,
            nextScreen: MainNavigationScaffold(appState: appState),
          ),
        );
      },
    );
  }
}

typedef PesaTrackApp = GanjiPalApp;

class MainNavigationScaffold extends StatefulWidget {
  final AppState appState;

  const MainNavigationScaffold({super.key, required this.appState});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        appState: widget.appState,
        onNavigateTab: (index) {
          setState(() => _currentIndex = index);
        },
      ),
      TransactionsScreen(appState: widget.appState),
      AnalyticsScreen(appState: widget.appState),
      BudgetsScreen(appState: widget.appState),
      SettingsScreen(appState: widget.appState),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: Icon(Icons.pie_chart_rounded),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings_rounded),
            label: 'Budgets',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
