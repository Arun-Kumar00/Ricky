// lib/map_picker_screen.dart

// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// class MapPickerScreen extends StatefulWidget {
//   const MapPickerScreen({super.key});

//   @override
//   State<MapPickerScreen> createState() => _MapPickerScreenState();
// }

// class _MapPickerScreenState extends State<MapPickerScreen> {
//   // Initial location set to Mansa, Punjab
//   static const _initialPosition = LatLng(29.9902, 75.3941);
//   LatLng _pickedLocation = _initialPosition;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Pick Your Location'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.check),
//             onPressed: () {
//               // Return the selected location back to the profile screen
//               Navigator.of(context).pop(_pickedLocation);
//             },
//           ),
//         ],
//       ),
//       body: GoogleMap(
//         initialCameraPosition: const CameraPosition(
//           target: _initialPosition,
//           zoom: 16.0,
//         ),
//         onTap: (position) {
//           setState(() {
//             _pickedLocation = position;
//           });
//         },
//         markers: {
//           Marker(
//             markerId: const MarkerId('picked-location'),
//             position: _pickedLocation,
//             infoWindow: const InfoWindow(title: 'My Restaurant'),
//             icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//           ),
//         },
//       ),
//     );
//   }
// }
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'package:uuid/uuid.dart';
//
// // IMPORTANT: Replace this with your own Google Maps API Key
// const String googleMapsApiKey = "AIzaSyBRaty5Cs4xkv1dgudw_mS0PYyMxms4HFQ";
//
// class MapPickerScreen extends StatefulWidget {
//   const MapPickerScreen({super.key});
//
//   @override
//   State<MapPickerScreen> createState() => _MapPickerScreenState();
// }
//
// class _MapPickerScreenState extends State<MapPickerScreen> {
//   final _searchController = TextEditingController();
//   GoogleMapController? _mapController;
//
//   // Initial location (e.g., center of Delhi)
//   static const _initialPosition = LatLng(28.6139, 77.2090);
//   LatLng _pickedLocation = _initialPosition;
//
//   // State for address search
//   List<dynamic> _addressSuggestions = [];
//   Timer? _debounce;
//   String _sessionToken = Uuid().v4();
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     _debounce?.cancel();
//     super.dispose();
//   }
//
//   Future<void> _fetchAddressSuggestions(String input) async {
//     final url = Uri.parse('https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&sessiontoken=$_sessionToken&key=$googleMapsApiKey');
//     final response = await http.get(url);
//     if (mounted && response.statusCode == 200) {
//       setState(() {
//         _addressSuggestions = json.decode(response.body)['predictions'];
//       });
//     }
//   }
//
//   Future<void> _selectAddress(String placeId) async {
//     final detailsUrl = Uri.parse('https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&sessiontoken=$_sessionToken&key=$googleMapsApiKey');
//     final response = await http.get(detailsUrl);
//     if (mounted && response.statusCode == 200) {
//       final details = json.decode(response.body)['result'];
//       final location = details['geometry']['location'];
//       final newPosition = LatLng(location['lat'], location['lng']);
//
//       setState(() {
//         _pickedLocation = newPosition;
//         _addressSuggestions = []; // Clear suggestions
//         _searchController.clear(); // Clear search bar
//         _sessionToken = Uuid().v4(); // Reset session token for next search
//       });
//
//       // Animate map to the new location
//       _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newPosition, 16.0));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Pick Your Location'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.check),
//             onPressed: () {
//               // Return the selected location back to the profile screen
//               Navigator.of(context).pop(_pickedLocation);
//             },
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           // Google Map
//           GoogleMap(
//             onMapCreated: (controller) => _mapController = controller,
//             initialCameraPosition: const CameraPosition(
//               target: _initialPosition,
//               zoom: 12.0,
//             ),
//             onTap: (position) {
//               setState(() {
//                 _pickedLocation = position;
//               });
//             },
//             markers: {
//               Marker(
//                 markerId: const MarkerId('picked-location'),
//                 position: _pickedLocation,
//                 infoWindow: const InfoWindow(title: 'Selected Location'),
//                 icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
//               ),
//             },
//           ),
//           // Search Bar and Suggestions
//           Positioned(
//             top: 10,
//             left: 15,
//             right: 15,
//             child: Column(
//               children: [
//                 Material(
//                   elevation: 4.0,
//                   borderRadius: BorderRadius.circular(8.0),
//                   child: TextField(
//                     controller: _searchController,
//                     decoration: InputDecoration(
//                       hintText: 'Search for an address...',
//                       prefixIcon: const Icon(Icons.search),
//                       border: InputBorder.none,
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//                       suffixIcon: _searchController.text.isNotEmpty
//                           ? IconButton(
//                               icon: const Icon(Icons.clear),
//                               onPressed: () {
//                                 setState(() {
//                                   _searchController.clear();
//                                   _addressSuggestions = [];
//                                 });
//                               },
//                             )
//                           : null,
//                     ),
//                     onChanged: (value) {
//                       if (_debounce?.isActive ?? false) _debounce!.cancel();
//                       _debounce = Timer(const Duration(milliseconds: 500), () {
//                         if (value.isNotEmpty) {
//                           _fetchAddressSuggestions(value);
//                         } else {
//                           setState(() => _addressSuggestions = []);
//                         }
//                       });
//                     },
//                   ),
//                 ),
//                 if (_addressSuggestions.isNotEmpty)
//                   Material(
//                     elevation: 4.0,
//                     borderRadius: BorderRadius.circular(8.0),
//                     child: SizedBox(
//                       height: 200,
//                       child: ListView.builder(
//                         itemCount: _addressSuggestions.length,
//                         itemBuilder: (context, index) => ListTile(
//                           title: Text(_addressSuggestions[index]['description']),
//                           onTap: () => _selectAddress(_addressSuggestions[index]['place_id']),
//                         ),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

const String googleMapsApiKey = "YOUR_API_KEY_HERE";

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final _searchController = TextEditingController();
  GoogleMapController? _mapController;

  static const LatLng _defaultPosition = LatLng(28.6139, 77.2090);
  LatLng _pickedLocation = _defaultPosition;

  List<dynamic> _addressSuggestions = [];
  Timer? _debounce;
  String _sessionToken = Uuid().v4();

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _pickedLocation = LatLng(position.latitude, position.longitude);
      });

      // move camera to user location
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_pickedLocation, 16));
    } else {
      // permission denied → stay at default position
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission denied")),
      );
    }
  }

  Future<void> _fetchAddressSuggestions(String input) async {
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&sessiontoken=$_sessionToken&key=$googleMapsApiKey');
    final response = await http.get(url);
    if (mounted && response.statusCode == 200) {
      setState(() {
        _addressSuggestions = json.decode(response.body)['predictions'];
      });
    }
  }

  Future<void> _selectAddress(String placeId) async {
    final detailsUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&sessiontoken=$_sessionToken&key=$googleMapsApiKey');
    final response = await http.get(detailsUrl);
    if (mounted && response.statusCode == 200) {
      final details = json.decode(response.body)['result'];
      final location = details['geometry']['location'];
      final newPosition = LatLng(location['lat'], location['lng']);

      setState(() {
        _pickedLocation = newPosition;
        _addressSuggestions = [];
        _searchController.clear();
        _sessionToken = Uuid().v4();
      });

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newPosition, 16.0));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Your Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.of(context).pop(_pickedLocation);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _pickedLocation,
              zoom: 12.0,
            ),
            onTap: (position) {
              setState(() {
                _pickedLocation = position;
              });
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: {
              Marker(
                markerId: const MarkerId('picked-location'),
                position: _pickedLocation,
                infoWindow: const InfoWindow(title: 'Selected Location'),
              ),
            },
          ),
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: Column(
              children: [
                Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for an address...',
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _addressSuggestions = [];
                          });
                        },
                      )
                          : null,
                    ),
                    onChanged: (value) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        if (value.isNotEmpty) {
                          _fetchAddressSuggestions(value);
                        } else {
                          setState(() => _addressSuggestions = []);
                        }
                      });
                    },
                  ),
                ),
                if (_addressSuggestions.isNotEmpty)
                  Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(8.0),
                    child: SizedBox(
                      height: 200,
                      child: ListView.builder(
                        itemCount: _addressSuggestions.length,
                        itemBuilder: (context, index) => ListTile(
                          title: Text(_addressSuggestions[index]['description']),
                          onTap: () => _selectAddress(_addressSuggestions[index]['place_id']),
                        ),
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
