import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_config.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/screens/main_screen.dart';
import 'package:frontend/services/api_client.dart';

import 'package:frontend/screens/reports/reports_screen.dart';
import 'package:frontend/screens/activity/activity_screen.dart';
import 'package:frontend/screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.loadConfig();
  // Automatically scan & connect to active FastAPI backend on LAN
  await ApiClient.autoDiscoverBackend();
  runApp(const FuelStationApp());
}

class FuelStationApp extends StatelessWidget {
  const FuelStationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const MainScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/activity': (context) => const ActivityScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
