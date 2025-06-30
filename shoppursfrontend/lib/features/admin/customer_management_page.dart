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

  List<CustomerWithRetailerDetails> _customers = [];
  CustomerWithRetailerPagination? _pagination;
  bool _isLoading = false;
  bool _isSearching = false;
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
    _loadCustomers(); // Load customers on page init
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
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

  Future<void> _loadNextPage() async {
    if (_pagination != null && _currentPage < _pagination!.totalPages) {
      setState(() {
        _currentPage++;
      });
      if (_searchQuery.isNotEmpty) {
        await _performSearch(_searchQuery);
      } else {
        await _loadCustomers();
      }
    }
  }

  Future<void> _loadPreviousPage() async {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      if (_searchQuery.isNotEmpty) {
        await _performSearch(_searchQuery);
      } else {
        await _loadCustomers();
      }
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

  Widget _buildPaginationControls() {
    if (_pagination == null) return const SizedBox.shrink();

    final totalPages = _pagination!.totalPages;
    final hasNext = _pagination!.hasNext;
    final hasPrev = _pagination!.hasPrev;
    final totalCustomers = _pagination!.totalCustomers;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: $totalCustomers customers',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: hasPrev ? _loadPreviousPage : null,
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(
                  backgroundColor: hasPrev ? const Color(0xFF9B1B1B) : Colors.grey.shade300,
                  foregroundColor: hasPrev ? Colors.white : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$_currentPage of $totalPages',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: hasNext ? _loadNextPage : null,
                icon: const Icon(Icons.chevron_right),
                style: IconButton.styleFrom(
                  backgroundColor: hasNext ? const Color(0xFF9B1B1B) : Colors.grey.shade300,
                  foregroundColor: hasNext ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isEmpty) {
      return Center(
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
            const SizedBox(height: 8),
            Text(
              'No customers available at the moment',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
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
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Customer Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF9B1B1B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            color: const Color(0xFF9B1B1B),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search customers and retailers by name, mobile, email, or city...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _customers = [];
                                _pagination = null;
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _navigateToCreateCustomer,
                    icon: const Icon(Icons.person_add, color: Color(0xFF9B1B1B)),
                    label: const Text(
                      'Create New Customer',
                      style: TextStyle(
                        color: Color(0xFF9B1B1B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Section
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
                      }
                    },
                  )
                : _isSearching
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9B1B1B)),
                        ),
                      )
                    : _customers.isEmpty
                        ? _buildEmptyState()
                        : Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _customers.length,
                                  itemBuilder: (context, index) {
                                    return _buildCustomerCard(_customers[index]);
                                  },
                                ),
                              ),
                              _buildPaginationControls(),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
} 