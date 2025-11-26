
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/admin_session.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}


class _AdminPageState extends State<AdminPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();

  String _gender = 'female';
  final List<String> _availability = <String>[]; // e.g. ['daytime','night']
  bool _submitting = false;

  bool _adminLoading = true;
  String? _adminEmail;

  @override
  void initState() {
    super.initState();
    _loadAdminFromFirestore();
  }


  Future<void> _loadAdminFromFirestore() async {
    final adminId = AdminSession.instance.adminId;

    if (adminId == null) {
      _logout();
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('admin') 
          .doc(adminId)
          .get();

      if (!doc.exists) {
        _logout();
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      setState(() {
        _adminEmail = (data['email'] as String?) ?? '';
        _adminLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _adminLoading = false;
        });
      }
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

  Future<void> _saveNewCaregiver() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final caregiversRef =
          FirebaseFirestore.instance.collection('caregivers');
      final docRef = caregiversRef.doc();

      await docRef.set({
        'caregiverid': docRef.id,
        'cid': docRef.id,
        'Name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'Location': _locationController.text.trim(),
        'Qualifications': _qualificationController.text.trim(),
        'Gender': <String>[_gender],      
        'Availability': _availability,    
        'createdAt': FieldValue.serverTimestamp(),
       
      });

      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _locationController.clear();
      _qualificationController.clear();
      setState(() {
        _gender = 'female';
        _availability.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caregiver added.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add caregiver: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _logout() {
    AdminSession.instance.clear();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF3A7BD5);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _adminEmail != null && _adminEmail!.isNotEmpty
              ? 'Admin - Caregivers (${_adminEmail!})'
              : 'Admin - Caregivers',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: _logout,
          ),
        ],
      ),
      body: _adminLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 0,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add caregiver profile',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Enter name' : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Enter phone' : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Enter email' : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              labelText: 'Location',
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Enter location'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _qualificationController,
                            decoration: const InputDecoration(
                              labelText: 'Qualification',
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Enter qualification'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _gender,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'female', child: Text('Female')),
                              DropdownMenuItem(
                                  value: 'male', child: Text('Male')),
                              DropdownMenuItem(
                                  value: 'other', child: Text('Other')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _gender = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
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
                              FilterChip(
                                label: const Text('Weekends'),
                                selected: _availability.contains('weekends'),
                                onSelected: (selected) =>
                                    _toggleAvailability('weekends', selected),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _submitting ? null : _saveNewCaregiver,
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(
                                _submitting
                                    ? 'Saving caregiver...'
                                    : 'Save caregiver',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Divider(color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Text(
                            'Caregivers',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- Caregivers list ---
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('caregivers')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No caregivers yet.'),
                        );
                      }

                      final docs = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data =
                              doc.data() as Map<String, dynamic>;
                          final name =
                              (data['Name'] ?? '') as String;
                          final email =
                              (data['email'] ?? '') as String;
                          final phone =
                              (data['phone'] ?? '') as String;
                          final location =
                              (data['Location'] ?? '') as String;
                          final qualification =
                              (data['Qualifications'] ?? '') as String;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: ListTile(
                              title: Text(
                                name.isEmpty
                                    ? 'Unnamed caregiver'
                                    : name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  if (email.isNotEmpty) 'Email: $email',
                                  if (phone.isNotEmpty) 'Phone: $phone',
                                  if (location.isNotEmpty)
                                    'Location: $location',
                                  if (qualification.isNotEmpty)
                                    'Qualification: $qualification',
                                ].join('\n'),
                              ),
                              isThreeLine: true,
                              trailing: Wrap(
                                spacing: 8,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    tooltip: 'Edit',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditCaregiverPage(
                                            caregiverDoc: doc,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.people),
                                    tooltip: 'View patients matched',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              CaregiverPatientsMatchedPage(
                                            caregiverDoc: doc,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

/// Page to edit an existing caregiver's details.
class EditCaregiverPage extends StatefulWidget {
  final DocumentSnapshot caregiverDoc;

  const EditCaregiverPage({super.key, required this.caregiverDoc});

  @override
  State<EditCaregiverPage> createState() => _EditCaregiverPageState();
}

class _EditCaregiverPageState extends State<EditCaregiverPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _locationController;
  late TextEditingController _qualificationController;
  String _gender = 'female';
  final List<String> _availability = <String>[];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.caregiverDoc.data() as Map<String, dynamic>;
    _nameController =
        TextEditingController(text: (data['Name'] ?? '') as String);
    _phoneController =
        TextEditingController(text: (data['phone'] ?? '') as String);
    _emailController =
        TextEditingController(text: (data['email'] ?? '') as String);
    _locationController =
        TextEditingController(text: (data['Location'] ?? '') as String);
    _qualificationController =
        TextEditingController(text: (data['Qualifications'] ?? '') as String);

    final genders = (data['Gender'] ?? []) as List<dynamic>;
    if (genders.isNotEmpty) _gender = genders.first.toString();

    final avail = (data['Availability'] ?? []) as List<dynamic>;
    _availability
      ..clear()
      ..addAll(avail.map((e) => e.toString()));
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await widget.caregiverDoc.reference.update({
        'Name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'Location': _locationController.text.trim(),
        'Qualifications': _qualificationController.text.trim(),
        'Gender': <String>[_gender],
        'Availability': _availability,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caregiver updated.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update caregiver: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit caregiver'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter phone' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter email' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter location' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _qualificationController,
                decoration:
                    const InputDecoration(labelText: 'Qualification'),
                validator: (v) => v == null || v.isEmpty
                    ? 'Enter qualification'
                    : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'female', child: Text('Female')),
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
              const SizedBox(height: 12),
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
                  FilterChip(
                    label: const Text('Weekends'),
                    selected: _availability.contains('weekends'),
                    onSelected: (selected) =>
                        _toggleAvailability('weekends', selected),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label:
                      Text(_saving ? 'Saving caregiver...' : 'Save caregiver'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CaregiverPatientsMatchedPage extends StatelessWidget {
  final DocumentSnapshot caregiverDoc;

  const CaregiverPatientsMatchedPage({super.key, required this.caregiverDoc});

  @override
  Widget build(BuildContext context) {
    final caregiverId = caregiverDoc.id;
    final caregiverName =
        (caregiverDoc['Name'] as String?) ?? 'Selected caregiver';

    return Scaffold(
      appBar: AppBar(
        title: Text('Patients matched - $caregiverName'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('patients')
            .where('matchedCaregiverId', isEqualTo: caregiverId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No patients yet.'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final name = (data['name'] ?? '') as String;
              final phone = (data['phone'] ?? '') as String;
              final email = (data['email'] ?? '') as String;

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  title: Text(
                    name.isEmpty ? 'Unnamed patient' : name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    [
                      if (phone.isNotEmpty) 'Phone: $phone',
                      if (email.isNotEmpty) 'Email: $email',
                    ].join('\n'),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
