// ignore_for_file: undefined_shown_name, unused_local_variable, document_ignores

import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/app/bloc/app_bloc.dart';
import 'package:campusconnect/comments/view/comments_page.dart';
import 'package:campusconnect/feed/bloc/feed_bloc.dart';
import 'package:campusconnect/feed/post/bloc/post_bloc.dart';
import 'package:campusconnect/feed/post/video/view/video_player.dart';
import 'package:campusconnect/feed/post/video/widgets/video_player_inherited_widget.dart';
import 'package:campusconnect/feed/widgets/post_share_dialog.dart';
import 'package:campusconnect/user_profile/widgets/user_profile_props.dart'
    show UserProfileProps, build;
import 'package:campusconnect_blocks_ui/campusconnect_blocks_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:insta_blocks/insta_blocks.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:shared/shared.dart';
import 'package:user_repository/user_repository.dart';

class PostView extends StatelessWidget {
  const PostView({
    required this.block,
    this.videoPlayerType = VideoPlayerType.feed,
    this.builder,
    this.postIndex,
    this.withInViewNotifier = true,
    this.withCustomVideoPlayer = true,
    super.key,
  });

  final PostBlock block;
  final WidgetBuilder? builder;
  final int? postIndex;
  final bool withInViewNotifier;
  final bool withCustomVideoPlayer;
  final VideoPlayerType videoPlayerType;

  @override
  Widget build(BuildContext context) {
    final user = context.select((AppBloc bloc) => bloc.state.user);

    return BlocProvider(
      create: (context) =>
          PostBloc(
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
                currentUserId: user.id,
              ),
            )
            ..add(const PostLikersInFollowingsFetchRequested()),
      child:
          builder?.call(context) ??
          PostLargeView(
            block: block,
            postIndex: postIndex,
            withInViewNotifier: withInViewNotifier,
            withCustomVideoPlayer: withCustomVideoPlayer,
            videoPlayerType: videoPlayerType,
          ),
    );
  }
}

class PostLargeView extends StatelessWidget {
  const PostLargeView({
    required this.block,
    required this.postIndex,
    required this.withInViewNotifier,
    required this.withCustomVideoPlayer,
    required this.videoPlayerType,
    super.key,
  });

  final PostBlock block;
  final int? postIndex;
  final bool withInViewNotifier;
  final bool withCustomVideoPlayer;
  final VideoPlayerType videoPlayerType;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PostBloc>();

    final isOwner = context.select((PostBloc bloc) => bloc.state.isOwner);
    final isLiked = context.select((PostBloc bloc) => bloc.state.isLiked);
    final likesCount = context.select((PostBloc bloc) => bloc.state.likes);
    final isFollowed = context.select((PostBloc bloc) => bloc.state.isFollowed);
    final commentsCount = context.select(
      (PostBloc bloc) => bloc.state.commentsCount,
    );
    final likersInFollowing = context.select(
      (PostBloc bloc) => bloc.state.likersInFollowings,
    );
    final isSaved = context.select((PostBloc bloc) => bloc.state.isSaved);

    if (block is PostSponsoredBlock) {
      return PostSponsored(
        key: ValueKey(block.id),
        block: block as PostSponsoredBlock,
        isOwner: isOwner,
        isLiked: isLiked,
        likePost: () => bloc.add(const PostLikeRequested()),
        likesCount: likesCount,
        isFollowed: isOwner || (isFollowed ?? true),
        follow: () =>
            bloc.add(PostAuthorFollowRequested(authorId: block.author.id)),
        enableFollowButton: true,
        onCommentsTap: (showFullSized) {
          context.showScrollableModal(
            showFullSized: showFullSized,
            pageBuilder: (scrollController, draggableScrollController) =>
                CommentsPage(
                  post: block,
                  scrollController: scrollController,
                  draggableScrollController: draggableScrollController,
                ),
          );
        },
        postIndex: postIndex,
        withInViewNotifier: withInViewNotifier,
        commentsCount: commentsCount,
        postOptionsSettings: isOwner
            ? PostOptionsSettings.owner(
                onPostEdit: (block) => context.pushNamed(
                  'post_edit',
                  pathParameters: {'post_id': block.id},
                  extra: block,
                ),
                onPostDelete: (_) {
                  bloc.add(const PostDeleteRequested());
                  context.read<FeedBloc>().add(
                    FeedUpdateRequested(
                      update: FeedPageUpdate(
                        newPost: block.toPost,
                        type: PageUpdateType.delete,
                      ),
                    ),
                  );
                },
              )
            : const PostOptionsSettings.viewer(),
        onUserTap: (userId) => context.pushNamed(
          'user_profile',
          pathParameters: {'user_id': userId},
        ),
        onPressed: (action) => action?.when(
          navigateToPostAuthor: (action) => context.pushNamed(
            'user_profile',
            pathParameters: {'user_id': action.authorId},
          ),
          navigateToSponsoredPostAuthor: (action) => context.pushNamed(
            'user_profile',
            pathParameters: {'user_id': action.authorId},
            extra: UserProfileProps.build(
              isSponsored: true,
              promoBlockAction: action,
              sponsoredPost: block as PostSponsoredBlock,
            ),
          ),
        ),
        onPostShareTap: (postId, author) {
          showDialog<void>(
            context: context,
            builder: (context) => PostShareDialog(
              postId: postId,
              author: author,
            ),
          );
        },
        videoPlayerBuilder: !withCustomVideoPlayer
            ? null
            : (_, media, aspectRatio, isInView) {
                final videoPlayerState = VideoPlayerInheritedWidget.of(
                  context,
                ).videoPlayerState;
                return VideoPlayerInViewNotifierWidget(
                  type: videoPlayerType,
                  builder: (context, shouldPlay, child) {
                    final play = shouldPlay && isInView;
                    return ValueListenableBuilder(
                      valueListenable: videoPlayerState.withSound,
                      builder: (context, withSound, child) {
                        return InlineVideo(
                          key: ValueKey(media.url),
                          videoSettings: VideoSettings.build(
                            videoUrl: media.url,
                            shouldPlay: play,
                            aspectRatio: aspectRatio,
                            blurHash: media.blurHash,
                            withSound: withSound,
                            onSoundToggled: ({required enable}) {
                              videoPlayerState.withSound.value = enable;
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
      );
    }
    return PostLarge(
      key: ValueKey(block.id),
      block: block,
      isOwner: isOwner,
      isLiked: isLiked,
      likePost: () => bloc.add(const PostLikeRequested()),
      likesCount: likesCount,
      isFollowed: isOwner || (isFollowed ?? true),
      follow: () =>
          bloc.add(PostAuthorFollowRequested(authorId: block.author.id)),
      enableFollowButton: true,
      commentsCount: commentsCount,
      postIndex: postIndex,
      withInViewNotifier: withInViewNotifier,
      postOptionsSettings: isOwner
          ? PostOptionsSettings.owner(
              onPostEdit: (block) => context.pushNamed(
                'post_edit',
                pathParameters: {'post_id': block.id},
                extra: block,
              ),
              onPostDelete: (_) {
                bloc.add(const PostDeleteRequested());
                context.read<FeedBloc>().add(
                  FeedUpdateRequested(
                    update: FeedPageUpdate(
                      newPost: block.toPost,
                      type: PageUpdateType.delete,
                    ),
                  ),
                );
              },
            )
          : const PostOptionsSettings.viewer(),
      onUserTap: (userId) => context.pushNamed(
        'user_profile',
        pathParameters: {'user_id': userId},
      ),
      onPressed: (action) => action.when(
        navigateToPostAuthor: (action) => context.pushNamed(
          'user_profile',
          pathParameters: {'user_id': action.authorId},
        ),
        navigateToSponsoredPostAuthor: (action) => context.pushNamed(
          'user_profile',
          pathParameters: {'user_id': action.authorId},
          extra: UserProfileProps.build(
            isSponsored: true,
            promoBlockAction: action,
            sponsoredPost: block as PostSponsoredBlock,
          ),
        ),
      ),
      onCommentsTap: (showFullSized) => context.showScrollableModal(
        showFullSized: showFullSized,
        pageBuilder: (scrollController, draggableScrollController) =>
            CommentsPage(
              post: block,
              scrollController: scrollController,
              draggableScrollController: draggableScrollController,
            ),
      ),
      onPostShareTap: (postId, author) {
        showDialog<void>(
          context: context,
          builder: (context) => PostShareDialog(
            postId: postId,
            author: author,
          ),
        );
      },
      isSaved: isSaved,
      onSaveTap: () => bloc.add(const PostSaveRequested()),
    );
  }
}
