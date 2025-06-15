import 'package:flutter/material.dart';
import '../../services/retailer_service.dart';
import 'dart:async';

class RetailerSelectionPage extends StatefulWidget {
  const RetailerSelectionPage({Key? key}) : super(key: key);

  @override
  State<RetailerSelectionPage> createState() => _RetailerSelectionPageState();
}

class _RetailerSelectionPageState extends State<RetailerSelectionPage> {
  final RetailerService _retailerService = RetailerService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  
  List<Map<String, dynamic>> _retailers = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isLoadingMore = false;
  String _error = '';
  String _searchError = '';
  bool _showSearchResults = false;
  int _currentPage = 1;
  bool _hasMoreData = true;
  String? _selectedRetailerPhone;

  @override
  void initState() {
    super.initState();
    _loadRetailers();
    _loadSelectedRetailerPhone();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadSelectedRetailerPhone() async {
    final phone = await _retailerService.getSelectedRetailerPhone();
    if (mounted) {
      setState(() {
        _selectedRetailerPhone = phone;
      });
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.isNotEmpty) {
        _searchRetailers(query);
      } else {
        setState(() {
          _searchResults = [];
          _showSearchResults = false;
          _searchError = '';
        });
      }
    });
  }

  Future<void> _loadRetailers({bool loadMore = false}) async {
    if (loadMore && (_isLoadingMore || !_hasMoreData)) return;

    try {
      setState(() {
        if (loadMore) {
          _isLoadingMore = true;
        } else {
          _isLoading = true;
          _error = '';
          _currentPage = 1;
          _hasMoreData = true;
        }
      });

      final response = await _retailerService.getRetailers(
        page: _currentPage,
        limit: 10,
        status: 'active',
      );

      if (mounted) {
        final newRetailers = (response['data']['retailers'] as List).cast<Map<String, dynamic>>();
        final pagination = response['data']['pagination'];
        
        setState(() {
          if (loadMore) {
            _retailers.addAll(newRetailers);
            _isLoadingMore = false;
          } else {
            _retailers = newRetailers;
            _isLoading = false;
          }
          
          _currentPage = pagination['currentPage'] + 1;
          _hasMoreData = pagination['hasNextPage'] ?? false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          if (loadMore) {
            _isLoadingMore = false;
          } else {
            _isLoading = false;
          }
        });
      }
    }
  }

  Future<void> _searchRetailers(String query) async {
    setState(() {
      _isSearching = true;
      _searchError = '';
      _showSearchResults = true;
    });

    try {
      final results = await _retailerService.searchRetailers(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = e.toString();
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _selectRetailer(Map<String, dynamic> retailer) async {
    try {
      final phoneNumber = retailer['RET_MOBILE_NO']?.toString() ?? '';
      final shopName = retailer['RET_SHOP_NAME']?.toString() ?? retailer['RET_NAME']?.toString() ?? '';
      
      if (phoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Retailer phone number not available'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Store both phone number and shop name
      await _retailerService.storeSelectedRetailerPhone(phoneNumber);
      await _retailerService.storeSelectedRetailerShopName(shopName);
      
      if (mounted) {
        setState(() {
          _selectedRetailerPhone = phoneNumber;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selected retailer: ${retailer['RET_NAME']}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to cart page after selecting retailer
        Navigator.pushReplacementNamed(context, '/cart');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting retailer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRetailerCard(Map<String, dynamic> retailer) {
    final isSelected = _selectedRetailerPhone == retailer['RET_MOBILE_NO']?.toString();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF9B1B1B) : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectRetailer(retailer),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: retailer['RET_PHOTO'] != null
                    ? Image.network(
                        retailer['RET_PHOTO'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                      )
                    : _buildDefaultAvatar(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            retailer['RET_NAME'] ?? 'Unknown Retailer',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF9B1B1B),
                            size: 24,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      retailer['RET_MOBILE_NO']?.toString() ?? 'No phone',
                      style: const TextStyle(
                        color: Color(0xFF9B1B1B),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${retailer['RET_ADDRESS'] ?? ''}, ${retailer['RET_CITY'] ?? ''}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF9B1B1B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.store,
        color: Color(0xFF9B1B1B),
        size: 30,
      ),
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
          'Select Retailer',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search retailers by name or phone...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _showSearchResults = false;
                            _searchError = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          
          // Results
          Expanded(
            child: _showSearchResults
                ? _buildSearchResults()
                : _buildRetailersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_searchError.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _searchError,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _searchRetailers(_searchController.text.trim()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text(
          'No retailers found',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildRetailerCard(_searchResults[index]);
      },
    );
  }

  Widget _buildRetailersList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error.isNotEmpty) {
      return Center(
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
              onPressed: () => _loadRetailers(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_retailers.isEmpty) {
      return const Center(
        child: Text(
          'No retailers available',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }
    
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!_isLoadingMore && 
            _hasMoreData && 
            scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          _loadRetailers(loadMore: true);
        }
        return false;
      },
      child: ListView.builder(
        itemCount: _retailers.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _retailers.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _buildRetailerCard(_retailers[index]);
        },
      ),
    );
  }
} 