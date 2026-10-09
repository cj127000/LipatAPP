import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class LipatLoadingScreen extends StatelessWidget {
  final String message;

  const LipatLoadingScreen({
    super.key,
    this.message = 'Signing you in…',
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 14,
              sigmaY: 14,
            ),
            child: Container(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 210,
                  height: 175,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/images/truck_clock.png',
                    width: 175,
                    height: 145,
                    fit: BoxFit.contain,
                  )
                      .animate(
                        onPlay: (controller) {
                          controller.repeat(reverse: true);
                        },
                      )
                      .moveY(
                        begin: 0,
                        end: -9,
                        duration: 650.ms,
                        curve: Curves.easeInOut,
                      )
                      .scale(
                        begin: const Offset(.96, .96),
                        end: const Offset(1.02, 1.02),
                        duration: 650.ms,
                      ),
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF222222),
                  ),
                ).animate().fadeIn(duration: 300.ms).slideY(
                      begin: .15,
                      duration: 300.ms,
                    ),
                const SizedBox(height: 16),
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFB71C1C),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showLipatLoading(
  BuildContext context, {
  String message = 'Signing you in…',
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Loading',
    barrierColor: Colors.black.withValues(alpha: 0.08),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) {
      return LipatLoadingScreen(
        message: message,
      );
    },
    transitionBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}
