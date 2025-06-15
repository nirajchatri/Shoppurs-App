import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import '../../services/address_service.dart';
import '../../models/address_model.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'package:mobile_scanner/mobile_scanner.dart' hide Address;
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/retailer_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/common_bottom_navbar.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final OrderService _orderService = OrderService();
  final AddressService _addressService = AddressService();
  final AuthService _authService = AuthService();
  final RetailerService _retailerService = RetailerService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _searchError = '';
  bool _showSearchDropdown = false;
  bool _isLoading = true;
  bool _isAddressLoading = true;
  String _error = '';
  String? _addressError;
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic>? _retailerInfo;
  Address? _defaultAddress;
  User? _user;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if this is a return navigation from another page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isInitialized) {
        _fetchOrders();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadUserAndData() async {
    try {
      final user = await _authService.getUser();
      if (mounted) {
        setState(() {
          _user = user;
          _isInitialized = true;
        });
        _fetchOrders();
        if (_user?.role.toLowerCase() == 'customer') {
          _loadDefaultAddress();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isInitialized = true;
        });
      }
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        _searchOrders(query);
      } else {
        setState(() {
          _searchResults = [];
          _showSearchDropdown = false;
          _fetchOrders(); // Reset to show all orders
        });
      }
    });
  }

  Future<void> _searchOrders(String query) async {
    setState(() {
      _isSearching = true;
      _searchError = '';
      _showSearchDropdown = true;
    });
    try {
      final results = _user?.role.toLowerCase() == 'admin'
          ? await _orderService.adminSearchOrders(query)
          : _user?.role.toLowerCase() == 'employee'
          ? await _orderService.employeeSearchOrders(query)
          : await _orderService.searchOrders(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
        _showSearchDropdown = true;
      });
    } catch (e) {
      setState(() {
        _searchError = e.toString();
        _isSearching = false;
        _showSearchDropdown = true;
      });
    }
  }

  void _onSearchResultTap(Map<String, dynamic> order) {
    setState(() {
      _showSearchDropdown = false;
      _searchController.text = '';
    });
    Navigator.pushNamed(
      context,
      '/order-details',
      arguments: order['ORDER_ID'],
    );
  }

  void _onShowAllResults() {
    setState(() {
      _showSearchDropdown = false;
      if (_searchResults.isNotEmpty) {
        _orders = _searchResults; // Show all search results
      }
    });
  }

  Future<void> _fetchOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');
      
      Map<String, dynamic> response;
      http.Response apiResponse;
      
      if (_user?.role.toLowerCase() == 'admin') {
        // Admin: fetch all orders with pending status
        apiResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/admin/fetch-all-orders?status=pending'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      } else if (_user?.role.toLowerCase() == 'employee') {
        // Employee: fetch orders with confirmed status and limit of 5
        apiResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/employee/orders?status=confirmed&limit=5'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      } else {
        // Customer: fetch customer orders
        apiResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/orders/list'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      }
      
      if (apiResponse.statusCode == 200) {
        response = jsonDecode(apiResponse.body);
      } else {
        throw Exception('Failed to load orders: ${apiResponse.statusCode}');
      }

      setState(() {
        if (_user?.role.toLowerCase() == 'employee') {
          // Employee response structure - keep as is
          _orders = (response['data']['orders'] as List).cast<Map<String, dynamic>>();
        } else if (_user?.role.toLowerCase() == 'admin') {
          // Admin response structure
          _orders = (response['data']['orders'] as List).cast<Map<String, dynamic>>();
          // Admin API doesn't have retailer_info, so set to null
          _retailerInfo = null;
        } else {
          // Customer response structure
          _orders = (response['data']['orders'] as List).cast<Map<String, dynamic>>();
          _retailerInfo = response['data']['retailer_info'] as Map<String, dynamic>?;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final formatter = DateFormat('HH:mm hrs, d MMM yyyy');
    return formatter.format(date);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openRetailerSelection() async {
    final result = await Navigator.pushNamed(context, '/retailer-selection');
    if (result == true) {
      // Refresh orders if a retailer was selected
      _fetchOrders();
    }
  }

  Future<void> _openQRCodeScanner() async {
    // Check camera permission
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required for QR code scanning'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Navigate to QR scanner
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRCodeScannerPage(
          onQRCodeScanned: _getRetailerByPhone,
          title: 'Scan Retailer QR Code',
        ),
      ),
    );
  }

  Future<void> _getRetailerByPhone(String qrCode) async {
    try {
      print('Scanning QR code: $qrCode');
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');
      
      print('Making API call to: ${ApiConfig.baseUrl}/api/employee/get-retailer-by-phone/$qrCode');
      
      // Get retailer by phone number from QR code
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/employee/get-retailer-by-phone/$qrCode'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        final retailerData = data['data'];
        final phoneNumber = retailerData['RET_MOBILE_NO'].toString();
        
        print('Retailer found, setting for ordering: ${retailerData['RET_NAME']} - $phoneNumber');
        
        // Set retailer for ordering using the direct method
        final shopName = retailerData['RET_SHOP_NAME']?.toString() ?? retailerData['RET_NAME']?.toString() ?? '';
        await _setSelectedRetailerPhone(phoneNumber);
        await _setSelectedRetailerShopName(shopName);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Retailer selected: ${retailerData['RET_NAME']}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Navigate to cart page after selecting retailer
          Navigator.pushReplacementNamed(context, '/cart');
        }
      } else {
        print('Retailer not found: ${data['message']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Retailer not found'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _getRetailerByPhone: $e');
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F9),
        elevation: 0,
        title: _user?.role?.toLowerCase() == 'admin' || _user?.role?.toLowerCase() == 'employee'
          ? const Text(
              'Orders',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            )
          : Row(
          children: [
            const Icon(Icons.location_on, color: Colors.black, size: 22),
            const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/address-list');
                },
                child: _isAddressLoading
                    ? const SizedBox(
                        height: 18,
                        child: LinearProgressIndicator(minHeight: 2),
                      )
                    : _defaultAddress != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                              Text(
                                '${_defaultAddress!.address}, ${_defaultAddress!.city}, ${_defaultAddress!.state}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          )
                        : Text(
                            _addressError != null
                                ? 'No address found'
                                : 'No address set',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
              ),
            ),
          ],
        ),
        toolbarHeight: _user?.role?.toLowerCase() == 'admin' || _user?.role?.toLowerCase() == 'employee' ? 56 : 60,
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search your orders',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _user?.role.toLowerCase() == 'employee'
                              ? IconButton(
                                  icon: const Icon(Icons.camera_alt_outlined),
                                  onPressed: _openQRCodeScanner,
                                )
                              : null,
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
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Text(
                  'Review Orders',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error.isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _error,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchOrders,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _orders.isEmpty
                            ? const Center(
                                child: Text(
                                  'No orders found',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  // Clear search results when refreshing
                                  setState(() {
                                    _searchController.clear();
                                    _searchResults = [];
                                    _showSearchDropdown = false;
                                  });
                                  await _fetchOrders();
                                },
                                color: const Color(0xFF9B1B1B),
                                backgroundColor: Colors.white,
                                strokeWidth: 2.5,
                                displacement: 40,
                                child: ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                                  itemCount: _orders.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.transparent),
                                  itemBuilder: (context, index) {
                                    final order = _orders[index];
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(context, '/order-details', arguments: order);
                                      },
                                      child: Container(
                                        color: Colors.white,
                                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _retailerInfo != null && _retailerInfo!['RET_PHOTO'] != null
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(8),
                                                    child: Image.network(
                                                      _retailerInfo!['RET_PHOTO'],
                                                      width: 60,
                                                      height: 60,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => Container(
                                                        width: 60,
                                                        height: 60,
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFF9B1B1B).withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: const Icon(
                                                          Icons.shopping_bag_outlined,
                                                          color: Color(0xFF9B1B1B),
                                                          size: 30,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF9B1B1B).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.shopping_bag_outlined,
                                                color: Color(0xFF9B1B1B),
                                                size: 30,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Order No - ${order['ORDER_NUMBER']}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    _formatDate(order['CREATED_DATE']),
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    '₹${double.parse(order['ORDER_TOTAL'].toString()).toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      color: Color(0xFFFE6A00),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '${order['total_items'] ?? order['TOTAL_ITEMS'] ?? 0} items',
                                                        style: const TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '•',
                                                        style: TextStyle(
                                                          color: Colors.grey.shade400,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        order['ORDER_STATUS'].toString().toUpperCase(),
                                                        style: TextStyle(
                                                          color: _getStatusColor(order['ORDER_STATUS']),
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
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
                                  child: Text('No orders found'),
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
                                    final order = _searchResults[index];
                                    return ListTile(
                                      title: Text(
                                        'Order ${order['ORDER_NUMBER']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        '${order['total_items'] ?? order['TOTAL_ITEMS'] ?? 0} items • ${_formatDate(order['CREATED_DATE'])}',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                      trailing: Text(
                                        '₹${order['ORDER_TOTAL']}',
                                        style: const TextStyle(
                                          color: Color(0xFFFE6A00),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onTap: () => _onSearchResultTap(order),
                                    );
                                  },
                                ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: CommonBottomNavBar(
        currentIndex: 0, // Orders page is the ORDERS tab
        user: _user,
      ),
      floatingActionButton: _user?.role.toLowerCase() == 'employee'
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF9B1B1B),
              onPressed: _openRetailerSelection,
              child: const Icon(Icons.store, color: Colors.white),
            )
          : null,
    );
  }

  Future<void> _setSelectedRetailerPhone(String phoneNumber) async {
    try {
      // Use SharedPreferences to store the selected retailer phone
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_retailer_phone', phoneNumber);
    } catch (e) {
      print('Error setting retailer phone: $e');
      rethrow;
    }
  }

  Future<void> _setSelectedRetailerShopName(String shopName) async {
    try {
      // Use SharedPreferences to store the selected retailer shop name
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_retailer_shop_name', shopName);
    } catch (e) {
      print('Error setting retailer shop name: $e');
      rethrow;
    }
  }
}

class QRCodeScannerPage extends StatefulWidget {
  final Future<void> Function(String) onQRCodeScanned;
  final String title;
  
  const QRCodeScannerPage({
    Key? key,
    required this.onQRCodeScanned,
    this.title = 'Scan QR Code',
  }) : super(key: key);

  @override
  _QRCodeScannerPageState createState() => _QRCodeScannerPageState();
}

class _QRCodeScannerPageState extends State<QRCodeScannerPage> {
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
                      print('QR Code detected: ${barcode.rawValue!}');
                      
                      // Close the scanner first
                      Navigator.pop(context);
                      
                      // Then call the callback function
                      await widget.onQRCodeScanned(barcode.rawValue!);
                    } catch (e) {
                      print('Error processing QR code: $e');
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
             child: Center(
               child: Container(
                 width: 250,
                 height: 250,
                 decoration: BoxDecoration(
                   border: Border.all(
                     color: const Color(0xFF9B1B1B),
                     width: 3,
                   ),
                   borderRadius: BorderRadius.circular(10),
                 ),
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
                    : 'Place the QR code inside the frame to scan',
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

 