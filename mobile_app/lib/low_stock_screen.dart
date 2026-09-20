import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LowStockScreen extends StatefulWidget {
  final int ownerId;

  const LowStockScreen({super.key, required this.ownerId});

  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  List<dynamic> lowStockList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLowStockMedicines();
  }

  Future<void> fetchLowStockMedicines() async {
    try {
      final response = await http.get(
        Uri.parse('https://digital-medical-uiaj.onrender.com/api/low-stock/${widget.ownerId}'),
      );
      
      if (response.statusCode == 200) {
        setState(() {
          lowStockList = json.decode(response.body)['data'];
          isLoading = false;
        });
      } else {
        
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load low stock medicines!'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print("Error fetching low stock: $e");
      
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Medicines'),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) 
          : lowStockList.isEmpty
              ? const Center(
                  child: Text('All stock levels are good! 👍',
                      style: TextStyle(fontSize: 18, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: lowStockList.length,
                  itemBuilder: (context, index) {
                    final medicine = lowStockList[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.warning_amber_rounded, color: Colors.white),
                        ),
                        title: Text(
                          medicine['medicine_name'],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text('Batch: ${medicine['batch_no'] ?? 'N/A'}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Qty: ${medicine['quantity']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red, 
                              ),
                            ),
                            Text('MRP: ₹${medicine['mrp']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}