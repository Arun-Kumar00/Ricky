// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:geolocator/geolocator.dart';
// import 'BookRIde.dart';
//
// class RestaurantHomeScreen extends StatefulWidget {
//   const RestaurantHomeScreen({super.key});
//
//   @override
//   State<RestaurantHomeScreen> createState() => _RestaurantHomeScreenState();
// }
//
// class _RestaurantHomeScreenState extends State<RestaurantHomeScreen> {
//   final DatabaseReference _db = FirebaseDatabase.instance.ref();
//   List<Map<String, dynamic>> _nearbyRiders = [];
//   Position? _currentPosition;
//   bool _loading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchNearbyRiders();
//   }
//
//   Future<void> _fetchNearbyRiders() async {
//     _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//
//     final ridersSnapshot = await _db.child('riders').get();
//     final List<Map<String, dynamic>> nearby = [];
//
//     if (ridersSnapshot.exists) {
//       for (final riderEntry in ridersSnapshot.children) {
//         final data = Map<String, dynamic>.from(riderEntry.value as Map);
//         if (data.containsKey('location')) {
//           final lat = data['location']['latitude'];
//           final lng = data['location']['longitude'];
//
//           final double distance = Geolocator.distanceBetween(
//             _currentPosition!.latitude,
//             _currentPosition!.longitude,
//             lat,
//             lng,
//           ) / 1000; // in km
//
//           if (distance <= 2.0) {
//             nearby.add({
//               'name': data['name'] ?? 'Rider',
//               'phone': data['phone'] ?? '',
//               'distance': distance.toStringAsFixed(2),
//             });
//           }
//         }
//       }
//     }
//
//     setState(() {
//       _nearbyRiders = nearby;
//       _loading = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Nearby Riders')),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator())
//           : _nearbyRiders.isEmpty
//           ? const Center(child: Text('No riders found within 2km'))
//           : ListView.builder(
//         itemCount: _nearbyRiders.length,
//         itemBuilder: (context, index) {
//           final rider = _nearbyRiders[index];
//           return ListTile(
//             leading: const Icon(Icons.motorcycle),
//             title: Text(rider['name']),
//             subtitle: Text('📞 ${rider['phone']} • 📍 ${rider['distance']} km'),
//           );
//         },
//       ),
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: ElevatedButton(
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (_) => const BookRideScreen()),
//             );
//           },
//           child: const Text('📦 Book Ride'),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

class NearbyRidersScreen extends StatefulWidget {
  const NearbyRidersScreen({super.key});

  @override
  State<NearbyRidersScreen> createState() => _NearbyRidersScreenState();
}

class _NearbyRidersScreenState extends State<NearbyRidersScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _nearbyRiders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchNearbyRiders();
  }

  Future<void> _fetchNearbyRiders() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final String restaurantId = FirebaseAuth.instance.currentUser!.uid;
      final restaurantSnapshot = await _db.child('restaurants/$restaurantId/profile').get();
      if (!restaurantSnapshot.exists) throw Exception("Profile not found.");

      final profileData = Map<String, dynamic>.from(restaurantSnapshot.value as Map);
      final locationData = profileData['location'];
      if (locationData == null) throw Exception("Location not set.");

      final double restaurantLat = locationData['latitude'];
      final double restaurantLng = locationData['longitude'];

      final ridersSnapshot = await _db.child('riders').get();
      final List<Map<String, dynamic>> nearby = [];

      if (ridersSnapshot.exists) {
        for (final riderEntry in ridersSnapshot.children) {
          final data = Map<String, dynamic>.from(riderEntry.value as Map);

          // Only show riders who are available and have a location
          if (data['isAvailable'] == true && data['location'] != null) {
            final lat = data['location']['latitude'];
            final lng = data['location']['longitude'];
            final double distance = Geolocator.distanceBetween(restaurantLat, restaurantLng, lat, lng) / 1000;

            if (distance <= 5.0) { // Using a 5km radius
              nearby.add({
                'name': data['name'] ?? 'Rider',
                'distance': distance.toStringAsFixed(2),
              });
            }
          }
        }
      }
      if (mounted) setState(() => _nearbyRiders = nearby);
    } catch (e) {
      debugPrint("Error fetching riders: $e");
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_nearbyRiders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No available riders found within 5km'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _fetchNearbyRiders,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchNearbyRiders,
      child: ListView.builder(
        itemCount: _nearbyRiders.length,
        itemBuilder: (context, index) {
          final rider = _nearbyRiders[index];
          return ListTile(
            leading: const Icon(Icons.motorcycle, color: Colors.green),
            title: Text(rider['name']),
            subtitle: Text('📍 ${rider['distance']} km away'),
          );
        },
      ),
    );
  }
}