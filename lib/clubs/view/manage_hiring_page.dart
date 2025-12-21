// ignore_for_file: use_raw_strings, lines_longer_than_80_chars, avoid_catches_without_on_clauses, unnecessary_lambdas, flutter_style_todos, depend_on_referenced_packages, document_ignores

import 'package:app_ui/app_ui.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/Provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ManageHiringPage extends StatefulWidget {
  const ManageHiringPage({
    required this.clubId,
    super.key,
  });

  final String clubId;

  @override
  State<ManageHiringPage> createState() => _ManageHiringPageState();
}

class _ManageHiringPageState extends State<ManageHiringPage> {
  final _rolesController = TextEditingController();
  final _classesController = TextEditingController();
  bool _isHiringEnabled = false;
  bool _isLoading = true;
  bool _isSaving = false;

  List<String> _roles = [];
  List<String> _classes = [];

  List<String> _parsePgArray(dynamic value) {
    if (value is List<dynamic>) {
      return value.cast<String>();
    } else if (value is String) {
      // Check if it's already a JSON array string like ["item1","item2"]
      if (value.startsWith('[') && value.endsWith(']')) {
        // Remove brackets and quotes, split by comma
        final content = value.substring(1, value.length - 1);
        if (content.isEmpty) return [];
        return content
            .split('","')
            .map((e) => e.replaceAll('"', '').trim())
            .toList();
      } else if (value.startsWith('{') && value.endsWith('}')) {
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
    return [];
  }

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

    final hiringStream = databaseClient.watchClubHiring(widget.clubId);
    final hiringData = await hiringStream.first;

    if (hiringData != null) {
      setState(() {
        _isHiringEnabled = true;
        _roles = _parsePgArray(hiringData['roles']);
        _classes = _parsePgArray(hiringData['classes']);
        _rolesController.text = _roles.join(', ');
        _classesController.text = _classes.join(', ');
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveHiringData() async {
    setState(() => _isSaving = true);

    try {
      final databaseClient = Provider.of<PowerSyncDatabaseClient>(
        context,
        listen: false,
      );

      final roles = _rolesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final classes = _classesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      if (_isHiringEnabled) {
        if (_roles.isEmpty && _classes.isEmpty) {
          await databaseClient.createClubHiring(
            clubId: widget.clubId,
            roles: roles,
            classes: classes,
          );
        } else {
          await databaseClient.updateClubHiring(
            clubId: widget.clubId,
            roles: roles,
            classes: classes,
          );
        }

        // Send hiring notification to all users
        final clubResult = await databaseClient.database.execute(
          'SELECT club_name FROM clubs WHERE id = ?',
          [widget.clubId],
        );
        final clubName = clubResult.first['club_name'] as String;
        await databaseClient.sendHiringNotification(
          clubId: widget.clubId,
          clubName: clubName,
        );
      } else {
        await databaseClient.deleteClubHiring(widget.clubId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hiring settings saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving hiring settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppScaffold(
        appBar: AppBar(
          title: const Text('Manage Hiring'),
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
        title: const Text('Manage Hiring'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveHiringData,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text('Enable Hiring'),
                subtitle: const Text(
                  'Allow students to apply for positions in this club',
                ),
                value: _isHiringEnabled,
                onChanged: (value) {
                  setState(() {
                    _isHiringEnabled = value;
                  });
                },
                secondary: Icon(
                  _isHiringEnabled ? Icons.people : Icons.people_outline,
                  color: _isHiringEnabled ? Colors.green : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isHiringEnabled) ...[
              TextFormField(
                controller: _rolesController,
                decoration: InputDecoration(
                  labelText: 'Available Roles',
                  hintText:
                      'Enter roles separated by commas (e.g., Developer, Designer, Manager)',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: const Color(0xFF181A26),
                  prefixIcon: const Icon(Icons.work),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _classesController,
                decoration: InputDecoration(
                  labelText: 'Eligible Classes',
                  hintText:
                      'Enter classes separated by commas (e.g., FY, SY, TY, B.Tech)',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: const Color(0xFF181A26),
                  prefixIcon: const Icon(Icons.school),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              const Text(
                'Applications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: Provider.of<PowerSyncDatabaseClient>(
                  context,
                  listen: false,
                ).watchClubApplications(widget.clubId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final applications = snapshot.data ?? [];
                  if (applications.isEmpty) {
                    return const Text('No applications received yet');
                  }
                  return Column(
                    children: applications
                        .map((app) => _ApplicationCard(app))
                        .toList(),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _rolesController.dispose();
    _classesController.dispose();
    super.dispose();
  }
}

class _ApplicationCard extends StatefulWidget {
  const _ApplicationCard(this.application);

  final Map<String, dynamic> application;

  @override
  State<_ApplicationCard> createState() => _ApplicationCardState();
}

class _ApplicationCardState extends State<_ApplicationCard> {
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.application['status'] as String? ?? 'pending';
  }

  Color _getStatusColor() {
    switch (_status) {
      case 'pending':
        return Colors.blue;
      case 'received':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final databaseClient = Provider.of<PowerSyncDatabaseClient>(
      context,
      listen: false,
    );

    try {
      await databaseClient.updateApplicationStatus(
        applicationId: widget.application['id'] as String,
        status: newStatus,
      );

      setState(() {
        _status = newStatus;
      });

      // Send notification
      final userId = widget.application['user_id'] as String;
      final roleApplied = widget.application['role_applied'] as String;

      if (newStatus == 'accepted') {
        await databaseClient.sendApplicationNotification(
          userId: userId,
          title: 'Application Accepted',
          body:
              'Your application for the role "$roleApplied" has been accepted and you will get the call for the interview.',
        );
      } else if (newStatus == 'rejected') {
        await databaseClient.sendApplicationNotification(
          userId: userId,
          title: 'Application Rejected',
          body:
              'Your application for the role "$roleApplied" is rejected, you may try again next time.',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application $newStatus successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardColor.withOpacity(0.95),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.application['student_name'] as String,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Role: ${widget.application['role_applied']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor().withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.class_,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Class: ${widget.application['class']}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Department: ${widget.application['department']}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.badge,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'PRN: ${widget.application['prn']}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Phone: ${widget.application['phone']}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_status == 'pending' || _status == 'received') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_status == 'pending') {
                          await _updateStatus('received');
                        }
                        final resumeUrl =
                            widget.application['resume_url'] as String?;
                        if (resumeUrl != null && resumeUrl.isNotEmpty) {
                          final uri = Uri.parse(resumeUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Unable to open resume'),
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Resume not available'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.visibility, size: 18),
                      label: Text(
                        _status == 'pending' ? 'View Resume' : 'Resume Viewed',
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  if (_status == 'received') ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _updateStatus('accepted'),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _updateStatus('rejected'),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _status == 'accepted' ? Icons.check_circle : Icons.cancel,
                      color: _getStatusColor(),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Status: ${_status.toUpperCase()}',
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
