import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../core/config.dart';

DateTime _dt(dynamic v) => v is Timestamp ? v.toDate() : DateTime.now();
double _d(dynamic v) => v is num ? v.toDouble() : 0;
int _i(dynamic v) => v is num ? v.toInt() : 0;

class Place {
  final String address;
  final double lat, lng;
  const Place(this.address, this.lat, this.lng);
  LatLng get ll => LatLng(lat, lng);
  String get short => address.split(',').first.trim();
  Map<String, dynamic> toMap() => {'address': address, 'lat': lat, 'lng': lng};
  factory Place.fromMap(Map<String, dynamic> m) =>
      Place('${m['address'] ?? ''}', _d(m['lat']), _d(m['lng']));
}

class AppUser {
  final String uid, name, email, phone, role, status;
  final String vehicleType, plate, serviceArea, verification;
  final String licenseB64, orcrB64, photoB64;
  final String safetyCheck;
  final double rating;
  final int ratingCount, completed;
  final bool online;
  final List<Place> saved;
  final List<Map<String, String>> savedContacts;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = 'customer',
    this.status = 'active',
    this.vehicleType = '',
    this.plate = '',
    this.serviceArea = '',
    this.verification = 'none',
    this.safetyCheck = 'none',
    this.licenseB64 = '',
    this.orcrB64 = '',
    this.photoB64 = '',
    this.rating = 0,
    this.ratingCount = 0,
    this.completed = 0,
    this.online = false,
    this.saved = const [],
    this.savedContacts = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get verified => verification == 'verified';
  bool get isDriver => role == 'driver';

  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final m = (doc.data() as Map<String, dynamic>?) ?? {};
    return AppUser(
      uid: doc.id,
      name: '${m['name'] ?? ''}',
      email: '${m['email'] ?? ''}',
      phone: '${m['phone'] ?? ''}',
      role: '${m['role'] ?? 'customer'}',
      status: '${m['status'] ?? 'active'}',
      vehicleType: '${m['vehicleType'] ?? ''}',
      plate: '${m['plate'] ?? ''}',
      serviceArea: '${m['serviceArea'] ?? ''}',
      verification: '${m['verification'] ?? 'none'}',
      safetyCheck: '${m['safetyCheck'] ?? 'none'}',
      licenseB64: '${m['licenseB64'] ?? ''}',
      orcrB64: '${m['orcrB64'] ?? ''}',
      photoB64: '${m['photoB64'] ?? ''}',
      rating: _d(m['rating']),
      ratingCount: _i(m['ratingCount']),
      completed: _i(m['completed']),
      online: m['online'] == true,
      saved: ((m['saved'] as List?) ?? [])
          .map((e) => Place.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      savedContacts: ((m['savedContacts'] as List?) ?? [])
          .map((e) => Map<String, String>.from(e as Map))
          .toList(),
      createdAt: _dt(m['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'status': status,
        'vehicleType': vehicleType,
        'plate': plate,
        'serviceArea': serviceArea,
        'verification': isDriver ? 'pending' : 'none',
        'safetyCheck': 'none',
        'licenseB64': '',
        'orcrB64': '',
        'photoB64': '',
        'rating': 0.0,
        'ratingCount': 0,
        'completed': 0,
        'online': false,
        'saved': [],
        'savedContacts': [],
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class HaulRequest {
  final String id,
      customerId,
      customerName,
      item,
      size,
      notes,
      vehicleType,
      status;
  final Place pickup, dest;
  final double distanceKm;
  final DateTime schedule, createdAt;
  final int quoteCount;

  HaulRequest({
    this.id = '',
    required this.customerId,
    required this.customerName,
    required this.pickup,
    required this.dest,
    required this.distanceKm,
    required this.item,
    required this.size,
    required this.schedule,
    this.notes = '',
    this.vehicleType = '',
    this.status = 'open',
    this.quoteCount = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory HaulRequest.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return HaulRequest(
      id: doc.id,
      customerId: '${m['customerId']}',
      customerName: '${m['customerName']}',
      pickup: Place.fromMap(Map<String, dynamic>.from(m['pickup'])),
      dest: Place.fromMap(Map<String, dynamic>.from(m['dest'])),
      distanceKm: _d(m['distanceKm']),
      item: '${m['item']}',
      size: '${m['size']}',
      schedule: _dt(m['schedule']),
      notes: '${m['notes'] ?? ''}',
      vehicleType: '${m['vehicleType'] ?? ''}',
      status: '${m['status'] ?? 'open'}',
      quoteCount: _i(m['quoteCount']),
      createdAt: _dt(m['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'customerName': customerName,
        'pickup': pickup.toMap(),
        'dest': dest.toMap(),
        'distanceKm': distanceKm,
        'item': item,
        'size': size,
        'schedule': Timestamp.fromDate(schedule),
        'notes': notes,
        'vehicleType': vehicleType,
        'status': 'open',
        'quoteCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class Quote {
  final String id,
      requestId,
      driverId,
      driverName,
      customerId,
      vehicle,
      message,
      status,
      item,
      route;
  final double price, driverRating;
  final DateTime availability, createdAt;

  Quote({
    this.id = '',
    required this.requestId,
    required this.driverId,
    required this.driverName,
    this.customerId = '',
    required this.driverRating,
    required this.vehicle,
    required this.price,
    required this.availability,
    this.message = '',
    this.status = 'pending',
    this.item = '',
    this.route = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Quote.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return Quote(
      id: doc.id,
      requestId: '${m['requestId']}',
      driverId: '${m['driverId']}',
      driverName: '${m['driverName']}',
      customerId: '${m['customerId'] ?? ''}',
      driverRating: _d(m['driverRating']),
      vehicle: '${m['vehicle']}',
      price: _d(m['price']),
      availability: _dt(m['availability']),
      message: '${m['message'] ?? ''}',
      status: '${m['status'] ?? 'pending'}',
      item: '${m['item'] ?? ''}',
      route: '${m['route'] ?? ''}',
      createdAt: _dt(m['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'requestId': requestId,
        'driverId': driverId,
        'driverName': driverName,
        'customerId': customerId,
        'driverRating': driverRating,
        'vehicle': vehicle,
        'price': price,
        'availability': Timestamp.fromDate(availability),
        'message': message,
        'status': 'pending',
        'item': item,
        'route': route,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class Booking {
  final String id,
      code,
      requestId,
      quoteId,
      customerId,
      customerName,
      driverId,
      driverName,
      vehicle,
      item;
  final String status;

  /// Legacy base64 image (kept so old bookings still display).
  final String proofB64;

  /// Cloudinary secure URL for the proof photo (new).
  final String proofUrl;

  /// Base64 PNG of the recipient's signature.
  final String signatureB64;

  final String issue;
  final double price;
  final DateTime schedule, createdAt;
  final DateTime? proofAt;
  final Place pickup, dest;
  final bool reviewed, started, pickedUp;
  final bool codCollected;
  final double? codAmount;
  final bool payoutRequested;
  final double? driverLat, driverLng;
  final double commission, earnings;

  Booking({
    this.id = '',
    required this.code,
    required this.requestId,
    required this.quoteId,
    required this.customerId,
    required this.customerName,
    required this.driverId,
    required this.driverName,
    required this.vehicle,
    required this.item,
    required this.price,
    required this.schedule,
    required this.pickup,
    required this.dest,
    this.status = 'accepted',
    this.proofB64 = '',
    this.proofUrl = '',
    this.signatureB64 = '',
    this.proofAt,
    this.reviewed = false,
    this.issue = '',
    this.started = false,
    this.pickedUp = false,
    this.codCollected = false,
    this.codAmount,
    this.payoutRequested = false,
    this.driverLat,
    this.driverLng,
    double? commission,
    double? earnings,
    DateTime? createdAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        commission = commission ?? AppConfig.fee(price),
        earnings = earnings ?? (price - AppConfig.fee(price));

  factory Booking.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      code: '${m['code']}',
      requestId: '${m['requestId']}',
      quoteId: '${m['quoteId']}',
      customerId: '${m['customerId']}',
      customerName: '${m['customerName']}',
      driverId: '${m['driverId']}',
      driverName: '${m['driverName']}',
      vehicle: '${m['vehicle']}',
      item: '${m['item']}',
      price: _d(m['price']),
      schedule: _dt(m['schedule']),
      pickup: Place.fromMap(Map<String, dynamic>.from(m['pickup'])),
      dest: Place.fromMap(Map<String, dynamic>.from(m['dest'])),
      status: '${m['status']}',
      proofB64: '${m['proofB64'] ?? ''}',
      proofUrl: '${m['proofUrl'] ?? ''}',
      signatureB64: '${m['signatureB64'] ?? ''}',
      proofAt: m['proofAt'] == null ? null : _dt(m['proofAt']),
      reviewed: m['reviewed'] == true,
      issue: '${m['issue'] ?? ''}',
      createdAt: _dt(m['createdAt']),
      started: m['started'] == true,
      pickedUp: m['pickedUp'] == true,
      codCollected: m['codCollected'] == true,
      codAmount: m['codAmount'] == null ? null : _d(m['codAmount']),
      payoutRequested: m['payoutRequested'] == true,
      driverLat: m['driverLat'] == null ? null : _d(m['driverLat']),
      driverLng: m['driverLng'] == null ? null : _d(m['driverLng']),
      commission: m['commission'] == null ? null : _d(m['commission']),
      earnings: m['earnings'] == null ? null : _d(m['earnings']),
    );
  }

  Map<String, dynamic> toMap() => {
        'code': code,
        'requestId': requestId,
        'quoteId': quoteId,
        'customerId': customerId,
        'customerName': customerName,
        'driverId': driverId,
        'driverName': driverName,
        'vehicle': vehicle,
        'item': item,
        'price': price,
        'schedule': Timestamp.fromDate(schedule),
        'pickup': pickup.toMap(),
        'dest': dest.toMap(),
        'status': 'accepted',
        'proofB64': '',
        'proofUrl': '',
        'signatureB64': '',
        'reviewed': false,
        'issue': '',
        'started': false,
        'pickedUp': false,
        'codCollected': false,
        'codAmount': codAmount,
        'payoutRequested': false,
        'commission': commission,
        'earnings': earnings,
        'commissionRate': AppConfig.commissionRate,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class Review {
  final String id, bookingId, driverId, customerId, customerName, comment;
  final int rating;
  final DateTime createdAt;
  Review({
    required this.id,
    required this.bookingId,
    required this.driverId,
    required this.customerId,
    required this.customerName,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });

  factory Review.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      bookingId: '${m['bookingId']}',
      driverId: '${m['driverId']}',
      customerId: '${m['customerId']}',
      customerName: '${m['customerName']}',
      comment: '${m['comment'] ?? ''}',
      rating: _i(m['rating']),
      createdAt: _dt(m['createdAt']),
    );
  }
}
