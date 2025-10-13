import 'package:flutter/material.dart';
import 'package:gold_pos/layout/layout.dart';
import 'package:gold_pos/lock/lock.dart';
import 'package:gold_pos/splash/welcome.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:device_preview/device_preview.dart';
import 'customer/customer_transaction.dart';

void main() {
  // Ensure initialized
  WidgetsFlutterBinding.ensureInitialized();
  TransactionService.initializeAuth();
  runApp(DevicePreview(enabled: true, builder: (context) => const MyApp()));
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
        '/home': (context) => Layout(),
        '/dashboard': (context) => Layout(initialIndex: 0),
        '/customer': (context) => Layout(initialIndex: 1),
        '/shareholder': (context) => Layout(initialIndex: 2),
        '/agent': (context) => Layout(initialIndex: 3),
        '/subagent': (context) => Layout(initialIndex: 4),

        '/customer/all': (context) => Layout(initialIndex: 1, customerTab: 0),
        '/customer/transactions':
            (context) => Layout(initialIndex: 1, customerTab: 1),
        '/customer/payments':
            (context) => Layout(initialIndex: 1, customerTab: 2),
      },
    );
  }
}
