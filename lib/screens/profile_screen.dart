import 'package:calendar_application/screens/register_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:calendar_application/services/auth_service.dart';
import 'package:calendar_application/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditing = false;
  String? _email;  

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _email = user.email;
        _nameController.text = data['name'] ?? '';
      });
    }
    else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User incorrect")),
      );
      return;
    }
  }

  Future<void> _saveName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'name': _nameController.text.trim(),
    });

    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Name updated successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Profile")),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(0.0, 250.0, 0.0, 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Center(child: Text("Not logged in")),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: const Text("Sign In"),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text("Don't have an account? Register"),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actionsPadding: EdgeInsets.all(10),
        actions: [
            FloatingActionButton(
              onPressed: () async {
                await AuthService().signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
              child: const Icon(Icons.logout_rounded),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Email:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_email ?? "Loading...", style: const TextStyle(fontSize: 16)),

            const SizedBox(height: 24),
            const Text("Name:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            TextField(
              controller: _nameController,
              enabled: _isEditing,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Your name",
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_isEditing)
                  ElevatedButton(
                    onPressed: _saveName,
                    child: const Text("Save"),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = true;
                      });
                    },
                    child: const Text("Edit Name"),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
