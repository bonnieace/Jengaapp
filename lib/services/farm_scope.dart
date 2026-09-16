import 'package:cloud_firestore/cloud_firestore.dart';

/// Resolved only after authentication. All operational reads and writes must
/// go through this scope so a client can never accidentally use a root-level
/// farm collection.
class FarmScope {
  FarmScope._();

  static String? tenantId;
  static String? flockId;

  static DocumentReference<Map<String, dynamic>> get tenant {
    final id = tenantId;
    if (id == null) throw StateError('Farm context has not been initialized.');
    return FirebaseFirestore.instance.collection('tenants').doc(id);
  }

  static CollectionReference<Map<String, dynamic>> collection(String name) =>
      tenant.collection(name);

  static CollectionReference<Map<String, dynamic>> flockCollection(String name) {
    final id = flockId;
    if (id == null) throw StateError('An active flock is required.');
    return tenant.collection('flocks').doc(id).collection(name);
  }

  static void clear() {
    tenantId = null;
    flockId = null;
  }
}
