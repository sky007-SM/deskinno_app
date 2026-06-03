
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/features/landing/presentation/landing_page.dart';

void main() {
  // Ensure that widget binding is initialized for services.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TableBot Controller',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.grey,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.grey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const LandingPage(),
    );
  }
}
