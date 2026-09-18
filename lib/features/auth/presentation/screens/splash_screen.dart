import 'package:flutter/material.dart';
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.sports_cricket, size: 72), SizedBox(height: 16),
      Text('Cricket Scorer', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      SizedBox(height: 24), CircularProgressIndicator()])));
}
