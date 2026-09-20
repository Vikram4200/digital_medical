import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'register_screen.dart';
import 'main_screen.dart'; // ✅ यह नई लाइन ऐड की गई है

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  bool isLoading = false;

  Future<void> loginUser() async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        // Uri.parse('http://localhost:5000/api/login'), // localhost (Web के लिए)
        Uri.parse('https://digital-medical-uiaj.onrender.com/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'mobile': mobileController.text,
          'password': passwordController.text,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message']), backgroundColor: Colors.green));
        
        
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => MainScreen(ownerId: data['owner_id']))
        );
        
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
      appBar: AppBar(title: const Text('Medical Shop Login'), backgroundColor: Colors.teal),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_pharmacy, size: 80, color: Colors.teal),
            const SizedBox(height: 30),
            TextField(controller: mobileController, decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 24),
            isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: loginUser,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, minimumSize: const Size(double.infinity, 50)),
                  child: const Text('Login', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
              },
              child: const Text("Don't have an account? Register Here", style: TextStyle(color: Colors.teal)),
            )
          ],
        ),
      ),
    );
  }
}