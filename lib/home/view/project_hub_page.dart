// ignore_for_file: avoid_print, cascade_invocations, avoid_catches_without_on_clauses, unnecessary_brace_in_string_interps, lines_longer_than_80_chars, use_named_constants, inference_failure_on_instance_creation, unawaited_futures, document_ignores, depend_on_referenced_packages, inference_failure_on_function_invocation

import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/app/view/app.dart';
import 'package:campusconnect/home/provider/home_provider.dart';
import 'package:campusconnect/home/view/create_project_page.dart';
import 'package:campusconnect/home/view/project_details_page.dart';
import 'package:campusconnect/home/view/saved_projects_page.dart';
import 'package:campusconnect/home/widgets/project_card.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProjectHubPage extends StatefulWidget {
  const ProjectHubPage({super.key});

  @override
  State<ProjectHubPage> createState() => _ProjectHubPageState();
}

class _ProjectHubPageState extends State<ProjectHubPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  // Mock project data for now
  final List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;
  String? _selectedBranch;
  String? _selectedDomain;
  String? _selectedYear;
  List<String> _uniqueBranches = [];
  List<String> _uniqueDomains = [];
  List<String> _uniqueYears = [];
  late final PowerSyncDatabaseClient _databaseClient;
  bool _isVerified = false;
  bool _isClubAdmin = false;

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
    _loadUserStatus();
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

  Future<void> _loadUserStatus() async {
    final userId = _databaseClient.currentUserId;
    if (userId != null) {
      _isVerified = await _databaseClient.isUserVerified(userId: userId).first;
      _isClubAdmin = await _databaseClient.isClubAdmin(userId);
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadProjects() async {
    try {
      print('Loading projects...');
      final result = await _databaseClient.getProjects();
      print('Number of projects from DB: ${result.length}');
      if (result.isEmpty) {
        print('No projects found in database.');
      } else {
        for (final row in result) {
          print('Project: ${row['title']} (ID: ${row['id']})');
        }
      }
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
        final isBookmarked = await _databaseClient.isProjectPinned(projectId);
        projects.add({
          'id': projectId,
          'title': row['title'] as String? ?? '',
          'summary': row['summary'] as String? ?? '',
          'domain': row['domain'] as String? ?? '',
          'branch': row['branch'] as String? ?? '',
          'year': row['year'] as String? ?? '',
          'guide': row['guide'] as String? ?? '',
          'tags': tags,
          'rating': avgRating,
          'githubLink': row['github_link'] as String? ?? '',
          'researchpaperLink': row['researchpaper_link'] as String? ?? '',
          'isBookmarked': isBookmarked,
        });
      }
      print('Processed projects count: ${projects.length}');
      if (mounted) {
        setState(() {
          _projects.clear();
          _projects.addAll(projects);
          _isLoading = false;
        });
        print('SetState called, _projects.length: ${_projects.length}');

        // Compute unique values for filters
        setState(() {
          _uniqueBranches =
              _projects
                  .map((p) => p['branch'] as String)
                  .where((b) => b.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
          _uniqueDomains =
              _projects
                  .map((p) => p['domain'] as String)
                  .where((d) => d.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
          _uniqueYears =
              _projects
                  .map((p) => p['year'] as String)
                  .where((y) => y.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
        });
      }
    } catch (e) {
      print('Error loading projects: $e');
      // Handle error, perhaps show a snackbar
      openSnackBar(
        SnackbarMessage.error(
          title: 'Failed to load projects: ${e}',
        ),
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProjects = _projects.where((project) {
      final title = project['title'].toString().toLowerCase();
      final matchesTitle = title.contains(_searchText);
      final matchesBranch =
          _selectedBranch == null || project['branch'] == _selectedBranch;
      final matchesDomain =
          _selectedDomain == null || project['domain'] == _selectedDomain;
      final matchesYear =
          _selectedYear == null || project['year'] == _selectedYear;
      return matchesTitle && matchesBranch && matchesDomain && matchesYear;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.black, // dark background
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HomeProvider().animateToPage(1);
          },
        ),
        title: Text('Project Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SavedProjectsPage(),
                ),
              );
            },
          ),
          if (_isVerified && !_isClubAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateProjectPage(),
                  ),
                );
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // Search bar and filter icon row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search projects...',
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
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white),
                    onPressed: () {
                      var localSelectedBranch = _selectedBranch;
                      var localSelectedDomain = _selectedDomain;
                      var localSelectedYear = _selectedYear;

                      showModalBottomSheet(
                        context: context,
                        backgroundColor: AppColors.black,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (context) => StatefulBuilder(
                          builder: (context, setModalState) => Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Filter Options',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: localSelectedBranch ?? 'All',
                                  decoration: InputDecoration(
                                    labelText: 'Branch',
                                    labelStyle: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF1E1E1E),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  dropdownColor: AppColors.black,
                                  style: const TextStyle(color: Colors.white),
                                  items: ['All', ..._uniqueBranches]
                                      .map(
                                        (value) => DropdownMenuItem(
                                          value: value,
                                          child: Text(value),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setModalState(() {
                                      localSelectedBranch = value == 'All'
                                          ? null
                                          : value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: localSelectedDomain ?? 'All',
                                  decoration: InputDecoration(
                                    labelText: 'Domain',
                                    labelStyle: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF1E1E1E),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  dropdownColor: AppColors.black,
                                  style: const TextStyle(color: Colors.white),
                                  items: ['All', ..._uniqueDomains]
                                      .map(
                                        (value) => DropdownMenuItem(
                                          value: value,
                                          child: Text(value),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setModalState(() {
                                      localSelectedDomain = value == 'All'
                                          ? null
                                          : value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: localSelectedYear ?? 'All',
                                  decoration: InputDecoration(
                                    labelText: 'Year',
                                    labelStyle: const TextStyle(
                                      color: Colors.white54,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFF1E1E1E),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  dropdownColor: AppColors.black,
                                  style: const TextStyle(color: Colors.white),
                                  items: ['All', ..._uniqueYears]
                                      .map(
                                        (value) => DropdownMenuItem(
                                          value: value,
                                          child: Text(value),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setModalState(() {
                                      localSelectedYear = value == 'All'
                                          ? null
                                          : value;
                                    });
                                  },
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(color: Colors.white54),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedBranch = localSelectedBranch;
                                          _selectedDomain = localSelectedDomain;
                                          _selectedYear = localSelectedYear;
                                        });
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Apply filters'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Projects list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredProjects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.folder_open,
                            size: 64,
                            color: Colors.white54,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No projects available',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first project to get started',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CreateProjectPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text(
                              'Create Project',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
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
                            isBookmarked: project['isBookmarked'] as bool,
                            onBookmarkTap: () async {
                              final userId = _databaseClient.currentUserId;
                              if (userId == null) {
                                openSnackBar(
                                  const SnackbarMessage.error(
                                    title: 'Please log in to save projects',
                                  ),
                                );
                                return;
                              }
                              try {
                                final isPinned = await _databaseClient
                                    .isProjectPinned(
                                      project['id'] as String,
                                    );
                                if (isPinned) {
                                  await _databaseClient.unpinProject(
                                    projectId: project['id'] as String,
                                  );
                                  openSnackBar(
                                    const SnackbarMessage.success(
                                      title: 'Project removed from saved',
                                    ),
                                  );
                                } else {
                                  await _databaseClient.pinProject(
                                    projectId: project['id'] as String,
                                  );
                                  openSnackBar(
                                    const SnackbarMessage.success(
                                      title: 'Project saved',
                                    ),
                                  );
                                }
                                _loadProjects(); // Reload to update icon
                              } catch (e) {
                                print('Bookmark error: $e');
                                openSnackBar(
                                  SnackbarMessage.error(
                                    title: 'Failed to save project: ${e}',
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
