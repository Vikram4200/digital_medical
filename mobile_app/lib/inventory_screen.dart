

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InventoryScreen extends StatefulWidget {
  final int ownerId;
  const InventoryScreen({super.key, required this.ownerId});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> inventory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchInventory();
  }

  Future<void> fetchInventory() async {
    try {
      final response = await http.get(Uri.parse('https://digital-medical-uiaj.onrender.com/api/inventory/${widget.ownerId}'));
      if (response.statusCode == 200) {
        final parsedData = json.decode(response.body);
        if (parsedData['success'] == true && parsedData['data'] != null) {
          final List<dynamic> rawList = parsedData['data'];
          if (mounted) {
            setState(() {
              inventory = rawList.map((item) => Map<String, dynamic>.from(item as Map)).toList();
              isLoading = false;
            });
          }
        } else {
          if (mounted) setState(() => isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    return double.tryParse(val.toString()) ?? 0.0;
  }

  int _toInt(dynamic val) {
    if (val == null) return 0;
    return _toDouble(val).toInt();
  }

  
  void _showEditDialog(Map<String, dynamic> item) {
    TextEditingController tpsController = TextEditingController(text: item['tablets_per_strip']?.toString() ?? '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Pack Size', style: const TextStyle(color: Colors.teal)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Medicine: ${item['medicine_name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: tpsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tablets per Pack (1 पत्ते में गोलियां)', 
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication, color: Colors.orange)
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => isLoading = true);
              try {
                final response = await http.put(
                  Uri.parse('https://digital-medical-uiaj.onrender.com/api/inventory/quick-edit/${item['inventory_id']}'),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({'tablets_per_strip': tpsController.text}),
                );
                if (response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pack Size Updated Successfully! ✅'), backgroundColor: Colors.green));
                  fetchInventory(); // लिस्ट को रीफ्रेश करें
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error updating pack size!'), backgroundColor: Colors.red));
                setState(() => isLoading = false);
              }
            },
            child: const Text('Update & Save', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Inventory'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () { setState(() => isLoading = true); fetchInventory(); })
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : inventory.isEmpty
              ? const Center(child: Text("No inventory found."))
              : ListView.builder(
                  itemCount: inventory.length,
                  itemBuilder: (context, index) {
                    final item = inventory[index];
                    
                    double qty = _toDouble(item['quantity']);
                    double mrp = _toDouble(item['mrp']);
                    int tps = _toInt(item['tablets_per_strip']);
                    if (tps <= 0) tps = 1;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: qty > 0 ? Colors.teal[100] : Colors.red[100],
                          child: Icon(Icons.medication, color: qty > 0 ? Colors.teal : Colors.red),
                        ),
                        title: Text(item['medicine_name']?.toString() ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Stock: ${qty.toStringAsFixed(2)} Packs | MRP: ₹${mrp.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black87)),
                              
                              Text('Pack Size: $tps Tabs | Batch: ${item['batch_no'] ?? 'N/A'}', style: const TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_square, color: Colors.teal, size: 28),
                          tooltip: 'Edit Pack Size',
                          onPressed: () => _showEditDialog(item),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}