import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black, // Or your app's primary color
      child: Center(
        child: Image.asset(
          'assets/Logo_animation.gif',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
