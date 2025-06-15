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

class AdminEditRetailerPage extends StatefulWidget {
  const AdminEditRetailerPage({Key? key}) : super(key: key);

  @override
  State<AdminEditRetailerPage> createState() => _AdminEditRetailerPageState();
}

class _AdminEditRetailerPageState extends State<AdminEditRetailerPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  String? _error;
  int? _retailerId;
  String? _userRole;

  // Form controllers
  final _shopNameController = TextEditingController();
  final _retailerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstController = TextEditingController();
  final _mobileController = TextEditingController();
  final _retailerCodeController = TextEditingController();
  final _retailerTypeController = TextEditingController();
  
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
  LatLng _currentPosition = const LatLng(19.0760, 72.8777); // Default to Mumbai
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
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final user = await _authService.getUser();
      setState(() {
        _userRole = user?.role.toLowerCase();
      });
    } catch (e) {
      print('Error loading user role: $e');
    }
  }

  void _populateFormData(Map<String, dynamic> data) {
    _retailerId = data['RET_ID'];
    _shopNameController.text = data['RET_SHOP_NAME'] ?? '';
    _retailerNameController.text = data['RET_NAME'] ?? '';
    _addressController.text = data['RET_ADDRESS'] ?? '';
    _pinCodeController.text = data['RET_PIN_CODE']?.toString() ?? '';
    _emailController.text = data['RET_EMAIL_ID'] ?? '';
    _gstController.text = data['RET_GST_NO'] ?? '';
    _mobileController.text = data['RET_MOBILE_NO']?.toString() ?? '';
    _retailerCodeController.text = data['RET_CODE'] ?? '';
    _retailerTypeController.text = data['RET_TYPE'] ?? '';
    
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
      
      // Set current position if available
      if (data['RET_LAT'] != null && data['RET_LONG'] != null) {
        _currentPosition = LatLng(
          double.parse(data['RET_LAT'].toString()),
          double.parse(data['RET_LONG'].toString()),
        );
      }
      
      // Set current photo URL
      if (data['RET_PHOTO'] != null && data['RET_PHOTO'].toString().isNotEmpty) {
        _currentPhotoUrl = ApiConfig.retailerPhoto(data['RET_PHOTO']);
      }
    });
  }

  Future<void> _updateRetailer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_retailerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Retailer ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_userRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User role not loaded. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      // Create multipart request based on user role
      String endpoint;
      if (_userRole == 'admin') {
        endpoint = '${ApiConfig.baseUrl}/api/admin/edit-retailer/$_retailerId';
      } else {
        endpoint = '${ApiConfig.baseUrl}/api/employee/retailers/$_retailerId/edit';
      }
      
      var request = http.MultipartRequest('PUT', Uri.parse(endpoint));

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add form fields based on user role
      print('User role: $_userRole');
      print('Retailer ID: $_retailerId');
      
      // Validate minimum required fields
      if (_retailerNameController.text.trim().isEmpty) {
        throw Exception('Retailer name is required');
      }
      if (_shopNameController.text.trim().isEmpty) {
        throw Exception('Shop name is required');
      }
      if (_mobileController.text.trim().isEmpty) {
        throw Exception('Mobile number is required');
      }
      
      if (_userRole == 'admin') {
        // Admin fields (more comprehensive) - Send all fields for admin
        final adminFields = <String, String>{
          // Required fields
          'RET_NAME': _retailerNameController.text.trim(),
          'RET_SHOP_NAME': _shopNameController.text.trim(),
          'RET_MOBILE_NO': _mobileController.text.trim(),
          'RET_ADDRESS': _addressController.text.trim(),
          'RET_EMAIL_ID': _emailController.text.trim(),
          'RET_PIN_CODE': _pinCodeController.text.trim(),
          
          // Location fields
          'RET_COUNTRY': _selectedCountry ?? 'India',
          'RET_STATE': _selectedState ?? '',
          'RET_CITY': _selectedCity ?? '',
          'RET_LAT': _currentPosition.latitude.toString(),
          'RET_LONG': _currentPosition.longitude.toString(),
          
          // Status fields
          'SHOP_OPEN_STATUS': _shopOpenStatus == 'Y' ? '1' : '0',
          'RET_DEL_STATUS': 'active',
          
          // Optional fields (can be empty)
          'RET_CODE': _retailerCodeController.text.trim(),
          'RET_TYPE': _retailerTypeController.text.trim(),
          'RET_GST_NO': _gstController.text.trim(),
        };
        
        print('=== ADMIN EDIT RETAILER PAYLOAD DEBUG ===');
        print('Retailer ID: $_retailerId');
        print('Endpoint: ${ApiConfig.baseUrl}/api/admin/edit-retailer/$_retailerId');
        print('Admin fields:');
        adminFields.forEach((key, value) {
          print('  $key: $value');
        });
        print('Image field name: profileImage');
        print('Image selected: ${_selectedImage != null}');
        if (_selectedImage != null) {
          print('Image path: ${_selectedImage!.path}');
          print('Image size: ${_selectedImage!.lengthSync()} bytes');
        }
        print('=== END PAYLOAD DEBUG ===');
        
        request.fields.addAll(adminFields);
      } else {
        // Employee fields (limited access)
        final employeeFields = <String, String>{};
        
        // Only add non-empty fields for employee
        if (_retailerNameController.text.isNotEmpty) {
          employeeFields['RET_NAME'] = _retailerNameController.text;
        }
        if (_shopNameController.text.isNotEmpty) {
          employeeFields['RET_SHOP_NAME'] = _shopNameController.text;
        }
        if (_mobileController.text.isNotEmpty) {
          employeeFields['RET_MOBILE_NO'] = _mobileController.text;
        }
        if (_emailController.text.isNotEmpty) {
          employeeFields['RET_EMAIL_ID'] = _emailController.text;
        }
        if (_addressController.text.isNotEmpty) {
          employeeFields['RET_ADDRESS'] = _addressController.text;
        }
        if (_pinCodeController.text.isNotEmpty) {
          employeeFields['RET_PIN_CODE'] = _pinCodeController.text;
        }
        if (_selectedCity != null && _selectedCity!.isNotEmpty) {
          employeeFields['RET_CITY'] = _selectedCity!;
        }
        if (_selectedState != null && _selectedState!.isNotEmpty) {
          employeeFields['RET_STATE'] = _selectedState!;
        }
        print('Employee fields: $employeeFields');
        request.fields.addAll(employeeFields);
      }
      
      // Final check to ensure we have fields to update (only for employee role)
      if (_userRole != 'admin' && request.fields.isEmpty) {
        throw Exception('No fields to update. Please fill in at least one field.');
      }

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
        
        // Use the correct field name expected by the backend middleware
        String imageFieldName = 'profileImage';
        
        request.files.add(
          await http.MultipartFile.fromPath(
            imageFieldName,
            _selectedImage!.path,
            contentType: http_parser.MediaType.parse(contentType),
          ),
        );
      }

      // Send request
      print('Sending request to: ${request.url}');
      print('Request fields: ${request.fields}');
      print('Request files count: ${request.files.length}');
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retailer updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        // Handle different error cases
        String errorMessage = data['message'] ?? 'Failed to update retailer';
        if (response.statusCode == 400) {
          errorMessage = 'Bad request: ${data['message'] ?? 'Invalid data provided'}';
        } else if (response.statusCode == 401) {
          errorMessage = 'Authentication failed. Please login again.';
        } else if (response.statusCode == 403) {
          errorMessage = 'Access denied. You don\'t have permission to edit this retailer.';
        } else if (response.statusCode == 404) {
          errorMessage = 'Retailer not found.';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = 'Error updating retailer: ${e.toString()}';
      
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
      );
      
      if (image != null) {
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
        _isMapLoading = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isMapLoading = false;
      });
      return;
    }

    setState(() {
      _isLocationPermissionGranted = true;
      _isMapLoading = false;
    });
    _updateMarkers();
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
    _mobileController.dispose();
    _retailerCodeController.dispose();
    _retailerTypeController.dispose();
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
        title: Text(
          _userRole == 'admin' ? 'Edit Retailer (Admin)' : 'Edit Retailer',
          style: const TextStyle(
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
                // Profile Photo Section
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
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Basic Information
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
                      // Admin-only fields
                      if (_userRole == 'admin') ...[
                        TextFormField(
                          controller: _retailerCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Retailer Code (Optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _retailerTypeController,
                          decoration: const InputDecoration(
                            labelText: 'Retailer Type (Optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _mobileController,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter mobile number';
                          }
                          if (value.length != 10) {
                            return 'Mobile number must be 10 digits';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Location Information
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

                // Business Information
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
                      // GST field only for admin users
                      if (_userRole == 'admin') ...[
                        TextFormField(
                          controller: _gstController,
                          decoration: const InputDecoration(
                            labelText: 'GST Number (Optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Shop status only for admin users
                      if (_userRole == 'admin') ...[
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button
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
} 