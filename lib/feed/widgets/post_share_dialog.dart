import 'package:app_ui/app_ui.dart';
import 'package:campusconnect/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:insta_blocks/insta_blocks.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PostShareDialog extends StatelessWidget {
  const PostShareDialog({
    required this.postId,
    required this.author,
    super.key,
  });

  final String postId;
  final PostAuthor author;

  String get _postUrl => 'https://campusconnect.com/posts/$postId';

  String get _shareText => 'Check out this post by ${author.username}: $_postUrl';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Material(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.sharePostText,
              style: context.headlineSmall,
            ),
            const Gap.v(AppSpacing.lg),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text('Copy Link'),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: _postUrl));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Link copied!')),
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: Text('Share to Apps'),
              onTap: () async {
                await Share.share(_shareText);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: Text('Share to WhatsApp'),
              onTap: () async {
                final whatsappUrl = 'whatsapp://send?text=${Uri.encodeComponent(_shareText)}';
                if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
                  await launchUrl(Uri.parse(whatsappUrl));
                } else {
                  // Fallback to general share if WhatsApp not available
                  await Share.share(_shareText);
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
