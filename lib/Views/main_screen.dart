// import 'package:flutter/material.dart';
// import 'package:pacpic/Views/nearby_riders_screen.dart';
// import 'package:pacpic/Views/ProfileScreen.dart';
// import 'package:pacpic/Views/restaurant_history_screen.dart';
// import 'package:pacpic/Views/BookRIde.dart';
//
// class MainScreen extends StatefulWidget {
//   const MainScreen({super.key});
//
//   @override
//   State<MainScreen> createState() => _MainScreenState();
// }
//
// class _MainScreenState extends State<MainScreen> {
//   int _selectedIndex = 0;
//
//   static const List<Widget> _screens = <Widget>[
//     NearbyRidersScreen(),
//     RestaurantHistoryScreen(restaurantId: '',),
//     RestaurantProfileScreen(),
//   ];
//
//   static const List<String> _titles = <String>[
//     'Nearby Riders',
//     'Booking History',
//     'Your Profile',
//   ];
//
//   void _onItemTapped(int index) {
//     setState(() => _selectedIndex = index);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(_titles[_selectedIndex]),
//       ),
//       body: _screens[_selectedIndex],
//       // Show the "Book Ride" button only on the home tab
//       floatingActionButton: _selectedIndex == 0
//           ? FloatingActionButton.extended(
//         onPressed: () {
//           Navigator.of(context).push(
//             MaterialPageRoute(builder: (_) => const BookRideScreen()),
//           );
//         },
//         icon: const Icon(Icons.add),
//         label: const Text('Book Ride'),
//       )
//           : null,
//       bottomNavigationBar: BottomNavigationBar(
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(icon: Icon(Icons.motorcycle), label: 'Riders'),
//           BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
//           BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Profile'),
//         ],
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//       ),
//     );
//   }
// }
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import 'package:ricky/views/nearby_riders_screen.dart';

import 'package:ricky/views/restaurant_history_screen.dart';
import 'package:url_launcher/url_launcher.dart';


import 'BookRIde.dart';
import 'ProfileScreen.dart';

class MainScreen extends StatefulWidget {
  // The constructor is simple, no parameters needed.
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;
  bool _isLoading = true; // To show a loading spinner briefly

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }

  void _initializeScreens() {
    // It's safe to get the user here because AuthGate ensures we are logged in.
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Initialize the screens, passing the restaurant's UID to each one
      _screens = <Widget>[
        NearbyRidersScreen(),
        RestaurantHistoryScreen(restaurantId: user.uid),
        RestaurantProfileScreen(),
      ];
      // Once screens are ready, stop loading
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } else {
      // This is a safety fallback. If this happens, something is wrong.
      // We safely sign out and let AuthGate redirect to the login screen.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FirebaseAuth.instance.signOut();
      });
    }
  }
  void _showHelplineDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.support_agent),
            SizedBox(width: 8),
            Text('Helpline'),
          ],
        ),
        content: FutureBuilder<DataSnapshot>(
          future: FirebaseDatabase.instance.ref('helpline/phone').get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 50,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return const Text('Could not load helpline number.');
            }
            if (snapshot.hasData && snapshot.data!.exists) {
              final phoneNumber = snapshot.data!.value.toString();

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('For any issues, please contact:'),
                  const SizedBox(height: 8),
                  Text(phoneNumber,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    icon: const Icon(Icons.call),
                    label: const Text('Call Now'),
                    onPressed: () async {
                      final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
                      if (await canLaunchUrl(callUri)) {
                        await launchUrl(callUri);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open dialer.')),
                        );
                      }
                    },
                  )
                ],
              );
            }
            return const Text('Helpline number not available.');
          },
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }


  static const List<String> _titles = <String>[
    'Nearby Riders',
    'Booking History',
    'Your Profile',
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator until the user ID is fetched and screens are ready
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),

          actions: [
            IconButton(
              icon: const Icon(Icons.support_agent),
              tooltip: 'Helpline',
              onPressed: _showHelplineDialog,
            ),
          ],
      ),
      body: _screens[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BookRideScreen()),
          );
          if (result == 'completed' && mounted) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(
                content: Text("Ride Completed!"),
                backgroundColor: Colors.green,
              ));
            _onItemTapped(1);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Book Ride'),
      )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.motorcycle), label: 'Riders'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}