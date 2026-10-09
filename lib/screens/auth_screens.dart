import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config.dart';
import '../core/loading_screen.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import 'admin_screens.dart';
import 'customer_screens.dart';
import 'driver_screens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 3600), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 900),
          pageBuilder: (_, __, ___) => const AuthGate(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                height: 190,
                child: CustomPaint(
                  painter: _RoadPainter(),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 72),
                child: Image.asset(
                  'assets/images/rider_top.png',
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                ).animate(
                  onPlay: (controller) {
                    controller.repeat();
                  },
                ).moveY(
                  begin: 35,
                  end: -25,
                  duration: 2200.ms,
                  curve: Curves.easeInOut,
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0, -.40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'LIPAT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 43,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      color: C.red,
                    ),
                  )
                      .animate()
                      .fadeIn(
                        delay: 1700.ms,
                        duration: 600.ms,
                      )
                      .slideY(
                        begin: .25,
                        end: 0,
                        delay: 1700.ms,
                        duration: 600.ms,
                      ),
                  const SizedBox(height: 6),
                  Text(
                    'Local Hauling & Moving Marketplace',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: C.grey,
                      letterSpacing: .2,
                    ),
                  ).animate().fadeIn(
                        delay: 2050.ms,
                        duration: 600.ms,
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = const Color(0xFFF0F1F3)
      ..style = PaintingStyle.fill;

    final roadPath = Path();

    roadPath.moveTo(size.width * .27, 0);
    roadPath.lineTo(size.width * .73, 0);
    roadPath.lineTo(size.width, size.height);
    roadPath.lineTo(0, size.height);
    roadPath.close();

    canvas.drawPath(roadPath, road);

    final lane = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;

    for (int i = 0; i < 7; i++) {
      final y = size.height - (i * 42.0) - 18;

      final scale = 1 - (y / size.height) * .75;

      canvas.drawLine(
        Offset(
          centerX,
          y,
        ),
        Offset(
          centerX,
          y + (18 * scale),
        ),
        lane,
      );
    }

    final edge = Paint()
      ..color = const Color(0xFFD7D9DD)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(size.width * .27, 0),
      Offset(0, size.height),
      edge,
    );

    canvas.drawLine(
      Offset(size.width * .73, 0),
      Offset(size.width, size.height),
      edge,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: C.red,
              ),
            ),
          );
        }

        final u = s.data;

        if (u == null) {
          return const LoginScreen(
            key: ValueKey('login'),
          );
        }

        return StreamBuilder<AppUser?>(
          stream: Db.userStream(u.uid),
          builder: (context, us) {
            if (us.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    color: C.red,
                  ),
                ),
              );
            }

            final me = us.data;

            Widget screen;

            if (me == null) {
              screen = Auth.registering
                  ? const Scaffold(
                      body: Center(
                        child: CircularProgressIndicator(
                          color: C.red,
                        ),
                      ),
                    )
                  : RegisterScreen(
                      googleUser: u,
                      key: const ValueKey('complete'),
                    );
            } else if (me.status == 'suspended') {
              screen = const SuspendedScreen(
                key: ValueKey('suspended'),
              );
            } else if (me.role == 'admin') {
              screen = AdminShell(
                me: me,
                key: const ValueKey('admin'),
              );
            } else if (me.role == 'driver') {
              screen = DriverShell(
                me: me,
                key: const ValueKey('driver'),
              );
            } else {
              screen = CustomerShell(
                me: me,
                key: const ValueKey('customer'),
              );
            }

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: screen,
            );
          },
        );
      },
    );
  }
}

class SuspendedScreen extends StatelessWidget {
  const SuspendedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: C.pinkBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.block_rounded,
                  color: C.red,
                  size: 42,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Account suspended',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your account has been suspended by an administrator. Contact support to reactivate it.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: C.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Log out',
                outlined: true,
                onPressed: Auth.logout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();

  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool _loading = false;
  bool _gLoading = false;
  bool _hide = true;
  bool _keepSignedIn = true;

  @override
  void initState() {
    super.initState();
    _loadKeepSignedIn();
  }

  Future<void> _loadKeepSignedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      setState(() {
        _keepSignedIn = prefs.getBool('keep_signed_in') ?? true;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _saveKeepSignedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool(
        'keep_signed_in',
        _keepSignedIn,
      );
    } catch (_) {}
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    await _saveKeepSignedIn();

    if (!mounted) return;

    final nav = Navigator.of(context, rootNavigator: true);

    showLipatLoading(
      context,
      message: 'Signing you in…',
    );

    try {
      await Auth.login(
        _email.text.trim(),
        _pass.text,
      );

      if (nav.canPop()) nav.pop();
    } catch (e) {
      if (nav.canPop()) nav.pop();
      if (mounted) {
        toast(
          context,
          Auth.err(e),
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _google() async {
    setState(() {
      _gLoading = true;
    });

    final nav = Navigator.of(context, rootNavigator: true);

    showLipatLoading(
      context,
      message: 'Signing you in with Google…',
    );

    try {
      await Auth.google();

      if (nav.canPop()) nav.pop();
    } catch (e) {
      if (nav.canPop()) nav.pop();
      if (mounted) {
        toast(
          context,
          'Google sign-in failed. ${Auth.err(e)}',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _gLoading = false;
        });
      }
    }
  }

  Future<void> _forgot() async {
    if (_email.text.trim().isEmpty) {
      toast(
        context,
        'Enter your email first.',
        error: true,
      );
      return;
    }

    try {
      await Auth.resetPassword(
        _email.text.trim(),
      );

      if (mounted) {
        toast(
          context,
          'Password reset link sent to your email.',
        );
      }
    } catch (e) {
      if (mounted) {
        toast(
          context,
          Auth.err(e),
          error: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.peach,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 280,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            C.peach,
                            Color(0xFFFFD8C5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 20,
                    left: 24,
                    child: Text(
                      'LIPAT',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: C.red,
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideX(begin: -.15),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Image.asset(
                      'assets/images/hero_courier.png',
                      width: 285,
                      height: 250,
                      fit: BoxFit.contain,
                    )
                        .animate()
                        .fadeIn(
                          duration: 600.ms,
                        )
                        .slideY(
                          begin: .15,
                          duration: 600.ms,
                          curve: Curves.easeOut,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(34),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    26,
                    24,
                    30,
                  ),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            color: C.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Sign in to manage your hauling services.',
                          style: TextStyle(
                            color: C.grey,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 22),
                        AppField(
                          controller: _email,
                          label: 'Email',
                          icon: Icons.mail_outline_rounded,
                          keyboard: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || !v.trim().contains('@')) {
                              return 'Enter a valid email';
                            }

                            return null;
                          },
                        ),
                        AppField(
                          controller: _pass,
                          label: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _hide,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Enter your password';
                            }

                            return null;
                          },
                          suffix: IconButton(
                            icon: Icon(
                              _hide
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: C.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _hide = !_hide;
                              });
                            },
                          ),
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: _keepSignedIn,
                              activeColor: C.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              onChanged: (v) {
                                setState(() {
                                  _keepSignedIn = v ?? true;
                                });
                              },
                            ),
                            const Expanded(
                              child: Text(
                                'Keep me signed in',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: C.grey,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _forgot,
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: C.red,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        PrimaryButton(
                          label: 'Log In',
                          loading: _loading,
                          onPressed: _login,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(
                                color: C.line,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'or',
                                style: GoogleFonts.plusJakartaSans(
                                  color: C.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(
                                color: C.line,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        GoogleButton(
                          loading: _gLoading,
                          onPressed: _google,
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: Text.rich(
                              TextSpan(
                                text: "Don't have an account? ",
                                style: const TextStyle(
                                  color: C.grey,
                                ),
                                children: const [
                                  TextSpan(
                                    text: 'Sign Up',
                                    style: TextStyle(
                                      color: C.red,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ]
                          .animate(
                            interval: 60.ms,
                          )
                          .fadeIn(
                            duration: 350.ms,
                          )
                          .slideY(
                            begin: .06,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback onPressed;

  const GoogleButton({
    super.key,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(
            color: C.line,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: C.red,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _GoogleG(size: 22),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: C.ink,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleG extends StatelessWidget {
  final double size;
  const _GoogleG({this.size = 22});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _GPainter()),
      );
}

class _GPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final center = Offset(w / 2, w / 2);
    final stroke = w * 0.24;
    final radius = (w - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    Paint arc(Color c) => Paint()
      ..color = c
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;

    const blue = Color(0xFF4285F4);
    const green = Color(0xFF34A853);
    const yellow = Color(0xFFFBBC05);
    const red = Color(0xFFEA4335);

    const pi = 3.1415926535897932;
    double rad(double deg) => deg * pi / 180.0;

    canvas.drawArc(rect, rad(205), rad(90), false, arc(red));
    canvas.drawArc(rect, rad(295), rad(55), false, arc(blue));
    canvas.drawArc(rect, rad(15), rad(70), false, arc(green));
    canvas.drawArc(rect, rad(85), rad(120), false, arc(yellow));

    final bar = Paint()
      ..color = blue
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(w * 0.5, w * 0.5),
      Offset(w - stroke / 2, w * 0.5),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RegisterScreen extends StatefulWidget {
  final User? googleUser;

  const RegisterScreen({
    super.key,
    this.googleUser,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();

  late final _name = TextEditingController(
    text: widget.googleUser?.displayName ?? '',
  );

  late final _email = TextEditingController(
    text: widget.googleUser?.email ?? '',
  );

  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();
  final _plate = TextEditingController();
  final _area = TextEditingController();

  String _role = 'customer';
  String _vehicle = AppConfig.vehicleTypes[1];

  bool _loading = false;
  bool _gLoading = false;
  bool _hide = true;

  bool get _isGoogle => widget.googleUser != null;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _pass.dispose();
    _pass2.dispose();
    _plate.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    final nav = Navigator.of(context, rootNavigator: true);

    showLipatLoading(
      context,
      message: _isGoogle ? 'Finishing your profile…' : 'Creating your account…',
    );

    try {
      if (_isGoogle) {
        final u = widget.googleUser!;

        await Db.createUser(
          AppUser(
            uid: u.uid,
            name: _name.text.trim(),
            email: u.email ?? _email.text.trim(),
            phone: _phone.text.trim(),
            role: _role,
            vehicleType: _role == 'driver' ? _vehicle : '',
            plate: _plate.text.trim(),
            serviceArea: _area.text.trim(),
          ),
        );
      } else {
        await Auth.register(
          role: _role,
          name: _name.text,
          email: _email.text,
          phone: _phone.text,
          password: _pass.text,
          vehicleType: _role == 'driver' ? _vehicle : '',
          plate: _plate.text,
          serviceArea: _area.text,
        );
      }

      if (nav.canPop()) nav.pop();

      if (mounted) {
        Navigator.of(context).pop();

        if (!_isGoogle) {
          Navigator.of(context).popUntil(
            (r) => r.isFirst,
          );
        }
      }
    } catch (e) {
      if (nav.canPop()) nav.pop();

      if (mounted) {
        toast(
          context,
          Auth.err(e),
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _google() async {
    setState(() {
      _gLoading = true;
    });

    final nav = Navigator.of(context, rootNavigator: true);

    showLipatLoading(
      context,
      message: 'Signing you in with Google…',
    );

    try {
      await Auth.google();

      if (nav.canPop()) nav.pop();
    } catch (e) {
      if (nav.canPop()) nav.pop();

      if (mounted) {
        toast(
          context,
          'Google sign-in failed. ${Auth.err(e)}',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _gLoading = false;
        });
      }
    }
  }

  Widget _roleToggle() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: C.field,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _roleButton(
            'customer',
            'Customer',
            Icons.person_rounded,
          ),
          _roleButton(
            'driver',
            'Driver',
            Icons.local_shipping_rounded,
          ),
        ],
      ),
    );
  }

  Widget _roleButton(
    String role,
    String label,
    IconData icon,
  ) {
    final selected = _role == role;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _role = role;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 220,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: selected ? C.red : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : C.grey,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : C.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 230,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      C.peach,
                      Color(0xFFFFD8C5),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 18,
                      left: 20,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: C.red,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Image.asset(
                        'assets/images/hero_courier.png',
                        width: 235,
                        height: 205,
                        fit: BoxFit.contain,
                      )
                          .animate()
                          .fadeIn(
                            duration: 500.ms,
                          )
                          .slideY(
                            begin: .12,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                transform: Matrix4.translationValues(
                  0,
                  -22,
                  0,
                ),
                padding: const EdgeInsets.fromLTRB(
                  22,
                  28,
                  22,
                  35,
                ),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isGoogle
                            ? 'Complete your profile'
                            : 'Create your account',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: C.ink,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _isGoogle
                            ? 'Just a few details and you are ready.'
                            : 'Join LIPAT and start moving with ease.',
                        style: const TextStyle(
                          color: C.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Register as',
                        style: TextStyle(
                          color: C.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _roleToggle(),
                      const SizedBox(height: 18),
                      AppField(
                        controller: _name,
                        label: 'Full Name',
                        icon: Icons.badge_outlined,
                        validator: req,
                      ),
                      if (!_isGoogle)
                        AppField(
                          controller: _email,
                          label: 'Email',
                          icon: Icons.mail_outline_rounded,
                          keyboard: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || !v.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                      AppField(
                        controller: _phone,
                        label: 'Mobile Number',
                        icon: Icons.phone_outlined,
                        keyboard: TextInputType.phone,
                        validator: (v) {
                          if (v == null || v.trim().length < 10) {
                            return 'Enter a valid mobile number';
                          }
                          return null;
                        },
                      ),
                      if (!_isGoogle) ...[
                        AppField(
                          controller: _pass,
                          label: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _hide,
                          validator: (v) {
                            if (v == null || v.length < 6) {
                              return 'At least 6 characters';
                            }
                            return null;
                          },
                          suffix: IconButton(
                            icon: Icon(
                              _hide
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: C.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _hide = !_hide;
                              });
                            },
                          ),
                        ),
                        AppField(
                          controller: _pass2,
                          label: 'Confirm Password',
                          icon: Icons.lock_reset_rounded,
                          obscure: _hide,
                          validator: (v) {
                            if (v != _pass.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                      AnimatedSize(
                        duration: const Duration(
                          milliseconds: 300,
                        ),
                        child: _role != 'driver'
                            ? const SizedBox.shrink()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  Text(
                                    'Driver details',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  const Text(
                                    'These details will be reviewed by an administrator.',
                                    style: TextStyle(
                                      color: C.grey,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 14,
                                  ),
                                  DropdownButtonFormField<String>(
                                    initialValue: _vehicle,
                                    decoration: const InputDecoration(
                                      labelText: 'Vehicle Type',
                                      prefixIcon: Icon(
                                        Icons.local_shipping_outlined,
                                        color: C.grey,
                                      ),
                                    ),
                                    items: [
                                      for (final v in AppConfig.vehicleTypes)
                                        DropdownMenuItem(
                                          value: v,
                                          child: Text(v),
                                        ),
                                    ],
                                    onChanged: (v) {
                                      if (v == null) {
                                        return;
                                      }

                                      setState(() {
                                        _vehicle = v;
                                      });
                                    },
                                  ),
                                  const SizedBox(
                                    height: 14,
                                  ),
                                  AppField(
                                    controller: _plate,
                                    label: 'Plate Number',
                                    icon: Icons.pin_outlined,
                                    validator: req,
                                  ),
                                  AppField(
                                    controller: _area,
                                    label: 'Service Area',
                                    icon: Icons.map_outlined,
                                    validator: req,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    margin: const EdgeInsets.only(
                                      bottom: 15,
                                    ),
                                    decoration: BoxDecoration(
                                      color: C.cream,
                                      borderRadius: BorderRadius.circular(
                                        16,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.verified_user_outlined,
                                          color: C.red,
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        const Expanded(
                                          child: Text(
                                            'Drivers must be verified before sending quotations. License and OR/CR documents can be uploaded from Driver Profile.',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 5),
                      PrimaryButton(
                        label: _isGoogle ? 'Finish Setup' : 'Create Account',
                        loading: _loading,
                        onPressed: _submit,
                      ),
                      if (!_isGoogle) ...[
                        const SizedBox(
                          height: 16,
                        ),
                        GoogleButton(
                          loading: _gLoading,
                          onPressed: _google,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
