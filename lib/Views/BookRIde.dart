//
//
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:ricky/Views/order_status_screen.dart';
// import 'package:ricky/map_picker_screen_with_search.dart';
// import 'package:geolocator/geolocator.dart'; // Re-added for location services
// import 'package:http/http.dart' as http; // For reverse geocoding
//
// // NOTE: Make sure this key has "Geocoding API" enabled in your Google Cloud Console.
// const String googleMapsApiKey = "AIzaSyBRaty5Cs4xkv1dgudw_mS0PYyMxms4HFQ";
//
// class BookRideScreen extends StatefulWidget {
//   const BookRideScreen({super.key});
//
//   @override
//   State<BookRideScreen> createState() => _BookRideScreenState();
// }
//
// class _BookRideScreenState extends State<BookRideScreen> {
//   final DatabaseReference _db = FirebaseDatabase.instance.ref();
//
//   String? _pickupAddress;
//   LatLng? _pickupLocation;
//
//   String? _userName;
//   LatLng? _homeLocation;
//   String? _homeAddress;
//
//   String? _selectedTier;
//   double _price = 0.0;
//   bool _isPlacingOrder = false;
//   bool _isLoading = true;
//
//   // A default location to use if permission is denied or location fails.
//   static const LatLng _delhiLocation = LatLng(28.7041, 77.1025);
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeScreen();
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//   }
//
//   /// The main initialization function.
//   Future<void> _initializeScreen() async {
//     // First, try to fetch user details (including home address).
//     await _fetchUserDetails();
//     // If no home address was set as the pickup, then get the user's current location.
//     if (_pickupLocation == null) {
//       await _getCurrentLocationAsPickup();
//     }
//     if (mounted) {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   /// Fetches the address for a given LatLng using Google's Geocoding API.
//   Future<String> _getAddressFromLatLng(LatLng position) async {
//     final baseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
//     String url =
//         '$baseUrl?latlng=${position.latitude},${position.longitude}&key=$googleMapsApiKey';
//     try {
//       final response = await http.get(Uri.parse(url));
//       if (response.statusCode == 200) {
//         final result = json.decode(response.body);
//         if (result['status'] == 'OK' && result['results'].isNotEmpty) {
//           return result['results'][0]['formatted_address'];
//         }
//       }
//       return "Address not found";
//     } catch (e) {
//       return "Could not fetch address";
//     }
//   }
//
//   /// Gets the user's current GPS location and sets it as the default pickup.
//   Future<void> _getCurrentLocationAsPickup() async {
//     bool serviceEnabled;
//     LocationPermission permission;
//
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _setDefaultLocation("Location services are disabled.");
//       return;
//     }
//
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         _setDefaultLocation("Location permissions are denied.");
//         return;
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       _setDefaultLocation("Location permissions are permanently denied.");
//       return;
//     }
//
//     try {
//       final position = await Geolocator.getCurrentPosition();
//       final currentLatLng = LatLng(position.latitude, position.longitude);
//       final address = await _getAddressFromLatLng(currentLatLng);
//       if (mounted) {
//         setState(() {
//           _pickupLocation = currentLatLng;
//           _pickupAddress = address;
//         });
//       }
//     } catch (e) {
//       _setDefaultLocation("Failed to get current location.");
//     }
//   }
//
//   /// Sets a default location (Delhi) if the current location cannot be fetched.
//   void _setDefaultLocation(String message) {
//     if (mounted) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text(message)));
//       setState(() {
//         _pickupLocation = _delhiLocation;
//         _pickupAddress = "Delhi, India"; // A default address
//       });
//     }
//   }
//
//   Future<void> _fetchUserDetails() async {
//     final userId = FirebaseAuth.instance.currentUser!.uid;
//     final snapshot = await _db.child('restaurants/$userId/profile').get();
//
//     if (mounted && snapshot.exists) {
//       final data = Map<String, dynamic>.from(snapshot.value as Map);
//       _userName = data['name'];
//
//       if (data.containsKey('address') && data.containsKey('location')) {
//         _homeAddress = data['address'];
//         _homeLocation = LatLng(
//           data['location']['latitude'],
//           data['location']['longitude'],
//         );
//         _setPickupToHome();
//       }
//     }
//   }
//
//   void _setPickupToHome() {
//     if (_homeLocation != null && _homeAddress != null) {
//       setState(() {
//         _pickupLocation = _homeLocation;
//         _pickupAddress = _homeAddress!;
//       });
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('No home address saved in your profile.')),
//       );
//     }
//   }
//
//   void _openMapPicker() async {
//     final result = await Navigator.of(context).push<Map<String, dynamic>>(
//       MaterialPageRoute(builder: (ctx) => const MapPickerWithSearchScreen()),
//     );
//
//     if (result != null) {
//       final pickedLocation = result['location'] as LatLng;
//       final address = result['address'] as String;
//       setState(() {
//         _pickupLocation = pickedLocation;
//         _pickupAddress = address;
//       });
//     }
//   }
//
//   void _placeOrder() async {
//     if (_pickupLocation == null || _pickupAddress == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please select a pickup location.')),
//       );
//       return;
//     }
//
//     setState(() {
//       _isPlacingOrder = true;
//     });
//     final orderRef = _db.child('orders').push();
//
//     final Map<String, dynamic> orderData = {
//       'restaurantId': FirebaseAuth.instance.currentUser!.uid,
//       'restaurantName': _userName,
//       'restaurantLocation': {
//         'latitude': _pickupLocation!.latitude,
//         'longitude': _pickupLocation!.longitude
//       },
//       'pickupAddress': _pickupAddress!.trim(),
//       'price': _price,
//       'status': 'pending',
//       'riderId': null,
//       'createdAt': ServerValue.timestamp,
//       'orderType': 'tier',
//       'deliveryTier': _selectedTier,
//     };
//
//     await orderRef.set(orderData);
//
//     if (mounted) {
//       Navigator.of(context).pushReplacement(MaterialPageRoute(
//         builder: (ctx) => OrderStatusScreen(orderId: orderRef.key!),
//       ));
//     }
//   }
//
//   Widget _buildLocationPicker() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Set Your Pickup Location',
//           style: Theme.of(context).textTheme.titleLarge,
//         ),
//         const SizedBox(height: 16),
//         Stack(
//           alignment: Alignment.center,
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(12.0),
//               child: SizedBox(
//                 height: 200,
//                 child: GoogleMap(
//                   liteModeEnabled: true,
//                   initialCameraPosition: CameraPosition(
//                     target: _pickupLocation ?? _delhiLocation,
//                     zoom: 15,
//                   ),
//                   myLocationButtonEnabled: false,
//                   zoomControlsEnabled: false,
//                   zoomGesturesEnabled: false,
//                   scrollGesturesEnabled: false,
//                   markers: {
//                     if (_pickupLocation != null)
//                       Marker(
//                         markerId: const MarkerId('pickupLocation'),
//                         position: _pickupLocation!,
//                       ),
//                   },
//                 ),
//               ),
//             ),
//             Positioned.fill(
//               child: Material(
//                 color: Colors.transparent,
//                 child: InkWell(
//                   borderRadius: BorderRadius.circular(12.0),
//                   onTap: _openMapPicker,
//                   splashColor: Colors.black.withOpacity(0.1),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         Column(
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.location_on,
//                     color: Theme.of(context).primaryColor),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     _pickupAddress ?? 'Loading location...',
//                     style: const TextStyle(fontSize: 16),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 TextButton.icon(
//                   icon: const Icon(Icons.my_location),
//                   label: const Text('Current'),
//                   onPressed: _getCurrentLocationAsPickup,
//                 ),
//                 if (_homeAddress != null)
//                   TextButton.icon(
//                     icon: const Icon(Icons.home),
//                     label: const Text('Home'),
//                     onPressed: _setPickupToHome,
//                   ),
//               ],
//             )
//           ],
//         )
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final bool canPlaceOrder =
//         !_isPlacingOrder && _selectedTier != null && _pickupLocation != null;
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('Book a Rickshaw')),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Card(
//               margin: EdgeInsets.zero,
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: _buildLocationPicker(),
//               ),
//             ),
//             const SizedBox(height: 24),
//             DropdownButtonFormField<String>(
//               value: _selectedTier,
//               hint: const Text('Select a distance tier'),
//               decoration: const InputDecoration(
//                 labelText: 'Delivery Distance',
//                 border: OutlineInputBorder(),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   _selectedTier = value;
//                   if (value == '1km')
//                     _price = 20.0;
//                   else if (value == '2.5km')
//                     _price = 30.0;
//                   else
//                     _price = 20.0;
//                 });
//               },
//               items: const [
//                 DropdownMenuItem(
//                     value: '0.5km',
//                     child: Text('Nearby Metro (₹20)')),
//                 DropdownMenuItem(
//                     value: '1km', child: Text('Upto 1 km (₹20)')),
//                 DropdownMenuItem(
//                     value: '2.5km',
//                     child: Text('Upto 2.5 km (₹30)')),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Text(
//                   'Final Price: ₹${_price.toStringAsFixed(2)}',
//                   textAlign: TextAlign.center,
//                   style: Theme.of(context)
//                       .textTheme
//                       .headlineSmall
//                       ?.copyWith(fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: canPlaceOrder ? _placeOrder : null,
//               style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   backgroundColor: Theme.of(context).primaryColor,
//                   foregroundColor: Colors.white),
//               child: _isPlacingOrder
//                   ? const CircularProgressIndicator(color: Colors.white)
//                   : const Text('Place Order'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:ricky/Views/order_status_screen.dart';

class BookRideScreen extends StatefulWidget {
  const BookRideScreen({super.key});

  @override
  State<BookRideScreen> createState() => _BookRideScreenState();
}

class _BookRideScreenState extends State<BookRideScreen> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // --- NEW STATE VARIABLES FOR FIXED ROUTES ---
  String? _selectedPickup;
  String? _selectedDrop;
  int? _selectedPersons; // Using int for 1 or 2 persons

  String? _userName;
  double _price = 0.0;
  bool _isPlacingOrder = false;
  bool _isLoading = true;

  // --- STATIC LISTS FOR LOCATIONS ---
  // Updated with the locations you provided.
  final List<String> _pickupLocations = [
    'Gupta chowk vijay nagar',
    'Gtb nagar metro gate no 4',
    'Old gupta colony',
    'New gupta colony',
    'Aparna hostel',
    'Vijay no gate 2 double story',
    'Vijay nagar 1 double story',
    'Single story gurudwara',
  ];
  final List<String> _dropLocations = [
    'Gayatri namkeen',
    'Patel chest',
    'Metro gate 4',
    'Mukharjee nagar',
    'Batra cinema',
    'Gandhi vihar',
    'Parmanand colony',
    'Derawal',
  ];

  @override
  void initState() {
    super.initState();
    // We still fetch user details to get their name for the order.
    _fetchUserDetails();
  }

  /// Fetches only the user's name from their profile.
  Future<void> _fetchUserDetails() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    // Using the original 'restaurants' path as requested
    final snapshot = await _db.child('restaurants/$userId/profile').get();

    if (mounted && snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      _userName = data['name'];
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Updates the price based on the number of selected persons.
  void _updatePrice(int? persons) {
    setState(() {
      _selectedPersons = persons;
      if (persons == 1) {
        _price = 20.0;
      } else if (persons == 2) {
        _price = 30.0;
      } else {
        _price = 0.0; // Reset if nothing is selected
      }
    });
  }

  /// Places the order with the new fixed-route details.
  void _placeOrder() async {
    // A final check to ensure all fields are selected.
    if (_selectedPickup == null ||
        _selectedDrop == null ||
        _selectedPersons == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all the details to continue.')),
      );
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });
    final orderRef = _db.child('orders').push();

    // The data map no longer contains LatLng, it uses the selected location strings.
    final Map<String, dynamic> orderData = {
      'restaurantId': FirebaseAuth.instance.currentUser!.uid,
      'restaurantName': _userName,
      'pickupAddress': _selectedPickup,
      'dropAddress': _selectedDrop,
      'persons': _selectedPersons,
      'price': _price,
      'status': 'pending',
      'riderId': null,
      'createdAt': ServerValue.timestamp,
      'orderType': 'fixed_route', // A new order type
    };

    await orderRef.set(orderData);

    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (ctx) => OrderStatusScreen(orderId: orderRef.key!),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    // The order can be placed only if all three dropdowns have a value.
    final bool canPlaceOrder = !_isPlacingOrder &&
        _selectedPickup != null &&
        _selectedDrop != null &&
        _selectedPersons != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Book a Rickshaw')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            Padding(
              padding: const EdgeInsets.all(10.0), // The padding is now here
              child: Text(
                'Pickup and drop are only on Stands',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                ),
              ),
            ),
            // --- PICKUP LOCATION DROPDOWN ---
            DropdownButtonFormField<String>(
              value: _selectedPickup,
              hint: const Text('Select Pickup Location'),
              decoration: const InputDecoration(
                labelText: 'From',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.my_location),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedPickup = value;
                });
              },
              items: _pickupLocations.map((location) {
                return DropdownMenuItem(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // --- DROP LOCATION DROPDOWN ---
            DropdownButtonFormField<String>(
              value: _selectedDrop,
              hint: const Text('Select Drop Location'),
              decoration: const InputDecoration(
                labelText: 'To',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              onChanged: (value) {
                setState(() {
                  _selectedDrop = value;
                });
              },
              items: _dropLocations.map((location) {
                return DropdownMenuItem(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // --- PERSONS DROPDOWN ---
            DropdownButtonFormField<int>(
              value: _selectedPersons,
              hint: const Text('Select Number of Persons'),
              decoration: const InputDecoration(
                labelText: 'Persons',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              onChanged: _updatePrice,
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 Person')),
                DropdownMenuItem(value: 2, child: Text('2 Persons')),
              ],
            ),
            const SizedBox(height: 24),

            // --- FINAL PRICE DISPLAY ---
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Final Price: ₹${_price.toStringAsFixed(2)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- PLACE ORDER BUTTON ---
            ElevatedButton(
              onPressed: canPlaceOrder ? _placeOrder : null,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white),
              child: _isPlacingOrder
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Place Order'),
            ),
          ],
        ),
      ),
    );
  }
}
