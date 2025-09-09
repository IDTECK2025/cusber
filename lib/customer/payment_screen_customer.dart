import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class Customer {
  final String id;
  final String name;
  final String phone;
  final DateTime schemeStartDate;
  final DateTime nextPayableDate;
  final double schemeAmount;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.schemeStartDate,
    required this.nextPayableDate,
    required this.schemeAmount,
  });
}

enum PaymentType { online, offline }

class CustomerPaymentScreen extends StatefulWidget {
  const CustomerPaymentScreen({super.key});

  @override
  State<CustomerPaymentScreen> createState() => _CustomerPaymentScreenState();
}

class _CustomerPaymentScreenState extends State<CustomerPaymentScreen> {
  // Mock data; replace with your API results
  final List<Customer> _allCustomers = [
    Customer(
      id: 'C001',
      name: 'Aarav Sharma',
      phone: '9876543210',
      schemeStartDate: DateTime(2025, 1, 15),
      nextPayableDate: DateTime(2025, 2, 15),
      schemeAmount: 1000,
    ),
    Customer(
      id: 'C002',
      name: 'Diya Nair',
      phone: '9123456780',
      schemeStartDate: DateTime(2025, 3, 1),
      nextPayableDate: DateTime(2025, 4, 1),
      schemeAmount: 1500,
    ),
    Customer(
      id: 'C003',
      name: 'Rahul Kumar',
      phone: '9000000001',
      schemeStartDate: DateTime(2024, 12, 5),
      nextPayableDate: DateTime(2025, 1, 5),
      schemeAmount: 2000,
    ),
  ];

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
    // Initialize with default values to prevent null errors
    _paymentType = PaymentType.offline;
    _selectedDate = DateTime.now();
    _dateCtrl.text = _formatDate(DateTime.now());
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

  void _onSubmit() {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer.')),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Ensure all required values are not null before creating PaymentDetails
    if (_paymentType == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }

    final details = PaymentDetails(
      customer: _selectedCustomer!,
      amount: double.parse(_amountCtrl.text),
      paymentType: _paymentType!,
      paymentDate: _selectedDate!,
    );

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => SuccessScreen(details: details)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Field
            SizedBox(
              height: 40,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFE5E7EB)),
                      ),
                      child: TextField(
                        cursorColor: kPrimaryColor,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Search customer name or phone',
                          hintStyle: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 12,
                          ),
                          border: InputBorder.none,
                          icon: Icon(
                            Icons.search,
                            size: 16,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.reset_tv,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'return bill',
                          style: TextStyle(
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Results List
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: customer list
                  Expanded(
                    flex: 7,
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.black12),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child:
                          _filteredCustomers.isEmpty
                              ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: Text('No customers found'),
                                ),
                              )
                              : ListView.separated(
                                itemCount: _filteredCustomers.length,
                                separatorBuilder:
                                    (_, _) => Divider(
                                      height: 1,
                                      color: Colors.black12,
                                    ),
                                itemBuilder: (context, index) {
                                  final c = _filteredCustomers[index];
                                  final isSelected =
                                      _selectedCustomer?.id == c.id;
                                  return ListTile(
                                    leading: Avatar(name: c.name),
                                    title: Text(
                                      c.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isSelected
                                                ? kPrimaryColor
                                                : Colors.black,
                                      ),
                                    ),
                                    subtitle: Text(
                                      c.phone,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                    trailing:
                                        isSelected
                                            ? Icon(
                                              Icons.check_circle,
                                              color: kPrimaryColor,
                                            )
                                            : const Icon(Icons.chevron_right),
                                    selected: isSelected,
                                    onTap: () {
                                      setState(() {
                                        _selectedCustomer = c;
                                        _amountCtrl.text = c.schemeAmount
                                            .toStringAsFixed(0);
                                      });
                                    },
                                  );
                                },
                              ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Right: details + form
                  Expanded(
                    flex: 10,
                    child:
                        _selectedCustomer == null
                            ? _HintPanel()
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
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HintPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.black12),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            Icon(Icons.person_search, size: 48),
            SizedBox(height: 12),
            Text(
              'Select a customer from the left to continue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
    super.key,
  });

  @override
  State<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<_PaymentForm> {
  @override
  void initState() {
    super.initState();
    // Set today's date as default if no date is selected
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
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.black12, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              children: [
                // Scrollable form content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCustomerHeader(cs, isDark),
                        const SizedBox(height: 24),
                        _buildSchemeInfo(cs),
                        const SizedBox(height: 24),
                        _buildFormFields(cs, isDark),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // Fixed bottom button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kPrimaryColor.withOpacity(0.4),
            kPrimaryColor.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Avatar(
            name: widget.selectedCustomer.name,
            size: 30,
            color: Colors.black,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedCustomer.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: cs.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.phone_rounded,
                      size: 16,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.selectedCustomer.phone,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
      ),
    );
  }

  Widget _buildSchemeInfo(ColorScheme cs) {
    final startDate = widget.selectedCustomer.schemeStartDate;
    final nextPayableDate = widget.selectedCustomer.nextPayableDate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kPrimaryColor.withOpacity(0.3),
                      Colors.black.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.event_available_rounded,
                  color: kPrimaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Scheme started: ${_formatDate(startDate)}',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kPrimaryColor.withOpacity(0.3),
                      Colors.black.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.payment_rounded, color: kBlueColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Next payable date: ${_formatDate(nextPayableDate)}',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
        const SizedBox(height: 10),
        _buildAnimatedTextField(
          controller: widget.dateCtrl,
          label: 'Payment Date',
          hint: 'Select date',
          prefixIcon: Icons.calendar_today_rounded,
          //suffixIcon: Icons.expand_more_rounded,
          readOnly: true,
          //onTap: widget.onPickDate,
          validator:
              (v) => (v == null || v.isEmpty) ? 'Please pick a date' : null,
          cs: cs,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
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
        borderRadius: BorderRadius.circular(16),
        // boxShadow: [
        //   BoxShadow(
        //     color: cs.shadow.withOpacity(0.04),
        //     blurRadius: 10,
        //     offset: const Offset(0, 2),
        //   ),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 3),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            readOnly: readOnly,
            onTap: onTap,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            decoration: InputDecoration(
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              hintText: hint,
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      kPrimaryColor.withOpacity(0.3),
                      Colors.black.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(prefixIcon, color: kPrimaryColor, size: 20),
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
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              labelStyle: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              hintStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.6)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypeDropdown(ColorScheme cs, bool isDark) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Type',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 3),
          FormField<PaymentType>(
            initialValue: widget.paymentType ?? PaymentType.offline,
            validator:
                (value) => value == null ? 'Please select payment type' : null,
            builder: (FormFieldState<PaymentType> field) {
              return InputDecorator(
                decoration: InputDecoration(
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  //labelText: 'Payment Type',
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          kPrimaryColor.withOpacity(0.3),
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.payment_rounded,
                      color: kPrimaryColor,
                      size: 20,
                    ),
                  ),
                  filled: true,
                  fillColor:
                      isDark
                          ? cs.surface.withOpacity(0.8)
                          : Colors.grey.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  labelStyle: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
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
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: PaymentType.offline,
                        child: Row(
                          children: [
                            Icon(
                              Icons.offline_bolt_rounded,
                              size: 16,
                              color: cs.secondary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Offline',
                              style: TextStyle(fontWeight: FontWeight.w600),
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
                              size: 16,
                              color: cs.secondary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Online',
                              style: TextStyle(fontWeight: FontWeight.w600),
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
                      fontSize: 16,
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
    return Container(
      width: double.infinity,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kBlueColor, kBlueColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          FocusScope.of(context).unfocus();
          widget.onSubmit();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: cs.onPrimary, size: 22),
            const SizedBox(width: 12),
            Text(
              'Submit Payment',
              style: TextStyle(
                color: cs.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  }
}

class PaymentDetails {
  final Customer customer;
  final double amount;
  final PaymentType paymentType;
  final DateTime paymentDate;

  PaymentDetails({
    required this.customer,
    required this.amount,
    required this.paymentType,
    required this.paymentDate,
  });
}

class SuccessScreen extends StatelessWidget {
  final PaymentDetails details;
  const SuccessScreen({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Success')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.verified, size: 96, color: cs.primary),
              const SizedBox(height: 16),
              const Text(
                'Payment Saved Successfully',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Customer: ${details.customer.name} (${details.customer.phone})',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text('Amount: ₹${details.amount.toStringAsFixed(0)}'),
              const SizedBox(height: 4),
              Text(
                'Payment Type: ${details.paymentType == PaymentType.online ? 'Online' : 'Offline'}',
              ),
              const SizedBox(height: 4),
              Text('Date: ${_formatDate(details.paymentDate)}'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                      () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  }
}
