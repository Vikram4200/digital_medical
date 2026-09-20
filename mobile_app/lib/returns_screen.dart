import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReturnsScreen extends StatefulWidget {
  final int ownerId;
  const ReturnsScreen({super.key, required this.ownerId});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  List<dynamic> recentBills = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRecentBills();
  }

  Future<void> fetchRecentBills() async {
    try {
      final response = await http.get(Uri.parse('https://digital-medical-uiaj.onrender.com/api/recent-bills/${widget.ownerId}'));
      if (response.statusCode == 200) {
        final parsed = json.decode(response.body);
        if (mounted) {
          setState(() {
            recentBills = parsed['data'] ?? [];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  
  Future<void> processReturn(int invoiceId, int itemId, String medName, double maxQty, double mrp, int tps) async {
    int maxPacks = maxQty.toInt();
    int maxTabs = ((maxQty - maxPacks) * tps).round();

    int returnPacks = maxPacks;
    int returnTabs = maxTabs;
    
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Return $medName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Available to return: $maxPacks Packs, $maxTabs Tabs', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Packs', border: OutlineInputBorder()),
                      controller: TextEditingController(text: returnPacks.toString())..selection = TextSelection.collapsed(offset: returnPacks.toString().length),
                      onChanged: (val) => returnPacks = int.tryParse(val) ?? 0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tabs', border: OutlineInputBorder()),
                      controller: TextEditingController(text: returnTabs.toString())..selection = TextSelection.collapsed(offset: returnTabs.toString().length),
                      onChanged: (val) => returnTabs = int.tryParse(val) ?? 0,
                    ),
                  ),
                ],
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                
                double finalReturnQty = returnPacks + (returnTabs / tps);
                
                if (finalReturnQty > 0 && finalReturnQty <= maxQty + 0.001) { 
                  Navigator.pop(ctx);
                  setState(() => isLoading = true);
                  try {
                    final response = await http.post(
                      Uri.parse('https://digital-medical-uiaj.onrender.com/api/return-medicine'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode({
                        'owner_id': widget.ownerId,
                        'invoice_id': invoiceId,
                        'item_id': itemId,
                        'medicine_name': medName,
                        'return_quantity': double.parse(finalReturnQty.toStringAsFixed(3)), 
                        'mrp': mrp
                      }),
                    );
                    final data = json.decode(response.body);
                    if (response.statusCode == 200) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
                      fetchRecentBills(); 
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Return Failed'), backgroundColor: Colors.red));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                  setState(() => isLoading = false);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid quantity! Cannot exceed max available.')));
                }
              },
              child: const Text('Confirm Return', style: TextStyle(color: Colors.white)),
            )
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers & Returns (15 Days)'), backgroundColor: Colors.red),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : recentBills.isEmpty
              ? const Center(child: Text("No bills found in last 15 days.", style: TextStyle(fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: recentBills.length,
                  itemBuilder: (context, index) {
                    final bill = recentBills[index];
                    String dateStr = bill['sale_date'] != null ? bill['sale_date'].substring(0, 10) : '';
                    List items = bill['items'] ?? [];

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.receipt, color: Colors.white)),
                        title: Text('${bill['customer_name'] ?? 'Walk-in'} (₹${bill['total_amount']})', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Inv: ${bill['invoice_no']} | Date: $dateStr\nMob: ${bill['customer_mobile'] ?? 'N/A'}'),
                        children: items.map<Widget>((item) {
                          
                          
                          double qty = double.tryParse(item['quantity'].toString()) ?? 0.0;
                          double mrp = double.tryParse(item['mrp'].toString()) ?? 0.0;
                          int tps = item['tps'] != null ? int.tryParse(item['tps'].toString()) ?? 1 : 1;

                          int packs = qty.toInt();
                          int tabs = ((qty - packs) * tps).round();

                          String displayQty = '';
                          if (packs > 0 && tabs > 0) {
                            displayQty = '$packs Packs, $tabs Tabs';
                          } else if (packs > 0) {
                            displayQty = '$packs Packs';
                          } else if (tabs > 0) {
                            displayQty = '$tabs Tabs';
                          } else {
                            displayQty = '0 Packs';
                          }

                          return ListTile(
                            title: Text(item['medicine_name'] ?? ''),
                            subtitle: Text('Qty: $displayQty | MRP: ₹$mrp'), 
                            trailing: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[50], foregroundColor: Colors.red),
                              icon: const Icon(Icons.keyboard_return, size: 18),
                              label: const Text('Return'),
                              onPressed: () {
                                processReturn(bill['invoice_id'], item['item_id'], item['medicine_name'], qty, mrp, tps);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
    );
  }
}