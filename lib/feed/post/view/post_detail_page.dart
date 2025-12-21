import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/app/bloc/app_bloc.dart';
import 'package:campusconnect/feed/post/post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insta_blocks/insta_blocks.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:user_repository/user_repository.dart';

class PostDetailPage extends StatelessWidget {
  const PostDetailPage({
    required this.blocks,
    required this.initialIndex,
    super.key,
  });

  final List<PostBlock> blocks;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: blocks.length,
        scrollDirection: Axis.vertical, // Instagram-like scroll
        itemBuilder: (context, index) {
          final block = blocks[index];

          // ✅ Check for reel without media
          if (block.isReel && block.firstMedia == null) {
            return const Center(
              child: Text(
                'Video unavailable',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            );
          }

          return BlocProvider(
            create: (context) => PostBloc(
              postId: block.id,
              postsRepository: context.read<PostsRepository>(),
              userRepository: context.read<UserRepository>(),
            )
              ..add(const PostLikesCountSubscriptionRequested())
              ..add(const PostCommentsCountSubscriptionRequested())
              ..add(const PostIsLikedSubscriptionRequested())
              ..add(
                PostAuthorFollowingStatusSubscriptionRequested(
                  ownerId: block.author.id,
                  currentUserId: context.read<AppBloc>().state.user.id,
                ),
              )
              ..add(const PostLikersInFollowingsFetchRequested()),
            child: PostView(
              block: block,
              postIndex: index,
              withInViewNotifier: false,
            ),
          );
        },
      ),
    );
  }
}
