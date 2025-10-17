import 'package:flutter/material.dart';
import 'package:gold_pos/utils/diamond_indicator.dart';

// Define your primary color (replace with your actual color)
const Color kPrimaryColor = Colors.blue; // Change to your actual primary color

// Your DiamondIndicator widget (replace with your actual implementation)

class TestLoadingDialog extends StatefulWidget {
  @override
  _TestLoadingDialogState createState() => _TestLoadingDialogState();
}

class _TestLoadingDialogState extends State<TestLoadingDialog> {
  // Method 1: Simple test button
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(16), //
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Container(
            padding: EdgeInsets.all(24),
            width:
                MediaQuery.of(context).size.width < 600
                    ? double.infinity
                    : (MediaQuery.of(context).size.width < 1000)
                    ? 450
                    : 500,
            height:
                MediaQuery.of(context).size.width < 600
                    ? null
                    : (MediaQuery.of(context).size.width < 1000)
                    ? 200
                    : 250,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Enhanced diamond indicator section
                Container(
                  padding: EdgeInsets.all(16),
                  child: DiamondIndicator(color: kPrimaryColor, size: 10),
                ),
                SizedBox(height: 20),
                Text(
                  'Creating Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Setting up your customer profile...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );

    // Auto dismiss after 3 seconds for testing
    Future.delayed(Duration(seconds: 3), () {
      Navigator.of(context).pop();
    });
  }

  // Method 2: Simulate real account creation process
  Future<void> _simulateAccountCreation() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.grey.shade50],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Enhanced diamond indicator section
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kPrimaryColor.withOpacity(0.1),
                    border: Border.all(
                      color: kPrimaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: DiamondIndicator(
                    color: kPrimaryColor,
                    size: 9, // Slightly larger for better visibility
                  ),
                ),

                SizedBox(height: 20),

                // Title
                Text(
                  'Creating Account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),

                SizedBox(height: 8),

                // Enhanced message
                Text(
                  'Setting up your customer profile...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 20),

                // Progress indicator
                LinearProgressIndicator(
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                  minHeight: 3,
                ),
              ],
            ),
          ),
        );
      },
    );

    // Simulate API call delay
    await Future.delayed(Duration(seconds: 2));

    // Close dialog
    Navigator.of(context).pop();

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Account created successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Loading Dialog'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Method 1: Quick test
            ElevatedButton(
              onPressed: _showLoadingDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text('Show Loading Dialog (3s)'),
            ),

            SizedBox(height: 20),

            // Method 2: Realistic simulation
            ElevatedButton(
              onPressed: _simulateAccountCreation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text('Simulate Account Creation'),
            ),

            SizedBox(height: 40),

            Text(
              'Testing Tips:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Test on different screen sizes'),
                  Text('• Check animation smoothness'),
                  Text('• Verify colors match your theme'),
                  Text('• Test with different text lengths'),
                  Text('• Check accessibility (contrast, sizing)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Main app to run the test
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loading Dialog Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TestLoadingDialog(),
      debugShowCheckedModeBanner: false,
    );
  }
}

void main() {
  runApp(MyApp());
}
