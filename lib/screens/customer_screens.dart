import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/config.dart';
import '../core/map_widgets.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../services/location_service.dart';
import '../services/mapbox_service.dart';
import '../services/notification_service.dart';
import 'chat_screens.dart';
import 'profile_screens.dart';

class CustomerShell extends StatelessWidget {
  final AppUser me;
  const CustomerShell({super.key, required this.me});
  @override
  Widget build(BuildContext context) => TabShell(
        pages: [
          CustomerHome(me: me),
          RequestsTab(me: me),
          BookingsTab(me: me),
          CustomerProfile(me: me),
        ],
        items: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment_rounded),
              label: 'Requests'),
          NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined),
              selectedIcon: Icon(Icons.local_shipping_rounded),
              label: 'Bookings'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
        badges: [
          null,
          Notif.customerRequests(me.uid),
          Notif.customerBookings(me.uid),
          null,
        ],
      );
}

class CustomerHome extends StatefulWidget {
  final AppUser me;
  const CustomerHome({super.key, required this.me});
  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final first = widget.me.name.split(' ').first;
    return SafeArea(
      child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, $first!',
                          style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: C.red)),
                      const Text('Where do you need hauling today?',
                          style: TextStyle(color: C.grey)),
                    ]),
              ),
              MsgBell(uid: widget.me.uid),
              const SizedBox(width: 6),
              Avatar(widget.me.name, size: 48, photo: widget.me.photoB64),
            ]),
            const SizedBox(height: 18),
            TextField(
              onChanged: (v) => setState(() => _q = v.toLowerCase()),
              decoration: InputDecoration(
                  hintText: 'Search your requests',
                  prefixIcon: const Icon(Icons.search_rounded, color: C.grey),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: C.line)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(color: C.line))),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CreateRequestScreen(me: widget.me))),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [C.red, C.redDark]),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                          color: C.red.withOpacity(.35),
                          blurRadius: 20,
                          offset: const Offset(0, 10))
                    ]),
                child: Row(children: [
                  Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                          color: C.yellow, shape: BoxShape.circle),
                      child: const Icon(Icons.add_rounded,
                          color: C.red, size: 28)),
                  const SizedBox(width: 16),
                  const Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Create Hauling Request',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                        Text('Post it and compare driver quotations',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12.5)),
                      ])),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white70, size: 16),
                ]),
              ),
            ).animate().fadeIn().slideY(begin: .1),
            const SizedBox(height: 22),
            const SectionTitle('Vehicle Types'),
            Row(children: [
              for (final v in AppConfig.vehicleTypes)
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CreateRequestScreen(
                                me: widget.me, vehicle: v))),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: C.line)),
                      child: Column(children: [
                        Icon(vehicleIcon(v), color: C.red, size: 28),
                        const SizedBox(height: 8),
                        Text(v,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 10.5, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 14),
            const SectionTitle('My Active Requests'),
            StreamBuilder<List<HaulRequest>>(
              stream: Db.customerRequests(widget.me.uid),
              builder: (c, s) {
                if (!s.hasData)
                  return const Padding(
                      padding: EdgeInsets.all(30), child: Loader());
                final list = s.data!
                    .where((r) =>
                        r.status == 'open' && r.item.toLowerCase().contains(_q))
                    .toList();
                if (list.isEmpty)
                  return const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: EmptyState(
                        Icons.inventory_2_outlined,
                        'No active requests',
                      ));
                return Column(
                    children: [for (final r in list) RequestCard(r: r)]);
              },
            ),
          ]),
    );
  }
}

class RequestCard extends StatelessWidget {
  final HaulRequest r;
  const RequestCard({super.key, required this.r});
  @override
  Widget build(BuildContext context) => AppCard(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => RequestQuotesScreen(request: r))),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                  color: C.cream, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.inventory_2_rounded, color: C.red)),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.item,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${r.pickup.short}  →  ${r.dest.short}',
                  style: const TextStyle(color: C.grey, fontSize: 12.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              r.status == 'open'
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: r.quoteCount > 0
                              ? C.yellow
                              : const Color(0xFFEDEDF0),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(
                          r.quoteCount > 0
                              ? '${r.quoteCount} quotation${r.quoteCount > 1 ? 's' : ''}'
                              : 'Pending',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)))
                  : StatusChip(r.status),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: C.grey),
        ]),
      ).animate().fadeIn(duration: 300.ms).slideX(begin: .05);
}

class CreateRequestScreen extends StatefulWidget {
  final AppUser me;
  final String? vehicle;
  const CreateRequestScreen({super.key, required this.me, this.vehicle});
  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _form = GlobalKey<FormState>();
  final _item = TextEditingController(),
      _size = TextEditingController(),
      _notes = TextEditingController();
  Place? _pickup, _dest;
  double _km = 0;
  DateTime? _when;
  late String _vehicle = widget.vehicle ?? AppConfig.vehicleTypes[1];
  bool _loading = false;

  @override
  void dispose() {
    _item.dispose();
    _size.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick(bool pickup) async {
    final p = await Navigator.push<Place>(
        context,
        MaterialPageRoute(
            builder: (_) => LocationPickerScreen(
                title: pickup ? 'Pickup Location' : 'Destination',
                initial: pickup ? _pickup : _dest,
                saved: widget.me.saved)));
    if (p != null) setState(() => pickup ? _pickup = p : _dest = p);
  }

  bool _gps = false;

  Future<void> _useMyLocation() async {
    if (_gps) return;
    setState(() => _gps = true);
    try {
      final ll = await Loc.current();
      if (ll == null) {
        if (!mounted) return;
        toast(
            context,
            Loc.issueMessage.isEmpty
                ? 'Unable to get your location.'
                : Loc.issueMessage,
            error: true);
        if (Loc.issue == LocIssue.serviceOff ||
            Loc.issue == LocIssue.deniedForever) {
          await Loc.openSettings();
        }
        return;
      }
      final addr = await Mapbox.reverse(ll);
      if (!mounted) return;
      setState(() => _pickup = Place(addr, ll.latitude, ll.longitude));
      toast(context, 'Pickup set to your current location.');
    } finally {
      if (mounted) setState(() => _gps = false);
    }
  }

  Future<void> _post() async {
    if (!_form.currentState!.validate()) return;
    if (_pickup == null || _dest == null)
      return toast(context, 'Choose both pickup and destination.', error: true);
    if (_when == null)
      return toast(context, 'Choose a preferred schedule.', error: true);

    if (_when!.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
      return toast(
          context, 'Scheduled time is in the past. Pick a future date.',
          error: true);
    }

    setState(() => _loading = true);
    try {
      await Db.postRequest(HaulRequest(
          customerId: widget.me.uid,
          customerName: widget.me.name,
          pickup: _pickup!,
          dest: _dest!,
          distanceKm: _km,
          item: _item.text.trim(),
          size: _size.text.trim(),
          schedule: _when!,
          notes: _notes.text.trim(),
          vehicleType: _vehicle));
      if (!mounted) return;
      Navigator.pop(context);
      toast(context, 'Request posted! Drivers can now send quotations.');
    } catch (e) {
      if (mounted)
        toast(context, 'Could not post request. ${Auth.err(e)}', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _place(
          String label, IconData icon, Color color, Place? p, VoidCallback tap,
          {VoidCallback? onGps, bool gpsBusy = false}) =>
      GestureDetector(
        onTap: tap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: p == null ? C.line : color.withOpacity(.6))),
          child: Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: const TextStyle(fontSize: 11.5, color: C.grey)),
                  Text(p?.address ?? 'Select on map / type address',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: p == null ? C.grey : C.ink)),
                ])),
            if (onGps != null)
              InkWell(
                onTap: gpsBusy ? null : onGps,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: const BoxDecoration(
                      color: C.cream, shape: BoxShape.circle),
                  child: gpsBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.2, color: C.red))
                      : const Icon(Icons.my_location_rounded,
                          color: C.red, size: 20),
                ),
              )
            else
              const Icon(Icons.map_outlined, color: C.grey, size: 20),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create Hauling Request')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _place('Pickup Location', Icons.trip_origin_rounded, C.red,
                  _pickup, () => _pick(true),
                  onGps: _useMyLocation, gpsBusy: _gps),
              _place('Destination', Icons.location_on_rounded,
                  C.yellow.withOpacity(1), _dest, () => _pick(false)),
              AnimatedSize(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                child: (_pickup != null && _dest != null)
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: RouteMap(
                            pickup: _pickup!,
                            dest: _dest!,
                            height: 190,
                            onDistance: (d) {
                              if (mounted) setState(() => _km = d);
                            }))
                    : const SizedBox(width: double.infinity),
              ),
              if (_km > 0)
                Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(children: [
                      const Icon(Icons.straighten_rounded,
                          color: C.red, size: 20),
                      const SizedBox(width: 8),
                      Text('Estimated distance: ${_km.toStringAsFixed(1)} km',
                          style: const TextStyle(fontWeight: FontWeight.w600))
                    ])),
              const Text('Preferred vehicle',
                  style: TextStyle(color: C.grey, fontSize: 12.5)),
              const SizedBox(height: 8),
              FilterChips(
                  items: AppConfig.vehicleTypes,
                  selected: _vehicle,
                  onSelect: (v) => setState(() => _vehicle = v)),
              const SizedBox(height: 16),
              AppField(
                  controller: _item,
                  label: 'Item Description',
                  icon: Icons.chair_alt_outlined,
                  validator: req),
              AppField(
                  controller: _size,
                  label: 'Size / Weight',
                  icon: Icons.scale_outlined,
                  validator: req),
              AppField(
                  controller: TextEditingController(
                      text: _when == null ? '' : fmtDate(_when!)),
                  label: 'Preferred Schedule',
                  icon: Icons.event_outlined,
                  readOnly: true,
                  onTap: () async {
                    final d = await pickDateTime(context, initial: _when);
                    if (d != null) setState(() => _when = d);
                  }),
              AppField(
                  controller: _notes,
                  label: 'Special Instructions (optional)',
                  icon: Icons.notes_rounded,
                  maxLines: 3),
              const SizedBox(height: 4),
              PrimaryButton(
                  label: 'Post Request',
                  icon: Icons.send_rounded,
                  loading: _loading,
                  onPressed: _post),
            ]),
          ),
        ),
      );
}

class RequestQuotesScreen extends StatefulWidget {
  final HaulRequest request;
  const RequestQuotesScreen({super.key, required this.request});
  @override
  State<RequestQuotesScreen> createState() => _RequestQuotesScreenState();
}

class _RequestQuotesScreenState extends State<RequestQuotesScreen> {
  String _sort = 'Lowest Price';

  Future<void> _cancel() async {
    if (!await confirmDialog(context, 'Cancel request?',
        'Drivers will no longer be able to quote on it.',
        yes: 'Cancel request')) return;
    await Db.cancelRequest(widget.request.id);
    if (mounted) {
      Navigator.pop(context);
      toast(context, 'Request cancelled.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Scaffold(
      appBar: AppBar(title: const Text('Request & Quotations'), actions: [
        if (r.status == 'open')
          IconButton(
              tooltip: 'Cancel request',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _cancel)
      ]),
      body: StreamBuilder<List<Quote>>(
        stream: Db.requestQuotes(r.id),
        builder: (c, s) {
          final list = [...(s.data ?? <Quote>[])];
          if (_sort == 'Lowest Price') {
            list.sort((a, b) => a.price.compareTo(b.price));
          } else if (_sort == 'Top Rated') {
            list.sort((a, b) => b.driverRating.compareTo(a.driverRating));
          } else {
            list.sort((a, b) => a.vehicle.compareTo(b.vehicle));
          }
          return ListView(padding: const EdgeInsets.all(20), children: [
            RouteMap(pickup: r.pickup, dest: r.dest, height: 150),
            const SizedBox(height: 12),
            AppCard(
                color: C.cream,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.item,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('${r.pickup.address}\n→ ${r.dest.address}',
                          style:
                              const TextStyle(color: C.grey, fontSize: 12.5)),
                      const SizedBox(height: 6),
                      Text(
                          '${fmtDate(r.schedule)}  |  ${r.size}  |  ${r.distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w500)),
                    ])),
            SectionTitle('Driver Quotations (${list.length})'),
            if (r.status != 'open')
              const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                      'This request is no longer open for new bookings.',
                      style: TextStyle(color: C.grey))),
            FilterChips(
                items: const ['Lowest Price', 'Top Rated', 'Vehicle'],
                selected: _sort,
                onSelect: (v) => setState(() => _sort = v)),
            const SizedBox(height: 14),
            if (!s.hasData)
              const Loader()
            else if (list.isEmpty)
              const EmptyState(
                  Icons.hourglass_empty_rounded,
                  'Waiting for quotations',
                  'Nearby verified drivers have been notified. Check back soon.'),
            for (final q in list) _QuoteCard(q: q, r: r),
          ]);
        },
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final Quote q;
  final HaulRequest r;
  const _QuoteCard({required this.q, required this.r});
  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Avatar(q.driverName),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(q.driverName,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('${q.vehicle}  |  Available ${fmtShort(q.availability)}',
                      style: const TextStyle(color: C.grey, fontSize: 12)),
                  const SizedBox(height: 2),
                  Stars(q.driverRating, size: 15),
                ])),
            Text(moneyShort(q.price),
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, color: C.red, fontSize: 17)),
          ]),
          if (q.message.isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('“${q.message}”',
                    style: const TextStyle(
                        color: C.grey,
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic))),
          const SizedBox(height: 12),
          Row(children: [
            SizedBox(
                height: 40,
                child: OutlinedButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                DriverProfileView(driverId: q.driverId))),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: C.red,
                        side: const BorderSide(color: C.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20))),
                    child: const Text('View Profile'))),
            const Spacer(),
            if (r.status == 'open')
              SizedBox(
                  height: 40,
                  child: FilledButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => BookingDetailsScreen.preview(
                                  request: r, quote: q))),
                      style: FilledButton.styleFrom(
                          backgroundColor: C.red,
                          padding: const EdgeInsets.symmetric(horizontal: 26),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20))),
                      child: const Text('Accept')))
            else
              StatusChip(q.status, good: q.status == 'accepted'),
          ]),
        ]),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: .06);
}

class DriverProfileView extends StatelessWidget {
  final String driverId;
  const DriverProfileView({super.key, required this.driverId});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Driver Profile')),
        body: StreamBuilder<AppUser?>(
          stream: Db.userStream(driverId),
          builder: (c, s) {
            final d = s.data;
            if (d == null) return const Loader();
            return ListView(padding: EdgeInsets.zero, children: [
              ProfileHero(
                title: '',
                user: d,
                roleLabel: 'Driver',
                extraChip: StatusChip(d.verified ? 'verified' : d.verification),
                stats: [
                  ProfileStat(d.rating.toStringAsFixed(1), 'Rating',
                      Icons.star_rounded),
                  ProfileStat(
                      '${d.completed}', 'Completed', Icons.task_alt_rounded),
                  ProfileStat(
                      '${d.ratingCount}', 'Reviews', Icons.reviews_rounded),
                ],
              ),
              Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppCard(
                            child: Column(children: [
                          InfoRow('Vehicle Type', d.vehicleType),
                          InfoRow('Service Area', d.serviceArea),
                          InfoRow('Contact', maskPhone(d.phone))
                        ])),
                        const SectionTitle('Recent Reviews'),
                        StreamBuilder<List<Review>>(
                          stream: Db.driverReviews(driverId),
                          builder: (c, rs) {
                            final l = rs.data ?? [];
                            if (l.isEmpty)
                              return const Text('No reviews yet.',
                                  style: TextStyle(color: C.grey));
                            return Column(children: [
                              for (final r in l.take(10))
                                AppCard(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Stars(r.rating.toDouble(), size: 15),
                                      const SizedBox(height: 4),
                                      if (r.comment.isNotEmpty)
                                        Text('“${r.comment}”'),
                                      const SizedBox(height: 2),
                                      Text('- ${r.customerName}',
                                          style: const TextStyle(
                                              color: C.grey, fontSize: 12))
                                    ]))
                            ]);
                          },
                        ),
                      ])),
            ]);
          },
        ),
      );
}

class BookingDetailsScreen extends StatefulWidget {
  final Booking booking;
  final HaulRequest? request;
  final Quote? quote;
  final bool isPreview;
  const BookingDetailsScreen._(
      this.booking, this.request, this.quote, this.isPreview,
      {super.key});

  factory BookingDetailsScreen.preview(
          {required HaulRequest request, required Quote quote}) =>
      BookingDetailsScreen._(
          Booking(
              code: Db.newCode(),
              requestId: request.id,
              quoteId: quote.id,
              customerId: request.customerId,
              customerName: request.customerName,
              driverId: quote.driverId,
              driverName: quote.driverName,
              vehicle: quote.vehicle,
              item: request.item,
              price: quote.price,
              schedule: quote.availability,
              pickup: request.pickup,
              dest: request.dest),
          request,
          quote,
          true);
  factory BookingDetailsScreen.view(Booking b) =>
      BookingDetailsScreen._(b, null, null, false);

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  bool _loading = false;

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      final id = await Db.confirmBooking(
          widget.request!, widget.quote!, widget.booking.code);
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
      toast(context, 'Booking confirmed! Track it under Bookings.');
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => TrackScreen(bookingId: id)));
    } catch (e) {
      if (mounted)
        toast(context, 'Could not confirm booking. ${Auth.err(e)}',
            error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cancel(Booking b) async {
    if (!await confirmDialog(context, 'Cancel booking?',
        'The driver will be notified that this booking was cancelled.',
        yes: 'Cancel booking')) return;
    await Db.cancelBooking(b);
    if (mounted) {
      Navigator.pop(context);
      toast(context, 'Booking cancelled.');
    }
  }

  Widget _body(Booking b) =>
      ListView(padding: const EdgeInsets.all(20), children: [
        AppCard(
            color: C.cream,
            child: Text('Booking ID: ${b.code}',
                style: const TextStyle(
                    color: C.red, fontWeight: FontWeight.w700))),
        AppCard(
            child: Column(children: [
          InfoRow('Customer', b.customerName),
          InfoRow('Driver', b.driverName),
          InfoRow('Vehicle', b.vehicle),
          InfoRow('Agreed Price', money(b.price)),
          InfoRow('Schedule', fmtDate(b.schedule)),
          InfoRow('Pickup', b.pickup.address),
          InfoRow('Destination', b.dest.address),
          InfoRow('Item', b.item),
          Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: [
                const Text('Status',
                    style: TextStyle(color: C.grey, fontSize: 13)),
                const Spacer(),
                StatusChip(b.status)
              ])),
        ])),
        RouteMap(pickup: b.pickup, dest: b.dest, height: 150),
        const SizedBox(height: 18),
        if (widget.isPreview) ...[
          PrimaryButton(
              label: 'Confirm Booking',
              icon: Icons.check_circle_outline_rounded,
              loading: _loading,
              onPressed: _confirm),
          const SizedBox(height: 10),
          PrimaryButton(
              label: 'Cancel Booking',
              outlined: true,
              onPressed: () => Navigator.pop(context)),
        ] else ...[
          ContactBar(booking: b, asDriver: false),
          const SizedBox(height: 10),
          PrimaryButton(
              label: 'Track Transaction',
              icon: Icons.route_rounded,
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => TrackScreen(bookingId: b.id)))),
          const SizedBox(height: 10),
          PrimaryButton(
              label: 'Share Tracking Link',
              icon: Icons.share_rounded,
              outlined: true,
              onPressed: () => shareTrackingLink(context, b)),
          if (b.status == 'accepted') ...[
            const SizedBox(height: 10),
            PrimaryButton(
                label: 'Cancel Booking',
                outlined: true,
                onPressed: () => _cancel(b))
          ],
        ],
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: widget.isPreview
            ? _body(widget.booking)
            : StreamBuilder<Booking?>(
                stream: Db.booking(widget.booking.id),
                builder: (c, s) =>
                    s.data == null ? const Loader() : _body(s.data!)),
      );
}

class TrackScreen extends StatelessWidget {
  final String bookingId;
  const TrackScreen({super.key, required this.bookingId});
  static const _steps = [
    ['pending', 'Pending', 'Request posted'],
    ['accepted', 'Accepted', 'Driver accepted booking'],
    ['inTransit', 'In Transit', 'Item is on the way'],
    ['delivered', 'Delivered', 'Awaiting confirmation'],
    ['completed', 'Completed', 'Transaction closed'],
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Track Transaction')),
        body: StreamBuilder<Booking?>(
          stream: Db.booking(bookingId),
          builder: (c, s) {
            final b = s.data;
            if (b == null) return const Loader();
            final idx = _steps.indexWhere((e) => e[0] == b.status);
            return ListView(padding: const EdgeInsets.all(20), children: [
              Text(b.code,
                  style: const TextStyle(
                      color: C.red, fontWeight: FontWeight.w700, fontSize: 16)),
              Text('${b.pickup.short} → ${b.dest.short}',
                  style: const TextStyle(color: C.grey)),
              const SizedBox(height: 18),
              if (b.status == 'inTransit') ...[
                LiveTrackMap(booking: b),
                const SizedBox(height: 14),
                PrimaryButton(
                    label: 'Share Tracking Link',
                    icon: Icons.share_rounded,
                    outlined: true,
                    onPressed: () => shareTrackingLink(context, b)),
                const SizedBox(height: 18),
              ],
              if (b.status == 'cancelled')
                const AppCard(
                    color: C.pinkBg,
                    child: Text('This booking was cancelled.',
                        style: TextStyle(
                            color: C.red, fontWeight: FontWeight.w600))),
              for (int i = 0; i < _steps.length; i++)
                IntrinsicHeight(
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i <= idx ? C.red : Colors.white,
                                border: Border.all(
                                    color: i <= idx ? C.red : C.line,
                                    width: 2)),
                            child: i <= idx
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 20)
                                : null,
                          ),
                          if (i < _steps.length - 1)
                            Expanded(
                                child: Container(
                                    width: 3, color: i < idx ? C.red : C.line)),
                        ]),
                        const SizedBox(width: 14),
                        Expanded(
                            child: Padding(
                                padding: const EdgeInsets.only(bottom: 26),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(_steps[i][1],
                                          style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  i <= idx ? C.ink : C.grey)),
                                      Text(_steps[i][2],
                                          style: const TextStyle(
                                              color: C.grey, fontSize: 12.5)),
                                    ]))),
                      ]),
                ).animate().fadeIn(delay: (80 * i).ms).slideX(begin: .05),
              AppCard(
                  child: Row(children: [
                Avatar(b.driverName),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Driver: ${b.driverName}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${b.vehicle}  |  ${money(b.price)}',
                          style: const TextStyle(color: C.grey, fontSize: 12.5))
                    ])),
                IconButton(
                    icon: const Icon(Icons.person_search_rounded, color: C.red),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                DriverProfileView(driverId: b.driverId))))
              ])),
              ContactBar(booking: b, asDriver: false),
              const SizedBox(height: 14),
              if (b.status == 'delivered')
                PrimaryButton(
                    label: 'View Proof of Delivery',
                    icon: Icons.verified_rounded,
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ProofScreen(booking: b)))),
              if (b.status == 'completed' && !b.reviewed)
                PrimaryButton(
                    label: 'Rate & Review Driver',
                    icon: Icons.star_rounded,
                    color: C.yellow,
                    textColor: C.ink,
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => RateScreen(booking: b)))),
              if (b.status == 'completed' && b.reviewed)
                const Center(
                    child: Text('Thanks for your review!',
                        style: TextStyle(
                            color: C.green, fontWeight: FontWeight.w600))),
              if (b.issue.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text('Reported problem: ${b.issue}',
                        style: const TextStyle(color: C.red))),
            ]);
          },
        ),
      );
}

class ProofScreen extends StatefulWidget {
  final Booking booking;
  const ProofScreen({super.key, required this.booking});
  @override
  State<ProofScreen> createState() => _ProofScreenState();
}

class _ProofScreenState extends State<ProofScreen> {
  bool _loading = false;

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      await Db.completeBooking(widget.booking);
      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => RateScreen(booking: widget.booking)));
    } catch (e) {
      if (mounted) toast(context, Auth.err(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _report() async {
    final ctl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Report a problem'),
        content: TextField(
            controller: ctl,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'What went wrong?')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Back')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: C.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send report'))
        ],
      ),
    );
    if (ok == true && ctl.text.trim().isNotEmpty) {
      await Db.updateBooking(widget.booking.id, {'issue': ctl.text.trim()});
      if (mounted) {
        Navigator.pop(context);
        toast(context, 'Problem reported. We will review it.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return Scaffold(
      appBar: AppBar(title: const Text('Proof of Delivery')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text('Booking ${b.code}',
            style: const TextStyle(color: C.red, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: b.proofUrl.isNotEmpty
              ? Image.network(
                  b.proofUrl,
                  height: 280,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (c, child, progress) => progress == null
                      ? child
                      : Container(
                          height: 280,
                          color: C.line,
                          child: const Center(
                              child: CircularProgressIndicator(color: C.red))),
                  errorBuilder: (c, e, st) => Container(
                      height: 240,
                      color: C.line,
                      alignment: Alignment.center,
                      child: const Text('Could not load proof image')),
                )
              : b.proofB64.isNotEmpty
                  ? b64Image(b.proofB64, h: 280, w: double.infinity)
                  : Container(
                      height: 240,
                      color: C.line,
                      alignment: Alignment.center,
                      child: const Text('No photo uploaded')),
        ),
        if (b.signatureB64.isNotEmpty) ...[
          const SizedBox(height: 12),
          AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('Recipient signature',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: b64Image(b.signatureB64,
                        h: 120, w: double.infinity, fit: BoxFit.contain)),
              ])),
        ],
        if (b.codCollected) ...[
          const SizedBox(height: 12),
          AppCard(
              color: C.greenBg,
              child: Row(children: [
                const Icon(Icons.payments_rounded, color: C.green),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        'COD collected: ${money(b.codAmount ?? b.price)}',
                        style: const TextStyle(
                            color: C.green, fontWeight: FontWeight.w600))),
              ])),
        ],
        const SizedBox(height: 12),
        AppCard(
            child: Column(children: [
          InfoRow('Uploaded', b.proofAt == null ? '-' : fmtDate(b.proofAt!)),
          InfoRow('Location', b.dest.short)
        ])),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Please confirm that your item was received.')),
        PrimaryButton(
            label: 'Confirm Item Received',
            icon: Icons.check_circle_rounded,
            loading: _loading,
            onPressed: _confirm),
        const SizedBox(height: 10),
        PrimaryButton(
            label: 'Report a Problem', outlined: true, onPressed: _report),
      ]),
    );
  }
}

class RateScreen extends StatefulWidget {
  final Booking booking;
  const RateScreen({super.key, required this.booking});
  @override
  State<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends State<RateScreen> {
  int _stars = 5;
  final _fb = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await Db.submitReview(widget.booking, _stars, _fb.text.trim());
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
      toast(context, 'Review submitted. Thank you!');
    } catch (e) {
      if (mounted) toast(context, Auth.err(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Rate & Review')),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          Center(child: Avatar(widget.booking.driverName, size: 88)),
          const SizedBox(height: 10),
          Center(
              child: Text(widget.booking.driverName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 18))),
          Center(
              child: Text('${widget.booking.item}  |  Completed',
                  style: const TextStyle(color: C.grey))),
          const SizedBox(height: 22),
          const Center(
              child: Text('How was the service?',
                  style: TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (int i = 1; i <= 5; i++)
              IconButton(
                  iconSize: 42,
                  onPressed: () => setState(() => _stars = i),
                  icon: AnimatedScale(
                      scale: i <= _stars ? 1.1 : .9,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                          i <= _stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: C.yellow))),
          ]),
          const SizedBox(height: 16),
          AppField(controller: _fb, label: 'Write your feedback', maxLines: 5),
          PrimaryButton(
              label: 'Submit Review', loading: _loading, onPressed: _submit),
        ]),
      );
}

class RequestsTab extends StatelessWidget {
  final AppUser me;
  const RequestsTab({super.key, required this.me});
  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const ScreenTitle('My Requests'),
          Expanded(
            child: StreamBuilder<List<HaulRequest>>(
              stream: Db.customerRequests(me.uid),
              builder: (c, s) {
                if (!s.hasData) return const Loader();
                if (s.data!.isEmpty)
                  return const EmptyState(
                      Icons.assignment_outlined,
                      'No requests yet',
                      'Your posted hauling requests will show up here.');
                return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [for (final r in s.data!) RequestCard(r: r)]);
              },
            ),
          ),
        ]),
      );
}

class BookingsTab extends StatefulWidget {
  final AppUser me;
  final bool historyOnly;
  const BookingsTab({super.key, required this.me, this.historyOnly = false});
  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  String _f = 'All';
  @override
  Widget build(BuildContext context) {
    final content =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (!widget.historyOnly)
        ScreenTitle('My Bookings', trailing: MsgBell(uid: widget.me.uid)),
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: FilterChips(
              items: const ['All', 'Ongoing', 'Completed'],
              selected: _f,
              onSelect: (v) => setState(() => _f = v))),
      Expanded(
        child: StreamBuilder<List<Booking>>(
          stream: Db.customerBookings(widget.me.uid),
          builder: (c, s) {
            if (!s.hasData) return const Loader();
            var l = s.data!;
            if (widget.historyOnly)
              l = l
                  .where(
                      (b) => b.status == 'completed' || b.status == 'cancelled')
                  .toList();
            if (_f == 'Ongoing')
              l = l
                  .where((b) =>
                      ['accepted', 'inTransit', 'delivered'].contains(b.status))
                  .toList();
            if (_f == 'Completed')
              l = l.where((b) => b.status == 'completed').toList();
            if (l.isEmpty)
              return const EmptyState(
                  Icons.local_shipping_outlined,
                  'No bookings here',
                  'Accept a driver quotation to create a booking.');
            return ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  for (final b in l)
                    AppCard(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => b.status == 'cancelled'
                                  ? BookingDetailsScreen.view(b)
                                  : TrackScreen(bookingId: b.id))),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.code,
                                style: const TextStyle(
                                    color: C.red,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                            Text(b.item,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                            Text(
                                '${b.pickup.short} → ${b.dest.short}  |  ${moneyShort(b.price)}',
                                style: const TextStyle(
                                    color: C.grey, fontSize: 12.5)),
                            const SizedBox(height: 8),
                            Row(children: [
                              StatusChip(b.status),
                              const SizedBox(width: 10),
                              const Text('View Details >',
                                  style: TextStyle(
                                      color: C.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              ContactButtons(booking: b, asDriver: false),
                            ]),
                          ]),
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: .05),
                ]);
          },
        ),
      ),
    ]);
    return widget.historyOnly
        ? Scaffold(
            appBar: AppBar(title: const Text('Booking History')), body: content)
        : SafeArea(child: content);
  }
}

class SavedAddressesScreen extends StatelessWidget {
  final String uid;
  const SavedAddressesScreen({super.key, required this.uid});
  @override
  Widget build(BuildContext context) => StreamBuilder<AppUser?>(
        stream: Db.userStream(uid),
        builder: (c, s) {
          final u = s.data;
          return Scaffold(
            appBar: AppBar(title: const Text('Saved Addresses')),
            floatingActionButton: u == null
                ? null
                : FloatingActionButton.extended(
                    backgroundColor: C.red,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.add_location_alt_rounded),
                    label: const Text('Add address'),
                    onPressed: () async {
                      final p = await Navigator.push<Place>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LocationPickerScreen(
                                  title: 'Address')));
                      if (p != null)
                        await Db.updateUser(uid, {
                          'saved': [...u.saved.map((e) => e.toMap()), p.toMap()]
                        });
                    },
                  ),
            body: u == null
                ? const Loader()
                : u.saved.isEmpty
                    ? const EmptyState(
                        Icons.bookmark_border_rounded,
                        'No saved addresses',
                        'Save home or work to pick them faster on the map.')
                    : ListView(padding: const EdgeInsets.all(20), children: [
                        for (int i = 0; i < u.saved.length; i++)
                          AppCard(
                              child: Row(children: [
                            const Icon(Icons.place_rounded, color: C.red),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text(u.saved[i].address,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500))),
                            IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: C.grey),
                                onPressed: () {
                                  final l = [...u.saved]..removeAt(i);
                                  Db.updateUser(uid, {
                                    'saved': l.map((e) => e.toMap()).toList()
                                  });
                                })
                          ])),
                      ]),
          );
        },
      );
}

class SavedContactsScreen extends StatelessWidget {
  final String uid;
  const SavedContactsScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) => StreamBuilder<AppUser?>(
        stream: Db.userStream(uid),
        builder: (c, s) {
          final u = s.data;
          return Scaffold(
            appBar: AppBar(title: const Text('Saved Contacts')),
            floatingActionButton: u == null
                ? null
                : FloatingActionButton.extended(
                    backgroundColor: C.red,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Add contact'),
                    onPressed: () => _add(context, u),
                  ),
            body: u == null
                ? const Loader()
                : u.savedContacts.isEmpty
                    ? const EmptyState(
                        Icons.contacts_outlined,
                        'No saved contacts',
                        'Save recipients so you can pick them at checkout.')
                    : ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          for (int i = 0; i < u.savedContacts.length; i++)
                            AppCard(
                                child: Row(children: [
                              Avatar(u.savedContacts[i]['name'] ?? '?'),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(u.savedContacts[i]['name'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                    Text(
                                        maskPhone(
                                            u.savedContacts[i]['phone'] ?? ''),
                                        style: const TextStyle(
                                            color: C.grey, fontSize: 12.5)),
                                  ])),
                              IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: C.grey),
                                  onPressed: () {
                                    final l = [...u.savedContacts]..removeAt(i);
                                    Db.updateUser(uid, {'savedContacts': l});
                                  })
                            ])),
                        ],
                      ),
          );
        },
      );

  static Future<void> _add(BuildContext context, AppUser u) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add contact'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AppField(
                controller: name,
                label: 'Name',
                validator: req,
                icon: Icons.person_outline_rounded),
            AppField(
                controller: phone,
                label: 'Phone',
                icon: Icons.phone_outlined,
                keyboard: TextInputType.phone),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Back')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: C.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await Db.updateUser(u.uid, {
        'savedContacts': [
          ...u.savedContacts,
          {'name': name.text.trim(), 'phone': phone.text.trim()}
        ]
      });
      if (context.mounted) toast(context, 'Contact saved.');
    }
  }
}

class MyReviewsScreen extends StatelessWidget {
  final String uid;
  const MyReviewsScreen({super.key, required this.uid});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My Reviews')),
        body: StreamBuilder<List<Review>>(
          stream: Db.customerReviews(uid),
          builder: (c, s) {
            if (!s.hasData) return const Loader();
            if (s.data!.isEmpty)
              return const EmptyState(Icons.star_border_rounded,
                  'No reviews yet', 'Reviews you give to drivers appear here.');
            return ListView(padding: const EdgeInsets.all(20), children: [
              for (final r in s.data!)
                AppCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Stars(r.rating.toDouble()),
                      const SizedBox(height: 4),
                      Text(r.comment.isEmpty ? 'No comment' : r.comment),
                      Text(fmtDate(r.createdAt),
                          style: const TextStyle(color: C.grey, fontSize: 12))
                    ]))
            ]);
          },
        ),
      );
}
