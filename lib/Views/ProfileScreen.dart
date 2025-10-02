// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:pacpic/map_picker_screen.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// class RestaurantProfileScreen extends StatefulWidget {
//   const RestaurantProfileScreen({super.key});

//   @override
//   State<RestaurantProfileScreen> createState() => _RestaurantProfileScreenState();
// }

// class _RestaurantProfileScreenState extends State<RestaurantProfileScreen> {
//   final _nameController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final String _uid = FirebaseAuth.instance.currentUser!.uid;

//   bool _isLoading = true;
//   bool _isEditing = false;
//   LatLng? _selectedLocation;

//   @override
//   void initState() {
//     super.initState();
//     _loadProfileData();
//   }

//   Future<void> _loadProfileData() async {
//     final snapshot = await FirebaseDatabase.instance.ref('restaurants/$_uid/profile').get();
//     if (mounted && snapshot.exists) {
//       final data = Map<String, dynamic>.from(snapshot.value as Map);
//       _nameController.text = data['name'] ?? '';
//       _phoneController.text = data['phone'] ?? '';
//       _addressController.text = data['address'] ?? '';
//       if (data['location'] != null) {
//         _selectedLocation = LatLng(data['location']['latitude'], data['location']['longitude']);
//       }
//     }
//     if(mounted) setState(() => _isLoading = false);
//   }

//   Future<void> _saveProfile() async {
//     if (_selectedLocation == null) {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please set your location.')));
//       return;
//     }
//     setState(() => _isLoading = true);
//     try {
//       await FirebaseDatabase.instance.ref('restaurants/$_uid/profile').update({
//         'name': _nameController.text.trim(),
//         'phone': _phoneController.text.trim(),
//         'address': _addressController.text.trim(),
//         'location': {
//           'latitude': _selectedLocation!.latitude,
//           'longitude': _selectedLocation!.longitude,
//         },
//       });
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Saved!")));
//     } catch (e) {
//       // Handle error
//     }
//     if (mounted) setState(() {
//       _isLoading = false;
//       _isEditing = false;
//     });
//   }

//   void _pickLocationOnMap() async {
//     final pickedLocation = await Navigator.of(context).push<LatLng>(
//       MaterialPageRoute(builder: (ctx) => const MapPickerScreen()),
//     );
//     if (pickedLocation != null) {
//       setState(() => _selectedLocation = pickedLocation);
//     }
//   }

//   Widget _buildProfileField(String label, IconData icon, TextEditingController controller) {
//     return TextFormField(
//       controller: controller,
//       enabled: _isEditing,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon),
//         border: _isEditing ? const UnderlineInputBorder() : InputBorder.none,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         children: [
//           Card(
//             elevation: 4,
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   _buildProfileField('Restaurant Name', Icons.store, _nameController),
//                   const Divider(),
//                   _buildProfileField('Phone Number', Icons.phone, _phoneController),
//                   const Divider(),
//                   _buildProfileField('Address', Icons.location_city, _addressController),
//                   const Divider(),
//                   ListTile(
//                     leading: const Icon(Icons.map), // <-- 2. FIX ICON NAME HERE
//                     title: const Text('Restaurant Location'),
//                     subtitle: Text(_selectedLocation == null ? 'Not Set' : '${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}'),
//                     trailing: _isEditing ? IconButton(icon: const Icon(Icons.edit_location), onPressed: _pickLocationOnMap) : null,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),
//           if (_isEditing)
//             Row(
//               children: [
//                 Expanded(child: OutlinedButton(onPressed: () => setState(() => _isEditing = false), child: const Text('Cancel'))),
//                 const SizedBox(width: 10),
//                 Expanded(child: ElevatedButton(onPressed: _saveProfile, child: const Text('Save'))),
//               ],
//             )
//           else
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 icon: const Icon(Icons.edit),
//                 label: const Text('Edit Profile'),
//                 onPressed: () => setState(() => _isEditing = true),
//               ),
//             ),
//           const Spacer(),
//           TextButton.icon(
//             icon: const Icon(Icons.logout, color: Colors.red),
//             label: const Text('Logout', style: TextStyle(color: Colors.red)),
//             onPressed: () => FirebaseAuth.instance.signOut(),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ricky/map_picker_screen.dart'; // Verify this import path
import 'package:ricky/LoginScreen.dart'; // Verify this import path

class RestaurantProfileScreen extends StatefulWidget {
  const RestaurantProfileScreen({super.key});

  @override
  State<RestaurantProfileScreen> createState() => _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends State<RestaurantProfileScreen> {
  // Controllers for text fields
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // State management variables
  bool _isLoading = true; // For initial data loading
  bool _isSaving = false; // For saving changes
  bool _isEditing = false; // To toggle between view and edit mode
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _fetchRestaurantProfile();
  }

  /// Fetches the current restaurant's profile data from Firebase.
  Future<void> _fetchRestaurantProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in.");

      final ref = FirebaseDatabase.instance.ref('restaurants/${user.uid}/profile');
      final snapshot = await ref.get();

      if (mounted && snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _addressController.text = data['address'] ?? '';
        if (data['location'] != null) {
          _selectedLocation = LatLng(
            data['location']['latitude'],
            data['location']['longitude'],
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load profile: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Saves the updated profile data to Firebase.
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set your location on the map.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final profileData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'location': {
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
        },
      };

      await FirebaseDatabase.instance.ref('restaurants/${user.uid}/profile').update(profileData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        // Exit edit mode after saving
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update profile: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Signs the user out and navigates to the LoginScreen.
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (Route<dynamic> route) => false,
      );
    }
  }

  /// Navigates to the map picker screen to choose a location.
  void _pickLocationOnMap() async {
    final pickedLocation = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (ctx) => const MapPickerScreen()),
    );
    if (pickedLocation != null) {
      setState(() {
        _selectedLocation = pickedLocation;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        actions: [
          // Show an Edit/Cancel button in the AppBar
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.storefront, size: 80, color: Colors.blueGrey),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                enabled: _isEditing, // Enable/disable based on edit mode
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                enabled: _isEditing,
                decoration: const InputDecoration(labelText: 'Contact Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Please enter a phone number' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                enabled: _isEditing,
                decoration: const InputDecoration(labelText: 'Home Address'),
                validator: (v) => v!.isEmpty ? 'Please enter an address' : null,
              ),
              const SizedBox(height: 20),
              // Location Display
              Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  border: Border.all(color: _isEditing ? Theme.of(context).primaryColor : Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  _selectedLocation == null
                      ? 'Location Not Set'
                      : 'Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              // Show "Set Location" button only in edit mode
              if (_isEditing)
                TextButton.icon(
                  icon: const Icon(Icons.map),
                  label: const Text('Change Location on Map'),
                  onPressed: _pickLocationOnMap,
                ),
              const SizedBox(height: 30),
              // Show "Save Changes" button only in edit mode
              if (_isEditing)
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isSaving
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Save Changes'),
                ),
              const SizedBox(height: 20),
              // Logout Button
              OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Logout', style: TextStyle(color: Colors.red)),
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}