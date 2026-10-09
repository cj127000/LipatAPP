import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../core/config.dart';
import '../models/models.dart';

class RouteStep {
  final String text;
  final double meters;
  RouteStep(this.text, this.meters);
}

class RouteInfo {
  final double km, minutes;
  final List<LatLng> points;
  final List<RouteStep> steps;
  RouteInfo(this.km, this.points, {this.minutes = 0, this.steps = const []});
}

class Mapbox {
  static const _host = 'api.mapbox.com';
  static String get _t => AppConfig.mapboxToken;

  static Future<List<Place>> search(String q) async {
    if (q.trim().length < 2) return [];
    try {
      final uri = Uri.https(_host,
          '/geocoding/v5/mapbox.places/${q.trim().replaceAll('/', ' ')}.json', {
        'access_token': _t,
        'limit': '6',
        'country': 'ph',
        'proximity': '123.8854,10.3157',
      });
      final r = await http.get(uri).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return [];
      final f = (jsonDecode(r.body)['features'] as List);
      return f.map((e) {
        final c = e['center'] as List;
        return Place('${e['place_name']}', (c[1] as num).toDouble(),
            (c[0] as num).toDouble());
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<String> reverse(LatLng p) async {
    try {
      final uri = Uri.https(
          _host,
          '/geocoding/v5/mapbox.places/${p.longitude},${p.latitude}.json',
          {'access_token': _t, 'limit': '1'});
      final r = await http.get(uri).timeout(const Duration(seconds: 10));
      final f = jsonDecode(r.body)['features'] as List;
      if (f.isNotEmpty) return '${f.first['place_name']}';
    } catch (_) {}
    return '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
  }

  /// Road route via Mapbox Directions; falls back to straight-line distance if offline.
  static Future<RouteInfo> route(LatLng a, LatLng b) async {
    try {
      final uri = Uri.https(
          _host,
          '/directions/v5/mapbox/driving/${a.longitude},${a.latitude};${b.longitude},${b.latitude}',
          {
            'access_token': _t,
            'geometries': 'geojson',
            'overview': 'full',
            'steps': 'true',
          });
      final r = await http.get(uri).timeout(const Duration(seconds: 12));
      final routes = jsonDecode(r.body)['routes'] as List;
      if (routes.isNotEmpty) {
        final pts = (routes[0]['geometry']['coordinates'] as List)
            .map((c) =>
                LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();
        final steps = <RouteStep>[];
        try {
          for (final st in (routes[0]['legs'][0]['steps'] as List)) {
            steps.add(RouteStep('${st['maneuver']['instruction']}',
                (st['distance'] as num).toDouble()));
          }
        } catch (_) {}
        return RouteInfo(((routes[0]['distance'] as num) / 1000), pts,
            minutes: ((routes[0]['duration'] as num) / 60), steps: steps);
      }
    } catch (_) {}
    final km = const Distance().as(LengthUnit.Kilometer, a, b).toDouble();
    return RouteInfo(km < 0.1 ? 0.1 : km, [a, b], minutes: km / 25 * 60);
  }
}
