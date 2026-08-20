import 'package:flutter/material.dart';
import 'package:frontend/core/config/app_config.dart';
import 'package:frontend/core/theme/app_theme.dart';

class StationAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onLogoPressed;
  final VoidCallback? onSettingsPressed;
  final List<Widget>? actions;

  const StationAppBar({
    super.key,
    this.title = 'PSO Lucky Filling Station',
    this.subtitle,
    this.showBackButton = false,
    this.onLogoPressed,
    this.onSettingsPressed,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(58);

  @override
  Widget build(BuildContext context) {
    final canPop = showBackButton || Navigator.canPop(context);

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        bottom: 6,
        left: 12,
        right: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: const Border(bottom: BorderSide(color: AppTheme.borderLight, width: 0.8)),
      ),
      child: Row(
        children: [
          // Back Button if pushed sub-screen
          if (canPop)
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textDark, size: 22),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: const EdgeInsets.only(right: 6),
            ),

          // Station Brand Logo Avatar (Tapping navigates to Dashboard)
          InkWell(
            onTap: onLogoPressed ?? () {
              if (Navigator.canPop(context)) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.navyDark, AppTheme.navyPrimary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_gas_station_rounded, color: Colors.white, size: 19),
            ),
          ),
          const SizedBox(width: 10),

          // Title & Subtitle / Status Badge
          Expanded(
            child: InkWell(
              onTap: onLogoPressed ?? () {
                if (Navigator.canPop(context)) {
                  Navigator.popUntil(context, (route) => route.isFirst);
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.emeraldGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    subtitle ?? 'Aug 18, 2026 • Shift Active',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w400),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          if (actions != null) ...actions!,

          // Unclustered Settings Button
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppTheme.navyPrimary, size: 21),
            onPressed: onSettingsPressed ?? () => _showSettingsDialog(context),
            tooltip: 'Server Settings',
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  static void _showSettingsDialog(BuildContext context) {
    final ipCtrl = TextEditingController(text: AppConfig.baseUrl);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.navyPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.dns_rounded, color: AppTheme.navyPrimary, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Backend Connection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the FastAPI backend server URL for local network or remote access:',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              const Text('SERVER BASE URL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              const SizedBox(height: 6),
              TextField(
                controller: ipCtrl,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                decoration: InputDecoration(
                  hintText: 'http://192.168.1.5:8000',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: AppTheme.bgLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.navyPrimary, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUrl = ipCtrl.text.trim();
                await AppConfig.setBaseUrl(newUrl);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Server URL set to: ${AppConfig.baseUrl}'),
                    backgroundColor: AppTheme.emeraldGreen,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.navyPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save & Connect', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
