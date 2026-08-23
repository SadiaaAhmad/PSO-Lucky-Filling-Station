import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/station_app_bar.dart';
import 'package:frontend/core/widgets/state_views.dart';
import 'package:frontend/core/utils/formatters.dart';
import 'package:frontend/models/daily_log.dart';
import 'package:frontend/models/daily_log_detail.dart';
import 'package:frontend/models/master.dart';
import 'package:frontend/services/api_services.dart';

class StockReportScreen extends StatefulWidget {
  const StockReportScreen({super.key});

  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends State<StockReportScreen> {
  bool _isLoading = true;
  String? _error;
  List<DailyLogModel> _logs = [];
  DailyLogModel? _selectedLog;
  DailyLogDetailModel? _detail;
  List<TankModel> _tanks = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final logs = await DailyLogApi.getDailyLogs(limit: 100);
      _logs = logs;
      try {
        _tanks = await MasterApi.getTanks();
      } catch (_) {}

      if (_logs.isNotEmpty) {
        _selectedLog = _logs.first;
        await _fetchStockForLog(_selectedLog!);
      } else {
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchStockForLog(DailyLogModel log) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await DailyLogApi.getDailyLogDetail(log.id);
      if (mounted) {
        setState(() {
          _selectedLog = log;
          _detail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalValuation = 0.0;
    if (_detail != null) {
      for (var ts in _detail!.tankStocks) {
        final dip = double.tryParse(ts.actualDipLiters) ?? 0.0;
        final rate = double.tryParse(ts.purchaseRate) ?? 0.0;
        totalValuation += (dip * rate);
      }
    }

    if (_logs.isEmpty && !_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.bgLight,
        appBar: const StationAppBar(
          title: 'Fuel Stock Inventory Report',
          showBackButton: true,
        ),
        body: EmptyStateView(
          title: 'No Stock Dip Records Found',
          message: 'Create a Daily Shift Log in Operations to record tank dip readings and fuel stock valuation.',
          onRetry: _fetchInitialData,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: const StationAppBar(
        title: 'Fuel Stock Inventory Report',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Date Selector Banner
            if (_logs.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.white,
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.navyPrimary),
                    const SizedBox(width: 10),
                    const Text('Select Date:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<DailyLogModel>(
                          value: _logs.any((l) => l.id == _selectedLog?.id) ? _logs.firstWhere((l) => l.id == _selectedLog!.id) : _logs.first,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: AppTheme.navyPrimary),
                          items: _logs.map((l) => DropdownMenuItem(
                            value: l,
                            child: Text(
                              '${Formatters.formatDate(l.logDate)} (${l.status})',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )).toList(),
                          onChanged: (v) {
                            if (v != null) _fetchStockForLog(v);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1),

            Expanded(
              child: _isLoading
                  ? const LoadingView(message: 'Loading stock report...')
                  : _error != null
                      ? ErrorStateView(errorMessage: _error!, onRetry: _fetchInitialData)
                      : _detail == null || _detail!.tankStocks.isEmpty
                          ? const EmptyStateView(message: 'No stock dip records found for selected date.')
                          : RefreshIndicator(
                              onRefresh: () => _fetchStockForLog(_selectedLog!),
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  children: [
                                    ..._detail!.tankStocks.map((stock) {
                                      final dip = double.tryParse(stock.actualDipLiters) ?? 0.0;
                                      final rate = double.tryParse(stock.purchaseRate) ?? 0.0;
                                      final stockVal = dip * rate;

                                      // Match tank capacity
                                      final matchingTank = _tanks.where((t) => t.id == stock.tankId).firstOrNull;
                                      final capacity = matchingTank != null ? (double.tryParse(matchingTank.capacityLiters) ?? 25000.0) : 25000.0;
                                      final pct = capacity > 0 ? (dip / capacity).clamp(0.0, 1.0) : 0.0;

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(14),
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
                                                    '${stock.tankName} - ${stock.productCode}',
                                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  'Rate: ${stock.purchaseRate} PKR',
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            LinearProgressIndicator(value: pct, backgroundColor: AppTheme.bgLight, color: AppTheme.navyPrimary, minHeight: 8),
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(child: _stat('Opening Dip', '${stock.openingDipLiters} L')),
                                                Expanded(child: _stat('Actual Dip', Formatters.formatLiters(stock.actualDipLiters))),
                                                Expanded(child: _stat('Fill %', '${(pct * 100).toStringAsFixed(1)}%')),
                                                Expanded(child: _stat('Stock Value', Formatters.formatPKR(stockVal))),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppTheme.borderLight),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('NET INVENTORY VALUATION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                                          const SizedBox(height: 4),
                                          Text(Formatters.formatPKR(totalValuation), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textMuted), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDark), overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
