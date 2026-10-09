import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocIssue { none, serviceOff, denied, deniedForever, timeout, error }

class Loc {
  static LatLng? last;
  static LocIssue issue = LocIssue.none;

  static String get issueMessage {
    switch (issue) {
      case LocIssue.serviceOff:
        return 'Location services are off. Turn on GPS and try again.';
      case LocIssue.denied:
        return 'Location permission was denied. Allow it to use your location.';
      case LocIssue.deniedForever:
        return 'Location is blocked for LIPAT. Enable it in Settings > Apps > LIPAT > Permissions.';
      case LocIssue.timeout:
        return 'Could not get a GPS fix. Move to an open area and try again.';
      case LocIssue.error:
        return 'Unable to get your current location.';
      case LocIssue.none:
        return '';
    }
  }

  static Future<bool> ensurePermission({bool prompt = true}) async {
    issue = LocIssue.none;
    if (!kIsWeb && !await Geolocator.isLocationServiceEnabled()) {
      issue = LocIssue.serviceOff;
      return false;
    }
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied && prompt) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.denied) {
      issue = LocIssue.denied;
      return false;
    }
    if (p == LocationPermission.deniedForever) {
      issue = LocIssue.deniedForever;
      return false;
    }
    return true;
  }

  static Future<void> openSettings() async {
    if (issue == LocIssue.serviceOff) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  static Future<LatLng?> current() async {
    try {
      if (!await ensurePermission()) return null;

      // 1) Instant: last known position (not supported on web).
      if (!kIsWeb) {
        try {
          final known = await Geolocator.getLastKnownPosition();
          if (known != null) last = LatLng(known.latitude, known.longitude);
        } catch (_) {}
      }

      for (final acc in [LocationAccuracy.high, LocationAccuracy.medium]) {
        try {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(
              accuracy: acc,
              timeLimit: const Duration(seconds: 12),
            ),
          );
          last = LatLng(pos.latitude, pos.longitude);
          issue = LocIssue.none;
          return last;
        } on TimeoutException {
          issue = LocIssue.timeout;
        } catch (_) {
          issue = LocIssue.error;
        }
      }

      if (last != null) {
        issue = LocIssue.none;
        return last;
      }
      return null;
    } catch (_) {
      issue = LocIssue.error;
      return last;
    }
  }

  static Stream<LatLng> watch({int distanceFilter = 15}) async* {
    if (!await ensurePermission()) return;
    yield* Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    ).map((p) {
      last = LatLng(p.latitude, p.longitude);
      return last!;
    });
  }

  static double km(LatLng a, LatLng b) =>
      const Distance().as(LengthUnit.Kilometer, a, b).toDouble();
}
