import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import 'customer_screens.dart';

//PROFILE WIDGETS

class ProfileHero extends StatelessWidget {
  final String title;
  final AppUser user;
  final String roleLabel;
  final Widget? extraChip;
  final List<Widget> stats;

  const ProfileHero({
    super.key,
    this.title = 'Profile',
    required this.user,
    required this.roleLabel,
    this.extraChip,
    this.stats = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      decoration: const BoxDecoration(
        gradient: C.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(children: [
        if (title.isNotEmpty)
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.w700, color: C.red)),
        const SizedBox(height: 14),
        Avatar(user.name, size: 92, photo: user.photoB64),
        const SizedBox(height: 12),
        Text(user.name,
            style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.w700, color: C.ink)),
        const SizedBox(height: 2),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: C.red.withOpacity(.3))),
            child: Text(roleLabel,
                style: const TextStyle(
                    color: C.red, fontWeight: FontWeight.w600, fontSize: 11.5)),
          ),
          if (extraChip != null) ...[
            const SizedBox(width: 8),
            extraChip!,
          ],
        ]),
        if (user.email.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(user.email,
                style: const TextStyle(color: C.grey, fontSize: 12.5)),
          ),
        if (stats.isNotEmpty) ...[
          const SizedBox(height: 18),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: stats),
        ],
      ]),
    );
  }
}

class ProfileStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const ProfileStat(this.value, this.label, this.icon, {super.key});
  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, color: C.red, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 16, color: C.ink)),
        Text(label, style: const TextStyle(color: C.grey, fontSize: 11.5)),
      ]);
}

class ProfileGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const ProfileGroup({super.key, required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: C.grey,
                    fontSize: 12.5)),
          ),
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4))
                ]),
            child: Column(children: children),
          ),
        ]),
      );
}

class ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color tint;
  final bool danger;
  final Widget? trailing;
  final VoidCallback? onTap;
  const ProfileTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.tint = C.red,
    this.danger = false,
    this.trailing,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final color = danger ? C.red : tint;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: color.withOpacity(.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.5,
                            color: danger ? C.red : C.ink)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: const TextStyle(color: C.grey, fontSize: 12)),
                  ]),
            ),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: C.grey),
          ]),
        ),
      ),
    );
  }
}

Future<void> confirmLogout(BuildContext context) async {
  final ok = await confirmDialog(
      context, 'Log out?', 'You will need to sign in again.',
      yes: 'Log out');
  if (ok) await Auth.logout();
}

void _showAbout(BuildContext context) {
  showAboutDialog(
    context: context,
    applicationName: 'LIPAT',
    applicationVersion: '1.0.0',
    applicationIcon: Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(color: C.yellow, shape: BoxShape.circle),
      child: const Icon(Icons.local_shipping_rounded, color: C.red, size: 30),
    ),
    children: const [
      SizedBox(height: 10),
      Text('LIPAT is a local hauling and moving marketplace connecting '
          'customers with verified drivers in Davao City.'),
      SizedBox(height: 8),
      Text('Need help? Contact support@lipat.app',
          style: TextStyle(color: C.grey, fontSize: 12)),
    ],
  );
}

// CUSTOMER PROFILE

class CustomerProfile extends StatelessWidget {
  final AppUser me;
  const CustomerProfile({super.key, required this.me});

  @override
  Widget build(BuildContext context) => StreamBuilder<AppUser?>(
        stream: Db.userStream(me.uid),
        initialData: me,
        builder: (c, s) {
          final u = s.data ?? me;
          return SafeArea(
            child: ListView(padding: EdgeInsets.zero, children: [
              ProfileHero(
                title: '',
                user: u,
                roleLabel: 'Customer',
                stats: [
                  ProfileStat('${u.completed}', 'Deliveries',
                      Icons.local_shipping_rounded),
                  ProfileStat(
                      '${u.ratingCount}', 'Reviews', Icons.reviews_rounded),
                  ProfileStat(
                      '${u.saved.length}', 'Saved', Icons.bookmark_rounded),
                ],
              ),
              const SizedBox(height: 12),
              ProfileGroup(title: 'Account', children: [
                ProfileTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Edit profile',
                    subtitle: 'Name, phone, photo',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditProfileScreen(user: u)))),
                ProfileTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Change password',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen()))),
              ]),
              ProfileGroup(title: 'Activity', children: [
                ProfileTile(
                    icon: Icons.bookmark_outline_rounded,
                    title: 'Saved addresses',
                    tint: C.blue,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SavedAddressesScreen(uid: u.uid)))),
                ProfileTile(
                    icon: Icons.contacts_rounded,
                    title: 'Saved contacts',
                    tint: C.blue,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SavedContactsScreen(uid: u.uid)))),
                ProfileTile(
                    icon: Icons.history_rounded,
                    title: 'Booking history',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                BookingsTab(me: u, historyOnly: true)))),
                ProfileTile(
                    icon: Icons.star_rounded,
                    title: 'My reviews',
                    tint: const Color(0xFFFFA100),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => MyReviewsScreen(uid: u.uid)))),
              ]),
              ProfileGroup(title: 'More', children: [
                ProfileTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About LIPAT',
                    tint: C.grey,
                    onTap: () => _showAbout(context)),
                ProfileTile(
                    icon: Icons.logout_rounded,
                    title: 'Log out',
                    danger: true,
                    onTap: () => confirmLogout(context)),
              ]),
              const SizedBox(height: 30),
            ]),
          );
        },
      );
}

// DRIVER PROFILE

class DriverProfileTab extends StatelessWidget {
  final AppUser me;
  const DriverProfileTab({super.key, required this.me});

  @override
  Widget build(BuildContext context) => StreamBuilder<AppUser?>(
        stream: Db.userStream(me.uid),
        initialData: me,
        builder: (c, s) {
          final u = s.data ?? me;
          return SafeArea(
            child: ListView(padding: EdgeInsets.zero, children: [
              ProfileHero(
                title: '',
                user: u,
                roleLabel: 'Driver',
                extraChip: StatusChip(u.verified ? 'verified' : u.verification,
                    good: u.verified),
                stats: [
                  ProfileStat(u.rating.toStringAsFixed(1), 'Rating',
                      Icons.star_rounded),
                  ProfileStat(
                      '${u.completed}', 'Completed', Icons.task_alt_rounded),
                  ProfileStat(
                      '${u.ratingCount}', 'Reviews', Icons.reviews_rounded),
                ],
              ),
              if (!u.verified)
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: u.verification == 'rejected' ? C.pinkBg : C.cream,
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    Icon(
                        u.verification == 'rejected'
                            ? Icons.cancel_rounded
                            : Icons.hourglass_top_rounded,
                        color: C.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          u.verification == 'rejected'
                              ? 'Your verification was rejected. Update your documents below.'
                              : 'Verification pending. Upload your license and OR/CR below.',
                          style: const TextStyle(fontSize: 12.5)),
                    ),
                  ]),
                ),
              const SizedBox(height: 12),
              ProfileGroup(title: 'Vehicle', children: [
                ProfileTile(
                    icon: Icons.local_shipping_outlined,
                    title: 'Vehicle',
                    subtitle: '${u.vehicleType}  •  ${u.plate}',
                    tint: C.blue,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditProfileScreen(user: u)))),
                ProfileTile(
                    icon: Icons.location_city_rounded,
                    title: 'Service area',
                    subtitle: u.serviceArea.isEmpty ? '-' : u.serviceArea,
                    tint: C.blue,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditProfileScreen(user: u)))),
              ]),
              ProfileGroup(title: 'Documents', children: [
                ProfileTile(
                    icon: Icons.badge_outlined,
                    title: 'Driver license',
                    subtitle:
                        u.licenseB64.isEmpty ? 'Not uploaded' : 'Uploaded',
                    tint: u.licenseB64.isEmpty ? C.grey : C.green,
                    onTap: () => _uploadDoc(context, u, 'licenseB64')),
                ProfileTile(
                    icon: Icons.description_outlined,
                    title: 'OR / CR',
                    subtitle: u.orcrB64.isEmpty ? 'Not uploaded' : 'Uploaded',
                    tint: u.orcrB64.isEmpty ? C.grey : C.green,
                    onTap: () => _uploadDoc(context, u, 'orcrB64')),
              ]),
              ProfileGroup(title: 'Account', children: [
                ProfileTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Edit profile',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditProfileScreen(user: u)))),
                ProfileTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Change password',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen()))),
                ProfileTile(
                    icon: Icons.history_rounded,
                    title: 'Booking history',
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                BookingsTab(me: u, historyOnly: true)))),
              ]),
              ProfileGroup(title: 'More', children: [
                ProfileTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About LIPAT',
                    tint: C.grey,
                    onTap: () => _showAbout(context)),
                ProfileTile(
                    icon: Icons.logout_rounded,
                    title: 'Log out',
                    danger: true,
                    onTap: () => confirmLogout(context)),
              ]),
              const SizedBox(height: 30),
            ]),
          );
        },
      );

  static Future<void> _uploadDoc(
      BuildContext context, AppUser u, String field) async {
    final p = await pickImageB64(context);
    if (p == null) return;
    await Db.updateUser(u.uid, {field: p, 'verification': 'pending'});
    if (context.mounted) toast(context, 'Document uploaded.');
  }
}

// ADMIN PROFILE

class AdminProfileTab extends StatelessWidget {
  final AppUser me;
  const AdminProfileTab({super.key, required this.me});

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(padding: EdgeInsets.zero, children: [
          ProfileHero(
            title: '',
            user: me,
            roleLabel: 'Administrator',
            extraChip: const StatusChip('active', good: true),
          ),
          const SizedBox(height: 12),
          ProfileGroup(title: 'Account', children: [
            ProfileTile(
                icon: Icons.person_outline_rounded,
                title: 'Edit profile',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => EditProfileScreen(user: me)))),
            ProfileTile(
                icon: Icons.lock_outline_rounded,
                title: 'Change password',
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen()))),
          ]),
          ProfileGroup(title: 'More', children: [
            ProfileTile(
                icon: Icons.info_outline_rounded,
                title: 'About LIPAT',
                tint: C.grey,
                onTap: () => _showAbout(context)),
            ProfileTile(
                icon: Icons.logout_rounded,
                title: 'Log out',
                danger: true,
                onTap: () => confirmLogout(context)),
          ]),
          const SizedBox(height: 30),
        ]),
      );
}

// EDIT PROFILE

class EditProfileScreen extends StatefulWidget {
  final AppUser user;
  const EditProfileScreen({super.key, required this.user});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.name);
  late final _phone = TextEditingController(text: widget.user.phone);
  late final _plate = TextEditingController(text: widget.user.plate);
  late final _area = TextEditingController(text: widget.user.serviceArea);
  late String _vehicle = widget.user.vehicleType.isEmpty
      ? AppConfig.vehicleTypes.first
      : widget.user.vehicleType;
  late String _photo = widget.user.photoB64;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _plate.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final data = <String, dynamic>{
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'photoB64': _photo,
      };
      if (widget.user.isDriver) {
        data['plate'] = _plate.text.trim();
        data['serviceArea'] = _area.text.trim();
        data['vehicleType'] = _vehicle;
      }
      await Db.updateUser(widget.user.uid, data);
      if (!mounted) return;
      toast(context, 'Profile updated.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) toast(context, Auth.err(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickPhoto() async {
    final p = await pickImageB64(context);
    if (p != null) setState(() => _photo = p);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(children: [
                    Avatar(_name.text, size: 100, photo: _photo),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: const BoxDecoration(
                            color: C.red, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text('Tap to change photo',
                    style: TextStyle(color: C.grey, fontSize: 12)),
              ),
              const SizedBox(height: 22),
              AppField(
                  controller: _name,
                  label: 'Full name',
                  icon: Icons.badge_outlined,
                  validator: req),
              AppField(
                  controller: _phone,
                  label: 'Mobile number',
                  icon: Icons.phone_outlined,
                  keyboard: TextInputType.phone),
              if (widget.user.isDriver) ...[
                DropdownButtonFormField<String>(
                  initialValue: _vehicle,
                  decoration: const InputDecoration(
                      labelText: 'Vehicle Type',
                      prefixIcon:
                          Icon(Icons.local_shipping_outlined, color: C.grey)),
                  items: [
                    for (final v in AppConfig.vehicleTypes)
                      DropdownMenuItem(value: v, child: Text(v)),
                  ],
                  onChanged: (v) => setState(() => _vehicle = v ?? _vehicle),
                ),
                const SizedBox(height: 14),
                AppField(
                    controller: _plate,
                    label: 'Plate number',
                    icon: Icons.pin_outlined),
                AppField(
                    controller: _area,
                    label: 'Service area',
                    icon: Icons.map_outlined),
              ],
              const SizedBox(height: 8),
              PrimaryButton(
                  label: 'Save changes', loading: _busy, onPressed: _save),
            ]),
          ),
        ),
      );
}

// CHANGE PASSWORD

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _cur = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _hide = true;

  @override
  void dispose() {
    _cur.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await Auth.changePassword(_cur.text, _next.text);
      if (!mounted) return;
      toast(context, 'Password updated.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) toast(context, Auth.err(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Change Password')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppField(
                  controller: _cur,
                  label: 'Current password',
                  icon: Icons.lock_outline_rounded,
                  obscure: _hide,
                  suffix: IconButton(
                      icon: Icon(
                          _hide
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: C.grey),
                      onPressed: () => setState(() => _hide = !_hide)),
                  validator: req),
              AppField(
                  controller: _next,
                  label: 'New password',
                  icon: Icons.lock_reset_rounded,
                  obscure: _hide,
                  validator: (v) => (v == null || v.length < 6)
                      ? 'At least 6 characters'
                      : null),
              AppField(
                  controller: _confirm,
                  label: 'Confirm new password',
                  icon: Icons.lock_reset_rounded,
                  obscure: _hide,
                  validator: (v) =>
                      v != _next.text ? 'Passwords do not match' : null),
              const SizedBox(height: 8),
              PrimaryButton(
                  label: 'Update password', loading: _busy, onPressed: _save),
            ]),
          ),
        ),
      );
}
