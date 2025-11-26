// lib/pages/patient_predictions_history_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:muuguzi_app/services/patient_session.dart';

class PatientPredictionsHistoryPage extends StatelessWidget {
  const PatientPredictionsHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final patientId = PatientSession.instance.patientId;

    if (patientId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Predictions")),
        body: const Center(
          child: Text("Please log in again."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Predictions History"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('predictions') // <-- updated collection name
            .where("patientId", isEqualTo: patientId)
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // No data
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No predictions yet."),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              // Input is stored as a nested map
              final input = Map<String, dynamic>.from(
                data["input"] ?? <String, dynamic>{},
              );

              final age = input["age"];
              final sex = input["sex"];
              final dementia = input["dementia_type"];
              final mmse = input["mmse_score"];
              final fast = input["fast_stage"];
              final comorbidities =
                  List<String>.from(input["comorbidities"] ?? []);
              final neuro =
                  List<String>.from(input["neurological_symptoms"] ?? []);
              final resp =
                  List<String>.from(input["respiratory_issues"] ?? []);

              // Result fields from Flask
              final double? score = (data["score"] is num)
                  ? (data["score"] as num).toDouble()
                  : null;
              final String survivalLevel =
                  (data["survivalLevel"] ?? data["survival_level"] ?? "")
                      .toString();

              final recommendations =
                  Map<String, dynamic>.from(data["recommendations"] ?? {});

              final timestamp = data["createdAt"];
              String dateText = "";
              if (timestamp is Timestamp) {
                dateText = timestamp.toDate().toString().split(".").first;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Prediction #${index + 1}",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            dateText,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Result summary
                      if (survivalLevel.isNotEmpty || score != null) ...[
                        _infoRow(
                          "Survival Level",
                          survivalLevel.isNotEmpty
                              ? survivalLevel
                              : "Not available",
                        ),
                        if (score != null)
                          _infoRow("Score", "${score.toStringAsFixed(1)}/100"),
                        const SizedBox(height: 8),
                      ],

                      // Input snapshot
                      _infoRow("Age", age?.toString() ?? "-"),
                      _infoRow("Sex", sex?.toString() ?? "-"),
                      _infoRow("Dementia Type", dementia?.toString() ?? "-"),
                      _infoRow("MMSE Score", mmse?.toString() ?? "-"),
                      _infoRow("FAST Stage", fast?.toString() ?? "-"),

                      const SizedBox(height: 8),

                      if (comorbidities.isNotEmpty)
                        _infoRow(
                            "Comorbidities", comorbidities.join(", ")),
                      if (neuro.isNotEmpty)
                        _infoRow("Neurological Symptoms",
                            neuro.join(", ")),
                      if (resp.isNotEmpty)
                        _infoRow("Respiratory Issues",
                            resp.join(", ")),

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
                            child: Text(
                              "• ${e.key}: ${e.value}",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Helper row for cleaner UI
  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: "$title: ",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(
                fontWeight: FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
