
import 'package:cloud_firestore/cloud_firestore.dart';

class Mortality {
  String id;
  DateTime date;

  Mortality({required this.id, required this.date});

  factory Mortality.fromMap(Map<String, dynamic> data, String id) {
    return Mortality(
      id: id,
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
    };
  }
}
