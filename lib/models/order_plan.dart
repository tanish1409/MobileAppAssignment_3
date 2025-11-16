class OrderPlan {
  final int? id;
  final String date;          // Format: YYYY-MM-DD
  final double targetCost;
  final double totalCost;
  final String foodItemIds;

  OrderPlan({
    this.id,
    required this.date,
    required this.targetCost,
    required this.totalCost,
    required this.foodItemIds,
  });

  // 👇 THIS IS THE REQUIRED STATIC FIELD
  static const List<String> fields = ['id', 'date', 'targetCost', 'totalCost', 'foodItemIds'];

  // Convert an OrderPlan object into a Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'targetCost': targetCost,
      'totalCost': totalCost,
      'foodItemIds': foodItemIds,
    };
  }

  // Extract an OrderPlan object from a Map object.
  static OrderPlan fromMap(Map<String, dynamic> map) {
    return OrderPlan(
      id: map['id'] as int?,
      date: map['date'] as String,
      targetCost: map['targetCost'] as double,
      totalCost: map['totalCost'] as double,
      foodItemIds: map['foodItemIds'] as String,
    );
  }
}