import 'package:frontend/models/transactions.dart';

class NozzleReadingDetail {
  final int id;
  final int unitId;
  final String unitName;
  final String productCode;
  final String openingReading;
  final String closingReading;
  final String grossSaleLiters;
  final String saleRate;
  final String saleAmountPkr;
  final bool isReversed;

  NozzleReadingDetail({
    required this.id,
    required this.unitId,
    required this.unitName,
    required this.productCode,
    required this.openingReading,
    required this.closingReading,
    required this.grossSaleLiters,
    this.saleRate = "0.00",
    this.saleAmountPkr = "0.00",
    required this.isReversed,
  });

  factory NozzleReadingDetail.fromJson(Map<String, dynamic> json) {
    return NozzleReadingDetail(
      id: json['id'] as int,
      unitId: json['unit_id'] as int,
      unitName: json['unit_name'] as String,
      productCode: json['product_code'] as String,
      openingReading: json['opening_reading'].toString(),
      closingReading: json['closing_reading'].toString(),
      grossSaleLiters: json['gross_sale_liters'].toString(),
      saleRate: json['sale_rate']?.toString() ?? "0.00",
      saleAmountPkr: json['sale_amount_pkr']?.toString() ?? "0.00",
      isReversed: json['is_reversed'] as bool? ?? false,
    );
  }
}

class TankStockDetail {
  final int id;
  final int tankId;
  final String tankName;
  final String productCode;
  final String openingDipLiters;
  final String stockInPurchaseLiters;
  final String testingLossLiters;
  final String netSalesLiters;
  final String expectedClosingLiters;
  final String actualDipLiters;
  final String stockGainLossLiters;
  final String purchaseRate;
  final String rateDifference;
  final String saleRate;
  final String totalSalesPkr;
  final String rateDiffPkr;
  final String stockGainLossValuePkr;
  final String lubeOilSalePkr;
  final bool isReversed;

  TankStockDetail({
    required this.id,
    required this.tankId,
    required this.tankName,
    required this.productCode,
    required this.openingDipLiters,
    required this.stockInPurchaseLiters,
    required this.testingLossLiters,
    required this.netSalesLiters,
    required this.expectedClosingLiters,
    required this.actualDipLiters,
    required this.stockGainLossLiters,
    required this.purchaseRate,
    this.rateDifference = "0.00",
    this.saleRate = "0.00",
    this.totalSalesPkr = "0.00",
    this.rateDiffPkr = "0.00",
    required this.stockGainLossValuePkr,
    this.lubeOilSalePkr = "0.00",
    required this.isReversed,
  });

  factory TankStockDetail.fromJson(Map<String, dynamic> json) {
    return TankStockDetail(
      id: json['id'] as int,
      tankId: json['tank_id'] as int,
      tankName: json['tank_name'] as String,
      productCode: json['product_code'] as String,
      openingDipLiters: json['opening_dip_liters'].toString(),
      stockInPurchaseLiters: json['stock_in_purchase_liters'].toString(),
      testingLossLiters: json['testing_loss_liters'].toString(),
      netSalesLiters: json['net_sales_liters'].toString(),
      expectedClosingLiters: json['expected_closing_liters'].toString(),
      actualDipLiters: json['actual_dip_liters'].toString(),
      stockGainLossLiters: json['stock_gain_loss_liters'].toString(),
      purchaseRate: json['purchase_rate'].toString(),
      rateDifference: json['rate_difference']?.toString() ?? "0.00",
      saleRate: json['sale_rate']?.toString() ?? "0.00",
      totalSalesPkr: json['total_sales_pkr']?.toString() ?? "0.00",
      rateDiffPkr: json['rate_diff_pkr']?.toString() ?? "0.00",
      stockGainLossValuePkr: json['stock_gain_loss_value_pkr'].toString(),
      lubeOilSalePkr: json['lube_oil_sale_pkr']?.toString() ?? "0.00",
      isReversed: json['is_reversed'] as bool? ?? false,
    );
  }
}

class PurchaseDetail {
  final int id;
  final String productCode;
  final String tankName;
  final String? invoiceNo;
  final String purchaseLiters;
  final String purchaseRate;
  final String saleRate;
  final String? createdAt;
  final bool isReversed;

  PurchaseDetail({
    required this.id,
    required this.productCode,
    required this.tankName,
    this.invoiceNo,
    required this.purchaseLiters,
    required this.purchaseRate,
    required this.saleRate,
    this.createdAt,
    required this.isReversed,
  });

  factory PurchaseDetail.fromJson(Map<String, dynamic> json) {
    return PurchaseDetail(
      id: json['id'] as int,
      productCode: json['product_code'] as String,
      tankName: json['tank_name'] as String,
      invoiceNo: json['invoice_no'] as String?,
      purchaseLiters: json['purchase_liters'].toString(),
      purchaseRate: json['purchase_rate'].toString(),
      saleRate: json['sale_rate'].toString(),
      createdAt: json['created_at'] as String?,
      isReversed: json['is_reversed'] as bool? ?? false,
    );
  }
}

class CashMovementSummary {
  final String totalFuelSalesPkr;
  final String totalCreditSalesPkr;
  final String totalCreditRecoveriesPkr;
  final String totalCardSalesPkr;
  final String totalExpensesPkr;
  final String netCashPkr;

  CashMovementSummary({
    required this.totalFuelSalesPkr,
    required this.totalCreditSalesPkr,
    required this.totalCreditRecoveriesPkr,
    required this.totalCardSalesPkr,
    required this.totalExpensesPkr,
    required this.netCashPkr,
  });

  factory CashMovementSummary.fromJson(Map<String, dynamic> json) {
    return CashMovementSummary(
      totalFuelSalesPkr: json['total_fuel_sales_pkr'].toString(),
      totalCreditSalesPkr: json['total_credit_sales_pkr'].toString(),
      totalCreditRecoveriesPkr: json['total_credit_recoveries_pkr'].toString(),
      totalCardSalesPkr: json['total_card_sales_pkr'].toString(),
      totalExpensesPkr: json['total_expenses_pkr'].toString(),
      netCashPkr: json['net_cash_pkr'].toString(),
    );
  }
}

class DailyLogDetailModel {
  final int id;
  final String logDate;
  final String status;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final List<NozzleReadingDetail> nozzleReadings;
  final List<TankStockDetail> tankStocks;
  final List<PurchaseDetail> fuelPurchases;
  final List<CreditTransactionModel> creditTransactions;
  final List<CardTransactionModel> cardTransactions;
  final CashMovementSummary cashMovement;

  DailyLogDetailModel({
    required this.id,
    required this.logDate,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.nozzleReadings,
    required this.tankStocks,
    required this.fuelPurchases,
    required this.creditTransactions,
    required this.cardTransactions,
    required this.cashMovement,
  });

  factory DailyLogDetailModel.fromJson(Map<String, dynamic> json) {
    return DailyLogDetailModel(
      id: json['id'] as int,
      logDate: json['log_date'] as String,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      nozzleReadings: (json['nozzle_readings'] as List?)
              ?.map((e) => NozzleReadingDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      tankStocks: (json['tank_stocks'] as List?)
              ?.map((e) => TankStockDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      fuelPurchases: (json['fuel_purchases'] as List?)
              ?.map((e) => PurchaseDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      creditTransactions: (json['credit_transactions'] as List?)
              ?.map((e) => CreditTransactionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      cardTransactions: (json['card_transactions'] as List?)
              ?.map((e) => CardTransactionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      cashMovement: CashMovementSummary.fromJson(json['cash_movement'] as Map<String, dynamic>),
    );
  }
}
