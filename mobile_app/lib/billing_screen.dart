
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:barcode_scan2/barcode_scan2.dart'; // scanner 
// import 'package:printing/printing.dart';
// import 'pdf_generator.dart'; 

// class BillingScreen extends StatefulWidget {
//   final int ownerId;

//   const BillingScreen({super.key, required this.ownerId});

//   @override
//   State<BillingScreen> createState() => _BillingScreenState();
// }

// class _BillingScreenState extends State<BillingScreen> {
//   List<Map<String, dynamic>> allInventory = [];      
//   List<Map<String, dynamic>> filteredInventory = []; 
//   List<Map<String, dynamic>> cart = [];
  
//   bool isLoading = true;
//   String shopName = 'MEDICAL STORE'; 
  
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController mobileController = TextEditingController();
//   final TextEditingController searchController = TextEditingController(); 

  
//   double _toDouble(dynamic val) {
//     if (val == null) return 0.0;
//     return double.tryParse(val.toString()) ?? 0.0;
//   }

//   int _toInt(dynamic val) {
//     if (val == null) return 0;
    
//     return _toDouble(val).toInt(); 
//   }

//   @override
//   void initState() {
//     super.initState();
//     fetchShopDetails();
//     fetchInventoryForSale();
//   }

//   Future<void> fetchShopDetails() async {
//     try {
//       final response = await http.get(Uri.parse('https://digital-medical-uiaj.onrender.com/api/owner-profile/${widget.ownerId}'));
//       if (response.statusCode == 200) {
//         final parsed = json.decode(response.body);
//         if (parsed != null && parsed['data'] != null && mounted) {
//           setState(() {
//             shopName = parsed['data']['shop_name']?.toString() ?? 'MEDICAL STORE';
//           });
//         }
//       }
//     } catch (e) {
//       print('Error: $e');
//     }
//   }

//   Future<void> fetchInventoryForSale() async {
//     try {
//       final response = await http.get(Uri.parse('https://digital-medical-uiaj.onrender.com/api/inventory/${widget.ownerId}'));
//       if (response.statusCode == 200) {
//         final parsedData = json.decode(response.body);
        
//         if (parsedData != null && parsedData['success'] == true && parsedData['data'] != null) {
//           final List<dynamic> rawList = parsedData['data'];
//           final List<Map<String, dynamic>> safeList = rawList.map((item) => Map<String, dynamic>.from(item as Map)).toList();

//           if (mounted) {
//             setState(() {
//               allInventory = safeList.where((item) {
//                 double qty = _toDouble(item['quantity']);
//                 return qty > 0;
//               }).toList();
              
//               filteredInventory = List<Map<String, dynamic>>.from(allInventory); 
//               isLoading = false;
//             });
//           }
//           return;
//         }
//       }
//     } catch (e) {
//       print("Fetch Error: $e");
//     }
    
//     if (mounted) setState(() => isLoading = false);
//   }

//   void filterSearch(String query) {
//     setState(() {
//       if (query.trim().isEmpty) {
//         filteredInventory = List<Map<String, dynamic>>.from(allInventory);
//       } else {
//         filteredInventory = allInventory.where((item) {
//           final nameMatch = (item['medicine_name'] ?? '').toString().toLowerCase().contains(query.toLowerCase());
//           final barcodeMatch = (item['barcode'] ?? '').toString() == query;
//           return nameMatch || barcodeMatch;
//         }).toList();
//       }
//     });
//   }

  
//   Future<void> scanBarcodeForSale() async {
//     try {
//       var result = await BarcodeScanner.scan();
//       if (result.type == ResultType.Barcode && result.rawContent.isNotEmpty) {
//         String barcodeScanRes = result.rawContent;
//         searchController.text = barcodeScanRes; 
//         filterSearch(barcodeScanRes); 
//         processScannedBarcode(barcodeScanRes); 
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to open scanner'), backgroundColor: Colors.red));
//     }
//   }

//   void processScannedBarcode(String barcode) {
//     try {
//       final medicine = allInventory.firstWhere((item) => (item['barcode'] ?? '').toString() == barcode);
//       addToCart(medicine);
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${medicine['medicine_name']} added!'), backgroundColor: Colors.green));
//       searchController.clear();
//       filterSearch(''); 
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine not found!'), backgroundColor: Colors.red));
//     }
//   }

//   void addToCart(Map<String, dynamic> medicine) {
//     setState(() {
//       final index = cart.indexWhere((item) => item['inventory_id'] == medicine['inventory_id']);
//       int tps = _toInt(medicine['tablets_per_strip']);
//       if (tps <= 0) tps = 1; // डिफ़ॉल्ट 1 पत्ता
//       double stockQty = _toDouble(medicine['quantity']);

//       if (index != -1) {
//         int packs = _toInt(cart[index]['sell_packs']);
//         int tabs = _toInt(cart[index]['sell_tablets']);
        
//         if (packs + 1 + (tabs / tps) <= stockQty) {
//            cart[index]['sell_packs'] = packs + 1;
//         } else {
//            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough stock!')));
//         }
//       } else {
//         cart.add({
//           'inventory_id': medicine['inventory_id'],
//           'medicine_name': medicine['medicine_name']?.toString() ?? 'Unknown',
//           'mrp': _toDouble(medicine['mrp']),
//           'tablets_per_strip': tps,
//           'sell_packs': 1,
//           'sell_tablets': 0, 
//         });
//       }
//       searchController.clear(); 
//       filterSearch('');
//     });
//   }

//   double get totalAmount {
//     double total = 0;
//     for (var item in cart) {
//       double mrp = _toDouble(item['mrp']);
//       int tps = _toInt(item['tablets_per_strip']);
//       if (tps <= 0) tps = 1;
//       int packs = _toInt(item['sell_packs']);
//       int tabs = _toInt(item['sell_tablets']);
      
//       double pricePerTab = mrp / tps;
//       total += (packs * mrp) + (tabs * pricePerTab);
//     }
//     return total;
//   }

//   Future<void> generateBill() async {
//     if (cart.isEmpty) return;
//     setState(() => isLoading = true);
    
//     try {
//       List<Map<String, dynamic>> formattedCart = cart.map((item) {
//         int packs = _toInt(item['sell_packs']);
//         int tabs = _toInt(item['sell_tablets']);
//         int tps = _toInt(item['tablets_per_strip']);
//         if (tps <= 0) tps = 1;
        
//         double totalQty = packs + (tabs / tps);
        
//         return {
//           'inventory_id': item['inventory_id'],
//           'medicine_name': item['medicine_name'],
//           'mrp': _toDouble(item['mrp']),
//           'sell_quantity': double.parse(totalQty.toStringAsFixed(3)), 
//           'packs': packs, 
//           'tabs': tabs,   
//         };
//       }).toList();

//       final response = await http.post(
//         Uri.parse('https://digital-medical-uiaj.onrender.com/api/new-sale'),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           'owner_id': widget.ownerId,
//           'customer_name': nameController.text, 
//           'customer_mobile': mobileController.text,
//           'total_amount': totalAmount,
//           'cart_items': formattedCart, 
//         }),
//       );

//       final data = json.decode(response.body);
//       if (response.statusCode == 200) {
//         String invoiceNo = data['invoice_no']?.toString() ?? 'INV-${DateTime.now().millisecondsSinceEpoch}';
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']?.toString() ?? 'Success'), backgroundColor: Colors.green));
        
//         final pdfBytes = await PdfGenerator.generateInvoice(
//           invoiceNo: invoiceNo,
//           shopName: shopName,
//           customerName: nameController.text,
//           customerMobile: mobileController.text,
//           cartItems: formattedCart,
//           totalAmount: totalAmount,
//         );

//         await Printing.layoutPdf(
//           onLayout: (format) async => pdfBytes,
//           name: '$invoiceNo.pdf',
//         );

//         if (mounted) Navigator.pop(context, true); 
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error']?.toString() ?? 'Error'), backgroundColor: Colors.red));
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
//     }
//     setState(() => isLoading = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('New Sale'), backgroundColor: Colors.teal),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: TextField(
//                     controller: searchController,
//                     onChanged: filterSearch, 
//                     decoration: InputDecoration(
//                       labelText: 'Search Medicine Name or Scan Barcode', 
//                       prefixIcon: const Icon(Icons.search, color: Colors.teal), 
//                       border: const OutlineInputBorder(),
//                       suffixIcon: IconButton(
//                         icon: const Icon(Icons.qr_code_scanner, color: Colors.teal, size: 30),
//                         onPressed: scanBarcodeForSale, 
//                       ),
//                     ),
//                   ),
//                 ),

//                 Expanded(
//                   flex: 2,
//                   child: filteredInventory.isEmpty 
//                   ? const Center(child: Text("No medicines found or available in stock."))
//                   : ListView.builder(
//                     itemCount: filteredInventory.length, 
//                     itemBuilder: (context, index) {
//                       final med = filteredInventory[index];
//                       double displayStock = _toDouble(med['quantity']);
//                       double displayMrp = _toDouble(med['mrp']);

//                       return ListTile(
//                         title: Text(med['medicine_name']?.toString() ?? 'Unknown'),
//                         subtitle: Text('Stock: $displayStock | MRP: ₹$displayMrp'),
//                         trailing: IconButton(
//                           icon: const Icon(Icons.add_circle, color: Colors.teal, size: 30),
//                           onPressed: () => addToCart(med),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//                 const Divider(thickness: 2),
                
//                 // 🛒 CART SECTION
//                 Expanded(
//                   flex: 4, 
//                   child: Container(
//                     color: Colors.teal[50],
//                     child: Column(
//                       children: [
//                         const Padding(
//                           padding: EdgeInsets.all(4.0),
//                           child: Text('Current Bill (Cart)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                         ),
//                         Expanded(
//                           child: cart.isEmpty
//                           ? const Center(child: Text("Cart is empty"))
//                           : ListView.builder(
//                             itemCount: cart.length, 
//                             itemBuilder: (context, index) {
//                               final item = cart[index];
//                               int packs = _toInt(item['sell_packs']);
//                               int tabs = _toInt(item['sell_tablets']);
//                               int tps = _toInt(item['tablets_per_strip']);
//                               if (tps <= 0) tps = 1;
//                               double mrp = _toDouble(item['mrp']);
                              
//                               double pricePerTab = mrp / tps;
//                               double itemTotal = (packs * mrp) + (tabs * pricePerTab);

//                               return Card(
//                                 margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                 elevation: 2,
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(8.0),
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Row(
//                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           Text(item['medicine_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                                           IconButton(
//                                             icon: const Icon(Icons.delete, color: Colors.red),
//                                             onPressed: () => setState(() => cart.removeAt(index)),
//                                             padding: EdgeInsets.zero,
//                                             constraints: const BoxConstraints(),
//                                           )
//                                         ]
//                                       ),
//                                       Text('MRP: ₹$mrp / pack  (1 Pack = $tps tabs)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
//                                       const SizedBox(height: 10),
                                      
//                                       Row(
//                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           // PACKS CONTROL
//                                           Container(
//                                             decoration: BoxDecoration(color: Colors.teal[100], borderRadius: BorderRadius.circular(8)),
//                                             child: Row(
//                                               children: [
//                                                 IconButton(
//                                                   icon: const Icon(Icons.remove, color: Colors.red),
//                                                   onPressed: () {
//                                                     setState(() {
//                                                       if (packs > 0) item['sell_packs'] = packs - 1;
//                                                     });
//                                                   }
//                                                 ),
//                                                 Text('$packs Packs', style: const TextStyle(fontWeight: FontWeight.bold)),
//                                                 IconButton(
//                                                   icon: const Icon(Icons.add, color: Colors.green),
//                                                   onPressed: () {
//                                                     final invItem = allInventory.firstWhere((inv) => inv['inventory_id'] == item['inventory_id']);
//                                                     double stockQty = _toDouble(invItem['quantity']);
//                                                     if ((packs + 1) + (tabs / tps) <= stockQty) {
//                                                       setState(() => item['sell_packs'] = packs + 1);
//                                                     } else {
//                                                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough stock!')));
//                                                     }
//                                                   }
//                                                 ),
//                                               ]
//                                             )
//                                           ),
                                          
//                                           // TABLETS CONTROL
//                                           Container(
//                                             decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(8)),
//                                             child: Row(
//                                               children: [
//                                                 IconButton(
//                                                   icon: const Icon(Icons.remove, color: Colors.red),
//                                                   onPressed: () {
//                                                     setState(() {
//                                                       if (tabs > 0) {
//                                                         item['sell_tablets'] = tabs - 1;
//                                                       } else if (packs > 0) {
//                                                         item['sell_packs'] = packs - 1;
//                                                         item['sell_tablets'] = tps - 1;
//                                                       }
//                                                     });
//                                                   }
//                                                 ),
//                                                 Text('$tabs Tabs', style: const TextStyle(fontWeight: FontWeight.bold)),
//                                                 IconButton(
//                                                   icon: const Icon(Icons.add, color: Colors.green),
//                                                   onPressed: () {
//                                                     final invItem = allInventory.firstWhere((inv) => inv['inventory_id'] == item['inventory_id']);
//                                                     double stockQty = _toDouble(invItem['quantity']);
                                                    
//                                                     if (tabs + 1 >= tps) {
//                                                       if ((packs + 1) <= stockQty) {
//                                                         setState(() {
//                                                           item['sell_packs'] = packs + 1;
//                                                           item['sell_tablets'] = 0;
//                                                         });
//                                                       } else {
//                                                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough stock!')));
//                                                       }
//                                                     } else {
//                                                       if (packs + ((tabs + 1) / tps) <= stockQty) {
//                                                         setState(() => item['sell_tablets'] = tabs + 1);
//                                                       } else {
//                                                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough stock!')));
//                                                       }
//                                                     }
//                                                   }
//                                                 ),
//                                               ]
//                                             )
//                                           ),
//                                         ]
//                                       ),
//                                       const SizedBox(height: 8),
//                                       Align(
//                                         alignment: Alignment.centerRight,
//                                         child: Text('Item Total: ₹${itemTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
//                                       )
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         ),
                        
//                         Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Column(
//                             children: [
//                               TextField(
//                                 controller: nameController,
//                                 decoration: const InputDecoration(labelText: 'Customer Name (Optional)', isDense: true, border: OutlineInputBorder()),
//                               ),
//                               const SizedBox(height: 6),
//                               TextField(
//                                 controller: mobileController,
//                                 decoration: const InputDecoration(labelText: 'Customer Mobile (Optional)', isDense: true, border: OutlineInputBorder()),
//                                 keyboardType: TextInputType.phone,
//                               ),
//                               const SizedBox(height: 8),
//                               Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Text('Total: ₹${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                                   ElevatedButton(
//                                     style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
//                                     onPressed: cart.isEmpty ? null : generateBill, 
//                                     child: const Text('Generate Bill', style: TextStyle(color: Colors.white)),
//                                   )
//                                 ],
//                               )
//                             ],
//                           ),
//                         )
//                       ],
//                     ),
//                   ),
//                 )
//               ],
//             ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:barcode_scan2/barcode_scan2.dart'; // scanner 
import 'package:printing/printing.dart';
import 'pdf_generator.dart'; 

class BillingScreen extends StatefulWidget {
  final int ownerId;

  const BillingScreen({super.key, required this.ownerId});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  List<Map<String, dynamic>> allInventory = [];      
  List<Map<String, dynamic>> filteredInventory = []; 
  List<Map<String, dynamic>> cart = [];
  
  bool isLoading = true;
  String shopName = 'MEDICAL STORE'; 
  
  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController searchController = TextEditingController(); 
  final TextEditingController discountController = TextEditingController(); // 🔥 नया डिस्काउंट कंट्रोलर

  
  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    return double.tryParse(val.toString()) ?? 0.0;
  }

  int _toInt(dynamic val) {
    if (val == null) return 0;
    
    return _toDouble(val).toInt(); 
  }

  @override
  void initState() {
    super.initState();
    fetchShopDetails();
    fetchInventoryForSale();
  }

  Future<void> fetchShopDetails() async {
    try {
      final response = await http.get(Uri.parse('https://digital-medical-uiaj.onrender.com/api/owner-profile/${widget.ownerId}'));
      if (response.statusCode == 200) {
        final parsed = json.decode(response.body);
        if (parsed != null && parsed['data'] != null && mounted) {
          setState(() {
            shopName = parsed['data']['shop_name']?.toString() ?? 'MEDICAL STORE';
          });
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> fetchInventoryForSale() async {
    try {
      final response = await http.get(Uri.parse('https://digital-medical-uiaj.onrender.com/api/inventory/${widget.ownerId}'));
      if (response.statusCode == 200) {
        final parsedData = json.decode(response.body);
        
        if (parsedData != null && parsedData['success'] == true && parsedData['data'] != null) {
          final List<dynamic> rawList = parsedData['data'];
          final List<Map<String, dynamic>> safeList = rawList.map((item) => Map<String, dynamic>.from(item as Map)).toList();

          if (mounted) {
            setState(() {
              allInventory = safeList.where((item) {
                double qty = _toDouble(item['quantity']);
                return qty > 0;
              }).toList();
              
              filteredInventory = List<Map<String, dynamic>>.from(allInventory); 
              isLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      print("Fetch Error: $e");
    }
    
    if (mounted) setState(() => isLoading = false);
  }

  void filterSearch(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        filteredInventory = List<Map<String, dynamic>>.from(allInventory);
      } else {
        filteredInventory = allInventory.where((item) {
          final nameMatch = (item['medicine_name'] ?? '').toString().toLowerCase().contains(query.toLowerCase());
          final barcodeMatch = (item['barcode'] ?? '').toString() == query;
          return nameMatch || barcodeMatch;
        }).toList();
      }
    });
  }

  
  Future<void> scanBarcodeForSale() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode && result.rawContent.isNotEmpty) {
        String barcodeScanRes = result.rawContent;
        searchController.text = barcodeScanRes; 
        filterSearch(barcodeScanRes); 
        processScannedBarcode(barcodeScanRes); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to open scanner'), backgroundColor: Colors.red));
    }
  }

  void processScannedBarcode(String barcode) {
    try {
      final medicine = allInventory.firstWhere((item) => (item['barcode'] ?? '').toString() == barcode);
      addToCart(medicine);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${medicine['medicine_name']} added!'), backgroundColor: Colors.green));
      searchController.clear();
      filterSearch(''); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine not found!'), backgroundColor: Colors.red));
    }
  }

  void addToCart(Map<String, dynamic> medicine) {
    setState(() {
      final index = cart.indexWhere((item) => item['inventory_id'] == medicine['inventory_id']);
      int tps = _toInt(medicine['tablets_per_strip']);
      if (tps <= 0) tps = 1; // डिफ़ॉल्ट 1 पत्ता
      double stockQty = _toDouble(medicine['quantity']);

      if (index != -1) {
        int packs = _toInt(cart[index]['sell_packs']);
        int tabs = _toInt(cart[index]['sell_tablets']);
        
        if (packs + 1 + (tabs / tps) <= stockQty) {
           cart[index]['sell_packs'] = packs + 1;
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough stock!')));
        }
      } else {
        cart.add({
          'inventory_id': medicine['inventory_id'],
          'medicine_name': medicine['medicine_name']?.toString() ?? 'Unknown',
          'mrp': _toDouble(medicine['mrp']),
          'tablets_per_strip': tps,
          'expiry_date': medicine['expiry_date']?.toString() ?? '-', // 🔥 PDF के लिए Expiry Date सेव कर रहे हैं
          'sell_packs': 1,
          'sell_tablets': 0, 
        });
      }
      searchController.clear(); 
      filterSearch('');
    });
  }

  double get totalAmount {
    double total = 0;
    for (var item in cart) {
      double mrp = _toDouble(item['mrp']);
      int tps = _toInt(item['tablets_per_strip']);
      if (tps <= 0) tps = 1;
      int packs = _toInt(item['sell_packs']);
      int tabs = _toInt(item['sell_tablets']);
      
      double pricePerTab = mrp / tps;
      total += (packs * mrp) + (tabs * pricePerTab);
    }
    return total;
  }

  Future<void> generateBill() async {
    if (cart.isEmpty) return;
    setState(() => isLoading = true);
    
    try {
      double discountVal = double.tryParse(discountController.text) ?? 0.0;
      double grandTotal = totalAmount - discountVal;

      List<Map<String, dynamic>> formattedCart = cart.map((item) {
        int packs = _toInt(item['sell_packs']);
        int tabs = _toInt(item['sell_tablets']);
        int tps = _toInt(item['tablets_per_strip']);
        if (tps <= 0) tps = 1;
        
        double totalQty = packs + (tabs / tps);
        
        return {
          'inventory_id': item['inventory_id'],
          'medicine_name': item['medicine_name'],
          'mrp': _toDouble(item['mrp']),
          'expiry_date': item['expiry_date'], // 🔥 PDF को Expiry Date भेजने के लिए
          'sell_quantity': double.parse(totalQty.toStringAsFixed(3)), 
          'packs': packs, 
          'tabs': tabs,   
        };
      }).toList();

      final response = await http.post(
        Uri.parse('https://digital-medical-uiaj.onrender.com/api/new-sale'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'owner_id': widget.ownerId,
          'customer_name': nameController.text, 
          'customer_mobile': mobileController.text,
          'total_amount': grandTotal, // 🔥 डेटाबेस में Discount काटकर फाइनल अमाउंट जाएगा
          'cart_items': formattedCart, 
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        String invoiceNo = data['invoice_no']?.toString() ?? 'INV-${DateTime.now().millisecondsSinceEpoch}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']?.toString() ?? 'Success'), backgroundColor: Colors.green));
        
        final pdfBytes = await PdfGenerator.generateInvoice(
          invoiceNo: invoiceNo,
          shopName: shopName,
          customerName: nameController.text,
          customerMobile: mobileController.text,
          cartItems: formattedCart,
          totalAmount: totalAmount,
          discountAmount: discountVal, // 🔥 PDF जनरेटर को Discount भेज दिया
        );

        await Printing.layoutPdf(
          onLayout: (format) async => pdfBytes,
          name: '$invoiceNo.pdf',
        );

        if (mounted) Navigator.pop(context, true); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error']?.toString() ?? 'Error'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 लाइव कैलकुलेशन (UI में दिखाने के लिए)
    double currentDiscount = double.tryParse(discountController.text) ?? 0.0;
    double finalPayableAmount = totalAmount - currentDiscount;

    return Scaffold(
      appBar: AppBar(title: const Text('New Sale'), backgroundColor: Colors.teal),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    onChanged: filterSearch, 
                    decoration: InputDecoration(
                      labelText: 'Search Medicine Name or Scan Barcode', 
                      prefixIcon: const Icon(Icons.search, color: Colors.teal), 
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.teal, size: 30),
                        onPressed: scanBarcodeForSale, 
                      ),
                    ),
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: filteredInventory.isEmpty 
                  ? const Center(child: Text("No medicines found or available in stock."))
                  : ListView.builder(
                    itemCount: filteredInventory.length, 
                    itemBuilder: (context, index) {
                      final med = filteredInventory[index];
                      double displayStock = _toDouble(med['quantity']);
                      double displayMrp = _toDouble(med['mrp']);

                      return ListTile(
                        title: Text(med['medicine_name']?.toString() ?? 'Unknown'),
                        subtitle: Text('Stock: $displayStock | MRP: ₹$displayMrp'),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.teal, size: 30),
                          onPressed: () => addToCart(med),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(thickness: 2),
                
                // 🛒 CART SECTION
                Expanded(
                  flex: 4, 
                  child: Container(
                    color: Colors.teal[50],
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Text('Current Bill (Cart)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          child: cart.isEmpty
                          ? const Center(child: Text("Cart is empty"))
                          : ListView.builder(
                            itemCount: cart.length, 
                            itemBuilder: (context, index) {
                              final item = cart[index];
                              int packs = _toInt(item['sell_packs']);
                              int tabs = _toInt(item['sell_tablets']);
                              int tps = _toInt(item['tablets_per_strip']);
                              if (tps <= 0) tps = 1;
                              double mrp = _toDouble(item['mrp']);
                              
                              double pricePerTab = mrp / tps;
                              double itemTotal = (packs * mrp) + (tabs * pricePerTab);

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(item['medicine_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => setState(() => cart.removeAt(index)),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          )
                                        ]
                                      ),
                                      Text('MRP: ₹$mrp / pack  (1 Pack = $tps tabs)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      const SizedBox(height: 10),
                                      
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // PACKS CONTROL
                                          Container(
                                            decoration: BoxDecoration(color: Colors.teal[100], borderRadius: BorderRadius.circular(8)),
                                            child: Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove, color: Colors.red),
                                                  onPressed: () {
                                                    setState(() {
                                                      if (packs > 0) item['sell_packs'] = packs - 1;
                                                    });
                                                  }
                                                ),
                                                Text('$packs Packs', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                IconButton(
                                                  icon: const Icon(Icons.add, color: Colors.green),
                                                  onPressed: () {
                                                    final invItem = allInventory.firstWhere((inv) => inv['inventory_id'] == item['inventory_id']);
                                                    double stockQty = _toDouble(invItem['quantity']);
                                                    if ((packs + 1) + (tabs / tps) <= stockQty) {
                                                      setState(() => item['sell_packs'] = packs + 1);
                                                    } else {
                                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough stock!')));
                                                    }
                                                  }
                                                ),
                                              ]
                                            )
                                          ),
                                          
                                          // TABLETS CONTROL
                                          Container(
                                            decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(8)),
                                            child: Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove, color: Colors.red),
                                                  onPressed: () {
                                                    setState(() {
                                                      if (tabs > 0) {
                                                        item['sell_tablets'] = tabs - 1;
                                                      } else if (packs > 0) {
                                                        item['sell_packs'] = packs - 1;
                                                        item['sell_tablets'] = tps - 1;
                                                      }
                                                    });
                                                  }
                                                ),
                                                Text('$tabs Tabs', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                IconButton(
                                                  icon: const Icon(Icons.add, color: Colors.green),
                                                  onPressed: () {
                                                    final invItem = allInventory.firstWhere((inv) => inv['inventory_id'] == item['inventory_id']);
                                                    double stockQty = _toDouble(invItem['quantity']);
                                                    
                                                    if (tabs + 1 >= tps) {
                                                      if ((packs + 1) <= stockQty) {
                                                        setState(() {
                                                          item['sell_packs'] = packs + 1;
                                                          item['sell_tablets'] = 0;
                                                        });
                                                      } else {
                                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough stock!')));
                                                      }
                                                    } else {
                                                      if (packs + ((tabs + 1) / tps) <= stockQty) {
                                                        setState(() => item['sell_tablets'] = tabs + 1);
                                                      } else {
                                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough stock!')));
                                                      }
                                                    }
                                                  }
                                                ),
                                              ]
                                            )
                                          ),
                                        ]
                                      ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text('Item Total: ₹${itemTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              TextField(
                                controller: nameController,
                                decoration: const InputDecoration(labelText: 'Customer Name (Optional)', isDense: true, border: OutlineInputBorder()),
                              ),
                              const SizedBox(height: 6),
                              
                              // 🔥 Mobile Number और Discount Box को एक लाइन (Row) में डाल दिया
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: mobileController,
                                      decoration: const InputDecoration(labelText: 'Customer Mobile', isDense: true, border: OutlineInputBorder()),
                                      keyboardType: TextInputType.phone,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: TextField(
                                      controller: discountController,
                                      decoration: const InputDecoration(labelText: 'Discount (₹)', isDense: true, border: OutlineInputBorder()),
                                      keyboardType: TextInputType.number,
                                      onChanged: (val) => setState(() {}), // डिस्काउंट डालते ही टोटल अमाउंट अपडेट होगा
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // 🔥 यहाँ Discount घटने के बाद वाला Final Amount दिखेगा
                                  Text('Total: ₹${finalPayableAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                                    onPressed: cart.isEmpty ? null : generateBill, 
                                    child: const Text('Generate Bill', style: TextStyle(color: Colors.white)),
                                  )
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
    );
  }
}