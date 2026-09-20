


import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:barcode_scan2/barcode_scan2.dart';

class AddMedicineScreen extends StatefulWidget {
  final int ownerId;
  const AddMedicineScreen({super.key, required this.ownerId});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController batchController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController mrpController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  
  final TextEditingController tabsPerPackController = TextEditingController(text: '1'); 

  TextEditingController? nameController; 
  int? selectedInventoryId; 

  // 🔥 पुरानी दवा का डेटा याद रखने के लिए नए वेरिएबल्स
  String? originalBatch;
  String? originalMrp;
  String? originalExpiry;

  bool isLoading = false;
  List<Map<String, dynamic>> existingInventory = [];

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
          setState(() {
            existingInventory = List<Map<String, dynamic>>.from(parsedData['data']);
          });
        }
      }
    } catch (e) {
      print("Error fetching inventory: $e");
    }
  }

  void _fillExistingData(Map<String, dynamic> med) {
    selectedInventoryId = med['inventory_id']; // 🔥 ID यहाँ सेव होगी
    nameController?.text = med['medicine_name']?.toString() ?? '';
    batchController.text = med['batch_no']?.toString() ?? '';
    mrpController.text = med['mrp']?.toString() ?? '';
    expiryController.text = med['expiry_date']?.toString() ?? '';
    barcodeController.text = med['barcode']?.toString() ?? '';
    tabsPerPackController.text = med['tablets_per_strip']?.toString() ?? '1';

    // 🔥 Auto-fill होते ही ओरिजिनल डेटा का बैकअप ले लिया
    originalBatch = batchController.text.trim();
    originalMrp = mrpController.text.trim();
    originalExpiry = expiryController.text.trim();
  }

  // scanner karake update karata hai
  Future<void> scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.type == ResultType.Barcode && result.rawContent.isNotEmpty) {
        barcodeController.text = result.rawContent;
        final existingMed = existingInventory.where((med) => med['barcode']?.toString() == result.rawContent).toList();
        if (existingMed.isNotEmpty) {
           _fillExistingData(existingMed.first);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to get barcode.'), backgroundColor: Colors.red));
    }
  }

  Future<void> saveMedicine() async {
    if (nameController?.text.trim().isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine Name is required!'), backgroundColor: Colors.red));
      return;
    }
    if (qtyController.text.isEmpty || mrpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Quantity and MRP are required!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => isLoading = true);

    try {
      int finalTps = int.tryParse(tabsPerPackController.text.trim()) ?? 1;
      if (finalTps <= 0) finalTps = 1;

      // 🔥 अगर यूज़र ने बैच, MRP या एक्सपायरी बदली है, तो ID हटा दें (ताकि नया सेव हो)
      if (originalBatch != null) {
        if (batchController.text.trim() != originalBatch || 
            mrpController.text.trim() != originalMrp || 
            expiryController.text.trim() != originalExpiry) {
          selectedInventoryId = null; // यह अब डेटाबेस में नई रो (row) बनाएगा
        }
      }

      final Map<String, dynamic> requestBody = {
        'owner_id': widget.ownerId,
        'inventory_id': selectedInventoryId, // send a id to backend
        'barcode': barcodeController.text.trim(),
        'medicine_name': nameController!.text.trim(),
        'batch_no': batchController.text.trim(),
        'quantity': double.tryParse(qtyController.text.trim()) ?? 0.0,
        'mrp': double.tryParse(mrpController.text.trim()) ?? 0.0,
        'expiry_date': expiryController.text.trim(),
        'tablets_per_strip': finalTps, 
      };

      print("📤 Sending to Backend: ${json.encode(requestBody)}");

      final response = await http.post(
        Uri.parse('https://digital-medical-uiaj.onrender.com/api/add-medicine'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Saved!'), backgroundColor: Colors.green));
        if (mounted) Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error'] ?? 'Error'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }

    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add / Update Stock'), backgroundColor: Colors.teal),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: barcodeController,
                  decoration: InputDecoration(
                    labelText: 'Barcode (Optional)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(icon: const Icon(Icons.qr_code_scanner, color: Colors.teal, size: 30), onPressed: scanBarcode),
                  ),
                ),
                const SizedBox(height: 16),
                
                Autocomplete<Map<String, dynamic>>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<Map<String, dynamic>>.empty();
                    }
                    return existingInventory.where((med) => 
                      med['medicine_name'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase())
                    );
                  },
                  displayStringForOption: (option) => option['medicine_name'].toString(),
                  onSelected: (selection) => _fillExistingData(selection),
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    nameController = controller; 
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Medicine Name * (Type to search)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search, color: Colors.teal),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: batchController,
                  decoration: const InputDecoration(labelText: 'Batch Number', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Add Quantity (Packs/Strips) *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: mrpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'MRP per Pack (₹) *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: tabsPerPackController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Tablets per Pack ', 
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.orange[50],
                    prefixIcon: const Icon(Icons.medication, color: Colors.orange),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: expiryController,
                  decoration: const InputDecoration(labelText: 'Expiry Date (MM/YYYY)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14)
                  ),
                  onPressed: saveMedicine,
                  child: const Text('Save to Inventory', style: TextStyle(fontSize: 18, color: Colors.white)),
                )
              ]
            )
          )
    );
  }
}