import 'package:campusconnect/user_profile/bloc/user_profile_bloc.dart';
import 'package:campusconnect_blocks_ui/campusconnect_blocks_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insta_blocks/insta_blocks.dart';
import 'package:shared/shared.dart';

class UserProfileMentionedPostsPage extends StatefulWidget {
  const UserProfileMentionedPostsPage({super.key});

  @override
  State<UserProfileMentionedPostsPage> createState() =>
      _UserProfileMentionedPostsPageState();
}

class _UserProfileMentionedPostsPageState
    extends State<UserProfileMentionedPostsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CustomScrollView(
      cacheExtent: 2760,
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        BetterStreamBuilder<List<PostBlock>>(
          initialData: const <PostBlock>[],
          stream: context.read<UserProfileBloc>().savedPosts(),
          builder: (context, blocks) {
            if (blocks.isEmpty) {
              return const SliverFillRemaining(
                child: Center(
                  child: Text('No mentioned posts yet'),
                ),
              );
            }
            return SliverList.builder(
              itemCount: blocks.length,
              itemBuilder: (context, index) {
                final block = blocks[index];
                return PostLarge(
                  block: block,
                  isOwner: false,
                  isFollowed: false,
                  follow: () {},
                  enableFollowButton: false,
                  onPressed: (_) {},
                  withInViewNotifier: false,
                  postOptionsSettings: const PostOptionsSettings.viewer(),
                  onPostShareTap: (postId, author) {},
                  onUserTap: (userId) {},
                  onCommentsTap: (showComments) {},
                  onSaveTap: () {},
                  isLiked: false,
                  likePost: () {},
                  likesCount: 0,
                  commentsCount: 0,
                  likersInFollowings: const [],
                );
              },
            );
          },
        ),
      ],
    );
  }
}
