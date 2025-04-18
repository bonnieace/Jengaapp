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
  int _selectedIndex = 1;
  List<String> selectedWorkers = []; // Track selected workers' IDs
  Map<String, bool> expandedTiles = {}; // Track the expanded/collapsed state of each tile
  bool isCheckingIn = true; // Track whether you're checking in or checking out workers

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

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

  void toggleTileExpansion(String role) {
    setState(() {
      expandedTiles[role] = !(expandedTiles[role] ?? false); // Toggle the expansion state
    });
  }

  void toggleWorkerSelection(String workerId) {
    setState(() {
      if (selectedWorkers.contains(workerId)) {
        selectedWorkers.remove(workerId); // Remove worker from selected list
      } else {
        selectedWorkers.add(workerId); // Add worker to selected list
      }
    });
  }

  void checkInSelectedWorkers(WorkersProvider workersProvider) {
    for (var workerId in selectedWorkers) {
      workersProvider.toggleCheckInWorker(workerId, false); // Mark them as checked in
    }
    setState(() {
      selectedWorkers.clear(); // Clear selected workers after check-in
    });
  }

  void checkOutSelectedWorkers(WorkersProvider workersProvider) {
    for (var workerId in selectedWorkers) {
      workersProvider.toggleCheckInWorker(workerId, true); // Mark them as checked out
    }
    setState(() {
      selectedWorkers.clear(); // Clear selected workers after check-out
    });
  }

  @override
  Widget build(BuildContext context) {
    final workersProvider = Provider.of<WorkersProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Workers Management', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
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
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                expandedAlignment: Alignment.topLeft,
                trailing: Icon(
                  expandedTiles[role] == true ? Icons.arrow_upward : Icons.arrow_downward,
                  color: Colors.deepPurple,
                ),
                title: Text(
                  role,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
                onExpansionChanged: (expanded) {
                  setState(() {
                    expandedTiles[role] = expanded; // Update the expansion state
                  });
                },
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
                    onWorkerSelected: () => toggleWorkerSelection(worker.id), // Handle worker selection
                    isSelected: selectedWorkers.contains(worker.id),
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
      floatingActionButton: selectedWorkers.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                // Toggle check-in or check-out action based on the current mode
                if (isCheckingIn) {
                  checkInSelectedWorkers(workersProvider); // Check-in workers
                } else {
                  checkOutSelectedWorkers(workersProvider); // Check-out workers
                }
              },
              label: Text(isCheckingIn ? 'Check In Selected' : 'Check Out Selected'),
              icon: Icon(isCheckingIn ? Icons.check : Icons.exit_to_app),
              backgroundColor: Colors.deepPurple,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class WorkerTile extends StatelessWidget {
  final Map<String, dynamic> worker;
  final void Function() onToggleCheckIn;
  final void Function() onWorkerSelected;
  final bool isSelected;

  WorkerTile({
    required this.worker,
    required this.onToggleCheckIn,
    required this.onWorkerSelected,
    required this.isSelected,
  });

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
            // Worker Selection
            IconButton(
              icon: Icon(
                isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                color: Colors.deepPurple,
              ),
              onPressed: onWorkerSelected,
            ),
          ],
        ),
      ),
    );
  }
}
