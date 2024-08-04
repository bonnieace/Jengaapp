import 'package:expense_tracker/local_notifications.dart';
import 'package:expense_tracker/screens/mortality_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import './screens/home_screens.dart';
import './screens/vaccine_tracker_screen.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'screens/workers.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await LocalNotifications.init();
  runApp(const MyApp());
}

Future<void> initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  tz.initializeTimeZones();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WorkersProvider(),
      child: MaterialApp(
        title: 'Vaccine Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomeScreen(),
        routes: {
          '/vaccineTracker': (context) => VaccineTrackerScreen(notificationsPlugin: flutterLocalNotificationsPlugin),
          '/mortalityScreen': (context) => MortalityScreen(),
          '/workersPage': (context) => WorkersPage(),
          // Add other routes as needed
        },
      ),
    );
  }
}
class WorkersProvider with ChangeNotifier {
  final CollectionReference workersCollection = FirebaseFirestore.instance.collection('workers');

  Stream<QuerySnapshot> get workers {
    return workersCollection.snapshots();
  }

  Future<void> addWorker(String name, String role) async {
    await workersCollection.add({
      'name': name,
      'role': role,
      'checkedIn': false,
      'checkInHistory': [],
      'workingDays': 0,
    });
    notifyListeners();
  }

  Future<void> toggleCheckInWorker(String id, bool checkedIn) async {
    final DocumentReference workerDoc = workersCollection.doc(id);
    final DocumentSnapshot workerSnapshot = await workerDoc.get();
    final data = workerSnapshot.data() as Map<String, dynamic>;

    // Update the checkedIn status
    final newCheckedIn = !checkedIn;

    // Get current timestamp
    final Timestamp now = Timestamp.now();

    // Update the checkInHistory
    final List<dynamic> checkInHistory = data['checkInHistory'];
    checkInHistory.add({'checkedIn': newCheckedIn, 'timestamp': now});

    // Calculate the Days Worked if checking out
    int workingDays = data['workingDays'];
    if (!newCheckedIn) {
      final lastCheckInTimestamp = checkInHistory.lastWhere((event) => event['checkedIn'])['timestamp'];
      final lastCheckInDate = lastCheckInTimestamp.toDate();
      final nowDate = now.toDate();
      workingDays += nowDate.difference(lastCheckInDate).inDays + 1;
    }

    // Update Firestore document
    await workerDoc.update({
      'checkedIn': newCheckedIn,
      'checkInHistory': checkInHistory,
      'workingDays': workingDays,
    });

    notifyListeners();
  }
}

