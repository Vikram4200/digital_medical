import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TodaysBillsScreen extends StatefulWidget {
  final int ownerId;

  const TodaysBillsScreen({super.key, required this.ownerId});

  @override
  State<TodaysBillsScreen> createState() => _TodaysBillsScreenState();
}

class _TodaysBillsScreenState extends State<TodaysBillsScreen> {
  List<dynamic> billsList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTodaysBills();
  }

  Future<void> fetchTodaysBills() async {
    try {
      final response = await http.get(
        Uri.parse('https://digital-medical-uiaj.onrender.com/api/todays-bills/${widget.ownerId}'),
      );
      
      if (response.statusCode == 200) {
        setState(() {
          billsList = json.decode(response.body)['data'];
          isLoading = false;
        });
      } else {
        
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load bills!'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print("Error fetching bills: $e");
      
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Bills & Details'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) 
          : billsList.isEmpty
              ? const Center(
                  child: Text('No bills generated today yet!',
                      style: TextStyle(fontSize: 18, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: billsList.length,
                  itemBuilder: (context, index) {
                    final bill = billsList[index];
                    
                    
                    String timeStr = '';
                    if (bill['sale_date'] != null) {
                      DateTime dt = DateTime.parse(bill['sale_date']).toLocal();
                      timeStr = "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
                    }

                    List items = bill['items'] ?? [];

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Invoice: ${bill['invoice_no']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  '₹${bill['total_amount']}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            Text(
                              'Customer: ${bill['customer_name'] != null && bill['customer_name'].toString().isNotEmpty ? bill['customer_name'] : 'Walk-in Customer'}',
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                            ),
                            Text(
                              'Mobile: ${bill['customer_mobile'] != null && bill['customer_mobile'].toString().isNotEmpty ? bill['customer_mobile'] : 'N/A'}',
                              style: const TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Medicines Purchased:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal),
                            ),
                            const SizedBox(height: 4),
                            
                            items.isEmpty
                                ? const Text('Items details not recorded', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey))
                                : Column(
                                    children: items.map<Widget>((item) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('• ${item['medicine_name']}', style: const TextStyle(fontSize: 14)),
                                            Text('Qty: ${item['quantity']}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text('Time: $timeStr', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}