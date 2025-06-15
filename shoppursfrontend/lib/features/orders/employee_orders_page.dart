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

class _EmployeeOrdersPageState extends State<EmployeeOrdersPage> {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isLoadingOrders = false;
  String _error = '';
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic>? _selectedEmployee;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _filteredEmployees = [];
  bool _showEmployeeList = true; // New flag to control view

  @override
  void initState() {
    super.initState();
    _loadEmployees();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  void _selectEmployee(Map<String, dynamic> employee) {
    setState(() {
      _selectedEmployee = employee;
      _showEmployeeList = false;
      _searchController.clear();
      _loadEmployeeOrders(employee['USER_ID']);
    });
  }

  void _showEmployeeSelectionView() {
    setState(() {
      _showEmployeeList = true;
      _searchController.clear();
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
                        if (_isLoadingOrders)
                          const Expanded(
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else
                          Expanded(
                            child: _buildOrdersList(),
                          ),
                      ],
                    ),
    );
  }
} 