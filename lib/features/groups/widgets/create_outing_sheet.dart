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
import '../../../core/theme/colors.dart';
import '../data/services/outing_service.dart';
import 'outing_waiting_room_sheet.dart';
import '../pages/location_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  
  // Direct Mode additions
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Map<String, dynamic>? _selectedVenue;
  bool _isDirectMode = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Restaurant', 'icon': Icons.restaurant_rounded, 'color': Colors.orange},
    {'name': 'Cafe', 'icon': Icons.coffee_rounded, 'color': Colors.brown},
    {'name': 'Park', 'icon': Icons.park_rounded, 'color': Colors.green},
    {'name': 'Mall', 'icon': Icons.shopping_bag_rounded, 'color': Colors.blue},
    {'name': 'Sporty', 'icon': Icons.sports_basketball_rounded, 'color': Colors.red},
    {'name': 'Cinema', 'icon': Icons.movie_rounded, 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    _isDirectMode = widget.initialDirectMode;
  }

  void _createSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Validation: If in Direct Mode, a venue MUST be selected from the list
    if (_isDirectMode && _selectedVenue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a specific location from the suggestions"),
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
          creatorName: user.displayName ?? "User",
          creatorPhotoUrl: user.photoURL,
          venue: _selectedVenue!,
          timeLimitMinutes: _timeLimit,
          creatorLocation: GeoPoint(pickedLocation.latitude, pickedLocation.longitude),
        );
      } else {
        sessionId = await _outingService.createSession(
          groupId: widget.groupId,
          creatorId: user.uid,
          creatorName: user.displayName ?? "User",
          creatorPhotoUrl: user.photoURL,
          category: _category,
          calculationMode: _calculationMode,
          timeLimitMinutes: _timeLimit,
          location: GeoPoint(pickedLocation.latitude, pickedLocation.longitude),
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
      final url = Uri.parse('https://places.googleapis.com/v1/places:searchText');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': apiKey ?? '',
          'X-Goog-FieldMask': 'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.photos',
        },
        body: jsonEncode({
          'textQuery': query,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _searchResults = data['places'] ?? [];
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
        'photoReference': (place['photos'] != null && place['photos'].isNotEmpty) 
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
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
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
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Search Bar (Only shown in Direct Mode)
            if (_isDirectMode) ...[
              _buildSearchBar(),
              
              if (_searchResults.isNotEmpty)
                _buildSearchResults(),

              const SizedBox(height: 32),
            ],
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isDirectMode ? "Direct Outing" : "Create Outing",
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkSlate,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      _isDirectMode ? "Pick a destination and let's go!" : "Find the perfect mid-point",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flash_on_rounded, color: AppColors.teal, size: 24),
                ).animate().scale(delay: 200.milliseconds, duration: 400.milliseconds, curve: Curves.easeOutBack),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Section 1: Mode (Hidden in Direct Mode as it's not needed for discovery)
            if (!_isDirectMode) ...[
              _buildSectionHeader("Calculation Mode"),
              const SizedBox(height: 16),
              _buildModeSwitcher(),
              const SizedBox(height: 32),
            ],
            
            // Section 2: Category (Only shown in Discovery Mode)
            if (!_isDirectMode) ...[
              _buildSectionHeader("Select Category"),
              const SizedBox(height: 16),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) => _buildCategoryCard(_categories[index]),
                ),
              ),
              const SizedBox(height: 40),
            ],
            
            // Section 3: Time Limit
            _buildSectionHeader("Join Time Limit"),
            const SizedBox(height: 16),
            _buildTimeLimitRow(),
            
            const SizedBox(height: 48),
            
            // Final Action
            _buildMainButton(),
            const SizedBox(height: 12),
          ],
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
        color: AppColors.darkSlate.withValues(alpha: 0.4),
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
          _buildModeOption("KM", Icons.social_distance_rounded),
          _buildModeOption("Time", Icons.timer_rounded),
        ],
      ),
    );
  }

  Widget _buildModeOption(String label, IconData icon) {
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
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon, 
                size: 20, 
                color: isSelected ? AppColors.teal : Colors.grey.shade400
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.darkSlate : Colors.grey.shade400,
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
        width: 100,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? AppColors.teal : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? AppColors.teal.withValues(alpha: 0.15) 
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(cat['icon'], color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              cat['name'],
              style: GoogleFonts.outfit(
                fontSize: 14,
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
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.darkSlate : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected ? AppColors.darkSlate : Colors.grey.shade200,
                  width: 1.5,
                ),
                boxShadow: isSelected ? [
                   BoxShadow(
                    color: AppColors.darkSlate.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ] : [],
              ),
              child: Center(
                child: Text(
                  "$t min",
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _searchPlaces,
        decoration: InputDecoration(
          hintText: "Where are we going?",
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 15),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.teal),
          suffixIcon: _isSearching 
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final place = _searchResults[index];
          final name = place['displayName']?['text'] ?? "Unknown Place";
          return ListTile(
            leading: const Icon(Icons.location_on_outlined, color: AppColors.teal),
            title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => _selectVenue(place),
          );
        },
      ),
    );
  }

  Widget _buildMainButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDirectMode ? [const Color(0xFF00C9A7), const Color(0xFF0097A7)] : AppColors.tealGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.4),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: _isCreating
            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isDirectMode ? Icons.map_rounded : Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    _isDirectMode ? "Start Journey" : "Launch Outing Session",
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
}
