// Helper methods for safe type conversion
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  if (value is double) return value.toInt();
  return null;
}

class CustomerWithRetailerDetails {
  // User fields
  final int userId;
  final int ulId;
  final String username;
  final String email;
  final String mobile;
  final String userCity;
  final String userProvince;
  final String userZip;
  final String userAddress;
  final String? userPhoto;
  final String? fcmToken;
  final DateTime userCreatedDate;
  final String userCreatedBy;
  final DateTime userUpdatedDate;
  final String userUpdatedBy;
  final String userType;
  final String userIsActive;
  final bool isOtpVerify;

  // Retailer fields (can be null if no retailer associated)
  final int? retId;
  final String? retCode;
  final String? retType;
  final String? retName;
  final String? retShopName;
  final String? retMobileNo;
  final String? retAddress;
  final int? retPinCode;
  final String? retEmailId;
  final String? retPhoto;
  final String? retCountry;
  final String? retState;
  final String? retCity;
  final String? retGstNo;
  final String? retLat;
  final String? retLong;
  final String? retDelStatus;
  final DateTime? retCreatedDate;
  final DateTime? retUpdatedDate;
  final String? retCreatedBy;
  final String? retUpdatedBy;
  final String? shopOpenStatus;
  final String? barcodeUrl;

  CustomerWithRetailerDetails({
    required this.userId,
    required this.ulId,
    required this.username,
    required this.email,
    required this.mobile,
    required this.userCity,
    required this.userProvince,
    required this.userZip,
    required this.userAddress,
    this.userPhoto,
    this.fcmToken,
    required this.userCreatedDate,
    required this.userCreatedBy,
    required this.userUpdatedDate,
    required this.userUpdatedBy,
    required this.userType,
    required this.userIsActive,
    required this.isOtpVerify,
    this.retId,
    this.retCode,
    this.retType,
    this.retName,
    this.retShopName,
    this.retMobileNo,
    this.retAddress,
    this.retPinCode,
    this.retEmailId,
    this.retPhoto,
    this.retCountry,
    this.retState,
    this.retCity,
    this.retGstNo,
    this.retLat,
    this.retLong,
    this.retDelStatus,
    this.retCreatedDate,
    this.retUpdatedDate,
    this.retCreatedBy,
    this.retUpdatedBy,
    this.shopOpenStatus,
    this.barcodeUrl,
  });

  factory CustomerWithRetailerDetails.fromJson(Map<String, dynamic> json) {
    return CustomerWithRetailerDetails(
      userId: _parseInt(json['USER_ID']) ?? 0,
      ulId: _parseInt(json['UL_ID']) ?? 0,
      username: json['USERNAME']?.toString() ?? '',
      email: json['EMAIL']?.toString() ?? '',
      mobile: json['MOBILE']?.toString() ?? '',
      userCity: json['USER_CITY']?.toString() ?? '',
      userProvince: json['USER_PROVINCE']?.toString() ?? '',
      userZip: json['USER_ZIP']?.toString() ?? '',
      userAddress: json['USER_ADDRESS']?.toString() ?? '',
      userPhoto: json['USER_PHOTO']?.toString(),
      fcmToken: json['FCM_TOKEN']?.toString(),
      userCreatedDate: json['USER_CREATED_DATE'] != null 
          ? DateTime.tryParse(json['USER_CREATED_DATE'].toString()) ?? DateTime.now()
          : DateTime.now(),
      userCreatedBy: json['USER_CREATED_BY']?.toString() ?? '',
      userUpdatedDate: json['USER_UPDATED_DATE'] != null 
          ? DateTime.tryParse(json['USER_UPDATED_DATE'].toString()) ?? DateTime.now()
          : DateTime.now(),
      userUpdatedBy: json['USER_UPDATED_BY']?.toString() ?? '',
      userType: json['USER_TYPE']?.toString() ?? '',
      userIsActive: json['USER_ISACTIVE']?.toString() ?? '',
      isOtpVerify: json['is_otp_verify'] == 1 || json['is_otp_verify'] == true,
      retId: _parseInt(json['RET_ID']),
      retCode: json['RET_CODE']?.toString(),
      retType: json['RET_TYPE']?.toString(),
      retName: json['RET_NAME']?.toString(),
      retShopName: json['RET_SHOP_NAME']?.toString(),
      retMobileNo: json['RET_MOBILE_NO']?.toString(),
      retAddress: json['RET_ADDRESS']?.toString(),
      retPinCode: _parseInt(json['RET_PIN_CODE']),
      retEmailId: json['RET_EMAIL_ID']?.toString(),
      retPhoto: json['RET_PHOTO']?.toString(),
      retCountry: json['RET_COUNTRY']?.toString(),
      retState: json['RET_STATE']?.toString(),
      retCity: json['RET_CITY']?.toString(),
      retGstNo: json['RET_GST_NO']?.toString(),
      retLat: json['RET_LAT']?.toString(),
      retLong: json['RET_LONG']?.toString(),
      retDelStatus: json['RET_DEL_STATUS']?.toString(),
      retCreatedDate: json['RET_CREATED_DATE'] != null 
          ? DateTime.tryParse(json['RET_CREATED_DATE'].toString())
          : null,
      retUpdatedDate: json['RET_UPDATED_DATE'] != null 
          ? DateTime.tryParse(json['RET_UPDATED_DATE'].toString())
          : null,
      retCreatedBy: json['RET_CREATED_BY']?.toString(),
      retUpdatedBy: json['RET_UPDATED_BY']?.toString(),
      shopOpenStatus: json['SHOP_OPEN_STATUS']?.toString(),
      barcodeUrl: json['BARCODE_URL']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'USER_ID': userId,
      'UL_ID': ulId,
      'USERNAME': username,
      'EMAIL': email,
      'MOBILE': mobile,
      'USER_CITY': userCity,
      'USER_PROVINCE': userProvince,
      'USER_ZIP': userZip,
      'USER_ADDRESS': userAddress,
      'USER_PHOTO': userPhoto,
      'FCM_TOKEN': fcmToken,
      'USER_CREATED_DATE': userCreatedDate.toIso8601String(),
      'USER_CREATED_BY': userCreatedBy,
      'USER_UPDATED_DATE': userUpdatedDate.toIso8601String(),
      'USER_UPDATED_BY': userUpdatedBy,
      'USER_TYPE': userType,
      'USER_ISACTIVE': userIsActive,
      'is_otp_verify': isOtpVerify,
      'RET_ID': retId,
      'RET_CODE': retCode,
      'RET_TYPE': retType,
      'RET_NAME': retName,
      'RET_SHOP_NAME': retShopName,
      'RET_MOBILE_NO': retMobileNo,
      'RET_ADDRESS': retAddress,
      'RET_PIN_CODE': retPinCode,
      'RET_EMAIL_ID': retEmailId,
      'RET_PHOTO': retPhoto,
      'RET_COUNTRY': retCountry,
      'RET_STATE': retState,
      'RET_CITY': retCity,
      'RET_GST_NO': retGstNo,
      'RET_LAT': retLat,
      'RET_LONG': retLong,
      'RET_DEL_STATUS': retDelStatus,
      'RET_CREATED_DATE': retCreatedDate?.toIso8601String(),
      'RET_UPDATED_DATE': retUpdatedDate?.toIso8601String(),
      'RET_CREATED_BY': retCreatedBy,
      'RET_UPDATED_BY': retUpdatedBy,
      'SHOP_OPEN_STATUS': shopOpenStatus,
      'BARCODE_URL': barcodeUrl,
    };
  }

  // Utility getters
  String get formattedMobile => '+91 $mobile';
  String get displayName => username.isNotEmpty ? username : 'Unknown User';
  String get fullUserAddress => '$userAddress, $userCity, $userProvince $userZip';
  bool get isUserActive => userIsActive.toLowerCase() == 'y';
  bool get hasRetailer => retId != null;
  String get retailerDisplayName => retName ?? retShopName ?? 'No Retailer';
  String get fullRetailerAddress {
    if (!hasRetailer) return 'No retailer address';
    final parts = <String>[];
    if (retAddress != null && retAddress!.isNotEmpty) parts.add(retAddress!);
    if (retCity != null && retCity!.isNotEmpty) parts.add(retCity!);
    if (retState != null && retState!.isNotEmpty) parts.add(retState!);
    if (retPinCode != null) parts.add(retPinCode.toString());
    return parts.isNotEmpty ? parts.join(', ') : 'No retailer address';
  }
  bool get isRetailerActive => retDelStatus?.toLowerCase() == 'active';
  bool get isShopOpen => shopOpenStatus?.toLowerCase() == 'open';
  String get formattedCreatedDate => '${userCreatedDate.day}/${userCreatedDate.month}/${userCreatedDate.year}';
}

class CustomerWithRetailerPagination {
  final int currentPage;
  final int totalPages;
  final int totalCustomers;
  final int limit;
  final bool hasNext;
  final bool hasPrev;

  CustomerWithRetailerPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalCustomers,
    required this.limit,
    required this.hasNext,
    required this.hasPrev,
  });

  factory CustomerWithRetailerPagination.fromJson(Map<String, dynamic> json) {
    return CustomerWithRetailerPagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalCustomers: json['totalCustomers'] ?? 0,
      limit: json['limit'] ?? 10,
      hasNext: json['hasNext'] ?? false,
      hasPrev: json['hasPrev'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalCustomers': totalCustomers,
      'limit': limit,
      'hasNext': hasNext,
      'hasPrev': hasPrev,
    };
  }
}

class CustomerWithRetailerFilters {
  final String? userType;
  final String? isActive;
  final String? city;
  final String? state;
  final String? country;
  final String? retStatus;
  final String? search;

  CustomerWithRetailerFilters({
    this.userType,
    this.isActive,
    this.city,
    this.state,
    this.country,
    this.retStatus,
    this.search,
  });

  factory CustomerWithRetailerFilters.fromJson(Map<String, dynamic> json) {
    return CustomerWithRetailerFilters(
      userType: json['userType'],
      isActive: json['isActive'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      retStatus: json['retStatus'],
      search: json['search'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userType': userType,
      'isActive': isActive,
      'city': city,
      'state': state,
      'country': country,
      'retStatus': retStatus,
      'search': search,
    };
  }
}

class CustomerWithRetailerResponse {
  final List<CustomerWithRetailerDetails> customers;
  final CustomerWithRetailerPagination pagination;
  final CustomerWithRetailerFilters? filters;
  final String? searchQuery;
  final String? accessedBy;
  final String? accessedByRole;
  final String? searchedBy;
  final String? searchedByRole;

  CustomerWithRetailerResponse({
    required this.customers,
    required this.pagination,
    this.filters,
    this.searchQuery,
    this.accessedBy,
    this.accessedByRole,
    this.searchedBy,
    this.searchedByRole,
  });

  factory CustomerWithRetailerResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    
    return CustomerWithRetailerResponse(
      customers: (data['customers'] as List? ?? [])
          .map((c) => CustomerWithRetailerDetails.fromJson(c))
          .toList(),
      pagination: CustomerWithRetailerPagination.fromJson(data['pagination'] ?? {}),
      filters: data['filters'] != null 
          ? CustomerWithRetailerFilters.fromJson(data['filters'])
          : null,
      searchQuery: data['searchQuery'],
      accessedBy: json['accessedBy'],
      accessedByRole: json['accessedByRole'],
      searchedBy: json['searchedBy'],
      searchedByRole: json['searchedByRole'],
    );
  }
} 