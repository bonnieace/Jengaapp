import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/flock.dart';
import '../services/farm_scope.dart';
import '../services/flock_repository.dart';

class FlocksScreen extends StatefulWidget {
  const FlocksScreen({super.key});
  @override
  State<FlocksScreen> createState() => _FlocksScreenState();
}

class _FlocksScreenState extends State<FlocksScreen> {
  late final FlockRepository _repository = FlockRepository();
  late final Stream<List<FlockSummary>> _summary = _repository.watchSummary();
  bool _busy = false;

  void _home() {
    if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      _home();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
        error is StateError ? error.message.toString() : 'Could not save. Check your connection and try again.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create([Flock? existing]) async {
    final form = GlobalKey<FormState>();
    final name = TextEditingController(text: existing?.name);
    final birds = TextEditingController(text: existing?.initialBirdCount.toString());
    DateTime hatch = existing?.hatchedAt ?? DateUtils.dateOnly(DateTime.now());
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) =>
      StatefulBuilder(builder: (ctx, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'Add a flock or batch' : 'Edit flock details'),
        content: SingleChildScrollView(child: Form(key: form, child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Keep birds of the same age together. Each flock has its own health records, egg production and stock.'),
          const SizedBox(height: 16),
          TextFormField(controller: name, maxLength: 100, decoration: const InputDecoration(labelText: 'Flock name', hintText: 'October chicks'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a flock name' : null),
          TextFormField(controller: birds, readOnly: existing != null, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Starting number of birds'),
            validator: (v) { final n = int.tryParse(v ?? ''); return n == null || n < 1 || n > 1000000 ? 'Enter 1 to 1,000,000 birds' : null; }),
          ListTile(contentPadding: EdgeInsets.zero, title: const Text('Hatch date'), subtitle: Text(DateFormat.yMMMd().format(hatch)),
            trailing: const Icon(Icons.calendar_month), onTap: () async {
              final date = await showDatePicker(context: ctx, initialDate: hatch, firstDate: DateTime(2000), lastDate: DateTime.now());
              if (date != null) setDialogState(() => hatch = date);
            }),
        ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () { if (form.currentState!.validate()) Navigator.pop(ctx, true); }, child: Text(existing == null ? 'Create flock' : 'Save details'))],
      )));
    final flockName = name.text;
    final count = int.tryParse(birds.text);
    name.dispose(); birds.dispose();
    if (confirmed == true && count != null && mounted) {
      await _run(() => existing == null
          ? _repository.create(name: flockName, birds: count, hatchedAt: hatch)
          : _repository.updateDetails(existing, name: flockName, hatchedAt: hatch));
    }
  }

  Future<void> _close(Flock flock) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(flock.active ? 'Close ${flock.name}?' : 'Reopen ${flock.name}?'),
      content: Text(flock.active
        ? 'Records stay available for viewing. New mortality, vaccination and egg records will be blocked until you reopen the batch. Remaining egg stock must be zero.'
        : 'You will be able to record activity for this flock again.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(flock.active ? 'Close batch' : 'Reopen'))],
    ));
    if (confirmed == true && mounted) await _run(() => _repository.setActive(flock, !flock.active));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your flocks'), actions: [IconButton(tooltip: 'Back to farm', onPressed: _busy ? null : _home, icon: const Icon(Icons.home_outlined))]),
    body: StreamBuilder<List<FlockSummary>>(stream: _summary, builder: (context, snapshot) {
      if (snapshot.hasError) return const Center(child: Text('Could not load flocks. Check your connection.'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final rows = snapshot.data!;
      final active = rows.where((r) => r.flock.active).toList();
      final birds = active.fold<int>(0, (sum, row) => sum + row.birdsRemaining);
      final eggs = rows.fold<int>(0, (sum, row) => sum + row.flock.eggStock);
      return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), children: [
        Text('Farm overview', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('${active.length} active flocks · $birds birds remaining · $eggs eggs in stock', style: Theme.of(context).textTheme.titleMedium),
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Birds remaining = starting birds minus recorded mortalities. Expenses and workers are shared across the farm.')),
        if (rows.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Text('Add your first flock to start tracking birds by age.')),
        for (final isActive in [true, false]) ...[
          if (rows.any((row) => row.flock.active == isActive)) Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(isActive ? 'Active flocks' : 'Closed batches', style: Theme.of(context).textTheme.titleLarge)),
          for (final row in rows.where((r) => r.flock.active == isActive)) _flockRow(row),
        ],
        if (_busy) const LinearProgressIndicator(),
      ]);
    }),
    floatingActionButton: FloatingActionButton.extended(onPressed: _busy ? null : () => _create(), icon: const Icon(Icons.add), label: const Text('Add flock')),
  );

  Widget _flockRow(FlockSummary row) {
    final flock = row.flock;
    final days = flock.ageInDays(DateTime.now());
    final age = days == null ? 'Hatch date not recorded' : '${days ~/ 7} weeks ${days % 7} days old';
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Material(
      color: flock.id == FarmScope.flockId ? Colors.deepPurple.shade50 : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(16), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(flock.name, style: Theme.of(context).textTheme.titleLarge)),
          if (flock.id == FarmScope.flockId) const Chip(label: Text('Selected'))]),
        Text(age), const SizedBox(height: 8),
        Text('${row.birdsRemaining} birds remaining · ${row.deaths} mortalities · ${flock.eggStock} eggs'),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          FilledButton.tonal(onPressed: _busy ? null : () => _run(() => _repository.select(flock.id)),
            child: Text(flock.active ? 'Open flock' : 'View records')),
          TextButton(onPressed: _busy ? null : () => _create(flock), child: const Text('Edit details')),
          TextButton(onPressed: _busy ? null : () => _close(flock), child: Text(flock.active ? 'Close batch' : 'Reopen batch')),
        ]),
      ]))),
    );
  }
}
