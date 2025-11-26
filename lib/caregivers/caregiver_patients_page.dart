// lib/pages/caregiver_patients_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/caregiver_session.dart';

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
            'Patient Screen',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Update your work info or view the patient you have been matched with.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),

          // Edit Work Info
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
            label: const Text('Edit Work Info'),
          ),
          const SizedBox(height: 12),

          // View My Patient
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
            label: const Text('View My Patient'),
          ),
        ],
      ),
    );
  }
}

//////////////////////////////////////////////
//    CAREGIVER EDIT WORK INFO PAGE
//////////////////////////////////////////////

class CaregiverEditWorkInfoPage extends StatefulWidget {
  const CaregiverEditWorkInfoPage({super.key});

  @override
  State<CaregiverEditWorkInfoPage> createState() =>
      _CaregiverEditWorkInfoPageState();
}

class _CaregiverEditWorkInfoPageState extends State<CaregiverEditWorkInfoPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _qualificationController =
      TextEditingController();

  String _gender = 'female';
  final List<String> _availability = <String>[];

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
      final snapshot = await FirebaseFirestore.instance
          .collection('caregivers')
          .doc(caregiverId)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;

        _locationController.text = data['Location'] ?? '';
        _qualificationController.text = data['Qualifications'] ?? '';

        // Gender (array)
        if (data['Gender'] is List && data['Gender'].isNotEmpty) {
          _gender = data['Gender'][0];
        }

        // Availability
        if (data['Availability'] != null) {
          _availability
            ..clear()
            ..addAll(List<String>.from(data['Availability']));
        }

        // Save to Session
        final session = CaregiverSession.instance;
        session.location = _locationController.text;
        session.qualifications = _qualificationController.text;
        session.gender = _gender;
        session.availability = List<String>.from(_availability);
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final caregiverId = CaregiverSession.instance.caregiverId;
    if (caregiverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expired. Please log in again.")),
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
        'Gender': [_gender],
        'Availability': _availability,
      });

      // UPDATE SESSION LOCALLY
      final session = CaregiverSession.instance;
      session.location = _locationController.text.trim();
      session.qualifications = _qualificationController.text.trim();
      session.gender = _gender;
      session.availability = List<String>.from(_availability);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Work info updated.")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed: $e")));
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
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Work Info")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: "Location"),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _qualificationController,
                      decoration:
                          const InputDecoration(labelText: "Qualification"),
                      validator: (v) =>
                          v == null || v.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(labelText: "Gender"),
                      items: const [
                        DropdownMenuItem(value: "female", child: Text("Female")),
                        DropdownMenuItem(value: "male", child: Text("Male")),
                        DropdownMenuItem(value: "other", child: Text("Other")),
                      ],
                      onChanged: (v) => setState(() {
                        _gender = v!;
                      }),
                    ),
                    const SizedBox(height: 16),

                    Text("Availability",
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text("Daytime"),
                          selected: _availability.contains("daytime"),
                          onSelected: (s) =>
                              _toggleAvailability("daytime", s),
                        ),
                        FilterChip(
                          label: const Text("Night"),
                          selected: _availability.contains("night"),
                          onSelected: (s) =>
                              _toggleAvailability("night", s),
                        ),
                        FilterChip(
                          label: const Text("Weekends"),
                          selected: _availability.contains("weekends"),
                          onSelected: (s) =>
                              _toggleAvailability("weekends", s),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _save,
                        icon: const Icon(Icons.save),
                        label: Text(_loading ? "Saving..." : "Save"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

//////////////////////////////////////////////
//       VIEW MATCHED PATIENT PAGE
//////////////////////////////////////////////

class MyMatchedPatientPage extends StatelessWidget {
  const MyMatchedPatientPage({super.key});

  @override
  Widget build(BuildContext context) {
    final caregiverId = CaregiverSession.instance.caregiverId;

    if (caregiverId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Patient')),
        body: const Center(child: Text("No patient found.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Patient")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("patients")
            .where("matchedCaregiverId", isEqualTo: caregiverId)
            .limit(1)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text("No patient yet."));
          }

          final doc = snap.data!.docs.first;
          final data = doc.data() as Map<String, dynamic>;

          // SAVE PATIENT SESSION
          CaregiverSession.instance.matchedPatientId = doc.id;
          CaregiverSession.instance.patientName = data['name'];
          CaregiverSession.instance.patientEmail = data['email'];
          CaregiverSession.instance.patientPhone = data['phone'];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? "Unnamed Patient",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text("Phone: ${data['phone'] ?? 'N/A'}"),
                        Text("Email: ${data['email'] ?? 'N/A'}"),
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
                "No predictions yet for this patient.",
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
                      "Latest Prediction",
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
                  Text("Survival Level: $survivalLevel"),
                if (score != null) Text("Score: ${score.toStringAsFixed(1)}"),
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
                    "Recommendations",
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  ...recommendations.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text("• ${e.key}: ${e.value}"),
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
