
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'add_medicine_screen.dart';
import 'billing_screen.dart'; 
import 'near_expiry_screen.dart'; 
import 'expired_screen.dart'; 
import 'todays_bills_screen.dart'; 
import 'low_stock_screen.dart'; 
import 'accounts_report_screen.dart';
import 'returns_screen.dart'; 

class DashboardScreen extends StatefulWidget {
  final int ownerId;

  const DashboardScreen({super.key, required this.ownerId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Stats variables
  int totalMedicines = 0;
  int lowStock = 0;
  double todaySales = 0;
  int todayBills = 0;
  int nearExpiry = 0; 
  String shopName = 'Medical Store'; 
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboardStats();
  }

  // Backend se Live Data aur Shop Name mangawane ka function hai
  Future<void> fetchDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('https://digital-medical-uiaj.onrender.com/api/dashboard-stats/${widget.ownerId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        if (mounted) {
          setState(() {
            totalMedicines = data['total_medicines'];
            lowStock = data['low_stock'];
            todaySales = (data['today_sales'] as num).toDouble();
            todayBills = data['today_bills'];
            nearExpiry = data['near_expiry']; 
            
            if (data['shop_name'] != null && data['shop_name'].toString().isNotEmpty) {
              shopName = data['shop_name'];
            }
            
            isLoading = false;
          });
        }
      } else {
        if(mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching stats: $e");
      if(mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(shopName.toUpperCase()), 
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => isLoading = true);
              fetchDashboardStats();
            },
          )
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to Your Pharmacy',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                // Sales Stats Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildStatRow('Today\'s Sales', '₹$todaySales', Colors.green),
                        const Divider(),
                        _buildStatRow(
                          'Today\'s Bills', 
                          '$todayBills', 
                          Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TodaysBillsScreen(ownerId: widget.ownerId),
                              ),
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Inventory Stats Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildStatRow('Total Medicines', '$totalMedicines', Colors.black87),
                        const Divider(),
                        _buildStatRow(
                          'Low Stock', 
                          '$lowStock', 
                          lowStock > 0 ? Colors.orange : Colors.grey,
                          onTap: () {
                            if (lowStock > 0) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LowStockScreen(ownerId: widget.ownerId),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('All stock levels are good! 👍'), 
                                  backgroundColor: Colors.green
                                ),
                              );
                            }
                          }
                        ),
                        const Divider(),
                        // Near Expiry Alert Row
                        _buildStatRow(
                          'Near Expiry Alert', 
                          '$nearExpiry', 
                          nearExpiry > 0 ? Colors.red : Colors.grey,
                          onTap: () {
                            if (nearExpiry > 0) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NearExpiryScreen(ownerId: widget.ownerId),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No medicines expiring soon! 🥳'), backgroundColor: Colors.green),
                              );
                            }
                          }
                        ), 
                        const Divider(),
                        // Expired Medicines Row
                        _buildStatRow(
                          'Expired Medicines', 
                          'View', 
                          Colors.brown,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExpiredScreen(ownerId: widget.ownerId),
                              ),
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // ✅ Action Buttons 
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildActionButton(Icons.add_shopping_cart, 'New Sale', Colors.teal, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BillingScreen(ownerId: widget.ownerId),
                        ),
                      ).then((value) {
                        if (value == true) {
                          setState(() => isLoading = true);
                          fetchDashboardStats();
                        }
                      });
                    }),
                    
                    _buildActionButton(Icons.medication, 'Add Meds', Colors.blue, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddMedicineScreen(ownerId: widget.ownerId),
                        ),
                      ).then((_) {
                        setState(() => isLoading = true);
                        fetchDashboardStats();
                      });
                    }),

                    _buildActionButton(Icons.bar_chart, 'Accounts', Colors.purple, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AccountsReportScreen(ownerId: widget.ownerId),
                        ),
                      );
                    }),

                    _buildActionButton(Icons.keyboard_return, 'Returns', Colors.red, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReturnsScreen(ownerId: widget.ownerId),
                        ),
                      ).then((_) {
                        setState(() => isLoading = true);
                        fetchDashboardStats();
                      });
                    }),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 26, 
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)), 
          ],
        ),
      ),
    );
  }
}