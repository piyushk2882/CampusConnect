// ignore_for_file: unused_element, deprecated_member_use, depend_on_referenced_packages, lines_longer_than_80_chars, document_ignores

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({
    required this.title,
    required this.summary,
    required this.tags,
    required this.rating,
    required this.githubLink,
    required this.pdfUrl,
    super.key,
    this.onBookmarkTap,
    this.onTap,
    this.isBookmarked = false,
  });
  final String title;
  final String summary;
  final List<String> tags; // domain, branch, year
  final double rating; // mock rating
  final String githubLink;
  final String pdfUrl;
  final VoidCallback? onBookmarkTap;
  final VoidCallback? onTap;
  final bool isBookmarked;

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF7C4DFF), // purple color as in screenshot
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStarIcon(bool filled) {
    return Icon(
      filled ? Icons.star : Icons.star_border,
      color: Colors.amber,
      size: 16,
    );
  }

  @override
  Widget build(BuildContext context) {
    final starCount = rating.floor();
    final hasHalfStar = (rating - starCount) >= 0.5;
    const totalStars = 5;

    return InkWell(
      onTap: onTap,
      child: Card(
        color: const Color(0xFF181A26), // dark card background
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and bookmark icon row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: onBookmarkTap,
                    child: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Summary
              Text(
                summary,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Tags row
              Row(
                children: tags.map(_buildTag).toList(),
              ),
              const SizedBox(height: 8),
              // Rating row
              Row(
                children: [
                  Row(
                    children: List.generate(totalStars, (index) {
                      if (index < starCount) {
                        return _buildStarIcon(true);
                      } else if (index == starCount && hasHalfStar) {
                        return const Icon(
                          Icons.star_half,
                          color: Colors.amber,
                          size: 16,
                        );
                      } else {
                        return _buildStarIcon(false);
                      }
                    }),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$rating / 5',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
