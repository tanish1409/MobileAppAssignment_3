import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/order_provider.dart';
import '../models/order_plan.dart';
import 'order_planning_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  DateTime _queryDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Query for today's date upon initial load (Requirement 4)
    _queryPlan();
  }

  // Function to query the database and update provider state (Requirement 4)
  void _queryPlan() {
    final String formattedDate = DateFormat('yyyy-MM-dd').format(_queryDate);
    context.read<OrderProvider>().queryOrderPlanByDate(formattedDate);
  }

  // Date selection for query (Requirement 4)
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _queryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _queryDate) {
      setState(() {
        _queryDate = picked;
      });
      _queryPlan(); // Re-query when the date changes
    }
  }

  // Delete the queried order plan (Requirement 5: Delete)
  void _deletePlan(OrderPlan plan, OrderProvider provider) {
    if (plan.id == null) return;

    provider.deletePlan(plan.id!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order Plan for ${plan.date} deleted.')),
    );
  }


  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History & Query'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // Date Picker for Query (Requirement 4)
            Card(
              elevation: 3,
              child: ListTile(
                title: Text('Query Date: ${DateFormat('EEE, MMM d, yyyy').format(_queryDate)}'),
                trailing: const Icon(Icons.search),
                onTap: () => _selectDate(context),
              ),
            ),
            const SizedBox(height: 15),

            // Display Area for Order Plan (Requirement 4)
            Expanded(
              child: provider.queriedOrderPlan == null
                  ? _buildNotFound(DateFormat('EEE, MMM d, yyyy').format(_queryDate))
                  : _buildPlanDetails(provider.queriedOrderPlan!, provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound(String date) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sentiment_dissatisfied, size: 50, color: Colors.grey),
          const SizedBox(height: 10),
          Text(
            'No Order Plan found for $date.',
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildPlanDetails(OrderPlan plan, OrderProvider provider) {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary
            Text(
              'Plan Details for ${plan.date}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const Divider(),
            _detailRow('Target Cost:', '\$${plan.targetCost.toStringAsFixed(2)}'),
            _detailRow('Total Cost:', '\$${plan.totalCost.toStringAsFixed(2)}',
                color: plan.totalCost > plan.targetCost ? Colors.red : Colors.green.shade700),

            const SizedBox(height: 15),
            const Text('Selected Items:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const Divider(),

            // List of Items
            Expanded(
              child: ListView.builder(
                itemCount: provider.queriedPlanItems.length,
                itemBuilder: (ctx, index) {
                  final item = provider.queriedPlanItems[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('• ${item.name}'),
                        Text('\$${item.cost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Delete and Edit Buttons (Requirement 5: Edit and Delete)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to planning screen with the plan data
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => OrderPlanningScreen(planToEdit: plan),
                          ),
                        ).then((_) {
                          // When returning from the edit screen, re-query the history
                          _queryPlan();
                        });
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit This Plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deletePlan(plan, provider),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Delete Plan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}