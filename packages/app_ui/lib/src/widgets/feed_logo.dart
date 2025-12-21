import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

class FeedLogo extends StatelessWidget {
  const FeedLogo({
    required this.fit,
    this.color,
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Assets.images.appbar.image(
      height: height ?? 125,
      width: width ?? 125,
      fit: fit,
      color: color ?? context.adaptiveColor,
    );
  }
}