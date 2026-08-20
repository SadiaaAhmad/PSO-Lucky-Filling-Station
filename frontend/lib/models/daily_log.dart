class DailyLogModel {
  final int id;
  final String logDate;
  final String status;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  DailyLogModel({
    required this.id,
    required this.logDate,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyLogModel.fromJson(Map<String, dynamic> json) {
    return DailyLogModel(
      id: json['id'] as int,
      logDate: json['log_date'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyLogModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
