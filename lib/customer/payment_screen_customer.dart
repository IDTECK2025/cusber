import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gold_pos/api.dart';
import 'package:gold_pos/auth_helper.dart';
import 'package:gold_pos/customer/payment_form.dart';
import 'package:gold_pos/models/customer_model.dart';
import 'package:gold_pos/utils/diamond_indicator.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' show ImageFilter;
import '../../utils/avathar.dart';
import '../../utils/colors.dart';
import 'mobile_payment_screen.dart';
import 'success_screen.dart';
import 'package:lottie/lottie.dart';

enum PaymentType { online, offline }

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

// PaymentService class
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
  Timer? _refreshTimer;

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
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadCustomers();
      }
    });
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
    _refreshTimer?.cancel();
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomers();
    });
  }

  Future<void> _refreshCustomerData(String customerId) async {
    try {
      await _loadCustomers();

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
      await _loadCustomers();
    }
  }

  // Enhanced submit function with confirmation dialog
  void _onSubmitWithConfirmation() async {
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

    // Check payment date restrictions
    if (_selectedCustomer!.emaidate != null) {
      final now = DateTime.now();
      final nextPayableDate = _selectedCustomer!.emaidate!;
      final twentyDaysBefore = DateTime(
        nextPayableDate.year,
        nextPayableDate.month,
        nextPayableDate.day - 320,
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

    // Show confirmation dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => PaymentConfirmationDialog(
            customer: _selectedCustomer!,
            amount: double.parse(_amountCtrl.text),
            paymentType: _paymentType!,
            paymentDate: _selectedDate!,
            formattedDate: _formatDate(_selectedDate!),
            onConfirm: () => _processPayment(),
          ),
    );
  }

  void _processPayment() async {
    // Show processing dialog with animation
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PaymentProcessingDialog(),
    );

    if (result == true) {
      // Make actual API call
      try {
        final emiDate = _selectedCustomer!.emaidate ?? _selectedDate!;
        final month =
            '${emiDate.year}-${emiDate.month.toString().padLeft(2, '0')}';

        final apiResult = await PaymentService.makePayment(
          customerId: _selectedCustomer!.id,
          amount: double.parse(_amountCtrl.text),
          month: month,
        );

        if (apiResult['success']) {
          final details = PaymentDetails(
            customer: _selectedCustomer!,
            amount: double.parse(_amountCtrl.text),
            paymentType: _paymentType!,
            paymentDate: _selectedDate!,
            apiResponse: apiResult['data'],
          );

          // Navigate to enhanced success screen
          // In both MobilePaymentScreen and CustomerPaymentScreen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder:
                  (_) => EnhancedSuccessScreen(
                    details: details,
                    onReturn: () {
                      // Refresh customer data
                      _loadCustomers();
                      if (_selectedCustomer != null) {
                        _refreshCustomerData(_selectedCustomer!.id);
                      }
                    },
                  ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: ${apiResult['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      return _buildMobileCustomerList();
    } else {
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
              ? const Center(child: DiamondIndicator(size: 8))
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
                  : PaymentForm(
                    formKey: _formKey,
                    selectedCustomer: _selectedCustomer!,
                    amountCtrl: _amountCtrl,
                    dateCtrl: _dateCtrl,
                    paymentType: _paymentType,
                    onPaymentTypeChanged:
                        (pt) => setState(() => _paymentType = pt),
                    onPickDate: _pickDate,
                    onSubmit: _onSubmitWithConfirmation,
                    selectedDate: _selectedDate,
                    isDesktop: isDesktop,
                    isTablet: isTablet,
                  ),
        ),
      ],
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

class PaymentConfirmationDialog extends StatefulWidget {
  final Customer customer;
  final double amount;
  final PaymentType paymentType;
  final DateTime paymentDate;
  final String formattedDate;
  final VoidCallback onConfirm;

  const PaymentConfirmationDialog({
    super.key,
    required this.customer,
    required this.amount,
    required this.paymentType,
    required this.paymentDate,
    required this.formattedDate,
    required this.onConfirm,
  });

  @override
  State<PaymentConfirmationDialog> createState() =>
      _PaymentConfirmationDialogState();
}

class _PaymentConfirmationDialogState extends State<PaymentConfirmationDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth >= 600 && screenWidth <= 1024;
    final isMobile = screenWidth < 600;

    return Dialog(
      // Remove constraints from Dialog to allow full customization
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(
        isMobile
            ? 16
            : isTablet
            ? 24
            : 32,
      ), // Control dialog margins
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          // This is the key fix - use actual width constraints
          width: isMobile ? double.infinity : (isTablet ? 450 : 500),
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : (isTablet ? 450 : 450),
            minWidth: isMobile ? 0 : (isTablet ? 400 : 450),
          ),
          padding: EdgeInsets.all(
            isDesktop
                ? 32
                : isTablet
                ? 28
                : 24,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              isDesktop
                  ? 24
                  : isTablet
                  ? 22
                  : 20,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius:
                    isDesktop
                        ? 25
                        : isTablet
                        ? 22
                        : 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon
              Container(
                width:
                    isDesktop
                        ? 80
                        : isTablet
                        ? 72
                        : 64,
                height:
                    isDesktop
                        ? 80
                        : isTablet
                        ? 72
                        : 64,
                decoration: BoxDecoration(
                  color: kBlueColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.payment,
                  size:
                      isDesktop
                          ? 40
                          : isTablet
                          ? 36
                          : 32,
                  color: kBlueColor,
                ),
              ),
              SizedBox(
                height:
                    isDesktop
                        ? 24
                        : isTablet
                        ? 20
                        : 16,
              ),

              // Title
              Text(
                'Confirm Payment',
                style: TextStyle(
                  fontSize:
                      isDesktop
                          ? 28
                          : isTablet
                          ? 26
                          : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(
                height:
                    isDesktop
                        ? 12
                        : isTablet
                        ? 10
                        : 8,
              ),

              Text(
                'Please review the payment details below',
                style: TextStyle(
                  fontSize:
                      isDesktop
                          ? 16
                          : isTablet
                          ? 15
                          : 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height:
                    isDesktop
                        ? 32
                        : isTablet
                        ? 28
                        : 24,
              ),

              // Customer details card
              Container(
                width: double.infinity, // Make sure card takes full width
                padding: EdgeInsets.all(
                  isDesktop
                      ? 20
                      : isTablet
                      ? 18
                      : 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(
                    isDesktop
                        ? 16
                        : isTablet
                        ? 14
                        : 12,
                  ),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Customer',
                      widget.customer.name,
                      isDesktop,
                      isTablet,
                    ),
                    SizedBox(
                      height:
                          isDesktop
                              ? 12
                              : isTablet
                              ? 10
                              : 8,
                    ),
                    _buildDetailRow(
                      'Phone',
                      widget.customer.phone,
                      isDesktop,
                      isTablet,
                    ),
                    SizedBox(
                      height:
                          isDesktop
                              ? 12
                              : isTablet
                              ? 10
                              : 8,
                    ),
                    _buildDetailRow(
                      'Amount',
                      '₹ ${widget.amount.toStringAsFixed(0)}',
                      isDesktop,
                      isTablet,
                    ),
                    SizedBox(
                      height:
                          isDesktop
                              ? 12
                              : isTablet
                              ? 10
                              : 8,
                    ),
                    _buildDetailRow(
                      'Payment Type',
                      widget.paymentType == PaymentType.online
                          ? 'Online'
                          : 'Offline',
                      isDesktop,
                      isTablet,
                    ),
                    SizedBox(
                      height:
                          isDesktop
                              ? 12
                              : isTablet
                              ? 10
                              : 8,
                    ),
                    _buildDetailRow(
                      'Date',
                      widget.formattedDate,
                      isDesktop,
                      isTablet,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height:
                    isDesktop
                        ? 32
                        : isTablet
                        ? 28
                        : 24,
              ),

              // Buttons
              SizedBox(
                width: double.infinity, // Make sure button row takes full width
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical:
                                isDesktop
                                    ? 16
                                    : isTablet
                                    ? 14
                                    : 12,
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
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
                          'Cancel',
                          style: TextStyle(
                            fontSize:
                                isDesktop
                                    ? 16
                                    : isTablet
                                    ? 17
                                    : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
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
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBlueColor,
                          padding: EdgeInsets.symmetric(
                            vertical:
                                isDesktop
                                    ? 16
                                    : isTablet
                                    ? 14
                                    : 12,
                          ),
                          elevation: 0,
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
                          'Submit',
                          style: TextStyle(
                            fontSize:
                                isDesktop
                                    ? 16
                                    : isTablet
                                    ? 17
                                    : 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    bool isDesktop,
    bool isTablet,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize:
                isDesktop
                    ? 16
                    : isTablet
                    ? 15
                    : 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize:
                  isDesktop
                      ? 16
                      : isTablet
                      ? 15
                      : 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

// Payment Processing Dialog with Lottery Animation - Responsive
class PaymentProcessingDialog extends StatefulWidget {
  const PaymentProcessingDialog({super.key});

  @override
  State<PaymentProcessingDialog> createState() =>
      _PaymentProcessingDialogState();
}

class _PaymentProcessingDialogState extends State<PaymentProcessingDialog>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _lottieController;
  bool _showCheck = false;

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _lottieController = AnimationController(
      duration: const Duration(
        seconds: 2,
      ), // Shorter duration for better timing
      vsync: this,
    );

    _startAnimation();
  }

  void _startAnimation() async {
    // Wait 2 seconds, then show check mark
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _showCheck = true;
      });

      // Start both animations simultaneously
      _checkController.forward();
      _lottieController.forward();

      // Auto close after showing success
      await Future.delayed(
        const Duration(seconds: 3),
      ); // Reduced back to 2 seconds
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth >= 600 && screenWidth <= 1024;
    final isMobile = screenWidth < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(
        isMobile
            ? 32
            : isTablet
            ? 36
            : 40,
      ),
      child: Container(
        width: isMobile ? double.infinity : (isTablet ? 350 : 400),
        padding: EdgeInsets.all(
          isDesktop
              ? 40
              : isTablet
              ? 36
              : 32,
        ),
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : (isTablet ? 350 : 400),
          minWidth: isMobile ? 0 : (isTablet ? 300 : 350),
        ),
        decoration: BoxDecoration(
          color: _showCheck ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(
            isDesktop
                ? 24
                : isTablet
                ? 22
                : 20,
          ),
          boxShadow:
              _showCheck
                  ? []
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius:
                          isDesktop
                              ? 25
                              : isTablet
                              ? 22
                              : 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height:
                  isDesktop
                      ? 160
                      : isTablet
                      ? 140
                      : 200,
              width: double.infinity,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child:
                      _showCheck
                          ? Stack(
                            alignment: Alignment.center,
                            children: [
                              Lottie.asset(
                                'assets/animation/success_confetti.json',
                                controller: _lottieController,
                                alignment: Alignment.center,
                                fit:
                                    BoxFit
                                        .cover, // Changed to contain for better centering
                                repeat: false,
                                animate: true,
                                width: double.infinity,
                                height: double.infinity,
                                // Add error handling
                                errorBuilder: (context, error, stackTrace) {
                                  return Lottie.network(
                                    'https://assets10.lottiefiles.com/packages/lf20_obhph3sh.json',
                                    controller: _lottieController,
                                    fit: BoxFit.contain,
                                    repeat: false,
                                    animate: true,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Final fallback - custom confetti animation
                                      return _buildFallbackConfetti();
                                    },
                                  );
                                },
                              ),
                              // ScaleTransition(
                              //   scale: _checkAnimation,
                              //   child: Container(
                              //     width:
                              //         isDesktop
                              //             ? 100
                              //             : isTablet
                              //             ? 90
                              //             : 90,
                              //     height:
                              //         isDesktop
                              //             ? 100
                              //             : isTablet
                              //             ? 90
                              //             : 90,
                              //     decoration: BoxDecoration(
                              //       color: kBlueColor,
                              //       shape: BoxShape.circle,
                              //       boxShadow: [
                              //         BoxShadow(
                              //           color: kBlueColor.withOpacity(0.3),
                              //           blurRadius: 10,
                              //           offset: const Offset(0, 2),
                              //         ),
                              //       ],
                              //     ),
                              //     child: Icon(
                              //       Icons.check,
                              //       color: Colors.white,
                              //       size:
                              //           isDesktop
                              //               ? 60
                              //               : isTablet
                              //               ? 55
                              //               : 50,
                              //     ),
                              //   ),
                              // ),
                            ],
                          )
                          : DiamondIndicator(
                            size:
                                isDesktop
                                    ? 16
                                    : isTablet
                                    ? 14
                                    : 12,
                          ),
                ),
              ),
            ),
            SizedBox(
              height:
                  isDesktop
                      ? 32
                      : isTablet
                      ? 28
                      : 24,
            ),

            // Status text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _showCheck ? '' : 'Processing Payment...',
                key: ValueKey(_showCheck),
                style: TextStyle(
                  fontSize:
                      isDesktop
                          ? 24
                          : isTablet
                          ? 22
                          : 20,
                  fontWeight: FontWeight.bold,
                  color: _showCheck ? kBlueColor : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            if (!_showCheck) ...[
              SizedBox(
                height:
                    isDesktop
                        ? 12
                        : isTablet
                        ? 10
                        : 8,
              ),
              Text(
                'Please wait while we process your payment',
                style: TextStyle(
                  fontSize:
                      isDesktop
                          ? 16
                          : isTablet
                          ? 15
                          : 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Fallback confetti animation if Lottie fails - CENTERED
  Widget _buildFallbackConfetti() {
    return Center(
      child: AnimatedBuilder(
        animation: _lottieController,
        builder: (context, child) {
          return SizedBox(
            width: 200, // Fixed width for centering
            height: 120, // Fixed height for centering
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(25, (index) {
                final colors = [
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                  Colors.pink,
                  Colors.yellow,
                  Colors.cyan,
                ];

                final screenWidth = MediaQuery.of(context).size.width;
                final isDesktop = screenWidth > 1024;
                final isTablet = screenWidth >= 600 && screenWidth <= 1024;

                final dotSize =
                    isDesktop
                        ? 8.0
                        : isTablet
                        ? 6.0
                        : 4.0;
                final longSize =
                    isDesktop
                        ? 16.0
                        : isTablet
                        ? 12.0
                        : 8.0;

                // Centered positioning
                final centerX = 100.0; // Half of container width (200/2)
                final centerY = 60.0; // Half of container height (120/2)
                final radius = 60.0; // Radius for circular distribution

                final angle =
                    (index / 25) * 2 * 3.14159; // Distribute evenly in circle
                final animatedRadius = radius * _lottieController.value;

                return Positioned(
                  left: centerX + (animatedRadius * math.cos(angle)),
                  top: centerY + (animatedRadius * math.sin(angle)),
                  child: Transform.rotate(
                    angle: _lottieController.value * 6.28 * (index + 1),
                    child: Container(
                      width: index % 3 == 0 ? dotSize : dotSize * 0.7,
                      height: index % 4 == 0 ? longSize : dotSize,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: colors[index % colors.length].withOpacity(
                              0.3,
                            ),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
