class Category {
  final int id;
  final String name;
  final String imageUrl;
  final List<Map<String, dynamic>>? subCategories;

  Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.subCategories,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['CATEGORY_ID'],
      name: json['CATEGORY_NAME'],
      imageUrl: json['CAT_IMAGE'],
      subCategories: json['sub_categories'] != null 
        ? List<Map<String, dynamic>>.from(json['sub_categories'])
        : null,
    );
  }
} 