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

class CreateUserRequest {
  final String username;
  final String email;
  final String mobile;
  final String? password;
  final String city;
  final String province;
  final String zip;
  final String address;
  final String? photo;
  final String? fcmToken;
  final int? ulId;

  CreateUserRequest({
    required this.username,
    required this.email,
    required this.mobile,
    this.password,
    required this.city,
    required this.province,
    required this.zip,
    required this.address,
    this.photo,
    this.fcmToken,
    this.ulId,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'mobile': mobile,
      if (password != null) 'password': password,
      'city': city,
      'province': province,
      'zip': zip,
      'address': address,
      if (photo != null) 'photo': photo,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (ulId != null) 'ulId': ulId,
    };
  }
}

class UserManagementUser {
  final int userId;
  final int ulId;
  final String username;
  final String email;
  final int mobile;
  final String city;
  final String province;
  final String zip;
  final String address;
  final String? photo;
  final String? fcmToken;
  final DateTime createdDate;
  final String createdBy;
  final DateTime updatedDate;
  final String updatedBy;
  final String userType;
  final String isActive;
  final bool isOtpVerify;

  UserManagementUser({
    required this.userId,
    required this.ulId,
    required this.username,
    required this.email,
    required this.mobile,
    required this.city,
    required this.province,
    required this.zip,
    required this.address,
    this.photo,
    this.fcmToken,
    required this.createdDate,
    required this.createdBy,
    required this.updatedDate,
    required this.updatedBy,
    required this.userType,
    required this.isActive,
    required this.isOtpVerify,
  });

  factory UserManagementUser.fromJson(Map<String, dynamic> json) {
    return UserManagementUser(
      userId: _parseInt(json['USER_ID']) ?? 0,
      ulId: _parseInt(json['UL_ID']) ?? 0,
      username: json['USERNAME']?.toString() ?? '',
      email: json['EMAIL']?.toString() ?? '',
      mobile: _parseInt(json['MOBILE']) ?? 0,
      city: json['CITY']?.toString() ?? '',
      province: json['PROVINCE']?.toString() ?? '',
      zip: json['ZIP']?.toString() ?? '',
      address: json['ADDRESS']?.toString() ?? '',
      photo: json['PHOTO']?.toString(),
      fcmToken: json['FCM_TOKEN']?.toString(),
      createdDate: json['CREATED_DATE'] != null 
          ? DateTime.tryParse(json['CREATED_DATE'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdBy: json['CREATED_BY']?.toString() ?? '',
      updatedDate: json['UPDATED_DATE'] != null 
          ? DateTime.tryParse(json['UPDATED_DATE'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedBy: json['UPDATED_BY']?.toString() ?? '',
      userType: json['USER_TYPE']?.toString() ?? '',
      isActive: json['ISACTIVE']?.toString() ?? 'Y',
      isOtpVerify: _parseInt(json['is_otp_verify']) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'USER_ID': userId,
      'UL_ID': ulId,
      'USERNAME': username,
      'EMAIL': email,
      'MOBILE': mobile,
      'CITY': city,
      'PROVINCE': province,
      'ZIP': zip,
      'ADDRESS': address,
      'PHOTO': photo,
      'FCM_TOKEN': fcmToken,
      'CREATED_DATE': createdDate.toIso8601String(),
      'CREATED_BY': createdBy,
      'UPDATED_DATE': updatedDate.toIso8601String(),
      'UPDATED_BY': updatedBy,
      'USER_TYPE': userType,
      'ISACTIVE': isActive,
      'is_otp_verify': isOtpVerify ? 1 : 0,
    };
  }

  bool get isActiveUser => isActive == 'Y';
  
  String get displayRole {
    switch (userType.toLowerCase()) {
      case 'admin':
        return 'Administrator';
      case 'employee':
        return 'Employee';
      default:
        return userType;
    }
  }

  String get formattedMobile => '+91 $mobile';
  
  String get fullAddress => '$address, $city, $province - $zip';
}

class EmployeeStats {
  final int ordersCreated;
  final double totalSalesValue;
  final int totalDwrEntries;
  final int completedDays;

  EmployeeStats({
    required this.ordersCreated,
    required this.totalSalesValue,
    required this.totalDwrEntries,
    required this.completedDays,
  });

  factory EmployeeStats.fromJson(Map<String, dynamic> json) {
    return EmployeeStats(
      ordersCreated: _parseInt(json['orders_created']) ?? 0,
      totalSalesValue: _parseDouble(json['total_sales_value']) ?? 0.0,
      totalDwrEntries: _parseInt(json['total_dwr_entries']) ?? 0,
      completedDays: _parseInt(json['completed_days']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orders_created': ordersCreated,
      'total_sales_value': totalSalesValue,
      'total_dwr_entries': totalDwrEntries,
      'completed_days': completedDays,
    };
  }
}

class UserDetailsResponse {
  final UserManagementUser user;
  final EmployeeStats? employeeStats;

  UserDetailsResponse({
    required this.user,
    this.employeeStats,
  });

  factory UserDetailsResponse.fromJson(Map<String, dynamic> json) {
    return UserDetailsResponse(
      user: UserManagementUser.fromJson(json['user']),
      employeeStats: json['employeeStats'] != null 
          ? EmployeeStats.fromJson(json['employeeStats']) 
          : null,
    );
  }
}

class CreateUserResponse {
  final UserManagementUser user;
  final String createdBy;
  final String defaultPassword;
  final String userType;

  CreateUserResponse({
    required this.user,
    required this.createdBy,
    required this.defaultPassword,
    required this.userType,
  });

  factory CreateUserResponse.fromJson(Map<String, dynamic> json) {
    return CreateUserResponse(
      user: UserManagementUser.fromJson(json['user']),
      createdBy: json['createdBy']?.toString() ?? '',
      defaultPassword: json['defaultPassword']?.toString() ?? '',
      userType: json['userType']?.toString() ?? '',
    );
  }
}

class UpdateUserStatusRequest {
  final String isActive;

  UpdateUserStatusRequest({
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
    };
  }
}

class UserSearchPagination {
  final int currentPage;
  final int totalPages;
  final int totalUsers;
  final int limit;
  final bool hasNext;
  final bool hasPrev;

  UserSearchPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalUsers,
    required this.limit,
    required this.hasNext,
    required this.hasPrev,
  });

  factory UserSearchPagination.fromJson(Map<String, dynamic> json) {
    return UserSearchPagination(
      currentPage: _parseInt(json['currentPage']) ?? 1,
      totalPages: _parseInt(json['totalPages']) ?? 1,
      totalUsers: _parseInt(json['totalUsers']) ?? 0,
      limit: _parseInt(json['limit']) ?? 10,
      hasNext: json['hasNext'] == true,
      hasPrev: json['hasPrev'] == true,
    );
  }
}

class UserSearchResponse {
  final List<UserManagementUser> users;
  final UserSearchPagination pagination;
  final String searchQuery;
  final String? userTypeFilter;

  UserSearchResponse({
    required this.users,
    required this.pagination,
    required this.searchQuery,
    this.userTypeFilter,
  });

  factory UserSearchResponse.fromJson(Map<String, dynamic> json) {
    return UserSearchResponse(
      users: (json['users'] as List)
          .map((user) => UserManagementUser.fromJson(user))
          .toList(),
      pagination: UserSearchPagination.fromJson(json['pagination']),
      searchQuery: json['searchQuery']?.toString() ?? '',
      userTypeFilter: json['userTypeFilter']?.toString(),
    );
  }
} 