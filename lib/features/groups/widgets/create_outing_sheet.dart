// lib/features/groups/widgets/create_outing_sheet.dart

import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/colors.dart';
import '../data/services/outing_service.dart';
import 'outing_waiting_room_sheet.dart';
import '../pages/location_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/location_service.dart';
import 'package:laween/l10n/app_localizations.dart';

class CreateOutingSheet extends StatefulWidget {
  final String groupId;
  final bool initialDirectMode;

  const CreateOutingSheet({
    super.key,
    required this.groupId,
    this.initialDirectMode = false,
  });

  @override
  State<CreateOutingSheet> createState() => _CreateOutingSheetState();
}

class _CreateOutingSheetState extends State<CreateOutingSheet> {
  final OutingService _outingService = OutingService();
  String _calculationMode = 'Time'; // 'KM' or 'Time'
  String _category = 'Restaurant';
  int _timeLimit = 5; // 2, 5, 10
  bool _isCreating = false;
  bool _isScheduled = false;
  DateTime? _scheduledDateTime;

  // Direct Mode additions
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Map<String, dynamic>? _selectedVenue;
  bool _isDirectMode = false;
  String? _creatorName;
  Position? _userPosition;
  String? _apiKey;

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Restaurant',
      'icon': Icons.restaurant_rounded,
      'color': Colors.orange,
    },
    {'name': 'Cafe', 'icon': Icons.coffee_rounded, 'color': Colors.brown},
    {'name': 'Park', 'icon': Icons.park_rounded, 'color': Colors.green},
    {'name': 'Mall', 'icon': Icons.shopping_bag_rounded, 'color': Colors.blue},
    {
      'name': 'Sporty',
      'icon': Icons.sports_basketball_rounded,
      'color': Colors.red,
    },
    {'name': 'Cinema', 'icon': Icons.movie_rounded, 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    _isDirectMode = widget.initialDirectMode;
    _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    _fetchCreatorInfo();
    _fetchUserLocation();
  }

  void _fetchUserLocation() async {
    try {
      final pos = await LocationService().getCurrentPosition();
      if (mounted) {
        setState(() => _userPosition = pos);
      }
    } catch (e) {
      debugPrint("Error fetching location for sorting: $e");
    }
  }

  void _fetchCreatorInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _creatorName = data['name'] ?? data['fullName'] ?? user.displayName;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching creator info: $e");
    }
  }

  void _createSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Validation: If in Direct Mode, a venue MUST be selected from the list
    if (_isDirectMode && _selectedVenue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.selectSpecificLocation ??
                "Please select a specific location from the suggestions",
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final LatLng? pickedLocation = await Navigator.push<LatLng>(
        context,
        MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
      );

      if (pickedLocation == null) {
        if (mounted) setState(() => _isCreating = false);
        return;
      }

      String sessionId;
      if (_isDirectMode && _selectedVenue != null) {
        sessionId = await _outingService.createDirectSession(
          groupId: widget.groupId,
          creatorId: user.uid,
          creatorName: _creatorName ?? user.displayName ?? "Me",
          creatorPhotoUrl: user.photoURL,
          venue: _selectedVenue!,
          timeLimitMinutes: _timeLimit,
          creatorLocation: GeoPoint(
            pickedLocation.latitude,
            pickedLocation.longitude,
          ),
          scheduledAt: _isScheduled ? _scheduledDateTime : null,
        );
      } else {
        sessionId = await _outingService.createSession(
          groupId: widget.groupId,
          creatorId: user.uid,
          creatorName: _creatorName ?? user.displayName ?? "Me",
          creatorPhotoUrl: user.photoURL,
          category: _category,
          calculationMode: _calculationMode,
          timeLimitMinutes: _timeLimit,
          location: GeoPoint(pickedLocation.latitude, pickedLocation.longitude),
          scheduledAt: _isScheduled ? _scheduledDateTime : null,
        );
      }

      if (mounted) {
        Navigator.pop(context); // Close creation sheet

        // Both modes now go to the waiting room first
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => OutingWaitingRoomSheet(
            groupId: widget.groupId,
            sessionId: sessionId,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _searchPlaces(String query) async {
    // Invalidate selected venue as soon as the user starts typing again
    if (_selectedVenue != null) {
      setState(() => _selectedVenue = null);
    }

    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
      final url = Uri.parse(
        'https://places.googleapis.com/v1/places:searchText',
      );

      final Map<String, dynamic> body = {'textQuery': query};
      if (_userPosition != null) {
        body['locationBias'] = {
          'circle': {
            'center': {
              'latitude': _userPosition!.latitude,
              'longitude': _userPosition!.longitude,
            },
            'radius': 5000.0, // 5km bias for relevant results
          },
        };
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey ?? '',
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.photos',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> places = data['places'] ?? [];

        if (_userPosition != null) {
          for (var place in places) {
            final loc = place['location'];
            if (loc != null) {
              final double distance = Geolocator.distanceBetween(
                _userPosition!.latitude,
                _userPosition!.longitude,
                loc['latitude'],
                loc['longitude'],
              );
              place['distanceMeters'] = distance;
            }
          }
          // Sort by proximity
          places.sort(
            (a, b) => (a['distanceMeters'] ?? 999999).compareTo(
              b['distanceMeters'] ?? 999999,
            ),
          );
        }

        setState(() {
          _searchResults = places;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint("Search error: $e");
      setState(() => _isSearching = false);
    }
  }

  void _selectVenue(dynamic place) async {
    setState(() {
      _searchController.text = place['displayName']?['text'] ?? "";
      _searchResults = [];

      final loc = place['location'];
      final lat = loc?['latitude'];
      final lng = loc?['longitude'];

      _selectedVenue = {
        'id': place['id'],
        'name': place['displayName']?['text'],
        'address': place['formattedAddress'],
        'location': {'latitude': lat, 'longitude': lng},
        'rating': place['rating'],
        'userRatingCount': place['userRatingCount'],
        'distanceMeters': place['distanceMeters'],
        'photoReference':
            (place['photos'] != null && place['photos'].isNotEmpty)
            ? place['photos'][0]['name'] // V1 uses 'name' for photo reference
            : null,
        'category': _category,
      };
      _isDirectMode = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 18,
          bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Handle
            Center(
              child: Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar (Only shown in Direct Mode)
            if (_isDirectMode) ...[
              _buildSearchBar(),

              if (_searchResults.isNotEmpty) _buildSearchResults(),

              const SizedBox(height: 20),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isDirectMode
                          ? (AppLocalizations.of(context)?.directOuting ??
                              "Direct Outing")
                          : (AppLocalizations.of(context)?.createOuting ??
                              "Create Outing"),
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkSlate,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      _isDirectMode
                          ? (AppLocalizations.of(context)?.pickDestinationAndGo ??
                              "Pick a destination and let's go!")
                          : (AppLocalizations.of(context)?.findPerfectMidpoint ??
                              "Find the perfect mid-point"),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flash_on_rounded,
                    color: AppColors.teal,
                    size: 22,
                  ),
                ).animate().scale(
                  delay: 200.milliseconds,
                  duration: 400.milliseconds,
                  curve: Curves.easeOutBack,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Section 1: Mode (Hidden in Direct Mode as it's not needed for discovery)
            if (!_isDirectMode) ...[
              _buildSectionHeader(AppLocalizations.of(context)?.calculationMode ?? "Calculation Mode"),
              const SizedBox(height: 12),
              _buildModeSwitcher(),
              const SizedBox(height: 24),
            ],

            // Section 2: Category (Only shown in Discovery Mode)
            if (!_isDirectMode) ...[
              _buildSectionHeader(AppLocalizations.of(context)?.selectCategory ?? "Select Category"),
              const SizedBox(height: 12),
              SizedBox(
                height: 104,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) =>
                      _buildCategoryCard(_categories[index]),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Section 3: Time Limit
            _buildSectionHeader(AppLocalizations.of(context)?.joinTimeLimit ?? "Join Time Limit"),
            const SizedBox(height: 12),
            _buildTimeLimitRow(),

            const SizedBox(height: 24),

            // Section 4: Schedule
            _buildSectionHeader(AppLocalizations.of(context)?.scheduleSession ?? "Schedule Session"),
            const SizedBox(height: 12),
            _buildScheduleSection(),

            const SizedBox(height: 32),

            // Final Action
            _buildMainButton(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppColors.darkSlate.withOpacity(0.4),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildModeSwitcher() {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildModeOption("KM", Icons.social_distance_rounded, labelOverride: AppLocalizations.of(context)?.kmLabel),
          _buildModeOption("Time", Icons.timer_rounded, labelOverride: AppLocalizations.of(context)?.timeLabel),
        ],
      ),
    );
  }

  Widget _buildModeOption(String label, IconData icon, {String? labelOverride}) {
    final isSelected = _calculationMode == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _calculationMode = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.teal : Colors.grey.shade400,
              ),
              const SizedBox(width: 8),
              Text(
                labelOverride ?? label,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? AppColors.darkSlate
                      : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat) {
    final isSelected = _category == cat['name'];
    final color = cat['color'] as Color;

    return GestureDetector(
      onTap: () => setState(() => _category = cat['name']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 86,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.teal : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.teal.withOpacity(0.15)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(cat['icon'], color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              _getLocalizedCategory(cat['name'], context),
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: AppColors.darkSlate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeLimitRow() {
    return Row(
      children: [2, 5, 10].map((t) {
        final isSelected = _timeLimit == t;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _timeLimit = t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: t == 10 ? 0 : 12),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.darkSlate : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColors.darkSlate
                      : Colors.grey.shade200,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.darkSlate.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  "$t ${AppLocalizations.of(context)?.minLabel ?? 'min'}",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _searchPlaces,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)?.whereAreWeGoing ?? "Where are we going?",
          hintStyle: GoogleFonts.inter(
            color: Colors.grey.shade400,
            fontSize: 15,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.teal),
          suffixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.teal,
                    ),
                  ),
                )
              : (_searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchResults = [];
                            // Only switch back to Discovery if it wasn't the initial mode
                            if (!widget.initialDirectMode) {
                              _isDirectMode = false;
                            }
                            _selectedVenue = null;
                          });
                        },
                      )
                    : null),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _searchResults.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            indent: 76,
            endIndent: 16,
            color: Colors.grey.shade50,
          ),
          itemBuilder: (context, index) {
            final place = _searchResults[index];
            final name = place['displayName']?['text'] ?? "Unknown Place";
            final address = place['formattedAddress'] ?? "";
            final rating = place['rating']?.toDouble();
            final distanceMeters = place['distanceMeters'] as double?;

            String distanceText = "";
            if (distanceMeters != null) {
              if (distanceMeters < 1000) {
                distanceText = "${distanceMeters.toStringAsFixed(0)}m";
              } else {
                distanceText = "${(distanceMeters / 1000).toStringAsFixed(1)}km";
              }
            }

            return InkWell(
              onTap: () => _selectVenue(place),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child:
                            (place['photos'] != null &&
                                    place['photos'].isNotEmpty &&
                                    _apiKey != null)
                                ? CachedNetworkImage(
                                  imageUrl:
                                      'https://places.googleapis.com/v1/${place['photos'][0]['name']}/media?key=$_apiKey&maxWidthPx=100',
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => const Icon(
                                        Icons.location_on_rounded,
                                        color: AppColors.teal,
                                        size: 22,
                                      ),
                                  errorWidget:
                                      (context, url, error) => const Icon(
                                        Icons.location_on_rounded,
                                        color: AppColors.teal,
                                        size: 22,
                                      ),
                                )
                                : const Icon(
                                  Icons.location_on_rounded,
                                  color: AppColors.teal,
                                  size: 22,
                                ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkSlate,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (distanceText.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.teal.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    distanceText,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.teal,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            address,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (rating != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                ...List.generate(5, (i) {
                                  return Icon(
                                    Icons.star_rounded,
                                    color:
                                        i < rating.floor()
                                            ? Colors.amber
                                            : Colors.grey.shade200,
                                    size: 14,
                                  );
                                }),
                                const SizedBox(width: 6),
                                Text(
                                  rating.toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "(${place['userRatingCount'] ?? 0})",
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDirectMode
              ? [const Color(0xFF00C9A7), const Color(0xFF0097A7)]
              : AppColors.tealGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createSession,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isCreating
            ? const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isDirectMode
                        ? Icons.map_rounded
                        : Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isDirectMode
                        ? (AppLocalizations.of(context)?.startJourney ??
                            "Start Journey")
                        : (AppLocalizations.of(context)?.launchOutingSession ??
                            "Launch Outing Session"),
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isScheduled ? AppColors.teal.withOpacity(0.4) : Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (_isScheduled ? AppColors.teal : Colors.grey).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: _isScheduled ? AppColors.teal : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.scheduleForLater ?? "Schedule for Later",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkSlate,
                        ),
                      ),
                      Text(
                        _isScheduled
                            ? (AppLocalizations.of(context)?.outingSetForFuture ?? "Outing set for a future time")
                            : (AppLocalizations.of(context)?.offStartNow ?? "Off - Start the session now"),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch.adaptive(
                value: _isScheduled,
                activeColor: AppColors.teal,
                onChanged: (val) {
                  setState(() {
                    _isScheduled = val;
                    if (val && _scheduledDateTime == null) {
                      _scheduledDateTime = DateTime.now().add(const Duration(hours: 1));
                    }
                  });
                },
              ),
            ],
          ),
          if (_isScheduled) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(height: 1),
            ),
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _scheduledDateTime ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.teal,
                          onPrimary: Colors.white,
                          onSurface: AppColors.darkSlate,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null && mounted) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_scheduledDateTime ?? DateTime.now()),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.teal,
                            onPrimary: Colors.white,
                            onSurface: AppColors.darkSlate,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (time != null && mounted) {
                    setState(() {
                      _scheduledDateTime = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _scheduledDateTime != null
                          ? "${_scheduledDateTime!.day}/${_scheduledDateTime!.month}/${_scheduledDateTime!.year}  at  ${_scheduledDateTime!.hour}:${_scheduledDateTime!.minute.toString().padLeft(2, '0')}"
                          : (AppLocalizations.of(context)?.tapToPickDateTime ?? "Tap to pick Date & Time"),
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.teal,
                      ),
                    ),
                    const Icon(
                      Icons.edit_calendar_rounded,
                      color: AppColors.teal,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getLocalizedCategory(String name, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (name) {
      case 'Restaurant':
        return l10n?.restaurant ?? name;
      case 'Cafe':
        return l10n?.cafe ?? name;
      case 'Park':
        return l10n?.park ?? name;
      case 'Mall':
        return l10n?.mall ?? name;
      case 'Sporty':
        return l10n?.sporty ?? name;
      case 'Cinema':
        return l10n?.cinema ?? name;
      default:
        return name;
    }
  }
}

