// Import the flutter widgets package to use TextSpan and other widgets
// Note: You might need to adjust the import path above to match your project structure.

import 'package:campusconnect/app/app.dart';
import 'package:campusconnect/bootstrap.dart';
import 'package:campusconnect/firebase_options_dev.dart';
import 'package:campusconnect_blocks_ui/campusconnect_blocks_ui.dart';
import 'package:database_client/database_client.dart';
import 'package:env/env.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:provider/provider.dart';
import 'package:search_repository/search_repository.dart';
import 'package:shared/src/config/app_flavor.dart';
import 'package:supabase_authentication_client/supabase_authentication_client.dart';
import 'package:token_storage/token_storage.dart';
import 'package:user_repository/user_repository.dart';

void main() {
  bootstrap(
    (powersyncRepository, FirebaseRemoteConfigRepository) async {
      // --- Initialize BlockSettings right here at the start ---
      BlockSettings().init(
        postDelegate: PostTextDelegate(
          likedByText: (count, name, onTap) => TextSpan(text: '$count likes'),
          cancelText: 'Cancel',
          editText: 'Edit',
          deleteText: 'Delete',
          visitSponsoredInstagramProfileText: 'Visit Profile',
          noPostsText: 'No Posts Yet',
          sponsoredPostText: 'Sponsored',
          likesCountText: (count) => '$count likes',
          likesCountShortText: (count) => '$count',
          deletePostText: 'Delete Post',
          deletePostConfirmationText: 'Are you sure?',
          notShowAgainText: "Don't Show Again",
          blockPostAuthorText: 'Block Author',
          blockAuthorText: 'Block',
          blockAuthorConfirmationText: 'Are you sure you want to block this user?',
          blockText: 'Block',
        ),
        followDelegate: const FollowTextDelegate(
          followText: 'Follow',
          followingText: 'Following',
        ),
        commentDelegate: CommentTextDelegate(
          seeAllCommentsText: (count) => 'See all $count comments',
          replyText: 'Reply',
        ),
      );
      // --- End of Initialization ---

      const iOSClientId =
          '870400612293-4aj90sshuiskgsuocbhbb9mp44fipuit.apps.googleusercontent.com';
      const webClientId =
          '870400612293-1nkj15s0dflggfo7n8ob6ridd9ogv66t.apps.googleusercontent.com';
      final tokenstorage = InMemoryTokenStorage();
      final googleSignIn = GoogleSignIn(
        clientId: iOSClientId,
        serverClientId: webClientId,
      );
      final supabaseAuthenticationClient = SupabaseAuthenticationClient(
        powerSyncRepository: powersyncRepository,
        tokenStorage: tokenstorage,
        googleSignIn: googleSignIn,
      );

      final powerSyncDatabaseClient = PowerSyncDatabaseClient(
        powerSyncRepository: powersyncRepository,
      );

      final userRepository = UserRepository(
        databaseClient: powerSyncDatabaseClient,
        authenticationClient: supabaseAuthenticationClient,
      );
      final postsRepository = PostsRepository(
        databaseClient: powerSyncDatabaseClient,
      );
      final searchRepository = SearchRepository(
        databaseClient: powerSyncDatabaseClient,
      );

      

      return Provider<PowerSyncDatabaseClient>.value(
        value: powerSyncDatabaseClient,
        child: App(
          user: await userRepository.user.first,
          userRepository: userRepository,
          postsRepository: postsRepository,
          searchRepository: searchRepository,
          firebaseRemoteConfigRepository: FirebaseRemoteConfigRepository,
        ),
      );
    },
    appFlavor: AppFlavor.development(),
    options: DefaultFirebaseOptions.currentPlatform,
    env: (Env env) {
      switch (env) {
        case Env.supabaseUrl:
          return 'https://dev.supabase.url';
        case Env.powerSyncUrl:
          return 'https://dev.powersync.url';
        case Env.iOSClientId:
          return 'dev-ios-client-id';
        case Env.webClientId:
          return 'dev-web-client-id';
        case Env.supabaseAnonKey:
          return 'dev-supabase-anon-key';
      }
    },
  );
}
