import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gold_pos/utils/colors.dart';
import '../../utils/responsive_size.dart';
import '../../utils/responsive_text.dart';

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
    bool isMobile = MediaQuery.of(context).size.width <= 600;

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
        MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 1000;
    bool isMobile = MediaQuery.of(context).size.width < 600;

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
    bool isMobile = MediaQuery.of(context).size.width <= 600;

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
