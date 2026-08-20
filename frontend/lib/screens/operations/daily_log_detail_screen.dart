import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/formatters.dart';
import 'package:frontend/core/widgets/state_views.dart';
import 'package:frontend/core/widgets/station_app_bar.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/models/daily_log.dart';
import 'package:frontend/models/daily_log_detail.dart';
import 'package:frontend/models/master.dart';
import 'package:frontend/services/api_services.dart';

class DailyLogDetailScreen extends StatefulWidget {
  final DailyLogModel log;
  const DailyLogDetailScreen({super.key, required this.log});

  @override
  State<DailyLogDetailScreen> createState() => _DailyLogDetailScreenState();
}

class _DailyLogDetailScreenState extends State<DailyLogDetailScreen> {
  bool _isLoading = true;
  String? _error;
  DailyLogDetailModel? _detail;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.log.status;
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      AppLogger.data('[API] Fetching DailyLogDetail for ID: ${widget.log.id}');
      final detail = await DailyLogApi.getDailyLogDetail(widget.log.id);
      setState(() {
        _detail = detail;
        _currentStatus = detail.status;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('[ERROR] Failed to fetch DailyLogDetail: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _closeLog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Daily Log'),
        content: const Text('Are you sure you want to close this log? You will not be able to add more records.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Close Log')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      AppLogger.data('[API] Closing DailyLog ID: ${widget.log.id}');
      final updated = await DailyLogApi.closeDailyLog(widget.log.id);
      setState(() {
        _currentStatus = updated.status;
      });
      _loadDetail();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Daily Log closed successfully!"), backgroundColor: AppTheme.emeraldGreen),
      );
    } catch (e) {
      AppLogger.error('[ERROR] Failed to close DailyLog: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.coralRed),
      );
    }
  }

  Future<void> _openRecordNozzleReadings() async {
    List<DispensingUnitModel> units = [];
    try {
      units = await MasterApi.getDispensingUnits();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.coralRed));
      return;
    }
    
    if (units.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No dispensing units found."), backgroundColor: AppTheme.coralRed));
      return;
    }

    final controllers = units.map((u) => {
      'unit': u,
      'opening': TextEditingController(),
      'closing': TextEditingController()
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
                          const Text('Record Nozzle Readings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ...controllers.map((c) {
                        final unit = c['unit'] as DispensingUnitModel;
                        final opCtrl = c['opening'] as TextEditingController;
                        final clCtrl = c['closing'] as TextEditingController;
                        final isHsd = unit.productCode == 'HSD';
                        final op = double.tryParse(opCtrl.text.trim()) ?? 0.0;
                        final cl = double.tryParse(clCtrl.text.trim()) ?? 0.0;
                        final diff = cl >= op ? (cl - op) : 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.bgLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: isHsd ? AppTheme.emeraldBg : AppTheme.navyLightBg,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.local_gas_station_rounded, size: 16, color: isHsd ? AppTheme.emeraldGreen : AppTheme.navyPrimary),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(unit.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isHsd ? AppTheme.emeraldBg : AppTheme.navyLightBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      unit.productCode,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isHsd ? AppTheme.emeraldGreen : AppTheme.navyPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Opening Meter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                                        const SizedBox(height: 4),
                                        TextField(
                                          controller: opCtrl,
                                          keyboardType: TextInputType.number,
                                          onChanged: (_) => setModalState(() {}),
                                          decoration: InputDecoration(
                                            hintText: '0.00',
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Closing Meter', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                                        const SizedBox(height: 4),
                                        TextField(
                                          controller: clCtrl,
                                          keyboardType: TextInputType.number,
                                          onChanged: (_) => setModalState(() {}),
                                          decoration: InputDecoration(
                                            hintText: '0.00',
                                            filled: true,
                                            fillColor: Colors.white,
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          if (cl > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Sale: ${diff.toStringAsFixed(2)} Liters',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: diff > 0 ? AppTheme.emeraldGreen : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.navyPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final navigator = Navigator.of(ctx);
                        final readings = controllers.map((c) {
                          final op = (c['opening'] as TextEditingController).text.trim();
                          final cl = (c['closing'] as TextEditingController).text.trim();
                          return {
                            'unit_id': (c['unit'] as DispensingUnitModel).id,
                            'opening_reading': op.isEmpty ? '0.00' : op,
                            'closing_reading': cl.isEmpty ? (op.isEmpty ? '0.00' : op) : cl,
                          };
                        }).toList();
                        
                        try {
                          await FuelApi.recordNozzleReadings(widget.log.id, readings);
                          navigator.pop();
                          _loadDetail();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Nozzle readings recorded!'), backgroundColor: AppTheme.emeraldGreen)
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.coralRed));
                          }
                        }
                      },
                      child: const Text('Save Meter Readings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Future<void> _openRecordTankDip() async {
    List<TankModel> tanks = [];
    try {
      tanks = await MasterApi.getTanks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.coralRed));
      return;
    }
    
    TankModel? selectedTank = tanks.isNotEmpty ? tanks.first : null;
    final openingCtrl = TextEditingController();
    final stockInCtrl = TextEditingController();
    final testingLossCtrl = TextEditingController();
    final netSalesCtrl = TextEditingController();
    final actualCtrl = TextEditingController();
    final rateCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateModal) => SafeArea(
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
                    const Text('Record Tank Dip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text('Select Tank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    DropdownButtonFormField<TankModel>(
                      value: selectedTank,
                      items: tanks.map((t) => DropdownMenuItem(value: t, child: Text('${t.tankName} - ${t.productCode}', overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setStateModal(() => selectedTank = v),
                      isExpanded: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: openingCtrl, decoration: const InputDecoration(labelText: 'Opening Dip', floatingLabelBehavior: FloatingLabelBehavior.always), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(controller: stockInCtrl, decoration: const InputDecoration(labelText: 'Stock In (Purchases)', floatingLabelBehavior: FloatingLabelBehavior.always), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(controller: testingLossCtrl, decoration: const InputDecoration(labelText: 'Testing Loss', floatingLabelBehavior: FloatingLabelBehavior.always), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(controller: netSalesCtrl, decoration: const InputDecoration(labelText: 'Net Sales', floatingLabelBehavior: FloatingLabelBehavior.always), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(controller: actualCtrl, decoration: const InputDecoration(labelText: 'Actual Dip', floatingLabelBehavior: FloatingLabelBehavior.always), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(controller: rateCtrl, decoration: const InputDecoration(labelText: 'Purchase Rate', floatingLabelBehavior: FloatingLabelBehavior.always), keyboardType: TextInputType.number),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedTank == null) return;
                          final navigator = Navigator.of(ctx);
                          try {
                            await StockApi.recordTankStock(
                              dailyLogId: widget.log.id,
                              tankId: selectedTank!.id,
                              productId: selectedTank!.productId,
                              openingDipLiters: openingCtrl.text,
                              stockInPurchaseLiters: stockInCtrl.text,
                              testingLossLiters: testingLossCtrl.text,
                              netSalesLiters: netSalesCtrl.text,
                              actualDipLiters: actualCtrl.text,
                              purchaseRate: rateCtrl.text,
                            );
                            navigator.pop();
                            _loadDetail();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tank dip recorded!'), backgroundColor: AppTheme.emeraldGreen));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.coralRed));
                          }
                        },
                        child: const Text('Save Dip Record', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navyPrimary),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        );
      }
    );
  }

  Future<void> _openRecordFuelPurchase() async {
    List<ProductModel> products = [];
    List<TankModel> tanks = [];
    try {
      products = await MasterApi.getProducts();
      tanks = await MasterApi.getTanks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.coralRed));
      return;
    }
    
    ProductModel? selectedProduct = products.isNotEmpty ? products.first : null;
    TankModel? selectedTank = tanks.isNotEmpty ? tanks.first : null;
    final litersCtrl = TextEditingController();
    final purchaseRateCtrl = TextEditingController();
    final saleRateCtrl = TextEditingController();
    final invoiceCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateModal) => SafeArea(
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
                    const Text('Record Fuel Purchase', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text('Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    DropdownButtonFormField<ProductModel>(
                      value: selectedProduct,
                      items: products.map((p) => DropdownMenuItem(value: p, child: Text(p.name, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setStateModal(() => selectedProduct = v),
                      isExpanded: true,
                    ),
                    const SizedBox(height: 12),
                    const Text('Tank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    DropdownButtonFormField<TankModel>(
                      value: selectedTank,
                      items: tanks.map((t) => DropdownMenuItem(value: t, child: Text(t.tankName, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setStateModal(() => selectedTank = v),
                      isExpanded: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: litersCtrl, decoration: const InputDecoration(labelText: 'Purchase Liters', floatingLabelBehavior: FloatingLabelBehavior.always), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(controller: purchaseRateCtrl, decoration: const InputDecoration(labelText: 'Purchase Rate', floatingLabelBehavior: FloatingLabelBehavior.always), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(controller: saleRateCtrl, decoration: const InputDecoration(labelText: 'Sale Rate', floatingLabelBehavior: FloatingLabelBehavior.always), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(controller: invoiceCtrl, decoration: const InputDecoration(labelText: 'Invoice No', floatingLabelBehavior: FloatingLabelBehavior.always)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedProduct == null || selectedTank == null) return;
                          final navigator = Navigator.of(ctx);
                          try {
                            await FuelApi.recordFuelPurchase(
                              dailyLogId: widget.log.id,
                              productId: selectedProduct!.id,
                              tankId: selectedTank!.id,
                              purchaseLiters: litersCtrl.text,
                              purchaseRate: purchaseRateCtrl.text,
                              saleRate: saleRateCtrl.text,
                              invoiceNo: invoiceCtrl.text,
                            );
                            navigator.pop();
                            _loadDetail();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fuel purchase recorded!'), backgroundColor: AppTheme.emeraldGreen));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.coralRed));
                          }
                        },
                        child: const Text('Save Purchase', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navyPrimary),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        );
      }
    );
  }

  Future<void> _openRecordExpense() async {
    List<AccountModel> accounts = [];
    try {
      accounts = await MasterApi.getAccounts();
      // Filter for expense accounts if possible, else just use all
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.coralRed));
      return;
    }
    
    AccountModel? selectedAccount = accounts.isNotEmpty ? accounts.first : null;
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final methodCtrl = TextEditingController(text: 'CASH');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateModal) => SafeArea(
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
                    const Text('Record Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text('Expense Account', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    DropdownButtonFormField<AccountModel>(
                      value: selectedAccount,
                      items: accounts.map((a) => DropdownMenuItem(value: a, child: Text(a.name, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (v) => setStateModal(() => selectedAccount = v),
                      isExpanded: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount', floatingLabelBehavior: FloatingLabelBehavior.always), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', floatingLabelBehavior: FloatingLabelBehavior.always)),
                    const SizedBox(height: 12),
                    TextField(controller: methodCtrl, decoration: const InputDecoration(labelText: 'Payment Method (CASH/BANK)', floatingLabelBehavior: FloatingLabelBehavior.always)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedAccount == null) return;
                          final navigator = Navigator.of(ctx);
                          String payCode = methodCtrl.text.trim();
                          if (payCode.isEmpty || payCode.toUpperCase() == 'CASH') {
                            payCode = '1010';
                          } else if (payCode.toUpperCase() == 'BANK') {
                            payCode = '1020';
                          }
                          try {
                            await FinanceApi.recordExpense(
                              dailyLogId: widget.log.id,
                              expenseAccountCode: selectedAccount!.accountCode,
                              amount: amountCtrl.text,
                              description: descCtrl.text.isEmpty ? 'Operating Expense' : descCtrl.text,
                              paymentAccountCode: payCode,
                            );
                            navigator.pop();
                            _loadDetail();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense recorded successfully!'), backgroundColor: AppTheme.emeraldGreen));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.coralRed));
                          }
                        },
                        child: const Text('Save Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navyPrimary),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: StationAppBar(
        title: Formatters.formatDate(widget.log.logDate),
        subtitle: 'Status: $_currentStatus',
        showBackButton: true,
      ),
      body: _isLoading 
        ? const LoadingView(message: 'Loading daily log details...') 
        : _error != null 
          ? ErrorStateView(errorMessage: _error!, onRetry: _loadDetail) 
          : _detail == null 
            ? const EmptyStateView(message: 'No detail found') 
            : RefreshIndicator(
                onRefresh: _loadDetail,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildNozzleReadings(),
                      const SizedBox(height: 20),
                      _buildTankStocks(),
                      const SizedBox(height: 20),
                      _buildPurchases(),
                      const SizedBox(height: 20),
                      _buildCashMovement(),
                      const SizedBox(height: 20),
                      _buildCreditTransactions(),
                      const SizedBox(height: 24),
                      if (_currentStatus != 'CLOSED') _buildActionButtons(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
    );
  }

  Future<void> _confirmDeleteLog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entire Daily Log?'),
        content: Text('Are you sure you want to permanently delete the daily log for ${Formatters.formatDate(_detail!.logDate)}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Log', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DailyLogApi.deleteDailyLog(widget.log.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Daily log deleted successfully!'), backgroundColor: AppTheme.emeraldGreen)
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete log: $e'), backgroundColor: AppTheme.coralRed)
          );
        }
      }
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Date:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              Text(Formatters.formatDate(_detail!.logDate), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _currentStatus == 'CLOSED' ? AppTheme.emeraldBg : AppTheme.amberBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _currentStatus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _currentStatus == 'CLOSED' ? AppTheme.emeraldGreen : AppTheme.amberWarning,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _confirmDeleteLog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.coralBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline, color: AppTheme.coralRed, size: 14),
                          SizedBox(width: 4),
                          Text('Delete Log', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.coralRed)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_detail!.notes != null && _detail!.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Notes: ${_detail!.notes}', style: const TextStyle(color: AppTheme.textDark)),
          ]
        ],
      ),
    );
  }

  Widget _buildNozzleReadings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nozzle Meter Readings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 10),
        if (_detail!.nozzleReadings.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, size: 20, color: AppTheme.navyLight),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Daily operational totals are loaded directly from the ledger datasheet.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderLight)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _detail!.nozzleReadings.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final r = _detail!.nozzleReadings[i];
                final amt = double.tryParse(r.saleAmountPkr) ?? 0;
                return ListTile(
                  title: Text('${r.unitName} - ${r.productCode}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, decoration: r.isReversed ? TextDecoration.lineThrough : null)),
                  subtitle: Text('Opening: ${r.openingReading} | Closing: ${r.closingReading}', style: const TextStyle(fontSize: 12)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${r.grossSaleLiters} L', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
                      if (amt > 0)
                        Text(Formatters.formatPKR(amt), style: const TextStyle(fontSize: 11, color: AppTheme.emeraldGreen, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDeleteTankStock(int stockId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete / Reverse Record?'),
        content: const Text('Are you sure you want to delete/reverse this tank stock entry?'),
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
        await StockApi.reverseTankStock(stockId, 'User deleted tank stock entry');
        _loadDetail();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tank stock entry deleted successfully!'), backgroundColor: AppTheme.emeraldGreen)
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppTheme.coralRed)
          );
        }
      }
    }
  }

  Future<void> _confirmDeletePurchase(int purchaseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Fuel Purchase?'),
        content: const Text('Are you sure you want to delete/reverse this fuel purchase entry?'),
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
        await FuelApi.reverseFuelPurchase(purchaseId, 'User deleted purchase entry');
        _loadDetail();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fuel purchase deleted successfully!'), backgroundColor: AppTheme.emeraldGreen)
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete purchase: $e'), backgroundColor: AppTheme.coralRed)
          );
        }
      }
    }
  }

  Widget _buildTankStocks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tank Operations & Datasheet Records', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 10),
        if (_detail!.tankStocks.isEmpty)
          const EmptyStateView(message: 'No dip/operation records yet.', icon: Icons.straighten)
        else
          ..._detail!.tankStocks.map((t) {
            final isGain = (double.tryParse(t.stockGainLossLiters) ?? 0) >= 0;
            final isRateDiffPos = (double.tryParse(t.rateDiffPkr) ?? 0) >= 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderLight)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('${t.tankName} - ${t.productCode}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.navyPrimary), overflow: TextOverflow.ellipsis)),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppTheme.navyLightBg, borderRadius: BorderRadius.circular(4)),
                            child: Text('Rate: ${t.purchaseRate} PKR', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.coralRed, size: 20),
                            onPressed: () => _confirmDeleteTankStock(t.id),
                            tooltip: 'Delete / Reverse Record',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Sales (Liters):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), Text('${t.netSalesLiters} L', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Purchase Rate:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)), Text('${t.purchaseRate} PKR/L', style: const TextStyle(fontSize: 12))]),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Rate Difference (Sale - Purch):', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)), Text('${t.rateDifference} PKR/L', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Effective Sale Rate:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)), Text('${t.saleRate} PKR/L', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(6)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Total Sales Amount (Rs):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      Text(Formatters.formatPKR(t.totalSalesPkr), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen)),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Rate Diff (+/-) Amount:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    Text(Formatters.formatPKR(t.rateDiffPkr), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isRateDiffPos ? AppTheme.emeraldGreen : AppTheme.coralRed)),
                  ]),
                  if ((double.tryParse(t.lubeOilSalePkr) ?? 0) > 0) ...[
                    const SizedBox(height: 6),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Lube / Oil Sale (PMG):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.navyPrimary)),
                      Text(Formatters.formatPKR(t.lubeOilSalePkr), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
                    ]),
                  ],
                  const Divider(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Opening Dip:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)), Text('${t.openingDipLiters} L', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Testing Loss:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)), Text('${t.testingLossLiters} L', style: const TextStyle(fontSize: 12))]),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Stock In / Purchase:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)), Text('${t.stockInPurchaseLiters} L', style: const TextStyle(fontSize: 12))]),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Closing Meter (Expected Closing):', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)), Text('${t.expectedClosingLiters} L', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Tank Dip (Actual Dip):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark)), Text('${t.actualDipLiters} L', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]),
                  const Divider(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Stock Diff / Variance:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('${t.stockGainLossLiters} L (${Formatters.formatPKR(t.stockGainLossValuePkr)})', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isGain ? AppTheme.emeraldGreen : AppTheme.coralRed)),
                  ]),
                ],
              ),
            );
          }).toList()
      ],
    );
  }

  Widget _buildPurchases() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fuel Purchases', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 10),
        if (_detail!.fuelPurchases.isEmpty)
          const EmptyStateView(message: 'No purchases recorded.', icon: Icons.local_shipping)
        else
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderLight)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _detail!.fuelPurchases.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final p = _detail!.fuelPurchases[i];
                return ListTile(
                  title: Text('${p.productCode} - Inv: ${p.invoiceNo}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('${p.purchaseLiters} L @ ${p.purchaseRate} PKR', style: const TextStyle(fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(Formatters.formatPKR((double.tryParse(p.purchaseLiters) ?? 0) * (double.tryParse(p.purchaseRate) ?? 0)), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.coralRed, size: 20),
                        onPressed: () => _confirmDeletePurchase(p.id),
                        tooltip: 'Delete / Reverse Purchase',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCashMovement() {
    final c = _detail!.cashMovement;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Daily Cash Movement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderLight)),
          child: Column(
            children: [
              _cashRow('Fuel Sales', Formatters.formatPKR(c.totalFuelSalesPkr), AppTheme.textDark),
              const SizedBox(height: 8),
              _cashRow('Credit Sales', '- ${Formatters.formatPKR(c.totalCreditSalesPkr)}', AppTheme.coralRed),
              const SizedBox(height: 8),
              _cashRow('Card Sales', '- ${Formatters.formatPKR(c.totalCardSalesPkr)}', AppTheme.coralRed),
              const SizedBox(height: 8),
              _cashRow('Recoveries', '+ ${Formatters.formatPKR(c.totalCreditRecoveriesPkr)}', AppTheme.emeraldGreen),
              const SizedBox(height: 8),
              _cashRow('Expenses', '- ${Formatters.formatPKR(c.totalExpensesPkr)}', AppTheme.coralRed),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Net Cash:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(Formatters.formatPKR(c.netCashPkr), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.navyPrimary)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _cashRow(String label, String amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
        Text(amount, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildCreditTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Credit Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 10),
        if (_detail!.creditTransactions.isEmpty)
          const EmptyStateView(message: 'No credit transactions.', icon: Icons.credit_card)
        else
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderLight)),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _detail!.creditTransactions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final tx = _detail!.creditTransactions[i];
                final isSale = tx.transactionType == 'CREDIT_SALE' || tx.transactionType == 'SALE';
                return ListTile(
                  leading: Icon(isSale ? Icons.shopping_cart : Icons.arrow_downward, color: isSale ? AppTheme.coralRed : AppTheme.emeraldGreen),
                  title: Text(isSale ? 'Credit Sale' : 'Credit Recovery', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Ref: ${tx.reference}', style: const TextStyle(fontSize: 12)),
                  trailing: Text((isSale ? '-' : '+') + Formatters.formatPKR(tx.amount), style: TextStyle(fontWeight: FontWeight.bold, color: isSale ? AppTheme.coralRed : AppTheme.emeraldGreen)),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton(onPressed: _openRecordNozzleReadings, child: const Text('Record Nozzle Readings')),
        OutlinedButton(onPressed: _openRecordTankDip, child: const Text('Record Tank Dip')),
        OutlinedButton(onPressed: _openRecordFuelPurchase, child: const Text('Record Fuel Purchase')),
        OutlinedButton(onPressed: _openRecordExpense, child: const Text('Record Expense')),
        ElevatedButton(
          onPressed: _closeLog,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navyDark),
          child: const Text('Close Daily Log', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
