import 'package:flutter/material.dart';

class Transaction {
  final String name;
  final String description;
  final String type; // Credit / Debit
  final String amount;
  final String date;
  final String status;
  final String avatar;

  Transaction({
    required this.name,
    required this.description,
    required this.type,
    required this.amount,
    required this.date,
    required this.status,
    required this.avatar,
  });
}

class AllTransaction extends StatefulWidget {
  final int currentPage;
  final int itemsPerPage;
  final String searchQuery;
  final String? expandedTransactionId;
  final Function(String?)? onExpandedTransactionChanged;
  final Function(int)? onPageChanged;

  const AllTransaction({
    Key? key,
    this.currentPage = 1,
    this.itemsPerPage = 25,
    this.searchQuery = '',
    this.expandedTransactionId,
    this.onExpandedTransactionChanged,
    this.onPageChanged,
  }) : super(key: key);

  @override
  State<AllTransaction> createState() => AllTransactionState();
}

class AllTransactionState extends State<AllTransaction> {
  final List<Transaction> transactions = [
    Transaction(
      name: "Mohammed safuvan tp",
      description: "A bag of cement",
      type: "Credit",
      amount: "N8,000",
      date: "22 Jan, 2025",
      status: "Pending",
      avatar: "assets/avatar1.png",
    ),
    Transaction(
      name: "Mary John",
      description: "Electric Bill Payment",
      type: "Debit",
      amount: "N15,000",
      date: "25 Jan, 2025",
      status: "Completed",
      avatar: "assets/avatar2.png",
    ),
    Transaction(
      name: "Ali Hassan",
      description: "Furniture Purchase",
      type: "Credit",
      amount: "N50,000",
      date: "30 Jan, 2025",
      status: "Pending",
      avatar: "assets/avatar3.png",
    ),
  ];

  List<Transaction> get filteredTransactions {
    if (widget.searchQuery.isEmpty) {
      return transactions;
    }
    return transactions.where((txn) {
      return txn.name.toLowerCase().contains(widget.searchQuery.toLowerCase()) ||
          txn.description.toLowerCase().contains(widget.searchQuery.toLowerCase()) ||
          txn.type.toLowerCase().contains(widget.searchQuery.toLowerCase()) ||
          txn.status.toLowerCase().contains(widget.searchQuery.toLowerCase());
    }).toList();
  }

  List<Transaction> get paginatedTransactions {
    final filtered = filteredTransactions;
    final startIndex = (widget.currentPage - 1) * widget.itemsPerPage;
    final endIndex = (startIndex + widget.itemsPerPage).clamp(0, filtered.length);

    if (startIndex >= filtered.length) {
      return [];
    }
    return filtered.sublist(startIndex, endIndex);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1000;
    final isTablet = MediaQuery.of(context).size.width > 700 && MediaQuery.of(context).size.width <= 1000;
    final isTabletMini = MediaQuery.of(context).size.width > 400 && MediaQuery.of(context).size.width <= 700;
    final isMobile = MediaQuery.of(context).size.width <= 400;

    return _buildTransactionTable(isDesktop, isTablet, isMobile, isTabletMini);
  }

  Widget _buildTransactionTable(bool isDesktop, bool isTablet, bool isMobile, bool isTabletMini) {
    if (isMobile) {
      return _buildMobileTransactionList(isDesktop, isTablet, isTabletMini, isMobile);
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
            child: paginatedTransactions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              itemCount: paginatedTransactions.length,
              itemBuilder: (context, index) {
                final txn = paginatedTransactions[index];
                final txnId = '${txn.name}_$index';
                final isExpanded = widget.expandedTransactionId == txnId;

                return Column(
                  children: [
                    _buildTransactionRow(txn, txnId),
                    if (isExpanded) _buildExpandedtxnDetails(txn,isDesktop,isTablet,isTabletMini,isMobile),
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
            widget.searchQuery.isEmpty ? 'No transactions found' : 'No transactions match your search',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
          ),
          SizedBox(height: 8),
          Text(
            widget.searchQuery.isEmpty ? 'Add your first transaction to get started' : 'Try adjusting your search terms',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTransactionList(bool isDesktop, bool isTablet, bool isTabletMini, bool isMobile) {
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
            if (isExpanded) _buildExpandedtxnDetails(txn,isDesktop,isTablet,isTabletMini,isMobile),
          ],
        );
      },
    );
  }

  Widget _buildMobileTransactionCard(Transaction txn, String txnId) {
    final isExpanded = widget.expandedTransactionId == txnId;

    return Container(
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
              _buildAvatar(txn.name),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  txn.name,
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                ),
              ),
              GestureDetector(
                onTap: () => _toggleExpansion(txnId),
                child: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(txn.amount, style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w500)),
              Text(txn.date, style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text('Name', style: _headerTextStyle())),
          Expanded(flex: 2, child: Text('Type', style: _headerTextStyle())),
          Expanded(flex: 2, child: Text('Amount', style: _headerTextStyle())),
          Expanded(flex: 2, child: Text('Date', style: _headerTextStyle())),
          Expanded(flex: 2, child: Text('Status', style: _headerTextStyle())),
          Container(width: 40, child: Text('Action', style: _headerTextStyle())),
        ],
      ),
    );
  }

  TextStyle _headerTextStyle() {
    return TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w500, fontSize: 12);
  }

  Widget _buildTransactionRow(Transaction txn, String txnId) {
    final isExpanded = widget.expandedTransactionId == txnId;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
      child: InkWell(
        onTap: () => _toggleExpansion(txnId),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  _buildAvatar(txn.name),
                  SizedBox(width: 10),
                  Expanded(child: Text(txn.name, style: TextStyle(fontWeight: FontWeight.w600))),
                ],
              ),
            ),
            Expanded(flex: 2, child: Text(txn.type, style: TextStyle(color: txn.type == "Credit" ? Colors.green : Colors.red))),
            Expanded(flex: 2, child: Text(txn.amount, style: TextStyle(fontWeight: FontWeight.w600))),
            Expanded(flex: 2, child: Text(txn.date)),
            Expanded(flex: 2, child: Text(txn.status, style: TextStyle(color: txn.status == "Completed" ? Colors.green : Colors.orange))),
            Container(
              width: 40,
              child: GestureDetector(
                onTap: () => _toggleExpansion(txnId),
                child: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedtxnDetails(Transaction txn, bool isDesktop, bool isTablet, bool isTabletMini,bool isMobile) {
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
              _buildAvatar(txn.name, size: isDesktop? 40 : (isTablet ? 36 : (isTabletMini ? 32 : 28))),
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
          _buildInfoWrap(txn,isDesktop,isTablet,isTabletMini,isMobile),
        ],
      ),
    );
  }

  Widget _buildInfoWrap(Transaction txn,isDesktop,isTablet,isTabletMini,isMobile) {
    return Wrap(
      spacing: isDesktop ? 100 : isTablet ? 100 :isTabletMini ? 70 :40,
      runSpacing: isDesktop ? 10 :10,
      children: [
        //_buildInfoItem("Name", txn.name),
        _buildInfoItem("Type", txn.type),
        _buildInfoItem("Amount", txn.amount),
        _buildInfoItem("Date", txn.date),
        _buildInfoItem("Status", txn.status),
      ],
    );
  }


  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, color: Color(0xFF1F2937), fontWeight: FontWeight.w500)),
      ]),
    );
  }

  void _toggleExpansion(String txnId) {
    widget.onExpandedTransactionChanged?.call(widget.expandedTransactionId == txnId ? null : txnId);
  }

  Widget _buildAvatar(String name, {double size = 16}) {
    return CircleAvatar(
      radius: size,
      backgroundColor: _getAvatarColor(name),
      child: Text(
        name.split(' ').map((n) => n[0]).take(2).join(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.6,
        ),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFFBDAC67), // Light Gold
      const Color(0xFFFBBF24), // Amber Gold
      const Color(0xFFEAB308), // Classic Gold
      const Color(0xFFCA8A04), // Dark Gold
      const Color(0xFFB45309), // Bronze
      const Color(0xFF78350F), // Deep Brown/Antique
    ];
    return colors[name.hashCode % colors.length];
  }
}
