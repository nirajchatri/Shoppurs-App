class SubCategory {
  final int id;
  final String name;
  final int categoryId;
  final String image;
  final String delStatus;
  final String createdBy;
  final String updatedBy;
  final DateTime createdDate;
  final DateTime updatedDate;

  SubCategory({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.image,
    required this.delStatus,
    required this.createdBy,
    required this.updatedBy,
    required this.createdDate,
    required this.updatedDate,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['SUB_CATEGORY_ID'] ?? 0,
      name: json['SUB_CATEGORY_NAME'] ?? '',
      categoryId: json['SUB_CATEGORY_CAT_ID'] ?? 0,
      image: json['SUB_CAT_IMAGE'] ?? '',
      delStatus: json['DEL_STATUS'] ?? '0',
      createdBy: json['CREATED_BY'] ?? '',
      updatedBy: json['UPDATED_BY'] ?? '',
      createdDate: DateTime.parse(json['CREATED_DATE'] ?? DateTime.now().toIso8601String()),
      updatedDate: DateTime.parse(json['UPDATED_DATE'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get imageUrl => image;
} 