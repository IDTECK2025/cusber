import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gold_pos/api.dart';
import 'package:gold_pos/layout/layout.dart';
import 'package:gold_pos/utils/colors.dart';
import 'package:gold_pos/utils/diamond_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/home': (context) => Layout(),
      },
    );
  }
}

// Response models
class LoginResponse {
  final String? message;
  final String token;
  final UserModel user;

  LoginResponse({this.message, required this.token, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'],
      token: json['token'],
      user: UserModel.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'message': message, 'token': token, 'user': user.toJson()};
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final int balance;
  final List<LedgerEntry> ledger;
  final String? phone;
  final String? customerId;
  final DateFormat? createdDate;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.balance,
    this.ledger = const [],
    this.phone,
    this.customerId,
    this.createdDate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      balance:
          (json['balance'] is int)
              ? json['balance']
              : (json['balance'] != null
                  ? int.tryParse(json['balance'].toString()) ?? 0
                  : 0),
      ledger:
          (json['ledger'] as List<dynamic>?)
              ?.map((e) => LedgerEntry.fromJson(e))
              .toList() ??
          [],
      phone: json['phone'],
      customerId: json['customerId'],
      createdDate: json['createdDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'balance': balance,
      'ledger': ledger.map((e) => e.toJson()).toList(),
      'phone': phone,
      'customerId': customerId,
      'createdDate': createdDate,
    };
  }
}

class LedgerEntry {
  final int amount;
  final String note;
  final String? payment; // Make payment nullable
  final String createdAt;

  LedgerEntry({
    required this.amount,
    required this.note,
    this.payment, // No longer required
    required this.createdAt,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      amount:
          (json['amount'] is int)
              ? json['amount']
              : (json['amount'] != null
                  ? int.tryParse(json['amount'].toString()) ?? 0
                  : 0),
      note: json['note'] ?? '',
      payment: json['payment'],
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'note': note,
      'payment': payment, // This can be null
      'createdAt': createdAt,
    };
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(); // Changed back to phone
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyLoggedIn();
  }

  // Check if user is already logged in
  Future<void> _checkIfAlreadyLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      // Already logged in, navigate to home screen
      Future.delayed(Duration.zero, () {
        Navigator.pushReplacementNamed(context, '/home');
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Handle login with API - Updated to use phone instead of email
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print(
        'Attempting login with phone: ${_phoneController.text.trim()}',
      ); // Debug log

      // API call to login endpoint with timeout
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'phone': _phoneController.text.trim(), // Changed to phone
              'password': _passwordController.text,
            }),
          )
          .timeout(
            Duration(seconds: 30), // 30 second timeout
            onTimeout: () {
              throw Exception('Connection timeout. Please try again.');
            },
          );

      print('Response status code: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        try {
          // Parse response
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          final loginResponse = LoginResponse.fromJson(responseData);

          // Save data to shared preferences
          await _saveToSharedPreferences(loginResponse);

          // Navigate to home screen
          Navigator.pushReplacementNamed(context, '/home');
        } catch (parseError) {
          print('JSON parsing error: $parseError');
          setState(() {
            _errorMessage = 'Invalid response format from server.';
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage =
              'Invalid phone number or password. Please try again.'; // Updated message
        });
      } else if (response.statusCode == 422) {
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          setState(() {
            _errorMessage =
                errorData['message'] ??
                'Validation error. Please check your input.';
          });
        } catch (e) {
          setState(() {
            _errorMessage = 'Validation error. Please check your input.';
          });
        }
      } else if (response.statusCode >= 500) {
        setState(() {
          _errorMessage = 'Server error. Please try again later.';
        });
      } else {
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          setState(() {
            _errorMessage =
                errorData['message'] ?? 'Login failed. Please try again.';
          });
        } catch (e) {
          setState(() {
            _errorMessage =
                'Login failed with status code: ${response.statusCode}';
          });
        }
      }
    } on TimeoutException catch (e) {
      print('Timeout error: $e');
      setState(() {
        _errorMessage =
            'Connection timeout. Please check your internet and try again.';
      });
    } on SocketException catch (e) {
      print('Socket error: $e');
      setState(() {
        _errorMessage = 'No internet connection. Please check your network.';
      });
    } on HttpException catch (e) {
      print('HTTP error: $e');
      setState(() {
        _errorMessage = 'Server connection failed. Please try again.';
      });
    } on FormatException catch (e) {
      print('Format error: $e');
      setState(() {
        _errorMessage = 'Invalid server response format.';
      });
    } catch (e) {
      print('General error: $e');
      setState(() {
        _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save login response to shared preferences
  Future<void> _saveToSharedPreferences(LoginResponse loginResponse) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('token', loginResponse.token);
    await prefs.setString('userId', loginResponse.user.id);
    await prefs.setString('userName', loginResponse.user.name);
    await prefs.setString('userEmail', loginResponse.user.email);
    await prefs.setString('userRole', loginResponse.user.role);
    await prefs.setInt('userBalance', loginResponse.user.balance);

    if (loginResponse.user.createdDate != null) {
      await prefs.setString(
        'createdDate',
        loginResponse.user.createdDate!.pattern ?? '',
      );
    }

    if (loginResponse.user.phone != null) {
      await prefs.setString('userPhone', loginResponse.user.phone!);
    }
    if (loginResponse.user.customerId != null) {
      await prefs.setString('userCustomerId', loginResponse.user.customerId!);
    }

    await prefs.setString('loginResponse', jsonEncode(loginResponse.toJson()));
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Calculate responsive sizes
    double horizontalPadding = screenWidth * 0.05; // 5% of screen width
    double imageSize = screenHeight * 0.45;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 4, 1, 40),
      body: Column(
        children: [
          // Marquee Banner at the top
          Container(
            color: const Color.fromARGB(6, 6, 11, 32),
            height: screenHeight * 0.06,
            width: double.infinity,
            child: Marquee(
              text:
                  '•   emp Jewellerys    •    emp Jewellerys    •    emp Jewellerys   ',
              style: GoogleFonts.museoModerno(
                fontWeight: FontWeight.w600,
                fontSize: screenWidth < 1200 ? 16 : 18,
                color: const Color.fromARGB(255, 228, 207, 207),
              ),
              scrollAxis: Axis.horizontal,
              blankSpace: 10.0,
              velocity: 40.0,
              pauseAfterRound: Duration(seconds: 1),
              startPadding: 10.0,
              accelerationDuration: Duration(seconds: 1),
              accelerationCurve: Curves.linear,
              decelerationDuration: Duration(milliseconds: 500),
              decelerationCurve: Curves.easeOut,
            ),
          ),

          // Main Login UI - Responsive Layout
          Expanded(
            child:
                screenWidth > 800
                    ? _buildDesktopLayout(
                      screenWidth,
                      screenHeight,
                      imageSize,
                      horizontalPadding,
                    )
                    : _buildMobileLayout(screenWidth, screenHeight),
          ),
        ],
      ),
    );
  }

  // Desktop Layout with side-by-side design
  Widget _buildDesktopLayout(
    double screenWidth,
    double screenHeight,
    double imageSize,
    double horizontalPadding,
  ) {
    return Row(
      children: [
        // Left Side - Image
        Container(
          width: screenWidth * 0.5,
          padding: EdgeInsets.only(left: horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipOval(
                child: Container(
                  color: Colors.white,
                  height: imageSize,
                  width: imageSize,
                  child: Image.asset(
                    'assets/images/jellery.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Right Side - Login Form
        Container(
          width: screenWidth * 0.5,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding * 1.5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Login",
                style: GoogleFonts.rubik(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Welcome back to  emp Jewellerys",
                style: GoogleFonts.outfit(fontSize: 16, color: Colors.white70),
              ),
              SizedBox(height: 40),
              _buildLoginForm(screenWidth > 1200 ? 400 : 350),
            ],
          ),
        ),
      ],
    );
  }

  // Mobile Layout with stacked design
  Widget _buildMobileLayout(double screenWidth, double screenHeight) {
    double compactImageSize = screenWidth * 0.3;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: screenHeight * 0.05),
            // Image at the top
            ClipOval(
              child: Container(
                color: Colors.white,
                height: compactImageSize,
                width: compactImageSize,
                child: Image.asset(
                  'assets/images/jellery.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 30),
            Text(
              "Login",
              style: GoogleFonts.rubik(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Welcome back to emp Jewellerys",
              style: GoogleFonts.outfit(fontSize: 14, color: Colors.white70),
            ),
            SizedBox(height: 30),
            _buildLoginForm(screenWidth * 0.9),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Login Form Widget (shared between layouts) - Updated for phone
  Widget _buildLoginForm(double width) {
    return Form(
      key: _formKey,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show error message if any
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red[300]),
                ),
              ),

            // Phone Number Input
            Text(
              "Phone Number",
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.phone, color: Colors.white54),
                hintText: "Enter your phone number",
                hintStyle: TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter your phone number";
                }
                // Basic phone number validation (adjust as needed)
                if (value.length < 10) {
                  return "Please enter a valid phone number";
                }
                return null;
              },
            ),
            SizedBox(height: 20),

            // Password Input
            Text(
              "Password",
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscureText,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock, color: Colors.white54),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white54,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
                hintText: "Enter your password",
                hintStyle: TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter your password";
                }
                return null;
              },
            ),
            SizedBox(height: 12),

            // Forgot Password Link
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Add forgot password functionality
                },
                child: Text(
                  "Forgot Password?",
                  style: TextStyle(color: kPrimaryColor),
                ),
              ),
            ),
            SizedBox(height: 25),

            // Login Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child:
                    _isLoading
                        ? CupertinoActivityIndicator(
                          color: Colors.white,
                          radius: 16,
                        )
                        : Text(
                          "LOGIN",
                          style: GoogleFonts.rubik(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Example for modifying the DesktopHomeScreen to use the stored user data
class ProfileSection extends StatefulWidget {
  const ProfileSection({super.key});

  @override
  _ProfileSectionState createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  UserModel? userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final userId = prefs.getString('userId');
      if (userId != null) {
        setState(() {
          userData = UserModel(
            id: userId,
            name: prefs.getString('userName') ?? 'User',
            email: prefs.getString('userEmail') ?? 'No email',
            role: prefs.getString('userRole') ?? 'No role',
            balance: prefs.getInt('userBalance') ?? 0,
            ledger: [], // ✅ allowed now
            phone: prefs.getString('userPhone'),
            customerId: prefs.getString('userCustomerId'),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: DiamondIndicator());
    }

    if (userData == null) {
      return Center(child: Text('User data not available'));
    }

    return Column(
      children: [
        Text('Welcome, ${userData!.name}'),
        Text('Email: ${userData!.email}'),
        Text('Phone: ${userData!.phone ?? 'Not available'}'),
        Text('Customer ID: ${userData!.customerId ?? 'Not available'}'),
        Text('Role: ${userData!.role}'),
        Text('Balance: ${userData!.balance}'),
      ],
    );
  }
}
