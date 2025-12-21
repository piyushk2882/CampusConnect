// ignore_for_file: unused_field

import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/feed/bloc/feed_bloc.dart';
import 'package:campusconnect/feed/post/post.dart';
import 'package:campusconnect/feed/widgets/widgets.dart';
import 'package:campusconnect/l10n/l10n.dart';
import 'package:campusconnect/network_error/view/newtwork_error.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:insta_blocks/insta_blocks.dart';
import 'package:inview_notifier_list/inview_notifier_list.dart';

class FeedPage extends StatelessWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeedView();
  }
}

class FeedView extends StatefulWidget {
  const FeedView({super.key});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> with WidgetsBindingObserver {
  late ScrollController _nestedScrollController;
  late FeedPageController _feedPageController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<FeedBloc>().add(FeedPageRequested(page: 0));

    _nestedScrollController = ScrollController();
    _feedPageController = FeedPageController();

    _feedPageController.init(
      nestedScrollController: _nestedScrollController,
      context: context,
    );
  }

  bool _isDisposed = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isDisposed && mounted) {
      context.read<FeedBloc>().add(const FeedRefreshRequested());
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _nestedScrollController.dispose();
    // Note: _feedPageController is a singleton and should not be disposed here
    // to avoid affecting other parts of the app that use it.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: NestedScrollView(
        controller: _nestedScrollController,
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: FeedAppBar(
                innerBoxIsScrolled: innerBoxIsScrolled,
              ),
            ),
          ];
        },
        body: FeedBody(feedPageController: _feedPageController),
      ),
    );
  }
}

class FeedBody extends StatefulWidget {
  const FeedBody({
    required this.feedPageController,
    super.key,
  });

  final FeedPageController feedPageController;

  @override
  State<FeedBody> createState() => _FeedBodyState();
}

class _FeedBodyState extends State<FeedBody> {
  bool _hasTriggeredRecommended = false;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.adaptive(
      onRefresh: () async {
        setState(() => _hasTriggeredRecommended = false);
        await Future.microtask(
          () => context.read<FeedBloc>().add(FeedRefreshRequested()),
        );
        if (context.mounted) {
          widget.feedPageController.markAnimationAsUnseen();
        }
        widget.feedPageController.markAnimationAsUnseen();
      },
      child: InViewNotifierCustomScrollView(
        initialInViewIds: const ['0'],
        isInViewPortCondition: (deltaTop, deltaBottom, vpHeight) {
          return deltaTop < (0.5 * vpHeight) + 80.0 &&
              deltaBottom > (0.5 * vpHeight) - 80.0;
        },
        slivers: [
          BlocBuilder<FeedBloc, FeedState>(
            buildWhen: (previous, current) {
              if (previous.status == FeedStatus.populated &&
                  const ListEquality<InstaBlock>().equals(
                    previous.feed.feedPage.blocks,
                    current.feed.feedPage.blocks,
                  )) {
                return false;
              }
              if (previous.status == current.status) return false;
              return true;
            },
            builder: (context, state) {
              final feedPage = state.feed.feedPage;
              final hasMorePosts = feedPage.hasMore;
              final isFailure = state.status == FeedStatus.failure;
              return SliverList.builder(
                itemCount: feedPage.blocks.length,
                itemBuilder: (context, index) {
                  final block = feedPage.blocks[index];
                  return _buildBlock(
                    context: context,
                    index: index,
                    feedLength: feedPage.totalBlocks,
                    block: block,
                    feedPageController: widget.feedPageController,
                    hasMorePosts: hasMorePosts,
                    isFailure: isFailure,
                    hasRecommendedPosts: feedPage.hasRecommendedPosts,
                    hasMoreRecommended: feedPage.hasMoreRecommended,
                    hasTriggeredRecommended: _hasTriggeredRecommended,
                    onTriggerRecommended: () =>
                        setState(() => _hasTriggeredRecommended = true),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBlock({
    required BuildContext context,
    required int index,
    required int feedLength,
    required InstaBlock block,
    required FeedPageController feedPageController,
    required bool hasMorePosts,
    required bool isFailure,
    required bool hasRecommendedPosts,
    required bool hasMoreRecommended,
    required bool hasTriggeredRecommended,
    required VoidCallback onTriggerRecommended,
  }) {
    if (block is DividerHorizontalBlock) {
      return DividerBlock(feedPageController: feedPageController);
    }
    if (block is SectionHeaderBlock) {
      return switch (block.sectionType) {
        SectionHeaderBlockType.suggested => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                context.l10n.suggestedForYouText,
                style: context.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const AppDivider(),
          ],
        ),
      };
    }
    if (index + 1 == feedLength) {
      if (isFailure) {
        if (!hasMorePosts) return const SizedBox.shrink();
        return NetworkError(
          onRetry: () {
            context.read<FeedBloc>().add(const FeedPageRequested());
          },
        );
      } else if (hasMorePosts || (hasRecommendedPosts && hasMoreRecommended)) {
        return Padding(
          padding: EdgeInsets.only(top: feedLength == 0 ? AppSpacing.md : 0),
          child: FeedLoaderItem(
            key: ValueKey(index),
            onPresented: () {
              if (hasMorePosts) {
                context.read<FeedBloc>().add(const FeedPageRequested());
              } else if (hasRecommendedPosts &&
                  hasMoreRecommended &&
                  !hasTriggeredRecommended) {
                onTriggerRecommended();
                context.read<FeedBloc>().add(
                  const FeedRecommendedPostsPageRequested(),
                );
              }
            },
          ),
        );
      } else {
        return const SizedBox.shrink();
      }
    }

    if (block is PostSponsoredBlock) {
      return const SizedBox.shrink();
    }
    if (block is PostBlock) {
      return PostView(
        key: ValueKey(block.id),
        block: block,
        postIndex: index,
        withInViewNotifier: block.isReel,
      );
    }

    return Text('Unknown block type: ${block.type}');
  }
}
