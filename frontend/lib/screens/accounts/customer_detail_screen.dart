import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/station_app_bar.dart';
import 'package:frontend/core/widgets/state_views.dart';
import 'package:frontend/core/utils/formatters.dart';
import 'package:frontend/models/customer.dart';
import 'package:frontend/models/transactions.dart';
import 'package:frontend/models/daily_log.dart';
import 'package:frontend/models/master.dart';
import 'package:frontend/services/api_services.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  bool _isLoading = true;
  String? _error;
  CustomerModel? _customer;
  CustomerBalanceModel? _balance;
  List<CreditTransactionModel> _ledger = [];
  
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _litersCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _vehicleNoCtrl = TextEditingController();
  final _driverNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      _customer = await CustomerApi.getCustomerById(widget.customerId);
      _balance = await CustomerApi.getCustomerBalance(widget.customerId);
      _ledger = await CustomerApi.getCustomerLedger(widget.customerId);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<DailyLogModel?> _getOpenLog() async {
    try {
      final logs = await DailyLogApi.getDailyLogs(limit: 10);
      final openLogs = logs.where((l) => l.status == 'OPEN' || l.status == 'DRAFT').toList();
      if (openLogs.isNotEmpty) return openLogs.first;
      if (logs.isNotEmpty) return logs.first;
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _openCreditSaleModal() async {
    final openLog = await _getOpenLog();
    if (openLog == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No open log found for today.'), backgroundColor: AppTheme.coralRed));
      return;
    }

    List<ProductModel> products = [];
    try {
      products = await MasterApi.getProducts();
    } catch (_) {}

    CustomerVehicleModel? selectedVehicle = _customer!.vehicles.isNotEmpty ? _customer!.vehicles.first : null;
    ProductModel? selectedProduct = products.isNotEmpty ? products.first : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateModal) => SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 20, right: 20, top: 20
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Record Credit Sale (${_customer!.name})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text('Vehicle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    DropdownButtonFormField<CustomerVehicleModel>(
                      value: selectedVehicle,
                      items: _customer!.vehicles.map((v) => DropdownMenuItem(value: v, child: Text(v.vehicleNo))).toList(),
                      onChanged: (v) => setStateModal(() => selectedVehicle = v),
                      isExpanded: true,
                    ),
                    const SizedBox(height: 12),
                    const Text('Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    DropdownButtonFormField<ProductModel>(
                      value: selectedProduct,
                      items: products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                      onChanged: (v) => setStateModal(() => selectedProduct = v),
                      isExpanded: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _amountCtrl, decoration: const InputDecoration(labelText: 'Amount (PKR)', floatingLabelBehavior: FloatingLabelBehavior.always), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(controller: _litersCtrl, decoration: const InputDecoration(labelText: 'Liters', floatingLabelBehavior: FloatingLabelBehavior.always), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(controller: _rateCtrl, decoration: const InputDecoration(labelText: 'Rate', floatingLabelBehavior: FloatingLabelBehavior.always), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(controller: _refCtrl, decoration: const InputDecoration(labelText: 'Reference', floatingLabelBehavior: FloatingLabelBehavior.always)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedVehicle == null || selectedProduct == null) return;
                          final navigator = Navigator.of(ctx);
                          try {
                            await CreditApi.recordCreditSale(
                              dailyLogId: openLog.id,
                              customerId: widget.customerId,
                              vehicleId: selectedVehicle!.id,
                              productId: selectedProduct!.id,
                              liters: _litersCtrl.text,
                              ratePerLtr: _rateCtrl.text,
                              amount: _amountCtrl.text,
                              reference: _refCtrl.text,
                            );
                            navigator.pop();
                            _amountCtrl.clear(); _litersCtrl.clear(); _rateCtrl.clear(); _refCtrl.clear();
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credit Sale Recorded!'), backgroundColor: AppTheme.emeraldGreen));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.coralRed));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navyPrimary),
                        child: const Text('Post Credit Sale', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        );
      },
    );
  }

  Future<void> _openRecoveryModal() async {
    final openLog = await _getOpenLog();
    if (openLog == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No open log found for today.'), backgroundColor: AppTheme.coralRed));
      return;
    }

    String selectedMethod = 'CASH';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateModal) => SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 20, right: 20, top: 20
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Record Recovery (${_customer!.name})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text('Payment Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                    DropdownButtonFormField<String>(
                      value: selectedMethod,
                      items: ['CASH', 'BANK'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                      onChanged: (v) => setStateModal(() => selectedMethod = v!),
                      isExpanded: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _amountCtrl, decoration: const InputDecoration(labelText: 'Amount (PKR)', floatingLabelBehavior: FloatingLabelBehavior.always), keyboardType: TextInputType.number),
                    const SizedBox(height: 12),
                    TextField(controller: _refCtrl, decoration: const InputDecoration(labelText: 'Reference', floatingLabelBehavior: FloatingLabelBehavior.always)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final navigator = Navigator.of(ctx);
                          try {
                            await CreditApi.recordCreditRecovery(
                              dailyLogId: openLog.id,
                              customerId: widget.customerId,
                              amount: _amountCtrl.text,
                              paymentAccountCode: selectedMethod == 'CASH' ? '1010' : '1020',
                              reference: _refCtrl.text,
                            );
                            navigator.pop();
                            _amountCtrl.clear(); _refCtrl.clear();
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recovery Recorded!'), backgroundColor: AppTheme.emeraldGreen));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.coralRed));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen),
                        child: const Text('Save Recovery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        );
      },
    );
  }

  Future<void> _openAddVehicleModal() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 20, right: 20, top: 20
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Vehicle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(controller: _vehicleNoCtrl, decoration: const InputDecoration(labelText: 'Vehicle No', floatingLabelBehavior: FloatingLabelBehavior.always)),
                  const SizedBox(height: 12),
                  TextField(controller: _driverNameCtrl, decoration: const InputDecoration(labelText: 'Driver Name (Optional)', floatingLabelBehavior: FloatingLabelBehavior.always)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final navigator = Navigator.of(ctx);
                        try {
                          await CustomerApi.addVehicle(widget.customerId, vehicleNo: _vehicleNoCtrl.text, driverName: _driverNameCtrl.text);
                          navigator.pop();
                          _vehicleNoCtrl.clear(); _driverNameCtrl.clear();
                          _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle added!'), backgroundColor: AppTheme.emeraldGreen));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.coralRed));
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navyPrimary),
                      child: const Text('Save Vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          )
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingView(message: 'Loading customer detail...'));
    if (_error != null) return Scaffold(body: ErrorStateView(errorMessage: _error!, onRetry: _loadData));
    if (_customer == null || _balance == null) return const Scaffold(body: EmptyStateView(message: 'Customer not found.'));

    final bal = _balance!;
    final currentBal = double.tryParse(bal.currentBalance) ?? 0.0;
    final credLimit = double.tryParse(bal.creditLimit) ?? 0.0;
    final isHigh = credLimit > 0 && currentBal > (credLimit * 0.8);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: StationAppBar(
        title: _customer!.name,
        subtitle: _customer!.accountNo,
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
                  onPressed: _openRecoveryModal,
                  icon: const Icon(Icons.arrow_downward_rounded, color: AppTheme.emeraldGreen, size: 16),
                  label: const Text('Record Recovery', style: TextStyle(color: AppTheme.emeraldGreen, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openCreditSaleModal,
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 16, color: Colors.white),
                  label: const Text('Credit Sale', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navyPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Outstanding Balance Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderLight)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('OUTSTANDING BALANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
                      if (isHigh)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.coralBg, borderRadius: BorderRadius.circular(4)),
                          child: const Text('HIGH UTILIZATION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.coralRed)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(Formatters.formatPKR(bal.currentBalance), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isHigh ? AppTheme.coralRed : AppTheme.navyPrimary)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Credit Limit: ${Formatters.formatPKR(bal.creditLimit)}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      Text('Available: ${Formatters.formatPKR(bal.availableCredit)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Registered Vehicles Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Registered Vehicles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                TextButton(onPressed: _openAddVehicleModal, child: const Text('Add Vehicle')),
              ],
            ),
            const SizedBox(height: 8),
            if (_customer!.vehicles.isEmpty)
              const Text('No vehicles registered.', style: TextStyle(color: AppTheme.textMuted))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _customer!.vehicles.map((v) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.borderLight)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_car_rounded, size: 14, color: AppTheme.navyPrimary),
                      const SizedBox(width: 6),
                      Text(v.vehicleNo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    ],
                  ),
                )).toList(),
              ),
            const SizedBox(height: 20),

            // Udhaar Ledger History
            const Text('Udhaar Ledger History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 10),
            if (_ledger.isEmpty)
              const EmptyStateView(message: 'No transactions found.', icon: Icons.history)
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ledger.length,
                itemBuilder: (ctx, i) {
                  final tx = _ledger[i];
                  final isSale = tx.transactionType == 'SALE';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.borderLight)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(Formatters.formatDate(tx.createdAt), style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                              const SizedBox(height: 4),
                              Text('${isSale ? 'Credit Sale' : 'Recovery'} (${tx.reference})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark), overflow: TextOverflow.ellipsis),
                              if (isSale) ...[
                                const SizedBox(height: 4),
                                Text('${tx.liters ?? 0} L @ ${tx.ratePerLtr ?? 0} PKR', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              ]
                            ],
                          ),
                        ),
                        Text('${isSale ? '-' : '+'} ${Formatters.formatPKR(tx.amount)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSale ? AppTheme.coralRed : AppTheme.emeraldGreen)),
                      ],
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
