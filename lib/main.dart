import 'package:flutter/material.dart';
import 'package:gold_pos/dashboard.dart';
import 'package:gold_pos/lock/lock.dart';
import 'package:gold_pos/shareholder/shareholder_page.dart';
import 'package:gold_pos/splash/welcome.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  // Ensure initialized
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emp Jewellerys',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      // Start with the splash screen
      home: SplashScreen(),
      // Define routes but don't set initialRoute (we're using home instead)
      routes: {
        '/login': (context) => LoginPage(),
        '/home': (context) => DashboardScreen(),
        '/dashboard':
            (context) =>
                DashboardScreen(initialIndex: 0), // Explicit dashboard page
        '/customer':
            (context) => DashboardScreen(initialIndex: 1), // Customer page
        '/shareholder':
            (context) =>
                DashboardScreen(initialIndex: 2), // Shareholder page (index 2)
        '/agent': (context) => DashboardScreen(initialIndex: 3), // Agent page
        '/subagent': (context) => DashboardScreen(initialIndex: 4),
      },
    );
  }
}
