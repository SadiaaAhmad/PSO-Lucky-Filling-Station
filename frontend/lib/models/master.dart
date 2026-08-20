class ProductModel {
  final int id;
  final String code;
  final String name;
  final String unit;
  final String defaultMarginRate;
  
  ProductModel({required this.id, required this.code, required this.name, required this.unit, required this.defaultMarginRate});
  
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      unit: json['unit'] as String,
      defaultMarginRate: json['default_margin_rate']?.toString() ?? '0.0000',
    );
  }
}

class TankModel {
  final int id;
  final String tankName;
  final int productId;
  final String productCode;
  final String productName;
  final String capacityLiters;
  
  TankModel({required this.id, required this.tankName, required this.productId, required this.productCode, required this.productName, required this.capacityLiters});
  
  factory TankModel.fromJson(Map<String, dynamic> json) {
    return TankModel(
      id: json['id'] as int,
      tankName: json['tank_name'] as String,
      productId: json['product_id'] as int,
      productCode: json['product_code'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      capacityLiters: json['capacity_liters']?.toString() ?? '0.00',
    );
  }
}

class DispensingUnitModel {
  final int id;
  final int unitNumber;
  final String name;
  final int productId;
  final String productCode;
  final int tankId;
  final String tankName;
  final bool isActive;
  
  DispensingUnitModel({required this.id, required this.unitNumber, required this.name, required this.productId, required this.productCode, required this.tankId, required this.tankName, required this.isActive});
  
  factory DispensingUnitModel.fromJson(Map<String, dynamic> json) {
    return DispensingUnitModel(
      id: json['id'] as int,
      unitNumber: json['unit_number'] as int,
      name: json['name'] as String,
      productId: json['product_id'] as int,
      productCode: json['product_code'] as String? ?? '',
      tankId: json['tank_id'] as int,
      tankName: json['tank_name'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class AccountModel {
  final int id;
  final String accountCode;
  final String name;
  final String type;
  final bool isActive;
  
  AccountModel({required this.id, required this.accountCode, required this.name, required this.type, required this.isActive});
  
  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as int,
      accountCode: json['account_code'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class StationConfigModel {
  final String stationName;
  final String stationId;
  final String address;
  final String licenseNo;
  final String contactPhone;
  final String hsdCurrentRate;
  final String pmgCurrentRate;
  
  StationConfigModel({required this.stationName, required this.stationId, required this.address, required this.licenseNo, required this.contactPhone, required this.hsdCurrentRate, required this.pmgCurrentRate});
  
  factory StationConfigModel.fromJson(Map<String, dynamic> json) {
    return StationConfigModel(
      stationName: json['station_name'] as String? ?? 'PSO Lucky Filling Station',
      stationId: json['station_id'] as String? ?? '',
      address: json['address'] as String? ?? '',
      licenseNo: json['license_no'] as String? ?? '',
      contactPhone: json['contact_phone'] as String? ?? '',
      hsdCurrentRate: json['hsd_current_rate']?.toString() ?? '293.0000',
      pmgCurrentRate: json['pmg_current_rate']?.toString() ?? '280.5000',
    );
  }
}
