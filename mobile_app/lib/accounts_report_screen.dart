// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class AccountsReportScreen extends StatefulWidget {
//   final int ownerId;

//   const AccountsReportScreen({super.key, required this.ownerId});

//   @override
//   State<AccountsReportScreen> createState() => _AccountsReportScreenState();
// }

// class _AccountsReportScreenState extends State<AccountsReportScreen> {
//   bool isLoading = true;
//   Map<String, dynamic> reportData = {
//     'today': 0.0,
//     'weekly': 0.0,
//     'monthly': 0.0,
//     'yearly': 0.0,
//     'lifetime': 0.0,
//   };

//   @override
//   void initState() {
//     super.initState();
//     fetchAccountsReport();
//   }

//   Future<void> fetchAccountsReport() async {
//     try {
//       final response = await http.get(
//         Uri.parse('http://localhost:5000/api/accounts-report/${widget.ownerId}'),
//       );
//       if (response.statusCode == 200) {
//         setState(() {
//           reportData = json.decode(response.body)['data'];
//           isLoading = false;
//         });
//       } else {
//         setState(() => isLoading = false);
//       }
//     } catch (e) {
//       print("Error fetching report: $e");
//       setState(() => isLoading = false);
//     }
//   }

//   Widget _buildReportCard(String title, double amount, IconData icon, Color color) {
//     return Card(
//       elevation: 4,
//       margin: const EdgeInsets.only(bottom: 16),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Row(
//           children: [
//             CircleAvatar(
//               radius: 30,
//               backgroundColor: color.withOpacity(0.1),
//               child: Icon(icon, color: color, size: 30),
//             ),
//             const SizedBox(width: 20),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 5),
//                   Text('₹${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
//                 ],
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Sales & Accounts Report'),
//         backgroundColor: Colors.purple,
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : ListView(
//               padding: const EdgeInsets.all(16),
//               children: [
//                 _buildReportCard('Today\'s Sales', reportData['today'], Icons.today, Colors.green),
//                 _buildReportCard('This Week', reportData['weekly'], Icons.view_week, Colors.blue),
//                 _buildReportCard('This Month', reportData['monthly'], Icons.calendar_month, Colors.orange),
//                 _buildReportCard('This Year', reportData['yearly'], Icons.star, Colors.purple),
//                 const Divider(thickness: 2, height: 40),
//                 _buildReportCard('Lifetime Revenue', reportData['lifetime'], Icons.account_balance_wallet, Colors.teal),
//               ],
//             ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AccountsReportScreen extends StatefulWidget {
  final int ownerId;

  const AccountsReportScreen({super.key, required this.ownerId});

  @override
  State<AccountsReportScreen> createState() => _AccountsReportScreenState();
}

class _AccountsReportScreenState extends State<AccountsReportScreen> {
  bool isLoading = true;
  Map<String, dynamic> reportData = {
    'today': 0.0,
    'weekly': 0.0,
    'monthly': 0.0,
    'yearly': 0.0,
    'lifetime': 0.0,
  };

  // 🔥 MAGIC CONVERTER: int और double दोनों को सुरक्षित रूप से हैंडल करेगा
  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    return double.tryParse(val.toString()) ?? 0.0;
  }

  @override
  void initState() {
    super.initState();
    fetchAccountsReport();
  }

  Future<void> fetchAccountsReport() async {
    try {
      final response = await http.get(
        Uri.parse('https://digital-medical-uiaj.onrender.com/api/accounts-report/${widget.ownerId}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          reportData = json.decode(response.body)['data'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching report: $e");
      setState(() => isLoading = false);
    }
  }

  
  Future<List<dynamic>> _fetchDetailedData(String type) async {
    try {
      final response = await http.get(Uri.parse('https://digital-medical-uiaj.onrender.com/api/detailed-report/${widget.ownerId}/$type'));
      if (response.statusCode == 200) {
        return json.decode(response.body)['data'] ?? [];
      }
    } catch (e) {
      print("Detail Fetch Error: $e");
    }
    return [];
  }

  // (Bottom Sheet)
  void _showDetailsBottomSheet(String title, String type, Color color) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.6, // half screen occupy
          child: Column(
            children: [
              Text('$title Breakdown', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              const Divider(thickness: 2),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: _fetchDetailedData(type),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No data found for this period.', style: TextStyle(fontSize: 16)));
                    }
                    
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final item = snapshot.data![index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: Icon(Icons.analytics, color: color),
                            title: Text(item['label'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            trailing: Text(
                              '₹${item['total']}', 
                              style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)
                            ),
                          ),
                        );
                      }
                    );
                  }
                )
              )
            ]
          )
        );
      }
    );
  }

  // card clickeble banata hai
  Widget _buildReportCard(String title, double amount, IconData icon, Color color, {String? detailType}) {
    return InkWell(
      onTap: () {
        if (detailType != null) {
          _showDetailsBottomSheet(title, detailType, color);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Detailed view only available for Month, Year, and Lifetime.')));
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
                        if (detailType != null) ...[
                          const SizedBox(width: 5),
                          const Icon(Icons.touch_app, size: 14, color: Colors.grey), 
                        ]
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text('₹${amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
              ),
              if (detailType != null) const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16)
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales & Accounts Report'),
        backgroundColor: Colors.purple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ✅ _toDouble() को यहाँ सफलतापूर्वक जोड़ दिया गया है
                _buildReportCard('Today\'s Sales', _toDouble(reportData['today']), Icons.today, Colors.green), 
                _buildReportCard('This Week', _toDouble(reportData['weekly']), Icons.view_week, Colors.blue), 
                
                _buildReportCard('This Month', _toDouble(reportData['monthly']), Icons.calendar_month, Colors.orange, detailType: 'month'),
                _buildReportCard('This Year', _toDouble(reportData['yearly']), Icons.star, Colors.purple, detailType: 'year'),
                const Divider(thickness: 2, height: 40),
                _buildReportCard('Lifetime Revenue', _toDouble(reportData['lifetime']), Icons.account_balance_wallet, Colors.teal, detailType: 'lifetime'),
              ],
            ),
    );
  }
}