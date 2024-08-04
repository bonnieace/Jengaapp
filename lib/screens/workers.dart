import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import 'AddWorkerPage.dart';

class WorkersPage extends StatefulWidget {
  @override
  _WorkersPageState createState() => _WorkersPageState();
}

class _WorkersPageState extends State<WorkersPage> {
  int _selectedIndex = 1; // Set default to WorkersPage index

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to the selected page
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/workersPage');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/mortalityScreen');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final workersProvider = Provider.of<WorkersProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Workers Management', style: TextStyle(color: Colors.deepPurple,fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline_outlined, color: Colors.deepPurple),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddWorkerPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: workersProvider.workers,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final workers = snapshot.data!.docs;

          // Group workers by role
          Map<String, List<QueryDocumentSnapshot>> workersByRole = {};
          for (var worker in workers) {
            String role = worker['role'];
            if (workersByRole.containsKey(role)) {
              workersByRole[role]!.add(worker);
            } else {
              workersByRole[role] = [worker];
            }
          }

          return ListView(
            children: workersByRole.keys.map((role) {
              return ExpansionTile(
                leading: CircleAvatar(
                  child: Center(child: Icon(Iconsax.brifecase_cross5)),
                  backgroundColor: Colors.transparent,
                  radius: 15,
                ),
                initiallyExpanded: true,
                trailing:Icon(Iconsax.arrow_down_1,color: Colors.deepPurple,) ,
                title: Text(role, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.deepPurple)),
                children: workersByRole[role]!.map((worker) {
                  return WorkerTile(
                    worker: {
                      'id': worker.id,
                      'name': worker['name'],
                      'role': worker['role'],
                      'workingDays': worker['workingDays'],
                      'checkedIn': worker['checkedIn'],
                    },
                    onToggleCheckIn: () => workersProvider.toggleCheckInWorker(worker.id, worker['checkedIn']),
                  );
                }).toList(),
              );
            }).toList(),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.monetization_on_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Iconsax.user),
            label: 'Workers',
          ),
          
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }
}

class WorkerTile extends StatelessWidget {
  final Map<String, dynamic> worker;
  final void Function() onToggleCheckIn;

  WorkerTile({required this.worker, required this.onToggleCheckIn});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Worker Icon
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.deepPurple,
              backgroundImage: AssetImage('assets/architect.png'), // Provide the path to your local image
            ),
            SizedBox(width: 10),
            // Worker Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker['name'],
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    worker['role'],
                    style: TextStyle(fontSize: 14),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.star_outlined,
                        color: Colors.amber,
                        size: 16,
                      ),
                      Text(
                        'Days Worked: ${worker['workingDays']}',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Check In/Check Out Button
            TextButton(
              onPressed: onToggleCheckIn,
              child: Text(worker['checkedIn'] ? 'Check Out' : 'Check In'),
            ),
          ],
        ),
      ),
    );
  }
}
