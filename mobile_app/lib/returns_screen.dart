
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
  List<dynamic> displayBills = []; 
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRecentBills();
  }

  // 1. By default pichle 15 din ke bills load karega
  Future<void> fetchRecentBills() async {
    if (mounted) setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('https://digital-medical-uiaj.onrender.com/api/recent-bills/${widget.ownerId}'));
      if (response.statusCode == 200) {
        final parsed = json.decode(response.body);
        if (mounted) {
          setState(() {
            displayBills = parsed['data'] ?? [];
          });
        }
      }
    } catch (e) {
      print("Error fetching bills: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 2. Name ya Mobile number se search karega
  Future<void> searchCustomerBills() async {
    final query = searchController.text.trim();
    if (query.isEmpty) {
      fetchRecentBills(); 
      return;
    }
    
    if (mounted) setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://digital-medical-uiaj.onrender.com/api/search-bills/${widget.ownerId}?query=$query')
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && mounted) {
          setState(() => displayBills = data['data'] ?? []);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search Error: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 🔥 MAGIC MATH: Discount kaat kar sahi refund amount nikalna
  double calculateRefundAmount(dynamic bill, double returnQty, double itemMrp) {
    double originalSubtotal = 0;
    List items = bill['items'] ?? []; 
    
    for (var i in items) {
      double mrp = double.tryParse(i['mrp'].toString()) ?? 0;
      double qty = double.tryParse(i['quantity'].toString()) ?? 0;
      originalSubtotal += (mrp * qty);
    }

    double totalPaid = double.tryParse(bill['total_amount'].toString()) ?? 0;
    double returnItemValue = returnQty * itemMrp;

    if (originalSubtotal <= 0) return returnItemValue;
    double exactRefund = (returnItemValue / originalSubtotal) * totalPaid;
    
    return exactRefund;
  }

  Future<void> processReturn(dynamic bill, dynamic item) async {
    int invoiceId = bill['invoice_id'];
    int itemId = item['item_id'];
    String medName = item['medicine_name'];
    
    double maxQty = double.tryParse(item['quantity'].toString()) ?? 0.0;
    double mrp = double.tryParse(item['mrp'].toString()) ?? 0.0;
    int tps = item['tps'] != null ? int.tryParse(item['tps'].toString()) ?? 1 : 1;

    int maxPacks = maxQty.toInt();
    int maxTabs = ((maxQty - maxPacks) * tps).round();

    int returnPacks = maxPacks;
    int returnTabs = maxTabs;
    
    await showDialog(
      context: context,
      builder: (dialogCtx) { // 🔥 FIX: Context renaming
        return StatefulBuilder(
          builder: (stCtx, setStateDialog) { // 🔥 FIX: Context renaming
            
            double currentReturnQty = returnPacks + (returnTabs / tps);
            double exactRefund = calculateRefundAmount(bill, currentReturnQty, mrp);

            return AlertDialog(
              title: Text('Return $medName'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Available to return: $maxPacks Packs, $maxTabs Tabs', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Packs', border: OutlineInputBorder()),
                          controller: TextEditingController(text: returnPacks.toString())..selection = TextSelection.collapsed(offset: returnPacks.toString().length),
                          onChanged: (val) {
                            setStateDialog(() => returnPacks = int.tryParse(val) ?? 0);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Tabs', border: OutlineInputBorder()),
                          controller: TextEditingController(text: returnTabs.toString())..selection = TextSelection.collapsed(offset: returnTabs.toString().length),
                          onChanged: (val) {
                            setStateDialog(() => returnTabs = int.tryParse(val) ?? 0);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Refund Amount:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        Text('₹${exactRefund.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                      ],
                    ),
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    if (currentReturnQty > 0 && currentReturnQty <= maxQty + 0.001) { 
                      Navigator.pop(dialogCtx); // 🔥 FIX: Popup now uses correct context
                      if (mounted) setState(() => isLoading = true); 
                      
                      try {
                        final response = await http.post(
                          Uri.parse('https://digital-medical-uiaj.onrender.com/api/return-medicine'),
                          headers: {'Content-Type': 'application/json'},
                          body: json.encode({
                            'owner_id': widget.ownerId,
                            'invoice_id': invoiceId,
                            'item_id': itemId,
                            'medicine_name': medName,
                            'return_quantity': double.parse(currentReturnQty.toStringAsFixed(3)), 
                            'mrp': mrp,
                            'refund_amount': exactRefund 
                          }),
                        );
                        final data = json.decode(response.body);
                        if (response.statusCode == 200) {
                          // 🔥 Now this Snackbar will 100% show up!
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
                          await fetchRecentBills(); 
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Return Failed'), backgroundColor: Colors.red));
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      } finally {
                        if (mounted) setState(() => isLoading = false);
                      }
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customers & Returns'), backgroundColor: Colors.red),
      body: Column(
        children: [
          // 🔍 SEARCH BAR SECTION
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Name or Mobile...',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          fetchRecentBills();
                        },
                      )
                    ),
                    onSubmitted: (_) => searchCustomerBills(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16)
                  ),
                  onPressed: searchCustomerBills,
                  child: const Text('Search', style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
          
          // 📜 BILLS LIST SECTION
          Expanded(
            child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : displayBills.isEmpty
                  ? const Center(child: Text("No bills found.", style: TextStyle(fontSize: 16)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: displayBills.length,
                      itemBuilder: (context, index) {
                        final bill = displayBills[index];
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
                                    processReturn(bill, item); 
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}