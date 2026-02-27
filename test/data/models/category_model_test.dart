import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/data/models/category_model.dart';
import 'package:vent_expense_pro/domain/entities/category.dart';

void main() {
  group('CategoryModel', () {
    group('fromMap', () {
      test('should create a default CategoryModel from map', () {
        final map = {
          'id': 'food',
          'name': 'Food',
          'icon': 'food',
          'is_custom': 0,
        };

        final model = CategoryModel.fromMap(map);

        expect(model.id, 'food');
        expect(model.name, 'Food');
        expect(model.icon, 'food');
        expect(model.isCustom, false);
      });

      test('should create a custom CategoryModel from map', () {
        final map = {
          'id': 'custom-1',
          'name': 'Pets',
          'icon': 'pets',
          'is_custom': 1,
        };

        final model = CategoryModel.fromMap(map);
        expect(model.isCustom, true);
      });
    });

    group('fromEntity', () {
      test('should create a CategoryModel from a domain Category', () {
        const category = Category(
          id: 'bills',
          name: 'Bills',
          icon: 'bills',
        );

        final model = CategoryModel.fromEntity(category);

        expect(model.id, category.id);
        expect(model.name, category.name);
        expect(model.icon, category.icon);
        expect(model.isCustom, category.isCustom);
      });
    });

    group('toMap', () {
      test('should convert default category to SQLite map', () {
        const model = CategoryModel(
          id: 'food',
          name: 'Food',
          icon: 'food',
        );

        final map = model.toMap();

        expect(map['id'], 'food');
        expect(map['name'], 'Food');
        expect(map['icon'], 'food');
        expect(map['is_custom'], 0);
      });

      test('should convert custom category to SQLite map', () {
        const model = CategoryModel(
          id: 'custom-1',
          name: 'Gym',
          icon: 'gym',
          isCustom: true,
        );

        final map = model.toMap();
        expect(map['is_custom'], 1);
      });
    });

    group('round-trip', () {
      test('fromMap → toMap should produce equivalent data', () {
        final original = {
          'id': 'transport',
          'name': 'Transport',
          'icon': 'transport',
          'is_custom': 0,
        };

        final model = CategoryModel.fromMap(original);
        final result = model.toMap();

        expect(result, equals(original));
      });
    });
  });
}
