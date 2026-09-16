import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/egg_repository.dart';

class EggDashboardScreen extends StatefulWidget {
  const EggDashboardScreen({super.key});

  @override
  State<EggDashboardScreen> createState() => _EggDashboardScreenState();
}

class _EggDashboardScreenState extends State<EggDashboardScreen> {
  final EggRepository _repository = EggRepository();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Egg Production & Sales'),
          bottom: const TabBar(tabs: [
            Tab(icon: Icon(Icons.egg_outlined), text: 'Production'),
            Tab(icon: Icon(Icons.point_of_sale), text: 'Sales'),
            Tab(icon: Icon(Icons.tune), text: 'Corrections'),
          ]),
        ),
        body: Column(children: [
          _StockSummary(repository: _repository),
          Expanded(child: TabBarView(children: [
            _ProductionList(repository: _repository),
            _SalesList(repository: _repository),
            _AdjustmentList(repository: _repository),
          ])),
        ]),
        floatingActionButton: Builder(builder: (context) {
          final tab = DefaultTabController.of(context);
          return AnimatedBuilder(
            animation: tab,
            builder: (context, _) => FloatingActionButton.extended(
              onPressed: () => tab.index == 0
                  ? _showProductionForm(context)
                  : tab.index == 1 ? _showSaleForm(context) : _showAdjustmentForm(context),
              icon: Icon(tab.index == 0 ? Icons.add : tab.index == 1 ? Icons.shopping_cart_checkout : Icons.tune),
              label: Text(tab.index == 0 ? 'Record collection' : tab.index == 1 ? 'Record sale' : 'Correct stock'),
            ),
          );
        }),
      ),
    );
  }

  Future<void> _showProductionForm(BuildContext context) async {
    final good = TextEditingController();
    final cracked = TextEditingController(text: '0');
    final dirty = TextEditingController(text: '0');
    final rejected = TextEditingController(text: '0');
    final note = TextEditingController();
    DateTime date = DateTime.now();
    bool busy = false;

    await showDialog<void>(context: context, builder: (dialogContext) {
      return StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: const Text('Record egg collection'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          _NumberField(controller: good, label: 'Good eggs', autofocus: true),
          _NumberField(controller: cracked, label: 'Cracked eggs'),
          _NumberField(controller: dirty, label: 'Dirty eggs'),
          _NumberField(controller: rejected, label: 'Other rejected eggs'),
          TextField(controller: note, decoration: const InputDecoration(labelText: 'Note (optional)')),
          ListTile(contentPadding: EdgeInsets.zero, title: Text(DateFormat.yMMMd().format(date)), trailing: const Icon(Icons.calendar_month), onTap: () async {
            final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now());
            if (picked != null) setDialogState(() => date = picked);
          }),
        ])),
        actions: [
          TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: busy ? null : () async {
            final values = [good, cracked, dirty, rejected].map((c) => int.tryParse(c.text.trim()) ?? 0).toList();
            setDialogState(() => busy = true);
            try {
              await _repository.recordProduction(recordedFor: date, goodEggs: values[0], crackedEggs: values[1], dirtyEggs: values[2], rejectedEggs: values[3], note: note.text.trim());
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Egg collection recorded.')));
            } catch (error) {
              setDialogState(() => busy = false);
              if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(_message(error))));
            }
          }, child: Text(busy ? 'Saving…' : 'Save')),
        ],
      ));
    });
    good.dispose();
    cracked.dispose();
    dirty.dispose();
    rejected.dispose();
    note.dispose();
  }

  Future<void> _showSaleForm(BuildContext context) async {
    final trays = TextEditingController(text: '0');
    final loose = TextEditingController(text: '0');
    final eggsPerTray = TextEditingController(text: '30');
    final unitPrice = TextEditingController();
    final amountPaid = TextEditingController();
    final buyer = TextEditingController();
    final note = TextEditingController();
    String paymentStatus = 'paid';
    DateTime date = DateTime.now();
    bool busy = false;

    await showDialog<void>(context: context, builder: (dialogContext) {
      return StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
        title: const Text('Record egg sale'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          _NumberField(controller: trays, label: 'Trays sold'),
          _NumberField(controller: loose, label: 'Loose eggs sold'),
          _NumberField(controller: eggsPerTray, label: 'Eggs per tray'),
          TextField(controller: unitPrice, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price per egg (KSh)')),
          if (paymentStatus == 'partial') TextField(controller: amountPaid, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount received (KSh)')),
          TextField(controller: buyer, decoration: const InputDecoration(labelText: 'Buyer (optional)')),
          DropdownButtonFormField<String>(value: paymentStatus, decoration: const InputDecoration(labelText: 'Payment status'), items: const [
            DropdownMenuItem(value: 'paid', child: Text('Paid')),
            DropdownMenuItem(value: 'partial', child: Text('Partially paid')),
            DropdownMenuItem(value: 'credit', child: Text('Credit / unpaid')),
          ], onChanged: (value) => setDialogState(() => paymentStatus = value ?? 'paid')),
          TextField(controller: note, decoration: const InputDecoration(labelText: 'Note (optional)')),
          ListTile(contentPadding: EdgeInsets.zero, title: Text(DateFormat.yMMMd().format(date)), trailing: const Icon(Icons.calendar_month), onTap: () async {
            final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now());
            if (picked != null) setDialogState(() => date = picked);
          }),
        ])),
        actions: [
          TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: busy ? null : () async {
            setDialogState(() => busy = true);
            try {
              await _repository.recordSale(
                soldAt: date,
                trays: int.tryParse(trays.text.trim()) ?? 0,
                looseEggs: int.tryParse(loose.text.trim()) ?? 0,
                eggsPerTray: int.tryParse(eggsPerTray.text.trim()) ?? 0,
                unitPrice: double.tryParse(unitPrice.text.trim()) ?? 0,
                amountPaid: double.tryParse(amountPaid.text.trim()) ?? 0,
                buyer: buyer.text.trim(),
                paymentStatus: paymentStatus,
                note: note.text.trim(),
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Egg sale recorded.')));
            } catch (error) {
              setDialogState(() => busy = false);
              if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(_message(error))));
            }
          }, child: Text(busy ? 'Saving…' : 'Save sale')),
        ],
      ));
    });
    trays.dispose();
    loose.dispose();
    eggsPerTray.dispose();
    unitPrice.dispose();
    amountPaid.dispose();
    buyer.dispose();
    note.dispose();
  }

  Future<void> _showAdjustmentForm(BuildContext context) async {
    final delta = TextEditingController();
    final reason = TextEditingController();
    bool busy = false;
    await showDialog<void>(context: context, builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Correct egg stock'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: delta,
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            decoration: const InputDecoration(labelText: 'Adjustment', helperText: 'Use + to add or − to remove eggs'),
          ),
          TextField(controller: reason, decoration: const InputDecoration(labelText: 'Reason')),
        ]),
        actions: [
          TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: busy ? null : () async {
            setDialogState(() => busy = true);
            try {
              await _repository.adjustStock(delta: int.tryParse(delta.text.trim()) ?? 0, reason: reason.text);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (mounted) ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Stock correction recorded.')));
            } catch (error) {
              setDialogState(() => busy = false);
              if (dialogContext.mounted) ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(_message(error))));
            }
          }, child: Text(busy ? 'Saving…' : 'Save correction')),
        ],
      ),
    ));
    delta.dispose();
    reason.dispose();
  }

  String _message(Object error) => error is ArgumentError
      ? error.message.toString()
      : error is StateError ? error.message : 'Could not save. Please try again.';
}

class _StockSummary extends StatelessWidget {
  const _StockSummary({required this.repository});
  final EggRepository repository;

  @override
  Widget build(BuildContext context) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: repository.watchFlock(),
    builder: (context, snapshot) {
      final data = snapshot.data?.data() ?? {};
      final stock = (data['eggStock'] as num?)?.toInt() ?? 0;
      final sold = (data['lifetimeEggsSold'] as num?)?.toInt() ?? 0;
      final revenue = (data['lifetimeEggRevenue'] as num?)?.toDouble() ?? 0;
      return Container(
        width: double.infinity,
        color: Colors.deepPurple.shade50,
        padding: const EdgeInsets.all(16),
        child: Wrap(alignment: WrapAlignment.spaceAround, spacing: 24, runSpacing: 12, children: [
          _Metric(label: 'Available', value: '$stock eggs'),
          _Metric(label: 'Sold', value: '$sold eggs'),
          _Metric(label: 'Sales value', value: 'KSh ${NumberFormat('#,##0.00').format(revenue)}'),
        ]),
      );
    },
  );
}

class _ProductionList extends StatelessWidget {
  const _ProductionList({required this.repository});
  final EggRepository repository;
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: repository.watchProduction(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return const Center(child: Text('Could not load production records.'));
      final docs = snapshot.data?.docs ?? [];
      if (docs.isEmpty) return const _EmptyState(icon: Icons.egg_outlined, text: 'No egg collections recorded yet.');
      return ListView.builder(padding: const EdgeInsets.only(bottom: 96), itemCount: docs.length, itemBuilder: (context, index) {
        final data = docs[index].data();
        final date = (data['recordedFor'] as Timestamp?)?.toDate();
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.egg_outlined)),
          title: Text('${data['goodEggs'] ?? 0} good eggs'),
          subtitle: Text('Cracked ${data['crackedEggs'] ?? 0} • Dirty ${data['dirtyEggs'] ?? 0} • Rejected ${data['rejectedEggs'] ?? 0}'),
          trailing: Text(date == null ? '' : DateFormat.MMMd().format(date)),
        );
      });
    },
  );
}

class _SalesList extends StatelessWidget {
  const _SalesList({required this.repository});
  final EggRepository repository;
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: repository.watchSales(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return const Center(child: Text('Could not load egg sales.'));
      final docs = snapshot.data?.docs ?? [];
      if (docs.isEmpty) return const _EmptyState(icon: Icons.point_of_sale, text: 'No egg sales recorded yet.');
      return ListView.builder(padding: const EdgeInsets.only(bottom: 96), itemCount: docs.length, itemBuilder: (context, index) {
        final data = docs[index].data();
        final amount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
        final status = data['paymentStatus'] as String? ?? 'paid';
        final balance = (data['balanceDue'] as num?)?.toDouble() ?? 0;
        return ListTile(
          leading: CircleAvatar(child: Text('${data['quantity'] ?? 0}')),
          title: Text('KSh ${NumberFormat('#,##0.00').format(amount)}'),
          subtitle: Text('${(data['buyer'] as String?)?.isNotEmpty == true ? data['buyer'] : 'Walk-in buyer'} • ${status.toUpperCase()}${balance > 0 ? ' • Due KSh ${NumberFormat('#,##0.00').format(balance)}' : ''}'),
          trailing: Text('${data['trays'] ?? 0} trays\n${data['looseEggs'] ?? 0} loose', textAlign: TextAlign.end),
        );
      });
    },
  );
}

class _AdjustmentList extends StatelessWidget {
  const _AdjustmentList({required this.repository});
  final EggRepository repository;
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: repository.watchAdjustments(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return const Center(child: Text('Could not load stock corrections.'));
      final docs = snapshot.data?.docs ?? [];
      if (docs.isEmpty) return const _EmptyState(icon: Icons.tune, text: 'No stock corrections recorded.');
      return ListView.builder(padding: const EdgeInsets.only(bottom: 96), itemCount: docs.length, itemBuilder: (context, index) {
        final data = docs[index].data();
        final delta = (data['delta'] as num?)?.toInt() ?? 0;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        return ListTile(
          leading: CircleAvatar(child: Icon(delta > 0 ? Icons.add : Icons.remove)),
          title: Text('${delta > 0 ? '+' : ''}$delta eggs'),
          subtitle: Text('${data['reason'] ?? ''} • ${data['stockBefore'] ?? 0} → ${data['stockAfter'] ?? 0}'),
          trailing: Text(createdAt == null ? '' : DateFormat.MMMd().format(createdAt)),
        );
      });
    },
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    Text(label, style: Theme.of(context).textTheme.bodySmall),
  ]);
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label, this.autofocus = false});
  final TextEditingController controller;
  final String label;
  final bool autofocus;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    autofocus: autofocus,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 56, color: Colors.grey),
    const SizedBox(height: 12),
    Text(text),
  ]));
}
