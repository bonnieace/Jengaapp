import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:lottie/lottie.dart';

class AddWorkerPage extends StatefulWidget {
  @override
  _AddWorkerPageState createState() => _AddWorkerPageState();
}

class _AddWorkerPageState extends State<AddWorkerPage> {
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> _getRoles(String query) async {
    final QuerySnapshot snapshot = await _firestore.collection('workers').get();
    final allRoles = snapshot.docs.map((doc) => doc['role'].toString()).toSet().toList();
    return allRoles
        .where((role) => role.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void _submitData() async {
    final enteredName = _nameController.text;
    final enteredRole = _roleController.text;

    if (enteredName.isEmpty || enteredRole.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields!")),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Worker added successfully!")),
      );
      Navigator.of(context).pop();
    } catch (e) {
      print('Error adding worker: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred. Please try again!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Colors.deepPurple,
        title: const Text(
          'Add Worker',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return constraints.maxWidth > 800 
                          ? _buildWideScreenLayout() 
                          : _buildNarrowScreenLayout();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideScreenLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Lottie.asset(
            'assets/worker.json',
            height: 400,
            fit: BoxFit.contain,
            repeat: false,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _buildForm(),
        ),
      ],
    );
  }

  Widget _buildNarrowScreenLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Lottie.asset(
          'assets/worker.json',
          height: 250,
          fit: BoxFit.contain,
          repeat: false,
        ),
        const SizedBox(height: 20),
        _buildForm(),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 40),

        const Text(
          'Fill in the worker`s details',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[100],
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 20),
        TypeAheadFormField<String>(
          textFieldConfiguration: TextFieldConfiguration(
            controller: _roleController,
            decoration: InputDecoration(
              labelText: 'Role',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
              prefixIcon: const Icon(Icons.work),
            ),
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
            _roleController.text = suggestion;
          },
          noItemsFoundBuilder: (context) => const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'No roles found.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.deepPurple,
          ),
          onPressed: _submitData,
          child: const Text(
            'Add Worker',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }
}