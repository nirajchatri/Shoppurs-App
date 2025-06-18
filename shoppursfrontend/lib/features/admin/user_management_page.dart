import 'package:flutter/material.dart';
import '../../services/user_management_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_management_model.dart';
import 'create_user_page.dart';
import 'user_details_page.dart';
import '../../widgets/error_message_widget.dart';
import 'package:intl/intl.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({Key? key}) : super(key: key);

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final UserManagementService _userService = UserManagementService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  List<UserManagementUser> _users = [];
  UserSearchPagination? _pagination;
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  String? _userRole;
  int _currentPage = 1;
  final int _limit = 10;
  String _searchQuery = '';
  String? _selectedUserType;

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
        _users = [];
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
      final result = await _userService.searchUsers(
        query: query,
        userType: _selectedUserType,
        page: _currentPage,
        limit: _limit,
      );

      setState(() {
        _users = result.users;
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

  Future<void> _loadNextPage() async {
    if (_pagination != null && _currentPage < _pagination!.totalPages) {
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

  void _navigateToCreateUser(String userType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateUserPage(userType: userType),
      ),
    ).then((_) {
      // Refresh search results if we have a query
      if (_searchQuery.isNotEmpty) {
        _performSearch(_searchQuery);
      }
    });
  }

  void _navigateToUserDetails(UserManagementUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserDetailsPage(userId: user.userId),
      ),
    );
  }

  Future<void> _toggleUserStatus(UserManagementUser user) async {
    final newStatus = !user.isActiveUser;
    
    try {
      await _userService.updateUserStatus(user.userId, newStatus);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User ${newStatus ? 'activated' : 'deactivated'} successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh the search results
      if (_searchQuery.isNotEmpty) {
        _performSearch(_searchQuery);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy, HH:mm').format(date);
  }

  Widget _buildUserCard(UserManagementUser user) {
    final isActive = user.isActiveUser;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToUserDetails(user),
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
                    backgroundColor: user.userType == 'admin' 
                        ? const Color(0xFF9B1B1B).withOpacity(0.1)
                        : const Color(0xFF2196F3).withOpacity(0.1),
                    child: Text(
                      user.username.isNotEmpty 
                          ? user.username[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: user.userType == 'admin' 
                            ? const Color(0xFF9B1B1B)
                            : const Color(0xFF2196F3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: user.userType == 'admin' 
                              ? const Color(0xFF9B1B1B).withOpacity(0.1)
                              : const Color(0xFF2196F3).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.displayRole,
                          style: TextStyle(
                            color: user.userType == 'admin' 
                                ? const Color(0xFF9B1B1B)
                                : const Color(0xFF2196F3),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: isActive ? Colors.green : Colors.red,
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
                    user.formattedMobile,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${user.city}, ${user.province}',
                      style: TextStyle(color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created: ${_formatDate(user.createdDate)}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _toggleUserStatus(user),
                        icon: Icon(
                          isActive ? Icons.toggle_on : Icons.toggle_off,
                          color: isActive ? Colors.green : Colors.grey,
                          size: 28,
                        ),
                        tooltip: isActive ? 'Deactivate' : 'Activate',
                      ),
                      IconButton(
                        onPressed: () => _navigateToUserDetails(user),
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        tooltip: 'View Details',
                      ),
                    ],
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
    final totalUsers = _pagination!.totalUsers;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: $totalUsers users',
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
              'Search for Users',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a name, email, mobile, or city to find admin and employee users',
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
              'No users found',
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

  Widget _buildCreateUserButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToCreateUser('admin'),
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
              label: const Text(
                'Create Admin User',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B1B1B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToCreateUser('employee'),
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text(
                'Create Employee User',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
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
        title: const Text(
          'User Management',
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search users by name, email, mobile, or city...',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _users = [];
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
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String?>(
                        value: _selectedUserType,
                        hint: const Text('Filter'),
                        onChanged: (value) {
                          setState(() {
                            _selectedUserType = value;
                          });
                          if (_searchQuery.isNotEmpty) {
                            _performSearch(_searchQuery);
                          }
                        },
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Users'),
                          ),
                          const DropdownMenuItem<String>(
                            value: 'admin',
                            child: Text('Admin'),
                          ),
                          const DropdownMenuItem<String>(
                            value: 'employee',
                            child: Text('Employee'),
                          ),
                        ],
                        underline: const SizedBox.shrink(),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCreateUserButtons(),
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
                    : _users.isEmpty
                        ? _buildEmptyState()
                        : Column(
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _users.length,
                                  itemBuilder: (context, index) {
                                    return _buildUserCard(_users[index]);
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
