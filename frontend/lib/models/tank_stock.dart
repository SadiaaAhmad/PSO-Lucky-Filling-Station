class DailyTankStockModel {
  final int id;
  final int dailyLogId;
  final int tankId;
  final int productId;
  final String openingDipLiters;
  final String stockInPurchaseLiters;
  final String testingLossLiters;
  final String netSalesLiters;
  final String expectedClosingLiters;
  final String actualDipLiters;
  final String stockGainLossLiters;
  final String purchaseRate;
  final String stockGainLossValuePkr;

  DailyTankStockModel({
    required this.id,
    required this.dailyLogId,
    required this.tankId,
    required this.productId,
    required this.openingDipLiters,
    required this.stockInPurchaseLiters,
    required this.testingLossLiters,
    required this.netSalesLiters,
    required this.expectedClosingLiters,
    required this.actualDipLiters,
    required this.stockGainLossLiters,
    required this.purchaseRate,
    required this.stockGainLossValuePkr,
  });

  factory DailyTankStockModel.fromJson(Map<String, dynamic> json) {
    return DailyTankStockModel(
      id: json['id'] as int,
      dailyLogId: json['daily_log_id'] as int,
      tankId: json['tank_id'] as int,
      productId: json['product_id'] as int,
      openingDipLiters: json['opening_dip_liters'].toString(),
      stockInPurchaseLiters: json['stock_in_purchase_liters'].toString(),
      testingLossLiters: json['testing_loss_liters'].toString(),
      netSalesLiters: json['net_sales_liters'].toString(),
      expectedClosingLiters: json['expected_closing_liters'].toString(),
      actualDipLiters: json['actual_dip_liters'].toString(),
      stockGainLossLiters: json['stock_gain_loss_liters'].toString(),
      purchaseRate: json['purchase_rate'].toString(),
      stockGainLossValuePkr: json['stock_gain_loss_value_pkr'].toString(),
    );
  }
}

class LatestTankStockModel {
  final int tankId;
  final String tankName;
  final String productCode;
  final String capacityLiters;
  final String actualDipLiters;
  final String purchaseRate;
  final String stockValuePkr;
  final String logDate;

  LatestTankStockModel({
    required this.tankId,
    required this.tankName,
    required this.productCode,
    required this.capacityLiters,
    required this.actualDipLiters,
    required this.purchaseRate,
    required this.stockValuePkr,
    required this.logDate,
  });

  factory LatestTankStockModel.fromJson(Map<String, dynamic> json) {
    return LatestTankStockModel(
      tankId: json['tank_id'] as int,
      tankName: json['tank_name'] as String,
      productCode: json['product_code'] as String,
      capacityLiters: json['capacity_liters'].toString(),
      actualDipLiters: json['actual_dip_liters'].toString(),
      purchaseRate: json['purchase_rate'].toString(),
      stockValuePkr: json['stock_value_pkr'].toString(),
      logDate: json['log_date'] as String? ?? '',
    );
  }
}
