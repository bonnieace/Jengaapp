
import 'package:cloud_firestore/cloud_firestore.dart';

class Mortality {
  final String id;
  final DateTime date;
  final int quantity;
  final String cause;
  final String note;

  Mortality({required this.id, required this.date, required this.quantity, this.cause = '', this.note = ''});

  factory Mortality.fromMap(Map<String, dynamic> data, String id) {
    return Mortality(
      id: id,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      cause: data['cause'] as String? ?? '',
      note: data['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'quantity': quantity,
      'cause': cause,
      'note': note,
    };
  }
}
