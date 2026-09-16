import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/vaccine.dart';
import 'add_vaccine.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import '../services/farm_scope.dart';

class VaccineTrackerScreen extends StatefulWidget {
  final FlutterLocalNotificationsPlugin notificationsPlugin;
  VaccineTrackerScreen({required this.notificationsPlugin});

  @override
  _VaccineTrackerScreenState createState() => _VaccineTrackerScreenState();
}

class _VaccineTrackerScreenState extends State<VaccineTrackerScreen> {
  late CollectionReference _vaccinesCollection;
  int _selectedIndex = 2; // Set initial index for this screen in the bottom navigation
  Set<String> _administeredVaccines = Set();
  DateTime _selectedDate = DateTime.now();
  Set<DateTime> _vaccineDates = Set<DateTime>(); // Store vaccine dates for highlighting

  @override
  void initState() {
    super.initState();
    _vaccinesCollection = FarmScope.flockCollection('vaccinations');
    _fetchVaccineDates();
    _scheduleExistingNotifications();
  }

  Future<void> _fetchVaccineDates() async {
    final QuerySnapshot snapshot = await _vaccinesCollection.get();
    final dates = <DateTime>{};

    for (var doc in snapshot.docs) {
      final vaccine = Vaccine.fromFirestore(doc);
      if (vaccine.dateToBeAdministered != null) {
        dates.add(vaccine.dateToBeAdministered);
      }
    }

    if (!mounted) return;
    setState(() {
      _vaccineDates = dates;
    });
  }

  Future<void> _scheduleExistingNotifications() async {
    final QuerySnapshot snapshot = await _vaccinesCollection.get();
    for (var doc in snapshot.docs) {
      final vaccine = Vaccine.fromFirestore(doc);
      final isAdministered = (doc.data() as Map<String, dynamic>)['administered'] == true;
      if (!isAdministered) {
        await scheduleNotification(vaccine.id, vaccine.name, vaccine.dateToBeAdministered);
      }
    }
  }

  Future<void> scheduleNotification(String id, String vaccineName, DateTime date) async {
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(date, tz.local);
    final reminderDate = scheduledDate.subtract(const Duration(days: 1)).add(const Duration(hours: 9));
    if (reminderDate.isBefore(tz.TZDateTime.now(tz.local))) return;
    await widget.notificationsPlugin.zonedSchedule(
      id.hashCode,
      'Vaccine Reminder',
      'The $vaccineName vaccine is due on ${date.toLocal().toString().split(' ')[0]}',
      reminderDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'your_channel_id',
          'your_channel_name',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
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
      // No action needed for index 2 (current screen)
    }
  }

  Future<void> _markAsAdministered(String id, String vaccineName) async {
    try {
      await _vaccinesCollection.doc(id).update({'administered': true, 'administeredAt': FieldValue.serverTimestamp()});
      await widget.notificationsPlugin.cancel(id.hashCode);
      if (mounted) setState(() => _administeredVaccines.add(id));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update this vaccination.')));
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

 Widget _buildDateSelector() {
  final now = DateTime.now();
  final firstDayOfWeek = now.subtract(Duration(days: now.weekday - 1));

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: List.generate(7, (index) {
      final date = firstDayOfWeek.add(Duration(days: index));
      final isSelected = _selectedDate != null &&
          _selectedDate!.day == date.day &&
          _selectedDate!.month == date.month &&
          _selectedDate!.year == date.year;
      final isVaccineDate = _vaccineDates.any((vaccineDate) =>
          vaccineDate.year == date.year &&
          vaccineDate.month == date.month &&
          vaccineDate.day == date.day);
      final isCurrentDate = now.year == date.year && now.month == date.month && now.day == date.day;
      
      Color backgroundColor;
      Color textColor;

      if (isCurrentDate && isVaccineDate) {
        backgroundColor = Colors.blue; // Color for current date that is also a vaccine date
        textColor = Colors.white; // Text color for the current date and vaccine date
      } else if (isSelected) {
        backgroundColor = Colors.white;
        textColor = Colors.deepPurple;
      } else if (isCurrentDate) {
        backgroundColor = Colors.white; // Color for the current day
        textColor = Colors.deepPurple; // Text color for the current day
      } else if (isVaccineDate) {
        backgroundColor = Colors.orange; // Color for vaccine dates
        textColor = Colors.white; // Text color for vaccine dates
      } else {
        backgroundColor = Colors.transparent;
        textColor = Colors.white;
      }

      return GestureDetector(
        onTap: () => _onDateSelected(date),
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                DateFormat('EEE').format(date), // Short day of the week
                style: TextStyle(
                  color: textColor,
                ),
              ),
              SizedBox(height: 4),
              Text(
                DateFormat('d').format(date), // Day of the month
                style: TextStyle(
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      );
    }),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Vaccine Tracker',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDateSelector(),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder(
                stream: _vaccinesCollection.snapshots(),
                builder: (ctx, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) return const Center(child: Text('Could not load vaccinations.', style: TextStyle(color: Colors.white)));
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No vaccines found.'));
                  }
                  final List<Vaccine> vaccines = snapshot.data!.docs
                      .map((doc) => Vaccine.fromFirestore(doc))
                      .toList();
                  vaccines.sort((a, b) => a.dateToBeAdministered.compareTo(b.dateToBeAdministered)); // Sort vaccines by date
                  return ListView.builder(
                    itemCount: vaccines.length,
                    itemBuilder: (ctx, index) {
                      final vaccine = vaccines[index];
                      final isAdministered = _administeredVaccines.contains(vaccine.id) || vaccine.administered;
                      final currentDate = DateTime.now();
                      final dateToBeAdministered = vaccine.dateToBeAdministered.toLocal();
                      final isPastDue = currentDate.isAfter(dateToBeAdministered);

                      return Card(
                        elevation: 5,
                        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          title: Text(
                            vaccine.name,
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAdministered
                                    ? 'Administered on: ${DateFormat.yMMMd().format(vaccine.administeredAt ?? dateToBeAdministered)}'
                                    : isPastDue
                                        ? 'Overdue since: ${DateFormat.yMMMd().format(dateToBeAdministered)}'
                                        : 'Due: ${DateFormat.yMMMd().format(dateToBeAdministered)}',
                                style: TextStyle(color: Colors.deepPurple),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Route of administration: ${vaccine.routeOfAdministration}',
                                style: TextStyle(color: Colors.deepPurple),
                              ),
                            ],
                          ),
                          trailing: Icon(isAdministered ? Icons.check_circle : (isPastDue ? Icons.warning_amber : Icons.pending_actions), color: isPastDue && !isAdministered ? Colors.orange : Colors.deepPurple),
                          onTap: isAdministered ? null : () => _markAsAdministered(vaccine.id, vaccine.name),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddVaccineScreen()),
          );
          if (!mounted) return;
          await _fetchVaccineDates();
          await _scheduleExistingNotifications();
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.transparent,
        foregroundColor: Color.fromARGB(255, 13, 140, 175),
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
    );
  }
}
