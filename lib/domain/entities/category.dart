import 'package:equatable/equatable.dart';

/// A spending category (e.g. Food, Transport, Bills).
class Category extends Equatable {
  /// Unique identifier.
  final String id;

  /// Display name.
  final String name;

  /// Stamp-style icon identifier (maps to a CustomPainter design).
  final String icon;

  /// `false` for the pre-seeded set; `true` for user-created categories.
  final bool isCustom;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    this.isCustom = false,
  });

  /// Returns a copy with the given fields replaced.
  Category copyWith({String? id, String? name, String? icon, bool? isCustom}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  @override
  List<Object?> get props => [id, name, icon, isCustom];
}
