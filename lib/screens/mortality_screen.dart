import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/mortality.dart';

class MortalityScreen extends StatefulWidget {
  @override
  _MortalityScreenState createState() => _MortalityScreenState();
}

class _MortalityScreenState extends State<MortalityScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Mortality> _mortalities = [];
  int _selectedIndex = 1;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _fetchMortalityData();
  }

  void _fetchMortalityData() async {
    QuerySnapshot querySnapshot = await _firestore.collection('mortalities').orderBy('date').get();
    setState(() {
      _mortalities = querySnapshot.docs
          .map((doc) => Mortality.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  void _addMortality() async {
    DateTime now = DateTime.now();
    DocumentReference docRef = await _firestore.collection('mortalities').add({'date': now});
    setState(() {
      _mortalities.add(Mortality(id: docRef.id, date: now));
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/');
        break;
      case 1:
        // Current page
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/vaccineTracker');
        break;
    }
  }

  List<BarChartGroupData> _buildBarChartData(String period) {
    // Create a map to store the count of mortalities per day, week, month, or year
    Map<String, int> dataMap = {};

    for (var mortality in _mortalities) {
      String key;

      switch (period) {
        case 'Day':
          key = DateFormat('yyyy-MM-dd').format(mortality.date);
          break;
        case 'Week':
          DateTime startOfWeek = mortality.date.subtract(Duration(days: mortality.date.weekday - 1));
          key = DateFormat('yyyy-MM-dd').format(startOfWeek);
          break;
        case 'Month':
          key = DateFormat('yyyy-MM').format(mortality.date);
          break;
        case 'Year':
          key = DateFormat('yyyy').format(mortality.date);
          break;
        default:
          key = DateFormat('yyyy-MM-dd').format(mortality.date);
      }

      if (dataMap.containsKey(key)) {
        dataMap[key] = dataMap[key]! + 1;
      } else {
        dataMap[key] = 1;
      }
    }

    // Convert the data map to a list of BarChartGroupData
    List<BarChartGroupData> barChartData = [];
    int index = 0;

    dataMap.forEach((key, value) {
      if (value.isFinite) { // Ensure the value is finite
        barChartData.add(
          BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                y: value.toDouble(),
                colors: [Colors.lightBlueAccent, Colors.greenAccent],
              ),
            ],
          ),
        );
        index++;
      }
    });

    return barChartData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mortality Rate Tracker'),
  
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent('Day'),
         
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.transparent,
        onPressed: _addMortality,
        child: Icon(Icons.add,color: Colors.cyan,),
        tooltip: 'Add Mortality',
      ),
      bottomNavigationBar: BottomNavigationBar(
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
            icon: Icon(Icons.medical_services),
            label: 'Vaccine Tracker',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurpleAccent,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildTabContent(String period) {
    return Column(
      children: [
       
        Expanded(
          child: BarChart(
            BarChartData(
              barGroups: _buildBarChartData(period),
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: SideTitles(
                  showTitles: true,
                  getTitles: (double value) {
                    switch (period) {
                      case 'Day':
                        return DateFormat('MM-dd').format(_mortalities[value.toInt()].date);
                      case 'Week':
                        DateTime startOfWeek = _mortalities[value.toInt()].date.subtract(Duration(days: _mortalities[value.toInt()].date.weekday - 1));
                        return DateFormat('MM-dd').format(startOfWeek);
                      case 'Month':
                        return DateFormat('MM').format(_mortalities[value.toInt()].date);
                      case 'Year':
                        return DateFormat('yyyy').format(_mortalities[value.toInt()].date);
                      default:
                        return '';
                    }
                  },
                  margin: 8,
                ),
                leftTitles: SideTitles(showTitles: false),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text('Total Counts'),
                  Text(
                    _mortalities.length.toString(),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                children: [
                  Text('Daily Counts'),
                  Text(
                    _mortalities.isNotEmpty ? _mortalities.length.toString() : '0',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
