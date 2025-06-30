// Helper methods for safe type conversion
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  if (value is double) return value.toInt();
  return null;
}

class CustomerLead {
  final int custldId;
  final String? custldType;
  final String custldName;
  final String custldShopName;
  final int custldMobileNo;
  final String custldAddress;
  final int custldPinCode;
  final String? custldEmailId;
  final String? custldCountry;
  final String? custldState;
  final String? custldCity;
  final String? custldGstNo;
  final String custldDelStatus;
  final DateTime createdDate;
  final DateTime updatedDate;
  final String createdBy;
  final String updatedBy;

  CustomerLead({
    required this.custldId,
    this.custldType,
    required this.custldName,
    required this.custldShopName,
    required this.custldMobileNo,
    required this.custldAddress,
    required this.custldPinCode,
    this.custldEmailId,
    this.custldCountry,
    this.custldState,
    this.custldCity,
    this.custldGstNo,
    required this.custldDelStatus,
    required this.createdDate,
    required this.updatedDate,
    required this.createdBy,
    required this.updatedBy,
  });

  factory CustomerLead.fromJson(Map<String, dynamic> json) {
    return CustomerLead(
      custldId: _parseInt(json['CUSTLD_ID']) ?? 0,
      custldType: json['CUSTLD_TYPE']?.toString(),
      custldName: json['CUSTLD_NAME']?.toString() ?? '',
      custldShopName: json['CUSTLD_SHOP_NAME']?.toString() ?? '',
      custldMobileNo: _parseInt(json['CUSTLD_MOBILE_NO']) ?? 0,
      custldAddress: json['CUSTLD_ADDRESS']?.toString() ?? '',
      custldPinCode: _parseInt(json['CUSTLD_PIN_CODE']) ?? 0,
      custldEmailId: json['CUSTLD_EMAIL_ID']?.toString(),
      custldCountry: json['CUSTLD_COUNTRY']?.toString(),
      custldState: json['CUSTLD_STATE']?.toString(),
      custldCity: json['CUSTLD_CITY']?.toString(),
      custldGstNo: json['CUSTLD_GST_NO']?.toString(),
      custldDelStatus: json['CUSTLD_DEL_STATUS']?.toString() ?? 'active',
      createdDate: json['CREATED_DATE'] != null 
          ? DateTime.tryParse(json['CREATED_DATE'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedDate: json['UPDATED_DATE'] != null 
          ? DateTime.tryParse(json['UPDATED_DATE'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdBy: json['CREATED_BY']?.toString() ?? '',
      updatedBy: json['UPDATED_BY']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CUSTLD_ID': custldId,
      'CUSTLD_TYPE': custldType,
      'CUSTLD_NAME': custldName,
      'CUSTLD_SHOP_NAME': custldShopName,
      'CUSTLD_MOBILE_NO': custldMobileNo,
      'CUSTLD_ADDRESS': custldAddress,
      'CUSTLD_PIN_CODE': custldPinCode,
      'CUSTLD_EMAIL_ID': custldEmailId,
      'CUSTLD_COUNTRY': custldCountry,
      'CUSTLD_STATE': custldState,
      'CUSTLD_CITY': custldCity,
      'CUSTLD_GST_NO': custldGstNo,
      'CUSTLD_DEL_STATUS': custldDelStatus,
      'CREATED_DATE': createdDate.toIso8601String(),
      'UPDATED_DATE': updatedDate.toIso8601String(),
      'CREATED_BY': createdBy,
      'UPDATED_BY': updatedBy,
    };
  }

  // Utility getters
  String get formattedMobile => '+91 $custldMobileNo';
  String get displayName => custldName.isNotEmpty ? custldName : 'Unknown';
  String get displayShopName => custldShopName.isNotEmpty ? custldShopName : 'No Shop Name';
  String get fullAddress => [custldAddress, custldCity, custldState].where((s) => s != null && s.isNotEmpty).join(', ');
  bool get isActive => custldDelStatus.toLowerCase() == 'active';
}

class CustomerLeadPagination {
  final int currentPage;
  final int totalPages;
  final int totalLeads;
  final int limit;
  final bool hasNext;
  final bool hasPrev;

  CustomerLeadPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalLeads,
    required this.limit,
    required this.hasNext,
    required this.hasPrev,
  });

  factory CustomerLeadPagination.fromJson(Map<String, dynamic> json) {
    return CustomerLeadPagination(
      currentPage: _parseInt(json['currentPage']) ?? 1,
      totalPages: _parseInt(json['totalPages']) ?? 1,
      totalLeads: _parseInt(json['totalLeads']) ?? 0,
      limit: _parseInt(json['limit']) ?? 10,
      hasNext: json['hasNext'] == true,
      hasPrev: json['hasPrev'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalLeads': totalLeads,
      'limit': limit,
      'hasNext': hasNext,
      'hasPrev': hasPrev,
    };
  }
}

class CustomerLeadFilters {
  final String? type;
  final String? status;
  final String? city;
  final String? state;
  final String? search;

  CustomerLeadFilters({
    this.type,
    this.status,
    this.city,
    this.state,
    this.search,
  });

  factory CustomerLeadFilters.fromJson(Map<String, dynamic> json) {
    return CustomerLeadFilters(
      type: json['type']?.toString(),
      status: json['status']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      search: json['search']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'status': status,
      'city': city,
      'state': state,
      'search': search,
    };
  }
}

class CustomerLeadResponse {
  final List<CustomerLead> leads;
  final CustomerLeadPagination pagination;
  final CustomerLeadFilters? filters;
  final String? searchQuery;
  final String? accessedBy;
  final String? accessedByRole;
  final String? searchedBy;
  final String? searchedByRole;

  CustomerLeadResponse({
    required this.leads,
    required this.pagination,
    this.filters,
    this.searchQuery,
    this.accessedBy,
    this.accessedByRole,
    this.searchedBy,
    this.searchedByRole,
  });

  factory CustomerLeadResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    
    return CustomerLeadResponse(
      leads: (data['leads'] as List)
          .map((lead) => CustomerLead.fromJson(lead))
          .toList(),
      pagination: CustomerLeadPagination.fromJson(data['pagination']),
      filters: data['filters'] != null 
          ? CustomerLeadFilters.fromJson(data['filters']) 
          : null,
      searchQuery: data['searchQuery']?.toString(),
      accessedBy: json['accessedBy']?.toString(),
      accessedByRole: json['accessedByRole']?.toString(),
      searchedBy: json['searchedBy']?.toString(),
      searchedByRole: json['searchedByRole']?.toString(),
    );
  }
} 