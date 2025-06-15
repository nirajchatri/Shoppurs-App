class Address {
  final int addressId;
  final int userId;
  final String address;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final String landmark;
  final String addressType;
  final bool isDefault;
  final String delStatus;
  final DateTime createdDate;
  final DateTime updatedDate;
  final double? latitude;
  final double? longitude;

  Address({
    required this.addressId,
    required this.userId,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    required this.landmark,
    required this.addressType,
    required this.isDefault,
    required this.delStatus,
    required this.createdDate,
    required this.updatedDate,
    this.latitude,
    this.longitude,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      addressId: json['ADDRESS_ID'] ?? 0,
      userId: json['USER_ID'] ?? 0,
      address: json['ADDRESS'] ?? '',
      city: json['CITY'] ?? '',
      state: json['STATE'] ?? '',
      country: json['COUNTRY'] ?? '',
      pincode: json['PINCODE'] ?? '',
      landmark: json['LANDMARK'] ?? '',
      addressType: json['ADDRESS_TYPE'] ?? '',
      isDefault: (json['IS_DEFAULT'] ?? 0) == 1,
      delStatus: json['DEL_STATUS']?.toString() ?? '',
      createdDate: json['CREATED_DATE'] != null ? DateTime.tryParse(json['CREATED_DATE'].toString()) ?? DateTime(1970) : DateTime(1970),
      updatedDate: json['UPDATED_DATE'] != null ? DateTime.tryParse(json['UPDATED_DATE'].toString()) ?? DateTime(1970) : DateTime(1970),
      latitude: json['LATITUDE'] != null ? double.tryParse(json['LATITUDE'].toString()) : null,
      longitude: json['LONGITUDE'] != null ? double.tryParse(json['LONGITUDE'].toString()) : null,
    );
  }

  String get fullAddress => '$address, $city, $state, $country - $pincode';
} 