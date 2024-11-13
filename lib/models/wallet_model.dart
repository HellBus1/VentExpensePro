import 'package:vent_expense_pro/models/icon_model.dart';

class WalletModel {
  final int? id;
  final String name;
  final double balance;
  final IconModel? icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  WalletModel({
    this.id,
    required this.name,
    required this.balance,
    this.icon,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'wlt_id': id,
      'wlt_name': name,
      'wlt_balance': balance,
      'wlt_icon': icon?.id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      id: map['wlt_id'],
      name: map['wlt_name'],
      balance: map['wlt_balance'],
      icon: map['wlt_icon'] != null
          ? IconModel.fromMap({
              'icon_code': map['icon_code'],
              'icon_color': map['icon_color'],
              'icon_id': map['icon_id'],
            })
          : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
