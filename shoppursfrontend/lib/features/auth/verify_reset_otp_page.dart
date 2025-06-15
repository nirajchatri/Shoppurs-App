import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../services/auth_service.dart';

class VerifyResetOtpPage extends StatefulWidget {
  const VerifyResetOtpPage({Key? key}) : super(key: key);

  @override
  State<VerifyResetOtpPage> createState() => _VerifyResetOtpPageState();
}

class _VerifyResetOtpPageState extends State<VerifyResetOtpPage> {
  final List<TextEditingController> _otpControllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  final _authService = AuthService();
  
  String? _verificationId;
  String? _phoneNumber;
  bool _isLoading = false;
  String? _errorMessage;
  bool _otpVerified = false;
  
  // Timer related variables
  Timer? _timer;
  int _remainingSeconds = 120;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        setState(() {
          _verificationId = args['verificationId'];
          _phoneNumber = args['phoneNumber'];
        });
      }
    });
  }

  void _startTimer() {
    _canResend = false;
    _remainingSeconds = 120;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _handleResendOtp() async {
    if (_phoneNumber == null) {
      setState(() {
        _errorMessage = 'Phone number not found';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.resendOtp(_phoneNumber!);

      if (response['success'] == true) {
        // Update verification ID with new one
        setState(() {
          _verificationId = response['verificationId'];
          _otpVerified = false;
        });

        // Clear all OTP input fields
        for (var controller in _otpControllers) {
          controller.clear();
        }

        // Focus on first OTP field
        _focusNodes[0].requestFocus();

        // Restart timer
        _startTimer();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP resent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to resend OTP';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while resending OTP';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpControllers.map((controller) => controller.text).join();
    
    if (otp.length != 4) {
      setState(() {
        _errorMessage = 'Please enter complete OTP';
      });
      return;
    }

    if (_verificationId == null || _phoneNumber == null) {
      setState(() {
        _errorMessage = 'Missing verification details';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.confirmOtpForPassword(
        _phoneNumber!,
        _verificationId!,
        otp,
      );

      if (response['success'] == true) {
        setState(() {
          _otpVerified = true;
        });
        
        // Wait a moment to show green borders, then navigate
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Navigate to new password page
        Navigator.pushNamed(
          context,
          '/new-password',
          arguments: {
            'phoneNumber': _phoneNumber,
          },
        );
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'OTP verification failed';
          _otpVerified = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _otpVerified = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    
    // Auto verify when all digits are entered
    if (index == 3 && value.isNotEmpty) {
      final otp = _otpControllers.map((controller) => controller.text).join();
      if (otp.length == 4) {
        _handleVerifyOtp();
      }
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text(
                'Verify OTP',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Verify with OTP sent to',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _phoneNumber ?? '9810160596',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'OTP verification code',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ...List.generate(4, (index) => Container(
                        width: 44,
                        height: 48,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _otpVerified ? Colors.green : Colors.grey,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextFormField(
                          controller: _otpControllers[index],
                          focusNode: _focusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            counterText: '',
                          ),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (value) => _onOtpChanged(value, index),
                        ),
                      )),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    _canResend ? "Didn't get the OTP? " : "Resend OTP in ",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  if (_canResend)
                    TextButton(
                      onPressed: _handleResendOtp,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Resend',
                        style: TextStyle(
                          color: Color(0xFF9B1B1B),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    Text(
                      _formatTime(_remainingSeconds),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
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
                  onPressed: _isLoading ? null : _handleVerifyOtp,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Verify',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 