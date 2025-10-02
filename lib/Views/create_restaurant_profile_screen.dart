// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:ricky/map_picker_screen.dart'; // Make sure this path is correct
// import 'package:ricky/views/main_screen.dart'; // Make sure this path is correct
//
// class CreateRestaurantProfileScreen extends StatefulWidget {
//   const CreateRestaurantProfileScreen({super.key});
//
//   @override
//   State<CreateRestaurantProfileScreen> createState() => _CreateRestaurantProfileScreenState();
// }
//
// class _CreateRestaurantProfileScreenState extends State<CreateRestaurantProfileScreen> {
//   final _nameController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//
//   final _formKey = GlobalKey<FormState>();
//   bool _isSaving = false;
//   LatLng? _selectedLocation; // To store the location from the map
//
//   Future<void> _saveProfile() async {
//     if (_formKey.currentState!.validate()) {
//       if (_selectedLocation == null) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Please set your restaurant location on the map.')),
//         );
//         return;
//       }
//
//       setState(() => _isSaving = true);
//
//       try {
//         final user = FirebaseAuth.instance.currentUser;
//         if (user == null) return;
//
//         await FirebaseDatabase.instance.ref('restaurants/${user.uid}/profile').set({
//           'name': _nameController.text.trim(),
//           'phone': _phoneController.text.trim(),
//           'address': _addressController.text.trim(),
//           'location': {
//             'latitude': _selectedLocation!.latitude,
//             'longitude': _selectedLocation!.longitude,
//           },
//           'createdAt': ServerValue.timestamp,
//         });
//
//         if (mounted) {
//           Navigator.of(context).pushAndRemoveUntil(
//             MaterialPageRoute(builder: (context) => const MainScreen()),
//                 (Route<dynamic> route) => false,
//           );
//         }
//       } catch (e) {
//         setState(() => _isSaving = false);
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text("Failed to create profile: $e")),
//           );
//         }
//       }
//     }
//   }
//
//   void _pickLocationOnMap() async {
//     final pickedLocation = await Navigator.of(context).push<LatLng>(
//       MaterialPageRoute(builder: (ctx) => const MapPickerScreen()),
//     );
//     if (pickedLocation != null) {
//       setState(() {
//         _selectedLocation = pickedLocation;
//       });
//     }
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Create Restaurant Profile'),
//         automaticallyImplyLeading: false,
//       ),
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Text(
//                   'Welcome! Please complete your profile to continue.',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 16),
//                 ),
//                 const SizedBox(height: 24),
//                 TextFormField(
//                   controller: _nameController,
//                   decoration: const InputDecoration(labelText: 'Restaurant Name'),
//                   validator: (v) => v!.isEmpty ? 'Please enter a name' : null,
//                 ),
//                 const SizedBox(height: 12),
//                 TextFormField(
//                   controller: _phoneController,
//                   decoration: const InputDecoration(labelText: 'Contact Phone Number'),
//                   keyboardType: TextInputType.phone,
//                   validator: (v) => v!.isEmpty ? 'Please enter a phone number' : null,
//                 ),
//                 const SizedBox(height: 12),
//                 TextFormField(
//                   controller: _addressController,
//                   decoration: const InputDecoration(labelText: 'Full Address'),
//                   validator: (v) => v!.isEmpty ? 'Please enter an address' : null,
//                 ),
//                 const SizedBox(height: 20),
//                 // Location Picker
//                 Container(
//                   height: 50,
//                   width: double.infinity,
//                   alignment: Alignment.center,
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Colors.grey),
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: _selectedLocation == null
//                       ? const Text('Location Not Set')
//                       : Text(
//                     'Location Set: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
//                   ),
//                 ),
//                 TextButton.icon(
//                   icon: const Icon(Icons.map),
//                   label: const Text('Set Location on Map'),
//                   onPressed: _pickLocationOnMap,
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                   ),
//                   onPressed: _isSaving ? null : _saveProfile,
//                   child: _isSaving
//                       ? const SizedBox(
//                     height: 24,
//                     width: 24,
//                     child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0),
//                   )
//                       : const Text('Save & Continue'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ricky/map_picker_screen.dart'; // Make sure this path is correct
import 'package:ricky/views/main_screen.dart'; // Make sure this path is correct

class CreateRestaurantProfileScreen extends StatefulWidget {
  const CreateRestaurantProfileScreen({super.key});

  @override
  State<CreateRestaurantProfileScreen> createState() =>
      _CreateRestaurantProfileScreenState();
}

class _CreateRestaurantProfileScreenState
    extends State<CreateRestaurantProfileScreen> {
  // Key for form validation
  final _formKey = GlobalKey<FormState>();

  // Controllers for editable fields
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  // State variables to hold UI state
  bool _isSaving = false;
  LatLng? _selectedLocation;

  // Get current user directly
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    // Pre-fill the name field with the user's current display name, if available
    if (_currentUser != null) {
      _nameController.text = _currentUser!.displayName ?? '';
    }
  }

  /// Saves the user's profile to the Firebase Realtime Database.
  Future<void> _saveProfile() async {
    // Validate the form before proceeding
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show a snackbar if the user enters an address but doesn't set a location on the map.
    if (_addressController.text.isNotEmpty && _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please set your location on the map to save the address.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = _currentUser;
      if (user == null) return;

      // Prepare the user profile data using a dynamic map.
      final Map<String, dynamic> profileData = {
        // Get the name from the text controller
        'name': _nameController.text.trim(),
        'phone': user.phoneNumber ?? 'N/A',
        'createdAt': ServerValue.timestamp,
      };

      // Only add address and location information if the user has provided it.
      if (_addressController.text.trim().isNotEmpty &&
          _selectedLocation != null) {
        profileData['address'] = _addressController.text.trim();
        profileData['location'] = {
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
        };
      }

      // Use the original database path 'restaurants'.
      await FirebaseDatabase.instance
          .ref('restaurants/${user.uid}/profile')
          .set(profileData);

      if (mounted) {
        // Navigate to the main screen after the profile is saved.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
              (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save profile: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Navigates to the map screen to let the user pick a location.
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
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Reverted title
        title: const Text('Create Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.account_circle, size: 80, color: Colors.teal),
              const SizedBox(height: 16),
              const Text(
                'Welcome! Let\'s get your profile set up.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),

              // Editable Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                value!.trim().isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),

              // Display Phone (auto-fetched, non-editable)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildProfileInfoRow(
                      Icons.phone, 'Phone', _currentUser?.phoneNumber),
                ),
              ),
              const SizedBox(height: 32),

              // Optional Home Address Section
              Text(
                'Add a Home Address (Optional)',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Home Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
              ),
              const SizedBox(height: 12),

              // Location Picker
              OutlinedButton.icon(
                icon: const Icon(Icons.map_outlined),
                label: const Text('Set Home Location on Map'),
                onPressed: _pickLocationOnMap,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              if (_selectedLocation != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Location Set: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.0),
                )
                    : const Text('Save & Continue',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper widget to build a row for displaying user info.
  Widget _buildProfileInfoRow(IconData icon, String label, String? value) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal),
        const SizedBox(width: 16),
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value ?? 'Not available',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
