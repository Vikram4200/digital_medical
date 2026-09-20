import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExpiredScreen extends StatefulWidget {
  final int ownerId;

  const ExpiredScreen({super.key, required this.ownerId});

  @override
  State<ExpiredScreen> createState() => _ExpiredScreenState();
}

class _ExpiredScreenState extends State<ExpiredScreen> {
  List<dynamic> expiredList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchExpiredList();
  }

  Future<void> fetchExpiredList() async {
    try {
      final response = await http.get(
        Uri.parse('https://digital-medical-uiaj.onrender.com/api/expired-medicines/${widget.ownerId}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          expiredList = json.decode(response.body)['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  
  Future<void> deleteMedicine(int inventoryId) async {
    
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: const Text('Are you sure you want to remove this expired medicine from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await http.delete(
          Uri.parse('https://digital-medical-uiaj.onrender.com/api/delete-medicine/$inventoryId'),
        );

        final data = json.decode(response.body);
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message']), backgroundColor: Colors.green),
          );
          fetchExpiredList(); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error']), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Already Expired Medicines'),
        backgroundColor: Colors.brown,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : expiredList.isEmpty
              ? const Center(
                  child: Text('Great! No expired medicines in stock.',
                      style: TextStyle(fontSize: 18, color: Colors.green)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: expiredList.length,
                  itemBuilder: (context, index) {
                    final medicine = expiredList[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.brown, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.brown,
                          child: Icon(Icons.block, color: Colors.white),
                        ),
                        title: Text(medicine['medicine_name'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text('Batch: ${medicine['batch_no']} | Stock: ${medicine['quantity']} | Exp: ${medicine['expiry_date']}'),
                        // ✅ यहाँ हमने Delete (Trash) आइकॉन जोड़ दिया है
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteMedicine(medicine['inventory_id']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}