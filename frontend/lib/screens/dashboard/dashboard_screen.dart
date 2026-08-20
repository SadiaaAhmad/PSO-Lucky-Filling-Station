import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/formatters.dart';
import 'package:frontend/core/widgets/state_views.dart';
import 'package:frontend/core/widgets/station_app_bar.dart';
import 'package:frontend/models/report.dart';
import 'package:frontend/models/tank_stock.dart';
import 'package:frontend/models/activity.dart';
import 'package:frontend/models/daily_log.dart';
import 'package:frontend/services/api_services.dart';
import 'package:frontend/core/utils/app_logger.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int tabIndex) onNavigateTab;
  const DashboardScreen({super.key, required this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _error;
  MonthlyPnLModel? _pnlData;
  DailySummaryModel? _dailyData;
  List<LatestTankStockModel> _tankStocks = [];
  List<ActivityItem> _activities = [];
  List<DailyLogModel> _dailyLogs = [];
  DailyLogModel? _selectedLog;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    AppLogger.data('[API] Loading dashboard data');

    try {
      try {
        _dailyLogs = await DailyLogApi.getDailyLogs(limit: 100);
        if (_dailyLogs.isNotEmpty) {
          if (_selectedLog == null || !_dailyLogs.any((l) => l.id == _selectedLog!.id)) {
            _selectedLog = _dailyLogs.first;
          } else {
            _selectedLog = _dailyLogs.firstWhere((l) => l.id == _selectedLog!.id);
          }
        }
      } catch (e) {
        AppLogger.warn('[WARN] Failed getDailyLogs: $e');
      }

      MonthlyPnLModel? pnl;
      try {
        pnl = await ReportApi.getLatestMonthlyPnL();
      } catch (e) {
        AppLogger.warn('[API] Failed getLatestMonthlyPnL: $e');
      }

      DailySummaryModel? daily;
      try {
        if (_selectedLog != null) {
          daily = await ReportApi.getDailySummary(_selectedLog!.logDate);
        } else {
          daily = await ReportApi.getLatestDailySummary();
        }
      } catch (e) {
        AppLogger.warn('[WARN] Failed getDailySummary: $e');
      }
      
      List<LatestTankStockModel> stocks = [];
      try {
        if (_selectedLog != null) {
          final detail = await DailyLogApi.getDailyLogDetail(_selectedLog!.id);
          stocks = detail.tankStocks.map((ts) => LatestTankStockModel(
            tankId: ts.tankId,
            tankName: ts.tankName,
            productCode: ts.productCode,
            capacityLiters: "25000.00",
            actualDipLiters: ts.actualDipLiters,
            purchaseRate: ts.purchaseRate,
            stockValuePkr: ((double.tryParse(ts.actualDipLiters) ?? 0.0) * (double.tryParse(ts.purchaseRate) ?? 0.0)).toStringAsFixed(2),
            logDate: detail.logDate,
          )).toList();
        } else {
          stocks = await StockApi.getLatestTankStocks();
        }
      } catch (e) {
        AppLogger.error('[ERROR] Failed to load tank stocks: $e');
        try {
          stocks = await StockApi.getLatestTankStocks();
        } catch (_) {}
      }
      
      List<ActivityItem> activities = [];
      try {
        activities = await ActivityApi.getRecentActivity(limit: 5);
      } catch (e) {
        AppLogger.error('[ERROR] Failed to load recent activity: $e');
      }

      setState(() {
        _pnlData = pnl;
        _dailyData = daily;
        _tankStocks = stocks;
        _activities = activities;
        _isLoading = false;
      });
      AppLogger.data('[DATA] Dashboard data loaded successfully');
    } catch (e) {
      AppLogger.error('[ERROR] Dashboard loading failed: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: StationAppBar(),
        body: LoadingView(message: 'Loading station dashboard...'),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: const StationAppBar(),
        body: ErrorStateView(
          errorMessage: _error!,
          onRetry: _loadDashboardData,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: const StationAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(14.0, 14.0, 14.0, MediaQuery.of(context).padding.bottom + 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Financial Cards Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'NET PROFIT',
                        value: Formatters.formatPKR(_pnlData?.netProfit),
                        subtitle: 'Income - Expenses',
                        color: AppTheme.emeraldGreen,
                        icon: Icons.trending_up_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'REVENUE',
                        value: Formatters.formatPKR(_pnlData?.totalIncome),
                        subtitle: 'Margin & Stock Profits',
                        color: AppTheme.navyPrimary,
                        icon: Icons.payments_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        title: 'EXPENSES',
                        value: Formatters.formatPKR(_pnlData?.totalExpenses),
                        subtitle: 'Operating Expenses',
                        color: AppTheme.coralRed,
                        icon: Icons.account_balance_wallet_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMetricCard(
                        title: 'TODAY DISPENSED',
                        value: Formatters.formatLiters(_dailyData?.totalGrossLitersDispensed ?? 0),
                        subtitle: 'Total Volume',
                        color: AppTheme.navyLight,
                        icon: Icons.local_gas_station_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
    
                // Quick Actions Section
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.1,
                  children: [
                    _buildQuickActionButton(
                      icon: Icons.playlist_add_rounded,
                      label: 'Daily Entry',
                      onTap: () => widget.onNavigateTab(1),
                    ),
                    _buildQuickActionButton(
                      icon: Icons.speed_rounded,
                      label: 'Nozzle Reading',
                      onTap: () => widget.onNavigateTab(2),
                    ),
                    _buildQuickActionButton(
                      icon: Icons.local_shipping_rounded,
                      label: 'Fuel Purchase',
                      onTap: () => widget.onNavigateTab(2),
                    ),
                    _buildQuickActionButton(
                      icon: Icons.straighten_rounded,
                      label: 'Tank Dip',
                      onTap: () => widget.onNavigateTab(2),
                    ),
                    _buildQuickActionButton(
                      icon: Icons.credit_card_rounded,
                      label: 'Credit Sale',
                      onTap: () => widget.onNavigateTab(3),
                    ),
                    _buildQuickActionButton(
                      icon: Icons.receipt_long_rounded,
                      label: 'Expense',
                      onTap: () => widget.onNavigateTab(4),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // View Reports Card
                InkWell(
                  onTap: () => Navigator.pushNamed(context, '/reports'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.navyPrimary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.navyPrimary.withOpacity(0.2)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart_rounded, color: AppTheme.navyPrimary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'View All Reports',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.navyPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
    
                // Fuel Overview Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Fuel Overview',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    if (_dailyLogs.isNotEmpty)
                      DropdownButtonHideUnderline(
                        child: DropdownButton<DailyLogModel>(
                          value: _dailyLogs.any((l) => l.id == _selectedLog?.id) ? _dailyLogs.firstWhere((l) => l.id == _selectedLog!.id) : _dailyLogs.first,
                          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.navyPrimary, size: 20),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary),
                          items: _dailyLogs.map((l) => DropdownMenuItem(
                            value: l,
                            child: Text(Formatters.formatDate(l.logDate)),
                          )).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() { _selectedLog = v; });
                              _loadDashboardData();
                            }
                          },
                        ),
                      )
                    else
                      const Icon(Icons.show_chart_rounded, color: AppTheme.textMuted, size: 18),
                  ],
                ),
                const SizedBox(height: 10),
                if (_tankStocks.isEmpty)
                  const Text('No tank stocks available.', style: TextStyle(color: AppTheme.textMuted)),
                ..._tankStocks.map((stock) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildFuelOverviewCard(stock),
                )),
                const SizedBox(height: 16),
                
                // Recent Activity Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pushNamed(context, '/activity'),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.navyPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_activities.isEmpty)
                  const Text('No recent activity.', style: TextStyle(color: AppTheme.textMuted)),
                ..._activities.map((activity) => _buildActivityItem(activity)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(ActivityItem activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Icon(Icons.history, color: AppTheme.navyLight, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                if (activity.subtitle.isNotEmpty)
                  Text(
                    activity.subtitle,
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            Formatters.formatDate(activity.timestamp),
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.navyPrimary, size: 22),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelOverviewCard(LatestTankStockModel stock) {
    final double actualDip = double.tryParse(stock.actualDipLiters) ?? 0.0;
    final double capacity = double.tryParse(stock.capacityLiters) ?? 0.0;
    final double fillPercent = capacity > 0 ? (actualDip / capacity) * 100 : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${stock.tankName} (${stock.productCode})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${stock.purchaseRate} PKR/L',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Stock: ${Formatters.formatLiters(stock.actualDipLiters)} / ${Formatters.formatLiters(stock.capacityLiters)}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${fillPercent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.emeraldGreen,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
