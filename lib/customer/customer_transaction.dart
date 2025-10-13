import 'package:flutter/material.dart';
import 'package:gold_pos/api.dart';
import 'package:gold_pos/auth_helper.dart';
import 'package:gold_pos/utils/avathar.dart';
import 'package:gold_pos/utils/colors.dart';
import 'package:gold_pos/utils/diamond_indicator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthException implements Exception {
  final String message;
  final String? code;
  final String? statusCode;

  const AuthException(this.message, {this.code, this.statusCode});

  @override
  String toString() => 'AuthException: $message';
}

class TransactionService {
  static const String baseUrl = ApiConfig.baseUrl;
  static String? _authToken;

  // Initialize auth token from AuthHelper
  static Future<void> initializeAuth() async {
    try {
      _authToken = await AuthHelper.getToken();
      print('Token initialized: ${_authToken != null ? "✓" : "✗"}');
    } catch (e) {
      print('Error initializing auth: $e');
      _authToken = null;
    }
  }

  // Clear auth token
  static Future<void> clearAuthToken() async {
    try {
      _authToken = null;
      await AuthHelper.saveToken('');
      print('Auth token cleared');
    } catch (e) {
      print('Error clearing token: $e');
    }
  }

  // Headers with better validation
  static Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (_authToken != null && _authToken!.isNotEmpty && _authToken != 'null') {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  static Future<List<Transaction>> fetchTransactions() async {
    try {
      // Ensure auth token is loaded and valid
      if (_authToken == null || _authToken!.isEmpty || _authToken == 'null') {
        await initializeAuth();
      }

      // Double check token after initialization
      if (_authToken == null || _authToken!.isEmpty || _authToken == 'null') {
        throw const AuthException('No authentication token available');
      }

      // Validate token format (basic JWT check)
      final tokenParts = _authToken!.split('.');
      if (tokenParts.length != 3) {
        await clearAuthToken();
        throw const AuthException('Invalid token format. Please login again.');
      }

      print(
        'Fetching transactions with token: ${_authToken!.substring(0, 10)}...',
      );

      final response = await http
          .get(Uri.parse('$baseUrl/payments/transactions'), headers: _headers)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception(
                'Request timeout. Please check your internet connection.',
              );
            },
          );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Handle different response codes
      switch (response.statusCode) {
        case 200:
          try {
            final data = json.decode(response.body);

            // Check if response has expected structure
            if (data == null) {
              return [];
            }

            // Handle different possible response structures
            List<dynamic> transactionsList;
            if (data is Map<String, dynamic>) {
              if (data.containsKey('transactions')) {
                transactionsList = data['transactions'] as List<dynamic>? ?? [];
              } else if (data is List) {
                transactionsList = data as List;
              } else {
                print('Unexpected response format: $data');
                return [];
              }
            } else if (data is List) {
              transactionsList = data;
            } else {
              print('Unexpected response type: ${data.runtimeType}');
              return [];
            }

            return transactionsList
                .where((json) => json != null)
                .map((json) {
                  try {
                    return Transaction.fromJson(json as Map<String, dynamic>);
                  } catch (e) {
                    print('Error parsing transaction: $e');
                    print('Invalid transaction data: $json');
                    return null;
                  }
                })
                .where((transaction) => transaction != null)
                .cast<Transaction>()
                .toList();
          } catch (e) {
            print('JSON parsing error: $e');
            throw Exception('Failed to parse server response');
          }

        case 401:
          await clearAuthToken();
          throw const AuthException(
            'Authentication failed. Please login again.',
          );

        case 403:
          throw const AuthException('Access denied. Insufficient permissions.');

        case 404:
          throw Exception('Transactions endpoint not found');

        case 500:
          // Try to get more specific error from response
          try {
            final errorData = json.decode(response.body);
            final errorMessage =
                errorData['message'] ?? 'Internal server error';
            throw Exception('Server error: $errorMessage');
          } catch (e) {
            throw Exception('Server error. Please try again later.');
          }

        case 502:
        case 503:
        case 504:
          throw Exception(
            'Service temporarily unavailable. Please try again later.',
          );

        default:
          throw Exception(
            'Failed to load transactions (${response.statusCode}): ${response.reasonPhrase}',
          );
      }
    } on AuthException {
      // Re-throw auth exceptions as-is
      rethrow;
    } on http.ClientException catch (e) {
      print('Network error: $e');
      throw Exception('Network error: Please check your internet connection');
    } on FormatException catch (e) {
      print('Format error: $e');
      throw Exception('Invalid response format from server');
    } on Exception catch (e) {
      print('Transaction fetch error: $e');
      if (e.toString().contains('AuthException')) {
        rethrow;
      }
      throw Exception('Network error: ${e.toString()}');
    } catch (e) {
      print('Unexpected error: $e');
      throw Exception('Unexpected error occurred: ${e.toString()}');
    }
  }

  // Helper method to check authentication status
  static Future<bool> isAuthenticated() async {
    if (_authToken == null || _authToken!.isEmpty || _authToken == 'null') {
      await initializeAuth();
    }
    return _authToken != null && _authToken!.isNotEmpty && _authToken != 'null';
  }
}

class Transaction {
  final String transactionId;
  final String customerId;
  final String customerName;
  final double amount;
  final String month;
  final DateTime date;
  final String status;
  final String type;
  final String description;

  Transaction({
    required this.transactionId,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.month,
    required this.date,
    this.status = 'Completed',
    this.type = 'Credit',
    this.description = '',
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      transactionId: json['transactionId']?.toString() ?? '',
      customerId: json['customerId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? 'Unknown',
      amount: _parseAmount(json['amount']),
      month: json['month']?.toString() ?? '',
      date: _parseDate(json['date']),
      status: 'Completed',
      type: 'Credit',
      description:
          json['month'] != null ? 'Payment for ${json['month']}' : 'Payment',
    );
  }

  static double _parseAmount(dynamic amount) {
    if (amount == null) return 0.0;
    if (amount is double) return amount;
    if (amount is int) return amount.toDouble();
    if (amount is String) return double.tryParse(amount) ?? 0.0;
    return 0.0;
  }

  static DateTime _parseDate(dynamic dateStr) {
    if (dateStr == null) return DateTime.now();
    try {
      return DateTime.parse(dateStr.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  // Helper getters for display
  String get name => customerName;
  String get avatar => customerName;
  String get formattedAmount => '₹${amount.toStringAsFixed(2)}';
  String get formattedDate =>
      '${date.day} ${_getMonthName(date.month)}, ${date.year}';

  String _getMonthName(int month) {
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
    return months[month - 1];
  }
}

class AllTransaction extends StatefulWidget {
  final int currentPage;
  final int itemsPerPage;
  final String searchQuery;
  final String? expandedTransactionId;
  final Function(String?)? onExpandedTransactionChanged;
  final Function(int)? onPageChanged;
  final Function(int)? onTransactionCountChanged; // New callback
  final VoidCallback? onDataLoaded;

  const AllTransaction({
    Key? key,
    this.currentPage = 1,
    this.itemsPerPage = 25,
    this.searchQuery = '',
    this.expandedTransactionId,
    this.onExpandedTransactionChanged,
    this.onPageChanged,
    this.onTransactionCountChanged, // New
    this.onDataLoaded,
  }) : super(key: key);

  @override
  State<AllTransaction> createState() => AllTransactionState();
}

class AllTransactionState extends State<AllTransaction> {
  List<Transaction> transactions = [];
  bool isLoading = true;
  String? errorMessage;
  bool _isAuthError = false;

  @override
  void initState() {
    super.initState();
    _initializeAndFetch();
  }

  Future<void> _initializeAndFetch() async {
    // Initialize API service with auth token
    await TransactionService.initializeAuth();
    await _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
        _isAuthError = false;
      });

      // Check if user is authenticated
      final isAuth = await TransactionService.isAuthenticated();
      if (!isAuth) {
        setState(() {
          _isAuthError = true;
          errorMessage = 'Please login to view transactions';
          isLoading = false;
        });
        return;
      }

      final fetchedTransactions = await TransactionService.fetchTransactions();

      setState(() {
        transactions = fetchedTransactions;
        isLoading = false;
      });

      // Notify parent widgets
      // In _fetchTransactions method
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final count = filteredTransactions.length;
        widget.onTransactionCountChanged?.call(count);
        widget.onDataLoaded?.call();
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
        _isAuthError = e is AuthException;
      });
    }
  }

  Future<void> refreshTransactions() async {
    await _fetchTransactions();
  }

  List<Transaction> get filteredTransactions {
    if (widget.searchQuery.isEmpty) {
      return transactions;
    }
    return transactions.where((txn) {
      return txn.name.toLowerCase().contains(
            widget.searchQuery.toLowerCase(),
          ) ||
          txn.customerId.toLowerCase().contains(
            widget.searchQuery.toLowerCase(),
          ) ||
          txn.month.toLowerCase().contains(widget.searchQuery.toLowerCase()) ||
          txn.type.toLowerCase().contains(widget.searchQuery.toLowerCase()) ||
          txn.status.toLowerCase().contains(widget.searchQuery.toLowerCase());
    }).toList();
  }

  List<Transaction> get paginatedTransactions {
    final filtered = filteredTransactions;

    // Early return for empty list
    if (filtered.isEmpty) {
      return [];
    }

    final startIndex = (widget.currentPage - 1) * widget.itemsPerPage;

    // Check if startIndex is beyond the list length
    if (startIndex >= filtered.length) {
      return [];
    }

    final endIndex = (startIndex + widget.itemsPerPage).clamp(
      0,
      filtered.length,
    );

    return filtered.sublist(startIndex, endIndex);
  }

  @override
  void didUpdateWidget(AllTransaction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      // Add null check and ensure list is not empty
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final filteredCount = filteredTransactions.length;
        widget.onTransactionCountChanged?.call(filteredCount);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (transactions.isEmpty) {
      return _buildEmptyState();
    }

    final isDesktop = MediaQuery.of(context).size.width > 1000;
    final isTablet =
        MediaQuery.of(context).size.width > 700 &&
        MediaQuery.of(context).size.width <= 1000;
    final isTabletMini =
        MediaQuery.of(context).size.width > 600 &&
        MediaQuery.of(context).size.width <= 700;
    final isMobile = MediaQuery.of(context).size.width <= 600;

    return RefreshIndicator(
      onRefresh: refreshTransactions,
      child: _buildTransactionTable(
        isDesktop,
        isTablet,
        isMobile,
        isTabletMini,
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DiamondIndicator(size: 9, color: Color(0xFFBDAC67)),
            SizedBox(height: 20),
            Text(
              'Loading transactions...',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE5E7EB)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isAuthError ? Icons.lock_outline : Icons.error_outline,
              size: 80,
              color: _isAuthError ? Colors.orange : Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              _isAuthError
                  ? 'Authentication Required'
                  : 'Error loading transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              errorMessage ?? 'Unknown error occurred',
              style: TextStyle(color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isAuthError) ...[
                  ElevatedButton(
                    onPressed: () async {
                      // Clear auth data and navigate to login
                      await AuthHelper.clearAllData();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Login'),
                  ),
                  SizedBox(width: 8),
                ],
                ElevatedButton(
                  onPressed: _fetchTransactions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTable(
    bool isDesktop,
    bool isTablet,
    bool isMobile,
    bool isTabletMini,
  ) {
    if (isMobile) {
      return _buildMobileTransactionList(
        isDesktop,
        isTablet,
        isTabletMini,
        isMobile,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child:
                paginatedTransactions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      itemCount: paginatedTransactions.length,
                      itemBuilder: (context, index) {
                        if (index >= paginatedTransactions.length) {
                          return SizedBox.shrink();
                        }
                        final txn = paginatedTransactions[index];
                        final txnId = '${txn.name}_$index';
                        final isExpanded =
                            widget.expandedTransactionId == txnId;

                        return Column(
                          children: [
                            _buildTransactionRow(txn, txnId),
                            if (isExpanded)
                              _buildExpandedtxnDetails(
                                txn,
                                isDesktop,
                                isTablet,
                                isTabletMini,
                                isMobile,
                              ),
                          ],
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Color(0xFF6B7280)),
          SizedBox(height: 16),
          Text(
            widget.searchQuery.isEmpty
                ? 'No transactions found'
                : 'No transactions match your search',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.searchQuery.isEmpty
                ? 'Add your first transaction to get started'
                : 'Try adjusting your search terms',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTransactionList(
    bool isDesktop,
    bool isTablet,
    bool isTabletMini,
    bool isMobile,
  ) {
    if (paginatedTransactions.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: paginatedTransactions.length,
      itemBuilder: (context, index) {
        final txn = paginatedTransactions[index];
        final txnId = '${txn.name}_$index';
        final isExpanded = widget.expandedTransactionId == txnId;

        return Column(
          children: [
            _buildMobileTransactionCard(txn, txnId),
            if (isExpanded)
              _buildExpandedtxnDetails(
                txn,
                isDesktop,
                isTablet,
                isTabletMini,
                isMobile,
              ),
          ],
        );
      },
    );
  }

  Widget _buildMobileTransactionCard(Transaction txn, String txnId) {
    final isExpanded = widget.expandedTransactionId == txnId;

    return InkWell(
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () => _toggleExpansion(txnId),
      child: Container(
        margin: EdgeInsets.only(bottom: isExpanded ? 0 : 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Avatar(name: txn.name),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        txn.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        txn.customerId,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _toggleExpansion(txnId),
                  child: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  txn.formattedAmount, // Use formatted amount instead of casting
                  style: TextStyle(
                    color: Color(0xFF1F2937),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  txn.formattedDate, // Use formatted date instead of casting
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('Name', style: _headerTextStyle())),
          Expanded(flex: 2, child: Text('Type', style: _headerTextStyle())),
          Expanded(flex: 2, child: Text('Amount', style: _headerTextStyle())),
          Expanded(flex: 2, child: Text('Date', style: _headerTextStyle())),
          Expanded(flex: 2, child: Text('Status', style: _headerTextStyle())),
          Container(
            width: 40,
            child: Text('Action', style: _headerTextStyle()),
          ),
        ],
      ),
    );
  }

  TextStyle _headerTextStyle() {
    return TextStyle(
      color: Color(0xFF6B7280),
      fontWeight: FontWeight.w500,
      fontSize: 12,
    );
  }

  Widget _buildTransactionRow(Transaction txn, String txnId) {
    final isExpanded = widget.expandedTransactionId == txnId;

    return InkWell(
      onTap: () => _toggleExpansion(txnId),
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
        ),
        child: InkWell(
          onTap: () => _toggleExpansion(txnId),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Avatar(name: txn.name),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            txn.name,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            txn.customerId,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  txn.type,
                  style: TextStyle(
                    color: txn.type == "Credit" ? Colors.green : Colors.red,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  txn.formattedAmount,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(flex: 2, child: Text(txn.formattedDate)),
              Expanded(
                flex: 2,
                child: Text(
                  txn.status,
                  style: TextStyle(
                    color:
                        txn.status == "Completed"
                            ? Colors.green
                            : Colors.orange,
                  ),
                ),
              ),
              Container(
                width: 40,
                child: GestureDetector(
                  onTap: () => _toggleExpansion(txnId),
                  child: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedtxnDetails(
    Transaction txn,
    bool isDesktop,
    bool isTablet,
    bool isTabletMini,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Avatar(
                name: txn.name,
                size:
                    isDesktop ? 40 : (isTablet ? 36 : (isTabletMini ? 32 : 28)),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  txn.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'Basic Information:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 16),
          //_buildInfoGrid(txn, isDesktop, isTablet, isTabletMini,isMobile),
          _buildInfoWrap(txn, isDesktop, isTablet, isTabletMini, isMobile),
        ],
      ),
    );
  }

  Widget _buildInfoWrap(
    Transaction txn,
    isDesktop,
    isTablet,
    isTabletMini,
    isMobile,
  ) {
    return Wrap(
      spacing:
          isDesktop
              ? 100
              : isTablet
              ? 100
              : isTabletMini
              ? 70
              : 40,
      runSpacing: isDesktop ? 10 : 10,
      children: [
        _buildInfoItem("Customer ID", txn.customerId),
        _buildInfoItem("Type", txn.type),
        _buildInfoItem("Amount", txn.formattedAmount), // Use formatted amount
        _buildInfoItem("Date", txn.formattedDate), // Use formatted date
        _buildInfoItem("Month", txn.month),
        _buildInfoItem("Status", txn.status),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleExpansion(String txnId) {
    widget.onExpandedTransactionChanged?.call(
      widget.expandedTransactionId == txnId ? null : txnId,
    );
  }
}
