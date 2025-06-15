class Product {
  final int id;
  final String name;
  final String desc;
  final String mrp;
  final String sp;
  final String image1;
  final List<dynamic> units;
  final int? prodSubCatId;
  final String? prodCode;
  final String? prodReorderLevel;
  final String? prodQoh;
  final String? prodHsnCode;
  final String? prodCgst;
  final String? prodIgst;
  final String? prodSgst;
  final String? prodMfgDate;
  final String? prodExpiryDate;
  final String? prodMfgBy;
  final String? prodImage2;
  final String? prodImage3;
  final int? prodCatId;
  final String? isBarcodeAvailable;
  final String? barcodes;

  Product({
    required this.id,
    required this.name,
    required this.desc,
    required this.mrp,
    required this.sp,
    required this.image1,
    required this.units,
    this.prodSubCatId,
    this.prodCode,
    this.prodReorderLevel,
    this.prodQoh,
    this.prodHsnCode,
    this.prodCgst,
    this.prodIgst,
    this.prodSgst,
    this.prodMfgDate,
    this.prodExpiryDate,
    this.prodMfgBy,
    this.prodImage2,
    this.prodImage3,
    this.prodCatId,
    this.isBarcodeAvailable,
    this.barcodes,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['PROD_ID'] ?? 0,
      name: json['PROD_NAME'] ?? '',
      desc: json['PROD_DESC'] ?? '',
      mrp: json['PROD_MRP'] ?? '',
      sp: json['PROD_SP'] ?? '',
      image1: json['PROD_IMAGE_1'] ?? '',
      units: json['units'] ?? [],
      prodSubCatId: json['PROD_SUB_CAT_ID'],
      prodCode: json['PROD_CODE'],
      prodReorderLevel: json['PROD_REORDER_LEVEL'],
      prodQoh: json['PROD_QOH'],
      prodHsnCode: json['PROD_HSN_CODE'],
      prodCgst: json['PROD_CGST'],
      prodIgst: json['PROD_IGST'],
      prodSgst: json['PROD_SGST'],
      prodMfgDate: json['PROD_MFG_DATE'],
      prodExpiryDate: json['PROD_EXPIRY_DATE'],
      prodMfgBy: json['PROD_MFG_BY'],
      prodImage2: json['PROD_IMAGE_2'],
      prodImage3: json['PROD_IMAGE_3'],
      prodCatId: json['PROD_CAT_ID'],
      isBarcodeAvailable: json['IS_BARCODE_AVAILABLE'],
      barcodes: json['barcodes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'PROD_ID': id,
      'PROD_NAME': name,
      'PROD_DESC': desc,
      'PROD_MRP': mrp,
      'PROD_SP': sp,
      'PROD_IMAGE_1': image1,
      'units': units,
      'PROD_SUB_CAT_ID': prodSubCatId,
      'PROD_CODE': prodCode,
      'PROD_REORDER_LEVEL': prodReorderLevel,
      'PROD_QOH': prodQoh,
      'PROD_HSN_CODE': prodHsnCode,
      'PROD_CGST': prodCgst,
      'PROD_IGST': prodIgst,
      'PROD_SGST': prodSgst,
      'PROD_MFG_DATE': prodMfgDate,
      'PROD_EXPIRY_DATE': prodExpiryDate,
      'PROD_MFG_BY': prodMfgBy,
      'PROD_IMAGE_2': prodImage2,
      'PROD_IMAGE_3': prodImage3,
      'PROD_CAT_ID': prodCatId,
      'IS_BARCODE_AVAILABLE': isBarcodeAvailable,
      'barcodes': barcodes,
    };
  }
} 