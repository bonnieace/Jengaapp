// models/vaccine.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Vaccine {
  final String id;
  final String name;
  final DateTime dateToBeAdministered;
  final String routeOfAdministration;
  final bool administered;
  final DateTime? administeredAt;

  Vaccine({
    required this.id,
    required this.name,
    required this.dateToBeAdministered,
    required this.routeOfAdministration,
    this.administered = false,
    this.administeredAt,
  });

  factory Vaccine.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return Vaccine(
      id: doc.id,
      name: data['name'] ?? '',
      dateToBeAdministered: (data['dateToBeAdministered'] as Timestamp).toDate(),
      routeOfAdministration: data['routeOfAdministration'] ?? '',
      administered: data['administered'] == true,
      administeredAt: (data['administeredAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dateToBeAdministered': dateToBeAdministered,
      'routeOfAdministration': routeOfAdministration,
      'administered': administered,
      if (administeredAt != null) 'administeredAt': administeredAt,
    };
  }
}
