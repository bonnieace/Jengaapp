import 'package:cloud_firestore/cloud_firestore.dart';

import 'farm_scope.dart';

class EggRepository {
  EggRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _flock {
    final flockId = FarmScope.flockId;
    if (flockId == null) throw StateError('An active flock is required.');
    return FarmScope.tenant.collection('flocks').doc(flockId);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchFlock() =>
      _flock.snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchProduction() =>
      _flock.collection('eggProduction').orderBy('recordedFor', descending: true).limit(60).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSales() =>
      _flock.collection('eggSales').orderBy('soldAt', descending: true).limit(60).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAdjustments() =>
      _flock.collection('eggStockAdjustments').orderBy('createdAt', descending: true).limit(60).snapshots();

  Future<void> recordProduction({
    required DateTime recordedFor,
    required int goodEggs,
    required int crackedEggs,
    required int dirtyEggs,
    required int rejectedEggs,
    String note = '',
  }) async {
    if (goodEggs < 0 || crackedEggs < 0 || dirtyEggs < 0 || rejectedEggs < 0) {
      throw ArgumentError('Egg counts cannot be negative.');
    }
    if (goodEggs + crackedEggs + dirtyEggs + rejectedEggs == 0) {
      throw ArgumentError('Record at least one egg.');
    }

    final record = _flock.collection('eggProduction').doc();
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(_flock);
      if (!snapshot.exists) throw StateError('The active flock no longer exists.');
      final currentStock = (snapshot.data()?['eggStock'] as num?)?.toInt() ?? 0;
      transaction.set(record, {
        'recordedFor': Timestamp.fromDate(recordedFor),
        'goodEggs': goodEggs,
        'crackedEggs': crackedEggs,
        'dirtyEggs': dirtyEggs,
        'rejectedEggs': rejectedEggs,
        'totalCollected': goodEggs + crackedEggs + dirtyEggs + rejectedEggs,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(_flock, {
        'eggStock': currentStock + goodEggs,
        'eggMutationId': record.id,
        'eggMutationType': 'production',
        'lifetimeGoodEggs': FieldValue.increment(goodEggs),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> recordSale({
    required DateTime soldAt,
    required int trays,
    required int looseEggs,
    required int eggsPerTray,
    required double unitPrice,
    required double amountPaid,
    required String buyer,
    required String paymentStatus,
    String note = '',
  }) async {
    if (trays < 0 || looseEggs < 0 || eggsPerTray < 1 || unitPrice <= 0) {
      throw ArgumentError('Enter valid sale quantities and price.');
    }
    final quantity = (trays * eggsPerTray) + looseEggs;
    if (quantity < 1) throw ArgumentError('Record at least one egg sold.');
    final totalAmount = quantity * unitPrice;
    if (amountPaid < 0 || amountPaid > totalAmount) {
      throw ArgumentError('Amount received must be between zero and the sale total.');
    }
    var normalizedAmountPaid = amountPaid;
    if (paymentStatus == 'paid') normalizedAmountPaid = totalAmount;
    if (paymentStatus == 'credit') normalizedAmountPaid = 0;
    if (paymentStatus == 'partial' && (normalizedAmountPaid <= 0 || normalizedAmountPaid >= totalAmount)) {
      throw ArgumentError('A partial payment must be above zero and below the sale total.');
    }

    final sale = _flock.collection('eggSales').doc();
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(_flock);
      if (!snapshot.exists) throw StateError('The active flock no longer exists.');
      final currentStock = (snapshot.data()?['eggStock'] as num?)?.toInt() ?? 0;
      if (quantity > currentStock) {
        throw StateError('Only $currentStock sellable eggs are currently available.');
      }
      transaction.set(sale, {
        'soldAt': Timestamp.fromDate(soldAt),
        'trays': trays,
        'looseEggs': looseEggs,
        'eggsPerTray': eggsPerTray,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'totalAmount': totalAmount,
        'amountPaid': normalizedAmountPaid,
        'balanceDue': totalAmount - normalizedAmountPaid,
        'buyer': buyer,
        'paymentStatus': paymentStatus,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(_flock, {
        'eggStock': currentStock - quantity,
        'eggMutationId': sale.id,
        'eggMutationType': 'sale',
        'lifetimeEggsSold': FieldValue.increment(quantity),
        'lifetimeEggRevenue': FieldValue.increment(totalAmount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> adjustStock({required int delta, required String reason}) async {
    if (delta == 0) throw ArgumentError('The adjustment cannot be zero.');
    if (reason.trim().length < 3) throw ArgumentError('Add a reason for this correction.');
    final adjustment = _flock.collection('eggStockAdjustments').doc();
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(_flock);
      if (!snapshot.exists) throw StateError('The active flock no longer exists.');
      final currentStock = (snapshot.data()?['eggStock'] as num?)?.toInt() ?? 0;
      final correctedStock = currentStock + delta;
      if (correctedStock < 0) {
        throw StateError('This correction would reduce stock below zero.');
      }
      transaction.set(adjustment, {
        'delta': delta,
        'stockBefore': currentStock,
        'stockAfter': correctedStock,
        'reason': reason.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(_flock, {
        'eggStock': correctedStock,
        'eggMutationId': adjustment.id,
        'eggMutationType': 'adjustment',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
