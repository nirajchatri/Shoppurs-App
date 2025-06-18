import 'package:flutter/material.dart';
import '../common/customer_management_hub.dart';
import 'manage_users_page.dart';

class AdminDashboardExample extends StatelessWidget {
  const AdminDashboardExample({Key? key}) : super(key: key);

  Widget _buildDashboardCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF9B1B1B),
                    const Color(0xFF9B1B1B).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome, Administrator!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your system operations and customer data.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Management Options
            const Text(
              'Management Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            
            // Customer Management Card - NEW FEATURE
            _buildDashboardCard(
              title: 'Customer Management',
              description: 'Create new customers, manage existing ones, view details, and handle customer addresses. Automatically creates retailer profiles.',
              icon: Icons.people,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerManagementHub(),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // User Management Card - Existing
            _buildDashboardCard(
              title: 'User Management',
              description: 'Manage system users, view user details, and handle user permissions across the platform.',
              icon: Icons.admin_panel_settings,
              color: const Color(0xFF9B1B1B),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageUsersPage(),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Order Management Card - Example
            _buildDashboardCard(
              title: 'Order Management',
              description: 'View all orders, manage order status, and handle order operations across the system.',
              icon: Icons.shopping_cart,
              color: Colors.green,
              onTap: () {
                // Navigate to order management
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order Management - Coming Soon')),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Product Management Card - Example
            _buildDashboardCard(
              title: 'Product Management',
              description: 'Add new products, edit existing ones, manage categories and inventory.',
              icon: Icons.inventory,
              color: Colors.orange,
              onTap: () {
                // Navigate to product management
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product Management - Coming Soon')),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Reports Card - Example
            _buildDashboardCard(
              title: 'Reports & Analytics',
              description: 'View system reports, analytics, and business insights.',
              icon: Icons.analytics,
              color: Colors.purple,
              onTap: () {
                // Navigate to reports
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reports & Analytics - Coming Soon')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 