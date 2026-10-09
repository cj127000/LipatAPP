import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../services/notification_service.dart';
import 'profile_screens.dart';

class AdminShell extends StatelessWidget {
  final AppUser me;
  const AdminShell({super.key, required this.me});
  @override
  Widget build(BuildContext context) => TabShell(
        pages: [
          const DashboardTab(),
          const DriverVerificationTab(),
          UsersTab(me: me),
          const ReportsTab(),
          AdminProfileTab(me: me),
        ],
        items: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.verified_user_outlined),
              selectedIcon: Icon(Icons.verified_user_rounded),
              label: 'Drivers'),
          NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Users'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights_rounded),
              label: 'Reports'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
        badges: [
          null,
          Notif.adminPendingDrivers(),
          null,
          null,
          null,
        ],
      );
}

// Dashboard
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  Widget _stat(String v, String l, bool hi, IconData i) => Expanded(
        child: Container(
          margin: const EdgeInsets.all(5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
              color: hi ? C.cream : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: hi ? C.yellow.withOpacity(.5) : C.line)),
          child: Column(children: [
            Icon(i, color: C.red, size: 20),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: double.parse(v)),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                builder: (_, x, __) => Text(x.round().toString(),
                    style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: C.red))),
            Text(l, style: const TextStyle(fontSize: 11, color: C.grey)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
        child: StreamBuilder<List<AppUser>>(
          stream: Db.allUsers(),
          builder: (c, us) => StreamBuilder<List<HaulRequest>>(
            stream: Db.allRequests(),
            builder: (c, rs) => StreamBuilder<List<Booking>>(
              stream: Db.allBookings(),
              builder: (c, bs) {
                if (!us.hasData || !rs.hasData || !bs.hasData)
                  return const Loader();
                final users = us.data!, bookings = bs.data!;
                final drivers = users.where((u) => u.isDriver).toList();
                final pending =
                    drivers.where((d) => d.verification == 'pending').length;
                final completed =
                    bookings.where((b) => b.status == 'completed').length;
                final now = DateTime.now();
                final weeks = List<double>.generate(6, (i) {
                  final end = now.subtract(Duration(days: 7 * (5 - i)));
                  final start = end.subtract(const Duration(days: 7));
                  return bookings
                      .where((b) =>
                          b.createdAt.isAfter(start) &&
                          !b.createdAt.isAfter(end))
                      .length
                      .toDouble();
                });
                final top = ([...drivers.where((d) => d.ratingCount > 0)]
                      ..sort((a, b) => b.rating.compareTo(a.rating)))
                    .take(3)
                    .toList();
                final maxW = weeks.fold<double>(1, (m, v) => v > m ? v : m);
                return ListView(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
                    children: [
                      Padding(
                          padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                          child: Row(children: [
                            const Expanded(
                                child: ScreenTitle('Admin Dashboard')),
                            IconButton(
                                tooltip: 'Log out',
                                icon: const Icon(Icons.logout_rounded,
                                    color: C.red),
                                onPressed: () async {
                                  if (await confirmDialog(context, 'Log out?',
                                      'You will need to sign in again.',
                                      yes: 'Log out')) Auth.logout();
                                })
                          ])),
                      Row(children: [
                        _stat(
                            '${users.where((u) => u.role == 'customer').length}',
                            'Customers',
                            true,
                            Icons.people_alt_rounded),
                        _stat('${drivers.length}', 'Drivers', true,
                            Icons.local_shipping_rounded),
                        _stat('${rs.data!.length}', 'Requests', true,
                            Icons.assignment_rounded)
                      ]),
                      Row(children: [
                        _stat('${bookings.length}', 'Bookings', false,
                            Icons.book_online_rounded),
                        _stat('$completed', 'Completed', false,
                            Icons.task_alt_rounded),
                        _stat('$pending', 'Pending Drivers', false,
                            Icons.pending_actions_rounded)
                      ]),
                      const Padding(
                          padding: EdgeInsets.fromLTRB(5, 16, 5, 0),
                          child: SectionTitle('Bookings per Week')),
                      Container(
                        height: 190,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: C.line)),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (int i = 0; i < weeks.length; i++)
                                Expanded(
                                  child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(weeks[i].toInt().toString(),
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 4),
                                        TweenAnimationBuilder<double>(
                                            tween: Tween(
                                                begin: 0,
                                                end: (weeks[i] / maxW) * 100 +
                                                    4),
                                            duration: Duration(
                                                milliseconds: 600 + i * 120),
                                            curve: Curves.easeOutCubic,
                                            builder: (_, h, __) => Container(
                                                height: h,
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 7),
                                                decoration: BoxDecoration(
                                                    color: i.isEven
                                                        ? C.red
                                                        : C.yellow,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8)))),
                                        const SizedBox(height: 6),
                                        Text('W${i + 1}',
                                            style: const TextStyle(
                                                fontSize: 10.5, color: C.grey)),
                                      ]),
                                ),
                            ]),
                      ),
                      const Padding(
                          padding: EdgeInsets.fromLTRB(5, 16, 5, 0),
                          child: SectionTitle('Top Drivers')),
                      if (top.isEmpty)
                        const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('No rated drivers yet.',
                                style: TextStyle(color: C.grey))),
                      for (final d in top)
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: AppCard(
                                child: Row(children: [
                              Avatar(d.name, size: 38),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Text(d.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600))),
                              Stars(d.rating, size: 14),
                              const SizedBox(width: 6),
                              Text('${d.rating.toStringAsFixed(1)} rating',
                                  style: const TextStyle(
                                      color: C.grey, fontSize: 12))
                            ]))),
                    ]);
              },
            ),
          ),
        ),
      );
}

// Driver verification
class DriverVerificationTab extends StatefulWidget {
  const DriverVerificationTab({super.key});
  @override
  State<DriverVerificationTab> createState() => _DriverVerificationTabState();
}

class _DriverVerificationTabState extends State<DriverVerificationTab> {
  String _f = 'Pending', _q = '';

  void _view(String title, String b64) => showDialog(
        context: context,
        builder: (_) => Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  color: C.red,
                  padding: const EdgeInsets.all(14),
                  width: double.infinity,
                  child: Text(title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600))),
              InteractiveViewer(child: b64Image(b64, fit: BoxFit.contain))
            ])),
      );

  Widget _thumb(String label, String b64) => GestureDetector(
        onTap: b64.isEmpty ? null : () => _view(label, b64),
        child: Container(
          width: 66,
          height: 52,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
              color: C.bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: C.line)),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: b64.isEmpty
                  ? Center(
                      child: Text(label,
                          style: const TextStyle(fontSize: 9.5, color: C.grey)))
                  : b64Image(b64)),
        ),
      );

  Future<void> _set(AppUser d, String v) async {
    if (v == 'verified' &&
        d.licenseB64.isEmpty &&
        !await confirmDialog(context, 'No documents uploaded',
            '${d.name} has not uploaded a license yet. Approve anyway?',
            yes: 'Approve')) return;
    await Db.updateUser(d.uid, {'verification': v});
    if (mounted)
      toast(context, '${d.name} ${v == 'verified' ? 'approved' : 'rejected'}.');
  }

  Future<void> _clearSafety(AppUser d) async {
    await Db.updateUser(d.uid, {'safetyCheck': 'cleared'});
    if (mounted) toast(context, '${d.name}: safety check cleared.');
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const ScreenTitle('Driver Verification'),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                  onChanged: (v) => setState(() => _q = v.toLowerCase()),
                  decoration: InputDecoration(
                      hintText: 'Search driver',
                      prefixIcon:
                          const Icon(Icons.search_rounded, color: C.grey),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: C.line)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: C.line))))),
          const SizedBox(height: 12),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FilterChips(
                  items: const ['Pending', 'Verified', 'Rejected'],
                  selected: _f,
                  onSelect: (v) => setState(() => _f = v))),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: Db.allUsers(),
              builder: (c, s) {
                if (!s.hasData) return const Loader();
                final l = s.data!
                    .where((u) =>
                        u.isDriver &&
                        u.verification == _f.toLowerCase() &&
                        u.name.toLowerCase().contains(_q))
                    .toList();
                if (l.isEmpty)
                  return EmptyState(
                      Icons.verified_user_outlined,
                      'No ${_f.toLowerCase()} drivers',
                      'Drivers awaiting review will appear here.');
                return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      for (final d in l)
                        AppCard(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Row(children: [
                                Avatar(d.name),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(d.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700)),
                                      Text('${d.vehicleType}  |  ${d.plate}',
                                          style: const TextStyle(
                                              color: C.grey, fontSize: 12)),
                                      Text('${d.serviceArea}  |  ${d.phone}',
                                          style: const TextStyle(
                                              color: C.grey, fontSize: 12)),
                                      if (d.safetyCheck == 'cleared')
                                        const Padding(
                                            padding: EdgeInsets.only(top: 4),
                                            child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.shield_rounded,
                                                      color: C.green, size: 14),
                                                  SizedBox(width: 4),
                                                  Text('Safety cleared',
                                                      style: TextStyle(
                                                          color: C.green,
                                                          fontSize: 11.5,
                                                          fontWeight:
                                                              FontWeight.w600))
                                                ])),
                                    ]))
                              ]),
                              const SizedBox(height: 12),
                              Row(children: [
                                _thumb('License', d.licenseB64),
                                _thumb('OR/CR', d.orcrB64),
                                const Spacer(),
                                Column(children: [
                                  if (d.verification != 'verified')
                                    SizedBox(
                                        width: 92,
                                        height: 34,
                                        child: FilledButton(
                                            onPressed: () =>
                                                _set(d, 'verified'),
                                            style: FilledButton.styleFrom(
                                                backgroundColor: C.red,
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            18))),
                                            child: const Text('Approve',
                                                style: TextStyle(
                                                    fontSize: 12.5)))),
                                  if (d.verification != 'rejected') ...[
                                    const SizedBox(height: 6),
                                    SizedBox(
                                        width: 92,
                                        height: 34,
                                        child: OutlinedButton(
                                            onPressed: () =>
                                                _set(d, 'rejected'),
                                            style: OutlinedButton.styleFrom(
                                                foregroundColor: C.red,
                                                side: const BorderSide(
                                                    color: C.red),
                                                padding: EdgeInsets.zero,
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            18))),
                                            child: const Text('Reject',
                                                style:
                                                    TextStyle(fontSize: 12.5))))
                                  ],
                                ]),
                              ]),
                              if (d.verification == 'pending' &&
                                  d.safetyCheck != 'cleared')
                                Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: OutlinedButton.icon(
                                        onPressed: () => _clearSafety(d),
                                        icon: const Icon(Icons.shield_rounded,
                                            color: C.green, size: 18),
                                        label: const Text('Clear safety check',
                                            style: TextStyle(
                                                color: C.green,
                                                fontSize: 12.5)),
                                        style: OutlinedButton.styleFrom(
                                            minimumSize:
                                                const Size(double.infinity, 36),
                                            side: const BorderSide(
                                                color: C.green),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        18))))),
                            ])).animate().fadeIn(duration: 300.ms).slideY(
                            begin: .05),
                    ]);
              },
            ),
          ),
        ]),
      );
}

//  Manage users
class UsersTab extends StatefulWidget {
  final AppUser me;
  const UsersTab({super.key, required this.me});
  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  String _f = 'All', _q = '';

  void _manage(AppUser u) => showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Avatar(u.name, size: 50),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(u.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(u.email,
                            style:
                                const TextStyle(color: C.grey, fontSize: 12.5))
                      ])),
                  StatusChip(u.status)
                ]),
                const SizedBox(height: 12),
                InfoRow(
                    'Role',
                    StatusChip.label(
                        u.role == 'customer' ? 'customer' : u.role)),
                InfoRow('Phone', u.phone.isEmpty ? '-' : u.phone),
                if (u.isDriver)
                  InfoRow('Vehicle', '${u.vehicleType} (${u.plate})'),
                const SizedBox(height: 14),
                u.status == 'suspended'
                    ? PrimaryButton(
                        label: 'Reactivate Account',
                        icon: Icons.lock_open_rounded,
                        onPressed: () async {
                          await Db.updateUser(u.uid, {'status': 'active'});
                          if (mounted) {
                            Navigator.pop(context);
                            toast(context, '${u.name} reactivated.');
                          }
                        })
                    : PrimaryButton(
                        label: 'Suspend Account',
                        icon: Icons.block_rounded,
                        onPressed: () async {
                          await Db.updateUser(
                              u.uid, {'status': 'suspended', 'online': false});
                          if (mounted) {
                            Navigator.pop(context);
                            toast(context, '${u.name} suspended.');
                          }
                        }),
                const SizedBox(height: 8),
              ]),
        ),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const ScreenTitle('Manage Users'),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                  onChanged: (v) => setState(() => _q = v.toLowerCase()),
                  decoration: InputDecoration(
                      hintText: 'Search user',
                      prefixIcon:
                          const Icon(Icons.search_rounded, color: C.grey),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: C.line)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: C.line))))),
          const SizedBox(height: 12),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FilterChips(
                  items: const ['All', 'Customers', 'Drivers'],
                  selected: _f,
                  onSelect: (v) => setState(() => _f = v))),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: Db.allUsers(),
              builder: (c, s) {
                if (!s.hasData) return const Loader();
                final l = s.data!
                    .where((u) =>
                        u.role != 'admin' &&
                        (_f == 'All' ||
                            (_f == 'Customers'
                                ? u.role == 'customer'
                                : u.isDriver)) &&
                        (u.name.toLowerCase().contains(_q) ||
                            u.email.toLowerCase().contains(_q)))
                    .toList();
                if (l.isEmpty)
                  return const EmptyState(
                      Icons.people_outline_rounded, 'No users found');
                return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      for (final u in l)
                        AppCard(
                            child: Row(children: [
                          Avatar(u.name),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(u.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                Text(u.isDriver ? 'Driver' : 'Customer',
                                    style: const TextStyle(
                                        color: C.grey, fontSize: 12)),
                                const SizedBox(height: 4),
                                StatusChip(u.status)
                              ])),
                          SizedBox(
                              height: 36,
                              child: OutlinedButton(
                                  onPressed: () => _manage(u),
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: C.red,
                                      side: const BorderSide(color: C.red),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18))),
                                  child: const Text('Manage')))
                        ])),
                    ]);
              },
            ),
          ),
        ]),
      );
}

//  Reports
class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});
  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  DateTimeRange _range = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now());
  String _f = 'All';
  final _df = DateFormat('MMM d, y');

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2024),
        lastDate: DateTime.now().add(const Duration(days: 1)),
        initialDateRange: _range,
        builder: (c, w) => Theme(
            data: Theme.of(c).copyWith(
                colorScheme: Theme.of(c).colorScheme.copyWith(primary: C.red)),
            child: w!));
    if (r != null) setState(() => _range = r);
  }

  List<Booking> _filter(List<Booking> all) {
    final end =
        DateTime(_range.end.year, _range.end.month, _range.end.day, 23, 59, 59);
    return all
        .where((b) =>
            !b.createdAt.isBefore(_range.start) &&
            !b.createdAt.isAfter(end) &&
            (_f == 'All' || b.status == _f.toLowerCase()))
        .toList();
  }

  void _export(List<Booking> l) {
    final e = (String s) => '"${s.replaceAll('"', '""')}"';
    final sb = StringBuffer(
        'Booking ID,Date,Customer,Driver,Item,Pickup,Destination,Price,Status\n');
    for (final b in l) {
      sb.writeln([
        b.code,
        DateFormat('yyyy-MM-dd HH:mm').format(b.createdAt),
        e(b.customerName),
        e(b.driverName),
        e(b.item),
        e(b.pickup.short),
        e(b.dest.short),
        b.price.toStringAsFixed(2),
        b.status
      ].join(','));
    }
    Clipboard.setData(ClipboardData(text: sb.toString()));
    toast(context,
        'Report (${l.length} rows) copied as CSV. Paste it into Sheets or Excel.');
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: StreamBuilder<List<Booking>>(
          stream: Db.allBookings(),
          builder: (c, s) {
            if (!s.hasData) return const Loader();
            final l = _filter(s.data!);
            final done = l.where((b) => b.status == 'completed').toList();
            final days = _range.duration.inDays + 1;
            const buckets = 6;
            final vals = List<double>.filled(buckets, 0);
            for (final b in done) {
              final i = ((b.createdAt.difference(_range.start).inDays) *
                      buckets ~/
                      days)
                  .clamp(0, buckets - 1);
              vals[i] += 1;
            }
            final revenue = done.fold<double>(0, (a, b) => a + b.price);
            return ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  const ScreenTitle('Transactions & Reports'),
                  GestureDetector(
                      onTap: _pickRange,
                      child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: C.line)),
                          child: Row(children: [
                            const Icon(Icons.date_range_rounded, color: C.red),
                            const SizedBox(width: 12),
                            Text(
                                '${_df.format(_range.start)} - ${_df.format(_range.end)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            const Spacer(),
                            const Icon(Icons.expand_more_rounded, color: C.grey)
                          ]))),
                  const SizedBox(height: 12),
                  FilterChips(
                      items: const ['All', 'Completed', 'Cancelled'],
                      selected: _f,
                      onSelect: (v) => setState(() => _f = v)),
                  const SizedBox(height: 14),
                  AppCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(children: [
                          const Expanded(
                              child: Text('Completed Transactions',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700))),
                          Text(moneyShort(revenue),
                              style: GoogleFonts.poppins(
                                  color: C.red, fontWeight: FontWeight.w700))
                        ]),
                        const SizedBox(height: 14),
                        SizedBox(
                            height: 120,
                            width: double.infinity,
                            child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeOut,
                                builder: (_, t, __) => CustomPaint(
                                    painter: _LinePainter(vals, t)))),
                      ])),
                  if (l.isEmpty)
                    const EmptyState(
                        Icons.receipt_long_outlined,
                        'No transactions in this range',
                        'Try a wider date range or a different status.'),
                  for (final b in l.take(50))
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
                                    fontSize: 13)),
                            Text('${b.driverName}  |  ${b.item}',
                                style: const TextStyle(
                                    color: C.grey, fontSize: 12))
                          ])),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(moneyShort(b.price),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            StatusChip(b.status)
                          ])
                    ])),
                  const SizedBox(height: 6),
                  PrimaryButton(
                      label: 'Export Report',
                      icon: Icons.download_rounded,
                      onPressed: l.isEmpty ? null : () => _export(l)),
                ]);
          },
        ),
      );
}

class _LinePainter extends CustomPainter {
  final List<double> v;
  final double t;
  _LinePainter(this.v, this.t);
  @override
  void paint(Canvas canvas, Size s) {
    final mx = v.fold<double>(1, (m, x) => x > m ? x : m);
    final pts = [
      for (int i = 0; i < v.length; i++)
        Offset(i * s.width / (v.length - 1),
            s.height - 8 - (v[i] / mx) * (s.height - 24) * t)
    ];
    final grid = Paint()
      ..color = C.line
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
          Offset(0, s.height * i / 3), Offset(s.width, s.height * i / 3), grid);
    }
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final fill = Path.from(path)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [C.red.withOpacity(.25), C.red.withOpacity(0)])
              .createShader(Offset.zero & s));
    canvas.drawPath(
        path,
        Paint()
          ..color = C.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round);
    for (final p in pts) {
      canvas.drawCircle(p, 5, Paint()..color = Colors.white);
      canvas.drawCircle(
          p,
          5,
          Paint()
            ..color = C.red
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4);
    }
  }

  @override
  bool shouldRepaint(_LinePainter o) => o.t != t || o.v != v;
}
