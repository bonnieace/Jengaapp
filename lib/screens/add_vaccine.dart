import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

class AddVaccineScreen extends StatefulWidget {
  @override
  _AddVaccineScreenState createState() => _AddVaccineScreenState();
}

class _AddVaccineScreenState extends State<AddVaccineScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late DateTime _selectedDate;
  late String _routeOfAdministration;
  bool _dateSelected = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _routeOfAdministration = '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addVaccine(String name, DateTime dateToBeAdministered, String routeOfAdministration) async {
    try {
      await _firestore.collection('vaccines').add({
        'name': name,
        'dateToBeAdministered': dateToBeAdministered,
        'routeOfAdministration': routeOfAdministration,
      });
      Navigator.pop(context); // Go back to the vaccine list screen
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vaccine added successfully')));
    } catch (e) {
      print('Error adding vaccine: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding vaccine')));
    }
  }

  void _handleDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
      _dateSelected = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
              backgroundColor: Colors.deepPurple,

      appBar: AppBar(
        title: Text('Add Vaccine',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.deepPurple,

      ),
      body: SingleChildScrollView(
        
        child: Padding(
          
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Lottie.asset('assets/your_animation2.json', height: 150),
                SizedBox(height: 60),
                TextFormField(
  controller: _nameController,
  decoration: InputDecoration(
    labelText: 'Vaccine Name',
    labelStyle: TextStyle(color: Colors.white), // Hint text color
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white), // Border color when focused
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white), // Default border color
    ),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white), // Borderfsdz color
    ),
    fillColor: Colors.white,
    filled: false,
  ),
  style: TextStyle(color: Colors.white), // Text color
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a vaccine name';
    }
    return null;
  },
),

                SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(onPressed: () { showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        ).then((pickedDate) {
                          if (pickedDate != null) {
                            _handleDateChanged(pickedDate);
                          }
                        }); }, icon: Icon(Icons.calendar_month,color: Colors.white,),),
                    SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        ).then((pickedDate) {
                          if (pickedDate != null) {
                            _handleDateChanged(pickedDate);
                          }
                        });
                      },
                      child: Text(
                        _dateSelected
                            ? 'Date to be Administered: ${_selectedDate.toLocal().toString().split(' ')[0]}'
                            : 'Select Date to be Administered',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _dateSelected ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextFormField(
  decoration: InputDecoration(
    labelText: 'Route of Administration',
    labelStyle: TextStyle(color: Colors.white), // Hint text color
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white), // Border color when focused
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white), // Default border color
    ),
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white), // Border color
    ),
    fillColor: Colors.white,
    filled: false,
  ),
  style: TextStyle(color: Colors.white), // Text color
  onChanged: (value) {
    setState(() {
      _routeOfAdministration = value; // Update the route of administration value
    });
  },
),

                SizedBox(height: 30),
                SizedBox(
                  height: 60,
                  
                  width: double.infinity,
                  child: ElevatedButton(
  style: ElevatedButton.styleFrom(
    primary: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6), // Adjust the radius as needed
      side: BorderSide(color: Colors.deepPurpleAccent), // Optional: border color
    ),
  ),
  onPressed: () {
    if (_formKey.currentState!.validate() && _dateSelected) {
      _addVaccine(
        _nameController.text,
        _selectedDate,
        _routeOfAdministration,
      );
      _nameController.clear();
      setState(() {
        _selectedDate = DateTime.now();
        _routeOfAdministration = '';
        _dateSelected = false;
      });
    }
  },
  child: Text(
    'Add Vaccine',
    style: TextStyle(color: Colors.deepPurple),
  ),
),

                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
