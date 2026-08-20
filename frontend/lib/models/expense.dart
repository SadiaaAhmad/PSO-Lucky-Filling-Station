class ExpenseModel {
  final int id;
  final int? dailyLogId;
  final String accountCode;
  final String accountName;
  final String amount;
  final String description;
  final String paymentMethod;
  final String createdAt;
  final bool isReversed;

  ExpenseModel({
    required this.id,
    this.dailyLogId,
    required this.accountCode,
    required this.accountName,
    required this.amount,
    required this.description,
    required this.paymentMethod,
    required this.createdAt,
    required this.isReversed,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as int,
      dailyLogId: json['daily_log_id'] as int?,
      accountCode: json['account_code'] as String,
      accountName: json['account_name'] as String? ?? '',
      amount: json['amount'].toString(),
      description: json['description'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? 'Cash',
      createdAt: json['created_at'] as String,
      isReversed: json['is_reversed'] as bool? ?? false,
    );
  }
}
