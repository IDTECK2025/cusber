import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:gold_pos/agent/agent_page.dart';
import 'package:gold_pos/customer/customer_page.dart';
import 'package:gold_pos/lock/lock.dart';
import 'package:gold_pos/shareholder/shareholder_page.dart';
import 'package:gold_pos/subagent/subAgent_page.dart';
import 'package:gold_pos/utils/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uicons/uicons.dart';
import '../../utils/responsive_size.dart';
import '../../utils/responsive_text.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profitcal Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final int? initialIndex;
  const DashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String userName = 'User';
  String userShareId = '';
  String email = '';
  String userRole = '';
  String userPhone = '';
  String userCustomerId = '';
  int userBalance = 0;
  String token = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex!;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        userName = prefs.getString('userName') ?? 'User';
        userShareId = prefs.getString('userShareId') ?? '';
        email = prefs.getString('userEmail') ?? '';
        userRole = prefs.getString('userRole') ?? '';
        userPhone = prefs.getString('userPhone') ?? '';
        userCustomerId = prefs.getString('userCustomerId') ?? '';
        userBalance = prefs.getInt('userBalance') ?? 0;
        token = prefs.getString('token') ?? '';
        isLoading = false;
      });

      // Debug print to see what data we have
      print('Loaded user data:');
      print('Name: $userName');
      print('Email: $email');
      print('Role: $userRole');
      print('Balance: $userBalance');
      print('Phone: $userPhone');
      print('Customer ID: $userCustomerId');
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap a button
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlueColor,
                foregroundColor: Colors.white,
              ),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // confirm
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor.withOpacity(.7),
                foregroundColor: Colors.white,
              ),
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        final prefs = await SharedPreferences.getInstance();

        // Clear all authentication and user data
        await prefs.remove('token');
        await prefs.remove('userId');
        await prefs.remove('userName');
        await prefs.remove('userEmail');
        await prefs.remove('userPhone');
        await prefs.remove('userRole');
        await prefs.remove('userBalance');
        await prefs.remove('userCustomerId');
        await prefs.remove('userShareId');
        await prefs.remove('userCusId');
        await prefs.remove('loginResponse');

        // Navigate to login screen
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
      } catch (e) {
        print('Error during logout: $e');
      }
    }
  }

  int _selectedIndex = 0;
  bool _isCollapsed = false;

  // Bottom nav items (for mobile/tablet)
  final List<BottomNavigationBarItem> _bottomItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_rounded),
      activeIcon: Icon(UIcons.solidRounded.dashboard),
      label: "Dashboard",
    ),
    BottomNavigationBarItem(icon: Icon(Icons.person_pin), label: "Customer"),
    BottomNavigationBarItem(
      icon: Icon(Icons.handshake_rounded),
      label: "Share holder",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_add_alt_1_rounded),
      label: "Agent",
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_add_alt_1_rounded),
      label: "Sub agent",
    ),
  ];

  // Screens for each menu item
  List<Widget> get _pages => [
    Expanded(
      child: DashboardContent(
        userName: userName,
        userBalance: userBalance,
        userRole: userRole,
        userPhone: userPhone,
        userCustomerId: userCustomerId,
      ),
    ),
    CustomerManagementScreen(),
    ShareholderManagementScreen(),
    AgentManagementScreen(),
    SubAgentManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth >= 1000;
        bool isTablet = constraints.maxWidth <= 1000;
        bool isMobile = constraints.maxWidth <= 400;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          drawer: Drawer(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            width: 200,
            child: _buildSidebar(constraints),
          ),
          appBar:
              isMobile
                  ? AppBar(
                    backgroundColor: kBlueColor,
                    leading: Builder(
                      builder:
                          (context) => IconButton(
                            icon: Icon(PhosphorIcons.list_light),
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                          ),
                    ),
                    title: Image.asset(
                      "assets/images/emp_bg.png",
                      height: 70,
                      width: 70,
                    ),
                    centerTitle: true,
                    actionsPadding: EdgeInsets.symmetric(horizontal: 10),
                    actions: [
                      IconButton(
                        icon: Icon(Ionicons.log_out_outline, size: 22),
                        onPressed: () => _handleLogout(context),
                      ),
                    ],
                    foregroundColor: Colors.black54,
                    scrolledUnderElevation: 0,
                    elevation: 0,
                    iconTheme: const IconThemeData(color: Colors.white),
                  )
                  : null,
          body:
              isDesktop
                  ? Row(
                    children: [
                      SizedBox(
                        width: _isCollapsed ? 120 : 270,
                        child: _buildSidebar(constraints),
                      ),
                      Expanded(child: _pages[_selectedIndex]),
                    ],
                  )
                  : _pages[_selectedIndex],
          bottomNavigationBar:
              isDesktop
                  ? null
                  : BottomNavigationBar(
                    backgroundColor: kBlueColor,
                    currentIndex: _selectedIndex,
                    onTap: (index) {
                      setState(() => _selectedIndex = index);
                    },
                    items: _bottomItems,
                    unselectedLabelStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                    ),
                    selectedLabelStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                    iconSize: 20,
                    selectedItemColor: kPrimaryColor,
                    unselectedItemColor: Colors.white54,
                    unselectedIconTheme: const IconThemeData(size: 19),
                    type: BottomNavigationBarType.fixed,
                  ),
        );
      },
    );
  }

  /// ------------------- Sidebar -------------------
  Widget _buildSidebar(BoxConstraints constraints) {
    bool isMobile = constraints.maxWidth <= 600;
    double sidebarWidth = _isCollapsed ? 120 : 250;

    return Row(
      children: [
        Expanded(
          child: Container(
            width: sidebarWidth,
            decoration: const BoxDecoration(color: kBlueColor),
            child: Column(
              children: [
                // Logo
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/images/emp_bg.png",
                        height: _isCollapsed ? 40 : 110,
                        width: _isCollapsed ? 40 : 110,
                      ),
                    ],
                  ),
                ),

                isMobile ? _profileMenu() : SizedBox(),

                // Main Menu - Hide text when collapsed
                if (!_isCollapsed) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'MAIN MENU',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Flexible(
                  child: Column(
                    children: [
                      _buildMenuItem(Icons.dashboard, 'Dashboard', 0),
                      _buildMenuItem(Icons.person_pin, 'Customer', 1),
                      _buildMenuItem(Icons.handshake, 'Share holder', 2),
                      _buildMenuItem(Icons.person_add_alt_rounded, 'Agent', 3),
                      _buildMenuItem(
                        Icons.person_add_alt_rounded,
                        'Sub agent',
                        4,
                      ),
                    ],
                  ),
                ),

                _buildMenuItem(
                  Ionicons.exit_outline,
                  'Logout',
                  null,
                  onTap: () => _handleLogout(context),
                  color: kPrimaryColor.withOpacity(0.2),
                  colortext: Colors.white,
                ),

                SizedBox(height: 10),
                // User Profile
                isMobile ? SizedBox() : _profileMenu(),
              ],
            ),
          ),
        ),

        // Toggle Button using Transform
        isMobile
            ? SizedBox()
            : Align(
              alignment: Alignment.centerRight,
              child: Transform.translate(
                offset: const Offset(-10, 0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isCollapsed = !_isCollapsed;
                    });
                  },
                  child: Container(
                    width: 20,
                    height: 100,
                    decoration: BoxDecoration(
                      color: kBlueColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _profileMenu() {
    return GestureDetector(
      onTap: () => _showUserProfileDialog(context),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 20,
        ).copyWith(top: 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2F42),
          borderRadius: BorderRadius.circular(8),
        ),
        child:
            _isCollapsed
                ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: kPrimaryColor,
                    child: Text(
                      isLoading
                          ? '...'
                          : userName.split(' ').map((n) => n[0]).take(2).join(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
                : Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: kPrimaryColor,
                      child: Text(
                        isLoading
                            ? '...'
                            : userName
                                .split(' ')
                                .map((n) => n[0])
                                .take(2)
                                .join(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLoading ? 'Loading...' : userName,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          AutoSizeText(
                            isLoading ? 'Loading...' : email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
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

  void _showUserProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with avatar
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: kPrimaryColor,
                      child: Text(
                        userName.split(' ').map((n) => n[0]).take(2).join(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User Profile',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            'Account Details',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // User details
                _buildProfileDetailRow(
                  'Full Name',
                  userName.isNotEmpty ? userName : 'N/A',
                  Icons.person,
                ),
                _buildProfileDetailRow(
                  'Email',
                  email.isNotEmpty ? email : 'N/A',
                  Icons.email,
                ),
                _buildProfileDetailRow(
                  'Role',
                  userRole.isNotEmpty ? userRole : 'N/A',
                  Icons.work,
                ),
                _buildProfileDetailRow(
                  'Phone',
                  userPhone.isNotEmpty ? userPhone : 'N/A',
                  Icons.phone,
                ),
                _buildProfileDetailRow(
                  'Customer ID',
                  userCustomerId.isNotEmpty ? userCustomerId : 'N/A',
                  Icons.badge,
                ),
                _buildProfileDetailRow(
                  'Balance',
                  '\$${userBalance.toString()}',
                  Icons.account_balance_wallet,
                ),
                _buildProfileDetailRow(
                  'Share ID',
                  userShareId.isNotEmpty ? userShareId : 'N/A',
                  Icons.share,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: kPrimaryColor),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    int? index, {
    VoidCallback? onTap,
    Color? color,
    Color? colortext,
  }) {
    bool isSelected = index != null && _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color:
            color ??
            (isSelected ? kPrimaryColor.withOpacity(0.2) : Colors.transparent),
        borderRadius: BorderRadius.circular(8),
      ),
      child:
          _isCollapsed
              ? Padding(
                padding: const EdgeInsets.all(5.0),
                child: Center(
                  child: Tooltip(
                    message: title,
                    waitDuration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    textStyle: const TextStyle(
                      color: kPrimaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    child: IconButton(
                      hoverColor:
                          isSelected
                              ? Colors.transparent
                              : kSecondaryColor.withOpacity(0.2),
                      onPressed:
                          onTap ??
                          () {
                            if (index != null) {
                              setState(() {
                                _selectedIndex = index;
                              });
                            }
                          },
                      icon: Icon(icon, size: 20),
                      color:
                          colortext ??
                          (isSelected ? kPrimaryColor : Colors.white70),
                    ),
                  ),
                ),
              )
              : ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: Icon(
                  icon,
                  color:
                      colortext ??
                      (isSelected ? kPrimaryColor : Colors.white70),
                  size: 20,
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    color:
                        colortext ??
                        (isSelected ? kPrimaryColor : Colors.white70),
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                onTap:
                    onTap ??
                    () {
                      if (index != null) {
                        setState(() {
                          _selectedIndex = index;
                        });
                      }
                    },
              ),
    );
  }
}

/// ------------------- Main Content -------------------
class DashboardContent extends StatelessWidget {
  final String userName;
  final int userBalance;
  final String userRole;
  final String userPhone;
  final String userCustomerId;

  const DashboardContent({
    super.key,
    required this.userName,
    required this.userBalance,
    required this.userRole,
    required this.userPhone,
    required this.userCustomerId,
  });

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 1000;
    bool isTablet = MediaQuery.of(context).size.width <= 1000;
    bool isMobile = MediaQuery.of(context).size.width <= 400;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 15 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          SizedBox(height: isMobile ? 15 : 32),
          _buildRevenueSection(),
          SizedBox(height: isMobile ? 15 : 32),
          _buildCashflowAndExpenses(),
          SizedBox(height: isMobile ? 15 : 32),
          _buildTransactionsTable(),
        ],
      ),
    );
  }

  /// ------------------- Header -------------------
  Widget _buildHeader(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width >= 1000;
    bool isTablet =
        MediaQuery.of(context).size.width >= 400 &&
        MediaQuery.of(context).size.width < 1000;
    bool isMobile = MediaQuery.of(context).size.width < 400;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            ResponsiveText(
              'Welcome, ${userName.isNotEmpty ? userName : 'User'}',
              mobile: 15,
              tablet: 20,
              desktop: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
            SizedBox(width: 8),
            Text(
              ' 👋',
              style: TextStyle(
                color: Colors.white70,
                fontSize: ResponsiveSize(
                  mobile: 15,
                  tablet: 18,
                  desktop: 22,
                ).of(context),
              ),
            ),
          ],
        ),

        if (isDesktop || isTablet)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: ResponsiveSize(
                    mobile: 10,
                    tablet: 16,
                    desktop: 18,
                  ).of(context),
                ),
                SizedBox(width: 8),
                Text(
                  '6 Months',
                  style: TextStyle(
                    fontSize: ResponsiveSize(
                      tablet: 13,
                      desktop: 14,
                    ).of(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 16),
              ],
            ),
          ),
      ],
    );
  }

  /// ------------------- Revenue Section -------------------
  Widget _buildRevenueSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isLargeScreen = constraints.maxWidth > 1000;

        if (isLargeScreen) {
          return SizedBox(
            height: 400,
            child: Row(
              children: [
                Expanded(flex: 4, child: _buildRevenueChart(context)),
                const SizedBox(width: 20),
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          value: '\$500K',
                          label: 'Revenue projection',
                          bgColor: kSecondaryColor.withOpacity(.3),
                          icon: Icons.pie_chart,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          value: '\$250K',
                          label: 'Current revenue',
                          bgColor: kPrimaryColor.withOpacity(.3),
                          icon: Icons.account_balance_wallet,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        } else {
          return Column(
            children: [
              _buildRevenueChart(context),
              SizedBox(
                height: ResponsiveSize(
                  mobile: 15,
                  tablet: 20,
                  desktop: 24,
                ).of(context),
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      value: '\$500K',
                      label: 'Revenue projection',
                      bgColor: kSecondaryColor.withOpacity(.5),
                      icon: Icons.pie_chart,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      value: '\$250K',
                      label: 'Current revenue',
                      bgColor: kPrimaryColor.withOpacity(.3),
                      icon: Icons.account_balance_wallet,
                    ),
                  ),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    String? value,
    String? label,
    Color? bgColor,
    IconData? icon,
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ResponsiveText(
                value!,
                mobile: 15,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              SizedBox(width: 8),
              Icon(
                icon,
                color: Colors.grey,
                size: ResponsiveSize(
                  mobile: 15,
                  tablet: 20,
                  desktop: 24,
                ).of(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ResponsiveText(
            label!,
            mobile: 10,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              Row(
                children: [
                  _buildLegendItem('Current', kSecondaryColor, isMobile),
                  const SizedBox(width: 12),
                  _buildLegendItem('Projection', kPrimaryColor, isMobile),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: isMobile ? 200 : 290,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 80000,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const monthsFull = [
                          'January',
                          'February',
                          'March',
                          'April',
                          'June',
                          'July',
                        ];
                        const monthsShort = [
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'Jun',
                          'Jul',
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            isMobile
                                ? monthsShort[value.toInt()]
                                : monthsFull[value.toInt()],
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: isMobile ? 10 : 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: isMobile ? 40 : 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${(value / 1000).toInt()}K',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: isMobile ? 10 : 12,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: [
                  _buildBarGroup(context, 0, 25000, 35000),
                  _buildBarGroup(context, 1, 65000, 75000),
                  _buildBarGroup(context, 2, 55000, 40000),
                  _buildBarGroup(context, 3, 60000, 70000),
                  _buildBarGroup(context, 4, 25000, 40000),
                  _buildBarGroup(context, 5, 40000, 20000),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(
    BuildContext? context,
    int x,
    double current,
    double projection,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: current,
          color: kSecondaryColor,
          width: ResponsiveSize(
            mobile: 10,
            tablet: 12,
            desktop: 16,
          ).of(context!),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
        BarChartRodData(
          toY: projection,
          color: kPrimaryColor,
          width: ResponsiveSize(
            mobile: 10,
            tablet: 12,
            desktop: 16,
          ).of(context!),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isMobile) {
    return Row(
      children: [
        Container(
          width: isMobile ? 8 : 12,
          height: isMobile ? 8 : 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 10 : 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  /// ------------------- Cashflow + Expenses -------------------
  Widget _buildCashflowAndExpenses() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isLargeScreen = constraints.maxWidth > 1000;

        if (isLargeScreen) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildCashflowChart(context)),
              const SizedBox(width: 24),
              Expanded(child: _buildExpensesChart()),
            ],
          );
        } else {
          return Column(
            children: [
              _buildCashflowChart(context),
              SizedBox(
                height: ResponsiveSize(
                  mobile: 15,
                  tablet: 20,
                  desktop: 24,
                ).of(context),
              ),
              _buildExpensesChart(),
            ],
          );
        }
      },
    );
  }

  Widget _buildCashflowChart(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width <= 400;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              const Text(
                'Cashflow',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              _buildTabButton(context, 'Income', true),
              const SizedBox(width: 8),
              _buildTabButton(context, 'Expenses', false),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: isMobile ? 200 : 285,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const fullMonths = [
                          'January',
                          'February',
                          'March',
                          'April',
                          'May',
                          'June',
                        ];

                        const shortMonths = [
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'May',
                          'Jun',
                        ];

                        final isMobile =
                            MediaQuery.of(context).size.width < 600;

                        final index = value.toInt();
                        if (index < fullMonths.length) {
                          return SideTitleWidget(
                            meta: meta,
                            space: 8,
                            child: Text(
                              isMobile ? shortMonths[index] : fullMonths[index],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '\$${(value / 1000).toInt()}K',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 200),
                      FlSpot(1, 250),
                      FlSpot(2, -50),
                      FlSpot(3, 100),
                      FlSpot(4, 50),
                      FlSpot(5, -200),
                    ],
                    isCurved: true,
                    color: kPrimaryColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, -100),
                      FlSpot(1, 50),
                      FlSpot(2, -250),
                      FlSpot(3, 150),
                      FlSpot(4, 100),
                      FlSpot(5, 150),
                    ],
                    isCurved: true,
                    color: Colors.grey,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                    dashArray: [5, 5],
                  ),
                ],
                minY: -400,
                maxY: 400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(BuildContext context, String text, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveSize(
          mobile: 5,
          tablet: 12,
          desktop: 12,
        ).of(context),
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isSelected ? kPrimaryColor : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ResponsiveText(
        text,
        mobile: 9,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade600,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildExpensesChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            'Expenses',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 150,
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: kPrimaryColor,
                          value: 23.5,
                          radius: 40,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          color: kSecondaryColor,
                          value: 17.5,
                          radius: 40,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          color: kPrimaryColor.withOpacity(.5),
                          value: 12.5,
                          radius: 40,
                          showTitle: false,
                        ),
                        PieChartSectionData(
                          color: kSecondaryColor.withOpacity(.5),
                          value: 4.5,
                          radius: 40,
                          showTitle: false,
                        ),
                      ],
                      centerSpaceRadius: 30,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Column(
                children: [
                  const Text(
                    '\$80K',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const Text(
                    '6 Months',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              _buildExpenseItem('Goods', '23.5K', kPrimaryColor),
              _buildExpenseItem('General', '17.5K', kSecondaryColor),
              _buildExpenseItem(
                'Other',
                '12.5K',
                kPrimaryColor.withOpacity(.5),
              ),
              _buildExpenseItem(
                'Fees',
                '4.5K',
                kSecondaryColor.withOpacity(.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(String label, String amount, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  /// ------------------- Transactions -------------------
  Widget _buildTransactionsTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth = constraints.maxWidth;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: 24,
            horizontal: ResponsiveSize(
              mobile: 0,
              tablet: 24,
              desktop: 24,
            ).of(context),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveSize(
                    mobile: 15,
                    tablet: 0,
                    desktop: 0,
                  ).of(context),
                ),
                child: Text(
                  'Transactions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (maxWidth > 650)
                _buildExpandedRows()
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildDataTable(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpandedRows() {
    return Column(
      children: [
        _buildTableRowWidget(
          '#22312',
          'Income',
          'March 14, 2025',
          '+\$200',
          'Completed',
          Colors.green,
        ),
        _buildTableRowWidget(
          '#42331',
          'Expense',
          'March 13, 2025',
          '-\$400',
          'Pending',
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    return DataTable(
      columnSpacing: 24,
      columns: const [
        DataColumn(label: Text("ID")),
        DataColumn(label: Text("TYPE")),
        DataColumn(label: Text("DATE")),
        DataColumn(label: Text("AMOUNT")),
        DataColumn(label: Text("STATUS")),
      ],
      rows: [
        DataRow(
          cells: [
            DataCell(Text('#22312', style: TextStyle(color: kPrimaryColor))),
            DataCell(Text('Income')),
            DataCell(Text('March 14, 2025')),
            DataCell(
              Text(
                '+\$200',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataCell(
              Row(
                children: [
                  const Icon(Icons.circle, color: Colors.green, size: 10),
                  const SizedBox(width: 6),
                  Text("Completed", style: TextStyle(color: Colors.green)),
                ],
              ),
            ),
          ],
        ),
        DataRow(
          cells: [
            DataCell(Text('#42331', style: TextStyle(color: kPrimaryColor))),
            DataCell(Text('Expense')),
            DataCell(Text('March 13, 2025')),
            DataCell(
              Text(
                '-\$400',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataCell(
              Row(
                children: [
                  const Icon(Icons.circle, color: Colors.purple, size: 10),
                  const SizedBox(width: 6),
                  Text("Pending", style: TextStyle(color: Colors.purple)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableRowWidget(
    String id,
    String type,
    String date,
    String amount,
    String status,
    Color statusColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(id, style: TextStyle(color: kPrimaryColor)),
          ),
          Expanded(flex: 1, child: Text(type)),
          Expanded(flex: 2, child: Text(date)),
          Expanded(
            flex: 1,
            child: Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: amount.startsWith('+') ? Colors.green : Colors.red,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(status, style: TextStyle(color: statusColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
