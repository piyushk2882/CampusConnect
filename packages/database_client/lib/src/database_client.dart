// ignore_for_file: avoid_bool_literals_in_conditional_expressions, avoid_print, public_member_api_docs, one_member_abstracts, lines_longer_than_80_chars, document_ignores, depend_on_referenced_packages, use_raw_strings, prefer_interpolation_to_compose_strings

import 'package:flutter/services.dart';
import 'package:googleapis/fcm/v1.dart' as fcm;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:powersync/powersync.dart' as psync;
import 'package:powersync_repository/powersync_repository.dart';
import 'package:shared/shared.dart';
import 'package:user_repository/user_repository.dart';

String toPgArray(List<String> list) =>
    '{' +
    list
        .map((e) => e.replaceAll('\\', '\\\\').replaceAll('"', '\\"'))
        .map((e) => '"$e"')
        .join(',') +
    '}';

abstract class UserBaseRepository {
  const UserBaseRepository();
  String? get currentUserId;

  Future<void> updateUser({
    String? fullName,
    String? email,
    String? userName,
    String? avatarUrl,
    String? pushToken,
  });

  Stream<User> profile({required String userId});
  Stream<int> followingCountOf({required String userId});
  Stream<int> followersCountOf({required String userId});
  Stream<bool> followingStatus({required String userId, String? followerId});
  Future<bool> isFollowed({
    required String followerId,
    required String userId,
  });
  Future<void> follow({required String followToId, String? followerId});
  Future<void> unfollow({required String unfollowId, String? unfollowerId});

  Future<void> removeFollower({required String id});

  Future<List<User>> getFollowings({required String userId});

  Stream<bool> isUserVerified({required String userId});

  Stream<List<User>> followers({required String userId});
}

abstract class SearchBaseRepository {
  const SearchBaseRepository();

  Future<List<User>> searchUsers({
    required int limit,
    required int offset,
    required String? query,
    String? userId,
    String? excludeUserIds,
  });
}

abstract class PostsBaseRepository {
  const PostsBaseRepository();
  Stream<List<Post>> postsOf({String? userId});
  Stream<int> postsAmountOf({required String userId});

  Future<Post?> createPost({
    required String id,
    required String caption,
    required String media,
  });

  Future<List<User>> getPostLikersInFollowing({
    required String postId,
    int limit = 3,
    int offset = 0,
  });
  Future<Post?> updatePost({required String id, String? caption});
  Future<String?> deletePost({required String id});

  Stream<List<Comment>> commentsOf({required String postId});

  Stream<List<Comment>> repliedCommentsOf({required String commentId});

  Future<void> createComment({
    required String content,
    required String postId,
    required String userId,
    String? repliedToCommentId,
  });

  Future<void> deleteComment({required String id});

  Future<List<Post>> getPage({
    required int offset,
    required int limit,
    bool onlyReels = false,
    bool onlyFollowed = false,
  });

  Stream<int> likesOf({
    required String id,
    bool post = true,
  });

  Stream<bool> isLiked({
    required String id,
    String? userId,
    bool post = true,
  });

  Stream<int> commentsAmountOf({required String postId});

  Future<void> like({
    required String id,
    bool post = true,
  });

  Future<void> savePost({required String id, required String userId});

  Stream<List<Post>> savedPosts({required String userId});

  Future<List<Post>> getRecommendedPosts({
    required int offset,
    required int limit,
  });
}

/// {@template database_client}
/// A Very Good Project created by Very Good CLI.
/// {@endtemplate}
abstract class DatabaseClient
    implements UserBaseRepository, PostsBaseRepository, SearchBaseRepository {
  /// {@macro database_client}
  const DatabaseClient();

  Future<void> createProject({
    required String userId,
    required String title,
    String? summary,
    String? githubLink,
    String? researchpaperLink,
    String? domain,
    String? branch,
    String? year,
    String? guide,
  });

  Future<List<Map<String, dynamic>>> getProjects();

  Future<void> submitProjectRating({
    required String projectId,
    required int rating,
  });

  Future<void> submitProjectRatingWithReview({
    required String projectId,
    required int rating,
    required String review,
  });

  Future<List<Map<String, dynamic>>> getProjectRatingsWithReviews(
    String projectId,
  );

  Future<double> getAverageProjectRating(String projectId);

  Future<int?> getUserProjectRating(String projectId);

  Future<void> pinProject({required String projectId});

  Future<void> unpinProject({required String projectId});

  Future<List<Map<String, dynamic>>> getPinnedProjects();

  Future<bool> isProjectPinned(String projectId);

  Future<List<Map<String, dynamic>>> getFaculties();

  // Club Hiring methods
  Future<void> createClubHiring({
    required String clubId,
    required List<String> roles,
    required List<String> classes,
  });

  Future<void> updateClubHiring({
    required String clubId,
    required List<String> roles,
    required List<String> classes,
  });

  Future<void> deleteClubHiring(String clubId);

  Stream<Map<String, dynamic>?> watchClubHiring(String clubId);

  // Club Applications methods
  Future<void> submitClubApplication({
    required String clubId,
    required String userId,
    required String studentName,
    required String class_,
    required String department,
    required String prn,
    required String phone,
    required String roleApplied,
    required String resumeUrl,
  });

  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
  });

  Future<void> sendApplicationNotification({
    required String userId,
    required String title,
    required String body,
  });

  Future<void> sendHiringNotification({
    required String clubId,
    required String clubName,
  });

  Stream<List<Map<String, dynamic>>> watchClubApplications(String clubId);

  Future<bool> isClubAdmin(String userId);
}

class PowerSyncDatabaseClient extends DatabaseClient {
  const PowerSyncDatabaseClient({
    required PowerSyncRepository powerSyncRepository,
  }) : _powerSyncRepository = powerSyncRepository;

  final PowerSyncRepository _powerSyncRepository;

  psync.PowerSyncDatabase get database => _powerSyncRepository.db();

  @override
  Future<void> createProject({
    required String userId,
    required String title,
    String? summary,
    String? githubLink,
    String? researchpaperLink,
    String? domain,
    String? branch,
    String? year,
    String? guide,
  }) async {
    final projectId = uuid.v4();
    print(
      r'createProject called with id: $id, userId: $userId, title: $title',
    );
    await _powerSyncRepository.db().execute(
      '''
      INSERT INTO projects (
        id, user_id, title, summary, github_link, researchpaper_link,
        domain, branch, year, guide
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        projectId,
        userId,
        title,
        summary,
        githubLink,
        researchpaperLink,
        domain,
        branch,
        year,
        guide,
      ],
    );
  }

  @override
  Future<void> submitProjectRating({
    required String projectId,
    required int rating,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    final existing = await _powerSyncRepository.db().getAll(
      '''
      SELECT id FROM ratings WHERE project_id = ? AND user_id = ?
      ''',
      [projectId, userId],
    );
    if (existing.isEmpty) {
      final ratingId = uuid.v4();
      await _powerSyncRepository.db().execute(
        '''
        INSERT INTO ratings (id, project_id, user_id, rating, created_at)
        VALUES (?, ?, ?, ?, ?)
        ''',
        [ratingId, projectId, userId, rating, DateTime.now().toIso8601String()],
      );
    } else {
      final ratingId = existing.first['id'] as String;
      await _powerSyncRepository.db().execute(
        '''
        UPDATE ratings SET rating = ?, created_at = ? WHERE id = ?
        ''',
        [rating, DateTime.now().toIso8601String(), ratingId],
      );
    }
  }

  @override
  Future<void> submitProjectRatingWithReview({
    required String projectId,
    required int rating,
    required String review,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    final existing = await _powerSyncRepository.db().getAll(
      '''
      SELECT id FROM ratings WHERE project_id = ? AND user_id = ?
      ''',
      [projectId, userId],
    );
    if (existing.isEmpty) {
      final ratingId = uuid.v4();
      await _powerSyncRepository.db().execute(
        '''
        INSERT INTO ratings (id, project_id, user_id, rating, review, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
        ''',
        [
          ratingId,
          projectId,
          userId,
          rating,
          review,
          DateTime.now().toIso8601String(),
        ],
      );
    } else {
      final ratingId = existing.first['id'] as String;
      await _powerSyncRepository.db().execute(
        '''
        UPDATE ratings SET rating = ?, review = ?, created_at = ? WHERE id = ?
        ''',
        [rating, review, DateTime.now().toIso8601String(), ratingId],
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getProjectRatingsWithReviews(
    String projectId,
  ) async {
    final result = await _powerSyncRepository.db().getAll(
      '''
      SELECT pr.rating, pr.review, pr.created_at, p.full_name, p.avatar_url
      FROM ratings pr
      JOIN profiles p ON pr.user_id = p.id
      WHERE pr.project_id = ?
      ORDER BY pr.created_at DESC
      ''',
      [projectId],
    );
    return result;
  }

  @override
  Future<double> getAverageProjectRating(String projectId) async {
    final result = await _powerSyncRepository.db().getAll(
      '''
      SELECT AVG(rating) as avg_rating FROM ratings WHERE project_id = ?
      ''',
      [projectId],
    );
    if (result.isEmpty || result.first['avg_rating'] == null) {
      return 0.0;
    }
    return (result.first['avg_rating'] as num).toDouble();
  }

  @override
  Future<int?> getUserProjectRating(String projectId) async {
    final userId = currentUserId;
    if (userId == null) {
      return null;
    }
    final result = await _powerSyncRepository.db().getAll(
      '''
      SELECT rating FROM ratings WHERE project_id = ? AND user_id = ?
      ''',
      [projectId, userId],
    );
    if (result.isEmpty) {
      return null;
    }
    return result.first['rating'] as int?;
  }

  @override
  String? get currentUserId =>
      _powerSyncRepository.supabase.auth.currentSession?.user.id;

  @override
  Future<void> updateUser({
    String? fullName,
    String? email,
    String? userName,
    String? avatarUrl,
    String? pushToken,
    String? password,
  }) => _powerSyncRepository.updateUser(
    email: email,
    password: password,
    data: {
      if (fullName != null) 'full_name': fullName,
      if (userName != null) 'username': userName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (pushToken != null) 'push_token': pushToken,
    },
  );

  @override
  Stream<User> profile({required String userId}) => _powerSyncRepository
      .db()
      .watch('''SELECT * FROM profiles WHERE id = ?''', parameters: [userId])
      .map(
        (event) => event.isEmpty ? User.anonymous : User.fromJson(event.first),
      );

  @override
  Stream<bool> isUserVerified({required String userId}) => _powerSyncRepository
      .db()
      .watch(
        '''SELECT is_verified FROM profiles WHERE id = ?''',
        parameters: [userId],
      )
      .map((event) {
        final isVerified = event.isEmpty
            ? false
            : (event.first['is_verified'] as int? ?? 0) == 1;
        print('Fetched is_verified for user $userId: $isVerified');
        return isVerified;
      });

  @override
  Stream<int> postsAmountOf({required String userId}) => _powerSyncRepository
      .db()
      .watch(
        '''SELECT COUNT(*) as posts_count FROM posts WHERE user_id = ?''',
        parameters: [userId],
      )
      .map(
        (event) => event.first['posts_count'] as int,
      );

  @override
  Stream<int> followersCountOf({required String userId}) => _powerSyncRepository
      .db()
      .watch(
        'SELECT COUNT(*) AS subscription_count FROM subscriptions '
        'WHERE subscribed_to_id = ?',
        parameters: [userId],
      )
      .map(
        (event) => event.first['subscription_count'] as int,
      );

  @override
  Stream<int> followingCountOf({required String userId}) => _powerSyncRepository
      .db()
      .watch(
        'SELECT COUNT(*) AS subscription_count FROM subscriptions '
        'WHERE subscriber_id = ?',
        parameters: [userId],
      )
      .map(
        (event) => event.first['subscription_count'] as int,
      );

  @override
  Stream<bool> followingStatus({required String userId, String? followerId}) {
    if (followerId == null && currentUserId == null) {
      return const Stream.empty();
    }
    return _powerSyncRepository
        .db()
        .watch(
          '''SELECT 1 FROM subscriptions WHERE subscriber_id = ? AND subscribed_to_id = ?''',
          parameters: [followerId ?? currentUserId, userId],
        )
        .map((event) => event.isNotEmpty);
  }

  @override
  Future<bool> isFollowed({
    required String userId,
    required String followerId,
  }) async {
    final result = await _powerSyncRepository.db().execute(
      '''
    SELECT 1 FROM subscriptions WHERE subscriber_id = ? AND subscribed_to_id = ?
    ''',
      [followerId ?? currentUserId, userId],
    );
    return result.isNotEmpty;
  }

  @override
  Future<void> follow({
    required String followToId,
    String? followerId,
  }) async {
    if (currentUserId == null) return;
    if (followToId == currentUserId) return;
    final exists = await isFollowed(
      followerId: followerId ?? currentUserId!,
      userId: followToId,
    );
    if (!exists) {
      await _powerSyncRepository.db().execute(
        '''
          INSERT INTO subscriptions(id, subscriber_id, subscribed_to_id)
            VALUES(uuid(), ?, ?)
      ''',
        [followerId ?? currentUserId!, followToId],
      );
      return;
    }
    await unfollow(
      unfollowId: followToId,
      unfollowerId: followerId ?? currentUserId!,
    );
  }

  @override
  Future<void> unfollow({
    required String unfollowId,
    String? unfollowerId,
  }) async {
    if (currentUserId == null) return;
    await _powerSyncRepository.db().execute(
      '''
          DELETE FROM subscriptions WHERE subscriber_id = ? AND subscribed_to_id = ?
      ''',
      [unfollowerId ?? currentUserId, unfollowId],
    );
  }

  @override
  Future<Post?> createPost({
    required String id,
    required String caption,
    required String media,
  }) async {
    if (currentUserId == null) return null;
    final result = await Future.wait([
      _powerSyncRepository.db().execute(
        '''
    INSERT INTO posts(id, user_id, caption, media, created_at)
    VALUES(?, ?, ?, ?, ?)
    RETURNING *
    ''',
        [
          id,
          currentUserId,
          caption,
          media,
          DateTime.timestamp().toIso8601String(),
        ],
      ),
      _powerSyncRepository.db().get(
        '''
SELECT * FROM profiles WHERE id = ?
''',
        [currentUserId],
      ),
    ]);
    if (result.isEmpty) return null;
    final row = Map<String, dynamic>.from((result.first as ResultSet).first);
    final author = User.fromJson(result.last as Row);
    return Post.fromJson(row).copyWith(author: author);
  }

  @override
  Future<List<User>> getFollowings({String? userId}) async {
    final followingsUserId = await _powerSyncRepository.db().getAll(
      'SELECT subscribed_to_id FROM subscriptions WHERE subscriber_id = ? ',
      [userId ?? currentUserId],
    );
    if (followingsUserId.isEmpty) return [];

    final followings = <User>[];
    for (final followingsUserId in followingsUserId) {
      final result = await _powerSyncRepository.db().execute(
        'SELECT * FROM profiles WHERE id = ?',
        [followingsUserId['subscribed_to_id']],
      );
      if (result.isEmpty) continue;
      final following = User.fromJson(result.first);
      followings.add(following);
    }
    return followings;
  }

  @override
  Stream<List<User>> followers({required String userId}) async* {
    final streamResult = _powerSyncRepository.db().watch(
      'SELECT subscriber_id FROM subscriptions WHERE subscribed_to_id = ? ',
      parameters: [userId],
    );
    await for (final result in streamResult) {
      final followers = <User>[];
      final followersFutures = await Future.wait(
        result
            .where((row) => row.isNotEmpty)
            .safeMap(
              (row) => _powerSyncRepository.db().getOptional(
                'SELECT * FROM profiles WHERE id = ?',
                [row['subscriber_id']],
              ),
            ),
      );
      for (final user in followersFutures) {
        if (user == null) continue;
        final follower = User.fromJson(user);
        followers.add(follower);
      }
      yield followers;
    }
  }

  @override
  Future<void> removeFollower({required String id}) async {
    if (currentUserId == null) return;
    await _powerSyncRepository.db().execute(
      '''
DELETE FROM subscriptions WHERE subscriber_id = ? AND subscribed_to_id = ?''',
      [id, currentUserId],
    );
  }

  @override
  Future<List<Post>> getPage({
    required int offset,
    required int limit,
    bool onlyReels = false,
    bool onlyFollowed = false,
  }) async {
    if (onlyReels) {
      final result = await _powerSyncRepository.db().execute(
        '''
SELECT
  posts.*,
  p.id as user_id,
  p.avatar_url as avatar_url,
  p.username as username
FROM
  posts
  inner join profiles p on posts.user_id = p.id
WHERE array_length(array(posts.media), 1) = 1
  AND posts.media.type = '__video_media__'
  ${onlyFollowed ? 'AND posts.user_id IN (SELECT subscribed_to_id FROM subscriptions WHERE subscriber_id = ?)' : ''}
LIMIT ? OFFSET ?
    ''',
        onlyFollowed ? [currentUserId, limit, offset] : [limit, offset],
      );

      final posts = <Post>[];

      for (final row in result) {
        final json = Map<String, dynamic>.from(row);
        final post = Post.fromJson(json);
        posts.add(post);
      }
      return posts;
    } else {
      final result = await _powerSyncRepository.db().execute(
        '''
SELECT
  posts.*,
  p.id as user_id,
  p.avatar_url as avatar_url,
  p.username as username
FROM
  posts
  inner join profiles p on posts.user_id = p.id
  ${onlyFollowed ? 'WHERE posts.user_id IN (SELECT subscribed_to_id FROM subscriptions WHERE subscriber_id = ?)' : ''}
ORDER BY posts.created_at DESC
LIMIT ? OFFSET ?
    ''',
        onlyFollowed ? [currentUserId, limit, offset] : [limit, offset],
      );

      final posts = <Post>[];

      for (final row in result) {
        final json = Map<String, dynamic>.from(row);
        final post = Post.fromJson(json);
        posts.add(post);
      }
      return posts;
    }
  }

  @override
  Stream<int> likesOf({required String id, bool post = true}) {
    final statement = post ? 'post_id' : 'comment_id';
    return _powerSyncRepository
        .db()
        .watch(
          '''
SELECT COUNT(*) AS total_likes FROM likes WHERE $statement = ? AND $statement IS NOT NULL ''',
          parameters: [id],
        )
        .map(
          (result) => result.safeMap((row) => row['total_likes']).first as int,
        );
  }

  @override
  Stream<bool> isLiked({required String id, String? userId, bool post = true}) {
    final statement = post ? 'post_id' : 'comment_id';
    return _powerSyncRepository
        .db()
        .watch(
          '''SELECT EXISTS (SELECT 1 FROM likes WHERE user_id = ? AND $statement = ? AND $statement IS NOT NULL) as is_liked''',
          parameters: [userId ?? currentUserId, id],
        )
        .map((event) => (event.first.values.first! as int).isTrue);
  }

  @override
  Future<List<User>> getPostLikersInFollowing({
    required String postId,
    int limit = 3,
    int offset = 0,
  }) async {
    final result = await _powerSyncRepository.db().getAll(
      '''
SELECT id, avatar_url, username, full_name
FROM profiles
WHERE id IN (
    SELECT l.user_id
    FROM likes l
    WHERE l.post_id = ?1
    AND EXISTS (
        SELECT *
        FROM subscriptions f
        WHERE f.subscribed_to_id = l.user_Id
        AND f.subscriber_id = ?2
    ) AND id <> ?2
)
LIMIT ?3 OFFSET ?4
''',
      [postId, currentUserId, limit, offset],
    );
    if (result.isEmpty) return [];
    return result.safeMap(User.fromJson).toList(growable: false);
  }

  @override
  Stream<int> commentsAmountOf({required String postId}) => _powerSyncRepository
      .db()
      .watch(
        '''
SELECT COUNT(*) AS comments_count FROM comments
WHERE post_id = ? 
''',
        parameters: [postId],
      )
      .map(
        (result) => result.map((row) => row['comments_count']).first as int,
      );

  @override
  Future<void> like({required String id, bool post = true}) async {
    if (currentUserId == null) return;
    final statement = post ? 'post_id' : 'comment_id';
    final exists = await _powerSyncRepository.db().execute(
      'SELECT 1 FROM likes '
      'WHERE user_id = ? AND $statement = ? AND $statement IS NOT NULL',
      [currentUserId, id],
    );
    if (exists.isEmpty) {
      await _powerSyncRepository.db().execute(
        '''
          INSERT INTO likes(user_id, $statement, id)
            VALUES(?, ?, uuid())
      ''',
        [currentUserId, id],
      );
      return;
    }
    await _powerSyncRepository.db().execute(
      '''
          DELETE FROM likes
          WHERE user_id = ? AND $statement = ? AND $statement IS NOT NULL
      ''',
      [currentUserId, id],
    );
  }

  @override
  Future<void> savePost({required String id, required String userId}) async {
    final exists = await _powerSyncRepository.db().execute(
      'SELECT 1 FROM savedposts WHERE user_id = ? AND post_id = ?',
      [userId, id],
    );
    if (exists.isEmpty) {
      await _powerSyncRepository.db().execute(
        '''
          INSERT INTO savedposts(user_id, post_id, id)
            VALUES(?, ?, uuid())
      ''',
        [userId, id],
      );
      return;
    }
    await _powerSyncRepository.db().execute(
      '''
          DELETE FROM savedposts
          WHERE user_id = ? AND post_id = ?
      ''',
      [userId, id],
    );
  }

  @override
  Stream<List<Post>> savedPosts({required String userId}) {
    return _powerSyncRepository
        .db()
        .watch(
          '''
SELECT
  posts.*,
  p.id as user_id,
  p.avatar_url as avatar_url,
  p.username as username,
  p.full_name as full_name
FROM
  posts
  INNER JOIN savedposts s ON posts.id = s.post_id
  LEFT JOIN profiles p ON posts.user_id = p.id
WHERE s.user_id = ?
ORDER BY posts.created_at DESC
      ''',
          parameters: [userId],
        )
        .map(
          (event) => event
              .safeMap((row) => Post.fromJson(Map<String, dynamic>.from(row)))
              .toList(growable: false),
        );
  }

  @override
  Future<String?> deletePost({required String id}) async {
    final result = await _powerSyncRepository.db().execute(
      'DELETE FROM posts WHERE id = ? RETURNING id',
      [id],
    );
    if (result.isEmpty) return null;
    return result.first['id'] as String;
  }

  @override
  Future<Post?> updatePost({required String id, String? caption}) async {
    final row = await _powerSyncRepository.db().execute(
      '''
UPDATE posts
SET
  caption = ?2,
  updated_at = ?3
WHERE id = ?1
RETURNING *
''',
      [id, caption, DateTime.timestamp().toIso8601String()],
    );
    if (row.isEmpty) return null;
    final json = Map<String, dynamic>.from(row.first);
    return Post.fromJson(json);
  }

  @override
  Stream<List<Post>> postsOf({String? userId}) {
    if (currentUserId == null && userId == null) return const Stream.empty();
    return _powerSyncRepository
        .db()
        .watch(
          '''
SELECT
  posts.*,
  p.id as user_id,
  p.avatar_url as avatar_url,
  p.username as username,
  p.full_name as full_name
FROM
  posts
  left join profiles p on posts.user_id = p.id 
WHERE user_id = ?1
ORDER BY created_at DESC
      ''',
          parameters: [userId],
        )
        .map(
          (event) => event
              .safeMap((row) => Post.fromJson(Map<String, dynamic>.from(row)))
              .toList(growable: false),
        );
  }

  @override
  Stream<List<Comment>> commentsOf({required String postId}) =>
      _powerSyncRepository
          .db()
          .watch(
            '''
SELECT 
  c1.*,
  p.avatar_url as avatar_url,
  p.username as username,
  p.full_name as full_name,
  COUNT(c2.id) AS replies
FROM 
  comments c1
  INNER JOIN
    profiles p ON p.id = c1.user_id
  LEFT JOIN
    comments c2 ON c1.id = c2.replied_to_comment_id
WHERE
  c1.post_id = ? AND c1.replied_to_comment_id IS NULL
GROUP BY
    c1.id, p.avatar_url, p.username, p.full_name
ORDER BY created_at ASC
''',
            parameters: [postId],
          )
          .map(
            (result) => result.safeMap(Comment.fromRow).toList(growable: false),
          );

  @override
  Future<void> createComment({
    required String content,
    required String postId,
    required String userId,
    String? repliedToCommentId,
  }) => _powerSyncRepository.db().execute(
    '''
INSERT INTO
  comments(id, post_id, user_id, content, created_at, replied_to_comment_id)
VALUES(uuid(), ?, ?, ?, ?, ?)
''',
    [
      postId,
      userId,
      content,
      DateTime.timestamp().toIso8601String(),
      repliedToCommentId,
    ],
  );

  @override
  Stream<List<Comment>> repliedCommentsOf({required String commentId}) =>
      _powerSyncRepository
          .db()
          .watch(
            '''
SELECT 
  c1.*,
  p.avatar_url as avatar_url,
  p.username as username,
  p.full_name as full_name
FROM 
  comments c1
  INNER JOIN
    profiles p ON p.id = c1.user_id
WHERE
  c1.replied_to_comment_id = ? 
GROUP BY
    c1.id, p.avatar_url, p.username, p.full_name
ORDER BY created_at ASC
''',
            parameters: [commentId],
          )
          .map(
            (result) => result.safeMap(Comment.fromRow).toList(growable: false),
          );

  @override
  Future<void> deleteComment({required String id}) =>
      _powerSyncRepository.db().execute(
        '''
DELETE FROM comments
WHERE id = ?
''',
        [id],
      );

  @override
  Future<List<User>> searchUsers({
    required int limit,
    required int offset,
    required String? query,
    String? userId,
    String? excludeUserIds,
  }) async {
    if (query == null || query.trim().isEmpty) return <User>[];
    query = query.removeSpecialCharacters();
    final excludeUserIdsStatement = excludeUserIds == null
        ? ''
        : 'AND id NOT IN ($excludeUserIds)';

    final result = await _powerSyncRepository.db().getAll(
      '''
SELECT id, avatar_url, full_name, username
  FROM profiles
WHERE (LOWER(username) LIKE LOWER('%$query%') OR LOWER(full_name) LIKE LOWER('%$query%'))
  AND id <> ?1 $excludeUserIdsStatement
LIMIT ?2 OFFSET ?3
''',
      [currentUserId, limit, offset],
    );

    return result.safeMap(User.fromJson).toList(growable: false);
  }

  @override
  Future<List<Map<String, dynamic>>> getProjects() async {
    final result = await _powerSyncRepository.db().getAll(
      'SELECT * FROM projects',
    );
    return result;
  }

  @override
  Future<void> pinProject({required String projectId}) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    final existing = await _powerSyncRepository.db().getAll(
      '''
      SELECT id FROM pins WHERE project_id = ? AND user_id = ?
      ''',
      [projectId, userId],
    );
    if (existing.isEmpty) {
      final pinId = uuid.v4();
      await _powerSyncRepository.db().execute(
        '''
        INSERT INTO pins (id, project_id, user_id)
        VALUES (?, ?, ?)
        ''',
        [
          pinId,
          projectId,
          userId,
        ],
      );
    }
  }

  @override
  Future<void> unpinProject({required String projectId}) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }
    await _powerSyncRepository.db().execute(
      '''
      DELETE FROM pins WHERE project_id = ? AND user_id = ?
      ''',
      [projectId, userId],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getPinnedProjects() async {
    final userId = currentUserId;
    if (userId == null) {
      return [];
    }
    final result = await _powerSyncRepository.db().getAll(
      '''
      SELECT p.* FROM projects p
      INNER JOIN pins pin ON p.id = pin.project_id
      WHERE pin.user_id = ?
      ''',
      [userId],
    );
    return result;
  }

  @override
  Future<bool> isProjectPinned(String projectId) async {
    final userId = currentUserId;
    if (userId == null) {
      return false;
    }
    final result = await _powerSyncRepository.db().getAll(
      '''
      SELECT 1 FROM pins WHERE project_id = ? AND user_id = ?
      ''',
      [projectId, userId],
    );
    return result.isNotEmpty;
  }

  @override
  Future<List<Map<String, dynamic>>> getFaculties() async {
    print('Loading faculties from database...');
    final result = await _powerSyncRepository.db().getAll(
      'SELECT * FROM faculties',
    );
    print('Loaded ${result.length} faculties from database.');
    return result;
  }

  @override
  Future<void> createClubHiring({
    required String clubId,
    required List<String> roles,
    required List<String> classes,
  }) async {
    final hiringId = uuid.v4();
    await _powerSyncRepository.db().execute(
      '''
      INSERT INTO club_hiring (id, club_id, roles, classes)
      VALUES (?, ?, ?, ?)
      ''',
      [hiringId, clubId, toPgArray(roles), toPgArray(classes)],
    );
  }

  @override
  Future<void> updateClubHiring({
    required String clubId,
    required List<String> roles,
    required List<String> classes,
  }) async {
    await _powerSyncRepository.db().execute(
      '''
      UPDATE club_hiring SET roles = ?, classes = ? WHERE club_id = ?
      ''',
      [toPgArray(roles), toPgArray(classes), clubId],
    );
  }

  @override
  Future<void> deleteClubHiring(String clubId) async {
    await _powerSyncRepository.db().execute(
      'DELETE FROM club_hiring WHERE club_id = ?',
      [clubId],
    );
  }

  @override
  Stream<Map<String, dynamic>?> watchClubHiring(String clubId) {
    print('watchClubHiring called for clubId: $clubId');
    return _powerSyncRepository
        .db()
        .watch(
          'SELECT * FROM club_hiring WHERE club_id = ?',
          parameters: [clubId],
        )
        .map((rows) {
          print('watchClubHiring for clubId $clubId: received rows: $rows');
          final result = rows.isNotEmpty ? rows.first : null;
          if (result != null) {
            print(
              'Successfully retrieved hiring data for clubId $clubId: $result',
            );
          } else {
            print('No hiring data found for clubId $clubId');
          }
          return result;
        });
  }

  @override
  Future<void> submitClubApplication({
    required String clubId,
    required String userId,
    required String studentName,
    required String class_,
    required String department,
    required String prn,
    required String phone,
    required String roleApplied,
    required String resumeUrl,
  }) async {
    final applicationId = uuid.v4();
    await _powerSyncRepository.db().execute(
      '''
      INSERT INTO club_applications (id, club_id, user_id, student_name, class, department, prn, phone, role_applied, resume_url, status)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        applicationId,
        clubId,
        userId,
        studentName,
        class_,
        department,
        prn,
        phone,
        roleApplied,
        resumeUrl,
        'pending',
      ],
    );
  }

  @override
  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
  }) async {
    await _powerSyncRepository.db().execute(
      '''
      UPDATE club_applications SET status = ? WHERE id = ?
      ''',
      [status, applicationId],
    );
  }

  @override
  Future<void> sendApplicationNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      // Get user's push token
      final userResult = await _powerSyncRepository.db().execute(
        'SELECT push_token FROM profiles WHERE id = ?',
        [userId],
      );

      if (userResult.isEmpty) {
        print('No push token found for user $userId');
        return;
      }

      final pushToken = userResult.first['push_token'] as String?;
      if (pushToken == null || pushToken.isEmpty) {
        print('Push token is null or empty for user $userId');
        return;
      }

      // Use Firebase Cloud Messaging API (V1)
      final serviceAccountJson = await rootBundle.loadString(
        'assets/campusconnect-dev-9473c-firebase-adminsdk-fbsvc-2d676927c9.json',
      );
      final accountCredentials = auth.ServiceAccountCredentials.fromJson(
        serviceAccountJson,
      );
      final client = await auth.clientViaServiceAccount(accountCredentials, [
        'https://www.googleapis.com/auth/cloud-platform',
      ]);
      final fcmApi = fcm.FirebaseCloudMessagingApi(client);

      final message = fcm.Message(
        token: pushToken,
        notification: fcm.Notification(
          title: title,
          body: body,
        ),
        data: {
          'type': 'application_status',
          'user_id': userId,
        },
      );

      final sendMessageRequest = fcm.SendMessageRequest(message: message);
      await fcmApi.projects.messages.send(
        sendMessageRequest,
        'projects/campusconnect-dev-9473c',
      );

      print('Push notification sent successfully to user $userId');
      client.close();
    } catch (e) {
      print('Error sending push notification to user $userId: $e');
    }
  }

  @override
  Future<void> sendHiringNotification({
    required String clubId,
    required String clubName,
  }) async {
    try {
      // Get all users with push tokens
      final usersResult = await _powerSyncRepository.db().execute(
        "SELECT push_token FROM profiles WHERE push_token IS NOT NULL AND push_token != ''",
      );

      final pushTokens = usersResult
          .map((row) => row['push_token'] as String)
          .toList();

      if (pushTokens.isEmpty) {
        print('No push tokens found in database');
        return;
      }

      print(
        'Found ${pushTokens.length} push tokens, sending hiring notifications...',
      );

      // Use Firebase Cloud Messaging API (V1)
      final serviceAccountJson = await rootBundle.loadString(
        'assets/campusconnect-dev-9473c-firebase-adminsdk-fbsvc-2d676927c9.json',
      );
      final accountCredentials = auth.ServiceAccountCredentials.fromJson(
        serviceAccountJson,
      );
      final client = await auth.clientViaServiceAccount(accountCredentials, [
        'https://www.googleapis.com/auth/cloud-platform',
      ]);
      final fcmApi = fcm.FirebaseCloudMessagingApi(client);

      // Send notification to each token
      for (final token in pushTokens) {
        final message = fcm.Message(
          token: token,
          notification: fcm.Notification(
            title: 'Hiring Update',
            body: '$clubName has started recruiting. Apply now!!',
          ),
          data: {
            'type': 'hiring',
            'club_id': clubId,
            'club_name': clubName,
          },
        );

        final sendMessageRequest = fcm.SendMessageRequest(message: message);
        try {
          await fcmApi.projects.messages.send(
            sendMessageRequest,
            'projects/campusconnect-dev-9473c',
          );
          print(
            'Push notification sent successfully to token: ${token.substring(0, 10)}...',
          );
        } catch (e) {
          print(
            'Error sending push notification to token: ${token.substring(0, 10)}...: $e',
          );
        }
      }

      client.close();
    } catch (e) {
      print('Error sending hiring notification: $e');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchClubApplications(String clubId) {
    return _powerSyncRepository
        .db()
        .watch(
          'SELECT * FROM club_applications WHERE club_id = ? ORDER BY created_at DESC',
          parameters: [clubId],
        )
        .map((rows) => rows);
  }

  @override
  Future<bool> isClubAdmin(String userId) async {
    final result = await _powerSyncRepository.db().getAll(
      '''
      SELECT 1 FROM clubs WHERE club_email = (SELECT email FROM profiles WHERE id = ?)
      ''',
      [userId],
    );
    return result.isNotEmpty;
  }

  @override
  Future<List<Post>> getRecommendedPosts({
    required int offset,
    required int limit,
  }) async {
    final result = await _powerSyncRepository.db().execute(
      '''
SELECT
  posts.*,
  p.id as user_id,
  p.avatar_url as avatar_url,
  p.username as username
FROM
  posts
  inner join profiles p on posts.user_id = p.id
WHERE posts.user_id NOT IN (
  SELECT subscribed_to_id FROM subscriptions WHERE subscriber_id = ?
)
AND posts.user_id != ?
ORDER BY posts.created_at DESC
LIMIT ? OFFSET ?
    ''',
      [currentUserId, currentUserId, limit, offset],
    );

    final posts = <Post>[];

    for (final row in result) {
      final json = Map<String, dynamic>.from(row);
      final post = Post.fromJson(json);
      posts.add(post);
    }
    return posts;
  }
}
