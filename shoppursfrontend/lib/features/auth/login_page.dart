import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.login(
        _phoneController.text,
        _passwordController.text,
      );

      // Only proceed if we have a valid response
      if (response != null && response is Map<String, dynamic>) {
        if (response['success'] == true) {
          // Clear any previous error messages on successful response
          setState(() {
            _errorMessage = null;
          });

          // If login is successful, navigate to home
          if (response['token'] != null) {
            Navigator.pushReplacementNamed(context, '/home');
            return;
          }
          // Check if verification is needed
          else if (response['verificationId'] != null) {
            // Show verification message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please verify your account'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
            
            // Navigate to OTP verification
            await Future.delayed(const Duration(seconds: 1));
            Navigator.pushNamed(
              context,
              '/otp-verify',
              arguments: {
                'verificationId': response['verificationId'],
                'userId': response['userId'],
                'phoneNumber': _phoneController.text,
              },
            );
            return;
          }
        } else {
          // Handle failed login response
          String errorMsg = _getErrorMessage(response);
          setState(() {
            _errorMessage = errorMsg;
          });
          return;
        }
      }

      // If we reach here, something went wrong with the response
      setState(() {
        _errorMessage = 'Invalid credentials. Please check your phone number and password.';
      });

    } catch (e) {
      print('Login exception: $e');
      String errorMsg = _handleLoginException(e);
      setState(() {
        _errorMessage = errorMsg;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(Map<String, dynamic> response) {
    // Extract error message from response
    String? serverMessage = response['message']?.toString().trim();
    
    if (serverMessage != null && serverMessage.isNotEmpty) {
      // Handle specific server error messages
      if (serverMessage.toLowerCase().contains('session') || 
          serverMessage.toLowerCase().contains('expired') ||
          serverMessage.toLowerCase().contains('unauthorized')) {
        return 'Invalid credentials. Please check your phone number and password.';
      }
      if (serverMessage.toLowerCase().contains('invalid') || 
          serverMessage.toLowerCase().contains('wrong') ||
          serverMessage.toLowerCase().contains('incorrect')) {
        return 'Invalid phone number or password. Please try again.';
      }
      if (serverMessage.toLowerCase().contains('not found') || 
          serverMessage.toLowerCase().contains('user') ||
          serverMessage.toLowerCase().contains('account')) {
        return 'Account not found. Please check your phone number or sign up.';
      }
      // Return server message if it's user-friendly
      return serverMessage;
    }
    
    return 'Login failed. Please check your credentials and try again.';
  }

  String _handleLoginException(dynamic exception) {
    String exceptionStr = exception.toString().toLowerCase();
    
    // Handle network-related exceptions
    if (exceptionStr.contains('socket') || exceptionStr.contains('network') ||
        exceptionStr.contains('connection') || exceptionStr.contains('timeout')) {
      return 'Network error. Please check your connection and try again.';
    }
    
    // Handle server-related exceptions
    if (exceptionStr.contains('server') || exceptionStr.contains('500') ||
        exceptionStr.contains('502') || exceptionStr.contains('503')) {
      return 'Server error. Please try again later.';
    }
    
    // Handle session/auth related exceptions
    if (exceptionStr.contains('session') || exceptionStr.contains('expired') ||
        exceptionStr.contains('unauthorized') || exceptionStr.contains('401')) {
      return 'Invalid credentials. Please check your phone number and password.';
    }
    
    // Default error for invalid credentials
    return 'Invalid phone number or password. Please try again.';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 16),
                  // Phone Number Input with Country Code
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: const Text(
                            '+91',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: const InputDecoration(
                              hintText: '10 digit mobile number',
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              if (value.length != 10) {
                                return 'Please enter a valid 10 digit phone number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Password Input
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'enter password',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ),
                  if (_errorMessage != null && _errorMessage!.trim().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 16.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!.trim(),
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9B1B1B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text.rich(
                        TextSpan(
                          text: 'By clicking, you accept the ',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Terms of Service',
                              style: TextStyle(
                                color: Color(0xFF9B1B1B),
                                decoration: TextDecoration.underline,
                                fontSize: 12,
                              ),
                            ),
                            TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: Color(0xFF9B1B1B),
                                decoration: TextDecoration.underline,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/reset-password');
                      },
                      child: const Text(
                        'Reset Password with OTP',
                        style: TextStyle(
                          color: Color(0xFF9B1B1B),
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'New user? ',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          child: const Text(
                            'Register here',
                            style: TextStyle(
                              color: Color(0xFF9B1B1B),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 