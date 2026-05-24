import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DisasterSplatApp());
}

class DisasterSplatApp extends StatelessWidget {
  const DisasterSplatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neural Geolocated Disaster Splatting',
      debugShowCheckedModeBanner: false,
      
      // Gorgeous Dark Mode Material 3 Design
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        
        // Custom Curated Harmonious Dark Colors
        scaffoldBackgroundColor: const Color(0xFF0A0C16),
        primaryColor: const Color(0xFF6366F1), // Neon Indigo
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF10B981), // Emerald Success
          error: Color(0xFFEF4444), // Crimson danger
          surface: Color(0xFF121424),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onError: Colors.white,
        ),
        
        // Global Google Fonts style overrides (Outfit/Inter hierarchy)
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w700),
          headlineLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 18),
          bodyLarge: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.normal, fontSize: 14),
          bodyMedium: TextStyle(fontFamily: 'Outfit', fontSize: 13),
        ),
        
        // Customize dialogs & modals to match our premium aesthetic
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF131526),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: Colors.white10, width: 1),
          ),
        ),
        
        // Chip configurations
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          side: const BorderSide(color: Colors.white10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      
      home: const DashboardScreen(),
    );
  }
}
