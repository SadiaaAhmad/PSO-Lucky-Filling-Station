class NozzleReadingModel {
  final int id;
  final int dailyLogId;
  final int unitId;
  final String openingReading;
  final String closingReading;
  final String grossSaleLiters;

  NozzleReadingModel({
    required this.id,
    required this.dailyLogId,
    required this.unitId,
    required this.openingReading,
    required this.closingReading,
    required this.grossSaleLiters,
  });

  factory NozzleReadingModel.fromJson(Map<String, dynamic> json) {
    return NozzleReadingModel(
      id: json['id'] as int,
      dailyLogId: json['daily_log_id'] as int,
      unitId: json['unit_id'] as int,
      openingReading: json['opening_reading'].toString(),
      closingReading: json['closing_reading'].toString(),
      grossSaleLiters: json['gross_sale_liters'].toString(),
    );
  }
}

class FuelPurchaseModel {
  final int id;
  final int dailyLogId;
  final int productId;
  final int tankId;
  final String? invoiceNo;
  final String purchaseLiters;
  final String purchaseRate;
  final String saleRate;
  final String rateDiffPerLtr;
  final String rateDiffAmount;

  FuelPurchaseModel({
    required this.id,
    required this.dailyLogId,
    required this.productId,
    required this.tankId,
    this.invoiceNo,
    required this.purchaseLiters,
    required this.purchaseRate,
    required this.saleRate,
    required this.rateDiffPerLtr,
    required this.rateDiffAmount,
  });

  factory FuelPurchaseModel.fromJson(Map<String, dynamic> json) {
    return FuelPurchaseModel(
      id: json['id'] as int,
      dailyLogId: json['daily_log_id'] as int,
      productId: json['product_id'] as int,
      tankId: json['tank_id'] as int,
      invoiceNo: json['invoice_no'] as String?,
      purchaseLiters: json['purchase_liters'].toString(),
      purchaseRate: json['purchase_rate'].toString(),
      saleRate: json['sale_rate'].toString(),
      rateDiffPerLtr: json['rate_diff_per_ltr'].toString(),
      rateDiffAmount: json['rate_diff_amount'].toString(),
    );
  }
}
