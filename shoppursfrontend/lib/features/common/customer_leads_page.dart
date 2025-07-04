import 'package:flutter/material.dart';
import '../../services/customer_lead_service.dart';
import '../../models/customer_lead_model.dart';
import '../../widgets/error_message_widget.dart';
import '../admin/create_customer_page.dart';
import 'package:intl/intl.dart';

class CustomerLeadsPage extends StatefulWidget {
  const CustomerLeadsPage({Key? key}) : super(key: key);

  @override
  State<CustomerLeadsPage> createState() => _CustomerLeadsPageState();
}

class _CustomerLeadsPageState extends State<CustomerLeadsPage> {
  final CustomerLeadService _leadService = CustomerLeadService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<CustomerLead> _leads = [];
  CustomerLeadPagination? _pagination;
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  final int _limit = 15;
  String _searchQuery = '';
  String? _selectedType;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadCustomerLeads();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScrollChanged() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Load more when user is 200 pixels from the bottom
      // Add small delay to prevent too frequent calls
      Future.delayed(const Duration(milliseconds: 100), () {
        _loadMoreData();
      });
    }
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchQuery = '';
        _currentPage = 1;
        _isLoadingMore = false;
      });
      _loadCustomerLeads();
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

  Future<void> _loadCustomerLeads() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
    });

    try {
      final result = await _leadService.getCustomerLeads(
        page: _currentPage,
        limit: _limit,
        type: _selectedType,
        status: _selectedStatus ?? 'active',
      );

      setState(() {
        _leads = result.leads;
        _pagination = result.pagination;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    // Prevent multiple simultaneous requests
    if (_isLoadingMore || _pagination == null || !_pagination!.hasNext) {
      return;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      
      CustomerLeadResponse result;
      if (_searchQuery.isNotEmpty) {
        result = await _leadService.searchCustomerLeads(
          query: _searchQuery,
          page: nextPage,
          limit: _limit,
        );
      } else {
        result = await _leadService.getCustomerLeads(
          page: nextPage,
          limit: _limit,
          type: _selectedType,
          status: _selectedStatus ?? 'active',
        );
      }

      setState(() {
        _currentPage = nextPage;
        _leads.addAll(result.leads);
        _pagination = result.pagination;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      // Show a snackbar for load more errors instead of replacing the entire content
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load more data: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
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
      final result = await _leadService.searchCustomerLeads(
        query: query,
        page: _currentPage,
        limit: _limit,
      );

      setState(() {
        _leads = result.leads;
        _pagination = result.pagination;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSearching = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedStatus = null;
      _searchController.clear();
      _searchQuery = '';
      _currentPage = 1;
      _isLoadingMore = false;
    });
    _loadCustomerLeads();
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy, HH:mm').format(date);
  }

  void _convertToRetailer(CustomerLead lead) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateCustomerPage(leadData: lead),
      ),
    ).then((result) {
      // If customer was successfully created, refresh the leads list
      if (result == true) {
        if (_searchQuery.isNotEmpty) {
          _performSearch(_searchQuery);
        } else {
          _loadCustomerLeads();
        }
      }
    });
  }

  Widget _buildLeadCard(CustomerLead lead) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    lead.displayName.isNotEmpty 
                        ? lead.displayName[0].toUpperCase()
                        : 'L',
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
                        lead.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lead.displayShopName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (lead.custldType != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _leadService.getLeadTypeDisplayText(lead.custldType),
                          style: const TextStyle(
                            color: Color(0xFF2196F3),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: lead.isActive 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lead.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: lead.isActive ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                  lead.formattedMobile,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(width: 16),
                if (lead.custldEmailId != null && lead.custldEmailId!.isNotEmpty) ...[
                  Icon(Icons.email, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      lead.custldEmailId!,
                      style: TextStyle(color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    lead.fullAddress,
                    style: TextStyle(color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (lead.custldGstNo != null && lead.custldGstNo!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.receipt, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'GST: ${lead.custldGstNo}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // Convert to Retailer Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _convertToRetailer(lead),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Convert to Retailer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B1B1B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created: ${_formatDate(lead.createdDate)}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'ID: ${lead.custldId}',
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
    );
  }

  Widget _buildFilterSection() {
    final filterOptions = _leadService.getFilterOptions();
    
    return Container(
      color: const Color(0xFF9B1B1B),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, shop, mobile, email, address...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _currentPage = 1;
                                _isLoadingMore = false;
                              });
                              _loadCustomerLeads();
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
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Type',
                  _selectedType,
                  ['All Types'] + filterOptions['types']!,
                  (value) {
                    setState(() {
                      _selectedType = value == 'All Types' ? null : value;
                      _currentPage = 1;
                      _isLoadingMore = false;
                    });
                    _loadCustomerLeads();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  'Status',
                  _selectedStatus ?? 'active',
                  filterOptions['statuses']!,
                  (value) {
                    setState(() {
                      _selectedStatus = value;
                      _currentPage = 1;
                      _isLoadingMore = false;
                    });
                    _loadCustomerLeads();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_all, color: Colors.white),
                  label: const Text(
                    'Clear Filters',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentPage = 1;
                      _isLoadingMore = false;
                    });
                    _loadCustomerLeads();
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text(
                    'Refresh',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String? value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          hintText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        items: options.map((option) {
          return DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildScrollInfo() {
    if (_pagination == null) return const SizedBox.shrink();

    final totalLeads = _pagination!.totalLeads;
    final currentShowing = _leads.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'Showing $currentShowing of $totalLeads leads',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (_isLoadingMore) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9B1B1B)),
          ),
        ),
      );
    }
    
    // Show "No more results" message when reached the end
    if (_pagination != null && !_pagination!.hasNext && _leads.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'No more results',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
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
              'No Customer Leads',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Customer leads will appear here when available',
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
              Icons.search_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No leads found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords or adjust filters',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
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
          'Customer Leads',
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
          _buildFilterSection(),
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
                        _loadCustomerLeads();
                      }
                    },
                  )
                : _isLoading || _isSearching
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9B1B1B)),
                        ),
                      )
                    : _leads.isEmpty
                        ? _buildEmptyState()
                        : Column(
                            children: [
                              _buildScrollInfo(),
                              Expanded(
                                child: ListView.builder(
                                  controller: _scrollController,
                                  itemCount: _leads.length + (_isLoadingMore || (_pagination != null && !_pagination!.hasNext && _leads.isNotEmpty) ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _leads.length) {
                                      return _buildLoadMoreIndicator();
                                    }
                                    return _buildLeadCard(_leads[index]);
                                  },
                                ),
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
} 