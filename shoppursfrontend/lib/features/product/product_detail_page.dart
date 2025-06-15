import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../services/product_service.dart';
import '../../services/cart_service.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import 'dart:async';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({Key? key}) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final ProductService _productService = ProductService();
  final CartService _cartService = CartService();
  final AuthService _authService = AuthService();
  Product? _product;
  User? _user;
  bool _isLoading = true;
  String? _error;
  int _quantity = 1;
  int? _selectedUnitId;
  bool _isAdding = false;
  Map<String, dynamic>? _selectedUnit;
  bool _isInitialized = false;
  int _cartCount = 0;
  Timer? _cartCountTimer;
  int _selectedImageIndex = 0; // Track which image is currently displayed

  @override
  void initState() {
    super.initState();
    print('Initial state - selectedUnitId: $_selectedUnitId, selectedUnit: $_selectedUnit');
  }

  @override
  void dispose() {
    _cartCountTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final productId = ModalRoute.of(context)!.settings.arguments as int;
      _fetchProductAndUser(productId);
      _isInitialized = true;
    }
  }

  Future<void> _fetchProductAndUser(int productId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final productResult = await _productService.getProductDetails(productId, context: context);
      final user = await _authService.getUser();
      
      if (productResult['success'] != true) {
        throw Exception(productResult['message'] ?? 'Failed to load product');
      }
      
      final product = productResult['data'] as Product;
      
      if (!mounted) return;

      setState(() {
        _product = product;
        _user = user;
        _selectedImageIndex = 0; // Reset to first image when loading new product
        if (product.units != null && product.units.isNotEmpty) {
          final firstUnit = product.units[0];
          _selectedUnitId = firstUnit['PU_ID'] is int 
              ? firstUnit['PU_ID'] 
              : int.parse(firstUnit['PU_ID'].toString());
          _selectedUnit = firstUnit;
          _quantity = int.parse(firstUnit['PU_PROD_UNIT_VALUE'].toString());
          
          print('Initial unit setup - ID: $_selectedUnitId, Unit: $_selectedUnit');
        }
        _isLoading = false;
      });

      // Start fetching cart count after user is loaded and if they are a customer or employee
      if (user?.role.toLowerCase() == 'customer' || user?.role.toLowerCase() == 'employee') {
        await _fetchCartCount();
        // Setup periodic cart count refresh
        _cartCountTimer?.cancel(); // Cancel any existing timer
        _cartCountTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchCartCount());
      }
    } catch (e) {
      print('Error fetching product: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _updateSelectedUnit(int? unitId) {
    print('Updating unit: $unitId');
    if (_product == null || unitId == null) return;
    
    try {
      final newUnit = _product!.units.firstWhere(
        (unit) => unit['PU_ID'] == unitId,
      );

      print('Found new unit: $newUnit');

      if (!mounted) return;
      
      setState(() {
        _selectedUnitId = unitId;
        _selectedUnit = Map<String, dynamic>.from(newUnit); // Create a new map to ensure state update
        _quantity = int.parse(newUnit['PU_PROD_UNIT_VALUE'].toString());
      });
    } catch (e) {
      print('Error updating unit: $e');
    }
  }

  void _incrementQuantity() {
    if (_selectedUnit == null) return;
    final unitValue = int.parse(_selectedUnit!['PU_PROD_UNIT_VALUE'].toString());
    setState(() {
      _quantity += unitValue;
    });
  }

  void _decrementQuantity() {
    if (_selectedUnit == null) return;
    final unitValue = int.parse(_selectedUnit!['PU_PROD_UNIT_VALUE'].toString());
    if (_quantity > unitValue) {
      setState(() {
        _quantity -= unitValue;
      });
    }
  }

  double _calculateTotalPrice() {
    if (_selectedUnit == null) return 0.0;
    final unitRate = double.parse(_selectedUnit!['PU_PROD_RATE'].toString());
    final unitValue = int.parse(_selectedUnit!['PU_PROD_UNIT_VALUE'].toString());
    return (_quantity / unitValue) * unitRate;
  }

  Future<void> _fetchCartCount() async {
    if (_user?.role.toLowerCase() != 'customer' && _user?.role.toLowerCase() != 'employee') return;
    
    try {
      final cartData = await _cartService.getCartCount();
      if (mounted) {
        setState(() {
          _cartCount = cartData['totalItems'] ?? 0; // Using totalItems instead of totalQuantity
        });
      }
    } catch (e) {
      print('Error fetching cart count: $e');
    }
  }

  Future<void> _addToCart() async {
    if (_product == null || _selectedUnitId == null) return;
    setState(() {
      _isAdding = true;
    });
    try {
      final result = await _cartService.addToCart(
        productId: _product!.id,
        quantity: _quantity,
        unitId: _selectedUnitId!,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Added to cart'),
            backgroundColor: result['success'] == true ? Colors.green : Colors.red,
          ),
        );
        // Refresh cart count immediately after adding item
        await _fetchCartCount();
      }
    } catch (e) {
      print('Error adding to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAdding = false;
        });
      }
    }
  }

  Future<void> _editProduct() async {
    if (_product == null) return;
    
    final result = await Navigator.pushNamed(
      context,
      '/edit-product',
      arguments: _product,
    );
    
    // If the edit was successful, refresh the product data
    if (result == true) {
      final productId = ModalRoute.of(context)!.settings.arguments as int;
      _fetchProductAndUser(productId);
    }
  }

  Widget _buildActionButton() {
    if (_user == null) {
      return const SizedBox.shrink(); // No button if user data is not loaded
    }

    switch (_user!.role.toLowerCase()) {
      case 'admin':
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B1B1B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _editProduct,
            child: const Text(
              'Edit Product',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      case 'customer':
      case 'employee':
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B1B1B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isAdding ? null : _addToCart,
            child: _isAdding
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Add to Bag',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        );
      case 'deliver':
        return const SizedBox.shrink(); // No button for delivery users
      default:
        return const SizedBox.shrink(); // No button for unknown roles
    }
  }

  Widget _buildUnitDropdown() {
    if (_product == null || _product!.units.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Unit:', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: ButtonTheme(
              alignedDropdown: true,
              child: DropdownButton<int>(
                value: _selectedUnitId,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                items: _product!.units.map<DropdownMenuItem<int>>((unit) {
                  final id = unit['PU_ID'];
                  if (id == null) return const DropdownMenuItem<int>(child: Text('Invalid Unit'));
                  
                  final unitId = id is int ? id : int.parse(id.toString());
                  return DropdownMenuItem<int>(
                    value: unitId,
                    child: Text(
                      '${unit['PU_PROD_UNIT_VALUE']} ${unit['PU_PROD_UNIT']} - Rs. ${unit['PU_PROD_RATE']} each',
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  print('Dropdown value changed to: $value');
                  if (value != null && value != _selectedUnitId) {
                    _updateSelectedUnit(value);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<String> _getProductImages() {
    if (_product == null) return [];
    
    List<String> images = [];
    
    // Add main image if exists
    if (_product!.image1.isNotEmpty) {
      images.add(_product!.image1);
    }
    
    // Add second image if exists
    if (_product!.prodImage2 != null && _product!.prodImage2!.isNotEmpty) {
      images.add(_product!.prodImage2!);
    }
    
    // Add third image if exists
    if (_product!.prodImage3 != null && _product!.prodImage3!.isNotEmpty) {
      images.add(_product!.prodImage3!);
    }
    
    return images;
  }

  Widget _buildImageGallery() {
    final images = _getProductImages();
    
    if (images.isEmpty) {
      return Center(
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // Main Image
        Container(
          width: double.infinity,
          height: 250,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              '${ApiConfig.baseUrl}/uploads/products/${images[_selectedImageIndex]}',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
            ),
          ),
        ),
        
        // Thumbnail Images (only show if there are multiple images)
        if (images.length > 1) ...[
          const SizedBox(height: 16),
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedImageIndex;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImageIndex = index;
                          });
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF9B1B1B) : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              '${ApiConfig.baseUrl}/uploads/products/${images[index]}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported, size: 24, color: Colors.grey),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Product Detail',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _product == null
                  ? const Center(child: Text('Product not found'))
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            _buildImageGallery(),
                            const SizedBox(height: 16),
                            Text(
                              _product!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_selectedUnit != null) ...[
                              Row(
                                children: [
                                  Text(
                                    'MRP: ',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Rs. ${_product!.mrp}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SP: ',
                                    style: const TextStyle(
                                      color: Color(0xFF9B1B1B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Rs. ${_product!.sp}',
                                    style: const TextStyle(
                                      color: Color(0xFF9B1B1B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rs. ${_selectedUnit!['PU_PROD_RATE']} per ${_selectedUnit!['PU_PROD_UNIT_VALUE']} ${_selectedUnit!['PU_PROD_UNIT']}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Total: Rs. ${_calculateTotalPrice().toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              _product!.desc,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_product!.units.isNotEmpty) ...[
                              _buildUnitDropdown(),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Text('Quantity:', style: TextStyle(fontWeight: FontWeight.w500)),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: _selectedUnit != null ? _decrementQuantity : null,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '$_quantity',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: _selectedUnit != null ? _incrementQuantity : null,
                                  ),
                                  if (_selectedUnit != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedUnit!['PU_PROD_UNIT'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                            const SizedBox(height: 24),
                            _buildActionButton(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
      floatingActionButton: (_user?.role.toLowerCase() == 'customer' || _user?.role.toLowerCase() == 'employee')
          ? Stack(
              children: [
                FloatingActionButton(
                  backgroundColor: const Color(0xFF9B1B1B),
                  onPressed: () {
                    Navigator.pushNamed(context, '/cart').then((_) {
                      // Refresh cart count when returning from cart page
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
            )
          : null,
    );
  }
} 