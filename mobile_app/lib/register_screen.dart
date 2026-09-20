import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController shopNameController = TextEditingController();
  
  bool isLoading = false;

  Future<void> registerUser() async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('https://digital-medical-uiaj.onrender.com/api/register'), // localhost (Web के लिए)
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'owner_name': nameController.text,
          'mobile': mobileController.text,
          'password': passwordController.text,
          'shop_name': shopNameController.text,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
        Navigator.pop(context); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['error']), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Shop'), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Owner Name', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: mobileController, decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: shopNameController, decoration: const InputDecoration(labelText: 'Medical Shop Name', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()), obscureText: true),
              const SizedBox(height: 24),
              isLoading 
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: registerUser,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, minimumSize: const Size(double.infinity, 50)),
                    child: const Text('Create Account', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}