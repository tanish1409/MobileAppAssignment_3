class FoodItem {
  final int? id; // Nullable for when creating a new item
  final String name;
  final double cost;

  FoodItem({this.id, required this.name, required this.cost});

  // Convert a FoodItem object into a Map. The keys must correspond to the names of the columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'cost': cost,
    };
  }

  // Extract a FoodItem object from a Map object.
  static FoodItem fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      cost: map['cost'] as double,
    );
  }
}