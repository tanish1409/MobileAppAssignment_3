import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../models/food_item.dart';
import '../models/order_plan.dart';

class OrderProvider extends ChangeNotifier {
  // Store the full menu of food items (Requirement 1)
  List<FoodItem> _foodItems = [];
  List<FoodItem> get foodItems => _foodItems;

  // Store the currently selected items for a new order plan (Requirement 2)
  final Set<int> _selectedFoodItemIds = {};
  double _currentTotalCost = 0.0;

  Set<int> get selectedFoodItemIds => _selectedFoodItemIds;
  double get currentTotalCost => _currentTotalCost;

  // Store the retrieved order plan for a query (Requirement 4)
  OrderPlan? _queriedOrderPlan;
  List<FoodItem> _queriedPlanItems = [];

  OrderPlan? get queriedOrderPlan => _queriedOrderPlan;
  List<FoodItem> get queriedPlanItems => _queriedPlanItems;

  OrderProvider() {
    // Load initial data when the provider is created
    loadFoodItems();
  }

  // ------------------------------------
  // Initialization & Food Item CRUD
  // ------------------------------------

  Future<void> loadFoodItems() async {
    _foodItems = await DatabaseHelper.instance.readAllFoodItems();
    notifyListeners();
  }

  // Adds a new food item to the database and updates the state (Requirement 5: Add)
  Future<void> addFoodItem(FoodItem item) async {
    final newItem = await DatabaseHelper.instance.createFoodItem(item);
    _foodItems.add(newItem);
    notifyListeners();
  }

  // Updates an existing food item (Requirement 5: Update)
  Future<void> updateFoodItem(FoodItem item) async {
    await DatabaseHelper.instance.updateFoodItem(item);
    final index = _foodItems.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _foodItems[index] = item;
      notifyListeners();
    }
  }

  // Deletes a food item (Requirement 5: Delete)
  Future<void> deleteFoodItem(int id) async {
    await DatabaseHelper.instance.deleteFoodItem(id);
    _foodItems.removeWhere((item) => item.id == id);
    notifyListeners();
  }


  // ------------------------------------
  // Order Planning Logic (Requirement 2)
  // ------------------------------------

  // Handles selecting/deselecting a food item
  void toggleFoodItem(int foodItemId, double cost) {
    if (_selectedFoodItemIds.contains(foodItemId)) {
      _selectedFoodItemIds.remove(foodItemId);
      _currentTotalCost -= cost;
    } else {
      _selectedFoodItemIds.add(foodItemId);
      _currentTotalCost += cost;
    }
    // Ensures cost is rounded to two decimal places for display accuracy
    _currentTotalCost = double.parse(_currentTotalCost.toStringAsFixed(2));
    notifyListeners();
  }

  // Resets the current selection after an order is saved or cancelled
  void clearCurrentSelection() {
    _selectedFoodItemIds.clear();
    _currentTotalCost = 0.0;
    notifyListeners();
  }

  // Load selection state from OrderPlan for editing
  void loadSelectionFromPlan(List<int> ids, double totalCost) {
    _selectedFoodItemIds
      ..clear()
      ..addAll(ids);
    _currentTotalCost = totalCost;
    // NOTE: We don't call notifyListeners() here, as initState will rebuild the screen anyway.
  }

  // ------------------------------------
  // Order Plan CRUD (Requirement 3, 5)
  // ------------------------------------

  // Saves the current order plan (Requirement 3)
  Future<void> saveOrderPlan({
    required String date,
    required double targetCost,
    required bool isUpdate, // 🆕 NEW FLAG
    int? existingPlanId, // 🆕 NEW ID for update
  }) async {
    final idsString = _selectedFoodItemIds.join(',');

    final plan = OrderPlan(
      id: isUpdate ? existingPlanId : null, // Use existing ID for update
      date: date,
      targetCost: targetCost,
      totalCost: _currentTotalCost,
      foodItemIds: idsString,
    );

    if (isUpdate && existingPlanId != null) {
      await DatabaseHelper.instance.updateOrderPlan(plan);
    } else {
      // Note: We skip the uniqueness check here, as it is now in the UI.
      await DatabaseHelper.instance.createOrderPlan(plan);
    }

    clearCurrentSelection(); // Clear selection after saving/updating
  }

  // Deletes an Order Plan (Requirement 5: Delete)
  Future<void> deletePlan(int planId) async {
    await DatabaseHelper.instance.deleteOrderPlan(planId);
    // Clear the queried plan if it was the one deleted
    if (_queriedOrderPlan?.id == planId) {
      _queriedOrderPlan = null;
      _queriedPlanItems = [];
    }
    notifyListeners();
  }

  // Note: Update for OrderPlan can be implemented as a simple delete and recreate with new data.

  // ------------------------------------
  // Query Feature (Requirement 4)
  // ------------------------------------

  Future<void> queryOrderPlanByDate(String date) async {
    _queriedOrderPlan = await DatabaseHelper.instance.readOrderPlanByDate(date);
    _queriedPlanItems.clear();

    if (_queriedOrderPlan != null) {
      // Convert the saved comma-separated string of IDs back into a list of integers
      final idsList = _queriedOrderPlan!.foodItemIds
          .split(',')
          .map((id) => int.tryParse(id)!)
          .toList();

      // Get the actual FoodItem objects for display
      _queriedPlanItems = _foodItems.where((item) => idsList.contains(item.id)).toList();
    }

    notifyListeners();
  }
}