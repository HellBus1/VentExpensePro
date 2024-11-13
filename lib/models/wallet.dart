class Wallet {
  final int? id;
  final String name;
  final double balance;
  final String? icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wallet({
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
      'wlt_icon': icon,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['wlt_id'],
      name: map['wlt_name'],
      balance: map['wlt_balance'],
      icon: map['wlt_icon'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}
