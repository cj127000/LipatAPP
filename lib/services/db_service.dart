import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

List<T> _sorted<T>(List<T> l, DateTime Function(T) k) =>
    l..sort((a, b) => k(b).compareTo(k(a)));

class Db {
  static final _f = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get users =>
      _f.collection('users');
  static CollectionReference<Map<String, dynamic>> get requests =>
      _f.collection('requests');
  static CollectionReference<Map<String, dynamic>> get quotes =>
      _f.collection('quotations');
  static CollectionReference<Map<String, dynamic>> get bookings =>
      _f.collection('bookings');
  static CollectionReference<Map<String, dynamic>> get reviews =>
      _f.collection('reviews');

  // ---------- users ----------
  static Stream<AppUser?> userStream(String uid) => users
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? AppUser.fromDoc(d) : null);
  static Future<void> createUser(AppUser u) => users.doc(u.uid).set(u.toMap());
  static Future<void> updateUser(String uid, Map<String, dynamic> data) =>
      users.doc(uid).update(data);
  static Stream<List<AppUser>> allUsers() =>
      users.snapshots().map((s) => _sorted(
          s.docs.map((d) => AppUser.fromDoc(d)).toList(), (u) => u.createdAt));

  // ---------- requests ----------
  static Stream<List<HaulRequest>> customerRequests(String uid) => requests
      .where('customerId', isEqualTo: uid)
      .snapshots()
      .map((s) => _sorted(s.docs.map((d) => HaulRequest.fromDoc(d)).toList(),
          (r) => r.createdAt));
  static Stream<List<HaulRequest>> openRequests() => requests
      .where('status', isEqualTo: 'open')
      .snapshots()
      .map((s) => _sorted(s.docs.map((d) => HaulRequest.fromDoc(d)).toList(),
          (r) => r.createdAt));
  static Stream<List<HaulRequest>> allRequests() => requests
      .snapshots()
      .map((s) => s.docs.map((d) => HaulRequest.fromDoc(d)).toList());
  static Future<void> postRequest(HaulRequest r) => requests.add(r.toMap());
  static Future<void> cancelRequest(String id) =>
      requests.doc(id).update({'status': 'cancelled'});

  // ---------- quotations ----------
  static Stream<List<Quote>> requestQuotes(String requestId) => quotes
      .where('requestId', isEqualTo: requestId)
      .snapshots()
      .map((s) => s.docs.map((d) => Quote.fromDoc(d)).toList());
  static Stream<List<Quote>> driverQuotes(String driverId) => quotes
      .where('driverId', isEqualTo: driverId)
      .snapshots()
      .map((s) => _sorted(
          s.docs.map((d) => Quote.fromDoc(d)).toList(), (q) => q.createdAt));

  static Future<void> submitQuote(Quote q) async {
    final ref = quotes.doc(
        '${q.requestId}_${q.driverId}'); // one quotation per driver per request
    if ((await ref.get()).exists)
      throw 'You already sent a quotation for this request.';
    final b = _f.batch();
    b.set(ref, q.toMap());
    b.update(
        requests.doc(q.requestId), {'quoteCount': FieldValue.increment(1)});
    await b.commit();
  }

  // ---------- bookings ----------
  static String newCode() =>
      'LPT-${DateTime.now().year}-${(1000 + Random().nextInt(9000))}';

  static Future<String> confirmBooking(
      HaulRequest r, Quote q, String code) async {
    final all = await quotes.where('requestId', isEqualTo: r.id).get();
    final ref = bookings.doc();
    final b = _f.batch();
    b.set(
        ref,
        Booking(
          code: code,
          requestId: r.id,
          quoteId: q.id,
          customerId: r.customerId,
          customerName: r.customerName,
          driverId: q.driverId,
          driverName: q.driverName,
          vehicle: q.vehicle,
          item: r.item,
          price: q.price,
          schedule: q.availability,
          pickup: r.pickup,
          dest: r.dest,
        ).toMap());
    for (final d in all.docs) {
      b.update(d.reference, {'status': d.id == q.id ? 'accepted' : 'declined'});
    }
    b.update(requests.doc(r.id), {'status': 'booked'});
    await b.commit();
    return ref.id;
  }

  static Stream<Booking?> booking(String id) => bookings
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Booking.fromDoc(d) : null);
  static Stream<List<Booking>> customerBookings(String uid) => bookings
      .where('customerId', isEqualTo: uid)
      .snapshots()
      .map((s) => _sorted(
          s.docs.map((d) => Booking.fromDoc(d)).toList(), (b) => b.createdAt));
  static Stream<List<Booking>> driverBookings(String uid) =>
      bookings.where('driverId', isEqualTo: uid).snapshots().map((s) => _sorted(
          s.docs.map((d) => Booking.fromDoc(d)).toList(), (b) => b.createdAt));
  static Stream<List<Booking>> allBookings() =>
      bookings.snapshots().map((s) => _sorted(
          s.docs.map((d) => Booking.fromDoc(d)).toList(), (b) => b.createdAt));

  static Future<void> updateBooking(String id, Map<String, dynamic> data) =>
      bookings.doc(id).update(data);

  static Future<void> cancelBooking(Booking b) async {
    final batch = _f.batch();
    batch.update(bookings.doc(b.id), {'status': 'cancelled'});
    batch.update(requests.doc(b.requestId), {'status': 'cancelled'});
    await batch.commit();
  }

  static Future<void> completeBooking(Booking b) async {
    final batch = _f.batch();
    batch.update(bookings.doc(b.id), {'status': 'completed'});
    batch.update(users.doc(b.driverId), {'completed': FieldValue.increment(1)});
    await batch.commit();
  }

  // ---------- reviews ----------
  static Future<void> submitReview(
      Booking b, int rating, String comment) async {
    final dref = users.doc(b.driverId);
    await _f.runTransaction((t) async {
      final snap = await t.get(dref);
      final m = snap.data() ?? {};
      final rc = ((m['ratingCount'] ?? 0) as num).toInt();
      final r = ((m['rating'] ?? 0) as num).toDouble();
      t.update(dref,
          {'rating': ((r * rc) + rating) / (rc + 1), 'ratingCount': rc + 1});
      t.set(reviews.doc(), {
        'bookingId': b.id,
        'driverId': b.driverId,
        'customerId': b.customerId,
        'customerName': b.customerName,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });
      t.update(bookings.doc(b.id), {'reviewed': true});
    });
  }

  static Stream<List<Review>> driverReviews(String driverId) => reviews
      .where('driverId', isEqualTo: driverId)
      .snapshots()
      .map((s) => _sorted(
          s.docs.map((d) => Review.fromDoc(d)).toList(), (r) => r.createdAt));
  static Stream<List<Review>> customerReviews(String cid) => reviews
      .where('customerId', isEqualTo: cid)
      .snapshots()
      .map((s) => _sorted(
          s.docs.map((d) => Review.fromDoc(d)).toList(), (r) => r.createdAt));
}
