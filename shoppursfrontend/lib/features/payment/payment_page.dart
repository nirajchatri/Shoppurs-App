import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/settings_service.dart';
import '../../services/retailer_service.dart';
import '../order/order_success_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart' as http_parser;
import '../../config/api_config.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final AuthService _authService = AuthService();
  final SettingsService _settingsService = SettingsService();
  final RetailerService _retailerService = RetailerService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _notesController = TextEditingController();
  
  // Razorpay instance
  late Razorpay _razorpay;
  
  bool _isLoading = false;
  bool _isBankDetailsLoading = true;
  bool _isCreatingOrder = false;
  Map<String, dynamic>? _bankDetails;
  String? _error;
  dynamic _paymentScreenshot; // File for mobile, XFile for web
  bool _showImageUpload = false;
  Uint8List? _webImage; // For web platform
  String? _retailerPhone;
  String? _userRole;
  Map<String, dynamic>? _currentUser;
  double _orderAmount = 0.0; // Will be fetched from cart
  int _cartItemsCount = 0;
  bool _isLoadingCart = true;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _loadUserRole();
    _loadBankDetails();
    _loadRetailerPhone();
    _fetchCartData(); // Fetch real cart total
  }

  @override
  void dispose() {
    _notesController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('✅ Payment Success: ${response.paymentId}');
    print('✅ Order ID: ${response.orderId}');
    print('✅ Signature: ${response.signature}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Successful! ID: ${response.paymentId}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );

    // Place order after successful payment
    _placeOrderAfterPayment(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('❌ Payment Error: ${response.code} - ${response.message}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment Failed: ${response.message}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('🎯 External Wallet: ${response.walletName}');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External Wallet Selected: ${response.walletName}'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadUserRole() async {
    try {
      final user = await _authService.getUser();
      setState(() {
        _userRole = user?.role?.toLowerCase();
        _currentUser = user?.toJson();
      });
    } catch (e) {
      print('Error loading user role: $e');
    }
  }

  Future<void> _loadRetailerPhone() async {
    try {
      final phone = await _retailerService.getSelectedRetailerPhone();
      setState(() {
        _retailerPhone = phone;
      });
    } catch (e) {
      print('Error loading retailer phone: $e');
    }
  }

  Future<void> _fetchCartData() async {
    setState(() {
      _isLoadingCart = true;
    });
    
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');
      
      final response = await http.get(
        Uri.parse(ApiConfig.cartFetch),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final cartData = data['data'];
        setState(() {
          _orderAmount = (cartData['total'] ?? 0).toDouble();
          _cartItemsCount = (cartData['items'] as List? ?? []).length;
          _isLoadingCart = false;
        });
        print('✅ Cart total fetched: ₹$_orderAmount (${_cartItemsCount} items)');
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch cart data');
      }
    } catch (e) {
      print('❌ Error fetching cart data: $e');
      setState(() {
        _orderAmount = 0.0;
        _cartItemsCount = 0;
        _isLoadingCart = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load cart data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadBankDetails() async {
    // Only load bank details for non-employee users
    if (_userRole == 'employee') {
      setState(() {
        _isBankDetailsLoading = false;
      });
      return;
    }
    
    try {
      final details = await _settingsService.getBankDetails();
      setState(() {
        _bankDetails = details;
        _isBankDetailsLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isBankDetailsLoading = false;
      });
    }
  }

  Future<void> _createRazorpayOrder() async {
    // Validate order amount
    if (_orderAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot proceed with empty cart or zero amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_cartItemsCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty. Please add items before proceeding.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingOrder = true;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      print('🔄 Creating Razorpay order for ₹$_orderAmount...');
      final response = await http.post(
        Uri.parse(ApiConfig.paymentCreateOrder),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': (_orderAmount * 100).toInt(), // Convert to paise
          'currency': 'INR',
          'receipt': 'receipt_${DateTime.now().millisecondsSinceEpoch}',
        }),
      );

      print('📦 Order creation response: ${response.statusCode}');
      print('📦 Order creation body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final orderData = data['data'];
          print('✅ Razorpay order created: ${orderData['orderId']}');
          
          // Open Razorpay with order details
          _openRazorpay(orderData);
        } else {
          throw Exception(data['message'] ?? 'Failed to create payment order');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error creating Razorpay order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create payment order: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isCreatingOrder = false;
      });
    }
  }

  void _openRazorpay(Map<String, dynamic> orderData) {
    final user = _currentUser;
    
    var options = {
      'key': 'rzp_test_TXLp8WEhaRbLG8', // Replace with your Razorpay Key ID
      'amount': orderData['amount'],
      'name': 'Shoppurs Shop',
      'description': 'Online Shopping Payment',
      'order_id': orderData['orderId'],
      'prefill': {
        'contact': user?['mobile']?.toString() ?? '',
        'email': user?['email'] ?? '',
      },
      'theme': {
        'color': '#9B1B1B'
      },
      'currency': orderData['currency'] ?? 'INR',
      'timeout': 300, // 5 minutes
      'retry': {
        'enabled': true,
        'max_count': 1
      },
      'send_sms_hash': true,
      'allow_rotation': true,
      'remember_customer': false,
      'notes': {
        'user_id': user?['id']?.toString() ?? '',
        'order_time': DateTime.now().toIso8601String(),
      }
    };

    print('🚀 Opening Razorpay with options: $options');
    _razorpay.open(options);
  }

  Future<void> _placeOrderAfterPayment(PaymentSuccessResponse response) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _authService.getToken();
      final user = await _authService.getUser();
      
      if (token == null) throw Exception('No authentication token found');
      if (user == null) throw Exception('User not found');

      // Create multipart request for customer order with payment details
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/cart/place-order'),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add form fields
      request.fields.addAll({
        'paid_online': 'true',
        'authentication': token,
        'user_id': user.id.toString(),
        'paymentMethod': 'razorpay',
        'razorpay_payment_id': response.paymentId ?? '',
        'razorpay_order_id': response.orderId ?? '',
        'razorpay_signature': response.signature ?? '',
      });

      print('🔄 Placing order after payment...');
      final streamedResponse = await request.send();
      final responseBody = await http.Response.fromStream(streamedResponse);
      
      print('📦 Order placement response: ${responseBody.statusCode}');
      print('📦 Order placement body: ${responseBody.body}');

      final data = jsonDecode(responseBody.body);
      if (data['success'] == true) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OrderSuccessPage(orderDetails: data['data']),
            ),
          );
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to place order');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
        preferredCameraDevice: CameraDevice.rear,
      );
      
      if (image != null) {
        // Validate file extension
        final extension = image.path.toLowerCase().split('.').last;
        if (!['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a valid image file (JPG, PNG, GIF)'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        setState(() {
          _paymentScreenshot = kIsWeb ? image : File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUploadDialog() {
    setState(() {
      _showImageUpload = true;
    });
  }

  Future<void> _placeOrder({required bool isPaidOnline}) async {
    // Validate order amount for all payment methods
    if (_orderAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot proceed with empty cart or zero amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_cartItemsCount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty. Please add items before proceeding.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    try {
      final token = await _authService.getToken();
      final user = await _authService.getUser();
      
      if (token == null) throw Exception('No authentication token found');
      if (user == null) throw Exception('User not found');
      
      if (isPaidOnline && _paymentScreenshot == null) {
        throw Exception('Please upload payment screenshot');
      }

      // Check if user is employee
      if (user.role.toLowerCase() == 'employee') {
        await _placeEmployeeOrder(isPaidOnline: isPaidOnline, token: token);
      } else if (user.role.toLowerCase() == 'customer') {
        await _placeCustomerOrder(isPaidOnline: isPaidOnline, token: token, user: user);
      } else {
        throw Exception('Invalid user role for placing orders');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _placeEmployeeOrder({required bool isPaidOnline, required String token}) async {
    if (_retailerPhone == null || _retailerPhone!.isEmpty) {
      throw Exception('No retailer selected. Please select a retailer first.');
    }

    print('Placing employee order with retailer phone: $_retailerPhone');

    // For employees, only COD is allowed, so we use simple JSON request
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/employee/place-order'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phoneNumber': _retailerPhone!,
        'notes': _notesController.text.trim().isEmpty ? '' : _notesController.text.trim(),
      }),
    );
    
    print('Employee order response status: ${response.statusCode}');
    print('Employee order response body: ${response.body}');

    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      if (mounted) {
        // Format the order details for employee orders to match OrderSuccessPage expectations
        final orderData = data['data'] ?? {};
        final formattedOrderDetails = {
          'orderNumber': orderData['orderNumber'] ?? orderData['order_id'] ?? 'N/A',
          'orderTotal': orderData['orderTotal'] ?? orderData['total'] ?? orderData['amount'] ?? '0',
          'deliveryAddress': {
            'address': 'Retailer Phone: $_retailerPhone',
            'city': 'Order placed for retailer',
            'state': '',
            'country': '',
            'pincode': '',
            'landmark': _notesController.text.trim().isEmpty ? 'No special instructions' : _notesController.text.trim(),
          },
        };
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderSuccessPage(orderDetails: formattedOrderDetails),
          ),
        );
      }
    } else {
      throw Exception(data['message'] ?? 'Failed to place order');
    }
  }

  Future<void> _placeCustomerOrder({required bool isPaidOnline, required String token, required user}) async {
    // Create multipart request
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/api/cart/place-order'),
    );

    // Add headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    // Add form fields
    request.fields.addAll({
      'paid_online': isPaidOnline.toString(),
      'authentication': token,
      'user_id': user.id.toString(),
      'paymentMethod': isPaidOnline ? 'online' : 'cod',
    });

    // Add payment screenshot if paid online
    if (isPaidOnline && _paymentScreenshot != null) {
      try {
        if (kIsWeb) {
          // Handle web platform
          final xFile = _paymentScreenshot as XFile;
          final bytes = await xFile.readAsBytes();
          final fileName = xFile.name.isNotEmpty ? xFile.name : 'payment_image.jpg';
          final extension = fileName.toLowerCase().split('.').last;
          
          request.files.add(
            http.MultipartFile.fromBytes(
              'paymentImage',
              bytes,
              filename: fileName,
              contentType: http_parser.MediaType('image', _getImageExtension(extension)),
            ),
          );
        } else {
          // Handle mobile platforms
          final file = _paymentScreenshot as File;
          final fileName = file.path.split('/').last;
          final extension = _getImageExtension(fileName.toLowerCase().split('.').last);
          
          request.files.add(
            await http.MultipartFile.fromPath(
              'paymentImage',
              file.path,
              filename: fileName,
              contentType: http_parser.MediaType('image', extension),
            ),
          );
        }
      } catch (e) {
        print('Error adding payment image: $e');
        throw Exception('Failed to attach payment image: ${e.toString()}');
      }
    }

    // Send request
    print('Sending customer request to: ${request.url}');
    print('Request fields: ${request.fields}');
    print('Request files count: ${request.files.length}');
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    print('Customer order response status: ${response.statusCode}');
    print('Customer order response body: ${response.body}');

    final data = jsonDecode(response.body);
    if (data['success'] == true) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderSuccessPage(orderDetails: data['data']),
          ),
        );
      }
    } else {
      throw Exception(data['message'] ?? 'Failed to place order');
    }
  }

  String _getImageExtension(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      case 'webp':
        return 'webp';
      default:
        return 'jpeg'; // Default to jpeg
    }
  }

  Widget _buildImagePreview() {
    if (_paymentScreenshot == null) return const SizedBox.shrink();

    if (kIsWeb) {
      if (_webImage != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            _webImage!,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      }
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _paymentScreenshot as File,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildImageUploadSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Payment Screenshot',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please upload a clear image of your payment confirmation',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          if (_paymentScreenshot != null) ...[
            _buildImagePreview(),
            const SizedBox(height: 16),
          ],
          // Gallery Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B1B1B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library, size: 24),
              label: const Text(
                'Choose from Gallery',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // Camera Button (mobile only)
          if (!kIsWeb)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF9B1B1B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      color: Color(0xFF9B1B1B),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                ),
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, size: 24),
                label: const Text(
                  'Take Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          if (_paymentScreenshot != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B1B1B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : () => _placeOrder(isPaidOnline: true),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Confirm Order',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ],
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment Options',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_isLoadingCart)
                    const Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Loading cart data...', 
                          style: TextStyle(color: Colors.grey, fontSize: 14)
                        ),
                      ],
                    )
                  else
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            '$_cartItemsCount items. Total: ₹${_orderAmount.toStringAsFixed(0)}', 
                            style: const TextStyle(color: Colors.grey, fontSize: 14)
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 18, color: Colors.grey),
                            onPressed: _fetchCartData,
                            tooltip: 'Refresh cart data',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Show retailer info for employees
              if (_retailerPhone != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B1B1B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF9B1B1B).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9B1B1B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.store,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ordering for Retailer',
                              style: TextStyle(
                                color: Color(0xFF9B1B1B),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Phone: $_retailerPhone',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Notes section for employees
              if (_retailerPhone != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delivery Notes (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Add any special delivery instructions...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF9B1B1B)),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (!_showImageUpload) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Cash on Delivery Option
                      InkWell(
                        onTap: (_isLoading || _isLoadingCart || _orderAmount <= 0) ? null : () => _placeOrder(isPaidOnline: false),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                            color: (_isLoading || _isLoadingCart || _orderAmount <= 0) 
                                ? Colors.grey.shade100 
                                : Colors.white,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9B1B1B).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.delivery_dining,
                                  color: Color(0xFF9B1B1B),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pay on Delivery',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Pay when you receive your order',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isLoading)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Only show online payment options for non-employee users
                if (_userRole != 'employee') ...[
                  if (_isBankDetailsLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_error != null)
                    Center(
                      child: Column(
                        children: [
                          Text(_error!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadBankDetails,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  else if (_bankDetails != null) ...[
                    // Razorpay Payment Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9B1B1B).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.payment,
                                  color: Color(0xFF9B1B1B),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pay Online with Razorpay',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'UPI, Cards, Wallets & More',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9B1B1B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              onPressed: (_isCreatingOrder || _isLoading || _isLoadingCart || _orderAmount <= 0) ? null : _createRazorpayOrder,
                              child: _isLoadingCart
                                  ? const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Loading Cart...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    )
                                  : _isCreatingOrder
                                      ? const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Creating Order...',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          _orderAmount > 0 
                                              ? 'Pay ₹${_orderAmount.toStringAsFixed(0)}'
                                              : 'Cart is Empty',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ], // Close the _userRole != 'employee' condition
              ] else ...[
                _buildImageUploadSection(),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}