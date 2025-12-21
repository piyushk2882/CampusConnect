import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

/// {@template app_text_divider}
/// A divider widget that displays text in the middle of a horizontal line.
/// {@endtemplate}
class AppTextDivider extends StatelessWidget {
  /// {@macro app_text_divider}
  const AppTextDivider({
    required this.text, super.key,
    this.height,
    this.indent,
    this.endIndent,
    this.color,
    this.textStyle,
    this.padding,
  });

  /// The text to display in the middle of the divider.
  final String text;

  /// The divider's height extent.
  final double? height;

  /// The amount of empty space to the leading edge of the divider.
  final double? indent;

  /// The amount of empty space to the trailing edge of the divider.
  final double? endIndent;

  /// The color to use when painting the line.
  final Color? color;

  /// The style to use for the text.
  final TextStyle? textStyle;

  /// The padding around the text.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = context.customReversedAdaptiveColor(
      dark: AppColors.white,
      light: AppColors.black,
    );

    return Row(
      children: [
        Expanded(
          child: Divider(
            height: height,
            indent: indent,
            color: color ?? effectiveColor,
          ),
        ),
        Padding(
          padding:
              padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            text,
            style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: Divider(
            height: height,
            endIndent: endIndent,
            color: color ?? effectiveColor,
          ),
        ),
      ],
    );
  }
}
