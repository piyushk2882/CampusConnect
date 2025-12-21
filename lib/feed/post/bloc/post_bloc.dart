import 'dart:async';

import 'package:campusconnect/feed/bloc/feed_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:insta_blocks/insta_blocks.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:user_repository/user_repository.dart';

part 'post_event.dart';
part 'post_state.dart';
part 'post_bloc.g.dart';

class PostBloc extends HydratedBloc<PostEvent, PostState> {
  PostBloc({
    required String postId,
    required PostsRepository postsRepository,
    required UserRepository userRepository,
  }) : _postId = postId,
       _postsRepository = postsRepository,
       _userRepository = userRepository,
       super(PostState.initial()) {
    on<PostLikesCountSubscriptionRequested>(
      _onPostLikesCountSubscriptionRequested,
    );
    on<PostIsLikedSubscriptionRequested>(_onPostIsLikedSubscriptionRequested);
    on<PostAuthorFollowingStatusSubscriptionRequested>(
      _onPostAuthorFollowingStatusSubscriptionRequested,
    );
    on<PostCommentsCountSubscriptionRequested>(
      _onPostCommentsCountSubscriptionRequested,
    );
    on<PostLikeRequested>(_onPostLikeRequested);
    on<PostAuthorFollowRequested>(_onPostAuthorFollowRequested);
    on<PostLikersInFollowingsFetchRequested>(
      _onPostLikersInFollowingsFetchRequested,
    );
    on<PostDeleteRequested>(_onPostDeleteRequested);
    on<PostUpdateRequested>(_onPostUpdateRequested);
    on<PostSaveRequested>(_onPostSaveRequested);
  }

  final String _postId;
  final PostsRepository _postsRepository;
  final UserRepository _userRepository;

  @override
  String get id => _postId;

  Future<void> _onPostLikesCountSubscriptionRequested(
    PostLikesCountSubscriptionRequested event,
    Emitter<PostState> emit,
  ) async {
    await emit.forEach(
      _postsRepository.likesOf(id: id),
      onData: (LikesCount) => state.copyWith(likes: LikesCount),
    );
  }

  Future<void> _onPostIsLikedSubscriptionRequested(
    PostIsLikedSubscriptionRequested event,
    Emitter<PostState> emit,
  ) async {
    await emit.forEach(
      _postsRepository.isLiked(id: id),
      onData: (isLiked) => state.copyWith(isLiked: isLiked),
      onError: (error, stackTrace) {
        addError(error, stackTrace);
        return state.copyWith(status: PostStatus.failure);
      },
    );
  }

  Future<void> _onPostAuthorFollowingStatusSubscriptionRequested(
    PostAuthorFollowingStatusSubscriptionRequested event,
    Emitter<PostState> emit,
  ) async {
    if (event.currentUserId == event.ownerId) {
      emit(state.copyWith(isOwner: true));
      return;
    }
    await emit.forEach(
      _userRepository.followingStatus(userId: event.ownerId),
      onData: (isFollowed) =>
          state.copyWith(isFollowed: isFollowed, isOwner: false),
      onError: (error, stackTrace) {
        addError(error, stackTrace);
        return state.copyWith(status: PostStatus.failure);
      },
    );
  }

  FutureOr<void> _onPostCommentsCountSubscriptionRequested(
    PostCommentsCountSubscriptionRequested event,
    Emitter<PostState> emit,
  ) async {
    await emit.forEach(
      _postsRepository.commentsAmountOf(postId: id),
      onData: (CommentsCount) => state.copyWith(commentsCount: CommentsCount),
    );
  }

  @override
  PostState? fromJson(Map<String, dynamic> json) => PostState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(PostState state) => state.toJson();

  FutureOr<void> _onPostLikeRequested(
    PostLikeRequested event,
    Emitter<PostState> emit,
  ) async {
    try {
      await _postsRepository.like(id: id);
    } catch (error, stackTrace) {
      addError(error, stackTrace);
    }
  }

  FutureOr<void> _onPostAuthorFollowRequested(
    PostAuthorFollowRequested event,
    Emitter<PostState> emit,
  ) async {
    emit(state.copyWith(status: PostStatus.loading));
    try {
      await _userRepository.follow(followToId: event.authorId);
      emit(state.copyWith(status: PostStatus.success));
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: PostStatus.failure));
    }
  }

  FutureOr<void> _onPostLikersInFollowingsFetchRequested(
    PostLikersInFollowingsFetchRequested event,
    Emitter<PostState> emit,
  ) async {
    try {
      final likersInFollowings = await _postsRepository
          .getPostLikersInFollowing(postId: id);
      emit(state.copyWith(likersInFollowings: likersInFollowings));
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: PostStatus.failure));
    }
  }

  FutureOr<void> _onPostDeleteRequested(
    PostDeleteRequested event,
    Emitter<PostState> emit,
  ) async {
    try {
      await _postsRepository.deletePost(id: id);
      emit(state.copyWith(status: PostStatus.success));
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: PostStatus.failure));
    }
  }

  FutureOr<void> _onPostUpdateRequested(
    PostUpdateRequested event,
    Emitter<PostState> emit,
  ) async {
    try {
      final post = await _postsRepository.updatePost(
        id: id,
        caption: event.caption,
      );

      if (post != null) {
        event.onPostUpdated?.call(post.toPostLargeBlock);
      }
      emit(state.copyWith(status: PostStatus.success));
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: PostStatus.failure));
    }
  }

  FutureOr<void> _onPostSaveRequested(
    PostSaveRequested event,
    Emitter<PostState> emit,
  ) async {
    try {
      final userId = _userRepository.currentUserId;
      if (userId == null) return;
      await _postsRepository.savePost(id: id, userId: userId);
      emit(state.copyWith(isSaved: !state.isSaved));
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(status: PostStatus.failure));
    }
  }
}
