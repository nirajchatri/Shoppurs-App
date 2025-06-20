import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../models/user_model.dart';
import '../../services/category_service.dart';
import '../../services/address_service.dart';
import '../../services/auth_service.dart';
import '../../models/address_model.dart';
import '../../services/product_service.dart';
import '../../services/cart_service.dart';
import '../../services/settings_service.dart';
import '../../services/retailer_service.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../services/brand_service.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../services/advertising_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart' hide Address;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app_settings/app_settings.dart';

import '../../config/api_config.dart';
import '../../widgets/common_bottom_navbar.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CategoryService _categoryService = CategoryService();
  final AddressService _addressService = AddressService();
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();
  final CartService _cartService = CartService();
  final BrandService _brandService = BrandService();
  final AdvertisingService _advertisingService = AdvertisingService();
  final SettingsService _settingsService = SettingsService();
  final RetailerService _retailerService = RetailerService();
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();
  Timer? _debounce;
  Timer? _cartCountTimer;
  Timer? _autoPlayTimer;
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _brands = [];
  List<Map<String, dynamic>> _advertising = [];
  bool _isSearching = false;
  bool _isBrandsLoading = false;
  bool _isAdvertisingLoading = false;
  String _searchError = '';
  String? _brandsError;
  String? _advertisingError;
  bool _showSearchDropdown = false;
  int _cartCount = 0;
  int _currentAdIndex = 0;

  List<Category> _categories = [];
  Address? _defaultAddress;
  User? _user;
  bool _isLoading = true;
  bool _isAddressLoading = true;
  String? _error;
  String? _addressError;
  bool _isLoadingLocation = false;
  String? _locationError;
  String _appName = 'SHOPPURS APP'; // Default name until loaded
  String? _selectedRetailerPhone;
  
  // DWR related variables
  Map<String, dynamic>? _dwrData;
  bool _isDwrLoading = false;
  Timer? _dwrTimer;
  List<Map<String, dynamic>> _stations = [];
  bool _isStationsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadDefaultAddress();
    _loadUserData();
    _loadBrands();
    _loadAdvertising();
    _loadAppName();
    _searchController.addListener(_onSearchChanged);
    _startAutoPlay();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _pageController.dispose();
    _debounce?.cancel();
    _cartCountTimer?.cancel();
    _autoPlayTimer?.cancel();
    _dwrTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchDropdown = false;
      });
      return;
    }
    
    // Increased debounce time to reduce API calls
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _searchProducts(query);
    });
  }

  Future<void> _searchProducts(String query) async {
    setState(() {
      _isSearching = true;
      _searchError = '';
      _showSearchDropdown = true;
    });
    
    final result = await _productService.searchProducts(query, context: context);
    
    setState(() {
      _isSearching = false;
      _showSearchDropdown = true;
      
      if (result['success'] == true) {
        _searchResults = List<Map<String, dynamic>>.from(result['data'] ?? []);
        _searchError = '';
      } else {
        _searchResults = [];
        _searchError = result['message'] ?? 'Search failed';
      }
    });
  }

  void _onSearchResultTap(Map<String, dynamic> product) {
    setState(() {
      _showSearchDropdown = false;
    });
    Navigator.pushNamed(context, '/product-detail', arguments: product['PROD_ID']);
  }

  void _onShowAllResults() {
    // Optionally navigate to a full search results page
    setState(() {
      _showSearchDropdown = false;
    });
    // Navigator.pushNamed(context, '/search-results', arguments: _searchController.text.trim());
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    final result = await _categoryService.getCategories(context: context);
    
    setState(() {
      _isLoading = false;
      
      if (result['success'] == true) {
        _categories = List<Category>.from(result['data'] ?? []);
        _error = null;
      } else {
        _categories = [];
        _error = result['message'] ?? 'Failed to load categories';
      }
    });
  }

  Future<void> _loadDefaultAddress() async {
    setState(() {
      _isAddressLoading = true;
      _addressError = null;
    });
    try {
      final address = await _addressService.getDefaultAddress();
      setState(() {
        _defaultAddress = address;
        _isAddressLoading = false;
      });
    } catch (e) {
      setState(() {
        _addressError = e.toString();
        _isAddressLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getUser();
      setState(() {
        _user = user;
      });
      
      // Load retailer phone for employees
      if (user?.role.toLowerCase() == 'employee') {
        _loadSelectedRetailerPhone();
        _loadTodayDwr();
        // Setup periodic DWR refresh
        _dwrTimer?.cancel();
        _dwrTimer = Timer.periodic(const Duration(minutes: 5), (_) => _loadTodayDwr());
      }
      
      // Start fetching cart count if user is a customer or employee
      if (user?.role.toLowerCase() == 'customer' || user?.role.toLowerCase() == 'employee') {
        await _fetchCartCount();
        // Setup periodic cart count refresh - increased interval to reduce API calls
        _cartCountTimer?.cancel();
        _cartCountTimer = Timer.periodic(const Duration(minutes: 2), (_) => _fetchCartCount());
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadSelectedRetailerPhone() async {
    try {
      final phone = await _retailerService.getSelectedRetailerPhone();
      if (mounted) {
        setState(() {
          _selectedRetailerPhone = phone;
        });
      }
    } catch (e) {
      print('Error loading retailer phone: $e');
    }
  }

  Future<void> _loadTodayDwr() async {
    if (_isDwrLoading) return;
    
    setState(() {
      _isDwrLoading = true;
    });
    
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/employee/dwr/today'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _dwrData = data;
            _isDwrLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load DWR data');
      }
    } catch (e) {
      print('Error loading DWR: $e');
      if (mounted) {
        setState(() {
          _isDwrLoading = false;
        });
      }
    }
  }

  Future<void> _startDay() async {
    _showStartDayDialog();
  }

  Future<void> _loadStations() async {
    setState(() {
      _isStationsLoading = true;
    });
    
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/employee/sta-master'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _stations = List<Map<String, dynamic>>.from(data['data']);
            _isStationsLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load stations');
        }
      } else {
        throw Exception('Failed to load stations');
      }
    } catch (e) {
      print('Error loading stations: $e');
      if (mounted) {
        setState(() {
          _isStationsLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading stations: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadStationsForDialog() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/employee/sta-master'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              _stations = List<Map<String, dynamic>>.from(data['data']);
            });
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to load stations');
        }
      } else {
        throw Exception('Failed to load stations');
      }
    } catch (e) {
      print('Error loading stations for dialog: $e');
      rethrow; // Re-throw to handle in the dialog
    }
  }

  void _showStartDayDialog() async {
    int? selectedStationId;
    bool isStartingDay = false;
    bool isDialogStationsLoading = _stations.isEmpty;
    List<Map<String, dynamic>> dialogStations = List.from(_stations);
    String? stationsError;
    
    // Load stations if empty
    if (_stations.isEmpty) {
      try {
        await _loadStationsForDialog();
        dialogStations = List.from(_stations);
        isDialogStationsLoading = false;
      } catch (e) {
        isDialogStationsLoading = false;
        stationsError = e.toString();
      }
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Start Your Day',
                style: TextStyle(
                  color: Color(0xFF9B1B1B),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select your starting station:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isDialogStationsLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(
                          color: Color(0xFF9B1B1B),
                        ),
                      ),
                    )
                  else if (stationsError != null)
                    Column(
                      children: [
                        Text(
                          'Error loading stations: $stationsError',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () async {
                            setDialogState(() {
                              isDialogStationsLoading = true;
                              stationsError = null;
                            });
                            
                            try {
                              await _loadStationsForDialog();
                              setDialogState(() {
                                dialogStations = List.from(_stations);
                                isDialogStationsLoading = false;
                              });
                            } catch (e) {
                              setDialogState(() {
                                isDialogStationsLoading = false;
                                stationsError = e.toString();
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9B1B1B),
                          ),
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  else if (dialogStations.isEmpty)
                    const Text(
                      'No stations available',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    DropdownButtonFormField<int>(
                      value: selectedStationId,
                      decoration: InputDecoration(
                        hintText: 'Choose a station',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF9B1B1B),
                            width: 2,
                          ),
                        ),
                      ),
                      items: dialogStations.map((station) {
                        return DropdownMenuItem<int>(
                          value: station['STA_ID'],
                          child: Text(
                            station['STA_NAME'],
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedStationId = value;
                        });
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isStartingDay ? null : () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: (selectedStationId == null || isStartingDay || isDialogStationsLoading) 
                      ? null 
                      : () async {
                          setDialogState(() {
                            isStartingDay = true;
                          });
                          
                          await _startDayWithStation(selectedStationId!, dialogContext);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B1B1B),
                  ),
                  child: isStartingDay
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Start Your Day',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _startDayWithStation(int stationId, BuildContext dialogContext) async {
    try {
      // Get current location
      String location = await _getCurrentLocationString();
      
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/employee/dwr/start-day'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'DWR_START_STA': stationId,
          'DWR_START_LOC': location,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        // Close the station selection dialog
        Navigator.of(dialogContext).pop();
        
        // Show success dialog
        _showDayStartedDialog(data['message'] ?? 'Day started successfully!');
      } else {
        throw Exception(data['message'] ?? 'Failed to start day');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Close dialog on error
      if (Navigator.of(dialogContext).canPop()) {
        Navigator.of(dialogContext).pop();
      }
    }
  }

  Future<String> _getCurrentLocationString() async {
    try {
      if (kIsWeb) {
        // For web, return a default location or show error
        throw Exception('Location services not available on web');
      }

      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return '${position.longitude},${position.latitude}';
    } catch (e) {
      print('Error getting location: $e');
      // Return a default location or rethrow the error
      throw Exception('Failed to get current location: ${e.toString()}');
    }
  }

  void _showDayStartedDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Day Started!',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadTodayDwr(); // Refresh DWR data
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B1B1B),
              ),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _endDay() async {
    _showEndDayDialog();
  }

  String _getDwrButtonText() {
    if (_dwrData == null) return 'Start Your Day';
    
    final hasStartedDay = _dwrData!['has_started_day'] ?? false;
    final data = _dwrData!['data'];
    
    if (data != null) {
      // Check if DWR_END_LOC exists and DWR_SUBMIT date is today
      final dwrEndLoc = data['DWR_END_LOC'];
      final dwrSubmit = data['DWR_SUBMIT'];
      final todayDate = _dwrData!['today_date'];
      
      if (dwrEndLoc != null && dwrSubmit != null) {
        final submitDate = DateTime.parse(dwrSubmit).toLocal();
        final today = DateTime.now();
        
        if (submitDate.year == today.year &&
            submitDate.month == today.month &&
            submitDate.day == today.day) {
          return 'Today\'s Day Closed';
        }
      }
    }
    
    return hasStartedDay ? 'End Your Day' : 'Start Your Day';
  }

  bool _isDwrButtonDisabled() {
    if (_dwrData == null || _isDwrLoading) return true;
    
    final data = _dwrData!['data'];
    
    if (data != null) {
      final dwrEndLoc = data['DWR_END_LOC'];
      final dwrSubmit = data['DWR_SUBMIT'];
      
      if (dwrEndLoc != null && dwrSubmit != null) {
        final submitDate = DateTime.parse(dwrSubmit).toLocal();
        final today = DateTime.now();
        
        if (submitDate.year == today.year &&
            submitDate.month == today.month &&
            submitDate.day == today.day) {
          return true; // Day already closed
        }
      }
    }
    
    return _isDwrLoading;
  }

  void _showEndDayDialog() async {
    int? selectedStationId;
    bool isEndingDay = false;
    bool isDialogStationsLoading = _stations.isEmpty;
    List<Map<String, dynamic>> dialogStations = List.from(_stations);
    String? stationsError;
    
    // Controllers for form fields
    final TextEditingController expensesController = TextEditingController();
    final TextEditingController remarksController = TextEditingController();
    
    // Load stations if empty
    if (_stations.isEmpty) {
      try {
        await _loadStationsForDialog();
        dialogStations = List.from(_stations);
        isDialogStationsLoading = false;
      } catch (e) {
        isDialogStationsLoading = false;
        stationsError = e.toString();
      }
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'End Your Day',
                style: TextStyle(
                  color: Color(0xFF9B1B1B),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Station Selection
                    const Text(
                      'Select your ending station:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (isDialogStationsLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(
                            color: Color(0xFF9B1B1B),
                          ),
                        ),
                      )
                    else if (stationsError != null)
                      Column(
                        children: [
                          Text(
                            'Error loading stations: $stationsError',
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () async {
                              setDialogState(() {
                                isDialogStationsLoading = true;
                                stationsError = null;
                              });
                              
                              try {
                                await _loadStationsForDialog();
                                setDialogState(() {
                                  dialogStations = List.from(_stations);
                                  isDialogStationsLoading = false;
                                });
                              } catch (e) {
                                setDialogState(() {
                                  isDialogStationsLoading = false;
                                  stationsError = e.toString();
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9B1B1B),
                            ),
                            child: const Text(
                              'Retry',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      )
                    else if (dialogStations.isEmpty)
                      const Text(
                        'No stations available',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      DropdownButtonFormField<int>(
                        value: selectedStationId,
                        decoration: InputDecoration(
                          hintText: 'Choose a station',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF9B1B1B),
                              width: 2,
                            ),
                          ),
                        ),
                        items: dialogStations.map((station) {
                          return DropdownMenuItem<int>(
                            value: station['STA_ID'],
                            child: Text(
                              station['STA_NAME'],
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedStationId = value;
                          });
                        },
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Expenses Field
                    const Text(
                      'Expenses (₹):',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: expensesController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Enter expenses amount',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF9B1B1B),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Remarks Field
                    const Text(
                      'Remarks:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: remarksController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter remarks about your day',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF9B1B1B),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isEndingDay ? null : () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: (selectedStationId == null || isEndingDay || isDialogStationsLoading) 
                      ? null 
                      : () async {
                          setDialogState(() {
                            isEndingDay = true;
                          });
                          
                          await _endDayWithDetails(
                            selectedStationId!,
                            expensesController.text.trim(),
                            remarksController.text.trim(),
                            dialogContext,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B1B1B),
                  ),
                  child: isEndingDay
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'End Your Day',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _endDayWithDetails(
    int stationId,
    String expenses,
    String remarks,
    BuildContext dialogContext,
  ) async {
    try {
      // Get current location
      String location = await _getCurrentLocationString();
      
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');
      
      // Prepare request body
      Map<String, dynamic> requestBody = {
        'DWR_END_STA': stationId,
        'DWR_END_LOC': location,
        'DWR_REMARKS': remarks.isNotEmpty ? remarks : null,
      };
      
      // Add expenses if provided
      if (expenses.isNotEmpty) {
        double? expenseAmount = double.tryParse(expenses);
        if (expenseAmount != null) {
          requestBody['DWR_EXPENSES'] = expenseAmount;
        }
      }
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/employee/dwr/end-day'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      
      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        // Close the form dialog
        Navigator.of(dialogContext).pop();
        
        // Show success dialog
        _showDayEndedDialog(data['message'] ?? 'Day ended successfully!');
      } else {
        throw Exception(data['message'] ?? 'Failed to end day');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Close dialog on error
      if (Navigator.of(dialogContext).canPop()) {
        Navigator.of(dialogContext).pop();
      }
    }
  }

  void _showDayEndedDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Day Ended!',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadTodayDwr(); // Refresh DWR data
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B1B1B),
              ),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onDwrButtonPressed() {
    if (_isDwrButtonDisabled()) return;
    
    final hasStartedDay = _dwrData?['has_started_day'] ?? false;
    
    if (hasStartedDay) {
      _endDay();
    } else {
      _startDay();
    }
  }

  Future<void> _fetchCartCount() async {
    if (_user?.role.toLowerCase() != 'customer' && _user?.role.toLowerCase() != 'employee') return;
    
    try {
      final cartData = await _cartService.getCartCount();
      if (mounted) {
        setState(() {
          _cartCount = cartData['totalItems'] ?? 0;
        });
      }
    } catch (e) {
      print('Error fetching cart count: $e');
    }
  }

  Future<void> _loadBrands() async {
    setState(() {
      _isBrandsLoading = true;
      _brandsError = null;
    });
    
    final result = await _brandService.getBrands(context: context);
    
    setState(() {
      _isBrandsLoading = false;
      
      if (result['success'] == true) {
        _brands = List<Map<String, dynamic>>.from(result['data'] ?? []);
        _brandsError = null;
      } else {
        _brands = [];
        _brandsError = result['message'] ?? 'Failed to load brands';
      }
    });
  }

  Future<void> _loadAdvertising() async {
    setState(() {
      _isAdvertisingLoading = true;
      _advertisingError = null;
    });
    
    final result = await _advertisingService.getAdvertising(context: context);
    
    setState(() {
      _isAdvertisingLoading = false;
      
      if (result['success'] == true) {
        _advertising = List<Map<String, dynamic>>.from(result['data'] ?? []);
        _advertisingError = null;
      } else {
        _advertising = [];
        _advertisingError = result['message'] ?? 'Failed to load advertising';
      }
    });
  }

  Future<void> _loadAppName() async {
    try {
      final appName = await _settingsService.getAppName();
      setState(() {
        _appName = appName;
      });
    } catch (e) {
      // Keep default name if error occurs
      print('Error loading app name: $e');
    }
  }

  void _showAdminOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Admin Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9B1B1B),
              ),
            ),
            const SizedBox(height: 24),
            _buildAdminOption(
              icon: Icons.add_shopping_cart,
              title: 'Add Products',
              subtitle: 'Add new products to inventory',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/add-product');
              },
            ),
            const SizedBox(height: 16),
            _buildAdminOption(
              icon: Icons.people_outline,
              title: 'Manage Users',
              subtitle: 'View and manage user accounts',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/manage-users');
              },
            ),
            const SizedBox(height: 16),
            _buildAdminOption(
              icon: Icons.pending_actions,
              title: 'View Pending Orders',
              subtitle: 'Review orders awaiting processing',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/orders');
              },
            ),
            const SizedBox(height: 16),
            _buildAdminOption(
              icon: Icons.category_outlined,
              title: 'Category Management',
              subtitle: 'Manage product categories',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/category-management');
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF9B1B1B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF9B1B1B),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.status;
    if (status.isDenied) {
      _showLocationPermissionDialog();
    }
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'We need your location to provide better service and show nearby stores. '
            'Please grant location permission.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Not Now'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B1B1B),
              ),
              child: const Text(
                'Grant Permission',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _requestLocationPermission();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    if (kIsWeb) {
      setState(() {
        _locationError = 'Location services are not available in web browser. Please use the mobile app for location features.';
        _isLoadingLocation = false;
      });
      return;
    }

    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Create an address object
        Address currentLocation = Address(
          addressId: 0,
          userId: 0,
          address: '${place.street}, ${place.subLocality}',
          city: place.locality ?? '',
          state: place.administrativeArea ?? '',
          country: place.country ?? '',
          pincode: place.postalCode ?? '',
          landmark: '',
          addressType: 'Current Location',
          isDefault: false,
          delStatus: 'N',
          createdDate: DateTime.now(),
          updatedDate: DateTime.now(),
        );

        setState(() {
          _defaultAddress = currentLocation;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _locationError = e.toString();
        _isLoadingLocation = false;
      });
      print('Error getting location: $e');
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    // Increased interval to reduce performance impact
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_advertising.isNotEmpty && mounted) {
        final nextPage = (_currentAdIndex + 1) % _advertising.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Widget _buildAdvertisingCarousel() {
    if (_isAdvertisingLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_advertisingError != null) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_advertisingError!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadAdvertising,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_advertising.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No advertising banners available')),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentAdIndex = index;
              });
            },
            itemCount: _advertising.length,
            itemBuilder: (context, index) {
              final item = _advertising[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    '${ApiConfig.baseUrl}/uploads/advertising/${item['image_url']}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.error)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        SmoothPageIndicator(
          controller: _pageController,
          count: _advertising.length,
          effect: ExpandingDotsEffect(
            dotHeight: 8,
            dotWidth: 8,
            activeDotColor: Theme.of(context).primaryColor,
            dotColor: Colors.grey.shade300,
          ),
        ),
      ],
    );
  }

  Future<void> _openBarcodeScanner() async {
    final status = await Permission.camera.status;
    if (status.isDenied) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        if (result.isPermanentlyDenied) {
          await openAppSettings();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required for barcode scanning'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
      return;
    }

    // Navigate to barcode scanner
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerPage(
          onBarcodeScanned: _getProductByBarcode,
          title: 'Scan Product Barcode',
        ),
      ),
    );
  }

  Future<void> _getProductByBarcode(String barcode) async {
    try {
      print('Scanning barcode: $barcode');
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');
      
      print('Making API call to: ${ApiConfig.productsGetByBarcode}');
      
      // Get product by barcode
      final response = await http.post(
        Uri.parse(ApiConfig.productsGetByBarcode),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'PRDB_BARCODE': barcode,
        }),
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        final productId = data['data']['productId'];
        print('Product found, navigating to product ID: $productId');
        
        // Navigate to product detail page
        if (mounted) {
          Navigator.pushNamed(
            context,
            '/product-detail',
            arguments: productId,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Product found successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        print('Product not found: ${data['message']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Product not found'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _getProductByBarcode: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brands = [
      {'name': 'Amul', 'image': 'assets/images/brand_8.png'},
      {'name': 'Pepsi', 'image': 'assets/images/brand_2.png'},
      {'name': 'Britannia', 'image': 'assets/images/brand_3.png'},
      {'name': 'Parle', 'image': 'assets/images/brand_4.png'},
      {'name': 'Cadbury', 'image': 'assets/images/brand_5.png'},
      {'name': 'CocaCola', 'image': 'assets/images/brand_6.png'},
      {'name': 'ITC', 'image': 'assets/images/brand_7.png'},
      {'name': 'Colgate', 'image': 'assets/images/brand_1.png'},
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F9),
        elevation: 0,
        title: Row(
          children: [
            if (_user?.role.toLowerCase() == 'admin') ...[
              const Text(
                'ADMIN',
                style: TextStyle(
                  color: Color(0xFF9B1B1B),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const Spacer(),
            ] else if (_user?.role.toLowerCase() == 'employee') ...[
              const Text(
                'EMPLOYEE LOGIN',
                style: TextStyle(
                  color: Color(0xFF9B1B1B),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const Spacer(),
            ] else ...[
              const Icon(Icons.location_on, color: Colors.black, size: 22),
              const SizedBox(width: 6),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/address-list');
                  },
                  child: _buildAddressSection(),
                ),
              ),
              const Spacer(),
            ],
            if (_user?.role.toLowerCase() == 'customer' || _user?.role.toLowerCase() == 'employee')
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      Navigator.pushNamed(context, '/cart').then((_) {
                        _fetchCartCount();
                      });
                    },
                  ),
                  if (_cartCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          _cartCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
        toolbarHeight: 60,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search for groceries and more',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt_outlined),
                          onPressed: _openBarcodeScanner,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFFF8F6F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _appName,
                                    style: const TextStyle(
                                      color: Color(0xFFB00060),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'shop purchases made easy',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Delivering in',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: const [
                                    Icon(Icons.flash_on, color: Color(0xFFB00060), size: 20),
                                    SizedBox(width: 4),
                                    Text(
                                      '12 Hrs',
                                      style: TextStyle(
                                        color: Color(0xFFB00060),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(thickness: 1, color: Color(0xFFE0CFE6)),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                'want branded products for your retail store ? We are here to deliver all branded products in your retail store.',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: Image.asset(
                                'assets/images/hourglass_illustration.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Store Category',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_error != null)
                    Center(
                      child: Column(
                        children: [
                          Text(_error!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadCategories,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (_categories.isEmpty)
                    const Center(child: Text('No categories found'))
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 18,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/product-list',
                              arguments: cat,
                            );
                          },
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.network(
                                  '${ApiConfig.baseUrl}/uploads/category/${cat.imageUrl}',
                                  width: double.infinity,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image_not_supported, size: 38, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                cat.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 18),
                  _buildAdvertisingCarousel(),
                  const SizedBox(height: 18),
                  const Text(
                    'Brands In Store',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_isBrandsLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_brandsError != null)
                    Center(
                      child: Column(
                        children: [
                          Text(_brandsError!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadBrands,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (_brands.isEmpty)
                    const Center(child: Text('No brands found'))
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: _brands.length,
                      itemBuilder: (context, index) {
                        final brand = _brands[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            '${ApiConfig.baseUrl}/uploads/brands/${brand['image_url']}',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported, size: 38, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_showSearchDropdown && _searchController.text.trim().isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              top: 60,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _searchError.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(_searchError, style: const TextStyle(color: Colors.red)),
                            )
                          : _searchResults.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('No results found'),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: _searchResults.length + 1,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    if (index == _searchResults.length) {
                                      return ListTile(
                                        title: Text.rich(
                                          TextSpan(
                                            text: 'Show all results for ',
                                            style: const TextStyle(color: Colors.black),
                                            children: [
                                              TextSpan(
                                                text: _searchController.text.trim(),
                                                style: const TextStyle(color: Color(0xFF9B1B1B), fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                        onTap: _onShowAllResults,
                                      );
                                    }
                                    final prod = _searchResults[index];
                                    return ListTile(
                                      leading: prod['PROD_IMAGE_1'] != null && prod['PROD_IMAGE_1'].toString().isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                '${ApiConfig.baseUrl}/uploads/products/${prod['PROD_IMAGE_1']}',
                                                width: 38,
                                                height: 38,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : const Icon(Icons.image, size: 38, color: Colors.grey),
                                      title: _highlightSearchTerm(prod['PROD_NAME'] ?? '', _searchController.text.trim()),
                                      onTap: () => _onSearchResultTap(prod),
                                    );
                                  },
                                ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: CommonBottomNavBar(
        currentIndex: 1, // Home page is the PRODUCTS tab
        user: _user,
      ),
    );
  }

  Widget _buildAddressSection() {
    if (_isLoadingLocation) {
      return const SizedBox(
        height: 18,
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    if (kIsWeb) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Web Browser',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            'Location features available in mobile app',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    if (_defaultAddress != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _defaultAddress!.addressType.isNotEmpty
                    ? _defaultAddress!.addressType
                    : 'Default Address',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (_defaultAddress!.addressType == 'Current Location')
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: _getCurrentLocation,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          Text(
            '${_defaultAddress!.address}, ${_defaultAddress!.city}, ${_defaultAddress!.state}',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location Access Required',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          _locationError ?? 'Enable location for better service',
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _highlightSearchTerm(String text, String term) {
    if (term.isEmpty) return Text(text);
    final lcText = text.toLowerCase();
    final lcTerm = term.toLowerCase();
    final start = lcText.indexOf(lcTerm);
    if (start == -1) return Text(text);
    final end = start + term.length;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(text: text.substring(start, end), style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: text.substring(end)),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_user?.role.toLowerCase() == 'employee') {
      // DWR floating action button for employees
      return FloatingActionButton.extended(
        backgroundColor: _isDwrButtonDisabled() 
            ? Colors.grey 
            : const Color(0xFF9B1B1B),
        onPressed: _isDwrButtonDisabled() ? null : _onDwrButtonPressed,
        icon: _isDwrLoading 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                _getDwrButtonText().contains('Start') 
                    ? Icons.play_arrow 
                    : _getDwrButtonText().contains('End')
                        ? Icons.stop
                        : Icons.check_circle,
                color: Colors.white,
              ),
        label: Text(
          _getDwrButtonText(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (_user?.role.toLowerCase() == 'customer') {
      // Cart floating action button for customers
      return Stack(
        children: [
          FloatingActionButton(
            backgroundColor: const Color(0xFF9B1B1B),
            onPressed: () {
              Navigator.pushNamed(context, '/cart').then((_) {
                _fetchCartCount();
              });
            },
            child: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
          ),
          if (_cartCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  _cartCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    }
    
    return null; // No floating action button for other roles
  }
}

class BarcodeScannerPage extends StatefulWidget {
  final Future<void> Function(String) onBarcodeScanned;
  final String title;
  
  const BarcodeScannerPage({
    Key? key,
    required this.onBarcodeScanned,
    this.title = 'Scan Barcode',
  }) : super(key: key);

  @override
  _BarcodeScannerPageState createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  bool isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.white);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                return const Icon(Icons.camera_front, color: Colors.white);
              },
            ),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) async {
              if (!isProcessing) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final barcode = barcodes.first;
                  if (barcode.rawValue != null) {
                    setState(() {
                      isProcessing = true;
                    });
                    
                    try {
                      print('Barcode detected: ${barcode.rawValue!}');
                      
                      // Close the scanner first
                      Navigator.pop(context);
                      
                      // Then call the callback function
                      await widget.onBarcodeScanned(barcode.rawValue!);
                    } catch (e) {
                      print('Error processing barcode: $e');
                      // Reset processing state on error
                      if (mounted) {
                        setState(() {
                          isProcessing = false;
                        });
                      }
                    }
                  }
                }
              }
            },
          ),
          // Overlay with scanning area
          Container(
            decoration: ShapeDecoration(
              shape: ScannerOverlayShape(
                borderColor: const Color(0xFF9B1B1B),
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 4,
                cutOutSize: 250,
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                isProcessing 
                    ? 'Processing...' 
                    : 'Place the barcode inside the frame to scan',
                style: TextStyle(
                  color: isProcessing ? Colors.yellow : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayShape extends ShapeBorder {
  const ScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    double? cutOutSize,
    double? cutOutWidth,
    double? cutOutHeight,
  })  : cutOutWidth = cutOutWidth ?? cutOutSize ?? 250,
        cutOutHeight = cutOutHeight ?? cutOutSize ?? 250;

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutWidth;
  final double cutOutHeight;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderHeightSize = height / 2;
    final cutOutWidth =
        this.cutOutWidth < width ? this.cutOutWidth : width - borderWidth;
    final cutOutHeight =
        this.cutOutHeight < height ? this.cutOutHeight : height - borderWidth;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromLTWH(
      rect.left + (width - cutOutWidth) / 2 + borderWidth,
      rect.top + (height - cutOutHeight) / 2 + borderWidth,
      cutOutWidth - borderWidth * 2,
      cutOutHeight - borderWidth * 2,
    );

    canvas
      ..drawPath(
          Path.combine(
            PathOperation.difference,
            Path()..addRect(rect),
            Path()
              ..addRRect(RRect.fromRectAndRadius(
                  cutOutRect, Radius.circular(borderRadius)))
              ..close(),
          ),
          backgroundPaint)
      ..drawRRect(
          RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
          borderPaint);

    // Draw corner borders
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Top left corner
    canvas.drawPath(
        Path()
          ..moveTo(cutOutRect.left - borderWidth, cutOutRect.top)
          ..lineTo(cutOutRect.left - borderWidth, cutOutRect.top - borderLength)
          ..moveTo(cutOutRect.left, cutOutRect.top - borderWidth)
          ..lineTo(cutOutRect.left + borderLength, cutOutRect.top - borderWidth),
        cornerPaint);

    // Top right corner
    canvas.drawPath(
        Path()
          ..moveTo(cutOutRect.right + borderWidth, cutOutRect.top)
          ..lineTo(cutOutRect.right + borderWidth, cutOutRect.top - borderLength)
          ..moveTo(cutOutRect.right, cutOutRect.top - borderWidth)
          ..lineTo(cutOutRect.right - borderLength, cutOutRect.top - borderWidth),
        cornerPaint);

    // Bottom left corner
    canvas.drawPath(
        Path()
          ..moveTo(cutOutRect.left - borderWidth, cutOutRect.bottom)
          ..lineTo(cutOutRect.left - borderWidth, cutOutRect.bottom + borderLength)
          ..moveTo(cutOutRect.left, cutOutRect.bottom + borderWidth)
          ..lineTo(cutOutRect.left + borderLength, cutOutRect.bottom + borderWidth),
        cornerPaint);

    // Bottom right corner
    canvas.drawPath(
        Path()
          ..moveTo(cutOutRect.right + borderWidth, cutOutRect.bottom)
          ..lineTo(cutOutRect.right + borderWidth, cutOutRect.bottom + borderLength)
          ..moveTo(cutOutRect.right, cutOutRect.bottom + borderWidth)
          ..lineTo(cutOutRect.right - borderLength, cutOutRect.bottom + borderWidth),
        cornerPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return ScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
} 