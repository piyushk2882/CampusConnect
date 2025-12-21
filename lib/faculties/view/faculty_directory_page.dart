import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/faculties/model/faculty.dart';
import 'package:campusconnect/faculties/widgets/faculty_card.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class FacultyDirectoryPage extends StatefulWidget {
  const FacultyDirectoryPage({super.key});

  @override
  State<FacultyDirectoryPage> createState() => _FacultyDirectoryPageState();
}

class _FacultyDirectoryPageState extends State<FacultyDirectoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedDepartment;
  String? _selectedDesignation;

  List<Faculty> _allFaculties = [];
  bool _isLoading = true;

  List<Faculty> get _filteredFaculties {
    return _allFaculties.where((faculty) {
      final matchesSearch = faculty.fullname.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faculty.department.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faculty.designation.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesDepartment = _selectedDepartment == null || faculty.department == _selectedDepartment;
      final matchesDesignation = _selectedDesignation == null || faculty.designation == _selectedDesignation;

      return matchesSearch && matchesDepartment && matchesDesignation;
    }).toList();
  }

  Set<String> get _departments => _allFaculties.map((f) => f.department).toSet();
  Set<String> get _designations => _allFaculties.map((f) => f.designation).toSet();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_allFaculties.isEmpty && _isLoading) {
      _loadFaculties();
    }
  }

  Future<void> _loadFaculties() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final databaseClient = Provider.of<PowerSyncDatabaseClient>(context);
      print('Calling getFaculties...');
      final facultiesData = await databaseClient.getFaculties();
      print('Received facultiesData: $facultiesData');
      setState(() {
        _allFaculties = facultiesData.map(Faculty.fromJson).toList();
        _isLoading = false;
      });
      print('Loaded ${_allFaculties.length} faculties.');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading faculties: $e');
      // Handle error, maybe show a snackbar
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load faculties: $e')),
        );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Directory'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search faculty...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: const Color(0xFF181A26),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDepartment,
                    decoration: InputDecoration(
                      labelText: 'Department',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: const Color(0xFF181A26),
                      prefixIcon: const Icon(Icons.business),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        child: Text('All Departments'),
                      ),
                      ..._departments.map((dept) => DropdownMenuItem<String>(
                            value: dept,
                            child: Text(dept),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDepartment = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDesignation,
                    decoration: InputDecoration(
                      labelText: 'Designation',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: const Color(0xFF181A26),
                      prefixIcon: const Icon(Icons.work),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        child: Text('All Designations'),
                      ),
                      ..._designations.map((desig) => DropdownMenuItem<String>(
                            value: desig,
                            child: Text(desig),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDesignation = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _filteredFaculties.isEmpty
                    ? const Center(
                        child: Text('No faculty members found.'),
                      )
                    : ListView.builder(
                        itemCount: _filteredFaculties.length,
                        itemBuilder: (context, index) {
                          return FacultyCard(faculty: _filteredFaculties[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
