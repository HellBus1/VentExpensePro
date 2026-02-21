import 'package:flutter/foundation.dart' hide Category;

import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

/// Manages category state for the category management screen.
class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _categoryRepository;

  CategoryProvider(this._categoryRepository);

  List<Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  // — Getters —

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Pre-seeded (non-custom) categories.
  List<Category> get defaultCategories =>
      _categories.where((c) => !c.isCustom).toList();

  /// User-created custom categories.
  List<Category> get customCategories =>
      _categories.where((c) => c.isCustom).toList();

  // — Actions —

  /// Loads all categories.
  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _categoryRepository.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new custom category.
  Future<void> addCategory({
    required String id,
    required String name,
    required String icon,
  }) async {
    try {
      await _categoryRepository.insert(Category(
        id: id,
        name: name,
        icon: icon,
        isCustom: true,
      ));
      await loadCategories();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Updates a category name and/or icon.
  Future<void> updateCategory(Category category) async {
    try {
      await _categoryRepository.update(category);
      await loadCategories();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Deletes a custom category. Pre-seeded categories cannot be deleted.
  Future<bool> deleteCategory(String id) async {
    final cat = _categories.firstWhere(
      (c) => c.id == id,
      orElse: () => throw ArgumentError('Category not found: $id'),
    );

    if (!cat.isCustom) {
      _error = 'Cannot delete a default category';
      notifyListeners();
      return false;
    }

    try {
      await _categoryRepository.delete(id);
      await loadCategories();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
