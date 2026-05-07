import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/theme/colors.dart';
import 'package:laween/l10n/app_localizations.dart';

class LocationPickerPage extends StatefulWidget {
  final Position initialPosition;

  const LocationPickerPage({super.key, required this.initialPosition});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  gmaps.GoogleMapController? _mapController;
  late gmaps.LatLng _centerPosition;

  // Search
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<_PlaceSuggestion> _suggestions = [];
  Timer? _debounce;
  bool _showSuggestions = false;
  bool _isMoving = false;

  String get _apiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  @override
  void initState() {
    super.initState();
    _centerPosition = gmaps.LatLng(
      widget.initialPosition.latitude,
      widget.initialPosition.longitude,
    );
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() { _suggestions = []; _showSuggestions = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _fetchSuggestions(query));
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      final url = Uri.parse('https://places.googleapis.com/v1/places:searchText');
      final Map<String, dynamic> body = {'textQuery': query};

      body['locationBias'] = {
        'circle': {
          'center': {
            'latitude': _centerPosition.latitude,
            'longitude': _centerPosition.longitude,
          },
          'radius': 5000.0,
        },
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,places.location',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> places = data['places'] ?? [];
        if (mounted) {
          setState(() {
            _suggestions = places.map((p) {
              final loc = p['location'];
              return _PlaceSuggestion(
                placeId: p['id'] ?? '',
                mainText: p['displayName']?['text'] ?? '',
                secondaryText: p['formattedAddress'] ?? '',
                lat: loc?['latitude'],
                lng: loc?['longitude'],
              );
            }).toList();
            _showSuggestions = _suggestions.isNotEmpty;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _selectPlace(_PlaceSuggestion place) async {
    _searchFocus.unfocus();
    setState(() { _showSuggestions = false; });
    if (place.lat != null && place.lng != null) {
      final target = gmaps.LatLng(place.lat!, place.lng!);
      _mapController?.animateCamera(
        gmaps.CameraUpdate.newCameraPosition(
          gmaps.CameraPosition(target: target, zoom: 15),
        ),
      );
      setState(() => _centerPosition = target);
      _searchController.clear();
    }
  }

  void _onCameraMove(gmaps.CameraPosition pos) {
    setState(() {
      _centerPosition = pos.target;
      _isMoving = true;
    });
  }

  void _onCameraIdle() {
    setState(() => _isMoving = false);
  }

  void _goToMyLocation() {
    final myPos = gmaps.LatLng(
      widget.initialPosition.latitude,
      widget.initialPosition.longitude,
    );
    _mapController?.animateCamera(
      gmaps.CameraUpdate.newCameraPosition(
        gmaps.CameraPosition(target: myPos, zoom: 15),
      ),
    );
  }

  void _sendLocation() {
    Navigator.pop(context, _centerPosition);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Full-screen Google Map
          gmaps.GoogleMap(
            initialCameraPosition: gmaps.CameraPosition(
              target: _centerPosition,
              zoom: 15,
            ),
            onMapCreated: (c) => _mapController = c,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),

          // Fixed center crosshair pin
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  transform: Matrix4.translationValues(0, _isMoving ? -10 : 0, 0),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.teal,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.teal.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.location_on, color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                ),
                // Shadow dot below pin
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _isMoving ? 0.3 : 0.6,
                  child: Container(
                    width: _isMoving ? 12 : 8,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Top bar: back + search
          SafeArea(
            child: Column(
              children: [
                // App bar row
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppColors.darkSlate),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.darkSlate),
                          decoration: InputDecoration(
                            hintText: l10n.searchForAPlace,
                            hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade400),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.grey.shade400, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() { _suggestions = []; _showSuggestions = false; });
                          },
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.search, color: Colors.grey, size: 22),
                        ),
                    ],
                  ),
                ),

                // Search suggestions
                if (_showSuggestions)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _suggestions.length.clamp(0, 5),
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (context, i) {
                          final s = _suggestions[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_outlined, color: AppColors.teal, size: 20),
                            title: Text(s.mainText, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkSlate)),
                            subtitle: s.secondaryText.isNotEmpty
                                ? Text(s.secondaryText, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500), maxLines: 1, overflow: TextOverflow.ellipsis)
                                : null,
                            onTap: () => _selectPlace(s),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // My location button
          Positioned(
            right: 16,
            bottom: 175,
            child: GestureDetector(
              onTap: _goToMyLocation,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8),
                  ],
                ),
                child: const Icon(Icons.my_location, color: AppColors.teal, size: 22),
              ),
            ),
          ),

          // Bottom "Send" card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, color: AppColors.teal, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.selectedLocation,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkSlate,
                              ),
                            ),
                            Text(
                              "${_centerPosition.latitude.toStringAsFixed(5)}, ${_centerPosition.longitude.toStringAsFixed(5)}",
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.tealGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextButton(
                        onPressed: _sendLocation,
                        style: TextButton.styleFrom(
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              l10n.sendLocation,
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceSuggestion {
  final String placeId;
  final String mainText;
  final String secondaryText;
  final double? lat;
  final double? lng;
  const _PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    this.lat,
    this.lng,
  });
}
