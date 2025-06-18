import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../admin/customer_management_page.dart';
import '../admin/create_customer_page.dart';

class CustomerManagementHub extends StatefulWidget {
  const CustomerManagementHub({Key? key}) : super(key: key);

  @override
  State<CustomerManagementHub> createState() => _CustomerManagementHubState();
}

class _CustomerManagementHubState extends State<CustomerManagementHub> {
  final AuthService _authService = AuthService();
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = await _authService.getUser();
    setState(() {
      _userRole = user?.role.toLowerCase();
      _isLoading = false;
    });
  }

  void _navigateToCustomerManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerManagementPage(),
      ),
    );
  }

  void _navigateToCreateCustomer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateCustomerPage(),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Get Started',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    color: color,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }



  String _getRoleDisplayName() {
    switch (_userRole) {
      case 'admin':
        return 'Administrator';
      case 'employee':
        return 'Employee';
      default:
        return 'User';
    }
  }

  String _getWelcomeMessage() {
    switch (_userRole) {
      case 'admin':
        return 'Manage customers, create new accounts, and oversee all customer operations.';
      case 'employee':
        return 'Create and manage customer accounts to help grow our customer base.';
      default:
        return 'Access customer management features.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9B1B1B)),
          ),
        ),
      );
    }

    // Check if user has permission to access customer management
    if (_userRole != 'admin' && _userRole != 'employee') {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Access Denied',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF9B1B1B),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Access Restricted',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Only administrators and employees can access customer management.',
                style: TextStyle(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF9B1B1B),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${_getRoleDisplayName()}!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getWelcomeMessage(),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Main Features
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Management',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildFeatureCard(
                    title: 'Search & Manage Customers',
                    description: 'Search for existing customers, view their details, addresses, and order history. Manage customer information efficiently.',
                    icon: Icons.search,
                    color: Colors.blue,
                    onTap: _navigateToCustomerManagement,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildFeatureCard(
                    title: 'Create New Customer',
                    description: 'Add new customers with single or multiple addresses. Automatically creates retailer profiles with QR codes.',
                    icon: Icons.person_add,
                    color: Colors.green,
                    onTap: _navigateToCreateCustomer,
                  ),
                ],
              ),
            ),

            // Additional Information
            const SizedBox(height: 32),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF9B1B1B).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF9B1B1B).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: const Color(0xFF9B1B1B),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Key Features',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9B1B1B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '• Automatic retailer profile creation\n'
                    '• QR code generation for easy identification\n'
                    '• Multiple address support\n'
                    '• Comprehensive customer search\n'
                    '• Order history and summary\n'
                    '• Mobile number and email validation',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
} 