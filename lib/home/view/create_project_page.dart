// ignore_for_file: depend_on_referenced_packages, avoid_print, avoid_catches_without_on_clauses, flutter_style_todos, lines_longer_than_80_chars, inference_failure_on_instance_creation, document_ignores

import 'dart:io';

import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/app/view/app.dart';
import 'package:database_client/database_client.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({super.key});

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _domainController = TextEditingController();
  final TextEditingController _guideController = TextEditingController();
  final TextEditingController _githubLinkController = TextEditingController();

  String? _selectedBranch;
  String? _selectedYear;

  File? _researchPaperFile;

  final List<String> _branches = [
    'CSE',
    'AIML',
    'Data Science',
    'CSBS',
    'Electrical',
    'ENTC',
    'Mechanical',
    'Civil',
    'Civil and Environmental',
    'Biotechnology',
  ];
  final List<String> _years = List<String>.generate(
    (DateTime.now().year - 2020) + 1,
    (index) => (2020 + index).toString(),
  );

  bool _isUploading = false;

  Future<void> _pickResearchPaper() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _researchPaperFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _uploadProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final databaseClient = context.read<PowerSyncDatabaseClient>();
      final userId = databaseClient.currentUserId;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      String? pdfUrl;
      if (_researchPaperFile != null) {
        // Upload file to Supabase storage or similar
        // For now, mock the URL or implement actual upload logic
        pdfUrl = await _uploadFileToStorage(_researchPaperFile!);
        if (pdfUrl == null) {
          if (mounted) {
            openSnackBar(
              const SnackbarMessage.error(
                title: 'Failed to upload research paper',
              ),
            );
          }
          return;
        }
      }

      // Add log before creating project
      print('Uploading project with title: ${_titleController.text.trim()}');
      print('User ID: $userId');
      print('Summary: ${_summaryController.text.trim()}');
      print('Domain: ${_domainController.text.trim()}');
      print('Branch: $_selectedBranch');
      print('Year: $_selectedYear');
      print('Guide: ${_guideController.text.trim()}');
      print('GitHub Link: ${_githubLinkController.text.trim()}');
      print('PDF URL: $pdfUrl');


      await databaseClient.createProject(
        userId: userId,
        title: _titleController.text.trim(),
        summary: _summaryController.text.trim(),
        domain: _domainController.text.trim(),
        branch: _selectedBranch,
        year: _selectedYear,
        guide: _guideController.text.trim(),
        githubLink: _githubLinkController.text.trim(),
        researchpaperLink: pdfUrl,
      );

      if (mounted) {
      openSnackBar(
        const SnackbarMessage.success(
          title: 'Project Uploaded successfully',
        ),
      );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
      openSnackBar(
        const SnackbarMessage.success(
          title: 'Faild to Upload Project',
        ),
      );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<String?> _uploadFileToStorage(File file) async {
    try {
      print('Starting file upload...');
      final projectId = const Uuid().v4();
      final storage = Supabase.instance.client.storage.from('papers');
      final fileName = '${projectId}_research_paper.pdf';
      final bytes = await file.readAsBytes();
      print('File size: ${bytes.length} bytes');

      print('Uploading to bucket: papers, file: $fileName');
      await storage.uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          contentType: 'application/pdf',
          cacheControl: '9000000',
        ),
      );
      print('Upload completed successfully');

      final publicUrl = storage.getPublicUrl(fileName);
      print('Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Failed to upload research paper: $e');
      print('Error type: ${e.runtimeType}');
      return null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _domainController.dispose();
    _guideController.dispose();
    _githubLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Project'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: const Color(0xFF181A26),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _summaryController,
                decoration: InputDecoration(
                  labelText: 'Summary',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: const Color(0xFF181A26),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedBranch,
                decoration: InputDecoration(
                  labelText: 'Branch',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: const Color(0xFF181A26),
                  prefixIcon: const Icon(Icons.school),
                ),
                items: _branches
                    .map(
                      (branch) =>
                          DropdownMenuItem(value: branch, child: Text(branch)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBranch = value;
                  });
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Branch is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _domainController,
                decoration: InputDecoration(
                  labelText: 'Domain',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: const Color(0xFF181A26),
                  prefixIcon: const Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedYear,
                decoration: InputDecoration(
                  labelText: 'Year',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: const Color(0xFF181A26),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                items: _years
                    .map(
                      (year) =>
                          DropdownMenuItem(value: year, child: Text(year)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedYear = value;
                  });
                },
                validator: (value) =>
                    value == null || value.isEmpty ? 'Year is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _guideController,
                decoration: InputDecoration(
                  labelText: 'Guide',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: const Color(0xFF181A26),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _githubLinkController,
                decoration: InputDecoration(
                  labelText: 'GitHub Link',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: const Color(0xFF181A26),
                  prefixIcon: const Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickResearchPaper,
                icon: const Icon(Icons.upload_file),
                label: const Text('Choose Research Paper'),
              ),
              if (_researchPaperFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Selected file: ${_researchPaperFile!.path.split('/').last}',
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadProject,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Project'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
