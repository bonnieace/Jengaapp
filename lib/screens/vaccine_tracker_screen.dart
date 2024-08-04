import 'package:expense_tracker/local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';
import '../models/vaccine.dart';
import 'add_vaccine.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

class VaccineTrackerScreen extends StatefulWidget {
  final FlutterLocalNotificationsPlugin notificationsPlugin;
  VaccineTrackerScreen({required this.notificationsPlugin});

  @override
  _VaccineTrackerScreenState createState() => _VaccineTrackerScreenState();
}

class _VaccineTrackerScreenState extends State<VaccineTrackerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference _vaccinesCollection;
  int _selectedIndex = 2; // Set initial index for this screen in the bottom navigation
  Set<String> _administeredVaccines = Set();
  DateTime _selectedDate = DateTime.now();
  Set<DateTime> _vaccineDates = Set<DateTime>(); // Store vaccine dates for highlighting

  @override
  void initState() {
    super.initState();
    _vaccinesCollection = _firestore.collection('vaccines');
    LocalNotifications.showSimpleNotification(title: "vaccines", body: "body", payload: "payload");
    _fetchVaccineDates(); // Fetch vaccine dates on init
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

  Future<void> _triggerTestNotification() async {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local).add(Duration(seconds: 5)); // 5 seconds from now
    await widget.notificationsPlugin.zonedSchedule(
      0, // Unique identifier for the notification
      'Test Notification',
      'This is a test notification to verify the system.',
      now,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel_id',
          'Test Channel',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleNotification(String id, String vaccineName, DateTime date) async {
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(date, tz.local);
    await widget.notificationsPlugin.zonedSchedule(
      id.hashCode,
      'Vaccine Reminder',
      'The $vaccineName vaccine is due on ${date.toLocal().toString().split(' ')[0]}',
      scheduledDate.subtract(Duration(hours: 16)), // Schedule for 1 day before the due date
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'your_channel_id',
          'your_channel_name',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
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

  void _markAsAdministered(String id, String vaccineName) {
    setState(() {
      _administeredVaccines.add(id);
      _vaccinesCollection.doc(id).update({'administered': true});
    });
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
        onTap: () => (),
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
                  if (snapshot.data!.docs.isEmpty) {
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
                      final isAdministered = _administeredVaccines.contains(vaccine.id) || (snapshot.data!.docs[index].data() as Map<String, dynamic>)['administered'] == true;
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
                                isPastDue
                                    ? 'Administered on: ${dateToBeAdministered.toString().split(' ')[0]}'
                                    : 'Date to be administered: ${dateToBeAdministered.toString().split(' ')[0]}',
                                style: TextStyle(color: Colors.deepPurple),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Route of administration: ${vaccine.routeOfAdministration}',
                                style: TextStyle(color: Colors.deepPurple),
                              ),
                            ],
                          ),
                          trailing: isPastDue 
                              ? Icon(Icons.check_circle_sharp, color: Colors.deepPurple)
                              : Icon(Icons.pending_actions, color: Colors.deepPurple),
                          onTap: () {
                            try {
                              LocalNotifications.showSimpleNotification(title: "vaccines", body: "body", payload: "payload");
                            } catch (e) {
                              print(e);
                            }
                          },
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddVaccineScreen()),
          );
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
