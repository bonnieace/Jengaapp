// models/expense.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String category;
  final String description;
  final double amount;
  final DateTime date;

  Expense({
    required this.id,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
  });

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Expense(
      id: doc.id,
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] ?? DateTime.now()).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'description': description,
      'amount': amount,
      'date': date,
    };
  }
}
