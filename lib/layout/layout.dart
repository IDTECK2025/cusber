import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:gold_pos/agent/agent_page.dart';
import 'package:gold_pos/customer/customer_page.dart';
import 'package:gold_pos/dashboard.dart';
import 'package:gold_pos/lock/lock.dart';
import 'package:gold_pos/shareholder/shareholder_page.dart';
import 'package:gold_pos/subagent/subAgent_page.dart';
import 'package:gold_pos/utils/colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ionicons/ionicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uicons/uicons.dart';

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
      home: const Layout(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Layout extends StatefulWidget {
  final int? initialIndex;
  final int? customerTab;
  const Layout({super.key, this.initialIndex = 0, this.customerTab = 0});

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  String userName = 'User';
  String userShareId = '';
  String email = '';
  String userRole = '';
  String userPhone = '';
  String userCustomerId = '';
  String createdDate = '';
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
        createdDate = prefs.getString('createdDate') ?? '';
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
      print('Created Date: $createdDate');
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
        await prefs.remove('createdDate');
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
    DashboardContent(
      userName: userName,
      userBalance: userBalance,
      userRole: userRole,
      userPhone: userPhone,
      userCustomerId: userCustomerId,
    ),
    CustomerManagementScreen(initialTab: widget.customerTab),
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
        bool isMobile = constraints.maxWidth <= 600;

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
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Determine device type and responsive values
                final isDesktop = constraints.maxWidth > 1200;
                final isTablet =
                    constraints.maxWidth > 600 && constraints.maxWidth <= 1200;
                final isMobile = constraints.maxWidth <= 600;

                // Responsive dimensions
                final dialogWidth =
                    isDesktop
                        ? 450.0
                        : isTablet
                        ? constraints.maxWidth * 0.7
                        : constraints.maxWidth * 0.9;

                final horizontalMargin = isMobile ? 16.0 : 24.0;
                final verticalMargin = isMobile ? 20.0 : 40.0;

                // Responsive text sizes
                final nameTextSize =
                    isMobile
                        ? 24.0
                        : isTablet
                        ? 26.0
                        : 28.0;
                final handleTextSize = isMobile ? 14.0 : 16.0;
                final roleTextSize = isMobile ? 14.0 : 16.0;
                final statValueSize = isMobile ? 16.0 : 18.0;
                final statLabelSize = isMobile ? 10.0 : 12.0;

                // Avatar size
                final avatarSize =
                    isMobile
                        ? 100.0
                        : isTablet
                        ? 110.0
                        : 120.0;
                final avatarTextSize =
                    isMobile
                        ? 30.0
                        : isTablet
                        ? 33.0
                        : 36.0;

                return Container(
                  width: dialogWidth,
                  height: isMobile ? null : null,
                  margin: EdgeInsets.symmetric(
                    horizontal: horizontalMargin,
                    vertical: verticalMargin,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header Section
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isMobile ? 24 : 32),
                          child: Column(
                            children: [
                              // Close button
                              Align(
                                alignment: Alignment.topRight,
                                child: GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      size: isMobile ? 14 : 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: isMobile ? 12 : 16),
                              // Profile Avatar
                              Container(
                                width: avatarSize,
                                height: avatarSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      kPrimaryColor,
                                      kPrimaryColor.withOpacity(0.8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kPrimaryColor.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    userName
                                        .split(' ')
                                        .map((n) => n[0])
                                        .take(2)
                                        .join(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: avatarTextSize,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: isMobile ? 16 : 24),
                              // User Name
                              Text(
                                userName.isNotEmpty ? userName : 'N/A',
                                style: TextStyle(
                                  fontSize: nameTextSize,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1F2937),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              // User Handle/Email
                              Text(
                                email.isNotEmpty
                                    ? '@${email.split('@')[0]}'
                                    : '@user',
                                style: TextStyle(
                                  fontSize: handleTextSize,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: isMobile ? 12 : 16),
                              // Role Description
                              Text(
                                userRole.isNotEmpty ? userRole : 'User',
                                style: TextStyle(
                                  fontSize: roleTextSize,
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Stats Section - Responsive Layout
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 24 : 32,
                            vertical: isMobile ? 12 : 16,
                          ),
                          child: _buildStats(statValueSize, statLabelSize),
                        ),

                        SizedBox(height: isMobile ? 12 : 16),

                        // Contact Details Section
                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.symmetric(
                            horizontal: isMobile ? 24 : 32,
                          ),
                          padding: EdgeInsets.all(isMobile ? 16 : 24),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Contact Details',
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              SizedBox(height: isMobile ? 12 : 16),
                              _buildContactDetailRow(
                                'Email',
                                email.isNotEmpty ? email : 'N/A',
                                Icons.email_outlined,
                                isMobile,
                              ),
                              _buildContactDetailRow(
                                'Phone',
                                userPhone.isNotEmpty ? userPhone : 'N/A',
                                Icons.phone_outlined,
                                isMobile,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: isMobile ? 24 : 32),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Desktop/Tablet stats layout (horizontal)
  Widget _buildStats(double valueSize, double labelSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: _buildStatItem(
            'Balance',
            '\₹${userBalance.toString()}',
            valueSize,
            labelSize,
          ),
        ),
        Container(height: 40, width: 1, color: Colors.grey[300]),
        Expanded(
          child: _buildStatItem('Since', createdDate, valueSize, labelSize),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    double valueSize,
    double labelSize,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: labelSize,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildContactDetailRow(
    String label,
    String value,
    IconData icon,
    bool isMobile,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child:
          isMobile
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
              : Row(
                children: [
                  Icon(icon, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),

                  Flexible(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1F2937),
                      ),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
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
