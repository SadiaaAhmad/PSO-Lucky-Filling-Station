class EmbeddedLogSummary {
  final String grossLitersDispensed;
  final String cardSalesPkr;
  final String creditSalesPkr;
  final String creditRecoveriesPkr;
  final String expensesPkr;

  EmbeddedLogSummary({
    required this.grossLitersDispensed,
    required this.cardSalesPkr,
    required this.creditSalesPkr,
    required this.creditRecoveriesPkr,
    required this.expensesPkr,
  });

  factory EmbeddedLogSummary.fromJson(Map<String, dynamic> json) {
    return EmbeddedLogSummary(
      grossLitersDispensed: json['gross_liters_dispensed']?.toString() ?? '0.00',
      cardSalesPkr: json['card_sales_pkr']?.toString() ?? '0.00',
      creditSalesPkr: json['credit_sales_pkr']?.toString() ?? '0.00',
      creditRecoveriesPkr: json['credit_recoveries_pkr']?.toString() ?? '0.00',
      expensesPkr: json['expenses_pkr']?.toString() ?? '0.00',
    );
  }
}

class DailyLogModel {
  final int id;
  final String logDate;
  final String status;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final EmbeddedLogSummary? summary;

  DailyLogModel({
    required this.id,
    required this.logDate,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.summary,
  });

  factory DailyLogModel.fromJson(Map<String, dynamic> json) {
    return DailyLogModel(
      id: json['id'] as int,
      logDate: json['log_date'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      summary: json['summary'] != null ? EmbeddedLogSummary.fromJson(json['summary']) : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyLogModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
