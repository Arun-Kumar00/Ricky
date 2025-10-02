import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

// Use the same API key as in the BookRideScreen
// NOTE: Make sure this key has "Places API" and "Geocoding API" enabled.
const String googleMapsApiKey = "AIzaSyBRaty5Cs4xkv1dgudw_mS0PYyMxms4HFQ";

class PlaceSuggestion {
  final String placeId;
  final String description;
  PlaceSuggestion(this.placeId, this.description);
}

class MapPickerWithSearchScreen extends StatefulWidget {
  const MapPickerWithSearchScreen({super.key});

  @override
  State<MapPickerWithSearchScreen> createState() =>
      _MapPickerWithSearchScreenState();
}

class _MapPickerWithSearchScreenState extends State<MapPickerWithSearchScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _sessionToken = const Uuid().v4();
  List<PlaceSuggestion> _suggestions = [];

  LatLng _currentLocation =
  const LatLng(28.7041, 77.1025); // Default to Delhi
  String _currentAddress = "Loading address...";
  bool _isGeocoding = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchSuggestions(String input) async {
    final baseUrl =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json';
    // Limiting search to India for better results
    String url =
        '$baseUrl?input=$input&key=$googleMapsApiKey&sessiontoken=$_sessionToken&components=country:in';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'OK' && mounted) {
          setState(() {
            _suggestions = (result['predictions'] as List)
                .map((p) => PlaceSuggestion(p['place_id'], p['description']))
                .toList();
          });
        }
      }
    } catch (e) {
      // Handle error, e.g., print(e);
    }
  }

  Future<void> _getPlaceDetailsAndMoveCamera(String placeId) async {
    final baseUrl = 'https://maps.googleapis.com/maps/api/place/details/json';
    String url =
        '$baseUrl?place_id=$placeId&key=$googleMapsApiKey&sessiontoken=$_sessionToken&fields=geometry';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'OK' && mounted) {
          final placeDetails = result['result'];
          final location = placeDetails['geometry']['location'];
          final newPos = LatLng(location['lat'], location['lng']);

          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newPos, 16));
          setState(() {
            _suggestions = [];
            _searchController.clear();
            _sessionToken = const Uuid().v4(); // Reset token
          });
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    if(!mounted) return;
    setState(() {
      _isGeocoding = true;
    });
    final baseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
    String url = '$baseUrl?latlng=${position.latitude},${position.longitude}&key=$googleMapsApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'OK' && result['results'].isNotEmpty) {
          if(mounted) {
            setState(() {
              _currentAddress = result['results'][0]['formatted_address'];
            });
          }
        }
      }
    } catch (e) {
      if(mounted) setState(() => _currentAddress = "Could not get address");
    } finally {
      if(mounted) setState(() => _isGeocoding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location"),
        actions: [
          // The checkmark/tick button to confirm selection
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: (_currentAddress == "Loading address..." || _isGeocoding)
                ? null // Disable button while geocoding
                : () {
              Navigator.of(context).pop({
                'location': _currentLocation,
                'address': _currentAddress,
              });
            },
          )
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              _getAddressFromLatLng(_currentLocation);
            },
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 14.0,
            ),
            onCameraMove: (position) {
              _currentLocation = position.target;
            },
            onCameraIdle: () {
              _getAddressFromLatLng(_currentLocation);
            },
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            zoomControlsEnabled: false, // Cleaner UI
          ),
          const Center(
            child: Icon(
              Icons.location_pin,
              size: 50,
              color: Colors.red,
            ),
          ),
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for a location...',
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _suggestions = []);
                        },
                      )
                          : null,
                    ),
                    onChanged: (value) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 400), () {
                        if (value.isNotEmpty) {
                          _fetchSuggestions(value);
                        } else {
                          setState(() => _suggestions = []);
                        }
                      });
                    },
                  ),
                  if (_suggestions.isNotEmpty)
                    SizedBox(
                      height: 200, // Constrain list height
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_suggestions[index].description),
                            onTap: () {
                              _getPlaceDetailsAndMoveCamera(
                                  _suggestions[index].placeId);
                              FocusScope.of(context).unfocus();
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isGeocoding ? "Finding address..." : _currentAddress,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
