import 'package:cloud_firestore/cloud_firestore.dart';

class Notif {
  static final _db = FirebaseFirestore.instance;

  // ─────────────────── CUSTOMER ───────────────────

  static Stream<int> customerRequests(String uid) => _db
      .collection('requests')
      .where('customerId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.where((d) => d.data()['status'] == 'open').fold<int>(0,
              (a, d) {
            final qc = d.data()['quoteCount'];
            return a + (qc is num ? qc.toInt() : 0);
          }));

  static Stream<int> customerBookings(String uid) => _db
      .collection('bookings')
      .where('customerId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs
          .where((d) => ['accepted', 'inTransit', 'delivered']
              .contains('${d.data()['status']}'))
          .length);

  // ─────────────────── DRIVER ───────────────────

  /// Open requests available to quote on.
  static Stream<int> driverJobs() => _db
      .collection('requests')
      .where('status', isEqualTo: 'open')
      .snapshots()
      .map((s) => s.docs.length);

  static Stream<int> driverQuotes(String uid) => _db
      .collection('quotations')
      .where('driverId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs
          .where(
              (d) => ['accepted', 'declined'].contains('${d.data()['status']}'))
          .length);

  static Stream<int> driverActive(String uid) => _db
      .collection('bookings')
      .where('driverId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs
          .where((d) =>
              ['accepted', 'inTransit'].contains('${d.data()['status']}'))
          .length);

  // ─────────────────── ADMIN ───────────────────

  static Stream<int> adminPendingDrivers() =>
      _db.collection('users').snapshots().map((s) => s.docs.where((d) {
            final m = d.data();
            return m['role'] == 'driver' && m['verification'] == 'pending';
          }).length);
}
