import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../core/config.dart';
import '../core/map_widgets.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import '../services/db_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import 'chat_screens.dart';
import 'profile_screens.dart';

class DriverShell extends StatelessWidget {
  final AppUser me;
  const DriverShell({super.key, required this.me});
  @override
  Widget build(BuildContext context) => StreamBuilder<AppUser?>(
        stream: Db.userStream(me.uid),
        initialData: me,
        builder: (c, s) {
          final u = s.data ?? me;
          return TabShell(
            pages: [
              JobsTab(me: u),
              QuotesTab(me: u),
              ActiveTab(me: u),
              EarningsTab(me: u),
              DriverProfileTab(me: u),
            ],
            items: const [
              NavigationDestination(
                  icon: Icon(Icons.work_outline_rounded),
                  selectedIcon: Icon(Icons.work_rounded),
                  label: 'Jobs'),
              NavigationDestination(
                  icon: Icon(Icons.request_quote_outlined),
                  selectedIcon: Icon(Icons.request_quote_rounded),
                  label: 'Quotes'),
              NavigationDestination(
                  icon: Icon(Icons.local_shipping_outlined),
                  selectedIcon: Icon(Icons.local_shipping_rounded),
                  label: 'Active'),
              NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                  label: 'Earnings'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile'),
            ],
            badges: [
              Notif.driverJobs(),
              Notif.driverQuotes(u.uid),
              Notif.driverActive(u.uid),
              null,
              null,
            ],
          );
        },
      );
}

Widget verifyBanner(AppUser me) {
  if (me.verified) return const SizedBox.shrink();
  final rejected = me.verification == 'rejected';
  return Container(
    margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: rejected ? C.pinkBg : C.cream,
        borderRadius: BorderRadius.circular(14)),
    child: Row(children: [
      Icon(rejected ? Icons.cancel_rounded : Icons.hourglass_top_rounded,
          color: C.red, size: 22),
      const SizedBox(width: 10),
      Expanded(
          child: Text(
              rejected
                  ? 'Your verification was rejected. Update your details and documents in Profile.'
                  : 'Verification pending. Upload your license and OR/CR in Profile. You can send quotations once an admin approves you.',
              style: const TextStyle(fontSize: 12.5))),
    ]),
  );
}

class JobsTab extends StatefulWidget {
  final AppUser me;
  const JobsTab({super.key, required this.me});
  @override
  State<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<JobsTab> {
  String _f = 'Nearby';
  LatLng? _driverPos;

  @override
  void initState() {
    super.initState();
    Loc.current().then((p) {
      if (mounted && p != null) setState(() => _driverPos = p);
    });
  }

  void _details(HaulRequest r, bool quoted) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                              color: C.line,
                              borderRadius: BorderRadius.circular(4)))),
                  const SizedBox(height: 16),
                  RouteMap(pickup: r.pickup, dest: r.dest, height: 170),
                  const SizedBox(height: 14),
                  Text(r.item,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 6),
                  InfoRow('Pickup', r.pickup.address),
                  InfoRow('Destination', r.dest.address),
                  InfoRow('Distance', '${r.distanceKm.toStringAsFixed(1)} km'),
                  InfoRow('Schedule', fmtDate(r.schedule)),
                  InfoRow('Size / Weight', r.size),
                  InfoRow('Vehicle', r.vehicleType),
                  InfoRow('Customer', r.customerName),
                  if (r.notes.isNotEmpty) InfoRow('Note', r.notes),
                  const SizedBox(height: 14),
                  PrimaryButton(
                      label: quoted ? 'Already quoted' : 'Send Quotation',
                      onPressed: quoted
                          ? null
                          : () {
                              Navigator.pop(context);
                              _quote(r);
                            }),
                  const SizedBox(height: 8),
                ]),
          ),
        ),
      );

  void _quote(HaulRequest r) {
    if (!widget.me.verified)
      return toast(context,
          'Only verified drivers can send quotations. Wait for admin approval.',
          error: true);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => SubmitQuoteScreen(request: r, me: widget.me)));
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ScreenTitle('Available Requests',
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                MsgBell(uid: widget.me.uid),
                const SizedBox(width: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                      color: widget.me.online
                          ? C.greenBg
                          : const Color(0xFFEDEDF0),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(children: [
                    Text(widget.me.online ? 'Online' : 'Offline',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: widget.me.online ? C.green : C.grey)),
                    Switch(
                        value: widget.me.online,
                        activeColor: C.green,
                        onChanged: (v) =>
                            Db.updateUser(widget.me.uid, {'online': v})),
                  ]),
                ),
              ])),
          verifyBanner(widget.me),
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: FilterChips(
                  items: const ['Nearby', 'Newest', 'Highest'],
                  selected: _f,
                  onSelect: (v) => setState(() => _f = v))),
          Expanded(
            child: !widget.me.online
                ? const EmptyState(
                    Icons.power_settings_new_rounded,
                    'You are offline',
                    'Turn on the Online switch to see and quote hauling requests.')
                : StreamBuilder<List<HaulRequest>>(
                    stream: Db.openRequests(),
                    builder: (c, s) => StreamBuilder<List<Quote>>(
                      stream: Db.driverQuotes(widget.me.uid),
                      builder: (c, qs) {
                        if (!s.hasData) return const Loader();
                        final quoted = {
                          for (final q in qs.data ?? <Quote>[]) q.requestId
                        };
                        var l = [...s.data!];

                        if (_driverPos != null) {
                          l = l
                              .where((r) =>
                                  Loc.km(_driverPos!, r.pickup.ll) <=
                                      AppConfig.dispatchRadiusKm ||
                                  Loc.km(_driverPos!, r.dest.ll) <=
                                      AppConfig.dispatchRadiusKm)
                              .toList();
                        }

                        if (_f == 'Nearby') {
                          if (_driverPos != null) {
                            l.sort((a, b) => Loc.km(_driverPos!, a.pickup.ll)
                                .compareTo(Loc.km(_driverPos!, b.pickup.ll)));
                          } else {
                            l.sort(
                                (a, b) => a.distanceKm.compareTo(b.distanceKm));
                          }
                        } else if (_f == 'Highest') {
                          l.sort(
                              (a, b) => b.distanceKm.compareTo(a.distanceKm));
                        }

                        if (l.isEmpty)
                          return EmptyState(
                              Icons.inbox_outlined,
                              'No open requests nearby',
                              _driverPos == null
                                  ? 'New hauling requests will appear here.'
                                  : 'Only Davao City requests within ${AppConfig.dispatchRadiusKm.toStringAsFixed(0)} km are shown.');

                        return ListView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            children: [
                              for (final r in l)
                                AppCard(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                      Row(children: [
                                        Expanded(
                                            child: Text(r.item,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15))),
                                        if (quoted.contains(r.id))
                                          const StatusChip('pending'),
                                      ]),
                                      const SizedBox(height: 4),
                                      Text(
                                          '${r.pickup.short} → ${r.dest.short}',
                                          style: const TextStyle(
                                              color: C.grey, fontSize: 12.5)),
                                      Text(
                                          '${r.distanceKm.toStringAsFixed(1)} km  |  ${fmtShort(r.schedule)}',
                                          style: const TextStyle(
                                              color: C.grey, fontSize: 12.5)),
                                      const SizedBox(height: 12),
                                      Row(children: [
                                        SizedBox(
                                            height: 40,
                                            child: FilledButton(
                                                onPressed: quoted.contains(r.id)
                                                    ? null
                                                    : () => _quote(r),
                                                style: FilledButton.styleFrom(
                                                    backgroundColor: C.red,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20))),
                                                child: Text(
                                                    quoted.contains(r.id)
                                                        ? 'Quoted'
                                                        : 'Send Quotation'))),
                                        const SizedBox(width: 10),
                                        SizedBox(
                                            height: 40,
                                            child: OutlinedButton(
                                                onPressed: () => _details(
                                                    r, quoted.contains(r.id)),
                                                style: OutlinedButton.styleFrom(
                                                    foregroundColor: C.red,
                                                    side: const BorderSide(
                                                        color: C.red),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20))),
                                                child: const Text('Details'))),
                                      ]),
                                    ]))
                                    .animate()
                                    .fadeIn(duration: 300.ms)
                                    .slideY(begin: .05),
                            ]);
                      },
                    ),
                  ),
          ),
        ]),
      );
}

class SubmitQuoteScreen extends StatefulWidget {
  final HaulRequest request;
  final AppUser me;
  const SubmitQuoteScreen({super.key, required this.request, required this.me});
  @override
  State<SubmitQuoteScreen> createState() => _SubmitQuoteScreenState();
}

class _SubmitQuoteScreenState extends State<SubmitQuoteScreen> {
  final _form = GlobalKey<FormState>();
  final _price = TextEditingController(), _msg = TextEditingController();
  late String _vehicle = AppConfig.vehicleTypes.contains(widget.me.vehicleType)
      ? widget.me.vehicleType
      : AppConfig.vehicleTypes[1];
  late DateTime _when = widget.request.schedule.isAfter(DateTime.now())
      ? widget.request.schedule
      : DateTime.now().add(const Duration(hours: 1));
  bool _loading = false;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    if (_when.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
      return toast(context, 'Availability time must be in the future.',
          error: true);
    }

    setState(() => _loading = true);
    try {
      final r = widget.request;
      await Db.submitQuote(Quote(
          requestId: r.id,
          driverId: widget.me.uid,
          driverName: widget.me.name,
          customerId: r.customerId,
          driverRating: widget.me.rating,
          vehicle: _vehicle,
          price: double.parse(_price.text.trim()),
          availability: _when,
          message: _msg.text.trim(),
          item: r.item,
          route: '${r.pickup.short} → ${r.dest.short}'));
      if (!mounted) return;
      Navigator.pop(context);
      toast(context, 'Quotation sent to the customer.');
    } catch (e) {
      if (mounted) toast(context, Auth.err(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Quotation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            RouteMap(pickup: r.pickup, dest: r.dest, height: 140),
            const SizedBox(height: 12),
            AppCard(
                color: C.cream,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.item,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                          '${r.pickup.short} → ${r.dest.short} (${r.distanceKm.toStringAsFixed(1)} km)',
                          style:
                              const TextStyle(color: C.grey, fontSize: 12.5)),
                      Text('${fmtDate(r.schedule)} | ${r.size}',
                          style:
                              const TextStyle(color: C.grey, fontSize: 12.5)),
                      if (r.notes.isNotEmpty)
                        Text('Note: ${r.notes}',
                            style:
                                const TextStyle(color: C.grey, fontSize: 12.5)),
                    ])),
            const SizedBox(height: 8),
            AppField(
                controller: _price,
                label: 'Your Price (PHP)',
                icon: Icons.payments_outlined,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final d = double.tryParse((v ?? '').trim());
                  return (d == null || d <= 0)
                      ? 'Enter a price greater than zero'
                      : null;
                }),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: DropdownButtonFormField<String>(
                  initialValue: _vehicle,
                  decoration: const InputDecoration(
                      labelText: 'Vehicle to be used',
                      prefixIcon:
                          Icon(Icons.local_shipping_outlined, color: C.grey)),
                  items: [
                    for (final v in AppConfig.vehicleTypes)
                      DropdownMenuItem(value: v, child: Text(v))
                  ],
                  onChanged: (v) => setState(() => _vehicle = v!)),
            ),
            AppField(
                controller: TextEditingController(text: fmtDate(_when)),
                label: 'Available Date & Time',
                icon: Icons.event_available_outlined,
                readOnly: true,
                onTap: () async {
                  final d = await pickDateTime(context, initial: _when);
                  if (d != null) setState(() => _when = d);
                }),
            AppField(
                controller: _msg,
                label: 'Message to customer (optional)',
                maxLines: 4),
            PrimaryButton(
                label: 'Submit Quotation',
                icon: Icons.send_rounded,
                loading: _loading,
                onPressed: _submit),
          ]),
        ),
      ),
    );
  }
}

class QuotesTab extends StatefulWidget {
  final AppUser me;
  const QuotesTab({super.key, required this.me});
  @override
  State<QuotesTab> createState() => _QuotesTabState();
}

class _QuotesTabState extends State<QuotesTab> {
  String _f = 'Pending';
  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const ScreenTitle('My Quotations'),
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: FilterChips(
                  items: const ['Pending', 'Accepted', 'Declined'],
                  selected: _f,
                  onSelect: (v) => setState(() => _f = v))),
          Expanded(
            child: StreamBuilder<List<Quote>>(
              stream: Db.driverQuotes(widget.me.uid),
              builder: (c, s) {
                if (!s.hasData) return const Loader();
                final l =
                    s.data!.where((q) => q.status == _f.toLowerCase()).toList();
                if (l.isEmpty)
                  return EmptyState(
                      Icons.request_quote_outlined,
                      'No ${_f.toLowerCase()} quotations',
                      'Quotations you send will be listed here.');
                return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      for (final q in l)
                        AppCard(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Row(children: [
                                Expanded(
                                    child: Text(q.item,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700))),
                                Text(moneyShort(q.price),
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        color: C.red))
                              ]),
                              Text(q.route,
                                  style: const TextStyle(
                                      color: C.grey, fontSize: 12.5)),
                              Text('Sent: ${fmtDate(q.createdAt)}',
                                  style: const TextStyle(
                                      color: C.grey, fontSize: 12)),
                              const SizedBox(height: 8),
                              StatusChip(q.status,
                                  good: q.status == 'accepted'),
                            ])).animate().fadeIn(duration: 300.ms).slideY(
                            begin: .05),
                    ]);
              },
            ),
          ),
        ]),
      );
}

class ActiveTab extends StatelessWidget {
  final AppUser me;
  const ActiveTab({super.key, required this.me});
  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ScreenTitle('Active Job', trailing: MsgBell(uid: me.uid)),
          Expanded(
            child: StreamBuilder<List<Booking>>(
              stream: Db.driverBookings(me.uid),
              builder: (c, s) {
                if (!s.hasData) return const Loader();
                final l = s.data!
                    .where((b) => ['accepted', 'inTransit', 'delivered']
                        .contains(b.status))
                    .toList();
                if (l.isEmpty)
                  return const EmptyState(
                      Icons.local_shipping_outlined,
                      'No active jobs',
                      'When a customer accepts your quotation, the job shows up here.');
                return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      for (final b in l)
                        ActiveJobCard(key: ValueKey(b.id), b: b)
                    ]);
              },
            ),
          ),
        ]),
      );
}

class ActiveJobCard extends StatefulWidget {
  final Booking b;
  const ActiveJobCard({super.key, required this.b});
  @override
  State<ActiveJobCard> createState() => _ActiveJobCardState();
}

class _ActiveJobCardState extends State<ActiveJobCard> {
  String? _photo;
  bool _busy = false;

  Future<void> _run(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
    } catch (e) {
      if (mounted) toast(context, Auth.err(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openNav(Booking b) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => DriverNavigationScreen(booking: b)));

  void _openSignature() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recipient Signature',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text(
                  'Please have the receiver sign below to confirm delivery.',
                  style: TextStyle(color: C.grey, fontSize: 13)),
              const SizedBox(height: 12),
              SignaturePad(onSigned: (b64) async {
                await Db.updateBooking(widget.b.id, {'signatureB64': b64});
                if (mounted) Navigator.pop(context);
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markDelivered(Booking b) async {
    if (_photo == null)
      return toast(context, 'Upload a delivery photo first.', error: true);
    if (b.signatureB64.isEmpty)
      return toast(context, 'Capture the recipient signature first.',
          error: true);

    toast(context, 'Uploading proof of delivery…');
    final secureUrl = await CloudinaryService.uploadProof(
      _photo!,
      bookingCode: b.code,
    );
    if (secureUrl == null) {
      if (mounted)
        toast(context, 'Upload failed. Check your connection.', error: true);
      return;
    }

    await Db.updateBooking(b.id, {
      'status': 'delivered',
      'proofUrl': secureUrl,
      'proofB64': '',
      'proofAt': DateTime.now(),
    });

    if (mounted) {
      setState(() => _photo = null);
      toast(context, 'Delivery confirmed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.b;
    final proof = _photo;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(b.code,
                  style: const TextStyle(
                      color: C.red, fontWeight: FontWeight.w700))),
          StatusChip(b.status)
        ]),
        const SizedBox(height: 4),
        Text(b.item,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        const SizedBox(height: 10),
        RouteMap(pickup: b.pickup, dest: b.dest, height: 130),
        const SizedBox(height: 8),
        InfoRow('Customer', b.customerName),
        InfoRow('Pickup', b.pickup.address),
        InfoRow('Drop-off', b.dest.address),
        InfoRow('Price', money(b.price)),
        const SizedBox(height: 10),
        ContactBar(booking: b, asDriver: true),
        const SizedBox(height: 14),
        const Text('Update Status',
            style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (b.status == 'accepted')
          PrimaryButton(
              label: 'Start Trip (In Transit)',
              icon: Icons.play_arrow_rounded,
              color: C.yellow,
              textColor: C.ink,
              loading: _busy,
              onPressed: () => _run(() async {
                    await Db.updateBooking(
                        b.id, {'status': 'inTransit', 'started': true});
                    if (!mounted) return;
                    _openNav(b);
                  })),
        if (b.status == 'inTransit') ...[
          PrimaryButton(
              label: b.pickedUp
                  ? 'Open Map: Directions to Drop-off'
                  : 'Open Map: Directions to Pickup',
              icon: Icons.navigation_rounded,
              onPressed: () => _openNav(b)),
          const SizedBox(height: 14),
          const Text('Proof of Delivery',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: [
            ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: proof == null
                    ? Container(
                        width: 110,
                        height: 90,
                        color: C.line,
                        child: const Icon(Icons.image_outlined,
                            color: C.grey, size: 32))
                    : b64Image(proof, w: 110, h: 90)),
            const SizedBox(width: 12),
            Expanded(
                child: PrimaryButton(
                    label: proof == null ? 'Add Photo' : 'Retake',
                    outlined: true,
                    icon: Icons.photo_camera_rounded,
                    onPressed: () async {
                      final p = await pickImageB64(context);
                      if (p != null) setState(() => _photo = p);
                    })),
          ]),
          const SizedBox(height: 10),
          if (b.signatureB64.isEmpty)
            OutlinedButton.icon(
                onPressed: _openSignature,
                icon: const Icon(Icons.draw_rounded),
                label: const Text('Capture Recipient Signature'),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    foregroundColor: C.red,
                    side: const BorderSide(color: C.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))))
          else
            AppCard(
                color: C.greenBg,
                child: Row(children: [
                  const Icon(Icons.verified_rounded, color: C.green),
                  const SizedBox(width: 10),
                  const Text('Signature captured',
                      style: TextStyle(
                          color: C.green, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                      icon:
                          const Icon(Icons.visibility_rounded, color: C.green),
                      onPressed: () => showDialog(
                          context: context,
                          builder: (_) => Dialog(
                              child: b64Image(b.signatureB64,
                                  fit: BoxFit.contain)))),
                ])),
          const SizedBox(height: 12),
          const Text('Cash on Delivery',
              style: TextStyle(fontWeight: FontWeight.w600)),
          CheckboxListTile(
            value: b.codCollected,
            activeColor: C.green,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text('Collected ${money(b.price)} in cash'),
            onChanged: (v) async {
              if (v == true) {
                await Db.updateBooking(b.id, {
                  'codCollected': true,
                  'codAmount': b.price,
                });
              }
            },
          ),
          const SizedBox(height: 10),
          PrimaryButton(
              label: 'Mark as Delivered',
              icon: Icons.check_circle_outline_rounded,
              loading: _busy,
              onPressed: () => _run(() => _markDelivered(b))),
        ],
        if (b.status == 'delivered')
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: C.blueBg, borderRadius: BorderRadius.circular(14)),
              child: const Row(children: [
                Icon(Icons.hourglass_top_rounded, color: C.blue),
                SizedBox(width: 10),
                Expanded(
                    child: Text(
                        'Delivered. Waiting for the customer to confirm receipt.',
                        style: TextStyle(
                            color: C.blue, fontWeight: FontWeight.w500)))
              ])),
      ]),
    );
  }
}

class EarningsTab extends StatelessWidget {
  final AppUser me;
  const EarningsTab({super.key, required this.me});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: StreamBuilder<List<Booking>>(
          stream: Db.driverBookings(me.uid),
          builder: (c, s) {
            if (!s.hasData) return const Loader();
            final done = s.data!.where((b) => b.status == 'completed').toList();
            final today = DateTime.now();
            final startOfWeek = DateTime(today.year, today.month, today.day)
                .subtract(Duration(days: today.weekday - 1));
            final startOfMonth = DateTime(today.year, today.month, 1);

            double sum(List<Booking> l) => l.fold(0, (a, b) => a + b.earnings);

            final todayList = done
                .where((b) =>
                    b.createdAt.day == today.day &&
                    b.createdAt.month == today.month &&
                    b.createdAt.year == today.year)
                .toList();
            final weekList =
                done.where((b) => !b.createdAt.isBefore(startOfWeek)).toList();
            final monthList =
                done.where((b) => !b.createdAt.isBefore(startOfMonth)).toList();
            final pendingPayout = done
                .where((b) => !b.payoutRequested)
                .fold<double>(0, (a, b) => a + b.earnings);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                ScreenTitle('Earnings', trailing: MsgBell(uid: me.uid)),
                Row(children: [
                  _stat('Today', sum(todayList)),
                  _stat('This week', sum(weekList)),
                  _stat('This month', sum(monthList)),
                ]),
                const SizedBox(height: 14),
                AppCard(
                    color: C.cream,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Available for payout',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(money(pendingPayout),
                              style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: C.red)),
                          const SizedBox(height: 8),
                          const Text(
                              'Commission rate 15% is already deducted from each job.',
                              style: TextStyle(color: C.grey, fontSize: 11.5)),
                        ])),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Request Payout',
                  icon: Icons.account_balance_rounded,
                  onPressed: pendingPayout <= 0
                      ? null
                      : () => _requestPayout(context, done, pendingPayout),
                ),
                const SectionTitle('Completed Jobs'),
                if (done.isEmpty)
                  const EmptyState(Icons.receipt_long_outlined,
                      'No earnings yet', 'Completed jobs will show up here.'),
                for (final b in done.take(40))
                  AppCard(
                      child: Row(children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(b.code,
                              style: const TextStyle(
                                  color: C.red,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                          Text(b.item, style: const TextStyle(fontSize: 14)),
                          Text('${b.pickup.short} → ${b.dest.short}',
                              style:
                                  const TextStyle(color: C.grey, fontSize: 12)),
                        ])),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(moneyShort(b.earnings),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          if (b.payoutRequested) const StatusChip('pending'),
                        ]),
                  ])),
              ],
            );
          },
        ),
      );

  Widget _stat(String label, double value) => Expanded(
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: C.line)),
          child: Column(children: [
            Text(label, style: const TextStyle(color: C.grey, fontSize: 11)),
            const SizedBox(height: 6),
            Text(moneyShort(value),
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, color: C.red, fontSize: 13.5)),
          ]),
        ),
      );

  Future<void> _requestPayout(
      BuildContext context, List<Booking> done, double amount) async {
    if (!await confirmDialog(context, 'Request payout?',
        'You will receive ${money(amount)} within 1-2 business days.')) return;
    final toUpdate = done.where((b) => !b.payoutRequested);
    for (final b in toUpdate) {
      await Db.updateBooking(b.id, {'payoutRequested': true});
    }
    if (context.mounted) {
      toast(context, 'Payout requested for ${moneyShort(amount)}.');
    }
  }
}
