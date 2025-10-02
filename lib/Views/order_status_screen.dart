//
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'dart:async';
//
// // NOTE: Replace with your actual Google Maps API Key
// const String googleMapsApiKey = "AIzaSyBRaty5Cs4xkv1dgudw_mS0PYyMxms4HFQ";
//
// class OrderStatusScreen extends StatefulWidget {
//   final String orderId;
//   const OrderStatusScreen({super.key, required this.orderId});
//
//   @override
//   State<OrderStatusScreen> createState() => _OrderStatusScreenState();
// }
//
// class _OrderStatusScreenState extends State<OrderStatusScreen> {
//   StreamSubscription? _orderSubscription;
//   StreamSubscription? _riderLocationSubscription;
//   String _status = 'pending';
//   String? _riderId;
//   String? _riderName;
//   String? _riderPhone;
//
//   GoogleMapController? _mapController;
//   final Set<Marker> _markers = {};
//   final Set<Polyline> _polylines = {};
//   Timer? _timeoutTimer;
//
//   @override
//   void initState() {
//     super.initState();
//     _listenToOrder();
//     _startTimeoutTimer();
//   }
//
//   @override
//   void dispose() {
//     _orderSubscription?.cancel();
//     _riderLocationSubscription?.cancel();
//     _timeoutTimer?.cancel();
//     _mapController?.dispose();
//     super.dispose();
//   }
//
//   void _startTimeoutTimer() {
//     _timeoutTimer = Timer(const Duration(minutes: 5), () {
//       if (mounted && _status == 'pending') {
//         FirebaseDatabase.instance
//             .ref('orders/${widget.orderId}')
//             .update({'status': 'cancelled'});
//
//         showDialog(
//           context: context,
//           barrierDismissible: false,
//           builder: (ctx) => AlertDialog(
//             title: const Text("Ricky Not Found"),
//             content: const Text(
//                 "Sorry, we couldn't find a delivery partner at this time."),
//             actions: [
//               TextButton(
//                 child: const Text("OK"),
//                 onPressed: () {
//                   Navigator.of(ctx).pop();
//                   Navigator.of(context).pop();
//                 },
//               ),
//             ],
//           ),
//         );
//       }
//     });
//   }
//
//   void _listenToOrder() {
//     _orderSubscription = FirebaseDatabase.instance
//         .ref('orders/${widget.orderId}')
//         .onValue
//         .listen((event) {
//       if (mounted && event.snapshot.exists) {
//         final data = Map<String, dynamic>.from(event.snapshot.value as Map);
//         final newStatus = data['status'];
//         final newRiderId = data['riderId'];
//
//         if (newStatus == 'completed' || newStatus == 'cancelled') {
//           _timeoutTimer?.cancel();
//           Navigator.of(context).pop(newStatus);
//           return;
//         }
//
//         if (newStatus != _status || newRiderId != _riderId) {
//           setState(() {
//             _status = newStatus;
//             _riderId = newRiderId;
//           });
//
//           if (_status == 'accepted' && _riderId != null) {
//             _timeoutTimer?.cancel();
//             _fetchRiderDetails();
//             _listenToRiderLocation(data['restaurantLocation']);
//           }
//         }
//       }
//     });
//   }
//
//   Future<void> _fetchRiderDetails() async {
//     if (_riderId == null) return;
//     final riderSnapshot =
//     await FirebaseDatabase.instance.ref('riders/$_riderId').get();
//     if (mounted && riderSnapshot.exists) {
//       final riderData = Map<String, dynamic>.from(riderSnapshot.value as Map);
//       setState(() {
//         _riderName = riderData['name'];
//         _riderPhone = riderData['phone'];
//       });
//     }
//   }
//
//   void _listenToRiderLocation(Map pickupLocationData) {
//     bool isFirstLocationUpdate = true;
//     final pickupLocation = LatLng(
//         pickupLocationData['latitude'], pickupLocationData['longitude']);
//
//     _riderLocationSubscription?.cancel();
//     _riderLocationSubscription = FirebaseDatabase.instance
//         .ref('riders/$_riderId/location')
//         .onValue
//         .listen((event) {
//       if (mounted && event.snapshot.exists) {
//         final data = Map<String, dynamic>.from(event.snapshot.value as Map);
//         final riderPosition = LatLng(data['latitude'], data['longitude']);
//
//         setState(() {
//           _markers.removeWhere((m) => m.markerId.value == 'rider');
//           _markers.add(Marker(
//             markerId: const MarkerId('rider'),
//             position: riderPosition,
//             infoWindow: const InfoWindow(title: 'Your Rider'),
//             icon: BitmapDescriptor.defaultMarkerWithHue(
//                 BitmapDescriptor.hueGreen),
//           ));
//         });
//
//         if (isFirstLocationUpdate) {
//           _getRouteAndFitMap(riderPosition, pickupLocation);
//           isFirstLocationUpdate = false;
//         }
//
//         _mapController?.animateCamera(CameraUpdate.newLatLng(riderPosition));
//       }
//     });
//   }
//
//   Future<void> _getRouteAndFitMap(LatLng riderPos, LatLng pickupPos) async {
//     PolylinePoints polylinePoints = PolylinePoints();
//     PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
//       googleMapsApiKey,
//       PointLatLng(riderPos.latitude, riderPos.longitude),
//       PointLatLng(pickupPos.latitude, pickupPos.longitude),
//     );
//
//     if (result.points.isNotEmpty) {
//       List<LatLng> polylineCoordinates = result.points
//           .map((point) => LatLng(point.latitude, point.longitude))
//           .toList();
//
//       setState(() {
//         _polylines.add(Polyline(
//           polylineId: const PolylineId('route'),
//           color: Colors.blueAccent,
//           points: polylineCoordinates,
//           width: 5,
//         ));
//         _markers.add(Marker(
//           markerId: const MarkerId('pickup'),
//           position: pickupPos,
//           infoWindow: const InfoWindow(title: 'Pickup Location'),
//         ));
//       });
//
//       _mapController?.animateCamera(CameraUpdate.newLatLngBounds(
//         LatLngBounds(
//           southwest: LatLng(
//             riderPos.latitude < pickupPos.latitude
//                 ? riderPos.latitude
//                 : pickupPos.latitude,
//             riderPos.longitude < pickupPos.longitude
//                 ? riderPos.longitude
//                 : pickupPos.longitude,
//           ),
//           northeast: LatLng(
//             riderPos.latitude > pickupPos.latitude
//                 ? riderPos.latitude
//                 : pickupPos.latitude,
//             riderPos.longitude > pickupPos.longitude
//                 ? riderPos.longitude
//                 : pickupPos.longitude,
//           ),
//         ),
//         100.0,
//       ));
//     }
//   }
//
//   Future<void> _makePhoneCall(String phoneNumber) async {
//     final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
//     if (!await launchUrl(launchUri)) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Could not launch dialer for $phoneNumber')),
//         );
//       }
//     }
//   }
//
//   Widget _buildFindingRiderView() {
//     return const Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(),
//           SizedBox(height: 20),
//           Text('Finding your Ricky', style: TextStyle(fontSize: 18)),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTrackingMapView() {
//     return GoogleMap(
//       onMapCreated: (controller) => _mapController = controller,
//       initialCameraPosition:
//       const CameraPosition(target: LatLng(28.7041, 77.1025), zoom: 11),
//       markers: _markers,
//       polylines: _polylines,
//     );
//   }
//
//   Widget _buildRiderInfoCard() {
//     return Positioned(
//       bottom: 20,
//       left: 20,
//       right: 20,
//       child: Card(
//         elevation: 8,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         child: Padding(
//           padding: const EdgeInsets.all(12.0),
//           child: Row(
//             children: [
//               Icon(Icons.person_pin_circle,
//                   color: Theme.of(context).primaryColor, size: 40),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(_riderName ?? 'Fetching rider...',
//                         style: const TextStyle(
//                             fontWeight: FontWeight.bold, fontSize: 16)),
//                     if (_riderPhone != null)
//                       Text(_riderPhone!, style: const TextStyle(fontSize: 14)),
//                   ],
//                 ),
//               ),
//               if (_riderPhone != null)
//                 IconButton.filled(
//                   style: IconButton.styleFrom(backgroundColor: Colors.green),
//                   icon: const Icon(Icons.call, color: Colors.white),
//                   onPressed: () => _makePhoneCall(_riderPhone!),
//                   iconSize: 28,
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false,
//       onPopInvoked: (didPop) async {
//         if (didPop) return;
//
//         if (_status == 'pending') {
//           final bool shouldCancel = await showDialog(
//             context: context,
//             builder: (context) => AlertDialog(
//               title: const Text('Cancel Search?'),
//               content: const Text(
//                   'This will cancel the booking request for riders.'),
//               actions: <Widget>[
//                 TextButton(
//                   onPressed: () => Navigator.of(context).pop(false),
//                   child: const Text('No'),
//                 ),
//                 TextButton(
//                   onPressed: () => Navigator.of(context).pop(true),
//                   child: const Text('Yes, Cancel'),
//                 ),
//               ],
//             ),
//           ) ??
//               false;
//
//           if (shouldCancel && mounted) {
//             await FirebaseDatabase.instance
//                 .ref('orders/${widget.orderId}')
//                 .update({'status': 'cancelled'});
//             Navigator.of(context).pop();
//           }
//         } else {
//           Navigator.of(context).pop();
//         }
//       },
//       child: Scaffold(
//         appBar: AppBar(
//           title:
//           Text(_status == 'pending' ? 'Finding Rider' : 'Tracking Rider'),
//         ),
//         body: Stack(
//           children: [
//             _status == 'pending'
//                 ? _buildFindingRiderView()
//                 : _buildTrackingMapView(),
//             if (_status == 'accepted') _buildRiderInfoCard(),
//           ],
//         ),
//         floatingActionButton: _status == 'completed' || _status == 'cancelled'
//             ? FloatingActionButton.extended(
//           onPressed: () => Navigator.of(context).pop(),
//           label: const Text('Book Another Ride'),
//           icon: const Icon(Icons.add),
//         )
//             : null,
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class OrderStatusScreen extends StatefulWidget {
  final String orderId;
  const OrderStatusScreen({super.key, required this.orderId});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  StreamSubscription? _orderSubscription;
  String _status = 'pending';
  String? _riderId;

  // State for storing rider and ride details
  String? _riderName;
  String? _riderPhone;
  String? _vehicleNumber;
  double _price = 0.0;

  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _listenToOrder();
    _startTimeoutTimer();
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startTimeoutTimer() {
    _timeoutTimer = Timer(const Duration(minutes: 5), () {
      if (mounted && _status == 'pending') {
        FirebaseDatabase.instance
            .ref('orders/${widget.orderId}')
            .update({'status': 'cancelled'});

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Ricky Not Found"),
            content: const Text(
                "Sorry, we couldn't find a driver at this time."),
            actions: [
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    });
  }

  void _listenToOrder() {
    _orderSubscription = FirebaseDatabase.instance
        .ref('orders/${widget.orderId}')
        .onValue
        .listen((event) {
      if (mounted && event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final newStatus = data['status'];
        final newRiderId = data['riderId'];

        if (newStatus == 'completed' || newStatus == 'cancelled') {
          _timeoutTimer?.cancel();
          _showRideCompletionDialog(newStatus);
          return;
        }

        setState(() {
          _price = (data['price'] ?? 0.0).toDouble();
        });

        if (newStatus != _status || newRiderId != _riderId) {
          setState(() {
            _status = newStatus;
            _riderId = newRiderId;
          });

          if (_status == 'accepted' && _riderId != null) {
            _timeoutTimer?.cancel();
            _fetchRiderDetails();
          }
        }
      }
    });
  }

  /// Fetches rider's name, phone, and vehicle number from their profile.
  Future<void> _fetchRiderDetails() async {
    if (_riderId == null) return;
    final riderSnapshot =
    await FirebaseDatabase.instance.ref('riders/$_riderId').get();
    if (mounted && riderSnapshot.exists) {
      final riderData = Map<String, dynamic>.from(riderSnapshot.value as Map);
      setState(() {
        _riderName = riderData['name'] ?? 'N/A';
        _riderPhone = riderData['phone'] ?? 'N/A';
        _vehicleNumber = riderData['vehicle'] ?? 'N/A';
      });
    }
  }

  /// Initiates a phone call to the rider.
  Future<void> _makePhoneCall() async {
    if (_riderPhone == null || _riderPhone == 'N/A') return;
    final Uri launchUri = Uri(scheme: 'tel', path: _riderPhone);
    if (!await launchUrl(launchUri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch dialer for $_riderPhone')),
        );
      }
    }
  }

  /// Shows a final dialog when the ride is completed or cancelled.
  void _showRideCompletionDialog(String finalStatus) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(finalStatus == 'completed' ? "Ride Completed" : "Ride Cancelled"),
        content: Text(finalStatus == 'completed'
            ? "Your ride is complete. Thank you!"
            : "Your ride has been cancelled."),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.of(ctx).pop(); // Close the dialog
              Navigator.of(context).pop(); // Go back from the OrderStatusScreen
            },
          ),
        ],
      ),
    );
  }

  /// The view shown while searching for a driver.
  Widget _buildFindingRiderView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Finding your Ricky...', style: TextStyle(fontSize: 18)),
          SizedBox(height: 10),
          Text('Please wait a moment.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  /// The view shown after a driver has accepted the ride.
  Widget _buildRiderConfirmedView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.electric_rickshaw, size: 80, color: Colors.green),
          const SizedBox(height: 16),
          const Text(
            'Your Ricky is on the way!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDetailRow(Icons.person, "Driver Name", _riderName),
                  const Divider(),
                  _buildDetailRow(Icons.pin, "Vehicle No.", _vehicleNumber),
                  const Divider(),
                  // --- ADDED PHONE NUMBER DISPLAY ---
                  _buildDetailRow(Icons.phone, "Phone", _riderPhone),
                  const Divider(),
                  _buildDetailRow(Icons.price_change, "Ride Fare", "₹${_price.toStringAsFixed(2)}"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.call),
            label: const Text('Call Driver'),
            onPressed: _makePhoneCall,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          )
        ],
      ),
    );
  }

  /// Helper widget for creating styled rows.
  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(value ?? '...', style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // Allow cancellation only when the ride is in 'pending' state
        if (_status == 'pending') {
          final bool shouldCancel = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cancel Search?'),
              content: const Text(
                  'This will cancel the booking request for drivers.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes, Cancel'),
                ),
              ],
            ),
          ) ??
              false;

          if (shouldCancel && mounted) {
            await FirebaseDatabase.instance
                .ref('orders/${widget.orderId}')
                .update({'status': 'cancelled'});
            // The listener will handle the pop navigation
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("You cannot cancel a ride after a driver has been assigned."))
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_status == 'pending' ? 'Finding Driver' : 'Driver on the way'),
          automaticallyImplyLeading: false,
        ),
        body: _status == 'pending'
            ? _buildFindingRiderView()
            : _buildRiderConfirmedView(),
      ),
    );
  }
}


