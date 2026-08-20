import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/utils/formatters.dart';
import 'package:frontend/core/widgets/state_views.dart';
import 'package:frontend/core/widgets/station_app_bar.dart';
import 'package:frontend/models/activity.dart';
import 'package:frontend/services/api_services.dart';
import 'package:frontend/core/utils/app_logger.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  String? _error;
  List<ActivityItem> _activities = [];
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _fetchActivity();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isFetchingMore && _hasMore && !_isLoading) {
        _loadMoreActivity();
      }
    }
  }

  Future<void> _fetchActivity() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _hasMore = true;
    });
    
    AppLogger.data('[API] Fetching recent activity');

    try {
      final list = await ActivityApi.getRecentActivity(skip: 0, limit: _pageSize);
      setState(() {
        _activities = list;
        _isLoading = false;
        if (list.length < _pageSize) {
          _hasMore = false;
        }
      });
      AppLogger.data('[DATA] Fetched ${list.length} activities');
    } catch (e) {
      AppLogger.error('[ERROR] Failed to fetch activity: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreActivity() async {
    if (_isFetchingMore || !_hasMore) return;

    setState(() {
      _isFetchingMore = true;
    });

    try {
      final nextList = await ActivityApi.getRecentActivity(skip: _activities.length, limit: _pageSize);
      setState(() {
        _isFetchingMore = false;
        if (nextList.isEmpty) {
          _hasMore = false;
        } else {
          _activities.addAll(nextList);
          if (nextList.length < _pageSize) {
            _hasMore = false;
          }
        }
      });
    } catch (e) {
      AppLogger.error('[ERROR] Failed to load more activity: $e');
      setState(() {
        _isFetchingMore = false;
      });
    }
  }

  void _clearAllActivity() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Recent Activity?'),
        content: const Text('Are you sure you want to clear all activity items from your view?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralRed),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _activities.clear();
                _hasMore = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Activity view cleared!'), backgroundColor: AppTheme.emeraldGreen)
              );
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteActivityItem(int index) {
    setState(() {
      _activities.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activity item removed.'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: StationAppBar(
        subtitle: 'Activity History',
        showBackButton: true,
        actions: [
          if (_activities.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
              onPressed: _clearAllActivity,
              tooltip: 'Clear All Activity',
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const LoadingView(message: 'Loading activity history...')
            : _error != null
                ? ErrorStateView(errorMessage: _error!, onRetry: _fetchActivity)
                : _activities.isEmpty
                    ? const EmptyStateView(
                        title: 'No Activity Found',
                        message: 'No recent activity is available.',
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchActivity,
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(14, 14, 14, MediaQuery.of(context).padding.bottom + 24),
                          itemCount: _activities.length + (_isFetchingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _activities.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              );
                            }
                            final activity = _activities[index];
                            return _buildActivityCard(activity, index);
                          },
                        ),
                      ),
      ),
    );
  }

  Widget _buildActivityCard(ActivityItem activity, int index) {
    return Dismissible(
      key: Key('activity_${activity.id}_${activity.timestamp}_$index'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => _deleteActivityItem(index),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppTheme.coralRed,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.coralRed,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.navyPrimary.withValues(alpha: 0.1),
              child: const Icon(Icons.history_rounded, color: AppTheme.navyPrimary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (activity.subtitle.isNotEmpty)
                    Text(
                      activity.subtitle,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    Formatters.formatDate(activity.timestamp),
                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (activity.amount != null)
                  Text(
                    Formatters.formatPKR(activity.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.navyPrimary),
                  ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => _deleteActivityItem(index),
                  child: const Padding(
                    padding: EdgeInsets.all(2.0),
                    child: Icon(Icons.close, size: 16, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
