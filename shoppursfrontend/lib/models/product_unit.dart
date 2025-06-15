class ProductUnit {
  String unitName;
  String unitValue;
  String unitRate;

  ProductUnit({
    required this.unitName,
    required this.unitValue,
    required this.unitRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'unitName': unitName,
      'unitValue': unitValue,
      'unitRate': unitRate,
    };
  }

  factory ProductUnit.fromJson(Map<String, dynamic> json) {
    return ProductUnit(
      unitName: json['unitName'] ?? '',
      unitValue: json['unitValue'] ?? '',
      unitRate: json['unitRate'] ?? '',
    );
  }
} 