import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../services/db_service.dart';
import '../services/location_service.dart';
import '../services/mapbox_service.dart';
import 'config.dart';
import 'theme.dart';
import 'widgets.dart';

TileLayer mapTiles() => TileLayer(
      urlTemplate: AppConfig.tileUrl,
      userAgentPackageName: 'com.lipat.app',
    );

Marker pin(
  LatLng p,
  Color c,
  IconData icon,
) =>
    Marker(
      point: p,
      width: 44,
      height: 44,
      alignment: Alignment.topCenter,
      child: Icon(
        icon,
        color: c,
        size: 40,
        shadows: const [
          Shadow(
            color: Colors.black38,
            blurRadius: 8,
          ),
        ],
      ),
    );

/// Hand the destination to Google Maps or Waze (whichever is installed).
Future<void> launchExternalNav(BuildContext c, Place dest) async {
  final g = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${dest.lat},${dest.lng}&travelmode=driving');
  final waze = Uri.parse('waze://?ll=${dest.lat},${dest.lng}&navigate=yes');
  try {
    if (await canLaunchUrl(waze)) {
      await launchUrl(waze, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(g)) {
      await launchUrl(g, mode: LaunchMode.externalApplication);
    } else if (c.mounted) {
      toast(c, 'No navigation app available.', error: true);
    }
  } catch (_) {
    if (c.mounted) toast(c, 'Could not open navigation.', error: true);
  }
}

class RouteMap extends StatefulWidget {
  final Place pickup;
  final Place dest;
  final double height;
  final bool interactive;
  final ValueChanged<double>? onDistance;

  const RouteMap({
    super.key,
    required this.pickup,
    required this.dest,
    this.height = 180,
    this.interactive = false,
    this.onDistance,
  });

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  final _ctl = MapController();

  RouteInfo? _route;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(RouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.pickup.lat != widget.pickup.lat ||
        oldWidget.pickup.lng != widget.pickup.lng ||
        oldWidget.dest.lat != widget.dest.lat ||
        oldWidget.dest.lng != widget.dest.lng) {
      _load();
    }
  }

  Future<void> _load() async {
    final route = await Mapbox.route(
      widget.pickup.ll,
      widget.dest.ll,
    );

    if (!mounted) return;

    setState(() {
      _route = route;
    });

    widget.onDistance?.call(route.km);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fit();
    });
  }

  void _fit() {
    if (!_ready || !mounted) return;

    final points = _route?.points ?? [widget.pickup.ll, widget.dest.ll];

    _ctl.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(40),
        maxZoom: 16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _ctl,
              options: MapOptions(
                initialCenter: widget.pickup.ll,
                initialZoom: 12,
                interactionOptions: InteractionOptions(
                  flags: widget.interactive
                      ? InteractiveFlag.all
                      : InteractiveFlag.none,
                ),
                onMapReady: () {
                  _ready = true;
                  _fit();
                },
              ),
              children: [
                mapTiles(),
                if (_route != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _route!.points,
                        strokeWidth: 5,
                        color: C.red,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    pin(
                      widget.pickup.ll,
                      C.red,
                      Icons.trip_origin_rounded,
                    ),
                    pin(
                      widget.dest.ll,
                      C.yellow,
                      Icons.location_on_rounded,
                    ),
                  ],
                ),
              ],
            ),
            if (_route != null)
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    '${_route!.km.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
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

// ═══════════════════════════════════════════════════════════════
// LOCATION PICKER
// ═══════════════════════════════════════════════════════════════

class LocationPickerScreen extends StatefulWidget {
  final String title;
  final Place? initial;
  final List<Place> saved;

  const LocationPickerScreen({
    super.key,
    required this.title,
    this.initial,
    this.saved = const [],
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _map = MapController();
  final _q = TextEditingController();

  Timer? _deb;

  Place? _sel;

  List<Place> _results = [];

  bool _searching = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _sel = widget.initial;
  }

  @override
  void dispose() {
    _deb?.cancel();
    _q.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _deb?.cancel();

    if (value.trim().length < 2) {
      setState(() {
        _results = [];
      });
      return;
    }

    _deb = Timer(
      const Duration(milliseconds: 400),
      () async {
        setState(() {
          _searching = true;
        });

        final results = await Mapbox.search(value);

        if (!mounted) return;

        setState(() {
          _results = results;
          _searching = false;
        });
      },
    );
  }

  Future<void> _tap(LatLng ll) async {
    setState(() {
      _sel = Place(
        'Locating address…',
        ll.latitude,
        ll.longitude,
      );

      _locating = true;
      _results = [];
    });

    FocusScope.of(context).unfocus();

    final address = await Mapbox.reverse(ll);

    if (!mounted) return;

    setState(() {
      _sel = Place(
        address,
        ll.latitude,
        ll.longitude,
      );

      _locating = false;
    });
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;

    setState(() {
      _locating = true;
    });

    try {
      final current = await Loc.current();

      if (current == null) {
        if (mounted) {
          _locationError();
        }
        return;
      }

      final address = await Mapbox.reverse(current);

      if (!mounted) return;

      setState(() {
        _sel = Place(
          address,
          current.latitude,
          current.longitude,
        );

        _results = [];
        _q.clear();
      });

      _map.move(current, 16);

      toast(
        context,
        'Current location selected.',
      );
    } catch (_) {
      if (mounted) {
        toast(
          context,
          'Unable to get your current location.',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _locating = false;
        });
      }
    }
  }

  void _locationError() {
    final msg = Loc.issueMessage.isEmpty
        ? 'Location unavailable. Turn on GPS and allow LIPAT to use your location.'
        : Loc.issueMessage;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        action: (Loc.issue == LocIssue.serviceOff ||
                Loc.issue == LocIssue.deniedForever)
            ? SnackBarAction(
                label: 'SETTINGS',
                textColor: Colors.white,
                onPressed: Loc.openSettings)
            : null,
      ));
  }

  void _choose(Place p) {
    FocusScope.of(context).unfocus();

    setState(() {
      _sel = p;
      _results = [];
      _q.clear();
    });

    _map.move(
      p.ll,
      15.5,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: widget.initial?.ll ?? AppConfig.defaultCenter,
              initialZoom: 13.5,
              onTap: (_, ll) => _tap(ll),
            ),
            children: [
              mapTiles(),
              if (_sel != null)
                MarkerLayer(
                  markers: [
                    pin(
                      _sel!.ll,
                      C.red,
                      Icons.location_on_rounded,
                    ),
                  ],
                ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 4,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(16),
                          child: TextField(
                            controller: _q,
                            onChanged: _onSearch,
                            decoration: InputDecoration(
                              hintText: 'Search ${widget.title.toLowerCase()}',
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: C.red,
                              ),
                              suffixIcon: _searching
                                  ? const Padding(
                                      padding: EdgeInsets.all(14),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: C.red,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 4,
                        child: IconButton(
                          tooltip: 'Use my current location',
                          icon: _locating
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: C.red,
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location_rounded,
                                  color: C.red,
                                ),
                          onPressed: _locating ? null : _useCurrentLocation,
                        ),
                      ),
                    ],
                  ),
                  if (_results.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(
                        maxHeight: 280,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        children: [
                          for (final p in _results)
                            ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.place_outlined,
                                color: C.red,
                              ),
                              title: Text(
                                p.address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _choose(p),
                            ),
                        ],
                      ),
                    ),
                  if (_results.isEmpty && widget.saved.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final p in widget.saved)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 8,
                                  right: 8,
                                ),
                                child: ActionChip(
                                  avatar: const Icon(
                                    Icons.bookmark_rounded,
                                    size: 16,
                                    color: C.red,
                                  ),
                                  label: Text(p.short),
                                  backgroundColor: Colors.white,
                                  onPressed: () => _choose(p),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: C.red,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _sel?.address ??
                                'Tap the map or search to set the ${widget.title.toLowerCase()}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: _sel == null ? C.grey : C.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: 'Confirm ${widget.title}',
                      icon: Icons.check_rounded,
                      onPressed: (_sel == null || _locating)
                          ? null
                          : () => Navigator.pop(
                                context,
                                _sel,
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DRIVER NAVIGATION (live GPS, pickup leg then delivery leg)
// ═══════════════════════════════════════════════════════════════

class DriverNavigationScreen extends StatefulWidget {
  final Booking booking;
  const DriverNavigationScreen({super.key, required this.booking});

  @override
  State<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen> {
  final _map = MapController();
  StreamSubscription<LatLng>? _sub;
  Timer? _reroute;

  LatLng? _me;
  RouteInfo? _route;
  bool _loading = true;
  bool _mapReady = false;
  bool _follow = true;
  late bool _toPickup = !widget.booking.pickedUp;
  DateTime _lastPush = DateTime.fromMillisecondsSinceEpoch(0);

  Place get _target => _toPickup ? widget.booking.pickup : widget.booking.dest;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _reroute?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    final first = await Loc.current();
    if (!mounted) return;
    if (first == null) {
      _showLocError();
    } else {
      _me = first;
      _publish(first);
    }
    await _loadRoute();
    _sub = Loc.watch(distanceFilter: 10).listen((p) {
      if (!mounted) return;
      setState(() => _me = p);
      _publish(p);
      if (_follow && _mapReady) _map.move(p, _map.camera.zoom);
    }, onError: (_) {});
    // Refresh the road route every 30 s so directions follow the driver.
    _reroute = Timer.periodic(
        const Duration(seconds: 30), (_) => _loadRoute(fit: false));
  }

  void _showLocError() {
    final msg =
        Loc.issueMessage.isEmpty ? 'GPS unavailable.' : Loc.issueMessage;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        action: SnackBarAction(
            label: 'SETTINGS',
            textColor: Colors.white,
            onPressed: Loc.openSettings),
      ));
  }

  /// Writes the driver position so the customer can watch live (max every 4 s).
  void _publish(LatLng p) {
    final now = DateTime.now();
    if (now.difference(_lastPush).inSeconds < 4) return;
    _lastPush = now;
    Db.updateBooking(widget.booking.id,
        {'driverLat': p.latitude, 'driverLng': p.longitude}).catchError((_) {});
  }

  Future<void> _loadRoute({bool fit = true}) async {
    final from = _me ??
        (_toPickup ? widget.booking.pickup.ll : widget.booking.pickup.ll);
    final route = await Mapbox.route(from, _target.ll);
    if (!mounted) return;
    setState(() {
      _route = route;
      _loading = false;
    });
    if (fit) WidgetsBinding.instance.addPostFrameCallback((_) => _fit());
  }

  void _fit() {
    if (!mounted || !_mapReady) return;
    final pts = <LatLng>[if (_me != null) _me!, _target.ll, ...?_route?.points];
    _map.fitCamera(CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(pts),
        padding: const EdgeInsets.fromLTRB(50, 120, 50, 330),
        maxZoom: 17));
  }

  Future<void> _arrivedAtPickup() async {
    setState(() {
      _toPickup = false;
      _loading = true;
    });
    Db.updateBooking(widget.booking.id, {'pickedUp': true}).catchError((_) {});
    await _loadRoute();
  }

  Future<void> _recenter() async {
    setState(() => _follow = true);
    final p = _me ?? await Loc.current();
    if (p == null) return _showLocError();
    setState(() => _me = p);
    if (_mapReady) _map.move(p, 16.5);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return Scaffold(
      body: Stack(children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: _target.ll,
            initialZoom: 13,
            onMapReady: () {
              _mapReady = true;
              _fit();
            },
            onPositionChanged: (_, byGesture) {
              if (byGesture && _follow) setState(() => _follow = false);
            },
          ),
          children: [
            mapTiles(),
            if (_route != null)
              PolylineLayer(polylines: [
                Polyline(
                    points: _route!.points,
                    strokeWidth: 8,
                    color: Colors.white),
                Polyline(
                    points: _route!.points,
                    strokeWidth: 5,
                    color: _toPickup ? C.blue : C.red),
              ]),
            MarkerLayer(markers: [
              pin(b.pickup.ll, C.red, Icons.trip_origin_rounded),
              pin(b.dest.ll, C.yellow, Icons.location_on_rounded),
              if (_me != null)
                Marker(
                  point: _me!,
                  width: 46,
                  height: 46,
                  child: Container(
                    decoration: BoxDecoration(
                        color: C.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(color: Colors.black38, blurRadius: 8)
                        ]),
                    child: const Icon(Icons.navigation_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
            ]),
          ],
        ),
        // top bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 4,
                child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.pop(context)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                      color: _toPickup ? C.blue : C.red,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 10)
                      ]),
                  child: Row(children: [
                    Icon(
                        _toPickup
                            ? Icons.trip_origin_rounded
                            : Icons.flag_rounded,
                        color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _toPickup
                            ? 'Step 1 of 2: Go to pickup'
                            : 'Step 2 of 2: Deliver to drop-off',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
        if (_loading)
          const Center(
              child: Card(
                  child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        CircularProgressIndicator(color: C.red),
                        SizedBox(height: 12),
                        Text('Getting route...'),
                      ])))),
        // recenter
        Positioned(
          right: 16,
          bottom: 340,
          child: FloatingActionButton.small(
            heroTag: 'recenter',
            backgroundColor: Colors.white,
            onPressed: _recenter,
            child: Icon(
                _follow
                    ? Icons.my_location_rounded
                    : Icons.location_searching_rounded,
                color: C.red),
          ),
        ),
        // bottom panel
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 18)
                  ]),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_toPickup ? 'Pickup' : 'Drop-off',
                        style: const TextStyle(color: C.grey, fontSize: 12)),
                    Text(_target.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    if (_route != null) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        const Icon(Icons.route_rounded, color: C.red, size: 20),
                        const SizedBox(width: 6),
                        Text('${_route!.km.toStringAsFixed(1)} km',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 18),
                        const Icon(Icons.access_time_rounded,
                            color: C.red, size: 20),
                        const SizedBox(width: 6),
                        Text('${_route!.minutes.round()} min',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      ]),
                      if (_route!.steps.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: C.cream,
                              borderRadius: BorderRadius.circular(14)),
                          child: Row(children: [
                            const Icon(Icons.turn_right_rounded, color: C.red),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(_route!.steps.first.text,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ),
                            Text('${_route!.steps.first.meters.round()} m',
                                style: const TextStyle(
                                    color: C.grey, fontSize: 12)),
                          ]),
                        ),
                      ],
                    ],
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => launchExternalNav(context, _target),
                      icon: const Icon(Icons.map_rounded, color: C.red),
                      label: const Text('Open in Maps / Waze',
                          style: TextStyle(color: C.red)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: C.red),
                          minimumSize: const Size(double.infinity, 46),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                    ),
                    if (_route != null && _route!.steps.length > 1)
                      Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text('All directions',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13.5)),
                          children: [
                            SizedBox(
                              height: 140,
                              child: ListView(children: [
                                for (final st in _route!.steps)
                                  ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(
                                        Icons.turn_right_rounded,
                                        color: C.red,
                                        size: 20),
                                    title: Text(st.text,
                                        style: const TextStyle(fontSize: 13)),
                                    trailing: Text(
                                        '${(st.meters / 1000).toStringAsFixed(2)} km',
                                        style: const TextStyle(
                                            color: C.grey, fontSize: 12)),
                                  ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    if (_toPickup)
                      PrimaryButton(
                          label: 'Picked Up: Navigate to Drop-off',
                          icon: Icons.inventory_2_rounded,
                          color: C.yellow,
                          textColor: C.ink,
                          onPressed: _arrivedAtPickup)
                    else
                      PrimaryButton(
                          label: 'Arrived: Back to Job',
                          icon: Icons.flag_rounded,
                          onPressed: () => Navigator.pop(context)),
                  ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LIVE TRACKING MAP (customer side)
// ═══════════════════════════════════════════════════════════════

class LiveTrackMap extends StatefulWidget {
  final Booking booking;
  final double height;
  const LiveTrackMap({super.key, required this.booking, this.height = 260});

  @override
  State<LiveTrackMap> createState() => _LiveTrackMapState();
}

class _LiveTrackMapState extends State<LiveTrackMap> {
  final _ctl = MapController();
  RouteInfo? _route;
  bool _ready = false;
  LatLng? _lastDriver;
  double? _etaMinutes;

  @override
  void initState() {
    super.initState();
    Mapbox.route(widget.booking.pickup.ll, widget.booking.dest.ll).then((r) {
      if (mounted) setState(() => _route = r);
    });
    final b = widget.booking;
    if (b.driverLat != null && b.driverLng != null) {
      _recalcEta(LatLng(b.driverLat!, b.driverLng!));
    }
  }

  @override
  void didUpdateWidget(LiveTrackMap old) {
    super.didUpdateWidget(old);
    final b = widget.booking;
    if (b.driverLat != null && b.driverLng != null && _ready) {
      final d = LatLng(b.driverLat!, b.driverLng!);
      if (_lastDriver == null || Loc.km(_lastDriver!, d) > 0.01) {
        _lastDriver = d;
        _ctl.move(d, _ctl.camera.zoom);
        _recalcEta(d);
      }
    }
  }

  Future<void> _recalcEta(LatLng driver) async {
    final r = await Mapbox.route(driver, widget.booking.dest.ll);
    if (mounted) setState(() => _etaMinutes = r.minutes);
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final driver = (b.driverLat != null && b.driverLng != null)
        ? LatLng(b.driverLat!, b.driverLng!)
        : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: widget.height,
        child: Stack(children: [
          FlutterMap(
            mapController: _ctl,
            options: MapOptions(
              initialCenter: driver ?? b.pickup.ll,
              initialZoom: 14,
              onMapReady: () {
                _ready = true;
                final pts = [
                  b.pickup.ll,
                  b.dest.ll,
                  if (driver != null) driver
                ];
                _ctl.fitCamera(CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(pts),
                    padding: const EdgeInsets.all(50),
                    maxZoom: 16));
              },
            ),
            children: [
              mapTiles(),
              if (_route != null)
                PolylineLayer(polylines: [
                  Polyline(points: _route!.points, strokeWidth: 5, color: C.red)
                ]),
              MarkerLayer(markers: [
                pin(b.pickup.ll, C.red, Icons.trip_origin_rounded),
                pin(b.dest.ll, C.yellow, Icons.location_on_rounded),
                if (driver != null)
                  Marker(
                    point: driver,
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                          color: C.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 8)
                          ]),
                      child: const Icon(Icons.local_shipping_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
              ]),
            ],
          ),
          // Live / waiting chip
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8)
                  ]),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.circle,
                    size: 10, color: driver != null ? C.green : C.grey),
                const SizedBox(width: 6),
                Text(driver != null ? 'Driver live' : 'Waiting for driver GPS',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
            ),
          ),
          // ETA + Share
          Positioned(
            right: 10,
            top: 10,
            child: Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 8)
                    ]),
                child: Text(
                  _etaMinutes == null
                      ? 'ETA …'
                      : 'ETA ${_etaMinutes!.round()} min',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 3,
                child: IconButton(
                  tooltip: 'Share tracking link',
                  icon: const Icon(Icons.share_rounded, color: C.red, size: 18),
                  onPressed: () => shareTrackingLink(context, widget.booking),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
