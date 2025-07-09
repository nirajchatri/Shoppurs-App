import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/product_model.dart';
import 'dart:async';

class LowStockProductsPage extends StatefulWidget {
  const LowStockProductsPage({Key? key}) : super(key: key);

  @override
  State<LowStockProductsPage> createState() => _LowStockProductsPageState();
}

class _LowStockProductsPageState extends State<LowStockProductsPage> {
  final AdminService _adminService = AdminService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  List<Map<String, dynamic>> _products = [];
  Map<String, dynamic>? _statistics;
  Map<String, dynamic>? _filters;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  String? _error;
  bool _isUpdatingStock = false;

  // Filter options
  String _selectedType = 'all';
  String? _selectedCategory;
  String? _selectedSubCategory;
  String _sortBy = 'PROD_QOH';
  String _sortOrder = 'ASC';
  int _currentPage = 1;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _resetAndRefresh();
    });
  }

  Future<void> _loadProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreData = true;
        _products.clear();
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final result = await _adminService.getLowStockProducts(
        page: _currentPage,
        limit: _limit,
        type: _selectedType,
        category: _selectedCategory,
        subCategory: _selectedSubCategory,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        search: _searchController.text.trim().isEmpty 
            ? null 
            : _searchController.text.trim(),
      );

      if (result['success'] == true) {
        final data = result['data'];
        final newProducts = List<Map<String, dynamic>>.from(data['products'] ?? []);
        
        setState(() {
          if (isRefresh || _currentPage == 1) {
            _products = newProducts;
          } else {
            _products.addAll(newProducts);
          }
          
          _statistics = data['statistics'];
          _filters = data['filters'];
          _hasMoreData = data['pagination']['hasNext'] ?? false;
          _isLoading = false;
          _isLoadingMore = false;
          _error = null;
        });
      } else {
        throw Exception(result['message'] ?? 'Failed to load products');
      }
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadProducts();
  }

  void _resetAndRefresh() {
    _currentPage = 1;
    _loadProducts(isRefresh: true);
  }

  Future<void> _showEditStockDialog(Map<String, dynamic> product) async {
    final TextEditingController qohController = TextEditingController();
    final TextEditingController reorderLevelController = TextEditingController();
    
    // Pre-fill with current values
    qohController.text = product['PROD_QOH']?.toString() ?? '0';
    reorderLevelController.text = product['PROD_REORDER_LEVEL']?.toString() ?? '0';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Edit Stock Levels',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product['PROD_NAME'] ?? 'Product',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              if (product['PROD_CODE'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Code: ${product['PROD_CODE']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              
              // Quantity on Hand Field
              TextFormField(
                controller: qohController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity on Hand',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.inventory),
                  helperText: 'Current stock quantity',
                ),
              ),
              const SizedBox(height: 16),
              
              // Reorder Level Field
              TextFormField(
                controller: reorderLevelController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Reorder Level',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.warning_amber),
                  helperText: 'Minimum stock before reordering',
                ),
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9B1B1B),
                      ),
                      onPressed: _isUpdatingStock
                          ? null
                          : () => _updateProductStock(
                                product,
                                qohController.text,
                                reorderLevelController.text,
                              ),
                      child: _isUpdatingStock
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Update',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateProductStock(
    Map<String, dynamic> product,
    String qohText,
    String reorderLevelText,
  ) async {
    // Validate inputs
    final int? newQoh = int.tryParse(qohText);
    final int? newReorderLevel = int.tryParse(reorderLevelText);
    
    if (newQoh == null || newQoh < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid quantity on hand'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (newReorderLevel == null || newReorderLevel < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid reorder level'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUpdatingStock = true;
    });

    try {
      final result = await _adminService.updateProductStock(
        int.parse(product['PROD_ID'].toString()),
        prodQoh: newQoh,
        prodReorderLevel: newReorderLevel,
      );

      if (result['success'] == true && mounted) {
        // Update the product in the local list
        final productIndex = _products.indexWhere(
          (p) => p['PROD_ID'].toString() == product['PROD_ID'].toString(),
        );
        
        if (productIndex != -1) {
          setState(() {
            _products[productIndex]['PROD_QOH'] = newQoh.toString();
            _products[productIndex]['PROD_REORDER_LEVEL'] = newReorderLevel.toString();
            
            // Update stock status based on new values
            if (newQoh <= 0) {
              _products[productIndex]['STOCK_STATUS'] = 'OUT_OF_STOCK';
              _products[productIndex]['SHORTAGE_QUANTITY'] = newReorderLevel;
            } else if (newQoh <= newReorderLevel) {
              _products[productIndex]['STOCK_STATUS'] = 'LOW_STOCK';
              _products[productIndex]['SHORTAGE_QUANTITY'] = newReorderLevel - newQoh;
            } else {
              _products[productIndex]['STOCK_STATUS'] = 'NORMAL';
              _products[productIndex]['SHORTAGE_QUANTITY'] = 0;
            }
          });
        }

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Stock levels updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh statistics
        _loadProducts(isRefresh: true);
      } else {
        throw Exception(result['message'] ?? 'Failed to update stock levels');
      }
    } catch (e) {
      print('Error updating stock: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update stock: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStock = false;
        });
      }
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _buildFilterSheet(scrollController),
        ),
      ),
    );
  }

  Widget _buildFilterSheet(ScrollController scrollController) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Filter & Sort',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                // Stock Type Filter
                const Text(
                  'Stock Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                _buildStockTypeChips(),
                const SizedBox(height: 20),
                
                // Sort Options
                const Text(
                  'Sort By',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                _buildSortOptions(),
                const SizedBox(height: 20),
                
                // Category Filters (if available)
                if (_filters?['availableCategories'] != null) ...[
                  const Text(
                    'Category',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedType = 'all';
                      _selectedCategory = null;
                      _selectedSubCategory = null;
                      _sortBy = 'PROD_QOH';
                      _sortOrder = 'ASC';
                    });
                    Navigator.pop(context);
                    _resetAndRefresh();
                  },
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B1B1B),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _resetAndRefresh();
                  },
                  child: const Text('Apply', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockTypeChips() {
    final types = [
      {'value': 'all', 'label': 'All Products'},
      {'value': 'out_of_stock', 'label': 'Out of Stock'},
      {'value': 'low_stock', 'label': 'Low Stock'},
    ];

    return Wrap(
      spacing: 8,
      children: types.map((type) {
        final isSelected = _selectedType == type['value'];
        return FilterChip(
          selected: isSelected,
          label: Text(type['label']!),
          onSelected: (selected) {
            setState(() {
              _selectedType = type['value']!;
            });
          },
          selectedColor: const Color(0xFF9B1B1B).withOpacity(0.2),
          checkmarkColor: const Color(0xFF9B1B1B),
        );
      }).toList(),
    );
  }

  Widget _buildSortOptions() {
    final sortOptions = [
      {'value': 'PROD_QOH', 'label': 'Quantity on Hand'},
      {'value': 'SHORTAGE_QUANTITY', 'label': 'Shortage Quantity'},
      {'value': 'PROD_NAME', 'label': 'Product Name'},
      {'value': 'PROD_SP', 'label': 'Selling Price'},
    ];

    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _sortBy,
          decoration: const InputDecoration(
            labelText: 'Sort Field',
            border: OutlineInputBorder(),
          ),
          items: sortOptions.map((option) {
            return DropdownMenuItem(
              value: option['value'],
              child: Text(option['label']!),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _sortBy = value!;
            });
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Ascending'),
                value: 'ASC',
                groupValue: _sortOrder,
                onChanged: (value) {
                  setState(() {
                    _sortOrder = value!;
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Descending'),
                value: 'DESC',
                groupValue: _sortOrder,
                onChanged: (value) {
                  setState(() {
                    _sortOrder = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    final categories = _filters?['availableCategories'] as List? ?? [];
    
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Filter by Category',
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('All Categories'),
        ),
        ...categories.map((category) {
          return DropdownMenuItem(
            value: category['CAT_ID'].toString(),
            child: Text(category['CAT_NAME'] ?? 'Unknown Category'),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
          _selectedSubCategory = null; // Reset subcategory when category changes
        });
      },
    );
  }

  Widget _buildStatisticsCards() {
    if (_statistics == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Out of Stock',
              '${_statistics!['outOfStockCount'] ?? 0}',
              Colors.red,
              Icons.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Low Stock',
              '${_statistics!['lowStockCount'] ?? 0}',
              Colors.orange,
              Icons.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Total Issues',
              '${_statistics!['totalLowStockProducts'] ?? 0}',
              const Color(0xFF9B1B1B),
              Icons.inventory_2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final stockStatus = product['STOCK_STATUS'] ?? '';
    final qoh = int.tryParse(product['PROD_QOH']?.toString() ?? '0') ?? 0;
    final reorderLevel = int.tryParse(product['PROD_REORDER_LEVEL']?.toString() ?? '0') ?? 0;
    final shortageQty = product['SHORTAGE_QUANTITY'] ?? 0;
    
    Color statusColor = Colors.green;
    if (stockStatus == 'OUT_OF_STOCK') {
      statusColor = Colors.red;
    } else if (stockStatus == 'LOW_STOCK') {
      statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['PROD_NAME'] ?? 'Unknown Product',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (product['PROD_CODE'] != null)
                        Text(
                          'Code: ${product['PROD_CODE']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${product['CAT_NAME'] ?? 'Unknown'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (product['SUB_CAT_NAME'] != null) ...[
                            Text(' • ${product['SUB_CAT_NAME']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        stockStatus.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showEditStockDialog(product),
                      tooltip: 'Edit Stock Levels',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      color: const Color(0xFF9B1B1B),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInfoColumn('Current Stock', '$qoh', statusColor),
                  ),
                  Expanded(
                    child: _buildInfoColumn('Reorder Level', '$reorderLevel', Colors.blue),
                  ),
                  if (shortageQty > 0)
                    Expanded(
                      child: _buildInfoColumn('Shortage', '$shortageQty', Colors.red),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MRP: ₹${product['PROD_MRP'] ?? '0'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                Text(
                  'SP: ₹${product['PROD_SP'] ?? '0'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9B1B1B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
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
          'Restock Management',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF9B1B1B)),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF9B1B1B)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          // Statistics Cards
          _buildStatisticsCards(),
          
          // Products List
          Expanded(
            child: _isLoading && _products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _resetAndRefresh,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _products.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                const Text('No products found'),
                                const SizedBox(height: 8),
                                const Text('All products are well stocked!',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadProducts(isRefresh: true),
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: _products.length + (_isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _products.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return _buildProductCard(_products[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
} 