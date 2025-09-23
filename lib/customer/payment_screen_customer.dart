import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gold_pos/api.dart';
import 'package:gold_pos/auth_helper.dart';
import 'package:gold_pos/models/customer_model.dart';
import 'package:gold_pos/utils/diamond_indicator.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' show ImageFilter;
import '../../utils/avathar.dart';
import '../../utils/colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Customer Payment',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
      home: const CustomerPaymentScreen(),
    );
  }
}

// [PaymentService class remains the same]
class PaymentService {
  static const String baseUrl = ApiConfig.baseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthHelper.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> makePayment({
    required String customerId,
    required double amount,
    required String month,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$baseUrl/payments'),
        headers: headers,
        body: jsonEncode({
          'customerId': customerId,
          'amount': amount,
          'month': month,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        final errorBody = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorBody['message'] ?? 'Payment failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getCustomers() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/customers'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to fetch customers'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getCustomerById(String customerId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/customers/$customerId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'error': 'Failed to fetch customer details'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
}

enum PaymentType { online, offline }

class CustomerPaymentScreen extends StatefulWidget {
  const CustomerPaymentScreen({super.key});

  @override
  State<CustomerPaymentScreen> createState() => _CustomerPaymentScreenState();
}

class _CustomerPaymentScreenState extends State<CustomerPaymentScreen> {
  List<Customer> _allCustomers = [];
  bool _isLoading = true;
  String _query = '';
  Customer? _selectedCustomer;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();
  PaymentType? _paymentType;
  DateTime? _selectedDate;

  List<Customer> get _filteredCustomers {
    if (_query.trim().isEmpty) return _allCustomers;
    final q = _query.toLowerCase();
    return _allCustomers
        .where((c) => c.name.toLowerCase().contains(q) || c.phone.contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _paymentType = PaymentType.offline;
    _selectedDate = DateTime.now();
    _dateCtrl.text = _formatDate(DateTime.now());
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);

    try {
      final result = await PaymentService.getCustomers();

      if (result['success']) {
        final List<dynamic> customerData =
            result['data'] is List
                ? result['data']
                : result['data']['customers'] ?? [];

        _allCustomers =
            customerData.map((json) => Customer.fromJson(json)).toList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load customers: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
        _allCustomers = [];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading customers: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      _allCustomers = [];
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      helpText: 'Select Payment Date',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateCtrl.text = _formatDate(picked);
      });
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  }

  Future<void> _refreshCustomerData(String customerId) async {
    try {
      final result = await PaymentService.getCustomerById(customerId);

      if (result['success']) {
        final updatedCustomer = Customer.fromJson(result['data']);

        setState(() {
          final index = _allCustomers.indexWhere((c) => c.id == customerId);
          if (index != -1) {
            _allCustomers[index] = updatedCustomer;
            _selectedCustomer = updatedCustomer;
            _amountCtrl.text = updatedCustomer.schemeAmount.toStringAsFixed(0);
          }
        });
      }
    } catch (e) {
      print('Error refreshing customer data: $e');
    }
  }

  void _onSubmit() async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer.')),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_paymentType == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }

    if (_selectedCustomer!.emaidate != null) {
      final now = DateTime.now();
      final nextPayableDate = _selectedCustomer!.emaidate!;
      final twentyDaysBefore = DateTime(
        nextPayableDate.year,
        nextPayableDate.month,
        nextPayableDate.day - 20,
      );

      if (now.isBefore(twentyDaysBefore)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment can only be made 20 days before next payable date (${_formatDate(nextPayableDate)}). '
              'You can make payment from ${_formatDate(twentyDaysBefore)} onwards.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final emiDate = _selectedCustomer!.emaidate ?? _selectedDate!;
      final month =
          '${emiDate.year}-${emiDate.month.toString().padLeft(2, '0')}';

      final result = await PaymentService.makePayment(
        customerId: _selectedCustomer!.id,
        amount: double.parse(_amountCtrl.text),
        month: month,
      );

      Navigator.of(context).pop();

      if (result['success']) {
        final details = PaymentDetails(
          customer: _selectedCustomer!,
          amount: double.parse(_amountCtrl.text),
          paymentType: _paymentType!,
          paymentDate: _selectedDate!,
          apiResponse: result['data'],
        );

        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SuccessScreen(details: details)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Handle customer tap - navigate to payment screen on mobile
  void _onCustomerTap(Customer customer) {
    final constraints = MediaQuery.of(context).size;
    final isMobile = constraints.width < 600;

    if (isMobile) {
      // Navigate to separate payment screen on mobile
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => MobilePaymentScreen(
                customer: customer,
                onRefreshCustomer: () => _refreshCustomerData(customer.id),
              ),
        ),
      );
    } else {
      // Existing behavior for tablet/desktop
      setState(() {
        _selectedCustomer = customer;
        _amountCtrl.text = customer.schemeAmount.toStringAsFixed(0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive breakpoints
            final isDesktop = constraints.maxWidth > 1024;
            final isTablet =
                constraints.maxWidth >= 600 && constraints.maxWidth <= 1024;
            final isMobile = constraints.maxWidth < 600;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Responsive Search Header
                _buildSearchHeader(isDesktop, isTablet, isMobile),

                SizedBox(
                  height:
                      isDesktop
                          ? 24
                          : isTablet
                          ? 20
                          : 16,
                ),

                // Responsive Main Content
                Expanded(
                  child: _buildMainContent(
                    constraints,
                    isDesktop,
                    isTablet,
                    isMobile,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchHeader(bool isDesktop, bool isTablet, bool isMobile) {
    return SizedBox(
      height:
          isDesktop
              ? 48
              : isTablet
              ? 44
              : 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal:
                    isDesktop
                        ? 16
                        : isTablet
                        ? 14
                        : 12,
                vertical:
                    isDesktop
                        ? 12
                        : isTablet
                        ? 10
                        : 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  isDesktop
                      ? 16
                      : isTablet
                      ? 14
                      : 12,
                ),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow:
                    isDesktop
                        ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : [],
              ),
              child: TextField(
                cursorColor: kPrimaryColor,
                style: TextStyle(
                  fontSize:
                      isDesktop
                          ? 16
                          : isTablet
                          ? 14
                          : 12,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search customer name or phone',
                  hintStyle: TextStyle(
                    color: const Color(0xFF9CA3AF),
                    fontSize:
                        isDesktop
                            ? 16
                            : isTablet
                            ? 14
                            : 12,
                  ),
                  border: InputBorder.none,
                  icon: Icon(
                    Icons.search,
                    size:
                        isDesktop
                            ? 20
                            : isTablet
                            ? 18
                            : 16,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ),

          SizedBox(
            width:
                isDesktop
                    ? 16
                    : isTablet
                    ? 14
                    : 12,
          ),

          GestureDetector(
            onTap: _loadCustomers,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal:
                    isDesktop
                        ? 16
                        : isTablet
                        ? 14
                        : 12,
                vertical:
                    isDesktop
                        ? 12
                        : isTablet
                        ? 10
                        : 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  isDesktop
                      ? 16
                      : isTablet
                      ? 14
                      : 12,
                ),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow:
                    isDesktop
                        ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.refresh,
                    size:
                        isDesktop
                            ? 20
                            : isTablet
                            ? 18
                            : 16,
                    color: _isLoading ? kPrimaryColor : const Color(0xFF6B7280),
                  ),
                  if (!isMobile) ...[
                    SizedBox(width: isDesktop ? 8 : 6),
                    Text(
                      'Refresh',
                      style: TextStyle(
                        color:
                            _isLoading
                                ? kPrimaryColor
                                : const Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                        fontSize: isDesktop ? 16 : 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    BoxConstraints constraints,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
  ) {
    if (isMobile) {
      // Mobile: Only Customer List (Payment screen is separate)
      return _buildMobileCustomerList();
    } else {
      // Tablet & Desktop: Horizontal Layout
      return _buildTabletDesktopLayout(isDesktop, isTablet);
    }
  }

  Widget _buildMobileCustomerList() {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child:
          _isLoading
              ? Center(child: DiamondIndicator(size: 8))
              : _filteredCustomers.isEmpty
              ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No customers found'),
                ),
              )
              : ListView.separated(
                itemCount: _filteredCustomers.length,
                separatorBuilder:
                    (_, __) => const Divider(height: 1, color: Colors.black12),
                itemBuilder: (context, index) {
                  final c = _filteredCustomers[index];
                  return ListTile(
                    dense: true,
                    leading: Avatar(name: c.name, size: 20),
                    title: Text(
                      c.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.phone,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${c.schemeAmount.toStringAsFixed(0)}/month',
                          style: TextStyle(
                            color: kPrimaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _onCustomerTap(c),
                  );
                },
              ),
    );
  }

  Widget _buildTabletDesktopLayout(bool isDesktop, bool isTablet) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Customer List
        Expanded(
          flex: isDesktop ? 6 : 7,
          child: Card(
            margin: EdgeInsets.zero,
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Colors.black12),
              borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
            ),
            child:
                _isLoading
                    ? Center(child: DiamondIndicator(size: isDesktop ? 12 : 10))
                    : _filteredCustomers.isEmpty
                    ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(isDesktop ? 32.0 : 24.0),
                        child: Text(
                          'No customers found',
                          style: TextStyle(fontSize: isDesktop ? 16 : 14),
                        ),
                      ),
                    )
                    : ListView.separated(
                      itemCount: _filteredCustomers.length,
                      separatorBuilder:
                          (_, __) =>
                              const Divider(height: 1, color: Colors.black12),
                      itemBuilder: (context, index) {
                        final c = _filteredCustomers[index];
                        final isSelected = _selectedCustomer?.id == c.id;
                        return ListTile(
                          leading: Avatar(
                            name: c.name,
                            size: isDesktop ? 24 : 20,
                          ),
                          title: Text(
                            c.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isDesktop ? 16 : 14,
                              color: isSelected ? kPrimaryColor : Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            c.phone,
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: isDesktop ? 14 : 12,
                            ),
                          ),
                          trailing:
                              isSelected
                                  ? Icon(
                                    Icons.check_circle,
                                    color: kPrimaryColor,
                                    size: isDesktop ? 24 : 20,
                                  )
                                  : Icon(
                                    Icons.chevron_right,
                                    size: isDesktop ? 24 : 20,
                                  ),
                          selected: isSelected,
                          onTap: () => _onCustomerTap(c),
                        );
                      },
                    ),
          ),
        ),

        SizedBox(width: isDesktop ? 24 : 16),

        // Right: Payment Form or Hint
        Expanded(
          flex: isDesktop ? 8 : 10,
          child:
              _selectedCustomer == null
                  ? _HintPanel(isDesktop: isDesktop, isTablet: isTablet)
                  : _PaymentForm(
                    formKey: _formKey,
                    selectedCustomer: _selectedCustomer!,
                    amountCtrl: _amountCtrl,
                    dateCtrl: _dateCtrl,
                    paymentType: _paymentType,
                    onPaymentTypeChanged:
                        (pt) => setState(() => _paymentType = pt),
                    onPickDate: _pickDate,
                    onSubmit: _onSubmit,
                    selectedDate: _selectedDate,
                    isDesktop: isDesktop,
                    isTablet: isTablet,
                  ),
        ),
      ],
    );
  }
}

// New Mobile Payment Screen
class MobilePaymentScreen extends StatefulWidget {
  final Customer customer;
  final VoidCallback onRefreshCustomer;

  const MobilePaymentScreen({
    super.key,
    required this.customer,
    required this.onRefreshCustomer,
  });

  @override
  State<MobilePaymentScreen> createState() => _MobilePaymentScreenState();
}

class _MobilePaymentScreenState extends State<MobilePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _dateCtrl = TextEditingController();
  PaymentType? _paymentType;
  DateTime? _selectedDate;
  Customer? _currentCustomer;

  @override
  void initState() {
    super.initState();
    _currentCustomer = widget.customer;
    _paymentType = PaymentType.offline;
    _selectedDate = DateTime.now();
    _dateCtrl.text = _formatDate(DateTime.now());
    _amountCtrl.text = widget.customer.schemeAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      helpText: 'Select Payment Date',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateCtrl.text = _formatDate(picked);
      });
    }
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  }

  void _onSubmit() async {
    if (_currentCustomer == null) return;

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_paymentType == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }

    if (_currentCustomer!.emaidate != null) {
      final now = DateTime.now();
      final nextPayableDate = _currentCustomer!.emaidate!;
      final twentyDaysBefore = DateTime(
        nextPayableDate.year,
        nextPayableDate.month,
        nextPayableDate.day - 20,
      );

      if (now.isBefore(twentyDaysBefore)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment can only be made 20 days before next payable date (${_formatDate(nextPayableDate)}). '
              'You can make payment from ${_formatDate(twentyDaysBefore)} onwards.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final emiDate = _currentCustomer!.emaidate ?? _selectedDate!;
      final month =
          '${emiDate.year}-${emiDate.month.toString().padLeft(2, '0')}';

      final result = await PaymentService.makePayment(
        customerId: _currentCustomer!.id,
        amount: double.parse(_amountCtrl.text),
        month: month,
      );

      Navigator.of(context).pop();

      if (result['success']) {
        final details = PaymentDetails(
          customer: _currentCustomer!,
          amount: double.parse(_amountCtrl.text),
          paymentType: _paymentType!,
          paymentDate: _selectedDate!,
          apiResponse: result['data'],
        );

        // Navigate to success screen and refresh parent
        widget.onRefreshCustomer();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => SuccessScreen(details: details)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentCustomer == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Payment Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: Text('Customer not found')),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Payment Details',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _PaymentForm(
            formKey: _formKey,
            selectedCustomer: _currentCustomer!,
            amountCtrl: _amountCtrl,
            dateCtrl: _dateCtrl,
            paymentType: _paymentType,
            onPaymentTypeChanged: (pt) => setState(() => _paymentType = pt),
            onPickDate: _pickDate,
            onSubmit: _onSubmit,
            selectedDate: _selectedDate,
            isMobile: true,
            isFullScreen: true, // New parameter for full screen mobile view
          ),
        ),
      ),
    );
  }
}

class _HintPanel extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;

  const _HintPanel({this.isDesktop = false, this.isTablet = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.black12),
        borderRadius: BorderRadius.circular(
          isDesktop
              ? 16
              : isTablet
              ? 14
              : 12,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          isDesktop
              ? 32.0
              : isTablet
              ? 24.0
              : 16.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size:
                  isDesktop
                      ? 64
                      : isTablet
                      ? 56
                      : 48,
              color: Colors.grey[400],
            ),
            SizedBox(
              height:
                  isDesktop
                      ? 16
                      : isTablet
                      ? 14
                      : 12,
            ),
            Text(
              'Select a customer from the left to continue',
              style: TextStyle(
                fontSize:
                    isDesktop
                        ? 18
                        : isTablet
                        ? 16
                        : 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Customer selectedCustomer;
  final TextEditingController amountCtrl;
  final TextEditingController dateCtrl;
  final PaymentType? paymentType;
  final void Function(PaymentType?) onPaymentTypeChanged;
  final VoidCallback onPickDate;
  final VoidCallback onSubmit;
  final DateTime? selectedDate;
  final bool isDesktop;
  final bool isTablet;
  final bool isMobile;
  final bool isFullScreen; // New parameter for mobile full screen

  const _PaymentForm({
    required this.formKey,
    required this.selectedCustomer,
    required this.amountCtrl,
    required this.dateCtrl,
    required this.paymentType,
    required this.onPaymentTypeChanged,
    required this.onPickDate,
    required this.onSubmit,
    required this.selectedDate,
    this.isDesktop = false,
    this.isTablet = false,
    this.isMobile = false,
    this.isFullScreen = false, // New parameter for mobile full screen
    super.key,
  });

  @override
  State<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<_PaymentForm> {
  @override
  void initState() {
    super.initState();
    if (widget.selectedDate == null && widget.dateCtrl.text.isEmpty) {
      final today = DateTime.now();
      widget.dateCtrl.text = _formatDate(today);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: widget.formKey,
      child: Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            widget.isDesktop
                ? 16
                : widget.isTablet
                ? 14
                : 12,
          ),
          border: Border.all(color: Colors.black12, width: 1),
          boxShadow:
              widget.isDesktop
                  ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ]
                  : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            widget.isDesktop
                ? 16
                : widget.isTablet
                ? 14
                : 12,
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              children: [
                // Scrollable form content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                      widget.isDesktop
                          ? 0
                          : widget.isTablet
                          ? 24
                          : 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPaymentRestrictionNotice(cs),
                        if (_isPaymentAllowed == false)
                          SizedBox(
                            height:
                                widget.isDesktop
                                    ? 32
                                    : widget.isTablet
                                    ? 24
                                    : 16,
                          ),
                        _buildCustomerHeader(cs, isDark),
                        SizedBox(
                          height:
                              widget.isDesktop
                                  ? 32
                                  : widget.isTablet
                                  ? 24
                                  : 16,
                        ),
                        _buildSchemeInfo(cs),
                        SizedBox(
                          height:
                              widget.isDesktop
                                  ? 32
                                  : widget.isTablet
                                  ? 24
                                  : 16,
                        ),
                        _buildFormFields(cs, isDark),

                        // Add extra space for mobile full screen
                        if (widget.isFullScreen)
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.1,
                          ),
                      ],
                    ),
                  ),
                ),

                // Fixed bottom button
                Container(
                  padding: EdgeInsets.fromLTRB(20, 5, 20, 10),
                  decoration:
                      widget.isFullScreen
                          ? BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          )
                          : null,
                  child: _buildSubmitButton(cs, isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerHeader(ColorScheme cs, bool isDark) {
    return Container(
      padding: EdgeInsets.all(
        widget.isDesktop
            ? 24
            : widget.isTablet
            ? 20
            : 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kPrimaryColor.withOpacity(0.4),
            kPrimaryColor.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          widget.isDesktop
              ? 16
              : widget.isTablet
              ? 14
              : 12,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child:
          widget.isMobile || widget.isFullScreen
              ? Column(
                children: [
                  Row(
                    children: [
                      Avatar(
                        name: widget.selectedCustomer.name,
                        size: 24,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.selectedCustomer.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: cs.onSurface,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.selectedCustomer.phone,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kBlueColor, kBlueColor.withOpacity(0.6)],
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 16,
                          color: cs.onTertiary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '₹${widget.selectedCustomer.schemeAmount.toStringAsFixed(0)}/mo',
                          style: TextStyle(
                            color: cs.onTertiary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
              : Row(
                children: [
                  Avatar(
                    name: widget.selectedCustomer.name,
                    size: widget.isDesktop ? 32 : 28,
                    color: Colors.black,
                  ),
                  SizedBox(width: widget.isDesktop ? 20 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.selectedCustomer.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize:
                                widget.isDesktop
                                    ? 22
                                    : widget.isTablet
                                    ? 20
                                    : 18,
                            color: cs.onSurface,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: widget.isDesktop ? 8 : 6),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: widget.isDesktop ? 18 : 16,
                              color: cs.onSurfaceVariant,
                            ),
                            SizedBox(width: widget.isDesktop ? 8 : 6),
                            Text(
                              widget.selectedCustomer.phone,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize:
                                    widget.isDesktop
                                        ? 16
                                        : widget.isTablet
                                        ? 14
                                        : 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal:
                          widget.isDesktop
                              ? 20
                              : widget.isTablet
                              ? 16
                              : 12,
                      vertical:
                          widget.isDesktop
                              ? 12
                              : widget.isTablet
                              ? 10
                              : 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kBlueColor, kBlueColor.withOpacity(0.6)],
                      ),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: cs.tertiary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          size:
                              widget.isDesktop
                                  ? 18
                                  : widget.isTablet
                                  ? 16
                                  : 14,
                          color: cs.onTertiary,
                        ),
                        SizedBox(width: widget.isDesktop ? 8 : 6),
                        Text(
                          '₹${widget.selectedCustomer.schemeAmount.toStringAsFixed(0)}/mo',
                          style: TextStyle(
                            color: cs.onTertiary,
                            fontWeight: FontWeight.w700,
                            fontSize:
                                widget.isDesktop
                                    ? 14
                                    : widget.isTablet
                                    ? 12
                                    : 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildSchemeInfo(ColorScheme cs) {
    final startDate = widget.selectedCustomer.date;
    final nextPayableDate = widget.selectedCustomer.emaidate;

    return Container(
      padding: EdgeInsets.all(
        widget.isDesktop
            ? 20
            : widget.isTablet
            ? 16
            : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          widget.isDesktop
              ? 16
              : widget.isTablet
              ? 14
              : 12,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  widget.isDesktop
                      ? 12
                      : widget.isTablet
                      ? 10
                      : 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kPrimaryColor.withOpacity(0.3),
                      Colors.black.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(
                    widget.isDesktop
                        ? 14
                        : widget.isTablet
                        ? 12
                        : 10,
                  ),
                ),
                child: Icon(
                  Icons.event_available_rounded,
                  color: kPrimaryColor,
                  size:
                      widget.isDesktop
                          ? 24
                          : widget.isTablet
                          ? 20
                          : 18,
                ),
              ),
              SizedBox(
                width:
                    widget.isDesktop
                        ? 16
                        : widget.isTablet
                        ? 14
                        : 12,
              ),
              Expanded(
                child: Text(
                  'Scheme started : ${_formatDate(startDate)}',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize:
                        widget.isDesktop
                            ? 16
                            : widget.isTablet
                            ? 14
                            : 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height:
                widget.isDesktop
                    ? 16
                    : widget.isTablet
                    ? 14
                    : 12,
          ),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  widget.isDesktop
                      ? 12
                      : widget.isTablet
                      ? 10
                      : 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kPrimaryColor.withOpacity(0.3),
                      Colors.black.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(
                    widget.isDesktop
                        ? 14
                        : widget.isTablet
                        ? 12
                        : 10,
                  ),
                ),
                child: Icon(
                  Icons.payment_rounded,
                  color: kBlueColor,
                  size:
                      widget.isDesktop
                          ? 24
                          : widget.isTablet
                          ? 20
                          : 18,
                ),
              ),
              SizedBox(
                width:
                    widget.isDesktop
                        ? 16
                        : widget.isTablet
                        ? 14
                        : 12,
              ),
              Expanded(
                child: Text(
                  'Next Due date : ${_formatDate(nextPayableDate)}',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize:
                        widget.isDesktop
                            ? 16
                            : widget.isTablet
                            ? 14
                            : 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(ColorScheme cs, bool isDark) {
    return Column(
      children: [
        _buildAnimatedTextField(
          controller: widget.amountCtrl,
          label: 'Amount',
          hint: 'Enter amount',
          readOnly: true,
          prefixIcon: Icons.currency_rupee_rounded,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Amount is required';
            final value = double.tryParse(v);
            if (value == null || value <= 0) return 'Enter a valid amount';
            return null;
          },
          cs: cs,
          isDark: isDark,
        ),
        SizedBox(
          height:
              widget.isDesktop
                  ? 20
                  : widget.isTablet
                  ? 16
                  : 12,
        ),
        _buildAnimatedTextField(
          controller: widget.dateCtrl,
          label: 'Payment Date',
          hint: 'Select date',
          prefixIcon: Icons.calendar_today_rounded,
          readOnly: true,
          onTap: widget.onPickDate,
          validator:
              (v) => (v == null || v.isEmpty) ? 'Please pick a date' : null,
          cs: cs,
          isDark: isDark,
        ),
        SizedBox(
          height:
              widget.isDesktop
                  ? 20
                  : widget.isTablet
                  ? 16
                  : 12,
        ),
        _buildPaymentTypeDropdown(cs, isDark),
      ],
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    IconData? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    required ColorScheme cs,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          widget.isDesktop
              ? 18
              : widget.isTablet
              ? 16
              : 14,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize:
                  widget.isDesktop
                      ? 16
                      : widget.isTablet
                      ? 14
                      : 12,
            ),
          ),
          SizedBox(
            height:
                widget.isDesktop
                    ? 8
                    : widget.isTablet
                    ? 6
                    : 4,
          ),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            readOnly: readOnly,
            onTap: onTap,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize:
                  widget.isDesktop
                      ? 16
                      : widget.isTablet
                      ? 15
                      : 14,
            ),
            decoration: InputDecoration(
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              hintText: hint,
              prefixIcon: Container(
                margin: EdgeInsets.all(
                  widget.isDesktop
                      ? 12
                      : widget.isTablet
                      ? 10
                      : 8,
                ),
                padding: EdgeInsets.all(
                  widget.isDesktop
                      ? 12
                      : widget.isTablet
                      ? 10
                      : 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kPrimaryColor.withOpacity(0.3),
                      Colors.black.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(
                    widget.isDesktop
                        ? 14
                        : widget.isTablet
                        ? 12
                        : 10,
                  ),
                ),
                child: Icon(
                  prefixIcon,
                  color: kPrimaryColor,
                  size:
                      widget.isDesktop
                          ? 22
                          : widget.isTablet
                          ? 20
                          : 18,
                ),
              ),
              suffixIcon:
                  suffixIcon != null
                      ? Icon(suffixIcon, color: cs.onSurfaceVariant)
                      : null,
              filled: true,
              fillColor:
                  isDark
                      ? cs.surface.withOpacity(0.8)
                      : Colors.grey.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  widget.isDesktop
                      ? 18
                      : widget.isTablet
                      ? 16
                      : 14,
                ),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  widget.isDesktop
                      ? 18
                      : widget.isTablet
                      ? 16
                      : 14,
                ),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  widget.isDesktop
                      ? 18
                      : widget.isTablet
                      ? 16
                      : 14,
                ),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  widget.isDesktop
                      ? 18
                      : widget.isTablet
                      ? 16
                      : 14,
                ),
                borderSide: BorderSide.none,
              ),
              labelStyle: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize:
                    widget.isDesktop
                        ? 16
                        : widget.isTablet
                        ? 14
                        : 12,
              ),
              hintStyle: TextStyle(
                color: cs.onSurfaceVariant.withOpacity(0.6),
                fontSize:
                    widget.isDesktop
                        ? 16
                        : widget.isTablet
                        ? 14
                        : 12,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal:
                    widget.isDesktop
                        ? 20
                        : widget.isTablet
                        ? 16
                        : 12,
                vertical:
                    widget.isDesktop
                        ? 20
                        : widget.isTablet
                        ? 16
                        : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeDropdown(ColorScheme cs, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          widget.isDesktop
              ? 18
              : widget.isTablet
              ? 16
              : 14,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Type',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize:
                  widget.isDesktop
                      ? 16
                      : widget.isTablet
                      ? 14
                      : 12,
            ),
          ),
          SizedBox(
            height:
                widget.isDesktop
                    ? 8
                    : widget.isTablet
                    ? 6
                    : 4,
          ),
          FormField<PaymentType>(
            initialValue: widget.paymentType ?? PaymentType.offline,
            validator:
                (value) => value == null ? 'Please select payment type' : null,
            builder: (FormFieldState<PaymentType> field) {
              return InputDecorator(
                decoration: InputDecoration(
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  prefixIcon: Container(
                    margin: EdgeInsets.all(
                      widget.isDesktop
                          ? 12
                          : widget.isTablet
                          ? 10
                          : 8,
                    ),
                    padding: EdgeInsets.all(
                      widget.isDesktop
                          ? 12
                          : widget.isTablet
                          ? 10
                          : 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          kPrimaryColor.withOpacity(0.3),
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        widget.isDesktop
                            ? 14
                            : widget.isTablet
                            ? 12
                            : 10,
                      ),
                    ),
                    child: Icon(
                      Icons.payment_rounded,
                      color: kPrimaryColor,
                      size:
                          widget.isDesktop
                              ? 22
                              : widget.isTablet
                              ? 20
                              : 18,
                    ),
                  ),
                  filled: true,
                  fillColor:
                      isDark
                          ? cs.surface.withOpacity(0.8)
                          : Colors.grey.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      widget.isDesktop
                          ? 18
                          : widget.isTablet
                          ? 16
                          : 14,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      widget.isDesktop
                          ? 18
                          : widget.isTablet
                          ? 16
                          : 14,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      widget.isDesktop
                          ? 18
                          : widget.isTablet
                          ? 16
                          : 14,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      widget.isDesktop
                          ? 18
                          : widget.isTablet
                          ? 16
                          : 14,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  labelStyle: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal:
                        widget.isDesktop
                            ? 20
                            : widget.isTablet
                            ? 16
                            : 12,
                    vertical:
                        widget.isDesktop
                            ? 20
                            : widget.isTablet
                            ? 16
                            : 12,
                  ),
                  errorText: field.errorText,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<PaymentType>(
                    value: field.value,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(30),
                    hint: Text(
                      'Select payment type',
                      style: TextStyle(
                        color: cs.onSurfaceVariant.withOpacity(0.6),
                        fontSize:
                            widget.isDesktop
                                ? 16
                                : widget.isTablet
                                ? 14
                                : 12,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: PaymentType.offline,
                        child: Row(
                          children: [
                            Icon(
                              Icons.offline_bolt_rounded,
                              size:
                                  widget.isDesktop
                                      ? 20
                                      : widget.isTablet
                                      ? 18
                                      : 16,
                              color: cs.secondary,
                            ),
                            SizedBox(
                              width:
                                  widget.isDesktop
                                      ? 12
                                      : widget.isTablet
                                      ? 10
                                      : 8,
                            ),
                            Text(
                              'Offline',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize:
                                    widget.isDesktop
                                        ? 16
                                        : widget.isTablet
                                        ? 14
                                        : 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: PaymentType.online,
                        child: Row(
                          children: [
                            Icon(
                              Icons.wifi_rounded,
                              size:
                                  widget.isDesktop
                                      ? 20
                                      : widget.isTablet
                                      ? 18
                                      : 16,
                              color: cs.secondary,
                            ),
                            SizedBox(
                              width:
                                  widget.isDesktop
                                      ? 12
                                      : widget.isTablet
                                      ? 10
                                      : 8,
                            ),
                            Text(
                              'Online',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize:
                                    widget.isDesktop
                                        ? 16
                                        : widget.isTablet
                                        ? 14
                                        : 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (PaymentType? newValue) {
                      field.didChange(newValue);
                      widget.onPaymentTypeChanged(newValue);
                    },
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize:
                          widget.isDesktop
                              ? 16
                              : widget.isTablet
                              ? 14
                              : 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ColorScheme cs, bool isDark) {
    return AbsorbPointer(
      absorbing: !_isPaymentAllowed,
      child: Opacity(
        opacity: _isPaymentAllowed ? 1.0 : 0.5,
        child: Container(
          width: double.infinity,
          height:
              widget.isDesktop
                  ? 40
                  : widget.isTablet
                  ? 40
                  : 37,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  _isPaymentAllowed
                      ? [kBlueColor, kBlueColor.withOpacity(0.8)]
                      : [Colors.grey, Colors.grey.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(
              widget.isDesktop
                  ? 18
                  : widget.isTablet
                  ? 16
                  : 14,
            ),
            boxShadow:
                _isPaymentAllowed && widget.isDesktop
                    ? [
                      BoxShadow(
                        color: cs.primary.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 1,
                        offset: const Offset(0, 8),
                      ),
                    ]
                    : [],
          ),
          child: ElevatedButton(
            onPressed:
                _isPaymentAllowed
                    ? () {
                      FocusScope.of(context).unfocus();
                      widget.onSubmit();
                    }
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  widget.isDesktop
                      ? 18
                      : widget.isTablet
                      ? 16
                      : 14,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isPaymentAllowed
                      ? Icons.check_circle_rounded
                      : Icons.schedule,
                  color: _isPaymentAllowed ? cs.onPrimary : Colors.grey[600],
                  size:
                      widget.isDesktop
                          ? 24
                          : widget.isTablet
                          ? 22
                          : 20,
                ),
                SizedBox(
                  width:
                      widget.isDesktop
                          ? 16
                          : widget.isTablet
                          ? 12
                          : 8,
                ),
                Text(
                  _isPaymentAllowed
                      ? 'Submit Payment'
                      : 'Payment Not Available',
                  style: TextStyle(
                    color: _isPaymentAllowed ? cs.onPrimary : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize:
                        widget.isDesktop
                            ? 18
                            : widget.isTablet
                            ? 16
                            : 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _isPaymentAllowed {
    if (widget.selectedCustomer.emaidate == null) return true;
    final now = DateTime.now();
    final twentyDaysBefore = widget.selectedCustomer.emaidate!.subtract(
      const Duration(days: 20),
    );
    return now.isAfter(twentyDaysBefore) ||
        now.isAtSameMomentAs(twentyDaysBefore);
  }

  Widget _buildPaymentRestrictionNotice(ColorScheme cs) {
    if (_isPaymentAllowed) return const SizedBox.shrink();

    final emiDate = widget.selectedCustomer.emaidate!;
    final allowedDate = emiDate.subtract(const Duration(days: 20));

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical:
            widget.isDesktop
                ? 16
                : widget.isTablet
                ? 14
                : 12,
        horizontal:
            widget.isDesktop
                ? 20
                : widget.isTablet
                ? 16
                : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(.1),
        borderRadius: BorderRadius.circular(
          widget.isDesktop
              ? 16
              : widget.isTablet
              ? 14
              : 12,
        ),
        //border: Border.all(color: kPrimaryColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            color: kErrorRedColor,
            size:
                widget.isDesktop
                    ? 24
                    : widget.isTablet
                    ? 22
                    : 20,
          ),
          SizedBox(
            width:
                widget.isDesktop
                    ? 12
                    : widget.isTablet
                    ? 10
                    : 8,
          ),
          Expanded(
            child: Text(
              'Payment can be made from ${_formatDate(allowedDate)} onwards',
              style: TextStyle(
                color: kErrorRedColor,
                fontWeight: FontWeight.w600,
                fontSize:
                    widget.isDesktop
                        ? 16
                        : widget.isTablet
                        ? 14
                        : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  }
}

// [PaymentDetails class remains the same]
class PaymentDetails {
  final Customer customer;
  final double amount;
  final PaymentType paymentType;
  final DateTime paymentDate;
  final Map<String, dynamic>? apiResponse;

  PaymentDetails({
    required this.customer,
    required this.amount,
    required this.paymentType,
    required this.paymentDate,
    this.apiResponse,
  });
}

// [SuccessScreen class remains the same]
class SuccessScreen extends StatelessWidget {
  final PaymentDetails details;
  const SuccessScreen({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final apiData = details.apiResponse;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Success')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 1024;
          final isTablet =
              constraints.maxWidth >= 600 && constraints.maxWidth <= 1024;

          return Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth:
                    isDesktop
                        ? 600
                        : isTablet
                        ? 500
                        : double.infinity,
              ),
              child: Padding(
                padding: EdgeInsets.all(
                  isDesktop
                      ? 32.0
                      : isTablet
                      ? 24.0
                      : 16.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.verified,
                      size:
                          isDesktop
                              ? 120
                              : isTablet
                              ? 96
                              : 80,
                      color: cs.primary,
                    ),
                    SizedBox(
                      height:
                          isDesktop
                              ? 24
                              : isTablet
                              ? 20
                              : 16,
                    ),
                    Text(
                      'Payment Successful!',
                      style: TextStyle(
                        fontSize:
                            isDesktop
                                ? 32
                                : isTablet
                                ? 28
                                : 24,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height:
                          isDesktop
                              ? 20
                              : isTablet
                              ? 16
                              : 12,
                    ),

                    // Customer info
                    Text(
                      'Customer: ${details.customer.name}',
                      style: TextStyle(
                        fontSize:
                            isDesktop
                                ? 20
                                : isTablet
                                ? 18
                                : 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Phone: ${details.customer.phone}',
                      style: TextStyle(
                        fontSize:
                            isDesktop
                                ? 16
                                : isTablet
                                ? 15
                                : 14,
                      ),
                    ),
                    SizedBox(
                      height:
                          isDesktop
                              ? 16
                              : isTablet
                              ? 14
                              : 12,
                    ),

                    // Payment details
                    Text(
                      'Amount: ₹${details.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize:
                            isDesktop
                                ? 16
                                : isTablet
                                ? 15
                                : 14,
                      ),
                    ),
                    Text(
                      'Payment Type: ${details.paymentType == PaymentType.online ? 'Online' : 'Offline'}',
                      style: TextStyle(
                        fontSize:
                            isDesktop
                                ? 16
                                : isTablet
                                ? 15
                                : 14,
                      ),
                    ),
                    Text(
                      'Date: ${_formatDate(details.paymentDate)}',
                      style: TextStyle(
                        fontSize:
                            isDesktop
                                ? 16
                                : isTablet
                                ? 15
                                : 14,
                      ),
                    ),

                    // API response details
                    if (apiData != null) ...[
                      SizedBox(
                        height:
                            isDesktop
                                ? 24
                                : isTablet
                                ? 20
                                : 16,
                      ),
                      if (apiData['message'] != null)
                        Text(
                          apiData['message'],
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w500,
                            fontSize:
                                isDesktop
                                    ? 18
                                    : isTablet
                                    ? 16
                                    : 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      if (apiData['nextDueDate'] != null)
                        Text(
                          'Next Due Date: ${apiData['nextDueDate']}',
                          style: TextStyle(
                            fontSize:
                                isDesktop
                                    ? 16
                                    : isTablet
                                    ? 15
                                    : 14,
                          ),
                        ),
                    ],

                    SizedBox(
                      height:
                          isDesktop
                              ? 48
                              : isTablet
                              ? 40
                              : 32,
                    ),
                    SizedBox(
                      width: double.infinity,
                      height:
                          isDesktop
                              ? 56
                              : isTablet
                              ? 48
                              : 44,
                      child: FilledButton(
                        onPressed:
                            () => Navigator.of(
                              context,
                            ).popUntil((r) => r.isFirst),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              isDesktop
                                  ? 16
                                  : isTablet
                                  ? 14
                                  : 12,
                            ),
                          ),
                        ),
                        child: Text(
                          'Done',
                          style: TextStyle(
                            fontSize:
                                isDesktop
                                    ? 18
                                    : isTablet
                                    ? 16
                                    : 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  }
}
