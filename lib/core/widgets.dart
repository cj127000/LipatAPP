import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import 'config.dart';
import 'theme.dart';

String money(num v) => 'PHP ${NumberFormat('#,##0.00').format(v)}';
String moneyShort(num v) => 'PHP ${NumberFormat('#,##0').format(v)}';
String fmtDate(DateTime d) => DateFormat('EEE, MMM d • h:mm a').format(d);
String fmtShort(DateTime d) => DateFormat('EEE, h:mm a').format(d);
String maskPhone(String p) =>
    p.length < 8 ? p : '${p.substring(0, 4)} *** ${p.substring(p.length - 4)}';

void toast(BuildContext c, String msg, {bool error = false}) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Row(children: [
        Icon(error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: Colors.white),
        const SizedBox(width: 10),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: error ? Colors.red.shade700 : C.ink,
    ));
}

Future<bool> confirmDialog(BuildContext c, String title, String body,
    {String yes = 'Confirm'}) async {
  final r = await showDialog<bool>(
    context: c,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      content: Text(body),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Back')),
        FilledButton(
            style: FilledButton.styleFrom(backgroundColor: C.red),
            onPressed: () => Navigator.pop(c, true),
            child: Text(yes)),
      ],
    ),
  );
  return r ?? false;
}

Future<DateTime?> pickDateTime(BuildContext c, {DateTime? initial}) async {
  final now = DateTime.now();
  final d = await showDatePicker(
      context: c,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: AppConfig.maxScheduleDays)));
  if (d == null || !c.mounted) return null;
  final t = await showTimePicker(
      context: c,
      initialTime:
          TimeOfDay.fromDateTime(initial ?? now.add(const Duration(hours: 1))));
  if (t == null) return null;
  final picked = DateTime(d.year, d.month, d.day, t.hour, t.minute);
  final cutoff = DateTime.now().add(const Duration(minutes: 1));
  if (picked.isBefore(cutoff)) {
    if (c.mounted) {
      toast(c, 'Please pick a date and time in the future.', error: true);
    }
    return null;
  }
  return picked;
}

Future<String?> pickImageB64(BuildContext c) async {
  final src = await showModalBottomSheet<ImageSource>(
    context: c,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        ListTile(
            leading: const Icon(Icons.photo_camera_rounded, color: C.red),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(c, ImageSource.camera)),
        ListTile(
            leading: const Icon(Icons.photo_library_rounded, color: C.red),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(c, ImageSource.gallery)),
      ]),
    ),
  );
  if (src == null) return null;
  final f = await ImagePicker()
      .pickImage(source: src, maxWidth: 900, imageQuality: 55);
  if (f == null) return null;
  return base64Encode(await f.readAsBytes());
}

Widget b64Image(String b64, {double? h, double? w, BoxFit fit = BoxFit.cover}) {
  try {
    final Uint8List bytes = base64Decode(b64);
    return Image.memory(bytes, height: h, width: w, fit: fit);
  } catch (_) {
    return Container(
        height: h,
        width: w,
        color: C.line,
        child: const Icon(Icons.broken_image_rounded, color: C.grey));
  }
}

Future<void> shareTrackingLink(BuildContext c, Booking b) async {
  final text = 'Track my LIPAT delivery ${b.code}:\n'
      'From: ${b.pickup.short}\n'
      'To: ${b.dest.short}\n'
      'Driver: ${b.driverName} (${b.vehicle})\n'
      'Track inside the LIPAT app → Bookings → ${b.code}';
  await Share.share(text, subject: 'LIPAT Tracking ${b.code}');
}

class LipatLogo extends StatelessWidget {
  final double size;
  const LipatLogo({super.key, this.size = 90});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration:
            BoxDecoration(color: C.yellow, shape: BoxShape.circle, boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.2),
              blurRadius: 24,
              offset: const Offset(0, 10)),
        ]),
        alignment: Alignment.center,
        child: Text('LIPAT',
            style: GoogleFonts.poppins(
                color: C.red,
                fontWeight: FontWeight.w800,
                fontSize: size * .2,
                letterSpacing: .5)),
      );
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color color;
  const AppCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(14),
      this.onTap,
      this.color = Colors.white});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6)),
            ]),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: Padding(padding: padding, child: child)),
        ),
      );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading, outlined;
  final IconData? icon;
  final Color color;
  final Color? textColor;
  const PrimaryButton(
      {super.key,
      required this.label,
      this.onPressed,
      this.loading = false,
      this.outlined = false,
      this.icon,
      this.color = C.red,
      this.textColor});
  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? (outlined ? color : Colors.white);
    final child = loading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.6, color: fg))
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
                if (icon != null) ...[
                  Icon(icon, size: 20),
                  const SizedBox(width: 8)
                ],
                Flexible(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 15))),
              ]);
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: outlined
          ? OutlinedButton(
              onPressed: loading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                  foregroundColor: fg,
                  side: BorderSide(color: color, width: 1.6),
                  shape: shape),
              child: child)
          : FilledButton(
              onPressed: loading ? null : onPressed,
              style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: fg,
                  shape: shape,
                  elevation: 0),
              child: child),
    );
  }
}

class AppField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final IconData? icon;
  final bool obscure, readOnly;
  final TextInputType? keyboard;
  final int maxLines;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  const AppField(
      {super.key,
      this.controller,
      required this.label,
      this.icon,
      this.obscure = false,
      this.readOnly = false,
      this.keyboard,
      this.maxLines = 1,
      this.validator,
      this.onTap,
      this.suffix,
      this.onChanged});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: controller,
          obscureText: obscure,
          readOnly: readOnly,
          keyboardType: keyboard,
          maxLines: maxLines,
          validator: validator,
          onTap: onTap,
          onChanged: onChanged,
          decoration: InputDecoration(
              labelText: label,
              prefixIcon:
                  icon == null ? null : Icon(icon, color: C.grey, size: 22),
              suffixIcon: suffix),
        ),
      );
}

String? req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

class StatusChip extends StatelessWidget {
  final String status;
  final bool good;
  const StatusChip(this.status, {super.key, this.good = false});
  static String label(String s) {
    switch (s) {
      case 'inTransit':
        return 'In Transit';
      case 'none':
        return 'Customer';
      default:
        return s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg = C.yellow, fg = C.ink;
    if (good) {
      bg = C.greenBg;
      fg = C.green;
    }
    switch (good ? '' : status) {
      case 'completed':
      case 'verified':
      case 'active':
      case 'accepted_q':
        bg = C.greenBg;
        fg = C.green;
        break;
      case 'delivered':
        bg = C.blueBg;
        fg = C.blue;
        break;
      case 'cancelled':
      case 'declined':
        bg = const Color(0xFFEDEDF0);
        fg = C.grey;
        break;
      case 'suspended':
      case 'rejected':
        bg = C.pinkBg;
        fg = C.red;
        break;
      case 'booked':
        bg = C.greenBg;
        fg = C.green;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label(status),
          style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class Stars extends StatelessWidget {
  final double rating;
  final double size;
  const Stars(this.rating, {super.key, this.size = 16});
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        for (int i = 1; i <= 5; i++)
          Icon(
              rating >= i
                  ? Icons.star_rounded
                  : (rating >= i - .5
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded),
              color: C.yellow,
              size: size),
      ]);
}

class Avatar extends StatelessWidget {
  final String name;
  final double size;
  final String photo;
  const Avatar(this.name, {super.key, this.size = 44, this.photo = ''});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: C.cream,
            border: Border.all(color: C.yellow, width: 1.6)),
        alignment: Alignment.center,
        child: photo.isNotEmpty
            ? b64Image(photo, w: size, h: size)
            : Text(name.isEmpty ? '?' : name.trim()[0].toUpperCase(),
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: C.red,
                    fontSize: size * .42)),
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  const EmptyState(this.icon, this.title, [this.sub = '', Key? key])
      : super(key: key);
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                padding: const EdgeInsets.all(22),
                decoration:
                    const BoxDecoration(color: C.cream, shape: BoxShape.circle),
                child: Icon(icon, size: 40, color: C.red)),
            const SizedBox(height: 16),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                textAlign: TextAlign.center),
            if (sub.isNotEmpty)
              Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(sub,
                      style: const TextStyle(color: C.grey),
                      textAlign: TextAlign.center)),
          ]),
        ),
      );
}

class Loader extends StatelessWidget {
  const Loader({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: C.red));
}

class FilterChips extends StatelessWidget {
  final List<String> items;
  final String selected;
  final ValueChanged<String> onSelect;
  const FilterChips(
      {super.key,
      required this.items,
      required this.selected,
      required this.onSelect});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 40,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final i in items)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(i),
                selected: selected == i,
                onSelected: (_) => onSelect(i),
                showCheckmark: false,
                selectedColor: C.red,
                backgroundColor: Colors.white,
                side: BorderSide(color: selected == i ? C.red : C.line),
                labelStyle: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: selected == i ? Colors.white : C.ink),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
        ]),
      );
}

class InfoRow extends StatelessWidget {
  final String k, v;
  const InfoRow(this.k, this.v, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 110,
              child:
                  Text(k, style: const TextStyle(color: C.grey, fontSize: 13))),
          Expanded(
              child: Text(v,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13.5))),
        ]),
      );
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Row(children: [
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16))),
          if (trailing != null) trailing!
        ]),
      );
}

IconData vehicleIcon(String v) {
  switch (v) {
    case 'Tricycle':
      return Icons.electric_rickshaw_rounded;
    case 'Pickup':
      return Icons.local_shipping_outlined;
    case 'L300 / Van':
      return Icons.airport_shuttle_rounded;
    default:
      return Icons.local_shipping_rounded;
  }
}

class TabShell extends StatefulWidget {
  final List<Widget> pages;
  final List<NavigationDestination> items;
  final List<Stream<int>?>? badges;

  const TabShell({
    super.key,
    required this.pages,
    required this.items,
    this.badges,
  });

  @override
  State<TabShell> createState() => _TabShellState();
}

class _TabShellState extends State<TabShell> {
  int i = 0;

  NavigationDestination _wrap(NavigationDestination dest, Stream<int>? stream) {
    if (stream == null) return dest;
    return NavigationDestination(
      icon: _BadgeStream(stream: stream, child: dest.icon),
      selectedIcon: dest.selectedIcon == null
          ? null
          : _BadgeStream(stream: stream, child: dest.selectedIcon!),
      label: dest.label,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: PageTransitionSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, a, b) => FadeThroughTransition(
              animation: a,
              secondaryAnimation: b,
              fillColor: C.bg,
              child: child),
          child: KeyedSubtree(key: ValueKey(i), child: widget.pages[i]),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.08), blurRadius: 20)
          ]),
          child: NavigationBar(
            selectedIndex: i,
            onDestinationSelected: (v) => setState(() => i = v),
            destinations: [
              for (int j = 0; j < widget.items.length; j++)
                _wrap(
                  widget.items[j],
                  widget.badges != null && j < widget.badges!.length
                      ? widget.badges![j]
                      : null,
                ),
            ],
          ),
        ),
      );
}

class _BadgeStream extends StatelessWidget {
  final Stream<int> stream;
  final Widget child;
  const _BadgeStream({required this.stream, required this.child});

  @override
  Widget build(BuildContext context) => StreamBuilder<int>(
        stream: stream,
        builder: (c, s) {
          final n = s.data ?? 0;
          if (n <= 0) return child;
          return Badge(
            label: Text(n > 99 ? '99+' : '$n'),
            backgroundColor: C.red,
            textColor: Colors.white,
            child: child,
          );
        },
      );
}

class ScreenTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const ScreenTitle(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Row(children: [
          Expanded(
              child: Text(text,
                  style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: C.red))),
          if (trailing != null) trailing!,
        ]),
      );
}

class SignaturePad extends StatefulWidget {
  final void Function(String base64Png) onSigned;
  const SignaturePad({super.key, required this.onSigned});
  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final _points = <List<Offset>>[];
  List<Offset> _current = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: C.line),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: GestureDetector(
              onPanStart: (d) => setState(() => _current = [d.localPosition]),
              onPanUpdate: (d) =>
                  setState(() => _current = [..._current, d.localPosition]),
              onPanEnd: (_) {
                if (_current.length > 1) _points.add(_current);
                setState(() => _current = []);
              },
              child: CustomPaint(
                painter: _SignPainter([..._points, _current]),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => setState(() {
                _points.clear();
                _current = [];
              }),
              icon: const Icon(Icons.refresh_rounded, color: C.red),
              label: const Text('Clear', style: TextStyle(color: C.red)),
            ),
            const Spacer(),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: C.red),
              onPressed: () async {
                if (_points.isEmpty) return;
                final bytes = await _renderToPng();
                widget.onSigned(base64Encode(bytes));
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Use Signature'),
            ),
          ],
        ),
      ],
    );
  }

  Future<Uint8List> _renderToPng() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(600, 240);
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    for (final stroke in _points) {
      final p = Paint()
        ..color = Colors.black
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(stroke.first.dx * 1.6, stroke.first.dy * 1.6);
      for (final o in stroke.skip(1)) {
        path.lineTo(o.dx * 1.6, o.dy * 1.6);
      }
      canvas.drawPath(path, p);
    }
    final img = await recorder.endRecording().toImage(600, 240);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }
}

class _SignPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  _SignPainter(this.strokes);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = C.ink
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.length < 2) continue;
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (final o in s.skip(1)) {
        path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(_SignPainter old) => true;
}
