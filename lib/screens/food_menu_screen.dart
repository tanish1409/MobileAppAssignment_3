import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/food_item.dart';
import 'order_planning_screen.dart'; // We'll create this next

class FoodMenuScreen extends StatelessWidget {
  const FoodMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the provider to rebuild when food items change
    final provider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Ordering App'),
        backgroundColor: Colors.teal,
      ),
      body: provider.foodItems.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: provider.foodItems.length,
        itemBuilder: (context, index) {
          final item = provider.foodItems[index];
          return _FoodItemTile(item: item, provider: provider);
        },
      ),
      // Floating Action Button for adding a new item
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context, null),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
      // Navigation to the core planning screen
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const OrderPlanningScreen(),
              ),
            );
          },
          icon: const Icon(Icons.fastfood),
          label: const Text('Go to Order Planning'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(15),
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  // Helper function to show the Add/Edit dialog
  void _showAddEditDialog(BuildContext context, FoodItem? item) {
    showDialog(
      context: context,
      builder: (ctx) => AddEditFoodItemDialog(item: item),
    );
  }
}

// Widget for displaying and managing a single food item
class _FoodItemTile extends StatelessWidget {
  final FoodItem item;
  final OrderProvider provider;

  const _FoodItemTile({required this.item, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 2,
      child: ListTile(
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('\$${item.cost.toStringAsFixed(2)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Update Feature (Requirement 5)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showAddEditDialog(context, item),
            ),
            // Delete Feature (Requirement 5)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                provider.deleteFoodItem(item.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.name} deleted.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, FoodItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AddEditFoodItemDialog(item: item),
    );
  }
}

// Dialog for adding or editing a food item
class AddEditFoodItemDialog extends StatefulWidget {
  final FoodItem? item; // If non-null, we are editing

  const AddEditFoodItemDialog({super.key, this.item});

  @override
  State<AddEditFoodItemDialog> createState() => _AddEditFoodItemDialogState();
}

class _AddEditFoodItemDialogState extends State<AddEditFoodItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _costText;

  @override
  void initState() {
    super.initState();
    // Initialize fields with existing data if editing
    _name = widget.item?.name ?? '';
    _costText = widget.item?.cost.toString() ?? '';
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final provider = context.read<OrderProvider>();
      final double cost = double.parse(_costText);

      final newItem = FoodItem(
        id: widget.item?.id, // Keep ID if editing
        name: _name,
        cost: cost,
      );

      if (widget.item == null) {
        // Add Feature (Requirement 5)
        provider.addFoodItem(newItem);
      } else {
        // Update Feature (Requirement 5)
        provider.updateFoodItem(newItem);
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${newItem.name} successfully ${widget.item == null ? 'added' : 'updated'}.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Add New Food Item' : 'Edit Food Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Food Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name.';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                initialValue: _costText,
                decoration: const InputDecoration(labelText: 'Cost (\$)', hintText: 'e.g., 9.99'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a cost.';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number.';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Cost must be positive.';
                  }
                  return null;
                },
                onSaved: (value) => _costText = value!,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          onPressed: _saveForm,
          child: Text(widget.item == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}