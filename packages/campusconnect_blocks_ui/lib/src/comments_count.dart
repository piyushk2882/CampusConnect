import 'package:app_ui/app_ui.dart';
import 'package:campusconnect_blocks_ui/campusconnect_blocks_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sprung/sprung.dart';

/// {@template comments_count}
/// Renders the comment count with animation.
/// {@endtemplate}
class CommentsCount extends StatefulWidget {
  const CommentsCount({
    required this.count,
    required this.onTap,
    super.key,
  });

  final int count;
  final VoidCallback onTap;

  @override
  State<CommentsCount> createState() => _CommentsCountState();
}

class _CommentsCountState extends State<CommentsCount>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final count = widget.count;
    final isVisible = count != 0;

    // Safety check: Ensure commentTextDelegate is initialized
    final commentTextDelegate = BlockSettings().commentTextDelegate;

    return AnimatedVisibility(
      height: 25,
      duration: 250.ms,
      isVisible: isVisible,
      curve: Sprung.criticallyDamped,
      child: Tappable(
        onTap: widget.onTap,
        child: Text(
          commentTextDelegate.seeAllCommentsText(count),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.bodyLarge?.copyWith(color: AppColors.grey),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
