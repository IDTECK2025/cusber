import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gold_pos/customer/payment_screen_customer.dart';
import 'package:gold_pos/models/customer_model.dart';
import 'package:gold_pos/utils/avathar.dart';
import 'package:gold_pos/utils/colors.dart';

class PaymentForm extends StatefulWidget {
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

  const PaymentForm({
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
  State<PaymentForm> createState() => PaymentFormState();
}

class PaymentFormState extends State<PaymentForm> {
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
          child: Column(
            children: [
              // Scrollable form content
              Expanded(
                child: SingleChildScrollView(
                  physics: ClampingScrollPhysics(),
                  padding: EdgeInsets.all(
                    widget.isDesktop
                        ? 26
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
                      // if (widget.isFullScreen)
                      //   SizedBox(
                      //     height: MediaQuery.of(context).size.height * 0.1,
                      //   ),
                    ],
                  ),
                ),
              ),

              // Fixed bottom button
              Container(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
                decoration:
                    widget.isFullScreen
                        ? BoxDecoration(
                          color: Colors.white,
                          // boxShadow: [
                          //   BoxShadow(
                          //     color: Colors.black.withOpacity(0.1),
                          //     blurRadius: 10,
                          //     offset: const Offset(0, -2),
                          //   ),
                          // ],
                        )
                        : null,
                child: _buildSubmitButton(cs, isDark),
              ),
            ],
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
                      borderRadius: BorderRadius.circular(10),
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
                          '${widget.selectedCustomer.schemeAmount.toStringAsFixed(0)}/mo',
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
                          '${widget.selectedCustomer.schemeAmount.toStringAsFixed(0)}/mo',
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
      const Duration(days: 320),
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
