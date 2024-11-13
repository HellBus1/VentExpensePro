class IconModel {
  final int id;
  final int iconCode;
  final String iconColor;

  IconModel({
    required this.id,
    required this.iconCode,
    required this.iconColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'icon_id': id,
      'icon_code': iconCode,
      'icon_color': iconColor,
    };
  }

  factory IconModel.fromMap(Map<String, dynamic> map) {
    return IconModel(
      id: map['icon_id'],
      iconCode: map['icon_code'],
      iconColor: map['icon_color'],
    );
  }
}
