// lib/features/groups/pages/explore_map_page.dart

import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laween/l10n/app_localizations.dart';
import '../../../core/theme/colors.dart';
import '../../../core/services/google_maps_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/favorite_service.dart';

class ExploreMapPage extends StatefulWidget {
  const ExploreMapPage({super.key});

  @override
  State<ExploreMapPage> createState() => _ExploreMapPageState();
}

class _ExploreMapPageState extends State<ExploreMapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  final ScrollController _scrollController = ScrollController();
  final GoogleMapsService _mapsService = GoogleMapsService();
  
  // State
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _masterPlaces = [];    // Original API results (original ranking)
  List<Map<String, dynamic>> _displayedPlaces = []; // Sorted for UI [Visible, Hidden]
  
  bool _isLoading = false;
  String _currentQuery = "Coffee";
  LatLng? _currentCenter;
  LatLng? _lastFetchedCenter;
  String? _tappedPlaceId;
  Set<String> _favoritePlaceIds = {};
  StreamSubscription<Set<String>>? _favoriteSubscription;
  Timer? _debounceSync;
  Timer? _debounceSearch;
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isManualSearch = false;
  
  final List<String> _categories = ["Coffee", "Restaurants", "Parks", "Shopping"];
  final Map<int, BitmapDescriptor> _markerCache = {};
  double _currentZoom = 14.5;

  Future<BitmapDescriptor> _getCustomMarker(BuildContext context, double zoom) async {
    final int discreteZoom = zoom.round();
    if (_markerCache.containsKey(discreteZoom)) return _markerCache[discreteZoom]!;

    double baseSize = 30.0;
    if (zoom < 13) baseSize = 20.0;
    if (zoom < 10) baseSize = 12.0;
    if (zoom > 16) baseSize = 40.0;

    final double logicalSize = baseSize;
    const double scale = 2.0; 
    final double size = logicalSize * scale;
    
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(Icons.location_on_rounded.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: Icons.location_on_rounded.fontFamily,
        package: Icons.location_on_rounded.fontPackage,
        color: const Color(0xFF016D77),
      ),
    );
    
    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);

    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();
    
    final descriptor = BitmapDescriptor.bytes(uint8List);
    _markerCache[discreteZoom] = descriptor;
    return descriptor;
  }

  static const String _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#212121"}]},
  {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#757575"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#212121"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#757575"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#181818"}]},
  {"featureType": "road", "elementType": "geometry.fill", "stylers": [{"color": "#2c2c2c"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#000000"}]}
]
''';

  @override
  void initState() {
    super.initState();
    _initLocation();
    _subscribeToFavorites();
  }

  void _subscribeToFavorites() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint("📱 [ExploreMapPage] Subscribing to favorites for user: $uid");
    
    _favoriteSubscription = FavoriteService().streamUserFavoritePlaceIds().listen((ids) {
      debugPrint("📱 [ExploreMapPage] Received ${ids.length} favorite IDs from Firestore");
      debugPrint("📱 [ExploreMapPage] Current Favorite IDs: $ids");
      if (mounted) {
        setState(() {
          _favoritePlaceIds = ids;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceSync?.cancel();
    _debounceSearch?.cancel();
    _favoriteSubscription?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final loc = await LocationService().getCurrentPosition();
    if (loc != null) {
      final pos = LatLng(loc.latitude, loc.longitude);
      setState(() => _currentCenter = pos);
      _fetchPlaces(pos);
    }
  }

  /// Calculates distance in meters between two coordinates
  double _calculateDistance(LatLng p1, LatLng p2) {
    var p = 0.017453292519943295;
    var c = math.cos;
    var a = 0.5 - c((p2.latitude - p1.latitude) * p) / 2 +
        c(p1.latitude * p) * c(p2.latitude * p) *
            (1 - c((p2.longitude - p1.longitude) * p)) / 2;
    return 12742000 * math.asin(math.sqrt(a));
  }

  void _onSearchChanged(String query) {
    _debounceSearch?.cancel();
    _debounceSearch = Timer(const Duration(milliseconds: 600), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        _clearSearch();
      }
    });
  }

  void _performSearch(String query) {
    debugPrint("🔍 [ExploreSearch] Manual search: $query");
    setState(() {
      _isManualSearch = true;
      _currentQuery = query;
    });
    _fetchPlaces(_currentCenter ?? const LatLng(31.9539, 35.9106));
  }

  void _clearSearch() {
    debugPrint("🔍 [ExploreSearch] Clearing search");
    setState(() {
      _searchController.clear();
      _isManualSearch = false;
      _currentQuery = _categories[0]; // Reset to first category
    });
    _fetchPlaces(_currentCenter ?? const LatLng(31.9539, 35.9106));
  }

  Future<void> _fetchPlaces(LatLng position) async {
    setState(() => _isLoading = true);
    final results = await _mapsService.searchPlacesNearby(
      latitude: position.latitude,
      longitude: position.longitude,
      query: _currentQuery,
    );

    _lastFetchedCenter = position;
    
    // Convert to Map list to ensure stability
    final List<Map<String, dynamic>> masterList = results;

    setState(() {
      _masterPlaces = masterList;
      _isLoading = false;
    });
    
    // Immediately apply current viewport sorting after fetch
    final controller = await _controller.future;
    final bounds = await controller.getVisibleRegion();
    _reorderPlacesByViewport(bounds);
  }

  /// Partitions the master list into [Tapped, Visible, Others] without destroying master order
  Future<void> _reorderPlacesByViewport(LatLngBounds bounds, {String? priorityId}) async {
    if (_masterPlaces.isEmpty) return;

    final List<Map<String, dynamic>> priority = [];
    final List<Map<String, dynamic>> visible = [];
    final List<Map<String, dynamic>> hidden = [];

    final activePriorityId = priorityId ?? _tappedPlaceId;

    for (var p in _masterPlaces) {
      final String id = p['id'];
      final lat = p['location']['latitude'] as double;
      final lng = p['location']['longitude'] as double;
      final pos = LatLng(lat, lng);
      final isVisible = bounds.contains(pos);

      if (id == activePriorityId && isVisible) {
        priority.add(p);
      } else if (isVisible) {
        visible.add(p);
      } else {
        hidden.add(p);
      }
    }

    final List<Map<String, dynamic>> combined = [...priority, ...visible, ...hidden];

    // Stability check: Only update if the order actually changed
    bool changed = _displayedPlaces.length != combined.length;
    if (!changed) {
      for (int i = 0; i < combined.length; i++) {
        if (combined[i]['id'] != _displayedPlaces[i]['id']) {
          changed = true;
          break;
        }
      }
    }

    if (changed) {
      setState(() {
        _displayedPlaces = combined;
      });
      _updateMarkers(); 
      
      // Post-frame scroll to start
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(0, 
            duration: const Duration(milliseconds: 400), 
            curve: Curves.easeOutCubic);
        }
      });
    }
  }

  Future<void> _updateMarkers() async {
    final Set<Marker> newMarkers = {};
    final markerIcon = await _getCustomMarker(context, _currentZoom);

    // Markers are built from the master list to ensure all pins are shown regardless of card order
    for (var p in _masterPlaces) {
      final lat = p['location']['latitude'] as double;
      final lng = p['location']['longitude'] as double;
      newMarkers.add(
        Marker(
          markerId: MarkerId(p['id']),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: p['displayName']['text']),
          onTap: () => _onMarkerTapped(p['id']),
          icon: markerIcon,
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  void _onMarkerTapped(String placeId) async {
    setState(() => _tappedPlaceId = placeId);
    final controller = await _controller.future;
    final bounds = await controller.getVisibleRegion();
    _reorderPlacesByViewport(bounds, priorityId: placeId);
  }

  Future<void> _toggleFavorite(Map<String, dynamic> place) async {
    final l10n = AppLocalizations.of(context)!;
    final String? placeId = place['id']?.toString();
    
    if (placeId == null) {
      debugPrint("⚠️ [ExploreMapPage] Cannot toggle favorite: placeId is null");
      return;
    }

    final bool isFavorited = _favoritePlaceIds.contains(placeId);
    debugPrint("📱 [ExploreMapPage] Toggling favorite for $placeId. Currently favorited: $isFavorited");

    // Optimistic UI update
    setState(() {
      if (isFavorited) {
        _favoritePlaceIds.remove(placeId);
      } else {
        _favoritePlaceIds.add(placeId);
      }
    });

    try {
      if (isFavorited) {
        await FavoriteService().removeFavoritePlace(placeId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.removedFromFavorites)),
          );
        }
      } else {
        await FavoriteService().addFavoritePlace(
          place: place,
          source: "explore",
          visited: false,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.addedToFavorites)),
          );
        }
      }
    } catch (e) {
      debugPrint("❌ [ExploreMapPage] Error in _toggleFavorite: $e");
      
      // Revert optimistic UI update on error
      setState(() {
        if (isFavorited) {
          _favoritePlaceIds.add(placeId);
        } else {
          _favoritePlaceIds.remove(placeId);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _onCameraIdle() async {
    _debounceSync?.cancel();
    _debounceSync = Timer(const Duration(milliseconds: 300), () async {
      final controller = await _controller.future;
      final LatLngBounds bounds = await controller.getVisibleRegion();
      final LatLng center = LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
      );

      // 1. Check if we need to fetch new data (moved > 1.5km)
      bool needsFetch = false;
      if (_lastFetchedCenter == null) {
        needsFetch = true;
      } else {
        final dist = _calculateDistance(_lastFetchedCenter!, center);
        if (dist > 1500) needsFetch = true;
      }

      if (needsFetch) {
        _fetchPlaces(center);
      } else {
        // 2. Just reorder existing ones based on the new viewport
        _reorderPlacesByViewport(bounds);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
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
                if (AppColors.isDark(context)) {
                  controller.setMapStyle(_darkMapStyle);
                }
              },
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onCameraMove: (position) {
                final oldZoom = _currentZoom.round();
                final newZoom = position.zoom.round();
                if (oldZoom != newZoom) {
                  setState(() => _currentZoom = position.zoom);
                  _updateMarkers();
                }
              },
              onCameraIdle: _onCameraIdle,
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
                        backgroundColor: AppColors.getSurfaceElevated(context),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_ios_new_rounded,
                              color: AppColors.getTextPrimary(context),
                              size: 18),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.getSurfaceElevated(context),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                  color: AppColors.getShadow(context).withValues(alpha: 0.1),
                                  blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, color: AppColors.teal),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  onChanged: _onSearchChanged,
                                  onSubmitted: (val) => _performSearch(val),
                                  style: GoogleFonts.inter(
                                    color: AppColors.getTextPrimary(context),
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: l10n.isAr ? "ابحث عن أماكن..." : "Search for places...",
                                    hintStyle: GoogleFonts.inter(color: AppColors.getTextMuted(context)),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  icon: Icon(Icons.close_rounded, size: 18, color: AppColors.getTextMuted(context)),
                                  onPressed: _clearSearch,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              if (_isLoading)
                                const SizedBox(
                                  width: 16, height: 16,
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
                              setState(() {
                                _currentQuery = cat;
                                _tappedPlaceId = null;
                                _isManualSearch = false;
                                _searchController.clear();
                                _lastFetchedCenter = null; // Force fetch on category change
                              });
                              if (_currentCenter != null) _fetchPlaces(_currentCenter!);
                            }
                          },
                          backgroundColor: AppColors.getSurfaceElevated(context),
                          selectedColor: AppColors.teal,
                          labelStyle: GoogleFonts.inter(
                            color: isSelected ? Colors.white : AppColors.getTextSecondary(context),
                            fontSize: 12, fontWeight: FontWeight.bold,
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

          // 3. HORIZONTAL PLACES LIST
          Positioned(
            bottom: 40, left: 0, right: 0, height: 180,
            child: _displayedPlaces.isEmpty
                ? const SizedBox.shrink()
                : ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _displayedPlaces.length,
                    itemBuilder: (context, index) {
                      final p = _displayedPlaces[index];
                      final photoRef = (p['photos'] != null && p['photos'].isNotEmpty) 
                          ? p['photos'][0]['name'] : null;
                      final imageUrl = _mapsService.getPlacePhotoUrl(photoRef);

                      return Container(
                        width: 300, margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: AppColors.getSurfaceElevated(context),
                          borderRadius: BorderRadius.circular(24),
                          border: _tappedPlaceId == p['id'] ? Border.all(color: AppColors.teal, width: 2) : null,
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.getShadow(context).withValues(alpha: 0.1),
                                blurRadius: 15, offset: const Offset(0, 5))
                          ],
                        ),
                        child: Stack(
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                                  child: imageUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: imageUrl, width: 100, height: 180, fit: BoxFit.cover,
                                        )
                                      : Container(width: 100, color: AppColors.getSurface(context)),
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
                                            fontSize: 16, fontWeight: FontWeight.bold,
                                            color: AppColors.getTextPrimary(context),
                                          ),
                                          maxLines: 2, overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${p['rating'] ?? 'N/A'} (${p['userRatingCount'] ?? 0})",
                                              style: GoogleFonts.inter(
                                                  fontSize: 12, color: AppColors.getTextSecondary(context)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          p['formattedAddress'] ?? "",
                                          style: GoogleFonts.inter(
                                              fontSize: 11, color: AppColors.getTextSecondary(context)),
                                          maxLines: 2, overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Heart Button
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _toggleFavorite(p),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      _favoritePlaceIds.contains(p['id']) 
                                        ? Icons.favorite_rounded 
                                        : Icons.favorite_border_rounded,
                                      color: _favoritePlaceIds.contains(p['id']) 
                                        ? Colors.redAccent 
                                        : AppColors.getTextSecondary(context),
                                      size: 22,
                                    ),
                                  ),
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
