import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/caregiver_session.dart';
import '../caregivers/caregiver_profile_page.dart';
import '../caregivers/caregiver_reminders_page.dart';

/// First screen after choosing caregiver role:
/// lets user choose Private caregiver vs Nursing home.
class CaregiverRoleSelectionPage extends StatelessWidget {
  const CaregiverRoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF3A7BD5);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/',
            (route) => false,
          ),
        ),
        title: const Text('Caregiver type'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TypeCard(
              icon: Icons.person,
              title: 'Private caregiver',
              description: 'Sign up or log in as an individual caregiver.',
              color: primaryBlue,
              onTap: () {
                Navigator.pushReplacementNamed(context, '/caregiver-auth');
              },
            ),
            const SizedBox(height: 24),
            _TypeCard(
              icon: Icons.local_hospital,
              title: 'Nursing home',
              description:
                  'Log in as an admin and manage caregivers.',
              color: Colors.deepPurple,
              onTap: () {
                Navigator.pushReplacementNamed(context, '/nursing-login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _TypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Private caregiver auth choice page with Sign up / Log in buttons.
class CaregiverAuthChoicePage extends StatelessWidget {
  const CaregiverAuthChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF3A7BD5);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/',
            (route) => false,
          ),
        ),
        title: const Text('Private caregiver'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome caregiver',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Create an account or log in to manage your patients and reminders.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/caregiver-signup');
                },
                child: const Text('Sign up'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/caregiver-login');
                },
                child: const Text(
                  'Log in',
                  style: TextStyle(color: primaryBlue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Caregiver sign-up page: name, phone, email, password.
class CaregiverSignupPage extends StatefulWidget {
  const CaregiverSignupPage({super.key});

  @override
  State<CaregiverSignupPage> createState() => _CaregiverSignupPageState();
}

class _CaregiverSignupPageState extends State<CaregiverSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final docRef =
          FirebaseFirestore.instance.collection('caregivers').doc();
      await docRef.set({
        'caregiverid': docRef.id,
        'cid': docRef.id,
        'Name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text.trim(),
        'photoUrl': '',
        'Qualifications': '',
        'Location': '',
        'Availability': <String>[],
        'Gender': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Store session info for this caregiver
      CaregiverSession.instance.caregiverId = docRef.id;
      CaregiverSession.instance.email = _email.text.trim();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created. You can now log in.')),
        );
        Navigator.pushReplacementNamed(context, '/caregiver-home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/',
            (route) => false,
          ),
        ),
        title: const Text('Caregiver sign up'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter full name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter phone number' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) =>
                    v == null || v.length < 6 ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Caregiver login page (simple, demo-only; no real auth).
class CaregiverLoginPage extends StatefulWidget {
  const CaregiverLoginPage({super.key});

  @override
  State<CaregiverLoginPage> createState() => _CaregiverLoginPageState();
}

class _CaregiverLoginPageState extends State<CaregiverLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loggingIn = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loggingIn = true);

    try {
      // In a real app, use FirebaseAuth. For now, just check if caregiver exists.
      final snapshot = await FirebaseFirestore.instance
          .collection('caregivers')
          .where('email', isEqualTo: _email.text.trim())
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No caregiver found with this email')),
          );
        }
      } else {
        final doc = snapshot.docs.first;
        CaregiverSession.instance.caregiverId = doc.id;
        CaregiverSession.instance.email = doc['email'] as String?;
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
      if (mounted) setState(() => _loggingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            '/',
            (route) => false,
          ),
        ),
        title: const Text('Caregiver login'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter password' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loggingIn ? null : _login,
                  child: _loggingIn
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Log in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Root shell for logged-in private caregiver: Home, Patients, Reminders, Profile.
class CaregiverHomeRoot extends StatefulWidget {
  const CaregiverHomeRoot({super.key});

  @override
  State<CaregiverHomeRoot> createState() => _CaregiverHomeRootState();
}

class _CaregiverHomeRootState extends State<CaregiverHomeRoot> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _CaregiverHomeDashboard(),
      const CaregiverPatientsPage(),
      const CaregiverRemindersPage(),
      const CaregiverProfilePage(),
    ];

    const Color primaryBlue = Color(0xFF3A7BD5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Muuguzi - Caregiver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'View reminder history',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CaregiverRemindersPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.grey,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Patients'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: 'Reminders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _CaregiverHomeDashboard extends StatelessWidget {
  const _CaregiverHomeDashboard();

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF3A7BD5);
    const Color lightBlue = Color(0xFFE6F2FF);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: lightBlue,
                    child: Icon(Icons.medical_information, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Welcome caregiver! View your patients and manage reminders.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: ListTile(
              leading: Icon(Icons.people, color: primaryBlue),
              title: Text('Patients'),
              subtitle: Text('View your assigned patients'),
            ),
          ),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              leading: Icon(Icons.calendar_month, color: primaryBlue),
              title: Text('Reminders'),
              subtitle: Text('Check upcoming care tasks'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Patient screen entry for private caregiver.
class CaregiverPatientsPage extends StatelessWidget {
  const CaregiverPatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF3A7BD5);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Patient screen',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'As a private caregiver you can update your work information '
            'and view the patient you have been matched with (if any).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CaregiverEditWorkInfoPage(),
                ),
              );
            },
            icon: const Icon(Icons.work),
            label: const Text('Edit work info'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyMatchedPatientPage(),
                ),
              );
            },
            icon: const Icon(Icons.person_search),
            label: const Text('View my patient'),
          ),
        ],
      ),
    );
  }
}

class CaregiverEditWorkInfoPage extends StatefulWidget {
  const CaregiverEditWorkInfoPage({super.key});

  @override
  State<CaregiverEditWorkInfoPage> createState() =>
      _CaregiverEditWorkInfoPageState();
}

class _CaregiverEditWorkInfoPageState
    extends State<CaregiverEditWorkInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _qualificationController =
      TextEditingController();
  String _gender = 'female';
  final List<String> _availability = [];

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final caregiverId = CaregiverSession.instance.caregiverId;
    if (caregiverId == null) return;

    setState(() => _loading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('caregivers')
          .doc(caregiverId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _locationController.text = (data['Location'] ?? '') as String;
        _qualificationController.text =
            (data['Qualifications'] ?? '') as String;
        final genders = (data['Gender'] ?? []) as List<dynamic>;
        if (genders.isNotEmpty) {
          _gender = genders.first.toString();
        }
        final availList = (data['Availability'] ?? []) as List<dynamic>;
        _availability
          ..clear()
          ..addAll(availList.map((e) => e.toString()));
        if (mounted) setState(() {});
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final caregiverId = CaregiverSession.instance.caregiverId;
    if (caregiverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No caregiver session. Please log in again.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('caregivers')
          .doc(caregiverId)
          .update({
        'Location': _locationController.text.trim(),
        'Qualifications': _qualificationController.text.trim(),
        'Gender': <String>[_gender],
        'Availability': _availability,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Work info updated.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleAvailability(String value, bool selected) {
    setState(() {
      if (selected) {
        if (!_availability.contains(value)) _availability.add(value);
      } else {
        _availability.remove(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF3A7BD5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit work info'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _locationController,
                      decoration:
                          const InputDecoration(labelText: 'Location'),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Enter your work location'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _qualificationController,
                      decoration:
                          const InputDecoration(labelText: 'Qualification'),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Enter your qualification'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: const [
                        DropdownMenuItem(
                            value: 'female', child: Text('Female')),
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _gender = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Availability',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Daytime'),
                          selected: _availability.contains('daytime'),
                          onSelected: (selected) =>
                              _toggleAvailability('daytime', selected),
                        ),
                        FilterChip(
                          label: const Text('Night'),
                          selected: _availability.contains('night'),
                          onSelected: (selected) =>
                              _toggleAvailability('night', selected),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _save,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: Text(_loading ? 'Saving...' : 'Save'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Displays the patient matched to the currently logged-in caregiver.
/// Assumes that in the 'patients' collection there is a field
/// 'matchedCaregiverId' that stores the caregiver document ID.
class MyMatchedPatientPage extends StatelessWidget {
  const MyMatchedPatientPage({super.key});

  @override
  Widget build(BuildContext context) {
    final caregiverId = CaregiverSession.instance.caregiverId;

    if (caregiverId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My patient'),
        ),
        body: const Center(
          child: Text('No patients yet.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My patient'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('patients')
            .where('matchedCaregiverId', isEqualTo: caregiverId)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No patients yet.'),
            );
          }
          final doc = snapshot.data!.docs.first;
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '') as String;
          final phone = (data['phone'] ?? '') as String;
          final email = (data['email'] ?? '') as String;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name.isEmpty ? 'Unnamed patient' : name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        if (phone.isNotEmpty) Text('Phone: $phone'),
                        if (email.isNotEmpty) Text('Email: $email'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _PatientPredictionSection(patientId: doc.id),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PatientPredictionSection extends StatelessWidget {
  final String patientId;

  const _PatientPredictionSection({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('predictions')
          .where('patientId', isEqualTo: patientId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No predictions yet for this patient.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        final doc = snapshot.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        final input =
            Map<String, dynamic>.from(data['input'] ?? <String, dynamic>{});
        final survivalLevel =
            (data['survivalLevel'] ?? data['survival_level'] ?? '').toString();
        final score = data['score'] is num
            ? (data['score'] as num).toDouble()
            : null;
        final timestamp = data['createdAt'];
        String dateText = '';
        if (timestamp is Timestamp) {
          dateText = timestamp.toDate().toString().split('.').first;
        }

        final mmse = input['mmse_score'];
        final fast = input['fast_stage'];
        final age = input['age'];
        final dementia = input['dementia_type'];
        final recommendations =
            Map<String, dynamic>.from(data['recommendations'] ?? {});

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Latest Prediction',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (dateText.isNotEmpty)
                      Text(
                        dateText,
                        style: const TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (survivalLevel.isNotEmpty)
                  Text('Survival Level: $survivalLevel'),
                if (score != null) Text('Score: ${score.toStringAsFixed(1)}'),
                if (mmse != null || fast != null || age != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Input: Age ${age ?? '-'}, MMSE ${mmse ?? '-'}, FAST ${fast ?? '-'}"
                          " ${dementia != null ? '($dementia)' : ''}",
                    ),
                  ),
                if (recommendations.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Recommendations',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  ...recommendations.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• ${e.key}: ${e.value}'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Nursing home login; redirects to admin dashboard on success.
class NursingHomeLoginPage extends StatefulWidget {
  const NursingHomeLoginPage({super.key});

  @override
  State<NursingHomeLoginPage> createState() => _NursingHomeLoginPageState();
}

class _NursingHomeLoginPageState extends State<NursingHomeLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('admin')
          .where('email', isEqualTo: _email.text.trim())
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid admin credentials')),
          );
        }
      } else {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/_admin');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nursing home login'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter email' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter password' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Log in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
