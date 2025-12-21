// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/app/view/app.dart';
import 'package:campusconnect/feed/feed.dart';
import 'package:campusconnect/home/home.dart';
import 'package:campusconnect/l10n/l10n.dart';
import 'package:campusconnect_blocks_ui/src/media_carousel_settings.dart';
import 'package:campusconnect_blocks_ui/src/widgets/media_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:posts_repository/posts_repository.dart';
import 'package:powersync_repository/powersync_repository.dart';
import 'package:shared/shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_repository/user_repository.dart';

class UserProfileCreatePost extends StatefulWidget {
  const UserProfileCreatePost({
    this.canPop = true,
    this.imagePickerKey,
    this.pickVideo = false,
    this.onPopInvoked,
    this.onBackButtonTap,
    super.key,
  });

  final bool canPop;
  final Key? imagePickerKey;
  final bool pickVideo;
  final VoidCallback? onBackButtonTap;
  final VoidCallback? onPopInvoked;

  @override
  State<UserProfileCreatePost> createState() => _UserProfileCreatePostState();
}

class _UserProfileCreatePostState extends State<UserProfileCreatePost> {
  @override
  void initState() {
    super.initState();
    // Verification check moved to router redirect
  }

  @override
  Widget build(BuildContext context) {
    final pickerSource = widget.pickVideo
        ? PickerSource.video
        : PickerSource.both;
    return PopScope(
      canPop: widget.canPop,
      onPopInvoked: (didPop) {
        if (didPop) return;
        widget.onPopInvoked?.call();
      },
      child: PickImage().customMediaPicker(
        key: widget.imagePickerKey,
        context: context,
        source: ImageSource.both,
        pickerSource: pickerSource,
        multiSelection: !widget.pickVideo,
        onMediaPicked: (details) async {
          context.pushNamed(
            'publish_post',
            extra: CreatePostProps(
              details: details,
              pickVideo: widget.pickVideo,
            ),
          );
        },
        onBackButtonTap: widget.onBackButtonTap != null
            ? () => widget.onBackButtonTap?.call()
            : null,
      ),
    );
  }
}

class CreatePostProps {
  const CreatePostProps({
    required this.details,
    this.pickVideo = false,
    this.context,
  });

  final SelectedImagesDetails details;
  final bool pickVideo;
  final BuildContext? context;
}

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({required this.props, super.key});

  final CreatePostProps props;

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  late TextEditingController _captionController;
  late List<Media> _media;

  List<SelectedByte> get selectedFiles => widget.props.details.selectedFiles;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController();
    _media = selectedFiles
        .map(
          (e) => e.isThatImage
              ? MemoryImageMedia(bytes: e.selectedByte, id: uuid.v4())
              : MemoryVideoMedia(id: uuid.v4(), file: e.selectedFile),
        )
        .toList();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _onShareTap(String caption) async {
    // Check verification before proceeding
    final isVerified = await context
        .read<UserRepository>()
        .isCurrentUserVerified()
        .first;
    if (!isVerified && mounted) {
      context.pushNamed('verification_required');
      return;
    }

    void goHome() {
      if (!widget.props.pickVideo) {
        HomeProvider().animateToPage(1);
        final feedPageController = FeedPageController();
        feedPageController.ScrollToTop();
      }
    }

    try {
      toggleLoadingIndeterminate();
      final postId = uuid.v4();
      await FeedPageController().processPostMedia(
        selectedFiles: selectedFiles,
        postId: postId,
        caption: caption,
        pickVideo: widget.props.pickVideo,
      );
      Future<void> uploadPost({
        required List<Map<String, dynamic>> media,
      }) async => context.read<PostsRepository>().createPost(
        id: postId,
        caption: caption,
        media: jsonEncode(media),
      );
      if (widget.props.pickVideo) {
        try {
          late final postId = uuid.v4();
          late final Storage = Supabase.instance.client.storage.from('posts');
          late final mediaPath = '$postId/video_0';

          final selectedFile = selectedFiles.first;
          final firstFrame = await VideoPlus.getVideoThumbnail(
            selectedFile.selectedFile,
          );
          final blurHash = firstFrame == null
              ? ''
              : await BlurHashPlus.blurHashEncode(firstFrame);
          final compressedVideo =
              (await VideoPlus.compressVideo(
                selectedFile.selectedFile,
              ))?.file ??
              selectedFile.selectedFile;
          final compressedVideoBytes = await PickImage().imageBytes(
            file: compressedVideo,
          );
          final attachment = AttachmentFile(
            size: compressedVideoBytes.length,
            bytes: compressedVideoBytes,
            path: compressedVideo.path,
          );
          await Storage.uploadBinary(
            mediaPath,
            attachment.bytes!,
            fileOptions: FileOptions(
              contentType: attachment.mediaType!.mimeType,
              cacheControl: '9000000',
            ),
          );
          final mediaUrl = Storage.getPublicUrl(mediaPath);
          String? firstFrameUrl;
          if (firstFrame != null) {
            late final firstFramePath = '$postId/video_first_frame_0';
            await Storage.uploadBinary(
              firstFramePath,
              firstFrame,
              fileOptions: FileOptions(
                contentType: attachment.mediaType!.mimeType,
                cacheControl: '9000000',
              ),
            );
            firstFrameUrl = Storage.getPublicUrl(firstFramePath);
          }
          final media = [
            {
              'media_id': uuid.v4(),
              'url': mediaUrl,
              'type': VideoMedia.identifier,
              'blur_hash': blurHash,
              'first_frame_url': firstFrameUrl,
            },
          ];
          await uploadPost(media: media);
        } catch (error, stackTrace) {
          logE(
            'Failed to create reel',
            error: error,
            stackTrace: stackTrace,
          );
          if (mounted) {
            openSnackBar(
              const SnackbarMessage.error(
                title: 'Failed to get video thumbnail',
              ),
            );
          }
          return;
        }
      } else {
        final storage = Supabase.instance.client.storage.from('posts');
        final media = <Map<String, dynamic>>[];
        for (var i = 0; i < selectedFiles.length; i++) {
          late final selectedByte = selectedFiles[i].selectedByte;
          late final selectedFile = selectedFiles[i].selectedFile;
          late final isVideo = selectedFile.isVideo;
          String blurHash;
          Uint8List? convertedBytes;
          if (isVideo) {
            convertedBytes = await VideoPlus.getVideoThumbnail(
              selectedFile,
            );
            blurHash = convertedBytes == null
                ? ''
                : await BlurHashPlus.blurHashEncode(convertedBytes);
          } else {
            blurHash = await BlurHashPlus.blurHashEncode(
              selectedByte,
            );
          }
          late final mediaExtension = selectedFile.path
              .split('.')
              .last
              .toLowerCase();
          late final mediaPath =
              '$postId/${!isVideo ? 'image_$i' : 'video_$i'}';
          Uint8List bytes;
          if (isVideo) {
            try {
              final compressedVideo = await VideoPlus.compressVideo(
                selectedFile,
              );
              bytes = await PickImage().imageBytes(
                file: compressedVideo!.file!,
              );
            } catch (error, stackTrace) {
              logE(
                'Failed to compress video',
                error: error,
                stackTrace: stackTrace,
              );
              bytes = selectedByte;
              if (mounted) {
                openSnackBar(
                  const SnackbarMessage.error(
                    title: 'Failed to compress video',
                  ),
                );
              }
              return;
            }
          } else {
            bytes = selectedByte;
          }
          await storage.uploadBinary(
            mediaPath,
            bytes,
            fileOptions: FileOptions(
              contentType: '${!isVideo ? 'image' : 'video'}/$mediaExtension',
              cacheControl: '9000000',
            ),
          );
          final mediaUrl = storage.getPublicUrl(mediaPath);
          String? firstFrameUrl;
          if (convertedBytes != null) {
            late final firstFramePath = '$postId/video_first_frame_$i';
            await storage.uploadBinary(
              firstFramePath,
              convertedBytes,
              fileOptions: FileOptions(
                contentType: 'video/$mediaExtension',
                cacheControl: '9000000',
              ),
            );
            firstFrameUrl = storage.getPublicUrl(firstFramePath);
          }
          final mediaType = isVideo
              ? VideoMedia.identifier
              : ImageMedia.identifier;
          if (isVideo) {
            media.add({
              'media_id': uuid.v4(),
              'url': mediaUrl,
              'type': mediaType,
              'blur_hash': blurHash,
              'first_frame_url': firstFrameUrl,
            });
          } else {
            media.add({
              'media_id': uuid.v4(),
              'url': mediaUrl,
              'type': mediaType,
              'blur_hash': blurHash,
            });
          }
        }
        await uploadPost(media: media);
      }
      goHome();
      if (mounted) {
        toggleLoadingIndeterminate(enable: false);
        openSnackBar(
          const SnackbarMessage.success(
            title: 'Post created successfully',
          ),
        );
      }
    } catch (error, stackTrace) {
      if (mounted) {
        toggleLoadingIndeterminate(enable: false);
        openSnackBar(
          const SnackbarMessage.error(title: 'Failed to create post'),
        );
      }
      logE('Faild to create post', error: error, stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      releaseFocus: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: false,
        title: Text(context.l10n.newPostText),
      ),
      bottomNavigationBar: PublishPostButton(
        onShareTap: () => _onShareTap(_captionController.text),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Gap.v(AppSpacing.sm),
            // Full-width media carousel display for all selected images/videos
            if (_media.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: double.infinity,
                  height: 300, // Fixed height for the carousel
                  child: MediaCarousel(
                    media: _media,
                    settings: MediaCarouselSettings.create(
                      aspectRatio: 1,
                      viewportFraction: 1,
                      enableInfiniteScroll: false,
                      withInViewNotifier: false,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Gap.v(AppSpacing.sm),
            ],
            CaptionInputField(
              captionController: _captionController,
              caption: _captionController.text.trim(),
              onSubmitted: _onShareTap,
            ),
          ],
        ),
      ),
    );
  }
}

class PublishPostButton extends StatelessWidget {
  const PublishPostButton({required this.onShareTap, super.key});

  final VoidCallback onShareTap;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      elevation: 0,
      color: context.reversedAdaptiveColor,
      padding: EdgeInsets.zero,
      height: 90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Tappable.faded(
              onTap: onShareTap,
              borderRadius: BorderRadius.circular(6),
              backgroundColor: AppColors.blue,
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.sm,
              ),
              child: Align(
                child: Text(
                  context.l10n.sharePostText,
                  style: context.labelLarge,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CaptionInputField extends StatefulWidget {
  const CaptionInputField({
    required this.captionController,
    required this.caption,
    required this.onSubmitted,
    super.key,
  });

  final TextEditingController captionController;
  final String caption;
  final ValueSetter<String> onSubmitted;

  @override
  State<CaptionInputField> createState() => _CaptionInputFieldState();
}

class _CaptionInputFieldState extends State<CaptionInputField> {
  late String _initialCaption;
  @override
  void initState() {
    super.initState();
    _initialCaption = widget.caption;
  }

  @override
  void didUpdateWidget(covariant CaptionInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.caption != _initialCaption) {
      setState(() => _initialCaption = widget.caption);
    }
  }

  String _effectiveValue(String? value) =>
      value ?? widget.captionController.text.trim();

  bool _equals(String? value) => _initialCaption == _effectiveValue(value);

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      border: InputBorder.none,
      textController: widget.captionController,
      contentPadding: EdgeInsets.zero,
      textInputType: TextInputType.text,
      textInputAction: TextInputAction.newline,
      textCapitalization: TextCapitalization.sentences,
      hintText: context.l10n.writeCaptionText,
    );
  }
}
