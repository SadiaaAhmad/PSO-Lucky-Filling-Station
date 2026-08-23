import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/formatters.dart';
import 'package:frontend/core/widgets/state_views.dart';
import 'package:frontend/core/widgets/station_app_bar.dart';
import 'package:frontend/models/daily_log.dart';
import 'package:frontend/models/report.dart';
import 'package:frontend/models/transactions.dart';
import 'package:frontend/models/expense.dart';
import 'package:frontend/models/master.dart';
import 'package:frontend/services/api_services.dart';
import 'package:frontend/core/utils/app_logger.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  
  List<DailyLogModel> _dailyLogs = [];
  DailyLogModel? _selectedLog;
  DailySummaryModel? _dailySummary;
  List<ExpenseModel> _expenses = [];
  List<CardTransactionModel> _cardSales = [];
  List<AccountModel> _expenseAccounts = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initialLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initialLoad() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final logs = await DailyLogApi.getDailyLogs(limit: 100);
      _dailyLogs = logs;

      // Load master expense accounts for modals
      try {
        final accounts = await MasterApi.getAccounts();
        _expenseAccounts = accounts.where((a) => a.accountCode.startsWith('5')).toList();
      } catch (e) {
        AppLogger.warn('Failed to load chart of accounts for expenses: $e');
      }

      if (_dailyLogs.isNotEmpty) {
        _selectedLog = _dailyLogs.first;
        await _fetchLogFinanceData(_selectedLog!);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      AppLogger.error('Failed initial load for finance: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchLogFinanceData(DailyLogModel log) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      DailySummaryModel? summary;
      try {
        summary = await ReportApi.getDailySummary(log.logDate);
      } catch (e) {
        AppLogger.warn('No summary for ${log.logDate}: $e');
      }

      List<ExpenseModel> exp = [];
      List<CardTransactionModel> cs = [];
      try {
        exp = await FinanceApi.getExpenses(log.id);
      } catch (e) {
        AppLogger.warn('No expenses for log ${log.id}: $e');
      }

      try {
        cs = await FinanceApi.getCardSales(log.id);
      } catch (e) {
        AppLogger.warn('No card sales for log ${log.id}: $e');
      }

      if (mounted) {
        setState(() {
          _selectedLog = log;
          _dailySummary = summary;
          _expenses = exp;
          _cardSales = cs;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to fetch finance log data: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showRecordExpenseModal() {
    if (_selectedLog == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or create a daily log first'), backgroundColor: AppTheme.amberWarning)
      );
      return;
    }

    AccountModel? selectedAcc = _expenseAccounts.isNotEmpty ? _expenseAccounts.first : null;
    String selectedPaymentCode = '1010'; // Cash in Hand
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20, 
                  20, 
                  20, 
                  MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 24
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Record Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: AppTheme.navyLightBg, borderRadius: BorderRadius.circular(6)),
                        child: Text('Log Date: ${Formatters.formatDate(_selectedLog!.logDate)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
                      ),
                      const SizedBox(height: 16),

                      const Text('Expense Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<AccountModel>(
                        value: selectedAcc,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: _expenseAccounts.map((a) => DropdownMenuItem(
                          value: a,
                          child: Text('${a.accountCode} - ${a.name}', style: const TextStyle(fontSize: 13)),
                        )).toList(),
                        onChanged: (v) => setModalState(() => selectedAcc = v),
                      ),
                      const SizedBox(height: 14),

                      const Text('Payment Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedPaymentCode,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: const [
                          DropdownMenuItem(value: '1010', child: Text('Cash in Hand (1010)', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: '1020', child: Text('Bank Account (1020)', style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (v) => setModalState(() => selectedPaymentCode = v ?? '1010'),
                      ),
                      const SizedBox(height: 14),

                      const Text('Amount (PKR)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'e.g. 2500',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text('Description / Purpose', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: descCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g. Generator Fuel / Tea / Office Supplies',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.navyPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            if (amountCtrl.text.trim().isEmpty || selectedAcc == null) return;
                            final navigator = Navigator.of(ctx);
                            try {
                              await FinanceApi.recordExpense(
                                dailyLogId: _selectedLog!.id,
                                expenseAccountCode: selectedAcc!.accountCode,
                                amount: amountCtrl.text.trim(),
                                description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : selectedAcc!.name,
                                paymentAccountCode: selectedPaymentCode,
                              );
                              navigator.pop();
                              _fetchLogFinanceData(_selectedLog!);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Expense recorded successfully!'), backgroundColor: AppTheme.emeraldGreen)
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.coralRed));
                              }
                            }
                          },
                          child: const Text('Save Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRecordCardSaleModal() {
    if (_selectedLog == null) return;

    String selectedCardType = 'BANK_CARD';
    final litersCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final chargesCtrl = TextEditingController(text: '0.00');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20, 
                  20, 
                  20, 
                  MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 24
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Record Card / PSO Sale', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      const Text('Card Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedCardType,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'BANK_CARD', child: Text('Bank Debit/Credit Card (PSO Terminal)')),
                          DropdownMenuItem(value: 'BPSO_CARD', child: Text('BPSO Fleet Card')),
                        ],
                        onChanged: (v) => setModalState(() => selectedCardType = v ?? 'BANK_CARD'),
                      ),
                      const SizedBox(height: 14),

                      const Text('Liters Dispensed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: litersCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'e.g. 50.00',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text('Total Amount (PKR)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'e.g. 15000.00',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text('Bank Charges / Fee (PKR)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: chargesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0.00',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.navyPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () async {
                            if (amountCtrl.text.trim().isEmpty) return;
                            final navigator = Navigator.of(ctx);
                            try {
                              await FinanceApi.recordCardSale(
                                dailyLogId: _selectedLog!.id,
                                cardType: selectedCardType,
                                liters: litersCtrl.text.trim().isEmpty ? '0.00' : litersCtrl.text.trim(),
                                amount: amountCtrl.text.trim(),
                                bankCharges: chargesCtrl.text.trim().isEmpty ? '0.00' : chargesCtrl.text.trim(),
                              );
                              navigator.pop();
                              _fetchLogFinanceData(_selectedLog!);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Card sale recorded!'), backgroundColor: AppTheme.emeraldGreen)
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.coralRed));
                              }
                            }
                          },
                          child: const Text('Save Card Sale', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRecordOwnerDrawModal() {
    if (_selectedLog == null) return;
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController(text: 'Owner Personal Withdrawal');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20, 
              20, 
              20, 
              MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 24
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Owner Draw / Home Withdrawal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text('Amount (PKR)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g. 50000',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Notes / Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descCtrl,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.navyPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        if (amountCtrl.text.trim().isEmpty) return;
                        final navigator = Navigator.of(ctx);
                        try {
                          await FinanceApi.recordOwnerDraw(
                            dailyLogId: _selectedLog!.id,
                            amount: amountCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                          );
                          navigator.pop();
                          _fetchLogFinanceData(_selectedLog!);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Owner draw recorded!'), backgroundColor: AppTheme.emeraldGreen)
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.coralRed));
                          }
                        }
                      },
                      child: const Text('Save Withdrawal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _dailyLogs.isEmpty) {
      return const Scaffold(
        appBar: StationAppBar(subtitle: 'Finance Management'),
        body: LoadingView(message: 'Loading financial records...'),
      );
    }

    if (_error != null && _dailyLogs.isEmpty) {
      return Scaffold(
        appBar: const StationAppBar(subtitle: 'Finance Management'),
        body: ErrorStateView(errorMessage: _error!, onRetry: _initialLoad),
      );
    }

    if (_dailyLogs.isEmpty) {
      return Scaffold(
        appBar: const StationAppBar(subtitle: 'Finance Management'),
        body: EmptyStateView(
          title: 'No Daily Logs Found',
          message: 'Create a Daily Log in Operations screen to record operating expenses, card sales, and cash movements.',
          onRetry: _initialLoad,
        ),
      );
    }

    final double totalCreditSales = _dailySummary != null ? double.tryParse(_dailySummary!.totalCreditSalesPkr) ?? 0.0 : 0.0;
    final double totalRecoveries = _dailySummary != null ? double.tryParse(_dailySummary!.totalCreditRecoveriesPkr) ?? 0.0 : 0.0;
    final double totalCardSales = _dailySummary != null ? double.tryParse(_dailySummary!.totalCardSalesPkr) ?? 0.0 : 0.0;
    final double totalExpenses = _expenses.fold<double>(0.0, (acc, e) => acc + (double.tryParse(e.amount) ?? 0.0));
    final double totalCashInflow = totalRecoveries + totalCardSales;
    final double netMovement = totalCashInflow - totalExpenses;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: const StationAppBar(subtitle: 'Finance Management'),
      body: SafeArea(
        child: Column(
          children: [
            // Daily Log Selector Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.navyPrimary),
                  const SizedBox(width: 10),
                  const Text('Daily Log:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<DailyLogModel>(
                        value: _dailyLogs.any((l) => l.id == _selectedLog?.id) ? _dailyLogs.firstWhere((l) => l.id == _selectedLog!.id) : _dailyLogs.first,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: AppTheme.navyPrimary),
                        items: _dailyLogs.map((l) => DropdownMenuItem(
                          value: l,
                          child: Text(
                            '${Formatters.formatDate(l.logDate)} (${l.status})',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            _fetchLogFinanceData(v);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Financial Summary Cards
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Cash Inflow',
                      Formatters.formatPKR(totalCashInflow.toStringAsFixed(2)),
                      Icons.arrow_downward_rounded,
                      AppTheme.emeraldGreen,
                      AppTheme.emeraldBg,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSummaryCard(
                      'Cash Outflow',
                      Formatters.formatPKR(totalExpenses.toStringAsFixed(2)),
                      Icons.arrow_upward_rounded,
                      AppTheme.coralRed,
                      AppTheme.coralBg,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSummaryCard(
                      'Net Cash',
                      Formatters.formatPKR(netMovement.toStringAsFixed(2)),
                      Icons.account_balance_wallet_rounded,
                      netMovement >= 0 ? AppTheme.navyPrimary : AppTheme.coralRed,
                      AppTheme.navyLightBg,
                    ),
                  ),
                ],
              ),
            ),

            // Action Buttons (Spacious & Clean)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.coralRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: _showRecordExpenseModal,
                      icon: const Icon(Icons.receipt_long_rounded, size: 18, color: Colors.white),
                      label: const Text('Record Operating Expense', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.navyPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            onPressed: _showRecordCardSaleModal,
                            icon: const Icon(Icons.credit_card, size: 16, color: Colors.white),
                            label: const Text('PSO Card Sale', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.navyPrimary),
                              foregroundColor: AppTheme.navyPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _showRecordOwnerDrawModal,
                            icon: const Icon(Icons.account_balance_rounded, size: 16),
                            label: const Text('Owner Draw', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.navyPrimary,
                labelColor: AppTheme.navyPrimary,
                unselectedLabelColor: AppTheme.textMuted,
                tabs: [
                  Tab(text: 'Expenses (${_expenses.length})'),
                  Tab(text: 'Card Sales (${_cardSales.length})'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExpensesTab(),
                  _buildCardSalesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteExpense(int journalId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('Are you sure you want to delete/reverse this expense entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FinanceApi.reverseExpense(journalId, 'User deleted expense');
        if (_selectedLog != null) _fetchLogFinanceData(_selectedLog!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense deleted successfully!'), backgroundColor: AppTheme.emeraldGreen)
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete expense: $e'), backgroundColor: AppTheme.coralRed)
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteCardSale(int cardId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Card Sale?'),
        content: const Text('Are you sure you want to delete/reverse this card sale entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FinanceApi.reverseCardSale(cardId, 'User deleted card sale');
        if (_selectedLog != null) _fetchLogFinanceData(_selectedLog!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Card sale deleted successfully!'), backgroundColor: AppTheme.emeraldGreen)
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete card sale: $e'), backgroundColor: AppTheme.coralRed)
          );
        }
      }
    }
  }

  Widget _buildExpensesTab() {
    if (_expenses.isEmpty) {
      return const EmptyStateView(
        title: 'No Expenses Recorded',
        message: 'Tap "+ Record Expense" to post operating expenses for this date.',
      );
    }
    return RefreshIndicator(
      onRefresh: () => _fetchLogFinanceData(_selectedLog!),
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _expenses.length,
        itemBuilder: (context, index) {
          final exp = _expenses[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.coralBg,
                child: Icon(Icons.receipt_long, color: AppTheme.coralRed, size: 20),
              ),
              title: Text(exp.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(
                '${exp.accountCode} - ${exp.accountName} | ${exp.paymentMethod}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Formatters.formatPKR(exp.amount),
                    style: const TextStyle(color: AppTheme.coralRed, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.coralRed, size: 20),
                    onPressed: () => _confirmDeleteExpense(exp.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardSalesTab() {
    if (_cardSales.isEmpty) {
      return const EmptyStateView(
        title: 'No Card Sales',
        message: 'No bank or PSO fleet card transactions recorded for this log.',
      );
    }
    return RefreshIndicator(
      onRefresh: () => _fetchLogFinanceData(_selectedLog!),
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _cardSales.length,
        itemBuilder: (context, index) {
          final sale = _cardSales[index];
          final isBank = sale.cardType == 'BANK_CARD';
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isBank ? AppTheme.navyLightBg : AppTheme.amberBg,
                child: Icon(
                  isBank ? Icons.credit_card : Icons.local_shipping_rounded,
                  color: isBank ? AppTheme.navyPrimary : AppTheme.amberWarning,
                  size: 20,
                ),
              ),
              title: Text(
                isBank ? 'PSO Bank Card Sale' : 'BPSO Fleet Card Sale',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Text(
                '${Formatters.formatLiters(sale.liters)} | Fee: ${Formatters.formatPKR(sale.bankCharges)}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Formatters.formatPKR(sale.amount),
                    style: const TextStyle(color: AppTheme.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.coralRed, size: 20),
                    onPressed: () => _confirmDeleteCardSale(sale.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
