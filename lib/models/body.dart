class BodyItem {
  final int id;
  final String? name;
  final String? category;
  final String? icon;
  final bool active;

  BodyItem({
    required this.id,
    this.name,
    this.category,
    this.icon,
    this.active = true,
  });

  factory BodyItem.fromJson(Map<String, dynamic> json) {
    return BodyItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
      category: json['category'] as String?,
      icon: json['icon'] as String?,
      active: (json['active'] as bool?) ?? true,
    );
  }
}


