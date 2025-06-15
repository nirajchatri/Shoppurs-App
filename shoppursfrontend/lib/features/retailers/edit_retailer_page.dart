import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class EditRetailerPage extends StatefulWidget {
  const EditRetailerPage({Key? key}) : super(key: key);

  @override
  State<EditRetailerPage> createState() => _EditRetailerPageState();
}

class _EditRetailerPageState extends State<EditRetailerPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  String? _error;

  // Form controllers
  final _shopNameController = TextEditingController();
  final _retailerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstController = TextEditingController();
  
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;
  String _shopOpenStatus = 'Y';
  
  // Profile photo variables
  File? _selectedImage;
  String? _currentPhotoUrl;

  // List of states and cities
  final List<String> _states = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Andaman and Nicobar Islands', 'Chandigarh', 'Dadra and Nagar Haveli',
    'Daman and Diu', 'Delhi', 'Jammu and Kashmir', 'Ladakh', 'Lakshadweep',
    'Puducherry'
  ];

  final Map<String, List<String>> _citiesByState = {
    'Andhra Pradesh': ['Visakhapatnam', 'Vijayawada', 'Guntur', 'Nellore', 'Kurnool', 'Tirupati', 'Kakinada', 'Kadapa', 'Anantapur', 'Rajahmundry'],
    'Arunachal Pradesh': ['Itanagar', 'Naharlagun', 'Tawang', 'Bomdila', 'Pasighat', 'Ziro', 'Along', 'Daporijo', 'Tezu', 'Aalo'],
    'Assam': ['Guwahati', 'Silchar', 'Dibrugarh', 'Jorhat', 'Nagaon', 'Tinsukia', 'Tezpur', 'Sivasagar', 'Dhubri', 'Diphu'],
    'Bihar': ['Patna', 'Gaya', 'Bhagalpur', 'Muzaffarpur', 'Purnia', 'Darbhanga', 'Arrah', 'Begusarai', 'Katihar', 'Munger'],
    'Chhattisgarh': ['Raipur', 'Bhilai', 'Bilaspur', 'Korba', 'Durg', 'Rajnandgaon', 'Raigarh', 'Jagdalpur', 'Ambikapur', 'Chirmiri'],
    'Goa': ['Panaji', 'Vasco da Gama', 'Margao', 'Mapusa', 'Ponda', 'Mormugao', 'Bicholim', 'Sanquelim', 'Valpoi', 'Cuncolim'],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Gandhinagar', 'Bhavnagar', 'Jamnagar', 'Junagadh', 'Gandhidham', 'Anand'],
    'Haryana': ['Faridabad', 'Gurgaon', 'Panipat', 'Ambala', 'Yamunanagar', 'Rohtak', 'Hisar', 'Karnal', 'Sonipat', 'Panchkula'],
    'Himachal Pradesh': ['Shimla', 'Mandi', 'Solan', 'Dharamshala', 'Bilaspur', 'Kullu', 'Chamba', 'Hamirpur', 'Una', 'Nahan'],
    'Jharkhand': ['Ranchi', 'Jamshedpur', 'Dhanbad', 'Bokaro', 'Hazaribagh', 'Deoghar', 'Giridih', 'Phusro', 'Adityapur', 'Hussainabad'],
    'Karnataka': ['Bangalore', 'Mysore', 'Hubli', 'Mangalore', 'Belgaum', 'Gulbarga', 'Davanagere', 'Bellary', 'Bijapur', 'Shimoga'],
    'Kerala': ['Thiruvananthapuram', 'Kochi', 'Kozhikode', 'Thrissur', 'Kollam', 'Alappuzha', 'Palakkad', 'Malappuram', 'Kannur', 'Kottayam'],
    'Madhya Pradesh': ['Bhopal', 'Indore', 'Jabalpur', 'Gwalior', 'Ujjain', 'Sagar', 'Dewas', 'Satna', 'Ratlam', 'Rewa'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Thane', 'Nashik', 'Aurangabad', 'Solapur', 'Amravati', 'Kolhapur', 'Nanded'],
    'Manipur': ['Imphal', 'Thoubal', 'Bishnupur', 'Churachandpur', 'Ukhrul', 'Senapati', 'Tamenglong', 'Chandel', 'Jiribam', 'Moreh'],
    'Meghalaya': ['Shillong', 'Tura', 'Jowai', 'Nongstoin', 'Williamnagar', 'Baghmara', 'Nongpoh', 'Mairang', 'Resubelpara', 'Khliehriat'],
    'Mizoram': ['Aizawl', 'Lunglei', 'Saiha', 'Champhai', 'Kolasib', 'Serchhip', 'Lawngtlai', 'Mamit', 'Saitual', 'Khawzawl'],
    'Nagaland': ['Dimapur', 'Kohima', 'Mokokchung', 'Tuensang', 'Wokha', 'Zunheboto', 'Phek', 'Kiphire', 'Longleng', 'Peren'],
    'Odisha': ['Bhubaneswar', 'Cuttack', 'Rourkela', 'Brahmapur', 'Sambalpur', 'Puri', 'Balasore', 'Bhadrak', 'Baripada', 'Jharsuguda'],
    'Punjab': ['Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala', 'Bathinda', 'Pathankot', 'Moga', 'Abohar', 'Malerkotla', 'Khanna'],
    'Rajasthan': ['Jaipur', 'Jodhpur', 'Kota', 'Bikaner', 'Ajmer', 'Udaipur', 'Bhilwara', 'Alwar', 'Bharatpur', 'Pali'],
    'Sikkim': ['Gangtok', 'Namchi', 'Mangan', 'Gyalshing', 'Rangpo', 'Singtam', 'Jorethang', 'Ravangla', 'Pelling', 'Lachen'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem', 'Tirunelveli', 'Tiruppur', 'Erode', 'Vellore', 'Thoothukudi'],
    'Telangana': ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar', 'Ramagundam', 'Khammam', 'Mahbubnagar', 'Nalgonda', 'Adilabad', 'Siddipet'],
    'Tripura': ['Agartala', 'Udaipur', 'Dharmanagar', 'Pratapgarh', 'Kailasahar', 'Belonia', 'Khowai', 'Teliamura', 'Ambassa', 'Kumarghat'],
    'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Ghaziabad', 'Agra', 'Varanasi', 'Meerut', 'Allahabad', 'Bareilly', 'Aligarh', 'Moradabad'],
    'Uttarakhand': ['Dehradun', 'Haridwar', 'Roorkee', 'Haldwani', 'Rudrapur', 'Kashipur', 'Rishikesh', 'Kotdwara', 'Ramnagar', 'Pithoragarh'],
    'West Bengal': ['Kolkata', 'Siliguri', 'Durgapur', 'Asansol', 'Bardhaman', 'Malda', 'Baharampur', 'Habra', 'Kharagpur', 'Shantiniketan'],
    'Andaman and Nicobar Islands': ['Port Blair', 'Garacharma', 'Bambooflat', 'Prothrapur', 'Mayabunder', 'Rangat', 'Diglipur', 'Havelock', 'Car Nicobar', 'Campbell Bay'],
    'Chandigarh': ['Chandigarh', 'Mohali', 'Panchkula'],
    'Dadra and Nagar Haveli': ['Silvassa', 'Amli', 'Dadra', 'Khanvel', 'Naroli', 'Rakholi', 'Masat', 'Kadai', 'Galonda', 'Kherdi'],
    'Daman and Diu': ['Daman', 'Diu', 'Nani Daman', 'Moti Daman'],
    'Delhi': ['New Delhi', 'Delhi', 'North Delhi', 'South Delhi', 'East Delhi', 'West Delhi', 'Central Delhi', 'North East Delhi', 'North West Delhi', 'South West Delhi'],
    'Jammu and Kashmir': ['Srinagar', 'Jammu', 'Anantnag', 'Baramulla', 'Udhampur', 'Kathua', 'Rajouri', 'Poonch', 'Sopore', 'Leh'],
    'Ladakh': ['Leh', 'Kargil', 'Drass', 'Nyoma', 'Diskit', 'Hundar', 'Panamik', 'Turtuk', 'Thoise', 'Chushul'],
    'Lakshadweep': ['Kavaratti', 'Agatti', 'Amini', 'Andrott', 'Kadmat', 'Kalpeni', 'Kiltan', 'Minicoy', 'Chetlat', 'Bitra'],
    'Puducherry': ['Puducherry', 'Karaikal', 'Mahe', 'Yanam', 'Ozhukarai', 'Villianur', 'Manavely', 'Nettapakkam', 'Ariyankuppam', 'Kurumbapet']
  };

  // Google Maps related variables
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(0, 0);
  bool _isMapLoading = true;
  Set<Marker> _markers = {};
  bool _isLocationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    // Set default values
    _selectedCountry = 'India';
    _selectedState = 'Maharashtra';
    _selectedCity = _citiesByState['Maharashtra']?.first;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final retailerData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (retailerData != null) {
        _populateFormData(retailerData);
      }
    });
    _checkLocationPermission();
  }

  void _populateFormData(Map<String, dynamic> data) {
    _shopNameController.text = data['RET_SHOP_NAME'] ?? '';
    _retailerNameController.text = data['RET_NAME'] ?? '';
    _addressController.text = data['RET_ADDRESS'] ?? '';
    _pinCodeController.text = data['RET_PIN_CODE']?.toString() ?? '';
    _emailController.text = data['RET_EMAIL_ID'] ?? '';
    _gstController.text = data['RET_GST_NO'] ?? '';
    
    setState(() {
      _selectedCountry = data['RET_COUNTRY'] ?? 'India';
      _selectedState = data['RET_STATE'];
      // If the state exists in our list, use it, otherwise default to Maharashtra
      if (_selectedState != null && !_states.contains(_selectedState)) {
        _selectedState = 'Maharashtra';
      }
      
      // Set city based on state
      if (_selectedState != null && _citiesByState.containsKey(_selectedState)) {
        final cities = _citiesByState[_selectedState!]!;
        _selectedCity = data['RET_CITY'];
        // If the city doesn't exist in our list for this state, use the first city
        if (_selectedCity == null || !cities.contains(_selectedCity)) {
          _selectedCity = cities.first;
        }
      }
      
      _shopOpenStatus = data['SHOP_OPEN_STATUS'] ?? 'Y';
      
      // Set current photo URL
      if (data['RET_PHOTO'] != null && data['RET_PHOTO'].toString().isNotEmpty) {
        _currentPhotoUrl = ApiConfig.retailerPhoto(data['RET_PHOTO']);
      }
    });
  }

  Future<void> _updateRetailer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      // Create multipart request
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse(ApiConfig.retailersMyRetailer),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add form fields
      request.fields.addAll({
        'RET_NAME': _retailerNameController.text,
        'RET_SHOP_NAME': _shopNameController.text,
        'RET_ADDRESS': _addressController.text,
        'RET_PIN_CODE': _pinCodeController.text,
        'RET_EMAIL_ID': _emailController.text,
        'RET_COUNTRY': _selectedCountry ?? 'India',
        'RET_STATE': _selectedState ?? '',
        'RET_CITY': _selectedCity ?? '',
        'RET_GST_NO': _gstController.text,
        'SHOP_OPEN_STATUS': _shopOpenStatus,
        'LATITUDE': _currentPosition.latitude.toString(),
        'LONGITUDE': _currentPosition.longitude.toString(),
      });

      // Add profile image if selected
      if (_selectedImage != null) {
        final extension = _selectedImage!.path.toLowerCase().split('.').last;
        String contentType = 'image/jpeg';
        
        switch (extension) {
          case 'png':
            contentType = 'image/png';
            break;
          case 'gif':
            contentType = 'image/gif';
            break;
          case 'jpg':
          case 'jpeg':
          default:
            contentType = 'image/jpeg';
            break;
        }
        
        print('Uploading image: ${_selectedImage!.path}');
        print('Content type: $contentType');
        print('Extension: $extension');
        
        request.files.add(
          await http.MultipartFile.fromPath(
            'profileImage',
            _selectedImage!.path,
            contentType: http_parser.MediaType.parse(contentType),
          ),
        );
      }

      // Send request
      print('Sending request to: ${ApiConfig.retailersMyRetailer}');
      print('Request fields: ${request.fields}');
      print('Request files count: ${request.files.length}');
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retailer profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate successful update
      } else {
        throw Exception(data['message'] ?? 'Failed to update retailer profile');
      }
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = 'Error updating profile: ${e.toString()}';
      
      // Handle specific error messages
      if (e.toString().contains('only images files are allowed')) {
        errorMessage = 'Please select a valid image file (JPG, PNG, or GIF)';
      } else if (e.toString().contains('File too large')) {
        errorMessage = 'Image file is too large. Please select a smaller image.';
      } else if (e.toString().contains('No authentication token')) {
        errorMessage = 'Authentication error. Please login again.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _selectImageSource() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_selectedImage != null || _currentPhotoUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedImage = null;
                      _currentPhotoUrl = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (image != null) {
        // Validate file extension
        final extension = image.path.toLowerCase().split('.').last;
        if (!['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a valid image file (JPG, PNG, GIF)'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _error = 'Location services are disabled. Please enable location services.';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _error = 'Location permissions are denied. Please enable location permissions.';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _error = 'Location permissions are permanently denied. Please enable location permissions in settings.';
      });
      return;
    }

    setState(() {
      _isLocationPermissionGranted = true;
    });
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isMapLoading = false;
        _updateMarkers();
      });
      _getAddressFromLatLng(_currentPosition);
    } catch (e) {
      setState(() {
        _error = 'Error getting location: $e';
        _isMapLoading = false;
      });
    }
  }

  void _updateMarkers() {
    _markers = {
      Marker(
        markerId: const MarkerId('selected_location'),
        position: _currentPosition,
        draggable: true,
        onDragEnd: (newPosition) {
          setState(() {
            _currentPosition = newPosition;
          });
          _getAddressFromLatLng(newPosition);
        },
      ),
    };
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _addressController.text = '${place.street}, ${place.subLocality}';
          _pinCodeController.text = place.postalCode ?? '';
          // Update state and city if they match our predefined lists
          if (_states.contains(place.administrativeArea)) {
            _selectedState = place.administrativeArea;
            if (_citiesByState[_selectedState!]?.contains(place.locality) ?? false) {
              _selectedCity = place.locality;
            }
          }
        });
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _retailerNameController.dispose();
    _addressController.dispose();
    _pinCodeController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Retailer Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Photo Section - Moved to top
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile Photo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: _selectedImage != null
                                    ? Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                        width: 120,
                                        height: 120,
                                      )
                                    : _currentPhotoUrl != null
                                        ? Image.network(
                                            _currentPhotoUrl!,
                                            fit: BoxFit.cover,
                                            width: 120,
                                            height: 120,
                                            errorBuilder: (context, error, stackTrace) {
                                              return _buildPlaceholderAvatar();
                                            },
                                          )
                                        : _buildPlaceholderAvatar(),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _selectImageSource,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF9B1B1B),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton.icon(
                          onPressed: _selectImageSource,
                          icon: const Icon(Icons.photo_camera),
                          label: Text(
                            _selectedImage != null || _currentPhotoUrl != null
                                ? 'Change Photo'
                                : 'Add Photo',
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF9B1B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Add Map Section
                _buildMapSection(),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _retailerNameController,
                        decoration: const InputDecoration(
                          labelText: 'Retailer Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter retailer name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _shopNameController,
                        decoration: const InputDecoration(
                          labelText: 'Shop Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter shop name';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Location Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedState,
                        decoration: const InputDecoration(
                          labelText: 'State',
                          border: OutlineInputBorder(),
                        ),
                        items: _states
                            .map((state) => DropdownMenuItem<String>(
                                  value: state,
                                  child: Text(state),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedState = value;
                              // Reset city when state changes
                              _selectedCity = _citiesByState[value]?.first;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a state';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_selectedState != null)
                        DropdownButtonFormField<String>(
                          value: _selectedCity,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            border: OutlineInputBorder(),
                          ),
                          items: (_citiesByState[_selectedState!] ?? [])
                              .map((city) => DropdownMenuItem<String>(
                                    value: city,
                                    child: Text(city),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCity = value;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a city';
                            }
                            return null;
                          },
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _pinCodeController,
                        decoration: const InputDecoration(
                          labelText: 'PIN Code',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter PIN code';
                          }
                          if (value.length != 6) {
                            return 'PIN code must be 6 digits';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Business Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _gstController,
                        decoration: const InputDecoration(
                          labelText: 'GST Number (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Shop Status: '),
                          Switch(
                            value: _shopOpenStatus == 'Y',
                            onChanged: (value) {
                              setState(() {
                                _shopOpenStatus = value ? 'Y' : 'N';
                              });
                            },
                            activeColor: const Color(0xFF9B1B1B),
                          ),
                          Text(
                            _shopOpenStatus == 'Y' ? 'Open' : 'Closed',
                            style: TextStyle(
                              color: _shopOpenStatus == 'Y' ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B1B1B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading ? null : _updateRetailer,
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      width: 120,
      height: 120,
      color: Colors.grey.withOpacity(0.2),
      child: const Icon(
        Icons.person,
        size: 48,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildMapSection() {
    if (!_isLocationPermissionGranted) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'Location permission required',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _checkLocationPermission,
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isMapLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _currentPosition.latitude,
                  _currentPosition.longitude,
                ),
                zoom: 15,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _updateMarkers();
              },
              markers: _markers,
              onTap: (LatLng position) {
                setState(() {
                  _currentPosition = position;
                  _updateMarkers();
                });
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: ElevatedButton.icon(
            onPressed: () async {
              if (_currentPosition != null) {
                try {
                  final placemarks = await placemarkFromCoordinates(
                    _currentPosition.latitude,
                    _currentPosition.longitude,
                  );

                  if (placemarks.isNotEmpty) {
                    final place = placemarks.first;
                    final state = place.administrativeArea;
                    final city = place.subAdministrativeArea;
                    String? matchedState;
                    String? matchedCity;
                    // Find the closest matching state
                    if (state != null) {
                      matchedState = _states.firstWhere(
                        (s) => s.toLowerCase() == state.toLowerCase(),
                        orElse: () => '',
                      );
                    }
                    // Find the closest matching city in the dropdown list
                    if (matchedState != null && matchedState.isNotEmpty && city != null && _citiesByState.containsKey(matchedState)) {
                      matchedCity = _citiesByState[matchedState]!.firstWhere(
                        (c) => c.toLowerCase() == city.toLowerCase() || city.toLowerCase().contains(c.toLowerCase()) || c.toLowerCase().contains(city.toLowerCase()),
                        orElse: () => '',
                      );
                    }
                    setState(() {
                      _addressController.text = '${place.street}, ${place.subLocality}';
                      _pinCodeController.text = place.postalCode ?? '';
                      _selectedCountry = place.country;
                      _selectedState = matchedState;
                      _selectedCity = matchedCity;
                    });
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error getting address: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.location_on),
            label: const Text('Use Map Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
} 