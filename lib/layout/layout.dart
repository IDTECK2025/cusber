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
