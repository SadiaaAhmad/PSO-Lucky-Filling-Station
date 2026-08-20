class CreditTransactionModel {
  final int id;
  final int dailyLogId;
  final int customerId;
  final int? vehicleId;
  final int? productId;
  final String transactionType;
  final String liters;
  final String ratePerLtr;
  final String amount;
  final String? reference;
  final String createdAt;

  CreditTransactionModel({
    required this.id,
    required this.dailyLogId,
    required this.customerId,
    this.vehicleId,
    this.productId,
    required this.transactionType,
    required this.liters,
    required this.ratePerLtr,
    required this.amount,
    this.reference,
    required this.createdAt,
  });

  factory CreditTransactionModel.fromJson(Map<String, dynamic> json) {
    return CreditTransactionModel(
      id: json['id'] as int,
      dailyLogId: json['daily_log_id'] as int,
      customerId: json['customer_id'] as int,
      vehicleId: json['vehicle_id'] as int?,
      productId: json['product_id'] as int?,
      transactionType: json['transaction_type'] as String,
      liters: json['liters'].toString(),
      ratePerLtr: json['rate_per_ltr'].toString(),
      amount: json['amount'].toString(),
      reference: json['reference'] as String?,
      createdAt: json['created_at'] as String,
    );
  }
}

class CardTransactionModel {
  final int id;
  final int dailyLogId;
  final String cardType;
  final String liters;
  final String amount;
  final String bankCharges;

  CardTransactionModel({
    required this.id,
    required this.dailyLogId,
    required this.cardType,
    required this.liters,
    required this.amount,
    required this.bankCharges,
  });

  factory CardTransactionModel.fromJson(Map<String, dynamic> json) {
    return CardTransactionModel(
      id: json['id'] as int,
      dailyLogId: json['daily_log_id'] as int,
      cardType: json['card_type'] as String,
      liters: json['liters'].toString(),
      amount: json['amount'].toString(),
      bankCharges: json['bank_charges'].toString(),
    );
  }
}
