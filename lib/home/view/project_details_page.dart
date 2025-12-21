// ignore_for_file: depend_on_referenced_packages, deprecated_member_use, inference_failure_on_instance_creation, use_build_context_synchronously, avoid_catches_without_on_clauses, lines_longer_than_80_chars, document_ignores

import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/app/view/app.dart';
import 'package:campusconnect/home/view/saved_projects_page.dart';
import 'package:database_client/database_client.dart';
import 'package:flutter/material.dart';
import 'package:provider/Provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectDetailsPage extends StatefulWidget {
  const ProjectDetailsPage({
    required this.project,
    super.key,
    this.onRatingSubmitted,
  });
  final Map<String, dynamic> project;
  final VoidCallback? onRatingSubmitted;

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  double _currentRating = 0;
  bool _isLoadingRating = true;
  bool _isLoadingReviews = true;
  late final PowerSyncDatabaseClient _databaseClient;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _databaseClient = Provider.of<PowerSyncDatabaseClient>(
      context,
      listen: false,
    );
    _loadUserRating();
    _loadReviews();
  }

  Future<void> _loadUserRating() async {
    final rating = await _databaseClient.getUserProjectRating(
      widget.project['id'] as String,
    );
    setState(() {
      _currentRating = rating?.toDouble() ?? 0.0;
      _isLoadingRating = false;
    });
  }

  Future<void> _loadReviews() async {
    final reviews = await _databaseClient.getProjectRatingsWithReviews(
      widget.project['id'] as String,
    );
    setState(() {
      _reviews = reviews;
      _isLoadingReviews = false;
    });
  }

  Future<void> _submitRating(double rating) async {
    await _databaseClient.submitProjectRating(
      projectId: widget.project['id'] as String,
      rating: rating.toInt(),
    );
    setState(() {
      _currentRating = rating;
    });
    await _loadReviews();
    widget.onRatingSubmitted?.call();
      openSnackBar(
        const SnackbarMessage.success(
          title: 'Rating submitted successfully',
        ),
      );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      openSnackBar(
        const SnackbarMessage.error(
          title: 'Could not launch URL',
        ),
      );
    }
  }

  void _viewResearchPaper() {
    final pdfUrl = widget.project['researchpaperLink'] as String?;
    if (pdfUrl == null || pdfUrl.isEmpty) {
      openSnackBar(
        const SnackbarMessage.error(
          title: 'No research paper available',
        ),
      );
      return;
    }
    _launchUrl(pdfUrl);
  }

  void _navigateToWriteReview() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => WriteReviewPage(
              projectId: widget.project['id'] as String,
              onReviewSubmitted: widget.onRatingSubmitted,
            ),
          ),
        )
        .then((_) {
          // Reload reviews after returning from write review page
          _loadReviews();
        });
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return Icon(
          starIndex <= rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          (project['title'] as String?) ?? 'Project Details',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              (project['title'] as String?) ?? '',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              (project['summary'] as String?) ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Domain: ${project['domain'] ?? 'Not provided'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Year: ${project['year'] ?? 'Not provided'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Guide: ${project['guide'] ?? 'Not provided'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                final githubLink = project['githubLink'] as String?;
                if (githubLink == null || githubLink.isEmpty) {
                  openSnackBar(
                    const SnackbarMessage.error(
                      title: 'No GitHub link available',
                    ),
                  );
                  return;
                }
                _launchUrl(githubLink);
              },
              icon: Assets.images.githubIcon.image(
                height: 24,
                width: 24,
                color: Colors.white,
              ),
              label: const Text(
                'View github Repo',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _viewResearchPaper,
              icon: Assets.images.pdfIcon.image(
                height: 24,
                width: 24,
                color: Colors.white,
              ),
              label: const Text(
                'View Research paper',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Rate this project',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoadingRating)
              const CircularProgressIndicator()
            else
              Row(
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    icon: Icon(
                      starIndex <= _currentRating
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => _submitRating(starIndex.toDouble()),
                  );
                }),
              ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _navigateToWriteReview,
              child: const Text(
                'Write a review',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Rating and Reviews',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoadingReviews)
              const CircularProgressIndicator()
            else if (_reviews.isEmpty)
              const Text(
                'No reviews added yet.',
                style: TextStyle(color: Colors.white70),
              )
            else
              Column(
                children: _reviews.map((review) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundImage: review['avatar_url'] != null
                              ? NetworkImage(review['avatar_url'] as String)
                              : null,
                          radius: 20,
                          child: review['avatar_url'] == null
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (review['full_name'] as String?) ?? 'Anonymous',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildStarRating(
                                (review['rating'] as num).toDouble(),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (review['review'] as String?) ?? '',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class WriteReviewPage extends StatefulWidget {
  const WriteReviewPage({
    required this.projectId,
    super.key,
    this.onReviewSubmitted,
  });
  final String projectId;
  final VoidCallback? onReviewSubmitted;

  @override
  State<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  double _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;
  late final PowerSyncDatabaseClient _databaseClient;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _databaseClient = Provider.of<PowerSyncDatabaseClient>(
      context,
      listen: false,
    );
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a rating')),
      );
      return;
    }
    setState(() {
      _isSubmitting = true;
    });
    try {
      await _databaseClient.submitProjectRatingWithReview(
        projectId: widget.projectId,
        rating: _rating.toInt(),
        review: _reviewController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted')),
      );
      widget.onReviewSubmitted?.call();
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return IconButton(
          icon: Icon(
            starIndex <= _rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
          onPressed: () {
            setState(() {
              _rating = starIndex.toDouble();
            });
          },
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write a Review'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rate this project',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildStarRating(),
            const SizedBox(height: 16),
            const Text(
              'Write your review',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter your review here',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
