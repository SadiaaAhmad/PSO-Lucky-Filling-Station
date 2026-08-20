import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/formatters.dart';
import 'package:frontend/core/widgets/state_views.dart';
import 'package:frontend/core/widgets/station_app_bar.dart';
import 'package:frontend/models/report.dart';
import 'package:frontend/services/api_services.dart';
import 'package:path_provider/path_provider.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class MonthlyPnLScreen extends StatefulWidget {
  final int year;
  final int month;

  const MonthlyPnLScreen({
    super.key,
    required this.year,
    required this.month,
  });

  @override
  State<MonthlyPnLScreen> createState() => _MonthlyPnLScreenState();
}

class _MonthlyPnLScreenState extends State<MonthlyPnLScreen> {
  bool _isLoading = true;
  String? _error;
  MonthlyPnLModel? _pnl;
  
  late int _currentYear;
  late int _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentYear = widget.year;
    _currentMonth = widget.month;
    _fetchPnLData();
  }

  Future<void> _fetchPnLData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pnl = await ReportApi.getMonthlyPnL(_currentYear, _currentMonth);
      setState(() {
        _pnl = pnl;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth += offset;
      if (_currentMonth > 12) {
        _currentMonth = 1;
        _currentYear++;
      } else if (_currentMonth < 1) {
        _currentMonth = 12;
        _currentYear--;
      }
    });
    _fetchPnLData();
  }

  Future<void> _exportPdf() async {
    if (_pnl == null) return;
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Monthly Profit & Loss', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text('Period: ${Formatters.formatMonthYear(_currentYear, _currentMonth)}', style: const pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 20),
            pw.Text('Income', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ..._pnl!.revenueBreakdown.entries.map((e) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(e.key), pw.Text(Formatters.formatPKR(e.value))])).toList(),
            pw.Divider(),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Total Income', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text(Formatters.formatPKR(_pnl!.totalIncome), style: pw.TextStyle(fontWeight: pw.FontWeight.bold))]),
            pw.SizedBox(height: 20),
            pw.Text('Expenses', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ..._pnl!.expenseBreakdown.entries.map((e) => pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(e.key), pw.Text(Formatters.formatPKR(e.value))])).toList(),
            pw.Divider(),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Total Expenses', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text(Formatters.formatPKR(_pnl!.totalExpenses), style: pw.TextStyle(fontWeight: pw.FontWeight.bold))]),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 2),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Net Profit', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)), pw.Text(Formatters.formatPKR(_pnl!.netProfit), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))]),
          ],
        ),
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'pnl_$_currentYear-$_currentMonth.pdf');
  }

  Future<void> _exportExcel() async {
    if (_pnl == null) return;
    
    // Simplistic CSV export
    final buffer = StringBuffer();
    buffer.writeln('Monthly Profit & Loss,${Formatters.formatMonthYear(_currentYear, _currentMonth)}');
    buffer.writeln('');
    buffer.writeln('INCOME');
    _pnl!.revenueBreakdown.forEach((key, value) => buffer.writeln('$key,$value'));
    buffer.writeln('Total Income,${_pnl!.totalIncome}');
    buffer.writeln('');
    buffer.writeln('EXPENSES');
    _pnl!.expenseBreakdown.forEach((key, value) => buffer.writeln('$key,$value'));
    buffer.writeln('Total Expenses,${_pnl!.totalExpenses}');
    buffer.writeln('');
    buffer.writeln('NET PROFIT,${_pnl!.netProfit}');

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/pnl_$_currentYear-$_currentMonth.csv');
      await file.writeAsString(buffer.toString());
      await Share.shareXFiles([XFile(file.path)], text: 'P&L Statement for ${Formatters.formatMonthYear(_currentYear, _currentMonth)}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export CSV: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: const StationAppBar(
        title: 'Profit & Loss Statement',
        showBackButton: true,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading || _pnl == null ? null : _exportExcel,
                  icon: const Icon(Icons.table_chart, size: 16),
                  label: const Text('Export Excel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading || _pnl == null ? null : _exportPdf,
                  icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.white),
                  label: const Text('Export PDF', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navyPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
                Text(Formatters.formatMonthYear(_currentYear, _currentMonth), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navyPrimary)),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const LoadingView(message: 'Generating live ledger P&L statement...')
                : _error != null
                    ? ErrorStateView(errorMessage: _error!, onRetry: _fetchPnLData)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.navyDark,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              Formatters.formatMonthYear(_pnl!.year, _pnl!.month),
                                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const Text('Monthly Financial Statement', style: TextStyle(fontSize: 11, color: Colors.white70)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                                        child: const Text('AUDITED LEDGER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('TOTAL INCOME', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white70)),
                                            const SizedBox(height: 2),
                                            Text(
                                              Formatters.formatPKR(_pnl!.totalIncome),
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text('TOTAL EXPENSES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white70)),
                                            const SizedBox(height: 2),
                                            Text(
                                              Formatters.formatPKR(_pnl!.totalExpenses),
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.coralRed),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20, color: Colors.white24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('NET PROFIT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                      Expanded(
                                        child: Text(
                                          Formatters.formatPKR(_pnl!.netProfit),
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                          textAlign: TextAlign.end,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text('Income Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              child: Column(
                                children: _pnl!.revenueBreakdown.entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            entry.key,
                                            style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          Formatters.formatPKR(entry.value),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text('Expense Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              child: Column(
                                children: _pnl!.expenseBreakdown.entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            entry.key,
                                            style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          Formatters.formatPKR(entry.value),
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.coralRed),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
