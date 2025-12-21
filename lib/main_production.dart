import 'package:campusconnect/app/app.dart';
import 'package:campusconnect/bootstrap.dart';
import 'package:campusconnect/firebase_options_prod.dart';
import 'package:database_client/database_client.dart';
import 'package:env/env.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:search_repository/search_repository.dart';
import 'package:shared/src/config/app_flavor.dart';
import 'package:supabase_authentication_client/supabase_authentication_client.dart';
import 'package:token_storage/token_storage.dart';
import 'package:user_repository/user_repository.dart';

void main() {
  bootstrap(
    (powersyncRepository,FirebaseRemoteConfigRepository) async {
      const iOSClientId = 'dev-ios-client-id';
      const webClientId = 'dev-web-client-id';
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
      return App(
        user: await userRepository.user.first,
        userRepository: userRepository,
        postsRepository: postsRepository,
        searchRepository: searchRepository,
        firebaseRemoteConfigRepository: FirebaseRemoteConfigRepository,
      );
    },
    appFlavor: AppFlavor.production(),
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
