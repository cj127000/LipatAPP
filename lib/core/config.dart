import 'package:latlong2/latlong.dart';

class AppConfig {
 
  static const mapboxToken = String.fromEnvironment(
    'MAPBOX_TOKEN',
    defaultValue:
        'pk.eyJ1IjoiY2ptYWdzMDMiLCJhIjoiY211bTMwa2l0MDE0ajJ4b2ZoNWZiNGtpcyJ9.YQjfew0knWywjX83sIXnEw',
  );
  static const mapStyle = 'streets-v12';
  static const defaultCenter = LatLng(7.1907, 125.4553); // Davao City

  /// Platform commission taken from every completed delivery (15%).
  static const commissionRate = 0.15;
  static double fee(num price) => price * commissionRate;

  static const vehicleTypes = ['Tricycle', 'Pickup', 'L300 / Van', 'Truck'];

  /// Jobs are only shown to drivers within this radius of the pickup
  /// (or destination). Davao City dispatch.
  static const dispatchRadiusKm = 15.0;

  /// How many days ahead a customer may schedule a hauling request.
  static const maxScheduleDays = 30;

  static String get tileUrl =>
      'https://api.mapbox.com/styles/v1/mapbox/$mapStyle/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxToken';
}
