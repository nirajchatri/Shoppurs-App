// Helper methods for safe type conversion
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  if (value is double) return value.toInt();
  return null;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

class Customer {
  final int userId;
  final String username;
  final String email;
  final int mobile;
  final String city;
  final String province;
  final String zip;
  final String address;
  final String userType;
  final String isActive;
  final bool isOtpVerify;
  final String createdBy;
  final DateTime createdDate;
  final int? retId;
  final String? retCode;
  final String? retType;
  final String? retailerName;
  final String? barcodeUrl;

  Customer({
    required this.userId,
    required this.username,
    required this.email,
    required this.mobile,
    required this.city,
    required this.province,
    required this.zip,
    required this.address,
    required this.userType,
    required this.isActive,
    required this.isOtpVerify,
    required this.createdBy,
    required this.createdDate,
    this.retId,
    this.retCode,
    this.retType,
    this.retailerName,
    this.barcodeUrl,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      userId: _parseInt(json['USER_ID']) ?? 0,
      username: json['USERNAME']?.toString() ?? '',
      email: json['EMAIL']?.toString() ?? '',
      mobile: _parseInt(json['MOBILE']) ?? 0,
      city: json['CITY']?.toString() ?? '',
      province: json['PROVINCE']?.toString() ?? '',
      zip: json['ZIP']?.toString() ?? '',
      address: json['ADDRESS']?.toString() ?? '',
      userType: json['USER_TYPE']?.toString() ?? 'customer',
      isActive: json['ISACTIVE']?.toString() ?? 'Y',
      isOtpVerify: _parseInt(json['is_otp_verify']) == 1,
      createdBy: json['CREATED_BY']?.toString() ?? '',
      createdDate: json['CREATED_DATE'] != null 
          ? DateTime.tryParse(json['CREATED_DATE'].toString()) ?? DateTime.now()
          : DateTime.now(),
      retId: _parseInt(json['RET_ID']),
      retCode: json['RET_CODE']?.toString(),
      retType: json['RET_TYPE']?.toString(),
      retailerName: json['RETAILER_NAME']?.toString(),
      barcodeUrl: json['BARCODE_URL']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'USER_ID': userId,
      'USERNAME': username,
      'EMAIL': email,
      'MOBILE': mobile,
      'CITY': city,
      'PROVINCE': province,
      'ZIP': zip,
      'ADDRESS': address,
      'USER_TYPE': userType,
      'ISACTIVE': isActive,
      'is_otp_verify': isOtpVerify ? 1 : 0,
      'CREATED_BY': createdBy,
      'CREATED_DATE': createdDate.toIso8601String(),
      'RET_ID': retId,
      'RET_CODE': retCode,
      'RET_TYPE': retType,
      'RETAILER_NAME': retailerName,
      'BARCODE_URL': barcodeUrl,
    };
    }
}

class CustomerAddress {
  final int? addressId;
  final int userId;
  final String address;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final String? landmark;
  final String addressType;
  final bool isDefault;
  final String delStatus;
  final DateTime createdDate;
  final DateTime? updatedDate;

  CustomerAddress({
    this.addressId,
    required this.userId,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    this.landmark,
    required this.addressType,
    required this.isDefault,
    this.delStatus = 'N',
    required this.createdDate,
    this.updatedDate,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      addressId: _parseInt(json['ADDRESS_ID']),
      userId: _parseInt(json['USER_ID']) ?? 0,
      address: json['ADDRESS']?.toString() ?? '',
      city: json['CITY']?.toString() ?? '',
      state: json['STATE']?.toString() ?? '',
      country: json['COUNTRY']?.toString() ?? 'India',
      pincode: json['PINCODE']?.toString() ?? '',
      landmark: json['LANDMARK']?.toString(),
      addressType: json['ADDRESS_TYPE']?.toString() ?? 'Home',
      isDefault: _parseInt(json['IS_DEFAULT']) == 1,
      delStatus: json['DEL_STATUS']?.toString() ?? 'N',
      createdDate: json['CREATED_DATE'] != null 
          ? DateTime.tryParse(json['CREATED_DATE'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedDate: json['UPDATED_DATE'] != null 
          ? DateTime.tryParse(json['UPDATED_DATE'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ADDRESS_ID': addressId,
      'USER_ID': userId,
      'ADDRESS': address,
      'CITY': city,
      'STATE': state,
      'COUNTRY': country,
      'PINCODE': pincode,
      'LANDMARK': landmark,
      'ADDRESS_TYPE': addressType,
      'IS_DEFAULT': isDefault ? 1 : 0,
      'DEL_STATUS': delStatus,
      'CREATED_DATE': createdDate.toIso8601String(),
      'UPDATED_DATE': updatedDate?.toIso8601String(),
    };
  }

    String get fullAddress => '$address, $city, $state, $country - $pincode';
}

class CustomerOrderSummary {
  final int totalOrders;
  final int completedOrders;
  final int pendingOrders;
  final int cancelledOrders;
  final double totalOrderValue;

  CustomerOrderSummary({
    required this.totalOrders,
    required this.completedOrders,
    required this.pendingOrders,
    required this.cancelledOrders,
    required this.totalOrderValue,
  });

  factory CustomerOrderSummary.fromJson(Map<String, dynamic> json) {
    return CustomerOrderSummary(
      totalOrders: _parseInt(json['total_orders']) ?? 0,
      completedOrders: _parseInt(json['completed_orders']) ?? 0,
      pendingOrders: _parseInt(json['pending_orders']) ?? 0,
      cancelledOrders: _parseInt(json['cancelled_orders']) ?? 0,
      totalOrderValue: _parseDouble(json['total_order_value']) ?? 0.0,
    );
     }
}

class CreateCustomerRequest {
  final String username;
  final String? email;
  final String mobile;
  final String? password;
  final String storeName;
  final String city;
  final String province;
  final String zip;
  final String address;
  final String? addressDetails;
  final String? addressCity;
  final String? addressState;
  final String? addressCountry;
  final String? addressPincode;
  final String? landmark;
  final String? addressType;
  final bool? isDefaultAddress;
  final String? lat;
  final String? long;
  final List<CustomerAddressRequest>? addresses;

  CreateCustomerRequest({
    required this.username,
    this.email,
    required this.mobile,
    this.password,
    required this.storeName,
    required this.city,
    required this.province,
    required this.zip,
    required this.address,
    this.addressDetails,
    this.addressCity,
    this.addressState,
    this.addressCountry,
    this.addressPincode,
    this.landmark,
    this.addressType,
    this.isDefaultAddress,
    this.lat,
    this.long,
    this.addresses,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      if (email != null) 'email': email,
      'mobile': mobile,
      if (password != null) 'password': password,
      'storeName': storeName,
      'city': city,
      'province': province,
      'zip': zip,
      'address': address,
      if (addressDetails != null) 'addressDetails': addressDetails,
      if (addressCity != null) 'addressCity': addressCity,
      if (addressState != null) 'addressState': addressState,
      if (addressCountry != null) 'addressCountry': addressCountry,
      if (addressPincode != null) 'addressPincode': addressPincode,
      if (landmark != null) 'landmark': landmark,
      if (addressType != null) 'addressType': addressType,
      if (isDefaultAddress != null) 'isDefaultAddress': isDefaultAddress,
      if (lat != null) 'lat': lat,
      if (long != null) 'long': long,
      if (addresses != null) 'addresses': addresses?.map((a) => a.toJson()).toList(),
    };
  }
}

class CustomerAddressRequest {
  final String address;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final String? landmark;
  final String addressType;
  final bool isDefault;

  CustomerAddressRequest({
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    this.landmark,
    required this.addressType,
    required this.isDefault,
  });

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'pincode': pincode,
      if (landmark != null) 'landmark': landmark,
      'addressType': addressType,
      'isDefault': isDefault,
    };
  }
} 