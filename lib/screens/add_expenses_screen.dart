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

  Future<List<String>> _getCategories(String query) async {
    final QuerySnapshot snapshot = await _firestore.collection('expenses').get();
    final allCategories = snapshot.docs
        .map((doc) => doc['category'].toString())
        .toSet()
        .toList();

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Add New Expense',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 800;

          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
              constraints: BoxConstraints(maxWidth: isWideScreen ? 600 : double.infinity),
              decoration: isWideScreen
                  ? BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 4,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    )
                  : null,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Lottie.asset('assets/your_animation1.json', height: 200),
                    const SizedBox(height: 20),
                    Text(
                      'Add Expense',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 30),
                    TypeAheadFormField<String>(
                      textFieldConfiguration: TextFieldConfiguration(
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                    const SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      controller: _descriptionController,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _submitData,
                        child: const Text(
                          'Add Expense',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
