import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

class ExpenseDetailsScreen extends StatefulWidget {
  final String category;
  const ExpenseDetailsScreen(this.category, {Key? key}) : super(key: key);

  @override
  _ExpenseDetailsScreenState createState() => _ExpenseDetailsScreenState();
}

class _ExpenseDetailsScreenState extends State<ExpenseDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<FlSpot> _dataPoints = [];
  List<Map<String, dynamic>> _expenseDetails = [];
  double _totalExpenses = 0.0;
  String _selectedPeriod = "Month";

  @override
  void initState() {
    super.initState();
    _fetchExpenseDetails();
  }

  void _fetchExpenseDetails() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('expenses')
          .where('category', isEqualTo: widget.category)
          .get();

      List<Map<String, dynamic>> expenseDetails = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Sort data by date in descending order
      expenseDetails.sort((a, b) {
        final dateA = (a['date'] as Timestamp).toDate();
        final dateB = (b['date'] as Timestamp).toDate();
        return dateB.compareTo(dateA); // Changed to descending order
      });

      double totalExpenses = 0.0;
      List<FlSpot> dataPoints = [];
      for (int i = 0; i < expenseDetails.length; i++) {
        final data = expenseDetails[i];
        final double amount = data['amount'];
        totalExpenses += amount;
        dataPoints.add(FlSpot(i.toDouble(), amount));
      }

      setState(() {
        _dataPoints = dataPoints;
        _expenseDetails = expenseDetails;
        _totalExpenses = totalExpenses;
      });
    } catch (e) {
      print('Error fetching expense details: $e');
    }
  }

  void _onPeriodChanged(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _fetchExpenseDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category} Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Ksh. ${_totalExpenses.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat.yMMMd().format(DateTime.now()),
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 60),
                  /*ToggleButtons(
                    children: [
                      Text('Week'),
                      Text('Month'),
                      Text('Year'),
                    ],
                    isSelected: [
                      _selectedPeriod == "Week",
                      _selectedPeriod == "Month",
                      _selectedPeriod == "Year",
                    ],
                    onPressed: (index) {
                      String period;
                      if (index == 0) period = "Week";
                      else if (index == 1) period = "Month";
                      else period = "Year";
                      _onPeriodChanged(period);
                    },
                  ),*/
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _dataPoints.isNotEmpty
                  ? Container(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: _dataPoints.length - 1,
                          minY: 0,
                          maxY: _dataPoints.map((e) => e.y).reduce((a, b) => a > b ? a : b),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _dataPoints,
                              isCurved: true,
                              colors: [Colors.black],
                              barWidth: 4,
                              belowBarData: BarAreaData(
                                show: false,
                                colors: [Colors.blue.withOpacity(0.3)],
                              ),
                              dotData: FlDotData(
                                show: true,
                              ),
                            ),
                          ],
                          titlesData: FlTitlesData(
                            leftTitles: SideTitles(showTitles: false),
                            rightTitles: SideTitles(showTitles: false),
                            topTitles: SideTitles(showTitles: false),
                            bottomTitles: SideTitles(
                              showTitles: false,
                              getTitles: (value) {
                                if (_selectedPeriod == "Week") {
                                  return DateFormat('E').format(
                                    (value.toInt() < _expenseDetails.length)
                                        ? (_expenseDetails[value.toInt()]['date'] as Timestamp).toDate()
                                        : DateTime.now(),
                                  );
                                } else if (_selectedPeriod == "Month") {
                                  return DateFormat('MMM').format(
                                    (value.toInt() < _expenseDetails.length)
                                        ? (_expenseDetails[value.toInt()]['date'] as Timestamp).toDate()
                                        : DateTime.now(),
                                  );
                                } else {
                                  return DateFormat('yyyy').format(
                                    (value.toInt() < _expenseDetails.length)
                                        ? (_expenseDetails[value.toInt()]['date'] as Timestamp).toDate()
                                        : DateTime.now(),
                                  );
                                }
                              },
                              reservedSize: 22,
                              margin: 8,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(show: false),
                        ),
                      ),
                    )
                  : Center(child: Text('No data available')),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expense Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _expenseDetails.length,
                    itemBuilder: (ctx, index) {
                      final expense = _expenseDetails[index];
                      return ListTile(
                        leading: Icon(Iconsax.wallet_minus, color: Colors.deepPurple),
                        title: Text(expense['description']),
                        subtitle: Text(
                          DateFormat.yMMMd().format((expense['date'] as Timestamp).toDate()),
                          style: TextStyle(color: Colors.grey),
                        ),
                        trailing: Text(
                          '- Ksh. ${expense['amount']}',
                          style: TextStyle(color: Color.fromARGB(255, 234, 17, 2), fontSize: 14),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
