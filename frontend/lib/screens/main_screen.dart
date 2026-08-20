import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/screens/dashboard/dashboard_screen.dart';
import 'package:frontend/screens/operations/daily_operations_screen.dart';
import 'package:frontend/screens/stock/stock_screen.dart';
import 'package:frontend/screens/accounts/accounts_screen.dart';
import 'package:frontend/screens/finance/finance_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(onNavigateTab: _onTabTapped),
      const DailyOperationsScreen(),
      const StockScreen(),
      const AccountsScreen(),
      const FinanceScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.navyPrimary,
        unselectedItemColor: AppTheme.textMuted,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_rounded),
            activeIcon: Icon(Icons.assignment_rounded),
            label: 'Operations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_rounded),
            activeIcon: Icon(Icons.inventory_2_rounded),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_rounded),
            activeIcon: Icon(Icons.people_rounded),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            activeIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Finance',
          ),
        ],
      ),
    );
  }
}
