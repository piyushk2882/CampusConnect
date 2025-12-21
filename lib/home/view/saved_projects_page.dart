// ignore_for_file: inference_failure_on_instance_creation, document_ignores, depend_on_referenced_packages, cascade_invocations, avoid_catches_without_on_clauses, use_named_constants, unawaited_futures, lines_longer_than_80_chars

import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/app/view/app.dart';
import 'package:campusconnect/home/view/project_details_page.dart';
import 'package:campusconnect/home/widgets/project_card.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SavedProjectsPage extends StatefulWidget {
  const SavedProjectsPage({super.key});

  @override
  State<SavedProjectsPage> createState() => _SavedProjectsPageState();
}

class _SavedProjectsPageState extends State<SavedProjectsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  // Mock project data for now
  final List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;
  late final PowerSyncDatabaseClient _databaseClient;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _databaseClient = Provider.of<PowerSyncDatabaseClient>(
      context,
      listen: false,
    );
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchText = _searchController.text.toLowerCase();
    });
  }

  Future<void> _loadProjects() async {
    try {
      final result = await _databaseClient.getPinnedProjects();
      final projects = <Map<String, dynamic>>[];
      for (final row in result) {
        final tags = <String>[];
        if (row['domain'] != null) tags.add(row['domain'] as String);
        if (row['branch'] != null) tags.add(row['branch'] as String);
        if (row['year'] != null) tags.add(row['year'] as String);
        final projectId = row['id'] as String? ?? '';
        final avgRating = await _databaseClient.getAverageProjectRating(
          projectId,
        );
        projects.add({
          'id': projectId,
          'title': row['title'] as String? ?? '',
          'summary': row['summary'] as String? ?? '',
          'domain': row['domain'] as String? ?? '',
          'year': row['year'] as String? ?? '',
          'guide': row['guide'] as String? ?? '',
          'tags': tags,
          'rating': avgRating,
          'githubLink': row['github_link'] as String? ?? '',
          'researchpaperLink': row['researchpaper_link'] as String? ?? '',
        });
      }
      setState(() {
        _projects.clear();
        _projects.addAll(projects);
        _isLoading = false;
      });
    } catch (e) {
      // Handle error, perhaps show a snackbar
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProjects = _projects.where((project) {
      final title = project['title'].toString().toLowerCase();
      return title.contains(_searchText);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.black, // dark background
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        title: Text('Saved Projects'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search saved projects...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.white54,
                ),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(),
              ),
            ),
            const SizedBox(height: 8),
            // Projects list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredProjects.isEmpty
                  ? const Center(
                      child: Text(
                        'No saved projects yet.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadProjects,
                      child: ListView.builder(
                        itemCount: filteredProjects.length,
                        itemBuilder: (context, index) {
                          final project = filteredProjects[index];
                          return ProjectCard(
                            title: project['title'] as String,
                            summary: project['summary'] as String,
                            tags: List<String>.from(
                              project['tags'] as Iterable<dynamic>,
                            ),
                            rating: project['rating'] as double,
                            githubLink: project['githubLink'] as String,
                            pdfUrl: project['researchpaperLink'] as String,
                            isBookmarked: true,
                            onBookmarkTap: () async {
                              try {
                                await _databaseClient.unpinProject(
                                  projectId: project['id'] as String,
                                );
                                setState(() {
                                  _projects.removeAt(index);
                                });
                                openSnackBar(
                                  const SnackbarMessage.success(
                                    title: 'Project removed from saved',
                                  ),
                                );
                              } catch (e) {
                                openSnackBar(
                                  const SnackbarMessage.error(
                                    title: 'Failed to remove project',
                                  ),
                                );
                              }
                            },
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ProjectDetailsPage(
                                    project: project,
                                    onRatingSubmitted: _loadProjects,
                                  ),
                                ),
                              );
                              _loadProjects();
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
