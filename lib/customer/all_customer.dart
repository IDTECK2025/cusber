import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:gold_pos/utils/avathar.dart';
import '../../models/customer_model.dart';
import '../../utils/colors.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:2025';
  static const String customersEndpoint = '/customers';

  Future<List<Customer>> getCustomers() async {
    try {
      final url = Uri.parse('$baseUrl$customersEndpoint');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic jsonData = json.decode(response.body);

        // Handle both array and single object responses
        if (jsonData is List) {
          return jsonData.map((json) => Customer.fromJson(json)).toList();
        } else if (jsonData is Map<String, dynamic>) {
          return [Customer.fromJson(jsonData)];
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('Failed to load customers: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching customers: $e');
      throw Exception('Failed to load customers: $e');
    }
  }
}

class AllCustomer extends StatefulWidget {
  final int currentPage;
  final int itemsPerPage;
  final String searchQuery;
  final String? expandedCustomerId;
  final Function(String?)? onExpandedCustomerChanged;
  final Function(int)? onPageChanged;

  const AllCustomer({
    Key? key,
    this.currentPage = 1,
    this.itemsPerPage = 25,
    this.searchQuery = '',
    this.expandedCustomerId,
    this.onExpandedCustomerChanged,
    this.onPageChanged,
  }) : super(key: key);

  @override
  State<AllCustomer> createState() => AllCustomerState();
}

class AllCustomerState extends State<AllCustomer> {
  List<Customer> customers = [];
  bool isLoading = true;
  String? errorMessage;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final fetchedCustomers = await _apiService.getCustomers();

      setState(() {
        customers = fetchedCustomers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> refreshCustomers() async {
    await _fetchCustomers();
  }

  List<Customer> get filteredCustomers {
    if (widget.searchQuery.isEmpty) {
      return customers;
    }
    return customers.where((customer) {
      return customer.fullName.toLowerCase().contains(
            widget.searchQuery.toLowerCase(),
          ) ||
          customer.email.toLowerCase().contains(
            widget.searchQuery.toLowerCase(),
          ) ||
          customer.phoneNumber.contains(widget.searchQuery) ||
          customer.city.toLowerCase().contains(
            widget.searchQuery.toLowerCase(),
          ) ||
          customer.customerId.toLowerCase().contains(
            widget.searchQuery.toLowerCase(),
          );
    }).toList();
  }

  List<Customer> get paginatedCustomers {
    final filtered = filteredCustomers;
    final startIndex = (widget.currentPage - 1) * widget.itemsPerPage;
    final endIndex = (startIndex + widget.itemsPerPage).clamp(
      0,
      filtered.length,
    );

    if (startIndex >= filtered.length) {
      return [];
    }
    return filtered.sublist(startIndex, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1000;
    final isTablet =
        MediaQuery.of(context).size.width > 700 &&
        MediaQuery.of(context).size.width <= 1000;
    final isTabletMini =
        MediaQuery.of(context).size.width > 400 &&
        MediaQuery.of(context).size.width <= 700;
    final isMobile = MediaQuery.of(context).size.width <= 400;

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: kPrimaryColor),
            SizedBox(height: 16),
            Text(
              'Loading customers...',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Error loading customers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage!,
                style: TextStyle(color: Color(0xFF6B7280)),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchCustomers,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFEAB308),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return _buildCustomerTable(isDesktop, isTablet, isMobile, isTabletMini);
  }

  Widget _buildCustomerTable(
    bool isDesktop,
    bool isTablet,
    bool isMobile,
    bool isTabletMini,
  ) {
    if (isMobile) {
      return RefreshIndicator(
        onRefresh: refreshCustomers,
        child: _buildMobileCustomerList(),
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
          _buildTableHeader(isDesktop, isTablet),
          Expanded(
            child:
                paginatedCustomers.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                      onRefresh: refreshCustomers,
                      child: ListView.builder(
                        itemCount: paginatedCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = paginatedCustomers[index];
                          final customerId = customer.id;
                          final isExpanded =
                              widget.expandedCustomerId == customerId;

                          return Column(
                            children: [
                              _buildCustomerRow(
                                customer,
                                isDesktop,
                                isTablet,
                                false,
                                customerId,
                              ),
                              if (isExpanded)
                                _buildExpandedCustomerDetails(
                                  customer,
                                  isDesktop,
                                  isTablet,
                                  isTabletMini,
                                ),
                            ],
                          );
                        },
                      ),
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
          Icon(Icons.people_outline, size: 80, color: Color(0xFF6B7280)),
          SizedBox(height: 16),
          Text(
            widget.searchQuery.isEmpty
                ? 'No customers found'
                : 'No customers match your search',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.searchQuery.isEmpty
                ? 'Add your first customer to get started'
                : 'Try adjusting your search terms',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          if (widget.searchQuery.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: refreshCustomers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFEAB308),
                  foregroundColor: Colors.white,
                ),
                child: Text('Refresh'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileCustomerList() {
    if (paginatedCustomers.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: paginatedCustomers.length,
      itemBuilder: (context, index) {
        final customer = paginatedCustomers[index];
        final customerId = customer.id;
        final isExpanded = widget.expandedCustomerId == customerId;

        return Column(
          children: [
            _buildMobileCustomerCard(customer, customerId),
            if (isExpanded) _buildMobileExpandedDetails(customer),
          ],
        );
      },
    );
  }

  Widget _buildMobileCustomerCard(Customer customer, String customerId) {
    final isExpanded = widget.expandedCustomerId == customerId;

    return Container(
      margin: EdgeInsets.only(bottom: isExpanded ? 0 : 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFE5E7EB).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(name: customer.fullName),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.fullName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      customer.email,
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                    ),
                    Text(
                      'ID: ${customer.customerId}',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 11),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _toggleExpansion(customerId),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                  ),
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
          SizedBox(height: 12),
          Text(
            customer.location,
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                customer.phoneNumber,
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFFEAB308).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '₹${customer.schemeAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Color(0xFFEAB308),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(bool isDesktop, bool isTablet) {
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
          Expanded(flex: 3, child: Text('Customer', style: _headerTextStyle())),
          if (isDesktop)
            Expanded(flex: 3, child: Text('Email', style: _headerTextStyle())),
          // if (isDesktop)
          //   Expanded(
          //     flex: 2,
          //     child: Text('Customer ID', style: _headerTextStyle()),
          //),
          Expanded(flex: 2, child: Text('Phone', style: _headerTextStyle())),
          Expanded(
            flex: 2,
            child: Text('Scheme Amount', style: _headerTextStyle()),
          ),
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

  Widget _buildCustomerRow(
    Customer customer,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
    String customerId,
  ) {
    final isExpanded = widget.expandedCustomerId == customerId;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: InkWell(
        onTap: () => _toggleExpansion(customerId),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Avatar(name: customer.fullName),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          customer.fullName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        if (!isDesktop)
                          Text(
                            customer.email,
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isDesktop)
              Expanded(
                flex: 3,
                child: Text(
                  customer.email,
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            // if (isDesktop)
            //   Expanded(
            //     flex: 2,
            //     child: Text(
            //       customer.customerId,
            //       style: TextStyle(
            //         color: Color(0xFF6B7280),
            //         fontSize: 12,
            //         fontFamily: 'monospace',
            //       ),
            //     ),
            //   ),
            Expanded(
              flex: 2,
              child: Text(
                customer.phoneNumber,
                style: TextStyle(color: Color(0xFF1F2937)),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '₹${customer.schemeAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              width: 40,
              child: GestureDetector(
                onTap: () => _toggleExpansion(customerId),
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                        isExpanded
                            ? Color(0xFFEAB308).withOpacity(0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: isExpanded ? Color(0xFFEAB308) : Color(0xFF6B7280),
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedCustomerDetails(
    Customer customer,
    bool isDesktop,
    bool isTablet,
    bool isTabletMini,
  ) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(name: customer.fullName, size: 40),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.fullName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      customer.email,
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                    ),
                    Text(
                      customer.phoneNumber,
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFFEAB308).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ID: ${customer.customerId}',
                        style: TextStyle(
                          color: Color(0xFFEAB308),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF6B7280), size: 20),
              SizedBox(width: 8),
              Text(
                'Customer Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 20 : 12),
          _buildInfoWrap(customer, isDesktop, isTablet, isTabletMini),
        ],
      ),
    );
  }

  Widget _buildMobileExpandedDetails(Customer customer) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        border: Border.all(color: Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFE5E7EB).withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF6B7280), size: 18),
              SizedBox(width: 8),
              Text(
                'Customer Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildMobileInfoList(customer),
        ],
      ),
    );
  }

  Widget _buildInfoWrap(Customer customer, isDesktop, isTablet, isTabletMini) {
    return Wrap(
      spacing:
          isDesktop
              ? 100
              : isTablet
              ? 100
              : isTabletMini
              ? 70
              : 40,
      runSpacing: isDesktop ? 30 : 10,
      children: [
        _buildInfoItem('ADDRESS', customer.address),
        _buildInfoItem('STATE', customer.state),
        _buildInfoItem('CITY', customer.city),
        _buildInfoItem('AADHAAR NO', customer.aadhaarNo),
        _buildInfoItem('PAN NUMBER', customer.panNumber),
        _buildInfoItem('JOIN DATE', _formatDate(customer.joinDate)),
        _buildInfoItem('Scheme Date', _formatDate(customer.schemeDate)),
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

  Widget _buildMobileInfoList(Customer customer) {
    final infoItems = [
      ['ADDRESS', customer.address],
      ['STATE', customer.state],
      ['CITY', customer.city],
      ['AADHAAR NO', customer.aadhaarNo],
      ['PAN NUMBER', customer.panNumber],
      ['BANK', customer.bank],
      ['IFSC CODE', customer.ifsc],
      ['ACCOUNT NO', customer.acc],
      ['BRANCH', customer.branch],
      ['PIN CODE', customer.pin],
      ['COINS', customer.coins.toString()],
      ['JOIN DATE', _formatDate(customer.joinDate)],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children:
          infoItems
              .map(
                (item) => Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: _buildInfoItem(item[0], item[1]),
                ),
              )
              .toList(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _toggleExpansion(String customerId) {
    widget.onExpandedCustomerChanged?.call(
      widget.expandedCustomerId == customerId ? null : customerId,
    );
  }
}
