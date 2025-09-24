import 'package:flutter/material.dart';
import 'package:gold_pos/customer/payment_screen_customer.dart';
import '../../utils/colors.dart';

class EnhancedSuccessScreen extends StatefulWidget {
  final PaymentDetails details;

  const EnhancedSuccessScreen({super.key, required this.details});

  @override
  State<EnhancedSuccessScreen> createState() => _EnhancedSuccessScreenState();
}

class _EnhancedSuccessScreenState extends State<EnhancedSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _confettiController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start scale animation after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // Generate transaction ID (similar to the uploaded image)
  // String get transactionId {
  //   final apiData = widget.details.apiResponse;
  //   if (apiData != null && apiData['transactionId'] != null) {
  //     return apiData['transactionId'];
  //   }
  //   // Generate a mock transaction ID
  //   final now = DateTime.now();
  //   return '3561 4422 8732'; // Similar format to uploaded image
  // }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final screenWidth = MediaQuery.of(context).size.width;

    final isDesktop = screenWidth > 1024;
    final isTablet = screenWidth >= 600 && screenWidth <= 1024;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F5F5,
      ), // Light background like the image
      body: Center(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              // crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),

                // Main success content
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      // Success checkmark with circle (like uploaded image)
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              kBlueColor.withOpacity(0.8),
                              kBlueColor.withOpacity(0.3),
                              kBlueColor.withOpacity(0.1),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.3, 0.6, 1.0],
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(25),
                          decoration: const BoxDecoration(
                            color: kBlueColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Success title
                      const Text(
                        'Payment Successful',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Successful Paid ₹${widget.details.amount.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Payment details card (like uploaded image)
                Container(
                  width: isMobile ? double.infinity : 500,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment methods',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),

                      //_buildPaymentDetailRow('Transaction ID', transactionId),
                      _buildPaymentDetailRow(
                        'Date',
                        _formatDateForDisplay(widget.details.paymentDate),
                      ),
                      _buildPaymentDetailRow(
                        'Type of Transaction',
                        widget.details.paymentType == PaymentType.online
                            ? 'Credit Card'
                            : 'Cash Payment',
                      ),
                      _buildPaymentDetailRow(
                        'Amount',
                        '₹${widget.details.amount.toStringAsFixed(0)}',
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Success',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Back Home button (like uploaded image)
                SizedBox(
                  width: isMobile ? double.infinity : 500,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        isMobile
                            ? () =>
                                Navigator.of(context).popUntil((r) => r.isFirst)
                            : () => Navigator.pushNamed(
                              context,
                              '/customer/payments',
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlueColor.withOpacity(.9),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Back Home',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfettiBackground() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        return Stack(
          children: List.generate(30, (index) {
            final colors = [
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.orange,
              Colors.purple,
              Colors.pink,
              Colors.yellow,
              Colors.teal,
            ];

            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;

            return Positioned(
              left:
                  (index % 6) * (screenWidth / 6) +
                  ((_confettiController.value * 100) % 50),
              top:
                  (index ~/ 6) * (screenHeight / 8) +
                  ((_confettiController.value * 200) % 100),
              child: Transform.rotate(
                angle: _confettiController.value * 6.28 * (index + 1),
                child: Container(
                  width: index % 3 == 0 ? 6 : 4,
                  height: index % 4 == 0 ? 12 : 8,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  String _formatDateForDisplay(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
