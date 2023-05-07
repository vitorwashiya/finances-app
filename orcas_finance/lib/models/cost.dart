class Cost {
  String categoryName;
  String subcategory;
  double value;
  DateTime dateCost;

  Cost({
    required this.dateCost,
    required this.categoryName,
    required this.subcategory,
    required this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryName': categoryName.toString(),
      'subcategory': subcategory.toString(),
      'value': value.toString(),
      'dateCost': dateCost.toIso8601String(),
    };
  }

  factory Cost.fromJson(Map<String, dynamic> json) {
    return Cost(
      categoryName: json['categoryName'],
      subcategory: json['subcategory'],
      value: double.parse(json['value']),
      dateCost: DateTime.parse(json['dateCost']),
    );
  }
}
