import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen(void Function(String category, String description, double amount) addExpense, {super.key});

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
  }

  Future<List<String>> _getCategories(String query) async {
  final QuerySnapshot snapshot = await _firestore.collection('expenses').get();
  final allCategories = snapshot.docs
      .map((doc) => doc['category'].toString())
      .toSet()
      .toList();  // Using a set to ensure uniqueness

  return allCategories
      .where((category) => category.toLowerCase().contains(query.toLowerCase()))
      .toList();
}


  void _submitData() async {
    final enteredCategory = _categoryController.text;
    final enteredDescription = _descriptionController.text;
    final enteredAmount = double.tryParse(_amountController.text);

    if (enteredCategory.isEmpty || enteredDescription.isEmpty || enteredAmount == null || enteredAmount <= 0) {
      return;
    }

    try {
      await _firestore.collection('expenses').add({
        'category': enteredCategory,
        'description': enteredDescription,
        'amount': enteredAmount,
        'date': DateTime.now(),
      });
      Navigator.of(context).pop();
    } catch (e) {
      print('Error adding expense: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Expense',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.deepPurple),),
        
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
          
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Lottie.asset('assets/your_animation1.json', height: 150),
                  SizedBox(height: 40),
          
              TypeAheadFormField<String>(
  textFieldConfiguration: TextFieldConfiguration(
    decoration: InputDecoration(
      labelText: 'Category',
      border: OutlineInputBorder(),
    ),
    controller: _categoryController,
  ),
  suggestionsCallback: (pattern) async {
    return await _getCategories(pattern);
  },
  itemBuilder: (context, suggestion) {
    return ListTile(
      title: Text(suggestion),
    );
  },
  onSuggestionSelected: (suggestion) {
    setState(() {
      _categoryController.text = suggestion;
    });
  },
  noItemsFoundBuilder: (context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        'No categories found',
        style: TextStyle(color: Colors.grey),
      ),
    );
  },
),

              SizedBox(height: 12),
          
              TextField(
                decoration: const InputDecoration(labelText: 'Description',                    border: OutlineInputBorder(),
          ),
          
                controller: _descriptionController,
              ),
                              SizedBox(height: 12),
          
              TextField(
                decoration: const InputDecoration(labelText: 'Amount',                    border: OutlineInputBorder(),
          ),
                controller: _amountController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                      style: ElevatedButton.styleFrom(primary: Colors.deepPurple),
                  onPressed: _submitData,
                  child: const Text('Add Expense',style: TextStyle(color: Colors.white),),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
