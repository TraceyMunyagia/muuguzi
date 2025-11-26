// lib/pages/prediction_page.dart
// UPDATED: Sends mmse_score & fast_stage to Flask,
// saves both input + result to Firestore + PatientSession,
// and handles errors / missing patientId safely.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:muuguzi_app/services/api_service.dart';
import 'package:muuguzi_app/services/patient_session.dart';

class PredictionPage extends StatefulWidget {
  const PredictionPage({super.key});

  @override
  State<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _ageController = TextEditingController();
  String _selectedSex = 'male';
  String _selectedDementiaType = 'alzheimers';
  int _mmseScore = 24; // MMSE (0–30)
  int _fastStage = 1; // FAST (1–7)
  final List<String> _selectedComorbidities = [];
  final List<String> _selectedNeurologicalSymptoms = [];
  final List<String> _selectedRespiratoryIssues = [];

  bool _loading = false;
  Map<String, dynamic>? _result;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _result = null;
    });

    final patientId = PatientSession.instance.patientId;

    if (patientId == null) {
      // make sure we stop the loader if session is missing
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login again.")),
      );
      return;
    }

    // ---------------------------
    // 1️⃣ Build Prediction Payload
    // (matches Flask backend: mmse_score + fast_stage)
    // ---------------------------
    final payload = {
      "age": double.tryParse(_ageController.text) ?? 0,
      "sex": _selectedSex,
      "dementia_type": _selectedDementiaType,
      "mmse_score": _mmseScore,        // <-- used by Flask
      "fast_stage": _fastStage,        // <-- used by Flask
      "comorbidities": _selectedComorbidities,
      "neurological_symptoms": _selectedNeurologicalSymptoms,
      "respiratory_issues": _selectedRespiratoryIssues,
    };

    // ---------------------------
    // 2️⃣ Save to PatientSession (local cache)
    // ---------------------------
    PatientSession.instance.savePredictionInput(payload);

    try {
      const minWait = Duration(seconds: 10);
      final start = DateTime.now();
      // ---------------------------
      // 3️⃣ Call Flask Survival Prediction API
      // ---------------------------
      final api = ApiService();
      final res = await api.predictSurvival(payload);

      final elapsed = DateTime.now().difference(start);
      if (elapsed < minWait) {
        await Future.delayed(minWait - elapsed);
      }

      // ---------------------------
      // 4️⃣ Save input + result to Firestore
      //    (collection name aligned with schema: "predictions")
      // ---------------------------
      await FirebaseFirestore.instance.collection("predictions").add({
        "patientId": patientId,
        "input": payload,
        "score": res["score"],
        "survivalLevel": res["survival_level"],
        "recommendations": res["recommendations"],
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() {
        _loading = false;
        _result = res;
      });
    } catch (e) {
      debugPrint("Failed to predict survival: $e");
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prediction failed. Please try again. ($e)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF3A7BD5);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dementia Survival Prediction',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fill in the details below. This tool supports caregivers but does not replace professional medical advice.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Age
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Age'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter age';
                      final n = int.tryParse(v);
                      if (n == null || n <= 0) return 'Enter valid age';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Sex
                  DropdownButtonFormField<String>(
                    value: _selectedSex,
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (v) => setState(() => _selectedSex = v!),
                    decoration: const InputDecoration(labelText: 'Sex'),
                  ),
                  const SizedBox(height: 12),

                  // Dementia Type
                  DropdownButtonFormField<String>(
                    value: _selectedDementiaType,
                    items: const [
                      DropdownMenuItem(
                          value: 'alzheimers', child: Text("Alzheimer's")),
                      DropdownMenuItem(
                          value: 'vascular', child: Text('Vascular dementia')),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedDementiaType = v!),
                    decoration:
                        const InputDecoration(labelText: 'Dementia Type'),
                  ),
                  const SizedBox(height: 12),

                  // MMSE Slider
                  _buildMmseSlider(),
                  const SizedBox(height: 12),

                  // FAST Slider
                  _buildFastSlider(),
                  const SizedBox(height: 12),

                  // Comorbidities
                  _MultiSelectChips(
                    label: 'Comorbidities',
                    helperText:
                        'Hypertension, diabetes, depression, cardiovascular disease…',
                    options: const [
                      'hypertension',
                      'diabetes',
                      'cardiovascular disease',
                      'depression',
                      'cerebrovascular disease',
                    ],
                    selectedValues: _selectedComorbidities,
                    onChanged: (values) {
                      setState(() {
                        _selectedComorbidities
                          ..clear()
                          ..addAll(values);
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Neurological symptoms
                  _MultiSelectChips(
                    label: 'Neurological symptoms',
                    helperText: 'Memory loss, movement issues, confusion…',
                    options: const [
                      'memory loss',
                      'difficulty with language',
                      'confusion',
                      'movement problems',
                      'changes in visual and spatial abilities',
                    ],
                    selectedValues: _selectedNeurologicalSymptoms,
                    onChanged: (values) {
                      setState(() {
                        _selectedNeurologicalSymptoms
                          ..clear()
                          ..addAll(values);
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Respiratory Issues
                  _MultiSelectChips(
                    label: 'Respiratory issues',
                    helperText: 'COPD, pneumonia, dyspnea…',
                    options: const [
                      'pneumonia',
                      'chronic obstructive pulmonary disease (COPD)',
                      'shortness of breath (dyspnea)',
                      'respiratory muscle weakness',
                      'sleep-disordered breathing',
                    ],
                    selectedValues: _selectedRespiratoryIssues,
                    onChanged: (values) {
                      setState(() {
                        _selectedRespiratoryIssues
                          ..clear()
                          ..addAll(values);
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.analytics),
                      label: Text(
                          _loading ? 'Predicting...' : 'Predict Survival'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_result != null) _PredictionResultCard(result: _result!),
          ],
        ),
      ),
    );
  }

  Widget _buildMmseSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Severity-MMSE Score (0–30)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        Slider(
          value: _mmseScore.toDouble(),
          min: 0,
          max: 30,
          divisions: 30,
          label: _mmseScore.toString(),
          onChanged: (v) => setState(() => _mmseScore = v.round()),
        ),
      ],
    );
  }

  Widget _buildFastSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Functional Decline - FAST Stage (1–7)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        Slider(
          value: _fastStage.toDouble(),
          min: 1,
          max: 7,
          divisions: 6,
          label: 'Stage $_fastStage',
          onChanged: (v) => setState(() => _fastStage = v.round()),
        ),
      ],
    );
  }
}

class _MultiSelectChips extends StatelessWidget {
  final String label;
  final String? helperText;
  final List<String> options;
  final List<String> selectedValues;
  final ValueChanged<List<String>> onChanged;

  const _MultiSelectChips({
    required this.label,
    this.helperText,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(helperText!, style: const TextStyle(fontSize: 12)),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final isSelected = selectedValues.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                final updated = List<String>.from(selectedValues);
                if (selected) {
                  updated.add(option);
                } else {
                  updated.remove(option);
                }
                onChanged(updated);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PredictionResultCard extends StatelessWidget {
  final Map<String, dynamic> result;

  const _PredictionResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final String level = result['survival_level'] ?? '';
    final num score = result['score'] ?? 0;

    final Map<String, dynamic> recommendations =
        Map<String, dynamic>.from(result['recommendations'] ?? {});

    Color levelColor;
    if (level.contains('high')) {
      levelColor = Colors.green;
    } else if (level.contains('medium')) {
      levelColor = Colors.orange;
    } else {
      levelColor = Colors.red;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estimated Survival Chance',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  level.toUpperCase(),
                  style: TextStyle(
                    color: levelColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text("Score: ${score.toStringAsFixed(1)}/100"),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Recommendations',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...recommendations.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(entry.value.toString()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
