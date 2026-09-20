import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int ownerId;

  const ProfileScreen({super.key, required this.ownerId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> ownerDetails = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOwnerProfile();
  }

  
  Future<void> fetchOwnerProfile() async {
    try {
      final response = await http.get(
        Uri.parse('https://digital-medical-uiaj.onrender.com/api/owner-profile/${widget.ownerId}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          ownerDetails = json.decode(response.body)['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() => isLoading = false);
    }
  }

  
  void showEditProfileDialog() {
    final TextEditingController nameController = TextEditingController(text: ownerDetails['owner_name']);
    final TextEditingController mobileController = TextEditingController(text: ownerDetails['mobile']);
    final TextEditingController shopNameController = TextEditingController(text: ownerDetails['shop_name']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: shopNameController,
                decoration: const InputDecoration(labelText: 'Shop Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Owner Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              Navigator.pop(context); 
              await updateProfile(
                shopNameController.text,
                nameController.text,
                mobileController.text,
              );
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  
  Future<void> updateProfile(String shopName, String ownerName, String mobile) async {
    setState(() => isLoading = true);
    try {
      final response = await http.put(
        Uri.parse('https://digital-medical-uiaj.onrender.com/api/update-profile/${widget.ownerId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'shop_name': shopName,
          'owner_name': ownerName,
          'mobile': mobile,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message']), backgroundColor: Colors.green),
        );
        fetchOwnerProfile(); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error']), backgroundColor: Colors.red),
        );
        setState(() => isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      setState(() => isLoading = false);
    }
  }

  
  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Profile'),
        backgroundColor: Colors.teal,
        actions: [
          
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: showEditProfileDialog,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.store, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    ownerDetails['shop_name'] ?? 'Medical Store',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Owner: ${ownerDetails['owner_name'] ?? ''}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  Card(
                    elevation: 3,
                    child: ListTile(
                      leading: const Icon(Icons.phone, color: Colors.teal),
                      title: const Text('Mobile Number'),
                      subtitle: Text('${ownerDetails['mobile'] ?? ''}'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal,
                        side: const BorderSide(color: Colors.teal),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile', style: TextStyle(fontSize: 16)),
                      onPressed: showEditProfileDialog,
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text('Logout', style: TextStyle(fontSize: 18, color: Colors.white)),
                      onPressed: logout,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}