import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../help/help_support_page.dart';
import '../../config/api_config.dart';
import '../common/customer_management_hub.dart';
import '../../services/user_profile_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  final _profileService = UserProfileService();
  User? _user;
  bool _isLoading = true;
  Map<String, dynamic>? _retailerData;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getUser();
    setState(() {
      _user = user;
      _isLoading = false;
    });
    
    // Only fetch retailer data for customers
    if (user?.role.toLowerCase() == 'customer') {
      _fetchRetailerData();
      _fetchProfileData();
    }
  }

  Future<void> _fetchProfileData() async {
    try {
      final profile = await _profileService.fetchUserProfile();
      if (profile != null && mounted) {
        setState(() {
          _profileData = profile;
        });
      }
    } catch (e) {
      print('Error fetching profile data: $e');
    }
  }

  Future<void> _fetchRetailerData() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/retailers/my-retailer'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          _retailerData = data['data'];
        });
      }
    } catch (e) {
      print('Error fetching retailer data: $e');
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Color(0xFF9B1B1B)),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
        );
      }
    }
  }

  Widget _buildQRCode() {
    final retailer = _retailerData?['retailer'];
    if (retailer == null || retailer['BARCODE_URL'] == null) return const SizedBox();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: Text(
              'Shop QR Code',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9B1B1B),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF9B1B1B).withOpacity(0.1),
                  width: 2,
                ),
              ),
              child: Image.network(
                '${ApiConfig.baseUrl}/uploads/retailers/qrcode/${retailer['BARCODE_URL']}',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.qr_code,
                  size: 150,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Scan to view shop details',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    // Check if we have profile data with PHOTO field
    if (_profileData != null && _profileData!['PHOTO'] != null && _profileData!['PHOTO'].toString().isNotEmpty) {
      return Image.network(
        '${ApiConfig.baseUrl}/${_profileData!['PHOTO']}',
        fit: BoxFit.cover,
        width: 90,
        height: 90,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
      );
    }
    
    // Fallback to photo_url if PHOTO is not available
    if (_profileData != null && _profileData!['photo_url'] != null && _profileData!['photo_url'].toString().isNotEmpty) {
      return Image.network(
        '${ApiConfig.baseUrl}${_profileData!['photo_url']}',
        fit: BoxFit.cover,
        width: 90,
        height: 90,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
      );
    }
    
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    final username = _user?.username ?? 'User';
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFF9B1B1B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(45),
      ),
      child: Center(
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Color(0xFF9B1B1B),
          ),
        ),
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
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_user?.role.toLowerCase() == 'customer')
            IconButton(
              icon: const Icon(
                Icons.edit,
                color: Color(0xFF9B1B1B),
              ),
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '/edit-profile');
                if (result == true) {
                  // Profile was updated, reload the page
                  _loadUserData();
                }
              },
              tooltip: 'Edit Profile',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(45),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(45),
                      child: _buildProfileImage(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _user?.username ?? 'User',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _user?.mobile != null ? '+91 ${_user!.mobile}' : 'No mobile',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 24),
                if (_user?.role.toLowerCase() == 'customer' && _retailerData != null) _buildQRCode(),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      if (_user?.role.toLowerCase() == 'customer') ...[
                        _ProfileOption(
                          icon: Icons.shopping_cart_outlined,
                          label: 'My Orders',
                          onTap: () => Navigator.pushNamed(context, '/orders'),
                        ),
                        _ProfileOption(
                          icon: Icons.location_on_outlined,
                          label: 'My Addresses',
                          onTap: () => Navigator.pushNamed(context, '/address-list'),
                        ),
                      ],
                      if (_user?.role.toLowerCase() == 'admin') ...[
                        _ProfileOption(
                          icon: Icons.people,
                          label: 'Customer Management',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CustomerManagementHub(),
                            ),
                          ),
                        ),
                        _ProfileOption(
                          icon: Icons.supervisor_account,
                          label: 'User Management',
                          onTap: () => Navigator.pushNamed(context, '/user-management'),
                        ),
                        _ProfileOption(
                          icon: Icons.people_outline,
                          label: 'Manage Employee Orders',
                          onTap: () => Navigator.pushNamed(context, '/employee-orders'),
                        ),
                      ],
                      if (_user?.role.toLowerCase() == 'employee') ...[
                        _ProfileOption(
                          icon: Icons.people,
                          label: 'Customer Management',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CustomerManagementHub(),
                            ),
                          ),
                        ),
                      ],
                      _ProfileOption(
                        icon: Icons.help_outline,
                        label: 'Help & Support',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpSupportPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      _ProfileOption(
                        icon: Icons.logout,
                        label: 'Logout',
                        color: const Color(0xFF9B1B1B),
                        onTap: _handleLogout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color ?? const Color(0xFF9B1B1B)),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: color ?? Colors.black,
            fontSize: 16,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
} 