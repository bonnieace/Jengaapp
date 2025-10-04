import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:pie_chart/pie_chart.dart';
import '../models/expense.dart';
import '../widgets/expense_list.dart';
import './add_expenses_screen.dart';
import 'expensedetails.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference _expensesCollection;
  double _totalExpenses = 0.0;
  int _selectedIndex = 0;
  String? _selectedCategory;
  List<String> _categories = [];
  Map<String, double> _categoryDataMap = {};
  Map<String, Color> _categoryColors = {};

  @override
  void initState() {
    super.initState();
    _expensesCollection = _firestore.collection('expenses');
    _fetchCategories();
    _calculateTotalExpenses();
  }
  Stream<List<String>> _categoriesStream() {
  return _firestore.collection('expenses').snapshots().map((snapshot) {
    return snapshot.docs
        .map((doc) => doc['category'] as String)
        .toSet()
        .toList();
  });
}

Stream<Map<String, dynamic>> _expensesStream() {
  return _firestore.collection('expenses').snapshots().map((snapshot) {
    double total = 0.0;
    Map<String, double> categoryDataMap = {};
    Map<String, Color> categoryColors = {};
    
    for (var doc in snapshot.docs) {
      total += doc['amount'];
      String category = doc['category'];
      if (categoryDataMap.containsKey(category)) {
        categoryDataMap[category] = categoryDataMap[category]! + doc['amount'];
      } else {
        categoryDataMap[category] = doc['amount'];
        // Assign a random color to the category for the pie chart
        categoryColors[category] = Colors.primaries[categoryDataMap.length % Colors.primaries.length];
      }
    }

    return {
      'total': total,
      'categoryDataMap': categoryDataMap,
      'categoryColors': categoryColors,
    };
  });
}


  void _fetchCategories() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('expenses').get();
      setState(() {
        _categories = snapshot.docs.map((doc) => doc['category'] as String).toSet().toList();
        _categories.insert(0, "All"); // Add "All" option at the beginning
      });
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  void _addExpense(String category, String description, double amount) async {
    try {
      await _expensesCollection.add({
        'category': category,
        'description': description,
        'amount': amount,
        'date': DateTime.now(),
      });
      _calculateTotalExpenses(); // Recalculate total expenses after adding a new expense
    } catch (e) {
      print('Error adding expense: $e');
    }
  }

  void _calculateTotalExpenses() async {
    try {
      double total = 0.0;
      Map<String, double> categoryDataMap = {};
      Map<String, Color> categoryColors = {};
      final QuerySnapshot snapshot;
      if (_selectedCategory == null || _selectedCategory == "All") {
        snapshot = await _firestore.collection('expenses').get();
      } else {
        snapshot = await _firestore.collection('expenses')
            .where('category', isEqualTo: _selectedCategory).get();
      }
      for (var doc in snapshot.docs) {
        total += doc['amount'];
        String category = doc['category'];
        if (categoryDataMap.containsKey(category)) {
          categoryDataMap[category] = categoryDataMap[category]! + doc['amount'];
        } else {
          categoryDataMap[category] = doc['amount'];
          // Assign a random color to the category for the pie chart
          categoryColors[category] = Colors.primaries[categoryDataMap.length % Colors.primaries.length];
        }
      }
      setState(() {
        _totalExpenses = total;
        _categoryDataMap = categoryDataMap;
        _categoryColors = categoryColors;
      });
      print('Total expenses for $_selectedCategory: $_totalExpenses');
    } catch (e) {
      print('Error calculating total expenses: $e');
    }
  }

  void _onCategoryChanged(String? newCategory) {
    setState(() {
      _selectedCategory = newCategory;
    });
    print('Selected category: $_selectedCategory');
    _calculateTotalExpenses();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        // Navigate to the current homepage or main screen
        Navigator.pushReplacementNamed(context, '/'); // Example navigation to home screen
        break;
      case 1:
        // Navigate to another screen if needed
        Navigator.pushReplacementNamed(context, '/mortalityScreen'); // Example navigation to another screen
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/vaccineTracker'); // Example navigation to another screen
      // No action needed for index 2 (current screen)
    }
  }

  @override
@override
Widget build(BuildContext context) {
  return Scaffold(
  appBar: AppBar(
    title: const Text('Expense Tracker', style: TextStyle(fontFamily: 'Roboto', fontSize: 24, fontWeight: FontWeight.bold,color: Colors.white)),
    actions: [
      TextButton(
        child: const Icon(Icons.add_circle_outline_sharp, color: Colors.white),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AddExpenseScreen(_addExpense),
          ));
        },
      ),
    ],
    backgroundColor: Colors.deepPurple,
    elevation: 5,
  ),
  body:LayoutBuilder(
  builder: (context, constraints) {
    // Determine if we are on a large screen
    bool isLargeScreen = constraints.maxWidth > 600;
    return StreamBuilder<List<String>>(
      stream: _categoriesStream(),
      builder: (context, categorySnapshot) {
        if (categorySnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        _categories = categorySnapshot.data ?? [];
        _categories.insert(0, "All");

        return StreamBuilder<Map<String, dynamic>>(
          stream: _expensesStream(),
          builder: (context, expenseSnapshot) {
            if (expenseSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            final expenseData = expenseSnapshot.data ?? {};
            _totalExpenses = expenseData['total'] ?? 0.0;
            _categoryDataMap = expenseData['categoryDataMap'] ?? {};
            _categoryColors = expenseData['categoryColors'] ?? {};

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category filter row with horizontal scroll
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = "All"; // Update selected category
                              });
                            },
                            child: Chip(
                              label: Text('All Expenses'),
                              backgroundColor: _selectedCategory == "All" ? Colors.deepPurple : Colors.grey[300],
                              labelStyle: TextStyle(fontWeight: FontWeight.bold, color: _selectedCategory == "All" ? Colors.white : Colors.black),
                            ),
                          ),
                          ..._categories.where((category) => category != "All").map((category) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => ExpenseDetailsScreen(category),
                                ));
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Chip(
                                  label: Text(category),
                                  backgroundColor: _selectedCategory == category ? Colors.deepPurple : Colors.grey[300],
                                  labelStyle: TextStyle(fontWeight: FontWeight.bold, color: _selectedCategory == category ? Colors.white : Colors.black),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),

                  // Expense Pie Chart
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _categoryDataMap.isNotEmpty
                        ? isLargeScreen
                            ? Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 250,
                                      child: PieChart(
                                        dataMap: _categoryDataMap,
                                        chartType: ChartType.ring,
                                        ringStrokeWidth: 32,
                                        centerText: 'Ksh. ${_totalExpenses.toStringAsFixed(0)}',
                                        legendOptions: LegendOptions(
                                          showLegends: false,
                                        ),
                                        chartValuesOptions: ChartValuesOptions(
                                          showChartValues: true,
                                          showChartValuesInPercentage: true,
                                          showChartValuesOutside: false,
                                          decimalPlaces: 2,
                                        ),
                                        colorList: _categoryColors.values.toList(),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: ListView.builder(
                                        physics: NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        itemCount: _categoryDataMap.length,
                                        itemBuilder: (ctx, index) {
                                          String category = _categoryDataMap.keys.elementAt(index);
                                          double percentage = (_categoryDataMap[category]! / _totalExpenses) * 100;
                                          double amount = _categoryDataMap[category]!;
                                          Color categoryColor = _categoryColors[category]!;
                                          return Card(
                                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                                            elevation: 3,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                                            child: ListTile(
                                              title: Row(
                                                children: [
                                                  Container(
                                                    width: 10,
                                                    height: 10,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: categoryColor,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(category),
                                                ],
                                              ),
                                              subtitle: LinearProgressIndicator(
                                                value: percentage / 100,
                                                backgroundColor: Colors.grey[300],
                                                color: categoryColor,
                                              ),
                                              trailing: Text('Ksh. $amount'),
                                              onTap: () {
                                                Navigator.of(context).push(MaterialPageRoute(
                                                  builder: (_) => ExpenseDetailsScreen(category),
                                                ));
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  Container(
                                    height: 200,
                                    child: PieChart(
                                      dataMap: _categoryDataMap,
                                      chartType: ChartType.ring,
                                      ringStrokeWidth: 32,
                                      centerText: 'Ksh. ${_totalExpenses.toStringAsFixed(0)}',
                                      legendOptions: LegendOptions(
                                        showLegends: false,
                                      ),
                                      chartValuesOptions: ChartValuesOptions(
                                        showChartValues: true,
                                        showChartValuesInPercentage: true,
                                        showChartValuesOutside: false,
                                        decimalPlaces: 2,
                                      ),
                                      colorList: _categoryColors.values.toList(),
                                    ),
                                  ),
                                  SingleChildScrollView(
                                    child: ListView.builder(
                                      physics: NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: _categoryDataMap.length,
                                      itemBuilder: (ctx, index) {
                                        String category = _categoryDataMap.keys.elementAt(index);
                                        double percentage = (_categoryDataMap[category]! / _totalExpenses) * 100;
                                        double amount = _categoryDataMap[category]!;
                                        Color categoryColor = _categoryColors[category]!;
                                        return Card(
                                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                                          elevation: 3,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                                          child: ListTile(
                                            title: Row(
                                              children: [
                                                Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: categoryColor,
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                Text(category),
                                              ],
                                            ),
                                            subtitle: LinearProgressIndicator(
                                              value: percentage / 100,
                                              backgroundColor: Colors.grey[300],
                                              color: categoryColor,
                                            ),
                                            trailing: Text('Ksh. $amount'),
                                            onTap: () {
                                              Navigator.of(context).push(MaterialPageRoute(
                                                builder: (_) => ExpenseDetailsScreen(category),
                                              ));
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              )
                        : Center(child: Text('No data available')),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  },
),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.deepPurple,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart_outlined),
            label: 'Survival rate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.vaccines),
            label: 'Vaccine Tracker',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        onTap: _onItemTapped,
      ),
  floatingActionButton: FloatingActionButton(
    onPressed: () {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AddExpenseScreen(_addExpense),
      ));
    },
    child: Icon(Icons.add),
    backgroundColor: Colors.deepPurpleAccent,
  ),
);

}

}
