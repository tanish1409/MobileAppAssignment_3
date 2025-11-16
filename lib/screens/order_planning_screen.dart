import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/order_provider.dart';
import 'order_history_screen.dart';
import '../models/order_plan.dart';
import '../services/database_helper.dart';

class OrderPlanningScreen extends StatefulWidget {
  final OrderPlan? planToEdit;
  const OrderPlanningScreen({super.key, this.planToEdit});

  @override
  State<OrderPlanningScreen> createState() => _OrderPlanningScreenState();
}

class _OrderPlanningScreenState extends State<OrderPlanningScreen> {
  final _targetCostController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  double _targetCost = 0.0;

  @override
  void initState() {
    super.initState();
    final provider = context.read<OrderProvider>();

    if (widget.planToEdit != null) {
      // 🆕 NEW: Load data from the plan being edited
      final plan = widget.planToEdit!;

      _selectedDate = DateFormat('yyyy-MM-dd').parse(plan.date);
      _targetCost = plan.targetCost;
      _targetCostController.text = plan.targetCost.toStringAsFixed(2);

      // Select the food items from the saved plan
      final idsList = plan.foodItemIds.split(',').map((id) => int.tryParse(id)).where((id) => id != null).cast<int>().toList();

      // We need a special method in OrderProvider to load a selection
      provider.loadSelectionFromPlan(idsList, plan.totalCost);

    } else {
      // Original setup for new plan
      _targetCostController.text = '25.00';
      _targetCost = 25.00;
      provider.clearCurrentSelection(); // Ensure no leftover selection from history query
    }
  }

  @override
  void dispose() {
    _targetCostController.dispose();
    super.dispose();
  }

  // Requirement 2: Date Selection
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Requirement 3: Save the Order Plan
  void _saveOrderPlan(OrderProvider provider) async {
    if (provider.selectedFoodItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one food item.')),
      );
      return;
    }

    if (provider.currentTotalCost > _targetCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Total cost exceeds the target amount.')),
      );
      return;
    }

    final String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Check for existing plan for this date
    final existingPlan = await DatabaseHelper.instance.readOrderPlanByDate(formattedDate);

    if (existingPlan != null && widget.planToEdit == null) {
      // If a plan exists AND we are not in an edit flow: BLOCK the save
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Only one food list available for $formattedDate. Use the History page to Edit the existing plan.'),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Determine if this is a CREATE or an UPDATE operation
    final bool isUpdate = widget.planToEdit != null;

    // Save/Update the plan using the provider (which now handles both)
    await provider.saveOrderPlan(
      date: formattedDate,
      targetCost: _targetCost,
      isUpdate: isUpdate, // Pass flag to provider
      existingPlanId: isUpdate ? widget.planToEdit!.id : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order Plan for $formattedDate ${isUpdate ? 'updated' : 'saved'} successfully!')),
    );

    // After updating, navigate back if it was an edit session
    if (isUpdate) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final isOverBudget = provider.currentTotalCost > _targetCost;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Order Planning'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // Target Cost and Date Selection Area (Requirement 2)
          _buildControlPanel(context),

          // Current Order Summary
          _buildSummaryCard(provider, isOverBudget),

          // Food Item Selection List
          Expanded(
            child: ListView.builder(
              itemCount: provider.foodItems.length,
              itemBuilder: (context, index) {
                final item = provider.foodItems[index];
                final isSelected = provider.selectedFoodItemIds.contains(item.id);

                return CheckboxListTile(
                  title: Text(item.name),
                  subtitle: Text('\$${item.cost.toStringAsFixed(2)}'),
                  value: isSelected,
                  onChanged: (bool? value) {
                    provider.toggleFoodItem(item.id!, item.cost);
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Save and Navigation Buttons
      bottomNavigationBar: _buildBottomActions(provider, isOverBudget),
    );
  }

  // Widget for Target Cost and Date
  Widget _buildControlPanel(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Target Cost Input (Requirement 2)
            TextFormField(
              controller: _targetCostController,
              decoration: const InputDecoration(
                labelText: 'Target Cost Per Day (\$)',
                hintText: 'e.g., 25.00',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                final cost = double.tryParse(value) ?? 0.0;
                setState(() {
                  _targetCost = cost;
                });
              },
            ),
            const SizedBox(height: 10),
            // Date Picker (Requirement 2)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Date: ${DateFormat('EEE, MMM d, yyyy').format(_selectedDate)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Select Date'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget for Total Cost Summary
  Widget _buildSummaryCard(OrderProvider provider, bool isOverBudget) {
    return Card(
      color: isOverBudget ? Colors.red.shade100 : Colors.green.shade100,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Target Cost: \$${_targetCost.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              'Selected Total: \$${provider.currentTotalCost.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isOverBudget ? Colors.red.shade900 : Colors.green.shade900,
              ),
            ),
            // Cost Validation Message (Requirement 2)
            if (isOverBudget)
              const Text(
                'BUDGET EXCEEDED!',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            if (!isOverBudget && provider.currentTotalCost > 0)
              const Text(
                'Budget OK.',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  // Widget for Save and Navigation
  Widget _buildBottomActions(OrderProvider provider, bool isOverBudget) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isOverBudget ? null : () => _saveOrderPlan(provider),
              icon: const Icon(Icons.save),
              label: const Text('Save Order Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(15),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const OrderHistoryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('View History'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}