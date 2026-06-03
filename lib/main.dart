
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/features/landing/presentation/landing_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MaterialApp(
      title: 'TableBot Controller',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        primaryColor: const Color(0xFF00BFFF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00BFFF),
          secondary: Color(0xFF00FF7F),
          error: Color(0xFFFF4500),
          surface: Color(0xFF1A1A1A),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(textTheme).apply(
          bodyColor: const Color(0xFFF5F5F5),
          displayColor: const Color(0xFFF5F5F5),
        ),
        useMaterial3: true,
      ),
      home: const LandingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
