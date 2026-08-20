class ActivityItem {
  final int id;
  final String activityType;
  final String title;
  final String subtitle;
  final String? amount;
  final String amountSign; // '+' or '-'
  final String timestamp;
  final String entityType;
  final int entityId;
  final int? dailyLogId;
  
  ActivityItem({required this.id, required this.activityType, required this.title, required this.subtitle, this.amount, required this.amountSign, required this.timestamp, required this.entityType, required this.entityId, this.dailyLogId});
  
  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id'] as int,
      activityType: json['activity_type'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      amount: json['amount']?.toString(),
      amountSign: json['amount_sign'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
      entityType: json['entity_type'] as String? ?? '',
      entityId: json['entity_id'] as int? ?? 0,
      dailyLogId: json['daily_log_id'] as int?,
    );
  }
}
