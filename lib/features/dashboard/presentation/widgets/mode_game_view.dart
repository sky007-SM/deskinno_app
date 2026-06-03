
import 'package:flutter/material.dart';

class GameView extends StatelessWidget {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Game Mode Active',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}
