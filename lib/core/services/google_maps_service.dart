import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapsService {
  static final GoogleMapsService _instance = GoogleMapsService._internal();
  factory GoogleMapsService() => _instance;
  GoogleMapsService._internal();

  final String? _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

  /// Fetch accurate ETA and distance from Google Routes API (Compute Routes)
  Future<Map<String, dynamic>?> getETA({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    if (_apiKey == null) return null;

    final url = Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'routes.duration,routes.staticDuration,routes.distanceMeters',
        },
        body: jsonEncode({
          'origin': {
            'location': {'latLng': {'latitude': originLat, 'longitude': originLng}}
          },
          'destination': {
            'location': {'latLng': {'latitude': destLat, 'longitude': destLng}}
          },
          'travelMode': 'DRIVE',
          'routingPreference': 'TRAFFIC_AWARE',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          
          final durationStr = route['duration'] ?? route['staticDuration'] ?? "0s";
          final durationSeconds = int.tryParse(durationStr.replaceAll('s', '')) ?? 0;
          final distanceMeters = route['distanceMeters'] as int? ?? 0;

          return {
            'etaMinutes': (durationSeconds / 60).ceil(),
            'distanceKm': (distanceMeters / 1000).toDouble(),
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Bulk calculate distances and ETA using Compute Route Matrix
  Future<List<Map<String, dynamic>>> getRouteMatrix({
    required List<LatLng> origins,
    required List<LatLng> destinations,
  }) async {
    if (_apiKey == null || origins.isEmpty || destinations.isEmpty) return [];

    final url = Uri.parse('https://routes.googleapis.com/distanceMatrix/v2:computeRouteMatrix');

    final originWaypoints = origins.map((loc) => {
      'waypoint': {
        'location': {'latLng': {'latitude': loc.latitude, 'longitude': loc.longitude}}
      }
    }).toList();

    final destWaypoints = destinations.map((loc) => {
      'waypoint': {
        'location': {'latLng': {'latitude': loc.latitude, 'longitude': loc.longitude}}
      }
    }).toList();

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'originIndex,destinationIndex,status,distanceMeters,duration,staticDuration,condition',
        },
        body: jsonEncode({
          'origins': originWaypoints,
          'destinations': destWaypoints,
          'travelMode': 'DRIVE',
          'routingPreference': 'TRAFFIC_AWARE',
        }),
      );

      if (response.statusCode == 200) {
        var body = response.body;

        // 🔍 DEBUG — log first 800 chars of raw response to verify API shape
        debugPrint('[RouteMatrix] HTTP 200. Raw body (first 800): ${body.length > 800 ? body.substring(0, 800) : body}');

        // computeRouteMatrix returns a JSON array; if the body is newline-separated
        // objects (streaming), wrap them into a proper array.
        if (body.trim().startsWith('{')) {
          body = '[${body.replaceAll('}\n{', '},{')}]';
        }

        final List data = jsonDecode(body);
        debugPrint('[RouteMatrix] Parsed ${data.length} elements');

        return data.map((item) {
          final condition = item['condition'] as String? ?? '';
          final durationStr = item['duration'] ?? item['staticDuration'] ?? '0s';
          final durationSeconds = int.tryParse(durationStr.replaceAll('s', '')) ?? 0;
          final staticDurationStr = item['staticDuration'] ?? '0s';
          final staticDurationSeconds = int.tryParse(staticDurationStr.replaceAll('s', '')) ?? 0;

          // A route is available only when condition is explicitly ROUTE_EXISTS.
          // The previous check (status == null) was fragile — the API can return
          // status:{code:0} (meaning OK) even for valid routes, which made every
          // route appear unavailable.
          final routeAvailable = condition == 'ROUTE_EXISTS';

          debugPrint('[RouteMatrix] element: origin=${item['originIndex']} dest=${item['destinationIndex']} condition=$condition routeAvailable=$routeAvailable dist=${item['distanceMeters']} dur=${durationSeconds}s');

          return {
            'originIndex': item['originIndex'] ?? 0,
            'destinationIndex': item['destinationIndex'] ?? 0,
            'routeAvailable': routeAvailable,
            'distanceMeters': item['distanceMeters'] as int? ?? 0,
            'durationSeconds': durationSeconds,
            'staticDurationSeconds': staticDurationSeconds,
            'error': item['status']?['message'],
            'condition': condition,
          };
        }).toList();
      } else {
        debugPrint('[RouteMatrix] HTTP ${response.statusCode}: ${response.body}');
      }
      return [];
    } catch (e) {
      debugPrint('[RouteMatrix] Exception: $e');
      return [];
    }
  }

  /// Fetch the route polyline from Google Routes API
  Future<List<LatLng>?> getRoutePolyline({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    if (_apiKey == null) return null;

    final url = Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'routes.polyline.encodedPolyline',
        },
        body: jsonEncode({
          'origin': {
            'location': {'latLng': {'latitude': originLat, 'longitude': originLng}}
          },
          'destination': {
            'location': {'latLng': {'latitude': destLat, 'longitude': destLng}}
          },
          'travelMode': 'DRIVE',
          'routingPreference': 'TRAFFIC_AWARE',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final points = data['routes'][0]['polyline']['encodedPolyline'] as String;
          return _decodePolyline(points);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Decode polyline points
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  /// Generate a Google Places New Photo URL from a photo reference (resource name)
  String? getPlacePhotoUrl(String? photoReference, {int maxWidth = 400}) {
    if (_apiKey == null || photoReference == null) return null;
    // photoReference is expected to be in the format "places/PLACE_ID/photos/PHOTO_ID"
    return "https://places.googleapis.com/v1/$photoReference/media?key=$_apiKey&maxWidthPx=$maxWidth";
  }

  /// Search for places nearby using text query and location bias
  Future<List<Map<String, dynamic>>> searchPlacesNearby({
    required double latitude,
    required double longitude,
    required String query,
    double radius = 3000.0,
    int maxResults = 20,
  }) async {
    if (_apiKey == null) return [];

    final url = Uri.parse('https://places.googleapis.com/v1/places:searchText');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.rating,places.userRatingCount,places.photos,places.location,places.id,places.businessStatus',
        },
        body: jsonEncode({
          'textQuery': query,
          'locationBias': {
            'circle': {
              'center': {'latitude': latitude, 'longitude': longitude},
              'radius': radius,
            },
          },
          'maxResultCount': maxResults,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['places'] ?? []);
      }
    } catch (e) {
      debugPrint('[PlacesSearch] Error: $e');
    }
    return [];
  }
}

