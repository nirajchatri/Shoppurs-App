import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../models/subcategory_model.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../services/product_service.dart';
import '../../services/category_service.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import 'dart:async';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../widgets/common_bottom_navbar.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({Key? key}) : super(key: key);

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  Category? category;
  SubCategory? selectedSubCategory;
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final AuthService _authService = AuthService();
  final CartService _cartService = CartService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _searchError = '';
  bool _showSearchDropdown = false;
  
  List<Product> _products = [];
  List<SubCategory> _subCategories = [];
  User? _user;
  bool _isLoading = true;
  bool _isSubCategoryLoading = true;
  String? _error;
  String? _subCategoryError;
  Timer? _cartCountTimer;
  int _cartCount = 0;
  Map<int, bool> _isAddingToCart = {};
  Map<int, int> _selectedQuantities = {};
  Map<int, Map<String, dynamic>> _selectedUnits = {};

  Future<void> _fetchAndSetFirstCategory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    final result = await _categoryService.getCategories(context: context);
    
    setState(() {
      if (result['success'] == true) {
        final categories = List<Category>.from(result['data'] ?? []);
        if (categories.isNotEmpty) {
          category = categories.first;
          _error = null;
          _fetchSubCategories();
        } else {
          _error = 'No categories available';
          _isLoading = false;
          _isSubCategoryLoading = false;
        }
      } else {
        _error = result['message'] ?? 'Failed to load categories';
        _isLoading = false;
        _isSubCategoryLoading = false;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args != null && args is Category) {
      category = args;
      _fetchSubCategories();
    } else {
      _fetchAndSetFirstCategory();
    }
    _searchController.addListener(_onSearchChanged);
    _loadUserData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    _cartCountTimer?.cancel();
    super.dispose();
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

  void _onSearchResultTap(Map<String, dynamic> product) {
    setState(() {
      _showSearchDropdown = false;
    });
    Navigator.pushNamed(context, '/product-detail', arguments: product['PROD_ID']);
  }

  void _onShowAllResults() {
    setState(() {
      _showSearchDropdown = false;
    });
  }

  Future<void> _fetchSubCategories() async {
    if (category == null) return;
    
    setState(() {
      _isSubCategoryLoading = true;
      _subCategoryError = null;
    });
    
    final result = await _categoryService.getSubCategoriesByCategoryId(category!.id, context: context);
    
    setState(() {
      _isSubCategoryLoading = false;
      
      if (result['success'] == true) {
        final subCategories = List<SubCategory>.from(result['data'] ?? []);
        _subCategories = subCategories;
        
        // Automatically select the first subcategory if available
        if (subCategories.isNotEmpty) {
          selectedSubCategory = subCategories.first;
          _fetchProducts(selectedSubCategory!.id);
        } else {
          _isLoading = false;
        }
      } else {
        _subCategoryError = result['message'] ?? 'Failed to load subcategories';
        _isLoading = false;
      }
    });
  }

  Future<void> _fetchProducts(int subCategoryId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    final result = await _productService.getProductsBySubCategory(subCategoryId, context: context);
    
    setState(() {
      _isLoading = false;
      
      if (result['success'] == true) {
        _products = List<Product>.from(result['data'] ?? []);
        _error = null;
      } else {
        _products = [];
        _error = result['message'] ?? 'Failed to load products';
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getUser();
      setState(() {
        _user = user;
      });
      
      // Start fetching cart count if user is a customer
      if (user?.role.toLowerCase() == 'customer') {
        await _fetchCartCount();
        // Setup periodic cart count refresh
        _cartCountTimer?.cancel();
        _cartCountTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchCartCount());
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _fetchCartCount() async {
    if (_user?.role.toLowerCase() != 'customer') return;
    
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

  void _showAddToCartDialog(Product product) {
    int quantity = _selectedQuantities[product.id] ?? int.parse(product.units[0]['PU_PROD_UNIT_VALUE'].toString());
    Map<String, dynamic> selectedUnit = _selectedUnits[product.id] ?? product.units[0];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(product.name),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Unit Selection
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
                      child: DropdownButton<Map<String, dynamic>>(
                        value: selectedUnit,
                        isExpanded: true,
                        items: product.units.map<DropdownMenuItem<Map<String, dynamic>>>((unit) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: unit,
                            child: Text(
                              '${unit['PU_PROD_UNIT_VALUE']} ${unit['PU_PROD_UNIT']} - Rs. ${unit['PU_PROD_RATE']} each',
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedUnit = value;
                              quantity = int.parse(value['PU_PROD_UNIT_VALUE'].toString());
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Quantity Selection
                  Row(
                    children: [
                      const Text('Quantity:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          final unitValue = int.parse(selectedUnit['PU_PROD_UNIT_VALUE'].toString());
                          if (quantity > unitValue) {
                            setState(() {
                              quantity -= unitValue;
                            });
                          }
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          quantity.toString(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          final unitValue = int.parse(selectedUnit['PU_PROD_UNIT_VALUE'].toString());
                          setState(() {
                            quantity += unitValue;
                          });
                        },
                      ),
                      Text(
                        selectedUnit['PU_PROD_UNIT'],
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Show total price
                  Text(
                    'Total: Rs. ${_calculateTotalPrice(quantity, selectedUnit)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B1B1B),
                  ),
                  child: const Text(
                    'Add to Cart',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _addToCart(
                      product,
                      quantity,
                      selectedUnit['PU_ID'] is int 
                          ? selectedUnit['PU_ID'] 
                          : int.parse(selectedUnit['PU_ID'].toString()),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Save the selected values for this product
      _selectedQuantities[product.id] = quantity;
      _selectedUnits[product.id] = selectedUnit;
    });
  }

  double _calculateTotalPrice(int quantity, Map<String, dynamic> unit) {
    final unitRate = double.parse(unit['PU_PROD_RATE'].toString());
    final unitValue = int.parse(unit['PU_PROD_UNIT_VALUE'].toString());
    return (quantity / unitValue) * unitRate;
  }

  Future<void> _addToCart(Product product, int quantity, int unitId) async {
    if (_isAddingToCart[product.id] == true) return;

    setState(() {
      _isAddingToCart[product.id] = true;
    });

    try {
      final result = await _cartService.addToCart(
        productId: product.id,
        quantity: quantity,
        unitId: unitId,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Added to cart'),
            backgroundColor: result['success'] == true ? Colors.green : Colors.red,
          ),
        );
        await _fetchCartCount();
      }
    } catch (e) {
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
          _isAddingToCart[product.id] = false;
        });
      }
    }
  }

  Future<void> _openBarcodeScanner() async {
    // Check camera permission
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required for barcode scanning'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F6F9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          category?.name ?? 'Products',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Column(
            children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for groceries and more',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.camera_alt_outlined),
                        onPressed: _openBarcodeScanner,
                      ),
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
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: _isSubCategoryLoading
                ? const Center(child: CircularProgressIndicator())
                : _subCategoryError != null
                    ? Center(child: Text(_subCategoryError!, style: const TextStyle(color: Colors.red)))
                    : _subCategories.isEmpty
                        ? const Center(child: Text('No subcategories found'))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: _subCategories.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final subCat = _subCategories[index];
                              final isSelected = selectedSubCategory?.id == subCat.id;
                              return InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  setState(() {
                                    selectedSubCategory = subCat;
                                  });
                                  _fetchProducts(subCat.id);
                                },
                                child: Container(
                                  width: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: isSelected 
                                      ? Border.all(color: const Color(0xFF9B1B1B), width: 2)
                                      : Border.all(color: Colors.transparent, width: 2),
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 60,
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected ? const Color(0xFF9B1B1B) : Colors.grey.shade200,
                                            width: 1,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            '${ApiConfig.baseUrl}/uploads/subcategory/${subCat.imageUrl}',
                                            width: 52,
                                            height: 52,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                const Icon(Icons.image_not_supported, size: 38, color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        subCat.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                          color: isSelected ? const Color(0xFF9B1B1B) : Colors.black,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : _products.isEmpty
                        ? const Center(child: Text('No products found'))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            itemCount: _products.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.transparent),
                            itemBuilder: (context, index) {
                              final prod = _products[index];
                              return Container(
                                color: Colors.white,
                                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                padding: const EdgeInsets.all(12),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/product-detail',
                                      arguments: prod.id,
                                    ).then((_) {
                                      // Refresh cart count when returning from detail page
                                      _fetchCartCount();
                                    });
                                  },
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Image.network(
                                        '${ApiConfig.baseUrl}/uploads/products/${prod.image1}',
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(Icons.image_not_supported, size: 38, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              prod.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              prod.desc,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Text(
                                                  'Rs. ${prod.mrp}',
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontWeight: FontWeight.w500,
                                                    decoration: TextDecoration.lineThrough,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Rs. ${prod.sp}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF9B1B1B),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
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
      floatingActionButton: _user?.role.toLowerCase() == 'customer'
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
        : _user?.role.toLowerCase() == 'admin'
            ? FloatingActionButton(
                backgroundColor: const Color(0xFF9B1B1B),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/add-product',
                    arguments: {
                      'categoryId': category?.id,
                      'categoryName': category?.name,
                      'subCategoryId': selectedSubCategory?.id,
                      'subCategoryName': selectedSubCategory?.name,
                    },
                  ).then((result) {
                    // Refresh products if a new product was added
                    if (result == true && selectedSubCategory != null) {
                      _fetchProducts(selectedSubCategory!.id);
                    }
                  });
                },
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
      bottomNavigationBar: CommonBottomNavBar(
        currentIndex: 1, // Product list page is the PRODUCTS tab
        user: _user,
      ),
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