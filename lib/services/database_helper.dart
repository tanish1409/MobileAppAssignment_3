import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/food_item.dart';
import '../models/order_plan.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Database Initialization

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('food_order.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // 1. FoodItem Table (Store 20+ food items)
    await db.execute('''
      CREATE TABLE food_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        cost REAL NOT NULL
      )
    ''');

    // 2. OrderPlan Table (Save the selected food items (order plan))
    await db.execute('''
      CREATE TABLE order_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        targetCost REAL NOT NULL,
        totalCost REAL NOT NULL,
        foodItemIds TEXT NOT NULL
      )
    ''');

    // Pre-populate the database with at least 20 food items (inserting 21 here making it 20+)
    await _insertInitialFoodItems(db);
  }

  Future _insertInitialFoodItems(Database db) async {
    final List<FoodItem> initialItems = [
      FoodItem(name: 'Classic Burger', cost: 8.50),
      FoodItem(name: 'Veggie Sandwich', cost: 7.00),
      FoodItem(name: 'Caesar Salad', cost: 9.25),
      FoodItem(name: 'Chicken Pasta', cost: 12.00),
      FoodItem(name: 'Steak Fries', cost: 18.99),
      FoodItem(name: 'Mushroom Pizza', cost: 15.50),
      FoodItem(name: 'Soup of the Day', cost: 4.50),
      FoodItem(name: 'Fries (Small)', cost: 3.00),
      FoodItem(name: 'Coke', cost: 2.50),
      FoodItem(name: 'Orange Juice', cost: 3.25),
      FoodItem(name: 'Breakfast Burrito', cost: 9.50),
      FoodItem(name: 'Pancakes Stack', cost: 10.00),
      FoodItem(name: 'Grilled Salmon', cost: 16.75),
      FoodItem(name: 'Taco Plate (3)', cost: 11.00),
      FoodItem(name: 'Sushi Roll (8pcs)', cost: 14.50),
      FoodItem(name: 'Brownie', cost: 4.00),
      FoodItem(name: 'Apple Pie', cost: 5.50),
      FoodItem(name: 'Iced Coffee', cost: 4.75),
      FoodItem(name: 'Milkshake', cost: 6.00),
      FoodItem(name: 'Chicken Wings (6)', cost: 9.99),
      FoodItem(name: 'Side Garden Salad', cost: 6.50),
    ];

    for (var item in initialItems) {
      await db.insert('food_items', item.toMap());
    }
  }

  // ------------------------------------
  // CRUD Operations for FoodItem
  // ------------------------------------

  // Add
  Future<FoodItem> createFoodItem(FoodItem item) async {
    final db = await instance.database;
    final id = await db.insert('food_items', item.toMap());
    return item.copyWith(id: id);
  }

  // Query/Read all
  Future<List<FoodItem>> readAllFoodItems() async {
    final db = await instance.database;
    final result = await db.query('food_items', orderBy: 'name ASC');
    return result.map((json) => FoodItem.fromMap(json)).toList();
  }

  // Update
  Future<int> updateFoodItem(FoodItem item) async {
    final db = await instance.database;
    return db.update(
      'food_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // Delete
  Future<int> deleteFoodItem(int id) async {
    final db = await instance.database;
    return await db.delete(
      'food_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ------------------------------------
  // CRUD Operations for OrderPlan
  // ------------------------------------

  // Save/Create Order Plan
  Future<OrderPlan> createOrderPlan(OrderPlan plan) async {
    final db = await instance.database;
    final id = await db.insert('order_plans', plan.toMap());
    return OrderPlan(
      id: id,
      date: plan.date,
      targetCost: plan.targetCost,
      totalCost: plan.totalCost,
      foodItemIds: plan.foodItemIds,
    );
  }

  // Query/Read by Date
  Future<OrderPlan?> readOrderPlanByDate(String date) async {
    final db = await instance.database;
    final maps = await db.query(
      'order_plans',
      columns: OrderPlan.fields, // assuming a static list of fields is defined in OrderPlan model
      where: 'date = ?',
      whereArgs: [date],
    );

    if (maps.isNotEmpty) {
      return OrderPlan.fromMap(maps.first);
    } else {
      return null;
    }
  }

  // Note: For simplicity and based on the requirement, we will focus on read by date,
  // but update/delete for plans are similar to FoodItem's.

  // Update Order Plan
  Future<int> updateOrderPlan(OrderPlan plan) async {
    final db = await instance.database;
    return db.update(
      'order_plans',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  // Delete Order Plan
  Future<int> deleteOrderPlan(int id) async {
    final db = await instance.database;
    return await db.delete(
      'order_plans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Close the database connection
  Future close() async {
    final db = await instance.database;
    _database = null;
    db.close();
  }
}

// Add copyWith method to FoodItem model for convenience (as used in createFoodItem)
extension FoodItemCopyWith on FoodItem {
  FoodItem copyWith({
    int? id,
    String? name,
    double? cost,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      cost: cost ?? this.cost,
    );
  }
}
// Add a static field list to OrderPlan for use in readOrderPlanByDate (as used in readOrderPlanByDate)
extension OrderPlanFields on OrderPlan {
  static final List<String> fields = ['id', 'date', 'targetCost', 'totalCost', 'foodItemIds'];
}