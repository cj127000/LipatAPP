import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

DateTime _t(dynamic v) => v is Timestamp ? v.toDate() : DateTime.now();

class ChatMsg {
  final String id, senderId, text;
  final DateTime at;
  ChatMsg(this.id, this.senderId, this.text, this.at);
}

class ChatInfo {
  final String id, title, code;
  final String customerId, customerName, driverId, driverName;
  final String lastText, lastSender;
  final DateTime? lastAt;
  final Map<String, int> unread;

  ChatInfo({
    required this.id,
    required this.title,
    required this.code,
    required this.customerId,
    required this.customerName,
    required this.driverId,
    required this.driverName,
    this.lastText = '',
    this.lastSender = '',
    this.lastAt,
    this.unread = const {},
  });

  factory ChatInfo.fromBooking(Booking b) => ChatInfo(
        id: b.id,
        title: b.item,
        code: b.code,
        customerId: b.customerId,
        customerName: b.customerName,
        driverId: b.driverId,
        driverName: b.driverName,
      );

  factory ChatInfo.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    final u = <String, int>{};
    final raw = m['unread'];
    if (raw is Map) {
      raw.forEach((k, v) => u['$k'] = v is num ? v.toInt() : 0);
    }
    return ChatInfo(
      id: d.id,
      title: '${m['title'] ?? ''}',
      code: '${m['code'] ?? ''}',
      customerId: '${m['customerId'] ?? ''}',
      customerName: '${m['customerName'] ?? ''}',
      driverId: '${m['driverId'] ?? ''}',
      driverName: '${m['driverName'] ?? ''}',
      lastText: '${m['lastText'] ?? ''}',
      lastSender: '${m['lastSender'] ?? ''}',
      lastAt:
          m['lastAt'] is Timestamp ? (m['lastAt'] as Timestamp).toDate() : null,
      unread: u,
    );
  }

  int unreadFor(String uid) => unread[uid] ?? 0;
  String otherId(String me) => me == customerId ? driverId : customerId;
  String otherName(String me) => me == customerId ? driverName : customerName;
}

class Chat {
  static final _f = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get chats =>
      _f.collection('chats');

  /// Newest first (the chat list is displayed reversed so it sticks to the bottom).
  static Stream<List<ChatMsg>> messages(String chatId) => chats
      .doc(chatId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(150)
      .snapshots()
      .map((s) => s.docs.map((d) {
            final m = d.data();
            return ChatMsg(
                d.id, '${m['senderId']}', '${m['text']}', _t(m['createdAt']));
          }).toList());

  static Stream<ChatInfo?> one(String chatId) => chats
      .doc(chatId)
      .snapshots()
      .map((d) => d.exists ? ChatInfo.fromDoc(d) : null);

  static Stream<List<ChatInfo>> mine(String uid) =>
      chats.where('members', arrayContains: uid).snapshots().map((s) {
        final l = s.docs
            .map((d) => ChatInfo.fromDoc(d))
            .where((c) => c.lastText.isNotEmpty)
            .toList();
        l.sort((a, b) =>
            (b.lastAt ?? DateTime.now()).compareTo(a.lastAt ?? DateTime.now()));
        return l;
      });

  static Stream<int> unreadTotal(String uid) =>
      mine(uid).map((l) => l.fold<int>(0, (a, c) => a + c.unreadFor(uid)));

  static Future<void> send(ChatInfo info, String fromId, String text) async {
    final to = info.otherId(fromId);
    final ref = chats.doc(info.id);
    final b = _f.batch();
    b.set(
        ref,
        {
          'members': [info.customerId, info.driverId],
          'customerId': info.customerId,
          'customerName': info.customerName,
          'driverId': info.driverId,
          'driverName': info.driverName,
          'title': info.title,
          'code': info.code,
          'lastText': text,
          'lastSender': fromId,
          'lastAt': FieldValue.serverTimestamp(),
          'unread': {to: FieldValue.increment(1), fromId: 0},
        },
        SetOptions(merge: true));
    b.set(ref.collection('messages').doc(), {
      'senderId': fromId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await b.commit();
  }

  static Future<void> markRead(String chatId, String uid) async {
    try {
      await chats.doc(chatId).update({'unread.$uid': 0});
    } catch (_) {}
  }
}
