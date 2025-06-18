import 'package:flutter/material.dart';
import '../../models/user_management_model.dart';
import '../../services/user_management_service.dart';
import '../../widgets/error_message_widget.dart';

class CreateUserPage extends StatefulWidget {
  final String userType; // 'admin' or 'employee'
  
  const CreateUserPage({
    Key? key,
    required this.userType,
  }) : super(key: key);

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final UserManagementService _userService = UserManagementService();
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;
  bool _useDefaultPassword = true;
  CreateUserResponse? _createdUser;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _zipController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String get _pageTitle {
    return widget.userType == 'admin' ? 'Create Admin User' : 'Create Employee User';
  }

  String get _roleDisplayName {
    return widget.userType == 'admin' ? 'Administrator' : 'Employee';
  }

  Color get _roleColor {
    return widget.userType == 'admin' ? const Color(0xFF9B1B1B) : const Color(0xFF2196F3);
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final request = CreateUserRequest(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        mobile: _mobileController.text.trim(),
        password: _useDefaultPassword ? null : _passwordController.text.trim(),
        city: _cityController.text.trim(),
        province: _provinceController.text.trim(),
        zip: _zipController.text.trim(),
        address: _addressController.text.trim(),
        ulId: _userService.getUserLevelId(widget.userType),
      );

      // Validate all fields
      final validationError = _userService.validateUserCreationFields(request);
      if (validationError != null) {
        setState(() {
          _error = validationError;
          _isLoading = false;
        });
        return;
      }

      Map<String, dynamic> result;
      
      if (widget.userType == 'admin') {
        result = await _userService.createAdminUser(request);
      } else {
        result = await _userService.createEmployeeUser(request);
      }

      if (result['success'] == true) {
        setState(() {
          _createdUser = CreateUserResponse.fromJson(result['data']);
          _isLoading = false;
        });
        
        _showSuccessDialog();
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to create user';
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

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'User Created!',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_roleDisplayName} user has been created successfully.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Login Credentials:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Email: ${_createdUser!.user.email}'),
                    Text('Password: ${_createdUser!.defaultPassword}'),
                    const SizedBox(height: 8),
                    Text(
                      'Please share these credentials with the user.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _clearForm();
              },
              child: const Text('Create Another'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous page
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _roleColor,
              ),
              child: const Text(
                'Done',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _usernameController.clear();
    _emailController.clear();
    _mobileController.clear();
    _passwordController.clear();
    _cityController.clear();
    _provinceController.clear();
    _zipController.clear();
    _addressController.clear();
    setState(() {
      _error = null;
      _createdUser = null;
      _useDefaultPassword = true;
      _obscurePassword = true;
    });
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          obscureText: obscureText,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _roleColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _pageTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _roleColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _roleColor,
                borderRadius: const BorderRadius.only(
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
                      'Create New ${_roleDisplayName}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fill in the details to create a new ${widget.userType} account',
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

            // Form Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Information Section
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      controller: _usernameController,
                      label: 'Full Name *',
                      hint: 'Enter full name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    _buildFormField(
                      controller: _emailController,
                      label: 'Email Address *',
                      hint: 'Enter email address',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!_userService.isValidEmail(value)) {
                          return 'Invalid email format';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    _buildFormField(
                      controller: _mobileController,
                      label: 'Mobile Number *',
                      hint: 'Enter 10-digit mobile number',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Mobile number is required';
                        }
                        if (!_userService.isValidMobile(value)) {
                          return 'Invalid mobile number format';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password Section
                    const Text(
                      'Account Security',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Checkbox(
                          value: _useDefaultPassword,
                          onChanged: (value) {
                            setState(() {
                              _useDefaultPassword = value ?? true;
                              if (_useDefaultPassword) {
                                _passwordController.clear();
                              }
                            });
                          },
                          activeColor: _roleColor,
                        ),
                        const Expanded(
                          child: Text(
                            'Use default password (123456)',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),

                    if (!_useDefaultPassword) ...[
                      const SizedBox(height: 16),
                      _buildFormField(
                        controller: _passwordController,
                        label: 'Custom Password *',
                        hint: 'Enter password (min 6 characters)',
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (!_useDefaultPassword) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Password is required';
                            }
                            if (!_userService.isValidPassword(value)) {
                              return 'Password must be at least 6 characters';
                            }
                          }
                          return null;
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Address Information Section
                    const Text(
                      'Address Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildFormField(
                      controller: _addressController,
                      label: 'Street Address *',
                      hint: 'Enter street address',
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Address is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            controller: _cityController,
                            label: 'City *',
                            hint: 'Enter city',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'City is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            controller: _provinceController,
                            label: 'State/Province *',
                            hint: 'Enter state',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'State is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildFormField(
                      controller: _zipController,
                      label: 'ZIP/Postal Code *',
                      hint: 'Enter ZIP code',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'ZIP code is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Error Display
                    if (_error != null) ...[
                      ErrorMessageWidget(
                        message: _error!,
                        onRetry: () {
                          setState(() {
                            _error = null;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Create Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _roleColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Create ${_roleDisplayName}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 