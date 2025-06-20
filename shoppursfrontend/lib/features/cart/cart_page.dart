import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import '../../services/retailer_service.dart';
import '../../models/user_model.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/api_config.dart';
import 'package:app_settings/app_settings.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final AuthService _authService = AuthService();
  final ProductService _productService = ProductService();
  final RetailerService _retailerService = RetailerService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  
  List<dynamic> cartItems = [];
  int total = 0;
  bool isLoading = true;
  String? error;
  Map<String, dynamic>? defaultAddress;
  User? _user;
  String? _selectedRetailerPhone;
  
  // Search related variables
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _searchError = '';
  bool _showSearchDropdown = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    fetchCartData();
    fetchDefaultAddress();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
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

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        _searchProducts(query);
      } else {
        setState(() {
          _searchResults = [];
          _showSearchDropdown = false;
        });
      }
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

  Future<void> _onSearchResultTap(Map<String, dynamic> product) async {
    setState(() {
      _showSearchDropdown = false;
    });
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('Adding to cart...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');
      
      final response = await http.post(
        Uri.parse(ApiConfig.cartAddAuto),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'productId': product['PROD_ID'],
        }),
      );

      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        // Hide loading snackbar and show success
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Item added to cart successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Refresh cart data
        await fetchCartData();
      } else {
        throw Exception(data['message'] ?? 'Failed to add item to cart');
      }
    } catch (e) {
      // Hide loading snackbar and show error
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding to cart: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _onShowAllResults() {
    setState(() {
      _showSearchDropdown = false;
    });
    // Navigate to product list or search results page
    Navigator.pushNamed(context, '/product-list');
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

  Future<void> fetchCartData() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');
      final response = await http.get(
        Uri.parse(ApiConfig.cartFetch),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          cartItems = data['data']['items'];
          total = data['data']['total'];
          defaultAddress = data['data']['selectedAddress'];
          isLoading = false;
        });
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch cart data');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> changeUnit(int cartId, int unitId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');
      
      final response = await http.post(
        Uri.parse(ApiConfig.cartEditUnit),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'cartId': cartId,
          'unitId': unitId,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        await fetchCartData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Unit changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(data['message'] ?? 'Failed to change unit');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error changing unit: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerPage(
          onBarcodeScanned: _addProductByBarcode,
        ),
      ),
    );

    // When scanner is closed, refresh cart data
    if (result == true) {
      await fetchCartData();
    }
  }

  Future<void> _addProductByBarcode(String barcode) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');
      
      // Add product to cart using barcode
      final response = await http.post(
        Uri.parse(ApiConfig.cartAddByBarcode),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'PRDB_BARCODE': barcode,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Product added to cart successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
        
        // Refresh cart data
        await fetchCartData();
        
        // Return to cart page
        if (mounted) {
          Navigator.pop(context, true);
        }
        return data['data']; // Return the product data for the scanner
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to add product to cart'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        return null;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return null;
    }
  }

  int _calculateTotal() {
    int calculatedTotal = 0;
    for (var item in cartItems) {
      calculatedTotal += item['itemTotal'] as int;
    }
    return calculatedTotal;
  }

  Future<void> fetchDefaultAddress() async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');
      final response = await http.get(
        Uri.parse(ApiConfig.addressDefault),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          defaultAddress = data['data'];
        });
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch default address');
      }
    } catch (e) {
      print('Error fetching default address: $e');
    }
  }

  Future<void> increaseQuantity(int cartId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');
      
      final response = await http.post(
        Uri.parse(ApiConfig.cartIncreaseQuantity),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'cartId': cartId,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        await fetchCartData();
      } else {
        throw Exception(data['message'] ?? 'Failed to increase quantity');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error increasing quantity: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> decreaseQuantity(int cartId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');
      
      final response = await http.post(
        Uri.parse(ApiConfig.cartDecreaseQuantity),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'cartId': cartId,
        }),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        await fetchCartData();
      } else {
        throw Exception(data['message'] ?? 'Failed to decrease quantity');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error decreasing quantity: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildEmptyCartState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 120,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add some products to get started',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
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
                onPressed: () {
                  Navigator.pushNamed(context, '/home');
                },
                child: const Text(
                  'Browse Products',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      );
    }

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
          'Your Cart',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Search Field - Always visible
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildRetailerBanner(),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search for more products...',
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
                  ],
                ),
              ),
              // Cart Content
              Expanded(
                child: cartItems.isEmpty
                    ? _buildEmptyCartState()
                    : SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
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
                                  children: cartItems.map((item) {
                                    final product = item['product'];
                                    final selectedUnit = item['selectedUnit'];
                                    final availableUnits = item['availableUnits'] as List<dynamic>;
                                    
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                                                    // Product Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product['images']['image1'] != null && product['images']['image1'].toString().isNotEmpty
                                  ? '${ApiConfig.baseUrl}/uploads/products/${product['images']['image1']}'
                                  : '',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                  ),
                            ),
                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product['name'],
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                // Unit Dropdown
                                                Container(
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[50],
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: Colors.grey[300]!),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                                  child: DropdownButtonHideUnderline(
                                                    child: DropdownButton<int>(
                                                      value: selectedUnit['id'],
                                                      isDense: true,
                                                      isExpanded: true,
                                                      style: TextStyle(
                                                        color: Colors.grey[700],
                                                        fontSize: 13,
                                                      ),
                                                      items: availableUnits.map((unit) {
                                                        return DropdownMenuItem<int>(
                                                          value: unit['id'],
                                                          child: Text(
                                                            '${unit['value']} ${unit['name']} - ₹${unit['rate']}',
                                                            overflow: TextOverflow.ellipsis,
                                                            style: const TextStyle(fontSize: 13),
                                                          ),
                                                        );
                                                      }).toList(),
                                                      onChanged: (newUnitId) {
                                                        if (newUnitId != null && newUnitId != selectedUnit['id']) {
                                                          changeUnit(item['cartId'], newUnitId);
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Text(
                                                      '₹${selectedUnit['rate']}',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    if (product['mrp'] != product['sellingPrice']) ...[
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '₹${product['mrp']}',
                                                        style: TextStyle(
                                                          decoration: TextDecoration.lineThrough,
                                                          color: Colors.grey[600],
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.grey),
                                                    onPressed: () => decreaseQuantity(item['cartId']),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                                    child: Text(
                                                      '${item['quantity']}',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                                    onPressed: () => increaseQuantity(item['cartId']),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '₹${item['itemTotal']}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Cart Summary
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
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
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Total Amount',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '₹$total',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/payment');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF9B1B1B),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        'Proceed to Pay',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
          // Search Dropdown Overlay
          if (_showSearchDropdown && _searchController.text.trim().isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              top: 80, // Adjusted to account for search field
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF9B1B1B),
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on orders/cart
              break;
            case 1:
              Navigator.pushNamed(context, '/home');
              break;
            case 2:
              Navigator.pushNamed(context, '/self-retailer-detail');
              break;
            case 3:
              Navigator.pushNamed(context, '/home');
              break;
            case 4:
              // Account page navigation
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'ORDERS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'PRODUCTS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            label: 'RETAILERS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'SEARCH',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'ACCOUNT',
          ),
        ],
      ),
    );
  }

  Widget _buildRetailerBanner() {
    if (_user?.role.toLowerCase() != 'employee' || _selectedRetailerPhone == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9B1B1B).withOpacity(0.1),
            const Color(0xFF9B1B1B).withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF9B1B1B).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF9B1B1B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.store,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ordering for Retailer',
                  style: TextStyle(
                    color: Color(0xFF9B1B1B),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Phone: $_selectedRetailerPhone',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/retailer-selection').then((result) {
                if (result == true) {
                  _loadSelectedRetailerPhone();
                }
              });
            },
            icon: const Icon(
              Icons.edit,
              color: Color(0xFF9B1B1B),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class BarcodeScannerPage extends StatefulWidget {
  final Future<dynamic> Function(String) onBarcodeScanned;
  
  const BarcodeScannerPage({
    Key? key,
    required this.onBarcodeScanned,
  }) : super(key: key);

  @override
  _BarcodeScannerPageState createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  List<Map<String, dynamic>> scannedProducts = [];
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
        title: const Text(
          'Scan Barcodes',
          style: TextStyle(color: Colors.white),
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
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Done',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
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
                    
                    // Add product to cart
                    final productData = await widget.onBarcodeScanned(barcode.rawValue!);
                    
                    if (productData != null) {
                      setState(() {
                        scannedProducts.add({
                          'barcode': barcode.rawValue,
                          'productName': productData['productName'],
                          'quantity': productData['quantity'],
                          'rate': productData['rate'],
                          'total': productData['total'],
                        });
                      });
                    }
                    
                    // Allow next scan after a short delay
                    await Future.delayed(const Duration(milliseconds: 1500));
                    setState(() {
                      isProcessing = false;
                    });
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
          // Scanned Products List
          if (scannedProducts.isNotEmpty)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.shopping_cart, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Scanned Items: ${scannedProducts.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: scannedProducts.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          color: Colors.grey,
                        ),
                        itemBuilder: (context, index) {
                          final product = scannedProducts[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['productName'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Qty: ${product['quantity']} | Rate: ₹${product['rate']}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹${product['total']}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Instructions
          Positioned(
            bottom: scannedProducts.isEmpty ? 100 : 240,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
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
                  if (scannedProducts.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Keep scanning or tap "Done" to finish',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
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