import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class AddWorkerPage extends StatefulWidget {
  @override
  _AddWorkerPageState createState() => _AddWorkerPageState();
}

class _AddWorkerPageState extends State<AddWorkerPage> {
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
  }

  Future<List<String>> _getRoles(String query) async {
    final QuerySnapshot snapshot = await _firestore.collection('workers').get();
    final allRoles = snapshot.docs
        .map((doc) => doc['role'].toString())
        .toSet()
        .toList();  // Using a set to ensure uniqueness
    
    return allRoles
        .where((role) => role.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void _submitData() async {
    final enteredName = _nameController.text;
    final enteredRole = _roleController.text;

    if (enteredName.isEmpty || enteredRole.isEmpty) {
      return;
    }

    try {
      await _firestore.collection('workers').add({
        'name': enteredName,
        'role': enteredRole,
        'checkedIn': false,
        'checkInHistory': [],
        'workingDays': 0,
      });
      Navigator.of(context).pop();
    } catch (e) {
      print('Error adding worker: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add New Worker',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Lottie.asset('assets/worker.json', height: 200),
              SizedBox(height: 60),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                controller: _nameController,
              ),
              SizedBox(height: 12),
              TypeAheadFormField<String>(
                textFieldConfiguration: TextFieldConfiguration(
                  decoration: InputDecoration(
                    labelText: 'Select Role',
                    fillColor: Colors.white,
                    filled: true,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                  controller: _roleController,
                ),
                suggestionsCallback: (pattern) async {
                  return await _getRoles(pattern);
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    title: Text(suggestion),
                  );
                },
                onSuggestionSelected: (suggestion) {
                  setState(() {
                    _roleController.text = suggestion;
                  });
                },
                noItemsFoundBuilder: (context) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'No roles found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                },
              ),
              SizedBox(height: 12),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(primary: Colors.deepPurple),
                  onPressed: _submitData,
                  child: const Text(
                    'Add Worker',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
