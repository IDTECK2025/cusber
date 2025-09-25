import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:gold_pos/api.dart';
import 'package:gold_pos/utils/diamond_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uicons/uicons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/colors.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi-Step Form',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Inter'),
      home: ShareHolderForm(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// API Service Class
class ApiService {
  static const String baseUrl = ApiConfig.baseUrl;

  // Method to get stored token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Method to store token (call this after login)
  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Method to clear token (call this on logout)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // Login method to get authentication token
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/auth/login'); // Adjust endpoint as needed

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      print('Login Response Status: ${response.statusCode}');
      print('Login Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Store the token (adjust the key based on your API response structure)
        String token =
            data['token'] ?? data['access_token'] ?? data['authToken'] ?? '';
        if (token.isNotEmpty) {
          await setToken(token);
        }

        return {
          'success': true,
          'data': data,
          'token': token,
          'message': 'Login successful',
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'message': 'Invalid credentials',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: $e',
        'message': 'Please check your internet connection and try again',
      };
    }
  }

  static Future<Map<String, dynamic>> createShareholder({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String aadhaar,
    required String pan,
    required String holderName,
    required String bankAccount,
    required String ifsc,
    required String branchName,
    required String branchCode,
    required String city,
    required String state,
    required String address,
    String? parentId,
  }) async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'error': 'Authentication required',
          'message': 'Please login first',
        };
      }

      final url = Uri.parse('$baseUrl/users/shareholders');

      final Map<String, dynamic> requestBody = {
        'name': '$firstName $lastName',
        'email': email,
        'phone': phone,
        'adhar': aadhaar,
        'pancard': pan,
        'Bank': holderName,
        'IFSC': ifsc,
        'acc': bankAccount,
        'branch': branchName,
        'city': city,
        'state': state,
        'addrass': address,
        'role': 'SHAREHOLDER',
      };

      // Add parent ID if provided
      if (parentId != null && parentId.isNotEmpty) {
        requestBody['parent'] = parentId;
      }

      print('📡 Sending shareholder data to: $url');
      print('📤 Request body: ${json.encode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('📡 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      // Success response handling
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        return {
          'success': true,
          'data': responseData['data'] ?? responseData,
          'message': 'Shareholder created successfully',
        };
      }
      // Authentication expired
      else if (response.statusCode == 401) {
        await clearToken();
        return {
          'success': false,
          'error': 'Authentication expired',
          'message': 'Please login again',
        };
      }
      // Client errors (400-499)
      else if (response.statusCode >= 400 && response.statusCode < 500) {
        String errorMessage = 'Invalid data provided';
        try {
          final errorData = json.decode(response.body);
          errorMessage =
              errorData['message'] ??
              errorData['error'] ??
              'Request failed with status ${response.statusCode}';
        } catch (e) {
          errorMessage =
              response.body.isNotEmpty
                  ? response.body
                  : 'Invalid request (${response.statusCode})';
        }

        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'message': errorMessage,
        };
      }
      // Server errors (500-599)
      else if (response.statusCode >= 500) {
        return {
          'success': false,
          'error': 'Server error',
          'message':
              'Server is temporarily unavailable. Please try again later.',
        };
      }
      // Other status codes
      else {
        String errorMessage = 'Request failed';
        try {
          final errorData = json.decode(response.body);
          errorMessage =
              errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (e) {
          errorMessage = 'Unexpected response (${response.statusCode})';
        }

        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'message': errorMessage,
        };
      }
    }
    // Network connectivity issues
    catch (e) {
      print('❌ API Error: $e');

      String userMessage;
      String errorType;

      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException')) {
        userMessage =
            'No internet connection. Please check your network and try again.';
        errorType = 'Network error';
      } else if (e.toString().contains('TimeoutException')) {
        userMessage = 'Request timed out. Please try again.';
        errorType = 'Timeout error';
      } else if (e.toString().contains('FormatException')) {
        userMessage = 'Invalid server response. Please try again.';
        errorType = 'Format error';
      } else {
        userMessage = 'Something went wrong. Please try again.';
        errorType = 'Unknown error';
      }

      return {
        'success': false,
        'error': '$errorType: $e',
        'message': userMessage,
      };
    }
  }

  static String generateTemporaryPassword() {
    final random = Random();
    final randomNumber = 100000 + random.nextInt(900000);
    return 'EMPJR-$randomNumber';
  }
}

class ShareHolderForm extends StatefulWidget {
  const ShareHolderForm({super.key});

  @override
  _ShareHolderFormScreenState createState() => _ShareHolderFormScreenState();
}

class _ShareHolderFormScreenState extends State<ShareHolderForm> {
  int currentStep = 1;
  final _formKey = GlobalKey<FormState>();

  // Step 1 - Personal Details Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();

  // Step 2 - Bank Details Controllers
  final _holderNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _branchCodeController = TextEditingController();

  // Step 3 - Address Details Controllers
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _addressController = TextEditingController();

  // Focus Nodes for Step 1 - Personal Details
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _aadhaarFocus = FocusNode();
  final FocusNode _panFocus = FocusNode();

  // Focus Nodes for Step 2 - Bank Details
  final FocusNode _holderNameFocus = FocusNode();
  final FocusNode _bankAccountFocus = FocusNode();
  final FocusNode _ifscFocus = FocusNode();
  final FocusNode _branchNameFocus = FocusNode();
  final FocusNode _branchCodeFocus = FocusNode();

  // Focus Nodes for Step 3 - Address Details
  final FocusNode _cityFocus = FocusNode();
  final FocusNode _stateFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();

  bool _isSubmitting = false;

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        if (currentStep < 4) {
          currentStep++;
        }
      });
    }
  }

  void _previousStep() {
    setState(() {
      if (currentStep > 1) {
        currentStep--;
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            children: [
              DiamondIndicator(color: kPrimaryColor),
              SizedBox(width: 20),
              Text('Creating shareholder account...'),
            ],
          ),
        );
      },
    );

    try {
      final result = await ApiService.createShareholder(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        aadhaar: _aadhaarController.text.trim(),
        pan: _panController.text.trim(),
        holderName: _holderNameController.text.trim(),
        bankAccount: _bankAccountController.text.trim(),
        ifsc: _ifscController.text.trim(),
        branchName: _branchNameController.text.trim(),
        branchCode: _branchCodeController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text?.trim() ?? 'Kerala',
        address: _addressController.text.trim(),
      );

      // Close loading dialog
      Navigator.of(context).pop();

      setState(() {
        _isSubmitting = false;
      });

      // CLEAN LOGIC: Only success or auth errors
      if (result['success'] == true) {
        _showSuccessDialog(result['data']);
      } else if (result['error'] == 'Authentication required' ||
          result['error'] == 'Authentication expired') {
        _showLoginRequiredDialog();
      } else {
        _showErrorDialog(result['message'] ?? 'Unknown error occurred');
      }
    } on SocketException {
      Navigator.of(context).pop(); // Close loading dialog
      setState(() {
        _isSubmitting = false;
      });
      _showErrorDialog(
        'No internet connection. Please check your network and try again.',
      );
    } on TimeoutException {
      Navigator.of(context).pop(); // Close loading dialog
      setState(() {
        _isSubmitting = false;
      });
      _showErrorDialog('Request timed out. Please try again.');
    } on FormatException {
      Navigator.of(context).pop(); // Close loading dialog
      setState(() {
        _isSubmitting = false;
      });
      _showErrorDialog('Invalid server response. Please try again.');
    } catch (e) {
      print('❌ Form submission error: $e');
      Navigator.of(context).pop(); // Close loading dialog

      setState(() {
        _isSubmitting = false;
      });

      _showErrorDialog('Failed to submit form: ${e.toString()}');
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Authentication Required'),
          content: const Text(
            'Please login before creating a shareholder account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Login', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(dynamic userData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            // FIXED: Removed Expanded wrapper
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(
                    0.1,
                  ), // CHANGED: Use kPrimaryColor instead of green
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color:
                      kPrimaryColor, // CHANGED: Use kPrimaryColor instead of green
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                // FIXED: Moved Expanded inside Row
                child: Text(
                  'Registration Complete!',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shareholder account has been successfully created.', // SIMPLIFIED: Removed verification text
                style: TextStyle(fontSize: 14),
              ),
              if (userData != null && userData['_id'] != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'User ID:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(userData['_id'].toString()),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetForm();
                Navigator.pushNamed(context, '/shareholder');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.error, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Submission Failed', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Text(message, style: const TextStyle(fontSize: 14)),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _resetForm() {
    setState(() {
      currentStep = 1;
    });

    // Clear all form fields
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _aadhaarController.clear();
    _panController.clear();
    _dobController.clear();
    _passwordController.clear();
    _holderNameController.clear();
    _bankAccountController.clear();
    _ifscController.clear();
    _branchNameController.clear();
    _branchCodeController.clear();
    _cityController.clear();
    _stateController.clear();
    _addressController.clear();
  }

  Widget _buildStep4Confirmation(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF8F9FA),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConfirmationSection('Personal Details', [
            _buildConfirmationRow(
              'Name',
              '${_firstNameController.text} ${_lastNameController.text}',
            ),
            _buildConfirmationRow('Email Address', _emailController.text),
            _buildConfirmationRow('Phone Number', _phoneController.text),
            _buildConfirmationRow(
              'Aadhaar Card Number',
              _aadhaarController.text,
            ),
            _buildConfirmationRow('Pan Card Number', _panController.text),
            _buildConfirmationRow('Date of Birth', _dobController.text),
          ]),
          const SizedBox(height: 24),
          _buildConfirmationSection('Bank Details', [
            _buildConfirmationRow(
              'Account Holder Name',
              _holderNameController.text,
            ),
            _buildConfirmationRow(
              'Bank Account Number',
              _bankAccountController.text,
            ),
            _buildConfirmationRow('IFSC Code', _ifscController.text),
            _buildConfirmationRow('Branch Name', _branchNameController.text),
            _buildConfirmationRow('Branch Code', _branchCodeController.text),
          ]),
          const SizedBox(height: 24),
          _buildConfirmationSection('Address Details', [
            _buildConfirmationRow('City', _cityController.text),
            _buildConfirmationRow('State', _stateController.text),
            _buildConfirmationRow('Address', _addressController.text),
          ]),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4FD),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: kPrimaryColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Please review all information carefully. Once confirmed, this data will be submitted to create your shareholder account.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[100]!, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 768;

          if (isDesktop) {
            return _buildDesktopLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        SizedBox(width: 300, child: _buildSidebar()),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _buildMainContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Container(
      color: Colors.white,
      child: SafeArea(child: _buildMainContent(isMobile: true)),
    );
  }

  Widget _buildSidebar() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(.5),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    UIcons.regularRounded.angle_small_left,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: const Text(
                      'Shareholder Registration',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          _buildStepItem(
            1,
            'Personal Details',
            currentStep > 1,
            isActive: currentStep == 1,
          ),
          _buildConnector(currentStep > 1),
          _buildStepItem(
            2,
            'Bank Details',
            currentStep > 2,
            isActive: currentStep == 2,
          ),
          _buildConnector(currentStep > 2),
          _buildStepItem(
            3,
            'Address Details',
            currentStep > 3,
            isActive: currentStep == 3,
          ),
          _buildConnector(currentStep > 3),
          _buildStepItem(4, 'Confirmation', false, isActive: currentStep == 4),
          const Spacer(),
          Center(
            child: Image.asset(
              'assets/images/emp_bg.png',
              height: 150,
              width: 150,
            ),
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStepItem(
    int step,
    String title,
    bool completed, {
    bool isActive = false,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(3),
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Container(
            padding: EdgeInsets.all(3),
            decoration: BoxDecoration(
              color:
                  isActive ? Colors.white.withOpacity(.5) : Colors.transparent,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Container(
              decoration: BoxDecoration(
                color:
                    completed
                        ? Colors.white
                        : (isActive ? Colors.white : Colors.transparent),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child:
                    completed
                        ? Icon(
                          PhosphorIcons.check,
                          color: kPrimaryColor,
                          size: 18,
                        )
                        : Text(
                          step.toString(),
                          style: TextStyle(
                            color: isActive ? kPrimaryColor : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STEP $step',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  color:
                      (isActive == completed) ? Colors.white70 : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(bool completed) {
    return Container(
      margin: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
      width: 2,
      height: 30,
      color: completed ? Colors.white : Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildMainContent({bool isMobile = false}) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 32).copyWith(bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMobileHeader(),
          const SizedBox(height: 24),
          Text(
            _getStepTitle(),
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getStepDescription(),
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Form(key: _formKey, child: _buildCurrentStepForm(isMobile)),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (currentStep) {
      case 1:
        return 'Shareholder personal details';
      case 2:
        return 'Add bank details';
      case 3:
        return 'Add address details';
      case 4:
        return 'Confirm shareholder information';
      default:
        return 'Complete shareholder profile';
    }
  }

  String _getStepDescription() {
    switch (currentStep) {
      case 1:
        return 'We need shareholder personal information for identity verification and account setup';
      case 2:
        return 'Please provide shareholder bank account details for payment processing and verification';
      case 3:
        return 'Please provide shareholder address and location information';
      case 4:
        return 'Please review shareholder information  and confirm to complete account ';
      default:
        return 'Please complete all required shareholder information';
    }
  }

  Widget _buildMobileHeader() {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          if (currentStep == 1)
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(
                UIcons.regularRounded.angle_small_left,
                color: kPrimaryColor,
              ),
            ),
          if (currentStep > 1)
            IconButton(
              onPressed: _previousStep,
              icon: Icon(
                UIcons.regularRounded.angle_small_left,
                color: kPrimaryColor,
              ),
            ),
          const SizedBox(width: 8),
          Text(
            'STEP $currentStep OF 4',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepForm(bool isMobile) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Column(
                key: ValueKey(currentStep),
                children: [
                  if (currentStep == 1) _buildStep1Fields(isMobile),
                  if (currentStep == 2) _buildStep2Fields(isMobile),
                  if (currentStep == 3) _buildStep3Fields(isMobile),
                  if (currentStep == 4) _buildStep4Confirmation(isMobile),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildNavigationButtons(),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1Fields(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildTextField(
            'First Name',
            _firstNameController,
            isRequired: true,
            focusNode: _firstNameFocus,
            nextFocusNode: _lastNameFocus,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Last Name',
            _lastNameController,
            isRequired: true,
            focusNode: _lastNameFocus,
            nextFocusNode: _emailFocus,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Email Address',
            _emailController,
            keyboardType: TextInputType.emailAddress,
            isRequired: true,
            focusNode: _emailFocus,
            nextFocusNode: _phoneFocus,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Phone Number',
            _phoneController,
            keyboardType: TextInputType.phone,
            isRequired: true,
            focusNode: _phoneFocus,
            nextFocusNode: _aadhaarFocus,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Aadhaar Card Number',
            _aadhaarController,
            keyboardType: TextInputType.number,
            isRequired: true,
            focusNode: _aadhaarFocus,
            nextFocusNode: _panFocus,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Pan Card Number',
            _panController,
            keyboardType: TextInputType.visiblePassword,
            isRequired: true,
            isUpperCase: true,
            focusNode: _panFocus,
          ), // No nextFocusNode - last field
        ],
      );
    } else {
      // Desktop layout - similar pattern but for rows
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'First Name',
                  _firstNameController,
                  isRequired: true,
                  focusNode: _firstNameFocus,
                  nextFocusNode: _lastNameFocus,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildTextField(
                  'Last Name',
                  _lastNameController,
                  isRequired: true,
                  focusNode: _lastNameFocus,
                  nextFocusNode: _emailFocus,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'Email Address',
                  _emailController,
                  keyboardType: TextInputType.emailAddress,
                  isRequired: true,
                  focusNode: _emailFocus,
                  nextFocusNode: _phoneFocus,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildTextField(
                  'Phone Number',
                  _phoneController,
                  keyboardType: TextInputType.phone,
                  isRequired: true,
                  focusNode: _phoneFocus,
                  nextFocusNode: _aadhaarFocus,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'Aadhaar Card Number',
                  _aadhaarController,
                  keyboardType: TextInputType.number,
                  isRequired: true,
                  focusNode: _aadhaarFocus,
                  nextFocusNode: _panFocus,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildTextField(
                  'Pan Card Number',
                  _panController,
                  keyboardType: TextInputType.visiblePassword,
                  isRequired: true,
                  isUpperCase: true,
                  focusNode: _panFocus,
                ), // No nextFocusNode - last field
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildStep2Fields(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildTextField(
            'Account Holder Name',
            _holderNameController,
            keyboardType: TextInputType.text,
            isRequired: true,
            isUpperCase: true,
            focusNode: _holderNameFocus,
            nextFocusNode: _bankAccountFocus,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Bank Account Number',
            _bankAccountController,
            keyboardType: TextInputType.number,
            isRequired: true,
            focusNode: _bankAccountFocus,
            nextFocusNode: _ifscFocus,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'IFSC Code',
            _ifscController,
            isRequired: true,
            isUpperCase: true,
            focusNode: _ifscFocus,
            nextFocusNode: _branchNameFocus,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Branch Name',
            _branchNameController,
            keyboardType: TextInputType.text,
            isRequired: true,
            isUpperCase: true,
            focusNode: _branchNameFocus,
            nextFocusNode: _branchCodeFocus,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Branch Code',
            _branchCodeController,
            keyboardType: TextInputType.visiblePassword,
            isRequired: true,
            isUpperCase: true,
            focusNode: _branchCodeFocus,
          ), // No nextFocusNode - last field
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'Account Holder Name',
                  _holderNameController,
                  keyboardType: TextInputType.text,
                  isRequired: true,
                  isUpperCase: true,
                  focusNode: _holderNameFocus,
                  nextFocusNode: _bankAccountFocus,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildTextField(
                  'Bank Account Number',
                  _bankAccountController,
                  keyboardType: TextInputType.number,
                  isRequired: true,
                  focusNode: _bankAccountFocus,
                  nextFocusNode: _ifscFocus,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildTextField(
            'IFSC Code',
            _ifscController,
            isRequired: true,
            isUpperCase: true,
            focusNode: _ifscFocus,
            nextFocusNode: _branchNameFocus,
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'Branch Name',
                  _branchNameController,
                  keyboardType: TextInputType.text,
                  isRequired: true,
                  isUpperCase: true,
                  focusNode: _branchNameFocus,
                  nextFocusNode: _branchCodeFocus,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildTextField(
                  'Branch Code',
                  _branchCodeController,
                  keyboardType: TextInputType.visiblePassword,
                  isRequired: true,
                  isUpperCase: true,
                  focusNode: _branchCodeFocus,
                ), // No nextFocusNode - last field
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildStep3Fields(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildTextField(
            'City',
            _cityController,
            keyboardType: TextInputType.text,
            isRequired: true,
            focusNode: _cityFocus,
            nextFocusNode: _stateFocus,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'State',
            _stateController,
            keyboardType: TextInputType.text,
            isRequired: true,
            focusNode: _stateFocus,
            nextFocusNode: _addressFocus,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Address',
            _addressController,
            keyboardType: TextInputType.multiline,
            isRequired: true,
            maxLines: 3,
            focusNode: _addressFocus,
          ), // No nextFocusNode - last field (multiline)
        ],
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'City',
                  _cityController,
                  keyboardType: TextInputType.text,
                  isRequired: true,
                  focusNode: _cityFocus,
                  nextFocusNode: _stateFocus,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildTextField(
                  'State',
                  _stateController,
                  keyboardType: TextInputType.text,
                  isRequired: true,
                  focusNode: _stateFocus,
                  nextFocusNode: _addressFocus,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildTextField(
            'Address',
            _addressController,
            keyboardType: TextInputType.multiline,
            isRequired: true,
            maxLines: 3,
            focusNode: _addressFocus,
          ), // No nextFocusNode - last field (multiline)
        ],
      );
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    bool isRequired = false,
    bool isUpperCase = false,
    int maxLines = 1,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
  }) {
    List<TextInputFormatter> inputFormatters = [];

    // Add uppercase formatter for bank fields
    if (isUpperCase) {
      inputFormatters.add(UpperCaseTextInputFormatter());
    }

    if (label == 'Aadhaar Card Number') {
      inputFormatters.add(FilteringTextInputFormatter.digitsOnly);
      inputFormatters.add(LengthLimitingTextInputFormatter(12));
    } else if (label == 'Pan Card Number') {
      inputFormatters.add(
        FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
      );
      inputFormatters.add(LengthLimitingTextInputFormatter(10));
    } else if (label == 'Phone Number') {
      inputFormatters.add(FilteringTextInputFormatter.digitsOnly);
      inputFormatters.add(LengthLimitingTextInputFormatter(10));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          autofocus: true,
          focusNode: focusNode,
          keyboardType: keyboardType,
          cursorColor: kPrimaryColor,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          textInputAction:
              maxLines > 1
                  ? TextInputAction.newline
                  : (nextFocusNode != null
                      ? TextInputAction.next
                      : TextInputAction.done),
          onFieldSubmitted: (value) {
            if (nextFocusNode != null) {
              FocusScope.of(context).requestFocus(nextFocusNode);
            } else {
              // This is the last field in the step, trigger next step or submit
              if (currentStep == 4) {
                _submitForm(); // Submit on final step
              } else {
                _nextStep(); // Go to next step
              }
            }
          },
          validator:
              isRequired
                  ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'This field is required';
                    }
                    if (label == 'Email Address' && !value.contains('@')) {
                      return 'Please enter a valid email address';
                    }
                    if (label == 'Aadhaar Card Number' && value.length != 12) {
                      return 'Aadhaar number should be 12 digits';
                    }
                    if (label == 'Pan Card Number' &&
                        value.length != 10 &&
                        !RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}').hasMatch(value)) {
                      return 'Enter valid PAN (e.g. ABCDE1234F)';
                    }
                    if (label == 'IFSC Code' &&
                        !RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}').hasMatch(value)) {
                      return 'Enter valid IFSC (e.g. SBIN0000123)';
                    }
                    if (label == 'Phone Number' && value.length != 10) {
                      return 'Phone number should be 10 digits';
                    }
                    return null;
                  }
                  : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF7FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kPrimaryColor),
            ),
            errorStyle: TextStyle(
              color: kPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (currentStep > 1) ...[
          OutlinedButton(
            onPressed: _previousStep,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: kPrimaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            ),
            child: Text(
              'Previous',
              style: TextStyle(
                color: kPrimaryColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        ElevatedButton(
          onPressed:
              _isSubmitting
                  ? null
                  : (currentStep == 4 ? _submitForm : _nextStep),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
          child:
              _isSubmitting
                  ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Submitting...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  )
                  : Text(
                    currentStep == 4 ? 'Submit' : 'Next',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Step 1 controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _aadhaarController.dispose();
    _panController.dispose();
    _dobController.dispose();
    _passwordController.dispose();

    // Step 2 controllers
    _holderNameController.dispose();
    _bankAccountController.dispose();
    _ifscController.dispose();
    _branchNameController.dispose();
    _branchCodeController.dispose();

    // Step 3 controllers
    _cityController.dispose();
    _stateController.dispose();
    _addressController.dispose();

    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _aadhaarFocus.dispose();
    _panFocus.dispose();
    _holderNameFocus.dispose();
    _bankAccountFocus.dispose();
    _ifscFocus.dispose();
    _branchNameFocus.dispose();
    _branchCodeFocus.dispose();
    _cityFocus.dispose();
    _stateFocus.dispose();
    _addressFocus.dispose();

    super.dispose();
  }
}

// Custom TextInputFormatter to convert input to uppercase
class UpperCaseTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
