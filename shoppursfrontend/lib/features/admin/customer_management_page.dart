import 'package:flutter/material.dart';
import '../../services/customer_service.dart';
import '../../services/auth_service.dart';
import '../../models/customer_model.dart';
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

  List<Customer> _customers = [];
  Map<String, dynamic>? _pagination;
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
        _customers = [];
        _pagination = null;
      });
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

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _error = null;
      _searchQuery = query;
      _currentPage = 1;
    });

    try {
      final result = await _customerService.searchCustomers(
        query: query,
        page: _currentPage,
        limit: _limit,
      );

      if (result['success'] == true && result['data'] != null) {
        final customersData = result['data']['customers'] as List;
        setState(() {
          _customers = customersData.map((c) => Customer.fromJson(c)).toList();
          _pagination = result['data']['pagination'];
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
    if (_pagination != null && _currentPage < _pagination!['totalPages']) {
      setState(() {
        _currentPage++;
      });
      await _performSearch(_searchQuery);
    }
  }

  Future<void> _loadPreviousPage() async {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      await _performSearch(_searchQuery);
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

  void _navigateToCustomerDetails(Customer customer) {
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

  Widget _buildCustomerCard(Customer customer) {
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
                          customer.username,
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
                      ],
                    ),
                  ),
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
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '+91 ${customer.mobile}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${customer.city}, ${customer.province}',
                      style: TextStyle(color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created: ${_formatDate(customer.createdDate)}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                  if (customer.createdBy.isNotEmpty)
                    Text(
                      'By: ${customer.createdBy}',
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

    final totalPages = _pagination!['totalPages'] ?? 1;
    final hasNext = _pagination!['hasNext'] ?? false;
    final hasPrev = _pagination!['hasPrev'] ?? false;
    final totalCustomers = _pagination!['totalCustomers'] ?? 0;

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
              Icons.search,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Search for customers',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a name, mobile number, email, or city to find customers',
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
                    hintText: 'Search customers by name, mobile, email, or city...',
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