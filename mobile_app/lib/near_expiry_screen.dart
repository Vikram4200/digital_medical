import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NearExpiryScreen extends StatefulWidget {
  final int ownerId;

  const NearExpiryScreen({super.key, required this.ownerId});

  @override
  State<NearExpiryScreen> createState() => _NearExpiryScreenState();
}

class _NearExpiryScreenState extends State<NearExpiryScreen> {
  List<dynamic> expiryList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchExpiryList();
  }

  Future<void> fetchExpiryList() async {
    try {
      final response = await http.get(
        Uri.parse('https://digital-medical-uiaj.onrender.com/api/near-expiry/${widget.ownerId}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          expiryList = json.decode(response.body)['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expiring Soon'),
        backgroundColor: Colors.redAccent, 
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : expiryList.isEmpty
              ? const Center(
                  child: Text('All good! No medicines expiring soon.',
                      style: TextStyle(fontSize: 18, color: Colors.green)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: expiryList.length,
                  itemBuilder: (context, index) {
                    final medicine = expiryList[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.redAccent, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.red,
                          child: Icon(Icons.warning, color: Colors.white),
                        ),
                        title: Text(medicine['medicine_name'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text('Batch: ${medicine['batch_no']} | Stock: ${medicine['quantity']}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Expiry', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(
                              '${medicine['expiry_date']}',
                              style: const TextStyle(
                                  color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
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