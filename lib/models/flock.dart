import 'package:cloud_firestore/cloud_firestore.dart';

class Flock {
  const Flock({required this.id, required this.name, required this.active,
    required this.initialBirdCount, required this.eggStock, this.hatchedAt});
  final String id;
  final String name;
  final bool active;
  final int initialBirdCount;
  final int eggStock;
  final DateTime? hatchedAt;

  factory Flock.fromMap(String id, Map<String, dynamic> data) => Flock(
    id: id, name: data['name'] as String? ?? 'Unnamed flock',
    active: data['active'] == true,
    initialBirdCount: (data['initialBirdCount'] as num?)?.toInt() ?? 0,
    eggStock: (data['eggStock'] as num?)?.toInt() ?? 0,
    hatchedAt: (data['hatchedAt'] as Timestamp?)?.toDate(),
  );

  int? ageInDays(DateTime now) {
    final hatch = hatchedAt;
    if (hatch == null) return null;
    return DateTime.utc(now.year, now.month, now.day)
        .difference(DateTime.utc(hatch.year, hatch.month, hatch.day)).inDays.clamp(0, 100000).toInt();
  }
}

Flock? selectFlock(List<Flock> flocks, String? preferredId) {
  for (final flock in flocks) {
    if (flock.id == preferredId) return flock;
  }
  for (final flock in flocks) {
    if (flock.active) return flock;
  }
  return flocks.isEmpty ? null : flocks.first;
}

class FlockSummary {
  const FlockSummary(this.flock, this.deaths);
  final Flock flock;
  final int deaths;
  int get birdsRemaining => (flock.initialBirdCount - deaths).clamp(0, flock.initialBirdCount).toInt();
}
