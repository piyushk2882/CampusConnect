import 'package:app_ui/app_ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:campusconnect/faculties/model/faculty.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FacultyCard extends StatelessWidget {
  const FacultyCard({
    required this.faculty,
    super.key,
  });

  final Faculty faculty;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      // Use a slightly larger margin for separation, as in the image
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + AppSpacing.xs,
      ),
      clipBehavior: Clip.antiAlias, // Ensures gradient respects rounded corners
      elevation: 4,
      shadowColor: Colors.green.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppSpacing.lg,
        ), // More rounded corners
      ),
      child: Container(
        // Apply the light green gradient from the image
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: const [
              Color(0xFF181A26),
              Color(0xFF181A26),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          // Increase padding for more internal space
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // Avatar with a border, as seen in the image
              _StyledAvatar(photoUrl: faculty.photoUrl),
              const SizedBox(height: AppSpacing.md),
              // Full name
              Text(
                '${faculty.titleOfRespect} ${faculty.fullname}',
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Designation (like "Role" in the image)
              _InfoRow(
                icon: Icons.work_outline,
                text: faculty.designation,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              // Department
              _InfoRow(
                icon: Icons.school_outlined,
                text: faculty.department,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Clickable Email
              _ClickableInfoRow(
                icon: Icons.email_outlined,
                text: faculty.email,
                onTap: () => _tryLaunchUrl('mailto:${faculty.email}'),
              ),
              const SizedBox(height: AppSpacing.xs),
              // Clickable Mobile Number
              _ClickableInfoRow(
                icon: Icons.phone_outlined,
                text: faculty.mobileNo,
                onTap: () => _tryLaunchUrl('tel:${faculty.mobileNo}'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to safely launch URLs
  Future<void> _tryLaunchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Handle error (e.g., show a snackbar)
      debugPrint('Could not launch $url: $e');
    }
  }
}

// Private helper widget for the styled avatar
class _StyledAvatar extends StatelessWidget {
  const _StyledAvatar({required this.photoUrl});

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        AppSpacing.xs,
      ), // This creates the border thickness
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.green.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 40, // Same as your original radius
        backgroundColor: Colors.grey.shade200, // Fallback color
        backgroundImage: CachedNetworkImageProvider(photoUrl),
        onBackgroundImageError: (_, __) {
          // You can return a widget here, but for CircleAvatar,
          // it's better to use a foreground/child widget.
          // For simplicity, we just let the error state show.
        },
        // If error, show a fallback icon
        child: Builder(
          builder: (context) {
            final imageProvider = CachedNetworkImageProvider(photoUrl);
            return CircleAvatar(
              radius: 40,
              backgroundImage: imageProvider
                ..resolve(const ImageConfiguration()).addListener(
                  ImageStreamListener(
                    (_, __) {},
                    onError: (exception, stackTrace) {
                      // This is a bit of a hack to show child on error
                      // A more robust way is to use CachedNetworkImage widget
                    },
                  ),
                ),
              child:
                  imageProvider.hashCode ==
                      CachedNetworkImageProvider(photoUrl).hashCode
                  ? null
                  : const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey,
                    ), // Fallback icon
            );
          },
        ),
      ),
    );
  }
}

// Private helper widget for a non-clickable icon/text row
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    this.style,
  });

  final IconData icon;
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle =
        style ??
        Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: effectiveStyle?.color?.withOpacity(0.8)),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            text,
            style: effectiveStyle,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// Private helper widget for a clickable icon/text row
class _ClickableInfoRow extends StatelessWidget {
  const _ClickableInfoRow({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Row takes only needed space
          children: [
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                text,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
