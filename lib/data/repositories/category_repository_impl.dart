import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/local_database.dart';
import '../models/category_model.dart';

/// Concrete [CategoryRepository] backed by local SQLite.
class CategoryRepositoryImpl implements CategoryRepository {
  @override
  Future<List<Category>> getAll() async {
    final db = await LocalDatabase.database;
    final maps = await db.query('categories', orderBy: 'name ASC');
    return maps.map(CategoryModel.fromMap).toList();
  }

  @override
  Future<Category?> getById(String id) async {
    final db = await LocalDatabase.database;
    final maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CategoryModel.fromMap(maps.first);
  }

  @override
  Future<Category> insert(Category category) async {
    final db = await LocalDatabase.database;
    final model = CategoryModel.fromEntity(category);
    await db.insert('categories', model.toMap());
    return model;
  }

  @override
  Future<Category> update(Category category) async {
    final db = await LocalDatabase.database;
    final model = CategoryModel.fromEntity(category);
    await db.update(
      'categories',
      model.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    return model;
  }

  @override
  Future<void> delete(String id) async {
    final db = await LocalDatabase.database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
