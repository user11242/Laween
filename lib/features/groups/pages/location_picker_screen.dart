// lib/features/groups/pages/location_picker_screen.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/colors.dart';
import '../../../core/services/location_service.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  LatLng? _currentCenter;
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final pos = await _locationService.getCurrentPosition();
      if (pos != null) {
        if (mounted) {
          setState(() {
            _currentCenter = LatLng(pos.latitude, pos.longitude);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        // Default to a fallback if permission denied to let them manually drag
        setState(() {
          _currentCenter = const LatLng(25.2048, 55.2708); // Default coordinates
          _isLoading = false;
        });
      }
    }
  }

  void _onMyLocationPressed() async {
    try {
      final pos = await _locationService.getCurrentPosition();
      if (pos != null && _mapController != null) {
        final latLng = LatLng(pos.latitude, pos.longitude);
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
        setState(() {
          _currentCenter = latLng;
          _searchController.clear();
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }
    
    if (mounted) setState(() => _isSearching = true);
    
    try {
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
      final url = Uri.parse('https://places.googleapis.com/v1/places:searchText');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey!,
          'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.location',
        },
        body: jsonEncode({
          'textQuery': query,
          if (_currentCenter != null) 'locationBias': {
            'circle': {
              'center': {'latitude': _currentCenter!.latitude, 'longitude': _currentCenter!.longitude},
              'radius': 50000.0 // 50km radius bias
            }
          }
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _searchResults = data['places'] ?? [];
            _isSearching = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _currentCenter == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.teal)),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.darkSlate.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentCenter!, zoom: 16),
            myLocationEnabled: false, // We use a custom button
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) {
              _currentCenter = position.target;
            },
          ),
          
          // Center Pin Image
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40), // Offset so the pointy bit is at exact center
              child: Icon(
                Icons.location_on_rounded,
                size: 50,
                color: Colors.redAccent,
              ),
            ),
          ),

          // Search Bar Area
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      if (val.length > 2) {
                        _searchPlaces(val);
                      } else {
                        setState(() => _searchResults = []);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: "Search for a neighborhood or place...",
                      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: AppColors.teal),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final place = _searchResults[index];
                        final name = place['displayName']?['text'] ?? "Unknown Place";
                        final address = place['formattedAddress'] ?? "";
                        return ListTile(
                          leading: const Icon(Icons.location_on_rounded, color: AppColors.teal),
                          title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(address, style: GoogleFonts.inter(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () {
                            final loc = place['location'];
                            if (loc != null) {
                              final latLng = LatLng(loc['latitude'], loc['longitude']);
                              _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
                              setState(() {
                                _currentCenter = latLng;
                                _searchResults = [];
                                _searchController.text = name;
                              });
                              FocusScope.of(context).unfocus();
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Action Area
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton(
                  backgroundColor: AppColors.darkSlate,
                  onPressed: _onMyLocationPressed,
                  child: const Icon(Icons.my_location_rounded, color: AppColors.teal),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _currentCenter);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 5,
                    ),
                    child: Text(
                      "Confirm Start Location",
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
