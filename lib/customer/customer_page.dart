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
  int itemsPerPage = 25;
  String? expandedCustomerId;
  String? expandedTransactionId;

  // Add these variables to track counts
  int _customerCount = 0;
  int _transactionCount = 0;
  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab ?? 0;

    // Initialize data after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateDataCounts();
    });
  }

  // Create GlobalKeys
  final GlobalKey<AllCustomerState> _allCustomerKey =
      GlobalKey<AllCustomerState>();
  final GlobalKey<AllTransactionState> _allTransactionKey =
      GlobalKey<AllTransactionState>();

  final List<String> tabs = ['All Customers', 'Transaction', 'Payment'];

  // Updated getter with proper fallback
  int get currentTabCount {
    if (selectedTab == 0) {
      return _customerCount;
    } else if (selectedTab == 1) {
      return _transactionCount;
    }
    return 0;
  }

  // Method to update data counts
  void _updateDataCounts() {
    if (selectedTab == 0 && _allCustomerKey.currentState != null) {
      final customerState = _allCustomerKey.currentState!;
      final filteredCount = _getFilteredCustomerCount(customerState);
      if (_customerCount != filteredCount) {
        setState(() {
          _customerCount = filteredCount;
          _isDataLoaded = true;
        });
      }
    } else if (selectedTab == 1 && _allTransactionKey.currentState != null) {
      final transactionState = _allTransactionKey.currentState!;
      final filteredCount = _getFilteredTransactionCount(transactionState);
      if (_transactionCount != filteredCount) {
        setState(() {
          _transactionCount = filteredCount;
          _isDataLoaded = true;
        });
      }
    }
  }

  // Helper method to get filtered customer count
  int _getFilteredCustomerCount(AllCustomerState customerState) {
    if (searchQuery.isEmpty) {
      return customerState.customers.length;
    }
    return customerState.filteredCustomers.length;
  }

  // Helper method to get filtered transaction count
  int _getFilteredTransactionCount(AllTransactionState transactionState) {
    if (searchQuery.isEmpty) {
      return transactionState.transactions.length;
    }
    return transactionState.filteredTransactions.length;
  }

  // Method to refresh pagination when needed
  void _refreshPagination() {
    setState(() {
      currentPage = 1;
      expandedCustomerId = null;
      expandedTransactionId = null;
      _isDataLoaded = false;
    });

    // Update counts after a brief delay to ensure state is ready
    Future.delayed(Duration(milliseconds: 100), () {
      _updateDataCounts();
    });
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
              padding:
                  isDesktop
                      ? const EdgeInsets.all(24)
                      : isTablet
                      ? const EdgeInsets.all(20)
                      : const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 10, // 👈 Mobile-ൽ bottom padding മാറ്റാം
                      ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDesktop, isTablet, isMobile),
                  SizedBox(height: 24),
                  _buildTabsAndActions(isDesktop, isTablet, isMobile),
                  SizedBox(height: 20),
                  // Only show search and filter for All Customers and Transaction tabs
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
                  // Only show pagination for All Customers and Transaction tabs
                  if (selectedTab != 2 && _isDataLoaded) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildPaginationInfo(
                            showPerPage: true,
                            showRangeText: false,
                            isMobile: isMobile,
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
          onCustomerCountChanged: (count) {
            setState(() {
              _customerCount = count;
              _isDataLoaded = true;
            });
          },
          onDataLoaded: () {
            // Callback when data is loaded
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateDataCounts();
            });
          },
        );
      case 1: // Transaction
        return AllTransaction(
          key: _allTransactionKey,
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
          onTransactionCountChanged: (count) {
            setState(() {
              _transactionCount = count;
              _isDataLoaded = true;
            });
          },
          onDataLoaded: () {
            // Callback when data is loaded
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateDataCounts();
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
            children: [_buildTabs(isDesktop, isTablet, isMobile)],
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
            onTap: () {
              setState(() {
                selectedTab = index;
              });
              _refreshPagination(); // Use the refresh method
            },
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
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CustomerForm()),
        );

        // Refresh data if a customer was added
        if (result == true && selectedTab == 0) {
          await _allCustomerKey.currentState?.refreshCustomers();
          _refreshPagination();
        }
      },
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
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                    currentPage = 1; // Reset to first page on search
                  });
                  // Update counts after search
                  Future.delayed(Duration(milliseconds: 100), () {
                    _updateDataCounts();
                  });
                },
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
    bool isMobile = false,
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
              if (!isMobile)
                Text('Show: ', style: TextStyle(color: Color(0xFF6B7280))),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButton2<int>(
                  value: itemsPerPage,
                  underline: SizedBox.shrink(),
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
                    _updateDataCounts();
                  },
                  buttonStyleData:
                      isMobile
                          ? ButtonStyleData(
                            height: 30,
                            width: 50,
                            overlayColor: MaterialStateProperty.all(
                              Colors.transparent,
                            ),
                          )
                          : ButtonStyleData(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            height: 40,
                            overlayColor: MaterialStateProperty.all(
                              Colors.transparent,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                              color: Colors.white,
                            ),
                          ),
                  dropdownStyleData: DropdownStyleData(
                    width: isMobile ? 70 : null,
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

    // Ensure current page is within valid range
    if (currentPage > totalPages && totalPages > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          currentPage = totalPages;
        });
      });
    }

    /// 🔹 Full pagination (for desktop/tablet)
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

    /// 🔹 Compact pagination (for mobile)
    Widget _buildCompactPagination() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed:
                currentPage > 1
                    ? () {
                      setState(() {
                        currentPage--;
                        expandedCustomerId = null;
                        expandedTransactionId = null;
                      });
                    }
                    : null,
            icon: Icon(Icons.chevron_left),
            color: currentPage > 1 ? kPrimaryColor : Color(0xFF9CA3AF),
          ),
          Text(
            "$currentPage / $totalPages",
            style: TextStyle(fontWeight: FontWeight.w600, color: kPrimaryColor),
          ),
          IconButton(
            onPressed:
                currentPage < totalPages
                    ? () {
                      setState(() {
                        currentPage++;
                        expandedCustomerId = null;
                        expandedTransactionId = null;
                      });
                    }
                    : null,
            icon: Icon(Icons.chevron_right),
            color: currentPage < totalPages ? kPrimaryColor : Color(0xFF9CA3AF),
          ),
        ],
      );
    }

    /// 🔹 Full pagination (your existing UI)
    Widget _buildFullPagination() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed:
                currentPage > 1
                    ? () {
                      setState(() {
                        currentPage--;
                        expandedCustomerId = null;
                        expandedTransactionId = null;
                      });
                    }
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
              onTap: () {
                setState(() {
                  currentPage = pageNum;
                  expandedCustomerId = null;
                  expandedTransactionId = null;
                });
              },
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
                    ? () {
                      setState(() {
                        currentPage++;
                        expandedCustomerId = null;
                        expandedTransactionId = null;
                      });
                    }
                    : null,
            icon: Icon(Icons.chevron_right),
            color: currentPage < totalPages ? kPrimaryColor : Color(0xFF9CA3AF),
          ),
        ],
      );
    }

    /// 🔹 Auto-switch based on device
    return isMobile ? _buildCompactPagination() : _buildFullPagination();
  }
}
