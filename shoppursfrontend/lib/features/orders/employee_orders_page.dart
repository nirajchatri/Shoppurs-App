import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class EmployeeOrdersPage extends StatefulWidget {
  const EmployeeOrdersPage({Key? key}) : super(key: key);

  @override
  State<EmployeeOrdersPage> createState() => _EmployeeOrdersPageState();
}

class _EmployeeOrdersPageState extends State<EmployeeOrdersPage>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isLoadingOrders = false;
  bool _isLoadingDwr = false;
  String _error = '';
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic>? _selectedEmployee;
  Map<String, dynamic>? _dwrData;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _filteredEmployees = [];
  bool _showEmployeeList = true;
  
  // Tab controller for Orders and DWR tabs
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEmployees();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _filteredEmployees = _employees;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _filteredEmployees = _employees.where((employee) {
        final searchTerm = _searchController.text.toLowerCase();
        final name = employee['USERNAME'].toString().toLowerCase();
        final email = employee['EMAIL'].toString().toLowerCase();
        final mobile = employee['MOBILE'].toString();
        return name.contains(searchTerm) || 
               email.contains(searchTerm) || 
               mobile.contains(searchTerm);
      }).toList();
    });
  }

  Future<void> _loadEmployees() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/employees'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          _employees = List<Map<String, dynamic>>.from(data['data']);
          _filteredEmployees = _employees;
          _isLoading = false;
        });
      } else {
        throw Exception(data['message'] ?? 'Failed to load employees');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadEmployeeOrders(int userId) async {
    try {
      setState(() {
        _isLoadingOrders = true;
        _error = '';
      });

      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/employee-orders/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(data['data']);
          _isLoadingOrders = false;
        });
      } else {
        throw Exception(data['message'] ?? 'Failed to load employee orders');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingOrders = false;
      });
    }
  }

  Future<void> _loadEmployeeDwr(int userId) async {
    try {
      setState(() {
        _isLoadingDwr = true;
        _error = '';
      });

      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/admin/employee-dwr-details/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          _dwrData = data['data'];
          _isLoadingDwr = false;
        });
      } else {
        throw Exception(data['message'] ?? 'Failed to load employee DWR details');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingDwr = false;
      });
    }
  }

  void _selectEmployee(Map<String, dynamic> employee) {
    setState(() {
      _selectedEmployee = employee;
      _showEmployeeList = false;
      _searchController.clear();
      _loadEmployeeOrders(employee['USER_ID']);
      _loadEmployeeDwr(employee['USER_ID']);
    });
  }

  void _showEmployeeSelectionView() {
    setState(() {
      _showEmployeeList = true;
      _searchController.clear();
      _selectedEmployee = null;
      _orders.clear();
      _dwrData = null;
    });
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

  Widget _buildEmployeeListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Employee',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search employees...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredEmployees.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final employee = _filteredEmployees[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: InkWell(
                  onTap: () => _selectEmployee(employee),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF9B1B1B).withOpacity(0.1),
                          radius: 24,
                          child: Text(
                            employee['USERNAME'][0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF9B1B1B),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                employee['USERNAME'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                employee['EMAIL'],
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '+91 ${employee['MOBILE']}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedEmployeeHeader() {
    if (_selectedEmployee == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF9B1B1B).withOpacity(0.1),
            radius: 24,
            child: Text(
              _selectedEmployee!['USERNAME'][0].toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF9B1B1B),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedEmployee!['USERNAME'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedEmployee!['EMAIL'],
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showEmployeeSelectionView,
            icon: const Icon(Icons.edit, color: Color(0xFF9B1B1B)),
            tooltip: 'Change Employee',
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No orders found for this employee',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final order = _orders[index];
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/order-details', arguments: order['ORDER_ID']);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order['ORDER_NUMBER']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order['ORDER_STATUS']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order['ORDER_STATUS'].toString().toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(order['ORDER_STATUS']),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      order['CUSTOMER_NAME'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '+91 ${order['CUSTOMER_MOBILE']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${order['ORDER_TOTAL']}',
                      style: const TextStyle(
                        color: Color(0xFF9B1B1B),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _formatDate(order['CREATED_DATE']),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDwrList() {
    if (_dwrData == null || _dwrData!['dwr_records'] == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No DWR records found for this employee',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final dwrRecords = List<Map<String, dynamic>>.from(_dwrData!['dwr_records']);
    final summary = _dwrData!['summary'];

    return Column(
      children: [
        // Summary Card
        if (summary != null)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF9B1B1B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF9B1B1B).withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DWR Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF9B1B1B),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Total Entries', summary['total_dwr_entries'].toString()),
                    _buildSummaryItem('Completed', summary['completed_days'].toString()),
                    _buildSummaryItem('Draft', summary['draft_days']?.toString() ?? '0'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Total Expenses', '₹${summary['total_expenses'] ?? '0.00'}'),
                    _buildSummaryItem('Completion Rate', '${summary['completion_rate']}%'),
                  ],
                ),
              ],
            ),
          ),
        
        // DWR Records List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: dwrRecords.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final dwr = dwrRecords[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatWorkDate(dwr['work_date']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (dwr['dwr_number'] != null)
                                Text(
                                  'DWR #${dwr['dwr_number']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getDwrStatusColor(dwr['status']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            dwr['status'].toString().toUpperCase(),
                            style: TextStyle(
                              color: _getDwrStatusColor(dwr['status']),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Day Start
                    if (dwr['day_start'] != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.play_circle_outline, size: 20, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start: ${dwr['day_start']['time']} - ${dwr['day_start']['station_name'] ?? 'Unknown Station'}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                if (dwr['day_start']['location'] != null)
                                  Text(
                                    'Location: ${dwr['day_start']['location']}',
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Day End
                    if (dwr['day_end'] != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.stop_circle_outlined, size: 20, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'End: ${dwr['day_end']['time']} - ${dwr['day_end']['station_name'] ?? 'Unknown Station'}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                if (dwr['day_end']['location'] != null)
                                  Text(
                                    'Location: ${dwr['day_end']['location']}',
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Expenses
                    if (dwr['expenses'] != null && dwr['expenses'] != '0.00')
                      Row(
                        children: [
                          Text(
                            'Expenses: ₹${dwr['expenses']}',
                            style: const TextStyle(
                              color: Color(0xFF9B1B1B),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    
                    if (dwr['remarks'] != null && dwr['remarks'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          dwr['remarks'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF9B1B1B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatWorkDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final formatter = DateFormat('EEE, d MMM yyyy');
    return formatter.format(date);
  }

  Color _getDwrStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getDataRangeText() {
    if (_dwrData != null && _dwrData!['filters'] != null) {
      return _dwrData!['filters']['data_limit'] ?? 'All Time';
    }
    return 'Last 14 days';
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
          'Employee Orders',
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
                        onPressed: _loadEmployees,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9B1B1B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _showEmployeeList
                  ? _buildEmployeeListView()
                  : Column(
                      children: [
                        _buildSelectedEmployeeHeader(),
                        // Tab Bar
                        Container(
                          color: Colors.white,
                          child: TabBar(
                            controller: _tabController,
                            labelColor: const Color(0xFF9B1B1B),
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: const Color(0xFF9B1B1B),
                            tabs: const [
                              Tab(
                                icon: Icon(Icons.shopping_cart_outlined),
                                text: 'Orders',
                              ),
                              Tab(
                                icon: Icon(Icons.work_outline),
                                text: 'DWR',
                              ),
                            ],
                          ),
                        ),
                        // Tab Bar View
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Orders Tab
                              _isLoadingOrders
                                  ? const Center(child: CircularProgressIndicator())
                                  : _buildOrdersList(),
                              // DWR Tab
                              _isLoadingDwr
                                  ? const Center(child: CircularProgressIndicator())
                                  : _buildDwrList(),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
} 