import 'package:frontend/services/api_client.dart';
import 'package:frontend/models/daily_log.dart';
import 'package:frontend/models/fuel.dart';
import 'package:frontend/models/tank_stock.dart';
import 'package:frontend/models/customer.dart';
import 'package:frontend/models/transactions.dart';
import 'package:frontend/models/report.dart';
import 'package:frontend/models/master.dart';
import 'package:frontend/models/activity.dart';
import 'package:frontend/models/daily_log_detail.dart';
import 'package:frontend/models/expense.dart';
import 'package:frontend/core/utils/app_logger.dart';

class MasterApi {
  static Future<List<ProductModel>> getProducts() async {
    final data = await ApiClient.get('/api/v1/master/products');
    final list = (data as List).map((e) => ProductModel.fromJson(e)).toList();
    AppLogger.data('Parsed Products', {'count': list.length});
    return list;
  }
  static Future<List<TankModel>> getTanks() async {
    final data = await ApiClient.get('/api/v1/master/tanks');
    final list = (data as List).map((e) => TankModel.fromJson(e)).toList();
    AppLogger.data('Parsed Tanks', {'count': list.length});
    return list;
  }
  static Future<List<DispensingUnitModel>> getDispensingUnits() async {
    final data = await ApiClient.get('/api/v1/master/dispensing-units');
    final list = (data as List).map((e) => DispensingUnitModel.fromJson(e)).toList();
    AppLogger.data('Parsed Dispensing Units', {'count': list.length});
    return list;
  }
  static Future<List<AccountModel>> getAccounts() async {
    final data = await ApiClient.get('/api/v1/master/accounts');
    final list = (data as List).map((e) => AccountModel.fromJson(e)).toList();
    AppLogger.data('Parsed Accounts', {'count': list.length});
    return list;
  }
  static Future<AccountModel> createAccount({
    required String accountCode,
    required String name,
    required String type,
    String? description,
  }) async {
    final payload = {
      'account_code': accountCode,
      'name': name,
      'type': type,
      'description': description,
    };
    final data = await ApiClient.post('/api/v1/master/accounts', payload);
    return AccountModel.fromJson(data as Map<String, dynamic>);
  }
  static Future<void> deleteAccount(int accountId) async {
    await ApiClient.post('/api/v1/master/accounts/$accountId/delete', {});
  }
  static Future<StationConfigModel> getStationConfig() async {
    final data = await ApiClient.get('/api/v1/master/station-config');
    final config = StationConfigModel.fromJson(data as Map<String, dynamic>);
    AppLogger.data('Parsed Station Config', {'name': config.stationName});
    return config;
  }
  static Future<StationConfigModel> updateStationConfig(Map<String, dynamic> payload) async {
    final data = await ApiClient.post('/api/v1/master/station-config', payload);
    return StationConfigModel.fromJson(data as Map<String, dynamic>);
  }
}

class ActivityApi {
  static Future<List<ActivityItem>> getRecentActivity({int skip = 0, int limit = 20}) async {
    final data = await ApiClient.get('/api/v1/activity/recent', {'skip': skip, 'limit': limit});
    final list = (data as List).map((e) => ActivityItem.fromJson(e)).toList();
    AppLogger.data('Parsed Recent Activity', {'count': list.length, 'skip': skip, 'limit': limit});
    return list;
  }
}

class DailyLogApi {
  static Future<List<DailyLogModel>> getDailyLogs({int skip = 0, int limit = 50}) async {
    final data = await ApiClient.get('/api/v1/daily-logs/', {'skip': skip, 'limit': limit});
    final list = (data as List).map((item) => DailyLogModel.fromJson(item as Map<String, dynamic>)).toList();
    AppLogger.data('Parsed Daily Logs', {'count': list.length});
    return list;
  }

  static Future<DailyLogModel> getDailyLogById(int id) async {
    final data = await ApiClient.get('/api/v1/daily-logs/$id');
    return DailyLogModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<DailyLogDetailModel> getDailyLogDetail(int id) async {
    final data = await ApiClient.get('/api/v1/daily-logs/$id/detail');
    final detail = DailyLogDetailModel.fromJson(data as Map<String, dynamic>);
    AppLogger.data('Parsed Daily Log Detail', {'id': detail.id, 'log_date': detail.logDate});
    return detail;
  }

  static Future<DailyLogModel> createDailyLog(String logDate, {String? notes}) async {
    final payload = {'log_date': logDate, 'notes': notes};
    final data = await ApiClient.post('/api/v1/daily-logs/', payload);
    return DailyLogModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<DailyLogModel> getOrCreateByDate(String logDate, {String? notes}) async {
    final payload = {'log_date': logDate, 'notes': notes};
    final data = await ApiClient.post('/api/v1/daily-logs/get-or-create-by-date', payload);
    return DailyLogModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<DailyLogModel> closeDailyLog(int id) async {
    final data = await ApiClient.post('/api/v1/daily-logs/$id/close', {});
    return DailyLogModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deleteDailyLog(int id) async {
    await ApiClient.post('/api/v1/daily-logs/$id/delete', {});
  }
}

class FuelApi {
  static Future<List<NozzleReadingModel>> getNozzleReadings(int dailyLogId) async {
    final data = await ApiClient.get('/api/v1/fuel/nozzle-readings', {'daily_log_id': dailyLogId});
    return (data as List).map((e) => NozzleReadingModel.fromJson(e)).toList();
  }

  static Future<List<FuelPurchaseModel>> getPurchases(int dailyLogId) async {
    final data = await ApiClient.get('/api/v1/fuel/purchases', {'daily_log_id': dailyLogId});
    return (data as List).map((e) => FuelPurchaseModel.fromJson(e)).toList();
  }

  static Future<void> reverseNozzleReading(int readingId, String reason) async {
    await ApiClient.post('/api/v1/fuel/nozzle-readings/$readingId/reverse', {'reason': reason});
  }

  static Future<void> restoreNozzleReading(int readingId) async {
    await ApiClient.post('/api/v1/fuel/nozzle-readings/$readingId/restore', {});
  }

  static Future<void> reversePurchase(int purchaseId, String reason) async {
    await ApiClient.post('/api/v1/fuel/purchases/$purchaseId/reverse', {'reason': reason});
  }

  static Future<void> reverseFuelPurchase(int purchaseId, String reason) async {
    await reversePurchase(purchaseId, reason);
  }

  static Future<void> restorePurchase(int purchaseId) async {
    await ApiClient.post('/api/v1/fuel/purchases/$purchaseId/restore', {});
  }

  static Future<List<NozzleReadingModel>> recordNozzleReadings(
    int dailyLogId,
    List<Map<String, dynamic>> readings,
  ) async {
    final payload = {
      'daily_log_id': dailyLogId,
      'readings': readings,
    };
    final data = await ApiClient.post('/api/v1/fuel/nozzle-readings', payload);
    final list = (data as List).map((item) => NozzleReadingModel.fromJson(item as Map<String, dynamic>)).toList();
    return list;
  }

  static Future<FuelPurchaseModel> recordFuelPurchase({
    required int dailyLogId,
    required int productId,
    required int tankId,
    required String purchaseLiters,
    required String purchaseRate,
    required String saleRate,
    String? invoiceNo,
    String rateDiffPerLtr = "0.0000",
  }) async {
    final payload = {
      'daily_log_id': dailyLogId,
      'product_id': productId,
      'tank_id': tankId,
      'purchase_liters': purchaseLiters,
      'purchase_rate': purchaseRate,
      'sale_rate': saleRate,
      'invoice_no': invoiceNo,
      'rate_diff_per_ltr': rateDiffPerLtr,
    };
    final data = await ApiClient.post('/api/v1/fuel/purchases', payload);
    return FuelPurchaseModel.fromJson(data as Map<String, dynamic>);
  }
}

class StockApi {
  static Future<List<DailyTankStockModel>> getTankStocks(int dailyLogId) async {
    final data = await ApiClient.get('/api/v1/stock/tank-stocks', {'daily_log_id': dailyLogId});
    return (data as List).map((e) => DailyTankStockModel.fromJson(e)).toList();
  }

  static Future<List<LatestTankStockModel>> getLatestTankStocks() async {
    final data = await ApiClient.get('/api/v1/stock/tank-stocks/latest');
    return (data as List).map((e) => LatestTankStockModel.fromJson(e)).toList();
  }

  static Future<void> reverseTankStock(int stockId, String reason) async {
    await ApiClient.post('/api/v1/stock/tank-stocks/$stockId/reverse', {'reason': reason});
  }

  static Future<DailyTankStockModel> recordTankStock({
    required int dailyLogId,
    required int tankId,
    required int productId,
    required String openingDipLiters,
    required String actualDipLiters,
    required String purchaseRate,
    String stockInPurchaseLiters = "0.00",
    String testingLossLiters = "0.00",
    String netSalesLiters = "0.00",
  }) async {
    final payload = {
      'daily_log_id': dailyLogId,
      'tank_id': tankId,
      'product_id': productId,
      'opening_dip_liters': openingDipLiters,
      'stock_in_purchase_liters': stockInPurchaseLiters,
      'testing_loss_liters': testingLossLiters,
      'net_sales_liters': netSalesLiters,
      'actual_dip_liters': actualDipLiters,
      'purchase_rate': purchaseRate,
    };
    final data = await ApiClient.post('/api/v1/stock/tank-stock', payload);
    return DailyTankStockModel.fromJson(data as Map<String, dynamic>);
  }
}

class CustomerApi {
  static Future<List<CustomerModel>> getCustomers() async {
    final data = await ApiClient.get('/api/v1/customers/');
    return (data as List).map((e) => CustomerModel.fromJson(e)).toList();
  }

  static Future<CustomerModel> getCustomerById(int id) async {
    final data = await ApiClient.get('/api/v1/customers/$id');
    return CustomerModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<List<CreditTransactionModel>> getCustomerLedger(int customerId, {int skip = 0, int limit = 50}) async {
    final data = await ApiClient.get('/api/v1/customers/$customerId/ledger', {'skip': skip, 'limit': limit});
    return (data as List).map((e) => CreditTransactionModel.fromJson(e)).toList();
  }

  static Future<CustomerModel> createCustomer({
    required String accountNo,
    required String name,
    String? phone,
    String creditLimit = "0.00",
    String openingBalance = "0.00",
  }) async {
    final payload = {
      'account_no': accountNo,
      'name': name,
      'phone': phone,
      'credit_limit': creditLimit,
      'opening_balance': openingBalance,
    };
    final data = await ApiClient.post('/api/v1/customers/', payload);
    return CustomerModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<CustomerVehicleModel> addVehicle(
    int customerId, {
    required String vehicleNo,
    String? driverName,
    String? notes,
  }) async {
    final payload = {
      'vehicle_no': vehicleNo,
      'driver_name': driverName,
      'notes': notes,
    };
    final data = await ApiClient.post('/api/v1/customers/$customerId/vehicles', payload);
    return CustomerVehicleModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<CustomerBalanceModel> getCustomerBalance(int customerId) async {
    final data = await ApiClient.get('/api/v1/customers/$customerId/balance');
    return CustomerBalanceModel.fromJson(data as Map<String, dynamic>);
  }
}

class CreditApi {
  static Future<void> reverseTransaction(int transactionId, String reason) async {
    await ApiClient.post('/api/v1/credit/transactions/$transactionId/reverse', {'reason': reason});
  }

  static Future<void> restoreTransaction(int transactionId) async {
    await ApiClient.post('/api/v1/credit/transactions/$transactionId/restore', {});
  }

  static Future<CreditTransactionModel> recordCreditSale({
    required int dailyLogId,
    required int customerId,
    required String amount,
    int? vehicleId,
    int? productId,
    String liters = "0.00",
    String ratePerLtr = "0.0000",
    String? reference,
  }) async {
    final payload = {
      'daily_log_id': dailyLogId,
      'customer_id': customerId,
      'amount': amount,
      'vehicle_id': vehicleId,
      'product_id': productId,
      'liters': liters,
      'rate_per_ltr': ratePerLtr,
      'reference': reference,
    };
    final data = await ApiClient.post('/api/v1/credit/sale', payload);
    return CreditTransactionModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<CreditTransactionModel> recordCreditRecovery({
    required int dailyLogId,
    required int customerId,
    required String amount,
    String paymentAccountCode = "1010",
    String? reference,
  }) async {
    final payload = {
      'daily_log_id': dailyLogId,
      'customer_id': customerId,
      'amount': amount,
      'payment_account_code': paymentAccountCode,
      'reference': reference,
    };
    final data = await ApiClient.post('/api/v1/credit/recovery', payload);
    return CreditTransactionModel.fromJson(data as Map<String, dynamic>);
  }
}

class FinanceApi {
  static Future<List<ExpenseModel>> getExpenses(int dailyLogId) async {
    final data = await ApiClient.get('/api/v1/finance/expenses', {'daily_log_id': dailyLogId});
    return (data as List).map((e) => ExpenseModel.fromJson(e)).toList();
  }

  static Future<List<CardTransactionModel>> getCardSales(int dailyLogId) async {
    final data = await ApiClient.get('/api/v1/finance/card-sales', {'daily_log_id': dailyLogId});
    return (data as List).map((e) => CardTransactionModel.fromJson(e)).toList();
  }

  static Future<void> reverseExpense(int journalId, String reason) async {
    await ApiClient.post('/api/v1/finance/expenses/$journalId/reverse', {'reason': reason});
  }

  static Future<void> reverseCardSale(int cardId, String reason) async {
    await ApiClient.post('/api/v1/finance/card-sales/$cardId/reverse', {'reason': reason});
  }

  static Future<dynamic> recordExpense({
    required int dailyLogId,
    required String expenseAccountCode,
    required String amount,
    required String description,
    String paymentAccountCode = "1010",
  }) async {
    final payload = {
      'daily_log_id': dailyLogId,
      'expense_account_code': expenseAccountCode,
      'amount': amount,
      'description': description,
      'payment_account_code': paymentAccountCode,
    };
    return await ApiClient.post('/api/v1/finance/expense', payload);
  }

  static Future<CardTransactionModel> recordCardSale({
    required int dailyLogId,
    required String cardType,
    required String liters,
    required String amount,
    String bankCharges = "0.00",
  }) async {
    final payload = {
      'daily_log_id': dailyLogId,
      'card_type': cardType,
      'liters': liters,
      'amount': amount,
      'bank_charges': bankCharges,
    };
    final data = await ApiClient.post('/api/v1/finance/card-sale', payload);
    return CardTransactionModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<dynamic> recordOwnerDraw({
    required int dailyLogId,
    required String amount,
    String description = "Owner Drawings / Home Expense",
  }) async {
    final payload = {
      'daily_log_id': dailyLogId,
      'amount': amount,
      'description': description,
    };
    return await ApiClient.post('/api/v1/finance/owner-draw', payload);
  }
}

class ReportApi {
  static Future<MonthlyPnLModel> getLatestMonthlyPnL() async {
    final data = await ApiClient.get('/api/v1/reports/latest-monthly');
    return MonthlyPnLModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<DailySummaryModel> getLatestDailySummary() async {
    final data = await ApiClient.get('/api/v1/reports/latest-daily');
    return DailySummaryModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<MonthlyPnLModel> getMonthlyPnL(int year, int month) async {
    final data = await ApiClient.get('/api/v1/reports/monthly/$year/$month');
    return MonthlyPnLModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<DailySummaryModel?> getDailySummary(String logDate) async {
    try {
      final data = await ApiClient.get('/api/v1/reports/daily/$logDate');
      return DailySummaryModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      if (e.toString().contains('404') || e.toString().contains('No daily log found')) {
        return null;
      }
      rethrow;
    }
  }
}
