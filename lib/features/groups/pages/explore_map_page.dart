// lib/features/groups/pages/explore_map_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/colors.dart';
import '../../../core/services/google_maps_service.dart';
import '../../../core/services/location_service.dart';
import 'package:laween/l10n/app_localizations.dart';

class ExploreMapPage extends StatefulWidget {
  const ExploreMapPage({super.key});

  @override
  State<ExploreMapPage> createState() => _ExploreMapPageState();
}

class _ExploreMapPageState extends State<ExploreMapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  final GoogleMapsService _mapsService = GoogleMapsService();
  
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _places = [];
  bool _isLoading = false;
  String _currentQuery = "Coffee";
  LatLng? _currentCenter;
  
  final List<String> _categories = ["Coffee", "Restaurants", "Parks", "Shopping"];

  static const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#212121"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#212121"}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{"color": "#181818"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#2c2c2c"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#000000"}]
  }
]
''';

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final loc = await LocationService().getCurrentPosition();
    if (loc != null) {
      final pos = LatLng(loc.latitude, loc.longitude);
      setState(() => _currentCenter = pos);
      _fetchPlaces(pos);
    }
  }

  Future<void> _fetchPlaces(LatLng position) async {
    setState(() => _isLoading = true);
    final results = await _mapsService.searchPlacesNearby(
      latitude: position.latitude,
      longitude: position.longitude,
      query: _currentQuery,
    );

    final Set<Marker> newMarkers = {};
    for (var p in results) {
      final lat = p['location']['latitude'] as double;
      final lng = p['location']['longitude'] as double;
      newMarkers.add(
        Marker(
          markerId: MarkerId(p['id']),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: p['displayName']['text']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        ),
      );
    }

    setState(() {
      _places = results;
      _markers = newMarkers;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. THE MAP
          if (_currentCenter != null)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentCenter!,
                zoom: 14,
              ),
              onMapCreated: (controller) {
                _controller.complete(controller);
                controller.setMapStyle(_darkMapStyle);
              },
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onCameraIdle: () async {
                final controller = await _controller.future;
                final bounds = await controller.getVisibleRegion();
                final center = LatLng(
                  (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
                  (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
                );
                _fetchPlaces(center);
              },
            ),

          // 2. SEARCH BAR & CATEGORIES
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 18),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, color: Colors.grey),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l10n.isAr ? "ابحث عن أماكن..." : "Search for places...",
                                  style: GoogleFonts.inter(color: Colors.grey),
                                ),
                              ),
                              if (_isLoading)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _currentQuery == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setState(() => _currentQuery = cat);
                              if (_currentCenter != null) _fetchPlaces(_currentCenter!);
                            }
                          },
                          backgroundColor: Colors.black87,
                          selectedColor: AppColors.teal,
                          labelStyle: GoogleFonts.inter(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // 3. HORIZONTAL PLACES LIST (at bottom)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            height: 180,
            child: _places.isEmpty
                ? const SizedBox.shrink()
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _places.length,
                    itemBuilder: (context, index) {
                      final p = _places[index];
                      final photoRef = (p['photos'] != null && p['photos'].isNotEmpty) 
                          ? p['photos'][0]['name'] 
                          : null;
                      final imageUrl = _mapsService.getPlacePhotoUrl(photoRef);

                      return Container(
                        width: 300,
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                              child: imageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      width: 100,
                                      height: 180,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(width: 100, color: Colors.grey.shade200),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      p['displayName']['text'] ?? "",
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${p['rating'] ?? 'N/A'} (${p['userRatingCount'] ?? 0})",
                                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      p['formattedAddress'] ?? "",
                                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
