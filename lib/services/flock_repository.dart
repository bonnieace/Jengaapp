import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/flock.dart';
import 'farm_scope.dart';

class FlockRepository {
  FlockRepository() : _flocks = FarmScope.collection('flocks');
  final CollectionReference<Map<String, dynamic>> _flocks;
  DocumentReference<Map<String, dynamic>> get _profile => FirebaseFirestore.instance
      .collection('users').doc(FirebaseAuth.instance.currentUser!.uid);

  Stream<List<FlockSummary>> watchSummary() => _flocks.snapshots().switchMap((snapshot) {
    final flocks = snapshot.docs.map((d) => Flock.fromMap(d.id, d.data())).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (flocks.isEmpty) return Stream.value(<FlockSummary>[]);
    return Rx.combineLatestList<FlockSummary>(flocks.map((flock) =>
      _flocks.doc(flock.id).collection('mortalities').snapshots().map((deaths) =>
        FlockSummary(flock, deaths.docs.fold<int>(0, (n, d) =>
          n + ((d.data()['quantity'] as num?)?.toInt() ?? 1))))));
  });

  Future<void> select(String id) async {
    await _profile.update({'activeFlockId': id});
  }

  Future<void> create({required String name, required int birds, required DateTime hatchedAt}) async {
    if (name.trim().isEmpty || name.trim().length > 100 || birds < 1 || birds > 1000000 || hatchedAt.isAfter(DateTime.now())) {
      throw ArgumentError('Enter a name, a valid bird count and a hatch date that is not in the future.');
    }
    final flock = _flocks.doc();
    final batch = FirebaseFirestore.instance.batch();
    batch.set(flock, {'name': name.trim(), 'initialBirdCount': birds, 'eggStock': 0,
      'hatchedAt': Timestamp.fromDate(hatchedAt), 'startedAt': Timestamp.now(),
      'active': true, 'createdAt': FieldValue.serverTimestamp()});
    batch.update(_profile, {'activeFlockId': flock.id});
    await batch.commit();
  }

  Future<void> updateDetails(Flock flock, {required String name, required DateTime hatchedAt}) async {
    if (name.trim().isEmpty || name.trim().length > 100 || hatchedAt.isAfter(DateTime.now())) {
      throw ArgumentError('Enter a name and a valid hatch date.');
    }
    await _flocks.doc(flock.id).update({'name': name.trim(), 'hatchedAt': Timestamp.fromDate(hatchedAt)});
  }

  Future<void> setActive(Flock flock, bool active) async {
    final doc = _flocks.doc(flock.id);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snapshot = await tx.get(doc);
      if (!snapshot.exists) throw StateError('This flock no longer exists.');
      final stock = (snapshot.data()?['eggStock'] as num?)?.toInt() ?? 0;
      if (!active && stock != 0) {
        throw StateError('Sell or correct the remaining $stock eggs before closing this batch.');
      }
      tx.update(doc, {'active': active,
        'closedAt': active ? FieldValue.delete() : FieldValue.serverTimestamp()});
    });
    if (!active) {
      try {
        final vaccines = await doc.collection('vaccinations').get();
        for (final vaccine in vaccines.docs) {
          await FlutterLocalNotificationsPlugin().cancel(vaccine.id.hashCode);
        }
      } catch (_) {
        throw StateError('Batch closed. Some reminders on this device could not be cancelled.');
      }
    }
  }
}
