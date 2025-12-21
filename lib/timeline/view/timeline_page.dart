import 'dart:math';

import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/feed/post/video/video.dart';
import 'package:campusconnect/l10n/l10n.dart';
import 'package:campusconnect/search/view/search_page.dart';
import 'package:campusconnect/timeline/bloc/timeline_bloc.dart';
import 'package:campusconnect_blocks_ui/campusconnect_blocks_ui.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:insta_blocks/insta_blocks.dart';
import 'package:inview_notifier_list/inview_notifier_list.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:shared/shared.dart';
import 'package:video_player/video_player.dart';

class TimelinePage extends StatelessWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TimelineBloc(
        postsRepository: context.read<PostsRepository>(),
      )..add(const TimelinePageRequested()),
      child: const TimelineView(),
    );
  }
}

class TimelineView extends StatelessWidget {
  const TimelineView({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.go('/feed');
        return false;
      },
      child: AppScaffold(
        releaseFocus: true,
        body: RefreshIndicator.adaptive(
          onRefresh: () async =>
              context.read<TimelineBloc>().add(const TimelineRefreshRequested()),
          child: InViewNotifierCustomScrollView(
            initialInViewIds: const ['2', '5'],
            isInViewPortCondition: (deltaTop, deltaBottom, vpHeight) =>
                deltaTop < (0.5 * vpHeight) + 220.0 &&
                deltaBottom > (0.5 * vpHeight) - 220.0,
            slivers: [
              const SliverAppBar(
                title: SearchInputField(
                  active: true,
                  readOnly: true,
                ),
                floating: true,
                toolbarHeight: 64,
              ),
              BlocBuilder<TimelineBloc, TimelineState>(
                buildWhen: (previous, current) {
                  if (previous.status == TimelineStatus.populated &&
                      const ListEquality<InstaBlock>().equals(
                        previous.timeline.blocks,
                        current.timeline.blocks,
                      )) {
                    return false;
                  }
                  if (previous.status != current.status) return true;

                  return true;
                },
                builder: (context, state) {
                  if (state.status == TimelineStatus.failure) {
                    return const TimelineError();
                  }
                  if (state.status == TimelineStatus.populated) {
                    final imageBlocks = <PostBlock>[];
                    final videoBlocks = <PostBlock>[];

                    for (final block in state.timeline.blocks.cast<PostBlock>()) {
                      final isImage = block.hasBothMediaTypes || !block.isReel;
                      if (isImage) {
                        imageBlocks.add(block);
                      } else {
                        videoBlocks.add(block);
                      }
                    }

                    final blocksLength = imageBlocks.length + videoBlocks.length;

                    return TimelineGridView(
                      imageBlocks: imageBlocks,
                      videoBlocks: videoBlocks,
                      blocksLength: blocksLength,
                    );
                  } else {
                    return const TimelineLoading();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TimelineGridView extends StatefulWidget {
  const TimelineGridView({
    required this.imageBlocks,
    required this.videoBlocks,
    required this.blocksLength,
    super.key,
  });

  final List<PostBlock> imageBlocks;
  final List<PostBlock> videoBlocks;
  final int blocksLength;

  @override
  State<TimelineGridView> createState() => _TimelineGridViewState();
}

class _TimelineGridViewState extends State<TimelineGridView> {
  late final List<PostBlock> orderedBlocks;

  @override
  void initState() {
    super.initState();
    orderedBlocks = _generateOrderedBlocks();
  }

  List<PostBlock> _generateOrderedBlocks() {
    final result = <PostBlock>[];
    var videoIndex = 0;
    var imageIndex = 0;
    for (var i = 0; i < widget.blocksLength; i++) {
      var displayVideo = false;

      if (i == 2) {
        displayVideo = true;
      } else if (i % 5 == 0 && i != 0) {
        displayVideo = !displayVideo;
      } else if (i % 11 == 0 && i != 0) {
        displayVideo = true;
      }

      if (displayVideo && videoIndex < widget.videoBlocks.length) {
        result.add(widget.videoBlocks[videoIndex++]);
      } else if (imageIndex < widget.imageBlocks.length) {
        result.add(widget.imageBlocks[imageIndex++]);
      } else if (videoIndex < widget.videoBlocks.length) {
        result.add(widget.videoBlocks[videoIndex++]);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final orderedBlocks = _generateOrderedBlocks();
    return SliverGrid.builder(
      gridDelegate: SliverQuiltedGridDelegate(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        repeatPattern: QuiltedGridRepeatPattern.inverted,
        pattern: const [
          QuiltedGridTile(1, 1),
          QuiltedGridTile(1, 1),
          QuiltedGridTile(2, 1),
          QuiltedGridTile(1, 1),
          QuiltedGridTile(1, 1),
        ],
      ),
      itemCount: orderedBlocks.length,
      itemBuilder: (context, index) {
        final block = orderedBlocks[index];
        final multiMedia = block.media.length > 1;
        return GestureDetector(
          onTap: () => context.pushNamed(
            'post_detail',
            pathParameters: {'post_id': block.id},
            extra: {
              'blocks': orderedBlocks,
              'initialIndex': index,
            },
          ),
          child: PostSmall(
  pinned: false,
  isReel: block.isReel,
  multiMedia: multiMedia,
  mediaUrl: block.firstMediaUrl ?? '', // safe fallback
  imageThumbnailBuilder: (_, url) {
    if (block.isReel) {
      // Reel case
      if (block.firstMedia == null || block.firstMedia!.url.isEmpty) {
        // No video available → fallback
        return const Center(
          child: Icon(Icons.videocam_off, size: 40, color: Colors.grey),
        );
      }

      return VideoPlayerInViewNotifierWidget(
        type: VideoPlayerType.timeline,
        id: '$index',
        checkIsInView: true,
        builder: (context, shouldPlay, child) {
          return InlineVideo(
            videoSettings: VideoSettings.build(
              videoUrl: block.firstMedia!.url,
              shouldPlay: shouldPlay,
              withSound: false,
              shouldExpand: true,
              blurHash: block.firstMedia!.blurHash,
              withSoundButton: false,
              withPlayerController: false,
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
              initDelay: 250,
            ),
          );
        },
      );
    } else {
      // Normal image post
      return TimelinePostImage(url: url ?? block.firstMediaUrl ?? '');
    }
  },
)

        );
      },
    );
  }
}

class TimelinePostImage extends StatelessWidget {
  const TimelinePostImage({required this.url, super.key});

  final String url;

  @override
  Widget build(BuildContext context) {
    /// AppSpacing.xxs is the padding of the image.
    final screenWidth = (context.screenWidth - AppSpacing.xxs) / 3;
    final pixelRatio = context.devicePixelRatio;

    final size = min((screenWidth * pixelRatio) ~/ 1, 1920);

    return ImageAttachmentThumbnail(
      resizeHeight: size,
      image: Attachment(imageUrl: url),
      fit: BoxFit.cover,
    );
  }
}

class TimelineLoading extends StatelessWidget {
  const TimelineLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      gridDelegate: SliverQuiltedGridDelegate(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        repeatPattern: QuiltedGridRepeatPattern.inverted,
        pattern: [
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(2, 1),
          const QuiltedGridTile(1, 1),
          const QuiltedGridTile(1, 1),
        ],
      ),
      itemCount: 20,
      itemBuilder: (_, _) => const ShimmerPlaceholder(),
    );
  }
}

class TimelineError extends StatelessWidget {
  const TimelineError({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            context.l10n.somethingWentWrongText,
            style: context.headlineSmall,
          ),
          FittedBox(
            child: Tappable.faded(
              onTap: () => context.read<TimelineBloc>().add(
                const TimelinePageRequested(),
              ),
              throttle: true,
              throttleDuration: 880.ms,
              borderRadius: BorderRadius.circular(22),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: context.adaptiveColor),
                ),
                child: Align(
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.refresh),
                      Text(
                        context.l10n.refreshText,
                        style: context.labelLarge,
                      ),
                    ].spacerBetween(width: AppSpacing.md),
                  ),
                ),
              ),
            ),
          ),
        ].spacerBetween(height: AppSpacing.sm),
      ),
    );
  }
}
