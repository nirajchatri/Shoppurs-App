import 'package:flutter/material.dart';
import '../../services/customer_service.dart';
import '../../services/auth_service.dart';
import '../../models/customer_model.dart';
import '../../models/customer_with_retailer_model.dart';
import 'create_customer_page.dart';
import 'customer_details_page.dart';
import '../../widgets/error_message_widget.dart';
import 'package:intl/intl.dart';

class CustomerManagementPage extends StatefulWidget {
  const CustomerManagementPage({Key? key}) : super(key: key);

  @override
  State<CustomerManagementPage> createState() => _CustomerManagementPageState();
}

class _CustomerManagementPageState extends State<CustomerManagementPage> {
  final CustomerService _customerService = CustomerService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<CustomerWithRetailerDetails> _customers = [];
  CustomerWithRetailerPagination? _pagination;
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isLoadingMore = false;
  String? _error;
  String? _userRole;
  int _currentPage = 1;
  final int _limit = 10;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _loadCustomers(); // Load customers on page init
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final user = await _authService.getUser();
    setState(() {
      _userRole = user?.role.toLowerCase();
    });
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchQuery = '';
      });
      _loadCustomers(); // Load default customers when search is cleared
      return;
    }

    // Debounce search to avoid too many API calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty && _searchController.text == _searchQuery) {
        return; // Query hasn't changed, don't search again
      }
      if (_searchController.text.isNotEmpty) {
        _performSearch(_searchController.text);
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || _pagination == null || _currentPage >= _pagination!.totalPages) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final result = _searchQuery.isNotEmpty
          ? await _customerService.searchCustomersWithRetailerDetails(
              query: _searchQuery,
              page: nextPage,
              limit: _limit,
            )
          : await _customerService.getCustomersWithRetailerDetails(
              page: nextPage,
              limit: _limit,
              userType: 'customer',
              isActive: 'Y',
            );

      if (result['success'] == true && result['data'] != null) {
        final response = CustomerWithRetailerResponse.fromJson(result);
        if (mounted) {
          setState(() {
            _currentPage = nextPage;
            _customers.addAll(response.customers);
            _pagination = response.pagination;
            _isLoadingMore = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading more data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _customers.clear(); // Clear existing customers when reloading
    });

    try {
      final result = await _customerService.getCustomersWithRetailerDetails(
        page: _currentPage,
        limit: _limit,
        userType: 'customer',
        isActive: 'Y',
      );

      if (result['success'] == true && result['data'] != null) {
        final response = CustomerWithRetailerResponse.fromJson(result);
        setState(() {
          _customers = response.customers;
          _pagination = response.pagination;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load customers';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _error = null;
      _searchQuery = query;
      _currentPage = 1;
      _customers.clear(); // Clear existing customers when searching
    });

    try {
      final result = await _customerService.searchCustomersWithRetailerDetails(
        query: query,
        page: _currentPage,
        limit: _limit,
      );

      if (result['success'] == true && result['data'] != null) {
        final response = CustomerWithRetailerResponse.fromJson(result);
        setState(() {
          _customers = response.customers;
          _pagination = response.pagination;
          _isSearching = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to search customers';
          _isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSearching = false;
      });
    }
  }

  void _navigateToCreateCustomer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCustomerPage(),
      ),
    ).then((_) {
      // Refresh search results if we have a query
      if (_searchQuery.isNotEmpty) {
        _performSearch(_searchQuery);
      }
    });
  }

  void _navigateToCustomerDetails(CustomerWithRetailerDetails customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailsPage(customerId: customer.userId),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy, HH:mm').format(date);
  }

  Widget _buildCustomerCard(CustomerWithRetailerDetails customer) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToCustomerDetails(customer),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: const Color(0xFF9B1B1B).withOpacity(0.1),
                    child: Text(
                      customer.username.isNotEmpty 
                          ? customer.username[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9B1B1B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.email,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        if (customer.hasRetailer && customer.retShopName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Shop: ${customer.retShopName}',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      if (customer.retCode != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            customer.retCode!,
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (customer.hasRetailer) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: customer.isRetailerActive 
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            customer.isRetailerActive ? 'Active Retailer' : 'Inactive Retailer',
                            style: TextStyle(
                              color: customer.isRetailerActive ? Colors.green : Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    customer.formattedMobile,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${customer.userCity}, ${customer.userProvince}',
                      style: TextStyle(color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (customer.hasRetailer && customer.fullRetailerAddress != 'No retailer address') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.store, size: 16, color: Colors.blue.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Retailer: ${customer.fullRetailerAddress}',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created: ${customer.formattedCreatedDate}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                  if (customer.userCreatedBy.isNotEmpty)
                    Text(
                      'By: ${customer.userCreatedBy}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (_isLoadingMore) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9B1B1B)),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Manage Customers',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF9B1B1B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _navigateToCreateCustomer,
              tooltip: 'Add Customer',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF9B1B1B),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search customers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _currentPage = 1;
                          });
                          _loadCustomers();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Customer List
          Expanded(
            child: _error != null
                ? ErrorMessageWidget(
                    message: _error!,
                    onRetry: () {
                      setState(() {
                        _error = null;
                      });
                      if (_searchQuery.isNotEmpty) {
                        _performSearch(_searchQuery);
                      } else {
                        _loadCustomers();
                      }
                    },
                  )
                : _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9B1B1B)),
                        ),
                      )
                    : _customers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No customers found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: _customers.length + 1, // +1 for the loading indicator
                            itemBuilder: (context, index) {
                              if (index == _customers.length) {
                                return _buildLoadMoreIndicator();
                              }
                              return _buildCustomerCard(_customers[index]);
                            },
                          ),
          ),
        ],
      ),
    );
  }
} 