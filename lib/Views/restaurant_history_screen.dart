// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:intl/intl.dart';
//
// class RestaurantHistoryScreen extends StatefulWidget {
//   const RestaurantHistoryScreen({super.key});
//
//   @override
//   State<RestaurantHistoryScreen> createState() => _RestaurantHistoryScreenState();
// }
//
// class _RestaurantHistoryScreenState extends State<RestaurantHistoryScreen> {
//   final String _restaurantId = FirebaseAuth.instance.currentUser!.uid;
//   List<DataSnapshot> _pastOrders = [];
//   double _totalRevenue = 0.0;
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchPastOrders();
//   }
//
//   Future<void> _fetchPastOrders() async {
//     try {
//       final snapshot = await FirebaseDatabase.instance
//           .ref('orders')
//           .orderByChild('restaurantId')
//           .equalTo(_restaurantId)
//           .get();
//
//       if (mounted && snapshot.exists) {
//         double revenue = 0.0;
//         final orders = snapshot.children.toList();
//
//         for (final orderSnapshot in orders) {
//           final data = Map<String, dynamic>.from(orderSnapshot.value as Map);
//           // --- THIS IS THE FIX ---
//           // Only add to the total if the order was completed
//           if (data['status'] == 'completed') {
//             revenue += (data['price'] ?? 0.0);
//           }
//         }
//
//         orders.sort((a, b) {
//           final aData = Map<String, dynamic>.from(a.value as Map);
//           final bData = Map<String, dynamic>.from(b.value as Map);
//           return (bData['createdAt'] as int).compareTo(aData['createdAt'] as int);
//         });
//
//         setState(() {
//           _pastOrders = orders;
//           _totalRevenue = revenue;
//         });
//       }
//     } catch (e) {
//       debugPrint("Error fetching history: $e");
//     }
//     if (mounted) setState(() => _isLoading = false);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }
//
//     return RefreshIndicator(
//       onRefresh: _fetchPastOrders,
//       child: Column(
//         children: [
//           Card(
//             margin: const EdgeInsets.all(12),
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Text(
//                     'Total Bills',
//                     textAlign: TextAlign.center,
//                     style: Theme.of(context).textTheme.titleMedium,
//                   ),
//                   Text(
//                     '₹${_totalRevenue.toStringAsFixed(2)}',
//                     textAlign: TextAlign.center,
//                     style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue.shade700,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           if (_pastOrders.isEmpty)
//             const Expanded(
//                 child: Center(child: Text('You have no past bookings.'))
//             )
//           else
//             Expanded(
//               child: ListView.builder(
//                 itemCount: _pastOrders.length,
//                 itemBuilder: (context, index) {
//                   final orderData = Map<String, dynamic>.from(_pastOrders[index].value as Map);
//                   final status = orderData['status'] ?? 'Unknown';
//                   final createdAt = DateTime.fromMillisecondsSinceEpoch(orderData['createdAt']);
//                   final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(createdAt);
//
//                   return ListTile(
//                     leading: Icon(
//                       status == 'completed' ? Icons.check_circle : Icons.error_outline,
//                       color: status == 'completed' ? Colors.green : Colors.grey,
//                     ),
//                     title: Text('Order to Customer'),
//                     subtitle: Text('Status: $status • $formattedDate'),
//                     trailing: Text('₹${orderData['price']?.toStringAsFixed(2) ?? '0.00'}'),
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:ricky/views/order_status_screen.dart'; // Import the order status screen

class RestaurantHistoryScreen extends StatefulWidget {
  // It now requires the restaurant's ID
  final String restaurantId;
  const RestaurantHistoryScreen({super.key, required this.restaurantId});

  @override
  State<RestaurantHistoryScreen> createState() => _RestaurantHistoryScreenState();
}

class _RestaurantHistoryScreenState extends State<RestaurantHistoryScreen> {
  // NEW STATE: Separate lists and totals for billing
  List<DataSnapshot> _activeOrders = [];
  List<DataSnapshot> _pastOrders = [];
  double _unsettledCommission = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  // UPDATED: This function now calculates unsettled commission
  Future<void> _fetchOrders() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _activeOrders = [];
        _pastOrders = [];
        _unsettledCommission = 0.0;
      });
    }

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('orders')
          .orderByChild('restaurantId')
          .equalTo(widget.restaurantId)
          .get();

      if (mounted && snapshot.exists) {
        double commissionDue = 0.0;
        final active = <DataSnapshot>[];
        final past = <DataSnapshot>[];

        for (final orderSnapshot in snapshot.children) {
          final data = Map<String, dynamic>.from(orderSnapshot.value as Map);
          final status = data['status'];

          if (status == 'pending' || status == 'accepted') {
            active.add(orderSnapshot);
          } else {
            past.add(orderSnapshot);
          }

          // Calculate commission for completed and unsettled rides
          if (status == 'completed' && data['isSettledByRestaurant'] != true) {
            final commission = (data['price'] ?? 0.0);
            commissionDue += commission;
          }
        }

        active.sort((a, b) => (b.value as Map)['createdAt'].compareTo((a.value as Map)['createdAt']));
        past.sort((a, b) => (b.value as Map)['createdAt'].compareTo((a.value as Map)['createdAt']));

        setState(() {
          _activeOrders = active;
          _pastOrders = past;
          _unsettledCommission = commissionDue;
        });
      }
    } catch (e) {
      debugPrint("Error fetching history: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _navigateToOrderStatus(String orderId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderStatusScreen(orderId: orderId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _fetchOrders,
      child: ListView(
        children: [
          // Section for active orders
          if (_activeOrders.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('In Progress', style: Theme.of(context).textTheme.titleLarge),
            ),
          ..._activeOrders.map((orderSnapshot) {
            final orderData = Map<String, dynamic>.from(orderSnapshot.value as Map);
            return Card(
              color: Colors.amber.shade50,
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.delivery_dining, color: Colors.amber),
                title: Text('Current active ride (${orderData['status']})'),
                subtitle: const Text('Tap to view live status'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => _navigateToOrderStatus(orderSnapshot.key!),
              ),
            );
          }).toList(),

          // UPDATED: Outstanding Commission Card
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Outstanding Bills (Unsettled)',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.red.shade800,
                    ),
                  ),
                  Text(
                    '₹${_unsettledCommission.toStringAsFixed(2)}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Header for Past Bookings
          if (_pastOrders.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Past Bookings', style: Theme.of(context).textTheme.titleLarge),
            ),

          // List of Past Bookings
          if (_pastOrders.isEmpty && _activeOrders.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('You have no bookings.'),
            ))
          else
            ..._pastOrders.map((orderSnapshot) {
              final orderData = Map<String, dynamic>.from(orderSnapshot.value as Map);
              final status = orderData['status'] ?? 'Unknown';
              final createdAt = DateTime.fromMillisecondsSinceEpoch(orderData['createdAt']);
              final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(createdAt);
              // NEW: Check settlement status
              final bool isSettled = orderData['isSettledByRestaurant'] == true;

              return ListTile(
                leading: Icon(
                  status == 'completed' ? Icons.check_circle : Icons.cancel,
                  color: status == 'completed' ? Colors.green : Colors.red,
                ),
                title: const Text('Past ride'),
                subtitle: Text('Status: $status • $formattedDate'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('₹${(orderData['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                    const SizedBox(width: 8),
                    if (status == 'completed' && isSettled)
                      const Chip(label: Text('Settled'), backgroundColor: Colors.greenAccent, padding: EdgeInsets.all(2)),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
