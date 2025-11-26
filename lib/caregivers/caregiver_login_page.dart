import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/caregiver_session.dart';

class CaregiverLoginPage extends StatefulWidget {
  const CaregiverLoginPage({super.key});

  @override
  State<CaregiverLoginPage> createState() => _CaregiverLoginPageState();
}

class _CaregiverLoginPageState extends State<CaregiverLoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _loading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('caregivers')
          .where('email', isEqualTo: _email.text.trim())
          .where('password', isEqualTo: _password.text.trim())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid credentials')),
          );
        }
      } else {
        final doc = snapshot.docs.first;
        final data = doc.data();

        // ======================
        // SAVE LOGIN SESSION HERE
        // ======================
        final session = CaregiverSession.instance;

        session.caregiverId = doc.id;
        session.email = data['email'];
        session.name = data['Name'];
        session.phone = data['phone'];
        session.photoUrl = data['photoUrl'];
        session.qualifications = data['Qualifications'];
        session.location = data['Location'];
        session.gender =
            (data['Gender'] is List && (data['Gender'] as List).isNotEmpty)
                ? data['Gender'][0]
                : null;

        session.availability = (data['Availability'] != null)
            ? List<String>.from(data['Availability'])
            : [];

        // Password NOT stored for security

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/caregiver-home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF3A7BD5);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("Caregiver Login"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 30),
              Text(
                "Welcome Back",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Log in to manage your patients and reminders",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // EMAIL
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter email" : null,
              ),
              const SizedBox(height: 16),

              // PASSWORD
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(labelText: "Password"),
                obscureText: true,
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter password" : null,
              ),
              const SizedBox(height: 24),

              // LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Log In"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
