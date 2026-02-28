import '../entities/category.dart';

/// Contract for category persistence operations.
abstract class CategoryRepository {
  /// Returns all categories (pre-seeded + custom).
  Future<List<Category>> getAll();

  /// Returns a single category by [id], or `null` if not found.
  Future<Category?> getById(String id);

  /// Inserts a new custom category.
  Future<Category> insert(Category category);

  /// Updates an existing category.
  Future<Category> update(Category category);

  /// Deletes a custom category by [id].
  Future<void> delete(String id);
}
