// ignore_for_file: unused_local_variable, avoid_print, lines_longer_than_80_chars, use_build_context_synchronously, document_ignores

import 'dart:math';

import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/app/bloc/app_bloc.dart';
import 'package:campusconnect/l10n/l10n.dart';
import 'package:campusconnect/user_profile/bloc/user_profile_bloc.dart';
import 'package:campusconnect/user_profile/widgets/user_profile_header.dart';

import 'package:campusconnect_blocks_ui/campusconnect_blocks_ui.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:insta_blocks/insta_blocks.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:shared/shared.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:user_repository/user_repository.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({
    required this.userId,
    super.key,
  });

  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          UserProfileBloc(
              userRepository: context.read<UserRepository>(),
              postsRepository: context.read<PostsRepository>(),
              userId: userId,
            )
            ..add(UserProfileSubscriptionRequested())
            ..add(
              UserProfilePostsCountSubscriptionRequested(),
            )
            ..add(
              UserProfileFollowingsCountSubscriptionRequested(),
            )
            ..add(
              UserProfileFollowersCountSubscriptionRequested(),
            ),
      child: UserProfileView(
        userId: userId,
      ),
    );
  }
}

class UserProfileView extends StatefulWidget {
  const UserProfileView({required this.userId, super.key});

  final String userId;

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  late ScrollController _nestedScrollController;
  @override
  void initState() {
    _nestedScrollController = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    _nestedScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((UserProfileBloc bloc) => bloc.state.user);
    return AppScaffold(
      body: NestedScrollView(
        controller: _nestedScrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                context,
              ),
              sliver: MultiSliver(
                children: [
                  const UserProfileAppBar(),
                  if (!user.isAnonymous) ...[
                    UserProfileHeader(
                      userId: widget.userId,
                    ),
                  ],
                  SliverToBoxAdapter(
                    child: const Gap.v(AppSpacing.md),
                  ),
                ],
              ),
            ),
          ];
        },
        body: const PostsPage(),
      ),
    );
  }
}

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage>
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
          stream: context.read<UserProfileBloc>().userPosts(),
          comparator: const ListEquality<PostBlock>().equals,
          builder: (context, blocks) {
            if (blocks.isEmpty) {
              return const EmptyPosts();
            }
            return SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: blocks.length,
              itemBuilder: (context, index) {
                final block = blocks[index];
                final multiMedia = block.media.length > 1;

                return Tappable(
                  onTap: () => context.pushNamed(
                    'user_posts',
                    queryParameters: {
                      'user_id': block.author.id,
                      'index': index.toString(),
                    },
                  ),
                  child: PostSmall(
                    key: ValueKey(block.id),
                    pinned: false,
                    isReel: block.isReel,
                    multiMedia: multiMedia,
                    mediaUrl: block.firstMediaUrl!,
                    imageThumbnailBuilder: (_, url) => PostSmallImage(url: url),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class PostSmallImage extends StatelessWidget {
  const PostSmallImage({required this.url, super.key});

  final String url;

  @override
  Widget build(BuildContext context) {
    /// AppSpacing.xxs is the padding of the image.
    final screenWidth = (context.screenWidth - AppSpacing.xxs) / 3;
    final pixelRatio = context.devicePixelRatio;

    final size = min((screenWidth * pixelRatio) ~/ 1, 1920);
    return ImageAttachmentThumbnail(
      resizeHeight: size,
      resizeWidth: size,
      image: Attachment(imageUrl: url),
      fit: BoxFit.cover,
    );
  }
}

class UserProfileAppBar extends StatelessWidget {
  const UserProfileAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isOwner = context.select((UserProfileBloc bloc) => bloc.isOwner);
    final user = context.select((UserProfileBloc b) => b.state.user);
    return SliverPadding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      sliver: SliverAppBar(
        centerTitle: false,
        pinned: !ModalRoute.of(context)!.isFirst,
        floating: !ModalRoute.of(context)!.isFirst,
        title: Row(
          children: [
            Flexible(
              flex: 12,
              child: Text(
                '${user.displayUsername} ',
                style: context.titleLarge?.copyWith(
                  fontWeight: AppFontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (user.isVerified)
              Flexible(
                child: Assets.icons.verifiedUser.svg(
                  width: AppSize.iconSizeSmall,
                  height: AppSize.iconSizeSmall,
                ),
              ),
          ],
        ),
        actions: [
          if (!isOwner)
            const UserProfileActions()
          else ...[
            const UserProfileAddMediaButton(),
            if (ModalRoute.of(context)?.isFirst ?? false) ...const [
              Gap.h(AppSpacing.md),
              UserProfileSettingsButton(),
            ],
          ],
        ],
      ),
    );
  }
}

class UserProfileActions extends StatelessWidget {
  const UserProfileActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Tappable.faded(
      onTap: () {},
      child: Icon(Icons.adaptive.more_outlined, size: AppSize.iconSize),
    );
  }
}

class UserProfileAddMediaButton extends StatelessWidget {
  const UserProfileAddMediaButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    print('UserProfileAddMediaButton: Building button');
    return StreamBuilder<bool>(
      stream: context.read<UserRepository>().isCurrentUserVerified(),
      builder: (context, snapshot) {
        print(
          'UserProfileAddMediaButton: StreamBuilder snapshot - hasData: ${snapshot.hasData}, data: ${snapshot.data}, error: ${snapshot.error}',
        );
        final isVerified = snapshot.data ?? false;
        print('UserProfileAddMediaButton: isVerified = $isVerified');

        if (!isVerified) {
          print(
            'UserProfileAddMediaButton: Hiding button because user is not verified',
          );
          return const SizedBox.shrink();
        }

        print(
          'UserProfileAddMediaButton: Showing button because user is verified',
        );
        return Tappable(
          onTap: () => context
              .showListOptionsModal(
                title: l10n.createText,
                options: createMediaModalOptions(
                  reelLabel: l10n.reelText,
                  postLabel: l10n.postText,
                  goTo: (route, {extra}) =>
                      context.pushNamed(route, extra: extra),
                ),
              )
              .then((option) {
                if (option == null) return;
                option.onTap(context);
              }),
          child: const Icon(
            Icons.add_box_outlined,
            size: AppSize.iconSize,
          ),
        );
      },
    );
  }
}

class UserProfileSettingsButton extends StatelessWidget {
  const UserProfileSettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Tappable.faded(
      onTap: () async {
        final option = await context.showListOptionsModal(
          options: [
            ModalOption(child: const LogoutModalOption()),
          ],
        );
        if (option != null) {
          option.onTap(context);
        }
      },
      child: Assets.icons.setting.svg(
        height: AppSize.iconSize,
        width: AppSize.iconSize,
        colorFilter: ColorFilter.mode(
          context.adaptiveColor,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

class LogoutModalOption extends StatelessWidget {
  const LogoutModalOption({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Tappable.faded(
      onTap: () => context.confirmAction(
        fn: () {
          context.pop();
          context.read<AppBloc>().add(const AppLogoutRequested());
        },
        title: context.l10n.logOutText,
        content: context.l10n.logOutConfirmationText,
        noText: context.l10n.cancelText,
        yesText: context.l10n.logOutText,
      ),
      child: ListTile(
        title: Text(
          context.l10n.logOutText,
          style: context.bodyLarge?.apply(color: AppColors.red),
        ),
        leading: const Icon(Icons.logout, color: AppColors.red),
      ),
    );
  }
}
