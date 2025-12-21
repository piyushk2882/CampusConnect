// ignore_for_file: use_raw_strings, avoid_redundant_argument_values, lines_longer_than_80_chars, avoid_catches_without_on_clauses, depend_on_referenced_packages, document_ignores

import 'dart:async';
import 'dart:io';

import 'package:app_ui/app_ui.dart';
import 'package:database_client/database_client.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HiringFormPage extends StatefulWidget {
  const HiringFormPage({
    required this.clubId,
    super.key,
  });

  final String clubId;

  @override
  State<HiringFormPage> createState() => _HiringFormPageState();
}

class _HiringFormPageState extends State<HiringFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _classController = TextEditingController();
  final _departmentController = TextEditingController();
  final _prnController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedRole;
  String? _resumeUrl;
  bool _isSubmitting = false;
  bool _isLoading = true;
  Map<String, dynamic>? _hiringData;
  List<String> _availableClasses = [];
  List<String> _availableRoles = [];

  @override
  void initState() {
    super.initState();
    _loadHiringData();
  }

  Future<void> _loadHiringData() async {
    final databaseClient = Provider.of<PowerSyncDatabaseClient>(
      context,
      listen: false,
    );
    try {
      final hiringStream = databaseClient.watchClubHiring(widget.clubId);
      final result = await hiringStream.first;
      setState(() {
        _hiringData = result;
        _availableClasses = _hiringData != null
            ? _parsePgArray(_hiringData!['classes'])
            : [];
        _availableRoles = _hiringData != null
            ? _parsePgArray(_hiringData!['roles'])
            : [];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading hiring data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<String> _parsePgArray(dynamic value) {
    print(
      'HiringFormPage: _parsePgArray called with value: $value, type: ${value.runtimeType}',
    );
    if (value is List<dynamic>) {
      print('HiringFormPage: value is List<dynamic>, casting to String');
      return value.cast<String>();
    } else if (value is String) {
      print('HiringFormPage: value is String, checking format');
      // Check if it's already a JSON array string like ["item1","item2"]
      if (value.startsWith('[') && value.endsWith(']')) {
        print('HiringFormPage: value is JSON array string, parsing as JSON');
        // Remove brackets and quotes, split by comma
        final content = value.substring(1, value.length - 1);
        if (content.isEmpty) return [];
        return content
            .split('","')
            .map((e) => e.replaceAll('"', '').trim())
            .toList();
      } else if (value.startsWith('{') && value.endsWith('}')) {
        print('HiringFormPage: value is PostgreSQL array string, parsing');
        final content = value.substring(1, value.length - 1);
        if (content.isEmpty) return [];
        return content.split(',').map((e) => e.trim()).map((e) {
          if (e.startsWith('"') && e.endsWith('"')) {
            return e
                .substring(1, e.length - 1)
                .replaceAll('\\"', '"')
                .replaceAll('\\\\', '\\');
          }
          return e.replaceAll('\\"', '"').replaceAll('\\\\', '\\');
        }).toList();
      }
      return [];
    }
    print(
      'HiringFormPage: value is neither List nor String, returning empty list',
    );
    return [];
  }

  Future<void> _pickResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
          final filePath = 'resumes/$fileName';

          // Upload to Supabase storage
          final supabase = Supabase.instance.client;
          await supabase.storage
              .from('resume')
              .upload(
                filePath,
                File(file.path!),
              );

          // Get public URL
          final publicUrl = supabase.storage
              .from('resume')
              .getPublicUrl(filePath);

          setState(() {
            _resumeUrl = publicUrl;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Resume uploaded successfully!')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading resume: $e')),
        );
      }
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null || _resumeUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role and upload your resume'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final databaseClient = Provider.of<PowerSyncDatabaseClient>(
        context,
        listen: false,
      );

      await databaseClient.submitClubApplication(
        clubId: widget.clubId,
        userId: databaseClient.currentUserId!,
        studentName: _nameController.text.trim(),
        class_: _classController.text.trim(),
        department: _departmentController.text.trim(),
        prn: _prnController.text.trim(),
        phone: _phoneController.text.trim(),
        roleApplied: _selectedRole!,
        resumeUrl: _resumeUrl!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting application: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppScaffold(
        appBar: AppBar(
          title: const Text('Apply for Position'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Apply for Position'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Personal Information Section
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Personal Information',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.person_outline),
                        filled: true,
                        fillColor: const Color(0xFF181A26),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.phone),
                        filled: true,
                        fillColor: const Color(0xFF181A26),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              // Academic Information Section
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.school,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Academic Information',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _classController.text.isNotEmpty
                          ? _classController.text
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Class',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.class_),
                        filled: true,
                        fillColor: const Color(0xFF181A26),
                      ),
                      items: _availableClasses.map<DropdownMenuItem<String>>((class_) {
                        return DropdownMenuItem<String>(
                          value: class_,
                          child: Text(class_),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _classController.text = value ?? '';
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your class';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _departmentController,
                      decoration: InputDecoration(
                        labelText: 'Department',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.business),
                        filled: true,
                        fillColor: const Color(0xFF181A26),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your department';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _prnController,
                      decoration: InputDecoration(
                        labelText: 'PRN',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.badge),
                        filled: true,
                        fillColor: const Color(0xFF181A26),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your PRN';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              // Application Details Section
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.work,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Application Details',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Role to Apply For',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.work_outline),
                        filled: true,
                        fillColor: const Color(0xFF181A26),
                      ),
                      items: _availableRoles.map<DropdownMenuItem<String>>((role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(role),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a role';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181A26),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF181A26)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Resume',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _resumeUrl != null
                                      ? 'Resume uploaded successfully'
                                      : 'No resume selected',
                                  style: TextStyle(
                                    color: _resumeUrl != null ? Colors.green : Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _pickResume,
                            icon: const Icon(Icons.upload_file, size: 18),
                            label: const Text('Upload'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF6EED2),
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Submit Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF6EED2),
                      const Color(0xFFF6EED2).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF6EED2).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitApplication,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send, color: Colors.black),
                            const SizedBox(width: 8),
                            Text(
                              'Submit Application',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    _departmentController.dispose();
    _prnController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
