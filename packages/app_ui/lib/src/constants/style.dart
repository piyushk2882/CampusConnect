import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';

///6:20:54
OutlineInputBorder outlinedBorder({
  double borderRadius = defaultBorderRadius,
  BorderSide? borderSide,
}) => OutlineInputBorder(
  borderSide: borderSide ?? BorderSide.none,
  borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
);

//outline
