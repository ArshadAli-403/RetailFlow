import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/product_provider.dart';
import 'providers/billing_provider.dart';
import 'providers/history_provider.dart';
import 'providers/reports_provider.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const PosApp());
}

/// Root widget. Wires up all app-wide providers (Product, Billing,
/// History) via MultiProvider so any screen in the tree can access
/// them with context.watch/read without manual prop-drilling.
class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => BillingProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
      ],
      child: MaterialApp(
        title: 'Offline POS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const DashboardScreen(),
      ),
    );
  }
}