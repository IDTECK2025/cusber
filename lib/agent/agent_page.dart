import 'package:auto_size_text/auto_size_text.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gold_pos/api.dart';
import 'package:gold_pos/utils/avathar.dart';
import 'package:gold_pos/utils/diamond_indicator.dart';
import 'package:gold_pos/utils/refresh_button.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/colors.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agent Management',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: AgentManagementScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Agent {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? adhar;
  final String? pancard;
  final String? bank;
  final String? ifsc;
  final String? acc;
  final String? branch;
  final String? city;
  final String? state;
  final String? address;
  final String? pin;
  final String? password;
  final String role;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  Agent({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.adhar,
    this.pancard,
    this.bank,
    this.ifsc,
    this.acc,
    this.branch,
    this.city,
    this.state,
    this.address,
    this.password,
    this.pin,
    required this.role,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      adhar: json['adhar']?.toString(),
      pancard: json['pancard']?.toString(),
      bank: json['Bank']?.toString(),
      ifsc: json['IFSC']?.toString(),
      acc: json['acc']?.toString(),
      branch: json['branch']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      address: json['addrass']?.toString(),
      pin: json['pin']?.toString(),
      password: json['password']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      active:
          json['active'] is bool
              ? json['active']
              : (json['active']?.toString().toLowerCase() == 'true'),
      createdAt: DateTime.parse(
        json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class AgentManagementScreen extends StatefulWidget {
  const AgentManagementScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AgentManagementScreenState createState() => _AgentManagementScreenState();
}

class _AgentManagementScreenState extends State<AgentManagementScreen> {
  String searchQuery = '';
  int currentPage = 1;
  int itemsPerPage = 10;
  String? expandedAgentId;

  List<Agent> agents = [];
  bool isLoading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchAgents();
  }

  // Method to get auth token from SharedPreferences
  Future<String?> getAuthTokenFromPrefs() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(
        'token',
      ); // or whatever key you used to store the token
    } catch (e) {
      print('Error getting token from SharedPreferences: $e');
      return null;
    }
  }

  Future<void> fetchAgents() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final token = await getAuthTokenFromPrefs();

      if (token == null || token.isEmpty) {
        setState(() {
          error = 'Please login first - No authentication token found';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
      }
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Debug: Print the structure of the response
        print('Data structure: ${data.runtimeType}');
        print('Data keys: ${data is Map ? data.keys.toList() : 'Not a Map'}');

        List<dynamic> userData = [];

        // Handle different response structures
        if (data is List) {
          userData = data;
        } else if (data is Map) {
          userData = data['data'] ?? data['users'] ?? data['result'] ?? [];
        }

        print('User data length: ${userData.length}');

        // Parse each user safely
        List<Agent> allAgents = [];
        for (int i = 0; i < userData.length; i++) {
          try {
            var userJson = userData[i];
            print('Parsing user $i: $userJson');
            allAgents.add(Agent.fromJson(userJson));
          } catch (e) {
            print('Error parsing user at index $i: $e');
            print('User data: ${userData[i]}');
            // Continue with other users instead of failing completely
          }
        }

        setState(() {
          agents =
              allAgents
                  .where((user) => user.role.toLowerCase() == 'agent')
                  .toList();
          isLoading = false;
        });

        print('Found ${agents.length} agents');
      } else if (response.statusCode == 401) {
        setState(() {
          error = 'Authentication failed. Token may be expired.';
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Failed to load users: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error fetching users: $e';
        isLoading = false;
      });
      print('Exception in fetchAgents: $e');
    }
  }

  List<Agent> get filteredAgents {
    if (searchQuery.isEmpty) {
      return agents;
    }

    return agents.where((agent) {
      return agent.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (agent.email?.toLowerCase().contains(searchQuery.toLowerCase()) ??
              false) ||
          (agent.phone?.contains(searchQuery) ?? false);
    }).toList();
  }

  List<Agent> get paginatedAgents {
    final filtered = filteredAgents;
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, filtered.length);

    if (startIndex >= filtered.length) return [];
    return filtered.sublist(startIndex, endIndex);
  }

  int get totalItems => filteredAgents.length;

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
                  _buildSearchAndFilter(isDesktop, isTablet, isMobile),
                  SizedBox(height: 20),
                  Expanded(
                    child: _buildAgentList(
                      isDesktop,
                      isTablet,
                      isMobile,
                      isTabletMini,
                    ),
                  ),
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
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop, bool isTablet, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Agents',
          style: TextStyle(
            fontSize: isDesktop ? 28 : (isTablet ? 24 : 20),
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        RefreshButton(isDesktop, isTablet, onTap: fetchAgents),
      ],
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
                  hintText: 'Search agent...',
                  hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                  border: InputBorder.none,
                  icon: Icon(Icons.search, size: 16, color: Color(0xFF6B7280)),
                ),
                onChanged:
                    (value) => setState(() {
                      searchQuery = value;
                      currentPage = 1;
                    }),
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

  Widget _buildAgentList(
    bool isDesktop,
    bool isTablet,
    bool isTabletMini,
    bool isMobile,
  ) {
    if (isLoading) {
      return Center(child: DiamondIndicator(color: kPrimaryColor));
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              error!,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: fetchAgents, child: Text('Retry')),
          ],
        ),
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
                paginatedAgents.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      itemCount: paginatedAgents.length,
                      itemBuilder: (context, index) {
                        final agent = paginatedAgents[index];
                        final isExpanded = expandedAgentId == agent.id;

                        return Column(
                          children: [
                            _buildAgentRow(
                              agent,
                              isDesktop,
                              isTablet,
                              false,
                              agent.id,
                            ),
                            if (isExpanded)
                              _ExpandedAgentDetails(
                                agent,
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
          Icon(Icons.people_outline, size: 80, color: Color(0xFF6B7280)),
          SizedBox(height: 16),
          Text(
            searchQuery.isEmpty
                ? 'No agents found'
                : 'No agents match your search',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Add your first agent to get started'
                : 'Try adjusting your search terms',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
          if (searchQuery.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 16),
              child: ElevatedButton(
                onPressed: fetchAgents,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text('Refresh'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAgentRow(
    Agent agent,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
    String agentId,
  ) {
    final isExpanded = expandedAgentId == agentId;
    final holderId = agent.id;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: InkWell(
        onTap: () => _toggleExpansion(holderId),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Avatar(name: agent.name),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          agent.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        // if (!isDesktop)
                        //   Text(
                        //     agent.email ?? 'N/A',
                        //     style: TextStyle(
                        //       color: Color(0xFF6B7280),
                        //       fontSize: 12,
                        //     ),
                        //   ),
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
                  agent.email ?? 'N/A',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            if (isDesktop || isTablet)
              Expanded(
                flex: 2,
                child: Text(
                  agent.phone ?? 'N/A',
                  style: TextStyle(color: Color(0xFF1F2937)),
                ),
              ),
            Expanded(
              flex: 2,
              child: Text(
                agent.active ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: agent.active ? Colors.green[700] : Colors.red[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              width: 40,
              child: GestureDetector(
                onTap: () => _toggleExpansion(holderId),
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                        isExpanded
                            ? kPrimaryColor.withOpacity(0.1)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: isExpanded ? kPrimaryColor : Color(0xFF6B7280),
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

  Widget _ExpandedAgentDetails(
    Agent agent,
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
              Avatar(name: agent.name, size: 40),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      agent.email ?? 'N/A',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                    ),
                    Text(
                      agent.phone ?? 'N/A',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        agent.active ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: kPrimaryColor,
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
          Text(
            'Basic Information:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 16),
          _buildInfoWrap(agent, isDesktop, isTablet, isTabletMini, isMobile),
        ],
      ),
    );
  }

  Widget _buildInfoWrap(
    Agent agent,
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
        _buildInfoItem("Address", agent.address ?? 'N/A'),
        _buildInfoItem("City", agent.city ?? 'N/A'),
        _buildInfoItem("Aadhaar No", agent.adhar ?? 'N/A'),
        _buildInfoItem("Pan No", agent.pancard ?? 'N/A'),
        _buildInfoItem('ACCOUNT NUMBER ', agent.acc ?? 'N/A'),
        _buildInfoItem('HOLDER NAME', agent.bank ?? 'N/A'),
        _buildInfoItem('BANK BRANCH', agent.branch ?? 'N/A'),
        _buildInfoItem('IFSC CODE', agent.ifsc ?? 'N/A'),
        _buildInfoItem('Password', agent.password ?? 'N/A'),
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

  void _toggleExpansion(String agentId) {
    setState(() {
      if (expandedAgentId == agentId) {
        expandedAgentId = null;
      } else {
        expandedAgentId = agentId;
      }
    });
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
          Expanded(flex: 3, child: Text('Agent', style: _headerTextStyle())),
          if (isDesktop)
            Expanded(flex: 3, child: Text('Email', style: _headerTextStyle())),
          if (isDesktop || isTablet)
            Expanded(flex: 2, child: Text('Phone', style: _headerTextStyle())),
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

  Widget _buildPaginationInfo({
    bool showRangeText = true,
    bool showPerPage = true,
  }) {
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
