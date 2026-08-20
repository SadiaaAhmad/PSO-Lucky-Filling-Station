import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/formatters.dart';
import 'package:frontend/core/widgets/state_views.dart';
import 'package:frontend/core/widgets/station_app_bar.dart';
import 'package:frontend/models/report.dart';
import 'package:frontend/services/api_services.dart';

class DailyReportScreen extends StatefulWidget {
  final String dateStr;
  const DailyReportScreen({super.key, required this.dateStr});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  bool _isLoading = true;
  String? _error;
  DailySummaryModel? _summary;
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.parse(widget.dateStr);
    _fetchDailySummary();
  }

  Future<void> _fetchDailySummary() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dateStr = '${_currentDate.year}-${_currentDate.month.toString().padLeft(2, '0')}-${_currentDate.day.toString().padLeft(2, '0')}';
      final summary = await ReportApi.getDailySummary(dateStr);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  void _changeDate(int days) {
    setState(() {
      _currentDate = _currentDate.add(Duration(days: days));
    });
    _fetchDailySummary();
  }
  
  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() { _currentDate = date; });
      _fetchDailySummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = '${_currentDate.year}-${_currentDate.month.toString().padLeft(2, '0')}-${_currentDate.day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: StationAppBar(
        title: 'Daily Operations Report',
        subtitle: dateStr,
        showBackButton: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeDate(-1)),
                InkWell(
                  onTap: _pickDate,
                  child: Text(Formatters.formatDate(dateStr), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navyPrimary)),
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeDate(1)),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
              ? const LoadingView(message: 'Generating daily report...')
              : _error != null
                  ? ErrorStateView(errorMessage: _error!, onRetry: _fetchDailySummary)
                  : _summary == null
                      ? EmptyStateView(
                          title: 'No Log Found',
                          message: 'No operational daily log was recorded on $dateStr.',
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('DAILY REPORT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                                    const SizedBox(height: 2),
                                    Text(Formatters.formatDate(_summary!.logDate), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppTheme.emeraldBg, borderRadius: BorderRadius.circular(4)),
                                  child: Text(_summary!.status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Fuel Sales Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Gross Liters Dispensed:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                    Text(Formatters.formatLiters(_summary!.totalGrossLitersDispensed), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
                                  ],
                                ),
                                const Divider(height: 18),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Nozzles Recorded:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                    Text('${_summary!.totalNozzlesRecorded} Active Nozzles', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text('Cash & Credit Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Credit Sales:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                    Text(Formatters.formatPKR(_summary!.totalCreditSalesPkr), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.amberWarning)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Credit Recoveries:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                    Text(Formatters.formatPKR(_summary!.totalCreditRecoveriesPkr), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('PSO Card Sales:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                    Text(Formatters.formatPKR(_summary!.totalCardSalesPkr), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
          )
        ],
      ),
    );
  }
}
