import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gold_pos/layout/layout.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gold_pos/lock/lock.dart'; // Your LoginPage
import 'package:gold_pos/utils/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Animation controller for the loading indicator
  late AnimationController _controller;
  late Animation<double> _animation;

  // State variables for tracking loading process
  String _loadingMessage = "Loading...";

  @override
  void initState() {
    super.initState();

    // Setup the animation controller for the rotating logo
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Create a curved animation
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Make the animation repeat continuously
    _controller.repeat();

    // Start checking SharedPreferences
    _checkAuthStatus();
  }

  // Check SharedPreferences for authentication status
  Future<void> _checkAuthStatus() async {
    try {
      setState(() {
        _loadingMessage = "Checking login status...";
      });

      // Simulate a delay for better user experience
      await Future.delayed(const Duration(seconds: 2));

      // Check SharedPreferences for token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Also check if there's a valid user ID and other required data
      final userId = prefs.getString('userId');
      final userName = prefs.getString('userName');

      // Update UI based on token existence and validity
      if (token != null &&
          token.isNotEmpty &&
          userId != null &&
          userId.isNotEmpty) {
        setState(() {
          _loadingMessage = "Welcome back, ${userName ?? 'User'}!";
        });

        // Redirect to home screen after delay
        Timer(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Layout()),
          );
        });
      } else {
        setState(() {
          _loadingMessage = "Please login to continue";
        });

        // Redirect to login screen after delay
        Timer(const Duration(seconds: 6), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        });
      }
    } catch (e) {
      setState(() {
        _loadingMessage = "Error: Unable to check login status";
      });

      // Redirect to login page as fallback
      Timer(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 4, 1, 40),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with rotation animation
            RotationTransition(
              turns: _animation,
              child: ClipOval(
                child: Container(
                  color: Colors.white,
                  height: screenWidth > 800 ? 150 : 120,
                  width: screenWidth > 800 ? 150 : 120,
                  child: Image.asset(
                    'assets/images/jellery.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            SizedBox(height: 40),

            // App title
            Text(
              "emp Jewellerys",
              style: GoogleFonts.rubik(
                fontSize: screenWidth > 800 ? 32 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 20),

            // Loading indicator
            SizedBox(
              width: screenWidth > 800 ? 300 : 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
              ),
            ),

            SizedBox(height: 20),

            // Status message
            Text(
              _loadingMessage,
              style: GoogleFonts.outfit(
                fontSize: screenWidth > 800 ? 16 : 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
