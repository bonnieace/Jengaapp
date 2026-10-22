import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/flock.dart';

void main() {
  Flock flock(String id, {bool active = true, DateTime? hatch}) => Flock(
    id: id, name: id, active: active, initialBirdCount: 100, eggStock: 0, hatchedAt: hatch);

  test('selection survives restart and permits viewing a closed flock', () {
    final flocks = [flock('chicks'), flock('layers'), flock('old batch', active: false)];
    expect(selectFlock(flocks, 'layers')!.id, 'layers');
    expect(selectFlock(flocks, 'old batch')!.active, false);
  });
  test('missing selection falls back to active flock; all closed remains viewable', () {
    final closed = flock('closed', active: false);
    expect(selectFlock([closed, flock('growers')], 'removed')!.id, 'growers');
    expect(selectFlock([closed], null)!.id, 'closed');
    expect(selectFlock([], null), null);
  });
  test('age uses calendar dates and never guesses age for legacy batches', () {
    expect(flock('new', hatch: DateTime(2026, 10, 1, 23)).ageInDays(DateTime(2026, 10, 15, 1)), 14);
    expect(flock('legacy').ageInDays(DateTime(2026, 10, 15)), null);
  });
  test('remaining birds includes quantity mortalities and stays nonnegative', () {
    expect(FlockSummary(flock('layers'), 7).birdsRemaining, 93);
    expect(FlockSummary(flock('layers'), 110).birdsRemaining, 0);
  });
}
