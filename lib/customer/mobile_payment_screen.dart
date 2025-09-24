import 'package:flutter/material.dart';
import 'package:gold_pos/customer/payment_form.dart';
import 'package:gold_pos/customer/payment_screen_customer.dart';
import 'package:gold_pos/models/customer_model.dart';
import '../../utils/colors.dart';
import 'success_screen.dart';

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

  // Enhanced submit with confirmation for mobile
  void _onSubmitWithConfirmation() async {
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
            customer: _currentCustomer!,
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
      try {
        final emiDate = _currentCustomer!.emaidate ?? _selectedDate!;
        final month =
            '${emiDate.year}-${emiDate.month.toString().padLeft(2, '0')}';

        final apiResult = await PaymentService.makePayment(
          customerId: _currentCustomer!.id,
          amount: double.parse(_amountCtrl.text),
          month: month,
        );

        if (apiResult['success']) {
          final details = PaymentDetails(
            customer: _currentCustomer!,
            amount: double.parse(_amountCtrl.text),
            paymentType: _paymentType!,
            paymentDate: _selectedDate!,
            apiResponse: apiResult['data'],
          );

          // Navigate to enhanced success screen and refresh parent
          widget.onRefreshCustomer();

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => EnhancedSuccessScreen(details: details),
            ),
          );

          if (result == true) {
            widget.onRefreshCustomer();
          }
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Payment Details',
          style: TextStyle(
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
          child: PaymentForm(
            formKey: _formKey,
            selectedCustomer: _currentCustomer!,
            amountCtrl: _amountCtrl,
            dateCtrl: _dateCtrl,
            paymentType: _paymentType,
            onPaymentTypeChanged: (pt) => setState(() => _paymentType = pt),
            onPickDate: _pickDate,
            onSubmit: _onSubmitWithConfirmation,
            selectedDate: _selectedDate,
            isMobile: true,
            isFullScreen: true,
          ),
        ),
      ),
    );
  }
}
