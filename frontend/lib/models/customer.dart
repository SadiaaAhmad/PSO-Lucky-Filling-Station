class CustomerVehicleModel {
  final int id;
  final int customerId;
  final String vehicleNo;
  final String? driverName;
  final String? notes;

  CustomerVehicleModel({
    required this.id,
    required this.customerId,
    required this.vehicleNo,
    this.driverName,
    this.notes,
  });

  factory CustomerVehicleModel.fromJson(Map<String, dynamic> json) {
    return CustomerVehicleModel(
      id: json['id'] as int,
      customerId: json['customer_id'] as int,
      vehicleNo: json['vehicle_no'] as String,
      driverName: json['driver_name'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

class CustomerModel {
  final int id;
  final String accountNo;
  final String name;
  final String? phone;
  final String creditLimit;
  final String openingBalance;
  final List<CustomerVehicleModel> vehicles;

  CustomerModel({
    required this.id,
    required this.accountNo,
    required this.name,
    this.phone,
    required this.creditLimit,
    required this.openingBalance,
    required this.vehicles,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    var vList = json['vehicles'] as List? ?? [];
    return CustomerModel(
      id: json['id'] as int,
      accountNo: json['account_no'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      creditLimit: json['credit_limit'].toString(),
      openingBalance: json['opening_balance'].toString(),
      vehicles: vList.map((v) => CustomerVehicleModel.fromJson(v as Map<String, dynamic>)).toList(),
    );
  }
}

class CustomerBalanceModel {
  final int customerId;
  final String accountNo;
  final String name;
  final String openingBalance;
  final String totalCreditSales;
  final String totalRecoveries;
  final String currentBalance;
  final String creditLimit;
  final String availableCredit;

  CustomerBalanceModel({
    required this.customerId,
    required this.accountNo,
    required this.name,
    required this.openingBalance,
    required this.totalCreditSales,
    required this.totalRecoveries,
    required this.currentBalance,
    required this.creditLimit,
    required this.availableCredit,
  });

  factory CustomerBalanceModel.fromJson(Map<String, dynamic> json) {
    return CustomerBalanceModel(
      customerId: json['customer_id'] as int,
      accountNo: json['account_no'] as String,
      name: json['name'] as String,
      openingBalance: json['opening_balance'].toString(),
      totalCreditSales: json['total_credit_sales'].toString(),
      totalRecoveries: json['total_recoveries'].toString(),
      currentBalance: json['current_balance'].toString(),
      creditLimit: json['credit_limit'].toString(),
      availableCredit: json['available_credit'].toString(),
    );
  }
}
