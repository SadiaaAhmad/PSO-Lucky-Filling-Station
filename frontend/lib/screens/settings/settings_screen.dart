import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_config.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/state_views.dart';
import 'package:frontend/core/widgets/station_app_bar.dart';
import 'package:frontend/models/master.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/api_services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;
  String? _error;
  
  StationConfigModel? _config;
  List<TankModel> _tanks = [];
  List<DispensingUnitModel> _units = [];
  String _currentApiUrl = AppConfig.apiBaseUrl;
  bool _isTestingConnection = false;
  String? _connectionStatus;

  List<AccountModel> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final config = await MasterApi.getStationConfig();
      final tanks = await MasterApi.getTanks();
      final units = await MasterApi.getDispensingUnits();
      final accounts = await MasterApi.getAccounts();

      if (mounted) {
        setState(() {
          _config = config;
          _tanks = tanks;
          _units = units;
          _accounts = accounts;
          _currentApiUrl = AppConfig.apiBaseUrl;
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

  Future<void> _confirmDeleteAccount(AccountModel account) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: Text('Are you sure you want to delete/deactivate "${account.accountCode} - ${account.name}" from your Chart of Accounts?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await MasterApi.deleteAccount(account.id);
        _loadSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Account ${account.accountCode} deleted successfully!'), backgroundColor: AppTheme.emeraldGreen),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting account: $e'), backgroundColor: AppTheme.coralRed),
          );
        }
      }
    }
  }

  void _showCreateAccountModal() {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String selectedType = 'EXPENSE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Add New Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    const Text('Account Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(controller: codeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'e.g. 5080', border: OutlineInputBorder())),
                    const SizedBox(height: 12),

                    const Text('Account Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'e.g. Generator Maintenance', border: OutlineInputBorder())),
                    const SizedBox(height: 12),

                    const Text('Account Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'ASSET', child: Text('ASSET (1000s)')),
                        DropdownMenuItem(value: 'LIABILITY', child: Text('LIABILITY (2000s)')),
                        DropdownMenuItem(value: 'EQUITY', child: Text('EQUITY (3000s)')),
                        DropdownMenuItem(value: 'REVENUE', child: Text('REVENUE (4000s)')),
                        DropdownMenuItem(value: 'EXPENSE', child: Text('EXPENSE (5000s)')),
                      ],
                      onChanged: (v) => setModalState(() => selectedType = v ?? 'EXPENSE'),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navyPrimary),
                        onPressed: () async {
                          if (codeCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) return;
                          final nav = Navigator.of(ctx);
                          try {
                            await MasterApi.createAccount(
                              accountCode: codeCtrl.text.trim(),
                              name: nameCtrl.text.trim(),
                              type: selectedType,
                            );
                            nav.pop();
                            _loadSettings();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.coralRed));
                            }
                          }
                        },
                        child: const Text('Save Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editProfileModal() {
    if (_config == null) return;
    final nameCtrl = TextEditingController(text: _config!.stationName);
    final idCtrl = TextEditingController(text: _config!.stationId);
    final addrCtrl = TextEditingController(text: _config!.address);
    final licCtrl = TextEditingController(text: _config!.licenseNo);
    final phoneCtrl = TextEditingController(text: _config!.contactPhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edit Station Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
                const SizedBox(height: 16),

                const Text('Station Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(controller: nameCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),
                const SizedBox(height: 12),

                const Text('Station ID / Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(controller: idCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),
                const SizedBox(height: 12),

                const Text('Physical Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(controller: addrCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),
                const SizedBox(height: 12),

                const Text('License / Explosive No', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(controller: licCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),
                const SizedBox(height: 12),

                const Text('Contact Phone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navyPrimary),
                    onPressed: () async {
                      final navigator = Navigator.of(ctx);
                      try {
                        await MasterApi.updateStationConfig({
                          'station_name': nameCtrl.text.trim(),
                          'station_id': idCtrl.text.trim(),
                          'address': addrCtrl.text.trim(),
                          'license_no': licCtrl.text.trim(),
                          'contact_phone': phoneCtrl.text.trim(),
                        });
                        navigator.pop();
                        _loadSettings();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Station profile updated!'), backgroundColor: AppTheme.emeraldGreen)
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.coralRed));
                        }
                      }
                    },
                    child: const Text('Save Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _editPricingModal() {
    if (_config == null) return;
    final hsdCtrl = TextEditingController(text: _config!.hsdCurrentRate);
    final pmgCtrl = TextEditingController(text: _config!.pmgCurrentRate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Update Fuel Rates (PKR/L)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
              const SizedBox(height: 16),

              const Text('High Speed Diesel (HSD) Rate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: hsdCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '306.50'),
              ),
              const SizedBox(height: 14),

              const Text('Super Petrol (PMG) Rate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: pmgCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '310.20'),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navyPrimary),
                  onPressed: () async {
                    final navigator = Navigator.of(ctx);
                    try {
                      await MasterApi.updateStationConfig({
                        'hsd_current_rate': hsdCtrl.text.trim(),
                        'pmg_current_rate': pmgCtrl.text.trim(),
                      });
                      navigator.pop();
                      _loadSettings();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fuel rates updated!'), backgroundColor: AppTheme.emeraldGreen)
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.coralRed));
                      }
                    }
                  },
                  child: const Text('Apply Rates', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _editApiUrlModal() {
    final urlCtrl = TextEditingController(text: _currentApiUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change API Backend URL'),
        content: TextField(
          controller: urlCtrl,
          decoration: const InputDecoration(
            hintText: 'http://192.168.1.5:8000',
            labelText: 'Server URL',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navyPrimary),
            onPressed: () async {
              final newUrl = urlCtrl.text.trim();
              if (newUrl.isNotEmpty) {
                final nav = Navigator.of(ctx);
                await AppConfig.setApiBaseUrl(newUrl);
                nav.pop();
                setState(() => _currentApiUrl = newUrl);
                _loadSettings();
              }
            },
            child: const Text('Save & Reconnect', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = null;
    });

    try {
      final success = await ApiClient.testConnection();
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
          _connectionStatus = success ? 'Connected successfully! (HTTP 200 OK)' : 'Failed to reach server.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTestingConnection = false;
          _connectionStatus = 'Connection error: $e';
        });
      }
    }
  }

  Future<void> _autoScanLan() async {
    setState(() {
      _isTestingConnection = true;
      _connectionStatus = 'Scanning local Wi-Fi network for FastAPI server...';
    });

    final found = await ApiClient.autoDiscoverBackend();
    if (mounted) {
      setState(() {
        _isTestingConnection = false;
        _currentApiUrl = AppConfig.apiBaseUrl;
        _connectionStatus = found != null 
            ? 'Connected to server at $found' 
            : 'Auto-scan complete. Could not find server on local subnet.';
      });
      if (found != null) {
        _loadSettings();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: StationAppBar(subtitle: 'Station Configuration', showBackButton: true),
        body: LoadingView(message: 'Loading station configuration...'),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: const StationAppBar(subtitle: 'Station Configuration', showBackButton: true),
        body: ErrorStateView(errorMessage: _error!, onRetry: _loadSettings),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: const StationAppBar(subtitle: 'Station Configuration', showBackButton: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Station Profile Card
            _buildSectionHeader('Station Profile', Icons.local_gas_station_rounded, onEdit: _editProfileModal),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                children: [
                  _buildProfileRow('Station Name', _config?.stationName ?? 'PSO Lucky Filling Station'),
                  const Divider(height: 1),
                  _buildProfileRow('Station ID', _config?.stationId ?? 'PSO-LFS-4821'),
                  const Divider(height: 1),
                  _buildProfileRow('Address', _config?.address ?? 'Main National Highway, Sadiqabad'),
                  const Divider(height: 1),
                  _buildProfileRow('License No', _config?.licenseNo ?? 'EXPL-PK-98234'),
                  const Divider(height: 1),
                  _buildProfileRow('Contact Phone', _config?.contactPhone ?? '+92 300 1234567'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Fuel Pricing Card
            _buildSectionHeader('Fuel Rates & Pricing', Icons.price_change_rounded, onEdit: _editPricingModal),
            Row(
              children: [
                Expanded(
                  child: _buildPriceCard(
                    'HSD (Diesel)',
                    '${_config?.hsdCurrentRate ?? "306.50"} PKR/L',
                    AppTheme.emeraldGreen,
                    AppTheme.emeraldBg,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPriceCard(
                    'PMG (Petrol)',
                    '${_config?.pmgCurrentRate ?? "310.20"} PKR/L',
                    AppTheme.navyPrimary,
                    AppTheme.navyLightBg,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Storage Tanks
            _buildSectionHeader('Storage Tanks (UST)', Icons.storage_rounded),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Column(
                children: _tanks.map((t) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.navyLightBg,
                    child: const Icon(Icons.storage, color: AppTheme.navyPrimary, size: 20),
                  ),
                  title: Text(t.tankName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('Product: ${t.productCode}', style: const TextStyle(fontSize: 11)),
                  trailing: Text(
                    '${t.capacityLiters} L',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.navyPrimary),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Dispensing Units
            _buildSectionHeader('Dispensing Nozzles (6 Units)', Icons.local_gas_station_outlined),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _units.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final u = _units[i];
                  return ListTile(
                    dense: true,
                    title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text('Tank: ${u.tankName}', style: const TextStyle(fontSize: 11)),
                    trailing: Chip(
                      label: Text(u.productCode, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      backgroundColor: u.productCode == 'HSD' ? AppTheme.emeraldBg : AppTheme.navyLightBg,
                      padding: EdgeInsets.zero,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Chart of Accounts Management Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('Chart of Accounts (${_accounts.length})', Icons.account_balance_wallet_rounded),
                TextButton.icon(
                  onPressed: _showCreateAccountModal,
                  icon: const Icon(Icons.add_circle_outline, size: 16, color: AppTheme.navyPrimary),
                  label: const Text('Add Account', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary)),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: _accounts.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No custom accounts found.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _accounts.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final acc = _accounts[i];
                        return ListTile(
                          dense: true,
                          title: Text(
                            '${acc.accountCode} - ${acc.name}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyPrimary),
                          ),
                          subtitle: Text(
                            'Type: ${acc.type}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.coralRed, size: 20),
                            tooltip: 'Delete Account',
                            onPressed: () => _confirmDeleteAccount(acc),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),

            // Backend Connectivity Card
            _buildSectionHeader('Backend Connection', Icons.lan_rounded),
            Container(
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
                    children: [
                      const Icon(Icons.link_rounded, color: AppTheme.navyPrimary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentApiUrl,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18, color: AppTheme.textMuted),
                        onPressed: _editApiUrlModal,
                      ),
                    ],
                  ),
                  if (_connectionStatus != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _connectionStatus!.contains('success') || _connectionStatus!.contains('Connected')
                            ? AppTheme.emeraldBg 
                            : AppTheme.coralBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _connectionStatus!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _connectionStatus!.contains('success') || _connectionStatus!.contains('Connected')
                              ? AppTheme.emeraldGreen 
                              : AppTheme.coralRed,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isTestingConnection ? null : _testConnection,
                          icon: _isTestingConnection 
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('Test Connection', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.navyPrimary),
                          onPressed: _isTestingConnection ? null : _autoScanLan,
                          icon: const Icon(Icons.wifi_find, size: 16, color: Colors.white),
                          label: const Text('Auto-Scan LAN', style: TextStyle(fontSize: 12, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {VoidCallback? onEdit}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.navyPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.navyPrimary),
              ),
            ],
          ),
          if (onEdit != null)
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 14, color: AppTheme.navyPrimary),
              label: const Text('Edit', style: TextStyle(fontSize: 12, color: AppTheme.navyPrimary, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(String product, String rate, Color color, Color bg) {
    return Container(
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
              Text(product, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(Icons.local_gas_station, size: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(rate, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
