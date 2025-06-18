import 'package:flutter/material.dart';
import '../../services/user_management_service.dart';
import '../../models/user_management_model.dart';
import '../../widgets/error_message_widget.dart';
import 'package:intl/intl.dart';

class UserDetailsPage extends StatefulWidget {
  final int userId;
  
  const UserDetailsPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final UserManagementService _userService = UserManagementService();

  UserDetailsResponse? _userDetails;
  bool _isLoading = true;
  String? _error;
  bool _isTogglingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final details = await _userService.getUserDetails(widget.userId);
      setState(() {
        _userDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleUserStatus() async {
    if (_userDetails == null) return;

    setState(() {
      _isTogglingStatus = true;
    });

    try {
      final newStatus = !_userDetails!.user.isActiveUser;
      await _userService.updateUserStatus(widget.userId, newStatus);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User ${newStatus ? 'activated' : 'deactivated'} successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Reload user details
      await _loadUserDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isTogglingStatus = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy, HH:mm').format(date);
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  Color _getUserRoleColor(String userType) {
    return userType == 'admin' ? const Color(0xFF9B1B1B) : const Color(0xFF2196F3);
  }

  Widget _buildDetailRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    if (_userDetails == null) return const SizedBox.shrink();

    final user = _userDetails!.user;
    final isActive = user.isActiveUser;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _getUserRoleColor(user.userType).withOpacity(0.1),
                  child: Text(
                    user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _getUserRoleColor(user.userType),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getUserRoleColor(user.userType).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.displayRole,
                          style: TextStyle(
                            color: _getUserRoleColor(user.userType),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive 
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: isActive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      onPressed: _isTogglingStatus ? null : _toggleUserStatus,
                      icon: _isTogglingStatus
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              isActive ? Icons.toggle_on : Icons.toggle_off,
                              color: isActive ? Colors.green : Colors.grey,
                              size: 32,
                            ),
                      tooltip: isActive ? 'Deactivate User' : 'Activate User',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoCard() {
    if (_userDetails == null) return const SizedBox.shrink();

    final user = _userDetails!.user;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Email', user.email, icon: Icons.email),
            _buildDetailRow('Mobile', user.formattedMobile, icon: Icons.phone),
            const Divider(height: 24),
            const Text(
              'Address',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildDetailRow('Street', user.address, icon: Icons.home),
            _buildDetailRow('City', user.city, icon: Icons.location_city),
            _buildDetailRow('State/Province', user.province, icon: Icons.map),
            _buildDetailRow('ZIP Code', user.zip, icon: Icons.local_post_office),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard() {
    if (_userDetails == null) return const SizedBox.shrink();

    final user = _userDetails!.user;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('User ID', user.userId.toString(), icon: Icons.badge),
            _buildDetailRow('User Level ID', user.ulId.toString(), icon: Icons.security),
            _buildDetailRow('OTP Verified', user.isOtpVerify ? 'Yes' : 'No', icon: Icons.verified),
            _buildDetailRow('Created Date', _formatDate(user.createdDate), icon: Icons.calendar_today),
            _buildDetailRow('Created By', user.createdBy, icon: Icons.person_add),
            _buildDetailRow('Last Updated', _formatDate(user.updatedDate), icon: Icons.update),
            _buildDetailRow('Updated By', user.updatedBy, icon: Icons.edit),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeStatsCard() {
    if (_userDetails == null || _userDetails!.employeeStats == null) {
      return const SizedBox.shrink();
    }

    final stats = _userDetails!.employeeStats!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Employee Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Orders Created',
                    stats.ordersCreated.toString(),
                    Icons.shopping_bag,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Total Sales',
                    _formatCurrency(stats.totalSalesValue),
                    Icons.monetization_on,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'DWR Entries',
                    stats.totalDwrEntries.toString(),
                    Icons.assignment,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Completed Days',
                    stats.completedDays.toString(),
                    Icons.check_circle,
                    const Color(0xFF9B1B1B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _userDetails?.user.username ?? 'User Details',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _userDetails != null 
            ? _getUserRoleColor(_userDetails!.user.userType)
            : const Color(0xFF9B1B1B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9B1B1B)),
              ),
            )
          : _error != null
              ? ErrorMessageWidget(
                  message: _error!,
                  onRetry: _loadUserDetails,
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildStatusCard(),
                      _buildContactInfoCard(),
                      _buildAccountInfoCard(),
                      _buildEmployeeStatsCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }
}