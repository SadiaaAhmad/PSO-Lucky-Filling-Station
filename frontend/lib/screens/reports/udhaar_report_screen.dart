import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/station_app_bar.dart';
import 'package:frontend/core/widgets/state_views.dart';
import 'package:frontend/core/utils/formatters.dart';
import 'package:frontend/models/customer.dart';
import 'package:frontend/services/api_services.dart';
import 'package:frontend/screens/accounts/customer_detail_screen.dart';

class UdhaarReportScreen extends StatefulWidget {
  const UdhaarReportScreen({super.key});

  @override
  State<UdhaarReportScreen> createState() => _UdhaarReportScreenState();
}

class _UdhaarReportScreenState extends State<UdhaarReportScreen> {
  bool _isLoading = true;
  String? _error;
  List<CustomerModel> _customers = [];
  Map<int, CustomerBalanceModel> _balances = {};

  @override
  void initState() {
    super.initState();
    _fetchUdhaarData();
  }

  Future<void> _fetchUdhaarData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final customers = await CustomerApi.getCustomers();
      final balances = <int, CustomerBalanceModel>{};
      
      for (var c in customers) {
        balances[c.id] = await CustomerApi.getCustomerBalance(c.id);
      }
      
      setState(() {
        _customers = customers;
        _balances = balances;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalReceivables = 0.0;
    for (var b in _balances.values) {
      totalReceivables += (double.tryParse(b.currentBalance) ?? 0);
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: const StationAppBar(
        title: 'Customer Udhaar Report',
        subtitle: 'Receivables & Credit Limits',
        showBackButton: true,
      ),
      body: _isLoading
          ? const LoadingView(message: 'Loading udhaar report...')
          : _error != null
              ? ErrorStateView(errorMessage: _error!, onRetry: _fetchUdhaarData)
              : RefreshIndicator(
                  onRefresh: _fetchUdhaarData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Total Receivables Header Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.navyDark,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('TOTAL OUTSTANDING RECEIVABLES', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white70)),
                              const SizedBox(height: 4),
                              Text(Formatters.formatPKR(totalReceivables), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
            
                        const Text('Customer Credit Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                        const SizedBox(height: 10),
                        if (_customers.isEmpty)
                          const EmptyStateView(message: 'No customers found.')
                        else
                          ..._customers.map((c) {
                            final b = _balances[c.id];
                            if (b == null) return const SizedBox.shrink();
                            
                            final pct = (double.tryParse(b.creditLimit) ?? 0) > 0 ? ((double.tryParse(b.currentBalance) ?? 0) / (double.tryParse(b.creditLimit) ?? 1)) : 0.0;
                            String status = 'NORMAL';
                            Color statusColor = AppTheme.emeraldGreen;
                            if (pct > 0.9) {
                              status = 'OVER LIMIT';
                              statusColor = AppTheme.coralRed;
                            } else if (pct > 0.75) {
                              status = 'NEAR LIMIT';
                              statusColor = AppTheme.amberWarning;
                            }

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => CustomerDetailScreen(customerId: c.id)),
                                ).then((_) => _fetchUdhaarData());
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
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
                                            c.name,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                          child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Account: ${c.accountNo}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                        Text('Outstanding: ${Formatters.formatPKR(b.currentBalance)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    LinearProgressIndicator(value: pct.clamp(0.0, 1.0), backgroundColor: AppTheme.bgLight, color: statusColor, minHeight: 4),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Limit: ${Formatters.formatPKR(b.creditLimit)}', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                        Text('Available: ${Formatters.formatPKR(b.availableCredit)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.emeraldGreen)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),
                ),
    );
  }
}
