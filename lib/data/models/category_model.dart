import '../../domain/entities/category.dart';

/// SQLite-compatible model for [Category].
class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.icon,
    super.isCustom,
  });

  /// Creates a [CategoryModel] from a SQLite row map.
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String,
      isCustom: (map['is_custom'] as int) == 1,
    );
  }

  /// Creates a [CategoryModel] from a domain [Category].
  factory CategoryModel.fromEntity(Category category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      icon: category.icon,
      isCustom: category.isCustom,
    );
  }

  /// Converts this model to a SQLite row map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'is_custom': isCustom ? 1 : 0,
    };
  }
}
