// lib/pages/caregiver_page.dart
// PATIENT → REQUEST CAREGIVER MATCHING PAGE
// UPDATED: Also calls Flask /api/match_caregivers and displays matches.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:muuguzi_app/services/patient_session.dart';

class CaregiverPage extends StatefulWidget {
  const CaregiverPage({super.key});

  @override
  State<CaregiverPage> createState() => _CaregiverPageState();
}

class _CaregiverPageState extends State<CaregiverPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _medicalController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _preferredGender = "female";
  String _preferredAvailability = "daytime"; // ONE CHOICE ONLY

  bool _loading = false;
  String? _selectingCaregiverId;
  List<dynamic> _matches = []; // <-- matches from Flask backend

  @override
  void initState() {
    super.initState();
    _loadExistingIfAny();
  }

  Future<void> _loadExistingIfAny() async {
    final patientId = PatientSession.instance.patientId;
    if (patientId == null) return;

    setState(() => _loading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        _medicalController.text =
            (data['medicalConditions'] ?? '') as String;
        _locationController.text =
            (data['location'] ?? '') as String;

        _preferredGender =
            (data['preferredGender'] ?? 'female') as String;

        _preferredAvailability =
            (data['preferredAvailability'] ?? 'daytime') as String;
      }
    } catch (_) {
      // Ignore error
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final patientId = PatientSession.instance.patientId;

    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again')),
      );
      return;
    }

    final firestorePayload = {
      'medicalConditions': _medicalController.text.trim(),
      'preferredGender': _preferredGender,
      'location': _locationController.text.trim(),
      'preferredAvailability': _preferredAvailability,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Payload expected by Flask /api/match_caregivers
    final apiPayload = {
      "medical_needs": _medicalController.text.trim(),
      "location": _locationController.text.trim(),
      "gender_preference": _preferredGender,
      "preferred_availability": _preferredAvailability,
    };

    setState(() {
      _loading = true;
      _matches = [];
    });

    try {
      final minWait = const Duration(seconds: 10);
      final start = DateTime.now();

      // 1️⃣ Save/update patient preferences in Firestore
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .set(firestorePayload, SetOptions(merge: true));

      // 2️⃣ Fetch caregiver matches from Firestore caregivers collection
      final matches = await _matchCaregiversFromFirestore(apiPayload);

      final elapsed = DateTime.now().difference(start);
      if (elapsed < minWait) {
        await Future.delayed(minWait - elapsed);
      }

      // 3️⃣ Optionally save match summary to Firestore (for admin / history)
      if (matches.isNotEmpty) {
        await FirebaseFirestore.instance.collection('matches').add({
          'pid': patientId,
          'matches': matches,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        setState(() {
          _matches = matches;
          _loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              matches.isEmpty
                  ? 'Request saved, but no strong caregiver matches found yet.'
                  : 'Request saved. Caregiver matches updated.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save or match: $e')),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _matchCaregiversFromFirestore(
      Map<String, String> prefs) async {
    final snap =
        await FirebaseFirestore.instance.collection('caregivers').get();

    final String prefGender = prefs['gender_preference'] ?? '';
    final String prefAvailability = prefs['preferred_availability'] ?? '';
    final String prefLocation = prefs['location'] ?? '';
    final String medicalNeeds = prefs['medical_needs'] ?? '';

    final List<Map<String, dynamic>> results = [];

    for (final doc in snap.docs) {
      final data = doc.data();
      final availability =
          (data['Availability'] as List?)?.map((e) => e.toString()).toList() ??
              <String>[];
      final genderList =
          (data['Gender'] as List?)?.map((e) => e.toString()).toList() ??
              <String>[];
      final gender = genderList.isNotEmpty ? genderList.first : '';
      final location = (data['Location'] ?? '').toString();
      final qualificationsField = data['Qualifications'];
      final qualifications = qualificationsField is List
          ? qualificationsField.map((e) => e.toString()).toList()
          : (qualificationsField != null
              ? qualificationsField.toString().split(',')
              : <String>[]);

      double score = 0;
      if (prefAvailability.isNotEmpty &&
          availability
              .map((e) => e.toLowerCase())
              .contains(prefAvailability.toLowerCase())) {
        score += 2;
      }
      if (prefGender.isNotEmpty &&
          prefGender.toLowerCase() != 'other' &&
          gender.toLowerCase() == prefGender.toLowerCase()) {
        score += 2;
      }
      if (prefLocation.isNotEmpty &&
          location.toLowerCase().contains(prefLocation.toLowerCase())) {
        score += 1.5;
      }
      if (medicalNeeds.isNotEmpty) {
        final needs = medicalNeeds.toLowerCase();
        if (qualifications.any((q) => q.toLowerCase().contains(needs))) {
          score += 1;
        }
      }

      results.add({
        'id': doc.id,
        'name': data['Name'] ?? 'Unnamed',
        'email': data['email'],
        'phone': data['phone'],
        'location': location,
        'gender': gender,
        'availability': availability,
        'qualifications': qualifications,
        'photo_url': data['photoUrl'],
        'match_score': score,
      });
    }

    results.sort((a, b) {
      final aScore = (a['match_score'] as num?)?.toDouble() ?? 0;
      final bScore = (b['match_score'] as num?)?.toDouble() ?? 0;
      return bScore.compareTo(aScore);
    });

    return results;
  }

  Future<void> _selectCaregiver(Map<String, dynamic> cg) async {
    final patientId = PatientSession.instance.patientId;
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again')),
      );
      return;
    }

    final caregiverId =
        (cg['id'] ?? cg['caregiver_id'] ?? '').toString();

    setState(() {
      _selectingCaregiverId =
          caregiverId.isNotEmpty ? caregiverId : cg.hashCode.toString();
    });

    try {
      // Save to session for immediate access elsewhere.
      PatientSession.instance.saveMatchedCaregiver(
        {
          'Name': cg['name'],
          'email': cg['email'],
          'phone': cg['phone'],
          'Location': cg['location'],
          'Qualifications':
              (cg['qualifications'] as List?)?.join(', ') ??
                  cg['qualifications'],
          'Availability': cg['availability'] ?? [],
          'Gender': [cg['gender'] ?? ''],
          'photoUrl': cg['photo_url'] ?? cg['photoUrl'],
        },
        caregiverId,
      );
      PatientSession.instance.saveMatchStatus(DateTime.now(), "active");

      await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .set({
        'matchedCaregiverId': caregiverId,
        'matchedCaregiverSnapshot': cg,
        'matchedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Caregiver ${cg['name'] ?? ''} selected successfully.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save selection: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _selectingCaregiverId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF3A7BD5);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Find a Caregiver"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          "Tell us your preferences to match you with the best caregiver.",
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Medical Conditions
                        TextFormField(
                          controller: _medicalController,
                          decoration: const InputDecoration(
                            labelText: "Medical Conditions",
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? "Enter your condition(s)"
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Preferred Gender
                        DropdownButtonFormField<String>(
                          value: _preferredGender,
                          items: const [
                            DropdownMenuItem(
                                value: "female", child: Text("Female")),
                            DropdownMenuItem(
                                value: "male", child: Text("Male")),
                            DropdownMenuItem(
                                value: "other", child: Text("Other")),
                          ],
                          decoration: const InputDecoration(
                            labelText: "Preferred Caregiver Gender",
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _preferredGender = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Location
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: "Your Location",
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? "Enter your location"
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Preferred Availability
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Preferred Availability",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 8),

                        RadioListTile<String>(
                          value: "daytime",
                          groupValue: _preferredAvailability,
                          onChanged: (v) => setState(() {
                            _preferredAvailability = v!;
                          }),
                          title: const Text("Daytime"),
                        ),
                        RadioListTile<String>(
                          value: "night",
                          groupValue: _preferredAvailability,
                          onChanged: (v) => setState(() {
                            _preferredAvailability = v!;
                          }),
                          title: const Text("Night"),
                        ),

                        const SizedBox(height: 24),

                        // Save + Match Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _loading ? null : _saveRequest,
                            icon: _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.search),
                            label: Text(
                              _loading
                                  ? "Saving & Matching..."
                                  : "Save & Find Caregivers",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Display matches from backend
                  if (_matches.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Top caregiver matches",
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._matches.map((cg) {
                      final map = Map<String, dynamic>.from(cg);
                      final name = map['name']?.toString() ?? 'Unnamed';
                      final location = map['location']?.toString() ?? '';
                      final gender = map['gender']?.toString() ?? '';
                      final availability =
                          (map['availability'] as List<dynamic>?)
                                  ?.join(', ') ??
                              '';

                      final qualifications =
                          (map['qualifications'] as List<dynamic>?)
                                  ?.join(', ') ??
                              '';

                      final caregiverId =
                          (map['id'] ?? map['caregiver_id'] ?? '').toString();
                      final isSelecting =
                          _selectingCaregiverId ==
                              (caregiverId.isNotEmpty
                                  ? caregiverId
                                  : map.hashCode.toString());

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.person),
                                title: Text(name),
                                subtitle: Text([
                                  if (location.isNotEmpty)
                                    'Location: $location',
                                  if (gender.isNotEmpty) 'Gender: $gender',
                                  if (availability.isNotEmpty)
                                    'Availability: $availability',
                                  if (qualifications.isNotEmpty)
                                    'Qualifications: $qualifications',
                                ].join('\n')),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: isSelecting
                                      ? null
                                      : () => _selectCaregiver(map),
                                  icon: isSelecting
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child:
                                              CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.check_circle),
                                  label: Text(
                                    isSelecting
                                        ? 'Selecting...'
                                        : 'Select caregiver',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ] else ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "No matches yet. Fill the form and tap 'Save & Find Caregivers'.",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
