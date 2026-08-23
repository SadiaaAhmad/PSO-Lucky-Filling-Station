class MonthlyPnLModel {
  final int year;
  final int month;
  final Map<String, String> revenueBreakdown;
  final String totalIncome;
  final Map<String, String> expenseBreakdown;
  final String totalExpenses;
  final String netProfit;

  MonthlyPnLModel({
    required this.year,
    required this.month,
    required this.revenueBreakdown,
    required this.totalIncome,
    required this.expenseBreakdown,
    required this.totalExpenses,
    required this.netProfit,
  });

  factory MonthlyPnLModel.fromJson(Map<String, dynamic> json) {
    Map<String, String> revMap = {};
    if (json['revenue_breakdown'] is Map) {
      (json['revenue_breakdown'] as Map).forEach((k, v) {
        revMap[k.toString()] = v.toString();
      });
    }

    Map<String, String> expMap = {};
    if (json['expense_breakdown'] is Map) {
      (json['expense_breakdown'] as Map).forEach((k, v) {
        expMap[k.toString()] = v.toString();
      });
    }

    return MonthlyPnLModel(
      year: json['year'] as int,
      month: json['month'] as int,
      revenueBreakdown: revMap,
      totalIncome: json['total_income'].toString(),
      expenseBreakdown: expMap,
      totalExpenses: json['total_expenses'].toString(),
      netProfit: json['net_profit'].toString(),
    );
  }
}

class DailySummaryModel {
  final String logDate;
  final String status;
  final int totalNozzlesRecorded;
  final String totalGrossLitersDispensed;
  final int tankStocksRecorded;
  final String totalCreditSalesPkr;
  final String totalCreditRecoveriesPkr;
  final String totalCardSalesPkr;
  final String totalExpensesPkr;
  final String totalRevenuePkr;
  final String netProfitPkr;

  DailySummaryModel({
    required this.logDate,
    required this.status,
    required this.totalNozzlesRecorded,
    required this.totalGrossLitersDispensed,
    required this.tankStocksRecorded,
    required this.totalCreditSalesPkr,
    required this.totalCreditRecoveriesPkr,
    required this.totalCardSalesPkr,
    this.totalExpensesPkr = "0.00",
    this.totalRevenuePkr = "0.00",
    this.netProfitPkr = "0.00",
  });

  factory DailySummaryModel.fromJson(Map<String, dynamic> json) {
    return DailySummaryModel(
      logDate: json['log_date'] as String,
      status: json['status'] as String,
      totalNozzlesRecorded: json['total_nozzles_recorded'] as int,
      totalGrossLitersDispensed: json['total_gross_liters_dispensed'].toString(),
      tankStocksRecorded: json['tank_stocks_recorded'] as int,
      totalCreditSalesPkr: json['total_credit_sales_pkr'].toString(),
      totalCreditRecoveriesPkr: json['total_credit_recoveries_pkr'].toString(),
      totalCardSalesPkr: json['total_card_sales_pkr'].toString(),
      totalExpensesPkr: json['total_expenses_pkr'] != null ? json['total_expenses_pkr'].toString() : "0.00",
      totalRevenuePkr: json['total_revenue_pkr'] != null ? json['total_revenue_pkr'].toString() : "0.00",
      netProfitPkr: json['net_profit_pkr'] != null ? json['net_profit_pkr'].toString() : "0.00",
    );
  }
}
