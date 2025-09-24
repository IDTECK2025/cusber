import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:gold_pos/customer/payment_screen_customer.dart';
import '../../utils/colors.dart';
import '../../utils/responsive_text.dart';
import 'all_customer.dart';
import 'customer_transaction.dart';
import 'form_customer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Customer Management',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: CustomerManagementScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CustomerManagementScreen extends StatefulWidget {
  final int? initialTab;

  const CustomerManagementScreen({super.key, this.initialTab});

  @override
  _CustomerManagementScreenState createState() =>
      _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  int selectedTab = 0;
  String searchQuery = '';
  int currentPage = 1;
  int itemsPerPage = 10;
  String? expandedCustomerId;
  String? expandedTransactionId;

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab ?? 0; // Set initial tab
  }

  // Create a GlobalKey to access AllCustomer state
  final GlobalKey<AllCustomerState> _allCustomerKey =
      GlobalKey<AllCustomerState>();
  final GlobalKey<AllTransactionState> _allTransactionKey =
      GlobalKey<AllTransactionState>();

  final List<String> tabs = ['All Customers', 'Transaction', 'Payment'];

  // Get customer count from AllCustomer
  int get currentTabCount {
    if (selectedTab == 0) {
      // Customers tab
      return _allCustomerKey.currentState?.customers.length ?? 0;
    } else if (selectedTab == 1) {
      // Transactions tab
      return _allTransactionKey.currentState?.transactions.length ?? 0;
    }
    return 0; // default for other tabs
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isDesktop = constraints.maxWidth > 1000;
            bool isTablet =
                constraints.maxWidth > 700 && constraints.maxWidth <= 1000;
            bool isTabletMini =
                constraints.maxWidth > 600 && constraints.maxWidth <= 700;
            bool isMobile = constraints.maxWidth <= 600;

            return Padding(
              padding: EdgeInsets.all(
                isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDesktop, isTablet, isMobile),
                  SizedBox(height: 24),
                  _buildTabsAndActions(isDesktop, isTablet, isMobile),
                  SizedBox(height: 20),
                  // Only show search and filter for All Customers tab
                  if (selectedTab != 2) ...[
                    _buildSearchAndFilter(isDesktop, isTablet, isMobile),
                    SizedBox(height: 20),
                  ],
                  Expanded(
                    child: _buildTabContent(
                      isDesktop,
                      isTablet,
                      isMobile,
                      isTabletMini,
                    ),
                  ),
                  // Only show pagination for All Customers tab
                  if (selectedTab != 2) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (!isMobile)
                            _buildPaginationInfo(
                              showPerPage: true,
                              showRangeText: false,
                            ),
                          Expanded(
                            child: _buildPagination(
                              isDesktop,
                              isTablet,
                              isMobile,
                            ),
                          ),
                          if (!isMobile)
                            _buildPaginationInfo(
                              showPerPage: false,
                              showRangeText: true,
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTabContent(
    bool isDesktop,
    bool isTablet,
    bool isMobile,
    bool isTabletMini,
  ) {
    switch (selectedTab) {
      case 0: // All Customers
        return AllCustomer(
          key: _allCustomerKey,
          currentPage: currentPage,
          itemsPerPage: itemsPerPage,
          searchQuery: searchQuery,
          expandedCustomerId: expandedCustomerId,
          onExpandedCustomerChanged: (customerId) {
            setState(() {
              expandedCustomerId = customerId;
            });
          },
          onPageChanged: (page) {
            setState(() {
              currentPage = page;
              expandedCustomerId = null;
            });
          },
        );
      case 1: // Transaction
        return AllTransaction(
          currentPage: currentPage,
          itemsPerPage: itemsPerPage,
          searchQuery: searchQuery,
          expandedTransactionId: expandedTransactionId,
          onExpandedTransactionChanged: (txnId) {
            setState(() {
              expandedTransactionId = txnId;
            });
          },
          onPageChanged: (page) {
            setState(() {
              currentPage = page;
              expandedTransactionId = null;
            });
          },
        );
      case 2: // Payment
        return CustomerPaymentScreen();
      default:
        return AllCustomer(key: _allCustomerKey);
    }
  }

  Widget _buildHeader(bool isDesktop, bool isTablet, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Customers',
          style: TextStyle(
            fontSize: isDesktop ? 28 : (isTablet ? 24 : 20),
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        if (isDesktop || isTablet) Row(children: [_buildAddCustomerButton()]),
      ],
    );
  }

  Widget _buildTabsAndActions(bool isDesktop, bool isTablet, bool isMobile) {
    return Column(
      children: [
        if (isDesktop || isTablet)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTabs(isDesktop, isTablet, isMobile),
              if (isMobile) Row(children: [_buildAddCustomerButton()]),
            ],
          )
        else ...[
          _buildTabs(isDesktop, isTablet, isMobile),
          SizedBox(height: 16),
          Row(children: [Expanded(child: _buildAddCustomerButton())]),
        ],
      ],
    );
  }

  Widget _buildTabs(bool isDesktop, bool isTablet, bool isMobile) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (index) {
          bool isSelected = selectedTab == index;
          return GestureDetector(
            onTap:
                () => setState(() {
                  selectedTab = index;
                  expandedCustomerId = null; // Close any expanded details
                  currentPage = 1; // Reset to first page
                }),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 20 : (isTablet ? 16 : 12),
                vertical: isDesktop ? 12 : (isTablet ? 10 : 8),
              ),
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? Color(0xFFE5E7EB) : Colors.transparent,
                ),
              ),
              child: Text(
                tabs[index],
                style: TextStyle(
                  color: isSelected ? kBlueColor : Color(0xFF6B7280),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAddCustomerButton() {
    return InkWell(
      onTap:
          () => setState(() {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CustomerForm()),
            );
          }),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: kPrimaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 16, color: Colors.white),
            SizedBox(width: 8),
            ResponsiveText(
              'Add Customers',
              tablet: 10,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter(bool isDesktop, bool isTablet, bool isMobile) {
    return SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFFE5E7EB)),
              ),
              child: TextField(
                cursorColor: kPrimaryColor,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Search customer...',
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, size: 16, color: Color(0xFF6B7280)),
                ),
                onChanged: (value) => setState(() => searchQuery = value),
              ),
            ),
          ),
          SizedBox(width: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.filter_list, size: 16, color: Color(0xFF6B7280)),
                SizedBox(width: 8),
                Text(
                  'Filter',
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
    );
  }

  Widget _buildPaginationInfo({
    bool showRangeText = true,
    bool showPerPage = true,
  }) {
    int totalItems = currentTabCount;
    int startItem = totalItems > 0 ? ((currentPage - 1) * itemsPerPage) + 1 : 0;
    int endItem =
        totalItems > 0 ? (currentPage * itemsPerPage).clamp(1, totalItems) : 0;

    return Row(
      children: [
        if (showPerPage)
          Row(
            children: [
              Text('Show: ', style: TextStyle(color: Color(0xFF6B7280))),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButton2<int>(
                  value: itemsPerPage,
                  items:
                      [10, 25, 50, 100].map((int item) {
                        return DropdownMenuItem<int>(
                          value: item,
                          child: Text(
                            item.toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF374151),
                            ),
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      itemsPerPage = value ?? 25;
                      currentPage = 1;
                    });
                  },
                  buttonStyleData: ButtonStyleData(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      color: Colors.white,
                    ),
                  ),
                  dropdownStyleData: DropdownStyleData(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                  ),
                  iconStyleData: const IconStyleData(
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ],
          ),
        if (showRangeText && totalItems > 0)
          Text(
            ' per page    $startItem - $endItem of $totalItems',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
      ],
    );
  }

  Widget _buildPagination(bool isDesktop, bool isTablet, bool isMobile) {
    int totalItems = currentTabCount;
    int totalPages = totalItems > 0 ? (totalItems / itemsPerPage).ceil() : 1;

    List<dynamic> getPageNumbers() {
      List<dynamic> pages = [];

      if (totalPages <= 6) {
        // Show all pages if total is 6 or less
        pages = List.generate(totalPages, (index) => index + 1);
      } else {
        // Always show first page
        pages.add(1);

        // Add left dots if current page > 4
        if (currentPage > 4) {
          pages.add('...');
        }

        // Show pages around current page (current-1, current, current+1)
        int start = (currentPage - 1).clamp(2, totalPages - 1);
        int end = (currentPage + 1).clamp(2, totalPages - 1);

        for (int i = start; i <= end; i++) {
          if (!pages.contains(i)) {
            pages.add(i);
          }
        }

        // Add right dots if current page < total pages - 3
        if (currentPage < totalPages - 3) {
          pages.add('...');
        }

        // Always show last page
        if (!pages.contains(totalPages)) {
          pages.add(totalPages);
        }
      }

      return pages;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed:
              currentPage > 1
                  ? () => setState(() {
                    currentPage--;
                    expandedCustomerId = null;
                  })
                  : null,
          icon: Icon(Icons.chevron_left),
          color: currentPage > 1 ? kPrimaryColor : Color(0xFF9CA3AF),
        ),
        ...getPageNumbers().map((pageItem) {
          if (pageItem == '...') {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '...',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          int pageNum = pageItem as int;
          bool isSelected = pageNum == currentPage;

          return GestureDetector(
            onTap:
                () => setState(() {
                  currentPage = pageNum;
                  expandedCustomerId = null;
                }),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? kPrimaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                pageNum.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Color(0xFF6B7280),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
        IconButton(
          onPressed:
              currentPage < totalPages
                  ? () => setState(() {
                    currentPage++;
                    expandedCustomerId = null;
                  })
                  : null,
          icon: Icon(Icons.chevron_right),
          color: currentPage < totalPages ? kPrimaryColor : Color(0xFF9CA3AF),
        ),
      ],
    );
  }
}
