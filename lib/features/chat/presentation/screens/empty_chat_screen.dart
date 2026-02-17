import 'package:flutter/material.dart';

class EmptyChatScreen extends StatelessWidget {
  const EmptyChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Select a conversation to start'),
      ),
    );
  }
}
