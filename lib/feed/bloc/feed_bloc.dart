import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:app_ui/app_ui.dart';
import 'package:bloc/bloc.dart';
import 'package:campusconnect/app/view/app.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_remote_config_repository/firebase_remote_config_repository.dart';
import 'package:flutter/material.dart';
import 'package:insta_blocks/insta_blocks.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:shared/shared.dart';

part 'feed_bloc_mixin.dart';
part 'feed_event.dart';
part 'feed_state.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> with FeedBlocMixin {
  FeedBloc({
    required PostsRepository postsRepository,
    required FirebaseRemoteConfigRepository firebaseRemoteConfigRepository,
  }) : _firebaseRemoteConfigRepository = firebaseRemoteConfigRepository,
       _postsRepository = postsRepository,
       super(const FeedState.initial()) {
    on<FeedPageRequested>(_onFeedPageRequested);
    on<FeedRefreshRequested>(
      _onFeedRefreshRequested,
      transformer: throttleDroppable(duration: 550.ms),
    );
    on<FeedRecommendedPostsPageRequested>(
      _onFeedRecommendedPostsPageRequested,
      transformer: throttleDroppable(),
    );
    on<FeedReelsRefreshRequested>(
      _onFeedReelsRefreshRequested,
      transformer: throttleDroppable(duration: 550.ms),
    );
    on<FeedUpdateRequested>(_onFeedUpdateRequested);
    on<FeedPostCreateRequested>(_onFeedPostCreateRequested);
    on<FeedReelsPageRequested>(_onFeedReelsPageRequested);
  }

  @override
  PostsRepository get postsRepository => _postsRepository;

  final PostsRepository _postsRepository;
  final FirebaseRemoteConfigRepository _firebaseRemoteConfigRepository;

  Future<void> _onFeedPageRequested(
    FeedPageRequested event,
    Emitter<FeedState> emit,
  ) async {
    emit(state.loading());
    try {
      final currentPage = event.page ?? state.feed.feedPage.page;
      final (:newPage, :hasMore, :blocks) = await fetchFeedPage(
        page: currentPage,
        mapper: postsToReelBlockMapper,
        onlyFollowed: true,
      );

      final feed = state.feed.copyWith(
        feedPage: state.feed.feedPage.copyWith(
          page: newPage,
          hasMore: hasMore,
          blocks: [...state.feed.feedPage.blocks, ...blocks],
          totalBlocks: state.feed.feedPage.totalBlocks + blocks.length,
        ),
      );
      emit(state.populated(feed: feed));
    } on Exception catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.failure());
    }
  }

  Future<void> _onFeedRefreshRequested(
    FeedRefreshRequested event,
    Emitter<FeedState> emit,
  ) async {
    emit(state.loading());
    try {
      final (:newPage, :hasMore, :blocks) = await fetchFeedPage(
        onlyFollowed: true,
      );
      final feed = state.feed.copyWith(
        feedPage: FeedPage(
          page: newPage,
          blocks: blocks,
          hasMore: hasMore,
          totalBlocks: blocks.length,
        ),
      );

      emit(state.populated(feed: feed));

      if (!hasMore) add(const FeedRecommendedPostsPageRequested());
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.failure());
    }
  }

  @override
  // TODO: implement firebaseRemoteConfigRepository
  FirebaseRemoteConfigRepository get firebaseRemoteConfigRepository =>
      _firebaseRemoteConfigRepository;

  FutureOr<void> _onFeedRecommendedPostsPageRequested(
    FeedRecommendedPostsPageRequested event,
    Emitter<FeedState> emit,
  ) async {
    if (state.feed.feedPage.hasRecommendedPosts &&
        !state.feed.feedPage.hasMoreRecommended) {
      return;
    }

    emit(state.loading());
    try {
      final currentPage = state.feed.feedPage.recommendedPostsPage;
      final posts = await _postsRepository.getRecommendedPosts(
        offset: currentPage * 20,
        limit: 20,
      );

      final recommendedBlocks = posts
          .map((post) => post.toPostLargeBlock)
          .toList();

      final blocks = <InstaBlock>[];
      if (currentPage == 0) {
        blocks.addAll([
          if (recommendedBlocks.isNotEmpty) DividerHorizontalBlock(),
          const SectionHeaderBlock(
            sectionType: SectionHeaderBlockType.suggested,
          ),
        ]);
      }
      blocks.addAll(recommendedBlocks);

      final feed = state.feed.copyWith(
        feedPage: state.feed.feedPage.copyWith(
          blocks: [...state.feed.feedPage.blocks, ...blocks],
          totalBlocks: state.feed.feedPage.totalBlocks + blocks.length,
          hasMore: false,
          hasRecommendedPosts: true,
          recommendedPostsPage: currentPage + 1,
          hasMoreRecommended: posts.length == 20,
        ),
      );

      emit(state.populated(feed: feed));
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.failure());
    }
  }

  FutureOr<void> _onFeedUpdateRequested(
    FeedUpdateRequested event,
    Emitter<FeedState> emit,
  ) async {
    emit(state.loading());
    final update = event.update;
    final oldFeed = state.feed;

    try {
      final feedBlock = oldFeed.feedPage.blocks.findPostBlock(
        test: (block) => block.id == update.newPost.id,
      );
      final reel = oldFeed.reelsPage.blocks.findPostBlock(
        test: (block) =>
            block.id == update.newPost.id &&
            block.type == PostReelBlock.identifier,
      );
      if (feedBlock == null && reel == null && !update.isCreate) {
        return emit(state.populated());
      }
      final updatedFeedBlocks = oldFeed.updateFeedPage(update: update);
      List<InstaBlock>? updatedReelsBlocks;
      if (update.canUpdateReel) {
        updatedReelsBlocks = oldFeed.updateReelsPage(update: update);
      }

      final feed = oldFeed.copyWith(
        feedPage: oldFeed.feedPage.copyWith(
          blocks: updatedFeedBlocks,
          totalBlocks: updatedFeedBlocks.length,
        ),
        reelsPage: oldFeed.reelsPage.copyWith(
          blocks: updatedReelsBlocks,
          totalBlocks: updatedReelsBlocks?.length,
        ),
      );

      emit(state.populated(feed: feed));
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.failure());
    }
  }

  FutureOr<void> _onFeedPostCreateRequested(
    FeedPostCreateRequested event,
    Emitter<FeedState> emit,
  ) async {
    emit(state.loading());
    try {
      final newPost = await _postsRepository.createPost(
        id: event.postId,
        caption: event.caption,
        media: json.encode(event.media),
      );
      if (newPost != null) {
        add(
          FeedUpdateRequested(
            update: FeedPageUpdate(
              newPost: newPost,
              type: PageUpdateType.create,
            ),
          ),
        );
      }
      emit(state.populated());
      toggleLoadingIndeterminate(enable: false);
      openSnackBar(
        const SnackbarMessage.success(
          title: 'Successfully created post!',
        ),
      );
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.failure());
    }
  }

  FutureOr<void> _onFeedReelsPageRequested(
    FeedReelsPageRequested event,
    Emitter<FeedState> emit,
  ) async {
    emit(state.loading());
    try {
      final currentPage = event.page ?? state.feed.reelsPage.page;
      final (:newPage, :hasMore, :blocks) = await fetchFeedPage(
        page: currentPage,
        mapper: postsToReelBlockMapper,
        onlyFollowed: true,
      );

      final feed = state.feed.copyWith(
        reelsPage: state.feed.reelsPage.copyWith(
          page: newPage,
          hasMore: hasMore,
          blocks: [...state.feed.reelsPage.blocks, ...blocks],
          totalBlocks: state.feed.reelsPage.totalBlocks + blocks.length,
        ),
      );
      emit(state.populated(feed: feed));
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.failure());
    }
  }

  FutureOr<void> _onFeedReelsRefreshRequested(
    FeedReelsRefreshRequested event,
    Emitter<FeedState> emit,
  ) async {
    emit(state.loading());
    try {
      final (:newPage, :hasMore, :blocks) = await fetchFeedPage(
        mapper: postsToReelBlockMapper,
        onlyFollowed: true,
      );

      final feed = state.feed.copyWith(
        reelsPage: ReelsPage(
          page: newPage,
          hasMore: hasMore,
          blocks: blocks,
          totalBlocks: blocks.length,
        ),
      );
      emit(state.populated(feed: feed));
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.failure());
    }
  }
}

extension PostX on Post {
  /// Converts `Post` instance into `PostLargeBlock` instance.
  PostLargeBlock get toPostLargeBlock => PostLargeBlock(
    id: id,
    author: PostAuthor.confirmed(
      id: author.id,
      avatarUrl: author.avatarUrl,
      username: author.username,
    ), // PostAuthor.confirmed
    createdAt: createdAt,
    media: media,
    caption: caption,
    action: NavigateToPostAuthorProfileAction(authorId: author.id),
  );
  PostSmallBlock get toPostSmallBlock => PostSmallBlock(
    id: id,
    author: PostAuthor.confirmed(
      id: author.id,
      avatarUrl: author.avatarUrl,
      username: author.displayUsername,
    ),
    createdAt: createdAt,
    media: media,
    caption: caption,
  );
  PostReelBlock get toPostReelBlock => PostReelBlock(
    id: id,
    author: PostAuthor.confirmed(
      id: author.id,
      avatarUrl: author.avatarUrl,
      username: author.displayUsername,
    ),
    createdAt: createdAt,
    media: media,
    caption: caption,
  );
}
