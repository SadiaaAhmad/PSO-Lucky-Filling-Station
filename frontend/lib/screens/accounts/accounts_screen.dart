import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/formatters.dart';
import 'package:frontend/core/widgets/state_views.dart';
import 'package:frontend/core/widgets/station_app_bar.dart';
import 'package:frontend/models/customer.dart';
import 'package:frontend/services/api_services.dart';
import 'package:frontend/screens/accounts/customer_detail_screen.dart';
import 'package:frontend/core/utils/app_logger.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  bool _isLoading = true;
  String? _error;
  List<CustomerModel> _allCustomers = [];
  List<CustomerModel> _filteredCustomers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = _allCustomers;
      } else {
        _filteredCustomers = _allCustomers.where((c) {
          return c.name.toLowerCase().contains(query) || 
                 c.accountNo.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _fetchCustomers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    AppLogger.data('[API] Fetching customers list');

    try {
      final list = await CustomerApi.getCustomers();
      setState(() {
        _allCustomers = list;
        _filteredCustomers = list;
        _isLoading = false;
      });
      AppLogger.data('[DATA] Fetched ${list.length} customers successfully');
    } catch (e) {
      AppLogger.error('[ERROR] Failed to fetch customers: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showNewCustomerModal() {
    final accountNoCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final creditLimitCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
                      const Text('New Customer Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('Account Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: accountNoCtrl,
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. CUST-1001'),
                  ),
                  const SizedBox(height: 12),
                  
                  const Text('Customer Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Enter full name / company'),
                  ),
                  const SizedBox(height: 12),

                  const Text('Phone Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. 0300-1234567'),
                  ),
                  const SizedBox(height: 12),

                  const Text('Credit Limit (PKR)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: creditLimitCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'e.g. 500000'),
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
                        if (accountNoCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) return;
                        final navigator = Navigator.of(ctx);
                        try {
                          final limit = double.tryParse(creditLimitCtrl.text.trim()) ?? 0.0;
                          await CustomerApi.createCustomer(
                            accountNo: accountNoCtrl.text.trim(),
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            creditLimit: limit.toStringAsFixed(2),
                          );
                          navigator.pop();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Customer account created successfully!'), backgroundColor: AppTheme.emeraldGreen)
                            );
                          }
                          _fetchCustomers();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.coralRed));
                          }
                        }
                      },
                      child: const Text('Save Customer Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: const StationAppBar(subtitle: 'Customer Accounts'),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _showNewCustomerModal,
        backgroundColor: AppTheme.navyPrimary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('New Account', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or account no...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.borderLight),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const LoadingView(message: 'Loading customers...')
                  : _error != null
                      ? ErrorStateView(errorMessage: _error!, onRetry: _fetchCustomers)
                      : _filteredCustomers.isEmpty
                          ? const EmptyStateView(
                              title: 'No Customers Found',
                              message: 'Tap New Account to add a customer.',
                            )
                          : RefreshIndicator(
                              onRefresh: _fetchCustomers,
                              child: ListView.builder(
                                padding: EdgeInsets.fromLTRB(14, 0, 14, MediaQuery.of(context).padding.bottom + 88),
                                itemCount: _filteredCustomers.length,
                                itemBuilder: (context, index) {
                                  final customer = _filteredCustomers[index];
                                  return _buildCustomerCard(customer);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(CustomerModel customer) {
    // Determine balance coloring. Using dummy logic: if balance approaches limit, warning color.
    final limit = double.tryParse(customer.creditLimit) ?? 1.0; 
    final isNearLimit = false;
    final balanceColor = AppTheme.textDark;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerDetailScreen(customerId: customer.id),
          ),
        ).then((_) => _fetchCustomers());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.navyPrimary.withOpacity(0.1),
              child: const Icon(Icons.business_rounded, color: AppTheme.navyPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customer.accountNo,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Credit Limit', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                const SizedBox(height: 2),
                Text(
                  Formatters.formatPKR(limit),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: balanceColor),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
