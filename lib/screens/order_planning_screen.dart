import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/order_provider.dart';
import 'order_history_screen.dart';

class OrderPlanningScreen extends StatefulWidget {
  const OrderPlanningScreen({super.key});

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
    // Default the target cost to a reasonable starting value
    _targetCostController.text = '25.00';
    _targetCost = 25.00;
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

    await provider.saveOrderPlan(
      date: formattedDate,
      targetCost: _targetCost,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order Plan for $formattedDate saved successfully!')),
    );
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
                '⚠️ BUDGET EXCEEDED!',
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