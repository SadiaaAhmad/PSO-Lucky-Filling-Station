import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/station_app_bar.dart';
import 'package:frontend/core/widgets/state_views.dart';
import 'package:frontend/core/utils/formatters.dart';
import 'package:frontend/core/utils/app_logger.dart';
import 'package:frontend/models/master.dart';
import 'package:frontend/models/tank_stock.dart';
import 'package:frontend/models/fuel.dart';
import 'package:frontend/models/daily_log.dart';
import 'package:frontend/services/api_services.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  bool _isLoading = false;
  String? _error;

  List<TankModel> _tanks = [];
  List<LatestTankStockModel> _latestStocks = [];
  List<DispensingUnitModel> _units = [];
  List<FuelPurchaseModel> _recentPurchases = [];
  List<DailyLogModel> _openLogs = [];

  final _purchaseLitersCtrl = TextEditingController();
  final _purchaseRateCtrl = TextEditingController();
  final _purchaseSaleRateCtrl = TextEditingController();
  final _purchaseInvoiceCtrl = TextEditingController();

  ProductModel? _selectedProduct;
  TankModel? _selectedTank;
  DailyLogModel? _selectedLog;

  List<ProductModel> _products = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadInitialData();
  }

  void _handleTabSelection() {
    setState(() {});
    if (_tabController.indexIsChanging) {
      if (_tabController.index == 0) _loadTankTab();
      if (_tabController.index == 1) _loadNozzlesTab();
      if (_tabController.index == 2) _loadPurchasesTab();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _loadTankTab();
    try {
      final logs = await DailyLogApi.getDailyLogs(limit: 100);
      _openLogs = logs;
      _products = await MasterApi.getProducts();
      _units = await MasterApi.getDispensingUnits();
    } catch (e) {
      AppLogger.error('Failed to load initial common data: $e');
    }
  }

  Future<void> _loadTankTab() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      _tanks = await MasterApi.getTanks();
      final latest = await StockApi.getLatestTankStocks();

      if (_selectedLog != null) {
        try {
          final detail = await DailyLogApi.getDailyLogDetail(_selectedLog!.id);
          if (detail.tankStocks.isNotEmpty) {
            _latestStocks = detail.tankStocks.map((ts) => LatestTankStockModel(
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
            _latestStocks = latest;
          }
        } catch (_) {
          _latestStocks = latest;
        }
      } else {
        _latestStocks = latest;
      }
      setState(() => _isLoading = false);
    } catch (e) {
      try {
        _latestStocks = await StockApi.getLatestTankStocks();
      } catch (_) {}
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _loadNozzlesTab() async {
    if (_units.isNotEmpty) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      _units = await MasterApi.getDispensingUnits();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _loadPurchasesTab() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      if (_openLogs.isNotEmpty) {
        _recentPurchases = await FuelApi.getPurchases(_openLogs.first.id);
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _openRecordTankDipModal() async {
    if (_openLogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No open logs available.'), backgroundColor: AppTheme.coralRed));
      return;
    }
    
    TankModel? modalSelectedTank = _tanks.isNotEmpty ? _tanks.first : null;
    DailyLogModel? modalSelectedLog = _openLogs.first;
    
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
                    const Text('Select Log', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    DropdownButtonFormField<DailyLogModel>(
                      value: modalSelectedLog,
                      items: _openLogs.map((l) => DropdownMenuItem(value: l, child: Text(Formatters.formatDate(l.logDate)))).toList(),
                      onChanged: (v) => setStateModal(() => modalSelectedLog = v),
                      isExpanded: true,
                    ),
                    const SizedBox(height: 12),
                    const Text('Select Tank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    DropdownButtonFormField<TankModel>(
                      value: modalSelectedTank,
                      items: _tanks.map((t) => DropdownMenuItem(value: t, child: Text(t.tankName))).toList(),
                      onChanged: (v) => setStateModal(() => modalSelectedTank = v),
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
                          if (modalSelectedTank == null || modalSelectedLog == null) return;
                          final navigator = Navigator.of(ctx);
                          try {
                            await StockApi.recordTankStock(
                              dailyLogId: modalSelectedLog!.id,
                              tankId: modalSelectedTank!.id,
                              productId: modalSelectedTank!.productId,
                              openingDipLiters: openingCtrl.text,
                              stockInPurchaseLiters: stockInCtrl.text,
                              testingLossLiters: testingLossCtrl.text,
                              netSalesLiters: netSalesCtrl.text,
                              actualDipLiters: actualCtrl.text,
                              purchaseRate: rateCtrl.text,
                            );
                            navigator.pop();
                            _loadTankTab();
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

  Future<void> _openRecordNozzlesModal() async {
    if (_openLogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No open logs available.'), backgroundColor: AppTheme.coralRed));
      return;
    }
    
    DailyLogModel? modalSelectedLog = _openLogs.first;
    final controllers = _units.map((u) => {
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Record Nozzle Readings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Operational Daily Log', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<DailyLogModel>(
                      value: modalSelectedLog,
                      items: _openLogs.map((l) => DropdownMenuItem(value: l, child: Text('${Formatters.formatDate(l.logDate)} (${l.status})'))).toList(),
                      onChanged: (v) => setStateModal(() => modalSelectedLog = v),
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                                        onChanged: (_) => setStateModal(() {}),
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
                                        onChanged: (_) => setStateModal(() {}),
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
                    }).toList(),
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
                          if (modalSelectedLog == null) return;
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
                            await FuelApi.recordNozzleReadings(modalSelectedLog!.id, readings);
                            navigator.pop();
                            _loadNozzlesTab();
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
          )
        );
      }
    );
  }

  Future<void> _submitPurchase() async {
    if (_selectedProduct == null || _selectedTank == null || _selectedLog == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields.'), backgroundColor: AppTheme.coralRed));
      return;
    }
    
    try {
      await FuelApi.recordFuelPurchase(
        dailyLogId: _selectedLog!.id,
        productId: _selectedProduct!.id,
        tankId: _selectedTank!.id,
        purchaseLiters: _purchaseLitersCtrl.text,
        purchaseRate: _purchaseRateCtrl.text,
        saleRate: _purchaseSaleRateCtrl.text,
        invoiceNo: _purchaseInvoiceCtrl.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase recorded!'), backgroundColor: AppTheme.emeraldGreen));
      _purchaseLitersCtrl.clear();
      _purchaseRateCtrl.clear();
      _purchaseSaleRateCtrl.clear();
      _purchaseInvoiceCtrl.clear();
      _loadPurchasesTab();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.coralRed));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: const StationAppBar(title: 'Fuel & Stock Management', showBackButton: false),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.navyPrimary,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.navyPrimary,
            tabs: const [Tab(text: 'Tank Dip'), Tab(text: 'Nozzles'), Tab(text: 'Purchases')],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTankTab(),
                _buildNozzlesTab(),
                _buildPurchasesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: _openRecordTankDipModal,
              label: const Text('Record Tank Dip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              icon: const Icon(Icons.add, color: Colors.white),
              backgroundColor: AppTheme.navyPrimary,
            )
          : _tabController.index == 1
              ? FloatingActionButton.extended(
                  heroTag: null,
                  onPressed: _openRecordNozzlesModal,
                  label: const Text('Record Nozzle Readings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  icon: const Icon(Icons.add, color: Colors.white),
                  backgroundColor: AppTheme.navyPrimary,
                )
              : null,
    );
  }

  Widget _buildTankTab() {
    if (_isLoading) return const LoadingView(message: 'Loading tanks...');
    if (_error != null) return ErrorStateView(errorMessage: _error!, onRetry: _loadTankTab);
    if (_tanks.isEmpty) return const EmptyStateView(message: 'No tanks found.');

    return RefreshIndicator(
      onRefresh: _loadTankTab,
      child: Column(
        children: [
          if (_openLogs.isNotEmpty)
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
                        value: _openLogs.any((l) => l.id == _selectedLog?.id) ? _openLogs.firstWhere((l) => l.id == _selectedLog!.id) : _openLogs.first,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: AppTheme.navyPrimary),
                        items: _openLogs.map((l) => DropdownMenuItem(
                          value: l,
                          child: Text(
                            '${Formatters.formatDate(l.logDate)} (${l.status})',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() { _selectedLog = v; });
                            _loadTankTab();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tanks.length,
              itemBuilder: (ctx, i) {
                final tank = _tanks[i];
                final stock = _latestStocks.where((s) => s.tankId == tank.id).firstOrNull;
                final pct = stock != null && (double.tryParse(tank.capacityLiters) ?? 0) > 0 ? ((double.tryParse(stock.actualDipLiters) ?? 0) / (double.tryParse(tank.capacityLiters) ?? 1)).clamp(0.0, 1.0) : 0.0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(tank.tankName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                            Text(tank.productCode, style: const TextStyle(color: AppTheme.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: pct, backgroundColor: AppTheme.bgLight, color: AppTheme.navyPrimary, minHeight: 8),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Actual Dip: ${stock != null ? Formatters.formatLiters(stock.actualDipLiters) : '0'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text('Cap: ${Formatters.formatLiters(tank.capacityLiters)}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (stock != null)
                          Text('Stock Value: ${Formatters.formatPKR(stock.stockValuePkr)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNozzlesTab() {
    if (_isLoading) return const LoadingView(message: 'Loading nozzles...');
    if (_error != null) return ErrorStateView(errorMessage: _error!, onRetry: _loadNozzlesTab);
    if (_units.isEmpty) return const EmptyStateView(message: 'No dispensing units found.');

    return RefreshIndicator(
      onRefresh: _loadNozzlesTab,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _units.length,
        itemBuilder: (ctx, i) {
          final unit = _units[i];
          final isHsd = unit.productCode == 'HSD';
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isHsd ? AppTheme.emeraldBg : AppTheme.navyLightBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_gas_station_rounded,
                    color: isHsd ? AppTheme.emeraldGreen : AppTheme.navyPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            unit.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isHsd ? AppTheme.emeraldBg : AppTheme.navyLightBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              unit.productCode,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isHsd ? AppTheme.emeraldGreen : AppTheme.navyPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Connected Tank: ${unit.tankName}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.bgLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Text(
                    'Unit #${unit.unitNumber}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textDark),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPurchasesTab() {
    return RefreshIndicator(
      onRefresh: _loadPurchasesTab,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderLight)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Record Purchase', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('Select Log', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  DropdownButtonFormField<DailyLogModel>(
                    value: _selectedLog,
                    items: _openLogs.map((l) => DropdownMenuItem(value: l, child: Text(Formatters.formatDate(l.logDate)))).toList(),
                    onChanged: (v) => setState(() => _selectedLog = v),
                    isExpanded: true,
                  ),
                  const SizedBox(height: 12),
                  const Text('Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  DropdownButtonFormField<ProductModel>(
                    value: _selectedProduct,
                    items: _products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                    onChanged: (v) => setState(() => _selectedProduct = v),
                    isExpanded: true,
                  ),
                  const SizedBox(height: 12),
                  const Text('Tank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                  DropdownButtonFormField<TankModel>(
                    value: _selectedTank,
                    items: _tanks.map((t) => DropdownMenuItem(value: t, child: Text(t.tankName))).toList(),
                    onChanged: (v) => setState(() => _selectedTank = v),
                    isExpanded: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: _purchaseInvoiceCtrl, decoration: const InputDecoration(labelText: 'Invoice No', floatingLabelBehavior: FloatingLabelBehavior.always)),
                  const SizedBox(height: 12),
                  TextField(controller: _purchaseLitersCtrl, decoration: const InputDecoration(labelText: 'Purchase Liters', floatingLabelBehavior: FloatingLabelBehavior.always), keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  TextField(controller: _purchaseRateCtrl, decoration: const InputDecoration(labelText: 'Purchase Rate', floatingLabelBehavior: FloatingLabelBehavior.always), keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  TextField(controller: _purchaseSaleRateCtrl, decoration: const InputDecoration(labelText: 'Sale Rate', floatingLabelBehavior: FloatingLabelBehavior.always), keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submitPurchase,
                      child: const Text('Save Purchase', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navyPrimary),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Recent Purchases', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (_isLoading) const LoadingView(message: 'Loading purchases...')
            else if (_error != null) ErrorStateView(errorMessage: _error!, onRetry: _loadPurchasesTab)
            else if (_recentPurchases.isEmpty) const EmptyStateView(message: 'No recent purchases.')
            else ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentPurchases.length,
              itemBuilder: (ctx, i) {
                final p = _recentPurchases[i];
                return Card(
                  child: ListTile(
                    title: Text('Product #${p.productId} - Inv: ${p.invoiceNo ?? 'N/A'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${Formatters.formatLiters(p.purchaseLiters)} @ ${p.purchaseRate} PKR'),
                    trailing: Text(Formatters.formatPKR(((double.tryParse(p.purchaseLiters) ?? 0) * (double.tryParse(p.purchaseRate) ?? 0)).toStringAsFixed(2)), style: const TextStyle(color: AppTheme.navyPrimary, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
