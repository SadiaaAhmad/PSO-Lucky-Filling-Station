import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/station_app_bar.dart';
import 'package:frontend/screens/reports/monthly_pnl_screen.dart';
import 'package:frontend/screens/reports/daily_report_screen.dart';
import 'package:frontend/screens/reports/stock_report_screen.dart';
import 'package:frontend/screens/reports/udhaar_report_screen.dart';
import 'package:frontend/screens/activity/activity_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: const StationAppBar(subtitle: 'Financial Reports Hub', showBackButton: false),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _buildReportTile(
            context,
            title: 'Monthly Profit & Loss',
            subtitle: 'Revenue, expenses, net profit & ledger breakdown',
            icon: Icons.account_balance_rounded,
            badgeText: 'MONTHLY',
            onTap: () async {
              // Custom simple month/year picker logic or navigate with current month
              final now = DateTime.now();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MonthlyPnLScreen(year: now.year, month: now.month)),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildReportTile(
            context,
            title: 'Daily Operations Report',
            subtitle: 'Nozzle sales, stock, credit & cash summary',
            icon: Icons.receipt_long_rounded,
            badgeText: 'DAILY',
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DailyReportScreen(dateStr: dateStr)),
                );
              }
            },
          ),
          const SizedBox(height: 10),
          _buildReportTile(
            context,
            title: 'Fuel Stock Inventory Report',
            subtitle: 'Opening stock, purchases, sales, closing & gain/loss',
            icon: Icons.inventory_2_rounded,
            badgeText: 'STOCK',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const StockReportScreen()));
            },
          ),
          const SizedBox(height: 10),
          _buildReportTile(
            context,
            title: 'Customer Credit & Udhaar Report',
            subtitle: 'Outstanding receivables, credit limits & recoveries',
            icon: Icons.people_outline_rounded,
            badgeText: 'UDHAAR',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const UdhaarReportScreen()));
            },
          ),
          const SizedBox(height: 10),
          _buildReportTile(
            context,
            title: 'Activity History',
            subtitle: 'Detailed logs of all system operations',
            icon: Icons.history_rounded,
            badgeText: 'SYSTEM',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivityScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.navyPrimary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.navyPrimary, size: 20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(4)),
              child: Text(
                badgeText,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
        onTap: onTap,
      ),
    );
  }
}
