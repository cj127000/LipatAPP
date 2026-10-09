import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../services/chat_service.dart';
import '../services/db_service.dart';

// CALL
Future<void> callUser(BuildContext context, String uid, String name) async {
  try {
    final d = await Db.users.doc(uid).get();
    final raw = '${d.data()?['phone'] ?? ''}';
    final phone = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.isEmpty) {
      if (context.mounted)
        toast(context, '$name has no phone number on file.', error: true);
      return;
    }
    final ok = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!ok && context.mounted)
      toast(context, 'Could not open the phone dialer.', error: true);
  } catch (_) {
    if (context.mounted)
      toast(context, 'Could not get the phone number. Try again.', error: true);
  }
}

void openChat(BuildContext context, Booking b, {required bool asDriver}) {
  Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ChatScreen(
              info: ChatInfo.fromBooking(b),
              meId: asDriver ? b.driverId : b.customerId)));
}

// ═══════════════════════════════════════════════════════════════
// CONTACT BUTTONS (use on every transaction)
// ═══════════════════════════════════════════════════════════════

class _Badge extends StatelessWidget {
  final int n;
  const _Badge(this.n);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
        decoration: BoxDecoration(
            color: C.red,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white, width: 1.5)),
        child: Text(n > 9 ? '9+' : '$n',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700)),
      );
}

/// Compact round Message + Call icons (for list cards).
class ContactButtons extends StatelessWidget {
  final Booking booking;
  final bool asDriver;
  const ContactButtons(
      {super.key, required this.booking, required this.asDriver});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final meId = asDriver ? b.driverId : b.customerId;
    final otherId = asDriver ? b.customerId : b.driverId;
    final otherName = asDriver ? b.customerName : b.driverName;

    Widget circle(
            IconData icon, Color fg, Color bg, String tip, VoidCallback f) =>
        Tooltip(
          message: tip,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: f,
            child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, color: fg, size: 20)),
          ),
        );

    return Row(mainAxisSize: MainAxisSize.min, children: [
      StreamBuilder<ChatInfo?>(
        stream: Chat.one(b.id),
        builder: (c, s) {
          final n = s.data?.unreadFor(meId) ?? 0;
          return Stack(clipBehavior: Clip.none, children: [
            circle(
                Icons.chat_bubble_rounded,
                C.red,
                C.cream,
                'Message $otherName',
                () => openChat(context, b, asDriver: asDriver)),
            if (n > 0) Positioned(right: -4, top: -4, child: _Badge(n)),
          ]);
        },
      ),
      const SizedBox(width: 8),
      circle(Icons.call_rounded, C.green, C.greenBg, 'Call $otherName',
          () => callUser(context, otherId, otherName)),
    ]);
  }
}

class ContactBar extends StatelessWidget {
  final Booking booking;
  final bool asDriver;
  const ContactBar({super.key, required this.booking, required this.asDriver});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final meId = asDriver ? b.driverId : b.customerId;
    final otherId = asDriver ? b.customerId : b.driverId;
    final otherName = asDriver ? b.customerName : b.driverName;

    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    return Row(children: [
      Expanded(
        child: StreamBuilder<ChatInfo?>(
          stream: Chat.one(b.id),
          builder: (c, s) {
            final n = s.data?.unreadFor(meId) ?? 0;
            return SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => openChat(context, b, asDriver: asDriver),
                style: OutlinedButton.styleFrom(
                    foregroundColor: C.red,
                    side: const BorderSide(color: C.red, width: 1.4),
                    shape: shape),
                icon: Stack(clipBehavior: Clip.none, children: [
                  const Icon(Icons.chat_bubble_rounded, size: 19),
                  if (n > 0) Positioned(right: -9, top: -8, child: _Badge(n)),
                ]),
                label: Text('Message',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            );
          },
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: () => callUser(context, otherId, otherName),
            style: FilledButton.styleFrom(
                backgroundColor: C.green,
                foregroundColor: Colors.white,
                shape: shape,
                elevation: 0),
            icon: const Icon(Icons.call_rounded, size: 19),
            label: Text('Call',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ),
      ),
    ]);
  }
}

// INBOX ICON (header) + INBOX SCREEN

class MsgBell extends StatelessWidget {
  final String uid;
  const MsgBell({super.key, required this.uid});

  @override
  Widget build(BuildContext context) => StreamBuilder<int>(
        stream: Chat.unreadTotal(uid),
        builder: (c, s) {
          final n = s.data ?? 0;
          return Stack(clipBehavior: Clip.none, children: [
            IconButton(
              tooltip: 'Messages',
              style: IconButton.styleFrom(backgroundColor: C.cream),
              icon: const Icon(Icons.chat_bubble_outline_rounded, color: C.red),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => MessagesScreen(meId: uid))),
            ),
            if (n > 0) Positioned(right: 2, top: 2, child: _Badge(n)),
          ]);
        },
      );
}

String _stamp(DateTime d) {
  final now = DateTime.now();
  if (d.year == now.year && d.month == now.month && d.day == now.day)
    return DateFormat('h:mm a').format(d);
  return DateFormat('MMM d').format(d);
}

class MessagesScreen extends StatelessWidget {
  final String meId;
  const MessagesScreen({super.key, required this.meId});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Messages')),
        body: StreamBuilder<List<ChatInfo>>(
          stream: Chat.mine(meId),
          builder: (c, s) {
            if (s.hasError) {
              return const EmptyState(
                  Icons.lock_outline_rounded,
                  'Cannot load messages',
                  'Add the chat rules from CHAT_SETUP.md to your Firestore rules.');
            }
            if (!s.hasData) return const Loader();
            final l = s.data!;
            if (l.isEmpty) {
              return const EmptyState(
                  Icons.chat_bubble_outline_rounded,
                  'No messages yet',
                  'Open a booking and tap the message icon to start a conversation.');
            }
            return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  for (final ch in l)
                    AppCard(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ChatScreen(info: ch, meId: meId))),
                      child: Row(children: [
                        Avatar(ch.otherName(meId), size: 48),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Row(children: [
                                Expanded(
                                    child: Text(ch.otherName(meId),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15))),
                                Text(_stamp(ch.lastAt ?? DateTime.now()),
                                    style: const TextStyle(
                                        color: C.grey, fontSize: 11.5)),
                              ]),
                              const SizedBox(height: 2),
                              Text('${ch.code}  •  ${ch.title}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: C.red,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              Row(children: [
                                Expanded(
                                    child: Text(
                                        '${ch.lastSender == meId ? 'You: ' : ''}${ch.lastText}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: ch.unreadFor(meId) > 0
                                                ? C.ink
                                                : C.grey,
                                            fontWeight: ch.unreadFor(meId) > 0
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            fontSize: 13))),
                                if (ch.unreadFor(meId) > 0) ...[
                                  const SizedBox(width: 8),
                                  _Badge(ch.unreadFor(meId))
                                ],
                              ]),
                            ])),
                      ]),
                    ),
                ]);
          },
        ),
      );
}

// CHAT SCREEN

class ChatScreen extends StatefulWidget {
  final ChatInfo info;
  final String meId;
  const ChatScreen({super.key, required this.info, required this.meId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctl = TextEditingController();
  StreamSubscription<ChatInfo?>? _sub;

  ChatInfo get _i => widget.info;
  String get _otherId => _i.otherId(widget.meId);
  String get _otherName => _i.otherName(widget.meId);
  bool get _asDriver => widget.meId == _i.driverId;

  List<String> get _quick => _asDriver
      ? const [
          "I'm on my way",
          "I've arrived at the pickup",
          'Running a little late',
          'Item delivered'
        ]
      : const [
          'Where are you now?',
          'Please call me',
          "I'm ready for pickup",
          'Thank you!'
        ];

  @override
  void initState() {
    super.initState();
    // Clear this user's unread counter whenever new messages arrive while the chat is open.
    _sub = Chat.one(_i.id).listen((c) {
      if (c != null && c.unreadFor(widget.meId) > 0)
        Chat.markRead(_i.id, widget.meId);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final t = (preset ?? _ctl.text).trim();
    if (t.isEmpty) return;
    if (preset == null) _ctl.clear();
    try {
      await Chat.send(_i, widget.meId, t);
    } catch (_) {
      if (!mounted) return;
      if (preset == null) _ctl.text = t;
      toast(context, 'Message not sent. Check your connection and chat rules.',
          error: true);
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _day(DateTime d) {
    final now = DateTime.now();
    final y = now.subtract(const Duration(days: 1));
    final label = _sameDay(d, now)
        ? 'Today'
        : (_sameDay(d, y) ? 'Yesterday' : DateFormat('EEE, MMM d').format(d));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                  color: C.line, borderRadius: BorderRadius.circular(12)),
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: C.grey,
                      fontWeight: FontWeight.w600)))),
    );
  }

  Widget _bubble(ChatMsg m) {
    final mine = m.senderId == widget.meId;
    final maxW = MediaQuery.of(context).size.width * .76;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 7),
        constraints: BoxConstraints(maxWidth: maxW),
        decoration: BoxDecoration(
          gradient:
              mine ? const LinearGradient(colors: [C.red, C.redDark]) : null,
          color: mine ? null : Colors.white,
          border: mine ? null : Border.all(color: C.line),
          borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 4),
              bottomRight: Radius.circular(mine ? 4 : 18)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.04),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(m.text,
                  style: TextStyle(
                      color: mine ? Colors.white : C.ink,
                      fontSize: 14.5,
                      height: 1.3)),
              const SizedBox(height: 3),
              Text(DateFormat('h:mm a').format(m.at),
                  style: TextStyle(
                      color: mine ? Colors.white70 : C.grey, fontSize: 10)),
            ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: C.bg,
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(children: [
            Avatar(_otherName, size: 38),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(_otherName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  Text('${_i.code}  •  ${_i.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11.5,
                          color: C.grey,
                          fontWeight: FontWeight.w500)),
                ])),
          ]),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: IconButton(
                tooltip: 'Call $_otherName',
                style: IconButton.styleFrom(backgroundColor: C.greenBg),
                icon: const Icon(Icons.call_rounded, color: C.green),
                onPressed: () => callUser(context, _otherId, _otherName),
              ),
            ),
          ],
        ),
        body: Column(children: [
          Expanded(
            child: StreamBuilder<List<ChatMsg>>(
              stream: Chat.messages(_i.id),
              builder: (c, s) {
                if (s.hasError) {
                  return const EmptyState(
                      Icons.lock_outline_rounded,
                      'Cannot load messages',
                      'Add the chat rules from CHAT_SETUP.md to your Firestore rules.');
                }
                if (!s.hasData) return const Loader();
                final l = s.data!;
                if (l.isEmpty) {
                  return EmptyState(
                      Icons.chat_bubble_outline_rounded,
                      'Say hello to $_otherName',
                      'Messages are saved under booking ${_i.code}.');
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: l.length,
                  itemBuilder: (c, i) {
                    final m = l[i];
                    final older = i + 1 < l.length ? l[i + 1] : null;
                    final showDay = older == null || !_sameDay(older.at, m.at);
                    return Column(
                        children: [if (showDay) _day(m.at), _bubble(m)]);
                  },
                );
              },
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                for (final q in _quick)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 6),
                    child: ActionChip(
                      label: Text(q,
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w500)),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: C.line),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      onPressed: () => _send(q),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: C.line))),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: SafeArea(
              top: false,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(
                  child: TextField(
                    controller: _ctl,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Type a message…',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: C.red,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _send(),
                    child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.send_rounded,
                            color: Colors.white, size: 22)),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      );
}
