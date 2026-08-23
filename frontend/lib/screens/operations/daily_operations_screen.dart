import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/formatters.dart';
import 'package:frontend/core/widgets/state_views.dart';
import 'package:frontend/core/widgets/station_app_bar.dart';
import 'package:frontend/models/daily_log.dart';
import 'package:frontend/models/report.dart';
import 'package:frontend/services/api_services.dart';
import 'package:frontend/screens/operations/daily_log_detail_screen.dart';
import 'package:frontend/core/utils/app_logger.dart';

class DailyOperationsScreen extends StatefulWidget {
  const DailyOperationsScreen({super.key});

  @override
  State<DailyOperationsScreen> createState() => _DailyOperationsScreenState();
}

class _DailyOperationsScreenState extends State<DailyOperationsScreen> {
  bool _isLoading = true;
  String? _error;
  List<DailyLogModel> _logs = [];
  bool _hasTodayLog = false;

  @override
  void initState() {
    super.initState();
    _fetchDailyLogs();
  }

  Future<void> _fetchDailyLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    AppLogger.api('[API] Fetching daily logs');

    try {
      final list = await DailyLogApi.getDailyLogs(limit: 100);
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      final hasToday = list.any((log) => log.logDate.startsWith(todayStr));
      
      // Sort today's log to the top if present
      list.sort((a, b) => b.logDate.compareTo(a.logDate));
      
      setState(() {
        _logs = list;
        _hasTodayLog = hasToday;
        _isLoading = false;
      });
      AppLogger.data('[DATA] Daily logs fetched successfully. Has today: $_hasTodayLog');
    } catch (e) {
      AppLogger.error('[ERROR] Failed to fetch daily logs: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewLog() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.navyPrimary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    final dateStr = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
    final messenger = ScaffoldMessenger.of(context);
    try {
      AppLogger.api('[API] Creating new daily log for $dateStr');
      final newLog = await DailyLogApi.createDailyLog(dateStr, notes: "Daily shift log");
      messenger.showSnackBar(
        SnackBar(
          content: Text("Daily Log #${newLog.id} created for $dateStr"),
          backgroundColor: AppTheme.emeraldGreen,
        ),
      );
      await _fetchDailyLogs();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DailyLogDetailScreen(log: newLog)),
        ).then((_) => _fetchDailyLogs());
      }
    } catch (e) {
      AppLogger.error('[ERROR] Failed to create daily log: $e');
      // If it already exists, find and open it
      final existing = _logs.where((l) => l.logDate.startsWith(dateStr)).toList();
      if (existing.isNotEmpty && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DailyLogDetailScreen(log: existing.first)),
        ).then((_) => _fetchDailyLogs());
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.coralRed,
          ),
        );
      }
    }
  }

  void _continueTodayLog() {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final todayLog = _logs.firstWhere((log) => log.logDate.startsWith(todayStr));
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DailyLogDetailScreen(log: todayLog),
      ),
    ).then((_) => _fetchDailyLogs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: StationAppBar(
        subtitle: 'Daily Operations Log',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.navyPrimary, size: 20),
            onPressed: _fetchDailyLogs,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _hasTodayLog ? _continueTodayLog : _createNewLog,
        backgroundColor: AppTheme.navyPrimary,
        icon: Icon(_hasTodayLog ? Icons.arrow_forward_rounded : Icons.add_rounded, color: Colors.white),
        label: Text(_hasTodayLog ? "Continue Today's Log" : 'New Daily Log', style: const TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const LoadingView(message: 'Loading daily operational logs...')
            : _error != null
                ? ErrorStateView(errorMessage: _error!, onRetry: _fetchDailyLogs)
                : _logs.isEmpty
                    ? const EmptyStateView(
                        title: 'No Daily Logs Found',
                        message: 'Tap + New Daily Log to start a shift record.',
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchDailyLogs,
                        child: ListView.builder(
                          padding: EdgeInsets.fromLTRB(14, 14, 14, MediaQuery.of(context).padding.bottom + 88),
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            final log = _logs[index];
                            final now = DateTime.now();
                            final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
                            final isToday = log.logDate.startsWith(todayStr);
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isToday)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 8.0),
                                    child: Text(
                                      "Today's Active Log",
                                      style: TextStyle(
                                        color: AppTheme.navyPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                DailyLogSummaryCard(
                                  log: log, 
                                  onRefreshNeeded: _fetchDailyLogs,
                                  isHighlighted: isToday,
                                ),
                                if (isToday) const SizedBox(height: 10),
                              ],
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}

class DailyLogSummaryCard extends StatefulWidget {
  final DailyLogModel log;
  final VoidCallback onRefreshNeeded;
  final bool isHighlighted;

  const DailyLogSummaryCard({
    super.key,
    required this.log,
    required this.onRefreshNeeded,
    this.isHighlighted = false,
  });

  @override
  State<DailyLogSummaryCard> createState() => _DailyLogSummaryCardState();
}

class _DailyLogSummaryCardState extends State<DailyLogSummaryCard> {
  DailySummaryModel? _summary;
  bool _loadingSummary = false;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    if (_loadingSummary) return;
    setState(() => _loadingSummary = true);
    try {
      final summary = await ReportApi.getDailySummary(widget.log.logDate);
      if (mounted) {
        setState(() {
          _summary = summary;
          _loadingSummary = false;
        });
      }
    } catch (e) {
      AppLogger.warn('[WARN] Failed to load summary for log ${widget.log.id}: $e');
      if (mounted) {
        setState(() => _loadingSummary = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClosed = widget.log.status == 'CLOSED';
    final statusColor = isClosed ? AppTheme.emeraldGreen : AppTheme.amberWarning;
    final statusBg = isClosed ? AppTheme.emeraldBg : AppTheme.amberBg;

    final grossLiters = _summary != null ? Formatters.formatLiters(_summary!.totalGrossLitersDispensed) : '-- L';
    final creditSales = _summary != null ? Formatters.formatPKR(_summary!.totalCreditSalesPkr) : 'PKR 0.00';
    final recoveries = _summary != null ? Formatters.formatPKR(_summary!.totalCreditRecoveriesPkr) : 'PKR 0.00';
    final cardSales = _summary != null ? Formatters.formatPKR(_summary!.totalCardSalesPkr) : 'PKR 0.00';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isHighlighted ? AppTheme.emeraldGreen.withValues(alpha: 0.6) : AppTheme.borderLight,
          width: widget.isHighlighted ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isHighlighted 
                ? AppTheme.emeraldGreen.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: widget.isHighlighted ? 10 : 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isClosed ? Icons.lock_outline_rounded : Icons.edit_note_rounded,
                      size: 18,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Formatters.formatDate(widget.log.logDate),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.log.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dynamic Figures from API
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _buildLogStat('GROSS DISPENSED', grossLiters, AppTheme.navyPrimary)),
                    Expanded(child: _buildLogStat('CREDIT SALES', creditSales, AppTheme.amberWarning)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _buildLogStat('CREDIT RECOVERIES', recoveries, AppTheme.emeraldGreen)),
                    Expanded(child: _buildLogStat('PSO CARD SALES', cardSales, AppTheme.navyLight)),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DailyLogDetailScreen(log: widget.log),
                        ),
                      ).then((_) => widget.onRefreshNeeded());
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View Log Details / Entries'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
