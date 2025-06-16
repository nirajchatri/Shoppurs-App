import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../config/api_config.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({Key? key}) : super(key: key);

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  final OrderService _orderService = OrderService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic>? _order;
  List<dynamic> _items = [];
  bool _isCancelling = false;
  bool _isUpdatingStatus = false;
  User? _user;
  dynamic _deliveryImage; // Changed to dynamic to handle both File and XFile
  bool _showDeliveryConfirmation = false;
  bool _isGettingLocation = false;
  double? _currentLat;
  double? _currentLong;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getUser();
      if (mounted) {
        setState(() {
          _user = user;
        });
        // Load order details after getting user data
        final args = ModalRoute.of(context)?.settings.arguments;
        int? orderId;
        if (args is Map<String, dynamic> && args['ORDER_ID'] != null) {
          orderId = args['ORDER_ID'] as int;
        } else if (args is int) {
          orderId = args;
        }
        if (orderId != null) {
          _fetchOrderDetails(orderId);
        } else {
          setState(() {
            _isLoading = false;
            _error = 'Order ID not found.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchOrderDetails(int orderId) async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      if (_user?.role?.toLowerCase() == 'admin') {
        final data = await _orderService.adminGetOrderDetails(orderId);
        setState(() {
          _order = data;
          _items = data['ORDER_ITEMS'] ?? [];
          _isLoading = false;
        });
      } else if (_user?.role?.toLowerCase() == 'employee') {
        final data = await _orderService.employeeGetOrderDetails(orderId);
        setState(() {
          _order = data;
          _items = data['items'] ?? [];
          _isLoading = false;
        });
      } else {
        final data = await _orderService.getOrderDetails(orderId);
        setState(() {
          _order = data['order'];
          _items = data['items'] ?? [];
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

  Future<Map<String, double?>> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        return {'lat': null, 'long': null};
      }

      // Check location permissions
      var status = await Permission.location.status;
      if (status.isDenied) {
        status = await Permission.location.request();
        if (status.isDenied) {
          print('Location permission denied');
          return {'lat': null, 'long': null};
        }
      }

      if (status.isPermanentlyDenied) {
        print('Location permission permanently denied');
        return {'lat': null, 'long': null};
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      return {
        'lat': position.latitude,
        'long': position.longitude,
      };
    } catch (e) {
      print('Error getting location: $e');
      return {'lat': null, 'long': null};
    }
  }

  Future<void> _pickDeliveryImage() async {
    try {
      if (kIsWeb) {
        // Web implementation - only gallery
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 1000,
        );
        
        if (image != null && mounted) {
          setState(() {
            _deliveryImage = image;
          });
        }
      } else {
        // Mobile implementation - for employees, only allow camera
        if (_user?.role?.toLowerCase() == 'employee') {
          await _pickImageFromSource(ImageSource.camera);
        } else {
          // For other roles, show choice dialog
          await _showImageSourceDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B1B1B).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_a_photo,
                    color: Color(0xFF9B1B1B),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Add Payment Image',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Choose how you want to add the payment image',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFF9B1B1B)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _pickImageFromSource(ImageSource.camera);
                        },
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Color(0xFF9B1B1B),
                        ),
                        label: const Text(
                          'Camera',
                          style: TextStyle(
                            color: Color(0xFF9B1B1B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9B1B1B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _pickImageFromSource(ImageSource.gallery);
                        },
                        icon: const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Gallery',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      // Check and request permissions based on source
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.request();
        if (cameraStatus.isDenied || cameraStatus.isPermanentlyDenied) {
          if (mounted) {
            _showPermissionDialog(
              'Camera Permission Required',
              'This app needs camera access to take photos for payment confirmation.',
              Permission.camera,
            );
          }
          return;
        }
      } else {
        // For gallery access
        PermissionStatus storageStatus;
        if (Platform.isAndroid) {
          final androidInfo = await _getAndroidVersion();
          if (androidInfo >= 33) {
            // Android 13+ uses granular media permissions
            storageStatus = await Permission.photos.request();
          } else {
            // Older Android versions
            storageStatus = await Permission.storage.request();
          }
        } else {
          // iOS
          storageStatus = await Permission.photos.request();
        }

        if (storageStatus.isDenied || storageStatus.isPermanentlyDenied) {
          if (mounted) {
            _showPermissionDialog(
              'Storage Permission Required',
              'This app needs storage access to select photos for payment confirmation.',
              storageStatus == PermissionStatus.permanentlyDenied ? null : (Platform.isAndroid ? Permission.storage : Permission.photos),
            );
          }
          return;
        }
      }

      // Pick image from the specified source with proper settings
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null && mounted) {
        // Verify it's an image file
        final fileName = image.name.toLowerCase();
        final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
        final hasValidExtension = validExtensions.any((ext) => fileName.endsWith('.$ext'));
        
        if (!hasValidExtension && !kIsWeb) {
          // For mobile, check the path extension
          final pathExtension = image.path.toLowerCase().split('.').last;
          if (!validExtensions.contains(pathExtension)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a valid image file (JPG, PNG, GIF, WEBP)'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }

        setState(() {
          _deliveryImage = kIsWeb ? image : File(image.path);
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment image selected successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<int> _getAndroidVersion() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await Permission.camera.status;
        // This is a simplified check - in real implementation you might want to use device_info_plus
        return 30; // Default to API 30 for now
      }
      return 0;
    } catch (e) {
      return 30; // Default
    }
  }

  void _showPermissionDialog(String title, String message, Permission? permission) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
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
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            if (permission != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B1B1B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await permission.request();
                },
                child: const Text(
                  'Grant Permission',
                  style: TextStyle(color: Colors.white),
                ),
              )
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B1B1B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text(
                  'Open Settings',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _markAsDelivered() async {
    if (_order == null) return;

    // For employee role only - check if payment image exists
    if (_user?.role?.toLowerCase() == 'employee') {
      // If payment image exists, directly mark as delivered
      if (_order!['PAYMENT_IMAGE'] != null && _order!['PAYMENT_IMAGE'].toString().isNotEmpty) {
        await _directMarkAsDelivered();
      } else {
        // If no payment image, show upload dialog
        setState(() {
          _showDeliveryConfirmation = true;
        });
      }
    } else {
      // For other roles, keep existing behavior
      setState(() {
        _showDeliveryConfirmation = true;
      });
    }
  }

  Future<void> _directMarkAsDelivered() async {
    if (_order == null) return;

    try {
      setState(() {
        _isUpdatingStatus = true;
        _isGettingLocation = true;
      });

      // Get current location
      final location = await _getCurrentLocation();
      setState(() {
        _currentLat = location['lat'];
        _currentLong = location['long'];
        _isGettingLocation = false;
      });

      final result = await _orderService.employeeUpdateOrderStatusWithLocation(
        _order!['ORDER_ID'], 
        'delivered',
        _currentLat,
        _currentLong,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Order marked as delivered'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _order!['ORDER_STATUS'] = 'delivered';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _confirmDelivery() async {
    if (_order == null) return;
    if (_deliveryImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a delivery confirmation image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isUpdatingStatus = true;
        _isGettingLocation = true;
      });

      // Get current location
      final location = await _getCurrentLocation();
      setState(() {
        _currentLat = location['lat'];
        _currentLong = location['long'];
        _isGettingLocation = false;
      });

      print('Starting delivery confirmation with image upload...');
      print('Image type: ${_deliveryImage.runtimeType}');
      print('Location: lat=${_currentLat}, long=${_currentLong}');
      
      if (kIsWeb) {
        print('Web upload - Image name: ${_deliveryImage.name}');
      } else {
        print('Mobile upload - Image path: ${_deliveryImage.path}');
      }

      // Update order status with payment image and location
      final result = await _orderService.employeeUpdateOrderStatusWithImage(
        _order!['ORDER_ID'], 
        'delivered',
        _deliveryImage,
        lat: _currentLat,
        long: _currentLong,
      );

      print('Upload successful: ${result.toString()}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Order marked as delivered successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _showDeliveryConfirmation = false;
          _order!['ORDER_STATUS'] = 'delivered';
          _deliveryImage = null;
        });
      }
    } catch (e) {
      print('Upload failed with error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
          _isGettingLocation = false;
        });
      }
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    final formatter = DateFormat('hh:mm a, dd MMM yyyy');
    return formatter.format(date);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFF9B1B1B);
      case 'cancelled':
        return Colors.red;
      case 'accepted':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _acceptOrder() async {
    if (_order == null) return;
    
    try {
      setState(() {
        _isCancelling = true; // Reuse the loading state
      });
      
      final result = await _orderService.adminUpdateOrderStatus(_order!['ORDER_ID'], 'confirmed');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Order confirmed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh order details
        _fetchOrderDetails(_order!['ORDER_ID']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  Future<void> _cancelOrder() async {
    if (_order == null) return;
    
    // Show confirmation dialog first
    final bool? shouldCancel = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel_outlined,
                  color: Colors.red,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cancel Order',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to cancel order #${_order!['ORDER_NUMBER']}?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF9B1B1B)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'No, Keep It',
                        style: TextStyle(
                          color: Color(0xFF9B1B1B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Yes, Cancel',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // If user didn't confirm, return
    if (shouldCancel != true) return;
    
    try {
      setState(() {
        _isCancelling = true;
      });
      
      final userRole = _user?.role?.toLowerCase() ?? '';
      final orderId = _order!['ORDER_ID'];
      Map<String, dynamic> result;

      // Use different API endpoints based on user role
      if (userRole == 'admin') {
        result = await _orderService.adminUpdateOrderStatus(orderId, 'cancelled');
      } else if (userRole == 'employee') {
        result = await _orderService.employeeUpdateOrderStatus(orderId, 'cancelled');
      } else {
        // For regular customers
        result = await _orderService.cancelOrder(orderId);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Order cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh order details
        _fetchOrderDetails(_order!['ORDER_ID']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  Widget _buildDeliveryConfirmation() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF9B1B1B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                color: Color(0xFF9B1B1B),
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Confirm Delivery',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please upload a delivery confirmation image',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            if (_deliveryImage != null)
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: kIsWeb
                      ? Image.network(
                          _deliveryImage.path,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.error, color: Colors.red),
                            );
                          },
                        )
                      : Image.file(
                          _deliveryImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.error, color: Colors.red),
                            );
                          },
                        ),
                ),
              )
            else
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add_a_photo_outlined, size: 40),
                  onPressed: _pickDeliveryImage,
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => setState(() {
                      _showDeliveryConfirmation = false;
                      _deliveryImage = null;
                    }),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B1B1B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isUpdatingStatus ? null : _confirmDelivery,
                    child: _isUpdatingStatus
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Confirm',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    if (_order == null) return const SizedBox.shrink();
    
    if (_order!['PAYMENT_METHOD'] == null && 
        (_order!['PAYMENT_IMAGE'] == null || _order!['PAYMENT_IMAGE'].toString().isEmpty)) {
      return const SizedBox.shrink();
    }

    return Column(
            children: [
                                      const SizedBox(height: 20),
                                      const Divider(),
                                      const SizedBox(height: 16),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF9B1B1B).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.payment_rounded,
                                              color: Color(0xFF9B1B1B),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (_order!['PAYMENT_METHOD'] != null) ...[
                                                  const Text(
                                                    'Payment Method',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${_order!['PAYMENT_METHOD']}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                                if (_order!['PAYMENT_IMAGE'] != null && _order!['PAYMENT_IMAGE'].toString().isNotEmpty) ...[
                                                  if (_order!['PAYMENT_METHOD'] != null)
                                                    const SizedBox(height: 12),
                                                  Row(
                                                    children: [
                                                      const Text(
                                                        'Payment Screenshot',
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      TextButton(
                                                        onPressed: () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (context) => Dialog(
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(20),
                                                              ),
                                                              child: Column(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: [
                                                                  AppBar(
                                                                    backgroundColor: Colors.transparent,
                                                                    elevation: 0,
                                                                    leading: IconButton(
                                                                      icon: const Icon(Icons.close, color: Colors.black),
                                                                      onPressed: () => Navigator.pop(context),
                                                                    ),
                                                                    title: const Text(
                                                                      'Payment Screenshot',
                                                                      style: TextStyle(
                                                                        color: Colors.black,
                                                                        fontSize: 18,
                                                                        fontWeight: FontWeight.bold,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Container(
                                                                    constraints: BoxConstraints(
                                                                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                                                                    ),
                                                                    child: InteractiveViewer(
                                                                      panEnabled: true,
                                                                      boundaryMargin: const EdgeInsets.all(20),
                                                                      minScale: 0.5,
                                                                      maxScale: 4,
                                                                      child: Image.network(
                                                                        '${ApiConfig.baseUrl}/uploads/orders/${_order!['PAYMENT_IMAGE']}',
                                                                        fit: BoxFit.contain,
                                                                        loadingBuilder: (context, child, loadingProgress) {
                                                                          if (loadingProgress == null) return child;
                                                                          return Center(
                                                                            child: CircularProgressIndicator(
                                                                              value: loadingProgress.expectedTotalBytes != null
                                                                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                                                  : null,
                                                                              color: const Color(0xFF9B1B1B),
                                                                            ),
                                                                          );
                                                                        },
                                                                        errorBuilder: (context, error, stackTrace) {
                                                                          return const Center(
                                                                            child: Column(
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              children: [
                                                                                Icon(
                                                                                  Icons.error_outline,
                                                                                  color: Colors.red,
                                                                                  size: 48,
                                                                                ),
                                                                                SizedBox(height: 8),
                                                                                Text(
                                                                                  'Failed to load image',
                                                                                  style: TextStyle(
                                                                                    color: Colors.red,
                                                                                    fontSize: 16,
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          );
                                                                        },
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(height: 16),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        style: TextButton.styleFrom(
                                                          foregroundColor: const Color(0xFF9B1B1B),
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 8,
                                                          ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                            side: const BorderSide(
                                                              color: Color(0xFF9B1B1B),
                                                              width: 1,
                                                            ),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: const [
                                                            Icon(Icons.image, size: 18),
                                                            SizedBox(width: 4),
                                                            Text(
                                                              'View',
                                                              style: TextStyle(
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
    );
  }

  Widget _buildRetailerDetails() {
    // Only show for admin users and when retailer info exists
    if (_user?.role?.toLowerCase() != 'admin' || 
        _order == null || 
        _order!['RETAILER_INFO'] == null) {
      return const SizedBox.shrink();
    }

    final retailer = _order!['RETAILER_INFO'];
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.store_rounded,
                color: Color(0xFF9B1B1B),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Retailer',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            retailer['RET_SHOP_NAME'] ?? 'Not provided',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '+91 ${retailer['RET_MOBILE_NO'] ?? 'Not provided'}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: retailer['SHOP_OPEN_STATUS'] == 'Y' 
                      ? Colors.green.shade50 
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  retailer['SHOP_OPEN_STATUS'] == 'Y' ? 'Open' : 'Closed',
                  style: TextStyle(
                    color: retailer['SHOP_OPEN_STATUS'] == 'Y' 
                        ? Colors.green.shade700 
                        : Colors.red.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceSection() {
    if (_order == null || 
        _order!['INVOICE_URL'] == null ||
        _order!['INVOICE_URL'].toString().isEmpty) {
      return const SizedBox.shrink();
    }

    final invoiceUrl = '${ApiConfig.baseUrl}${_order!['INVOICE_URL']}';
    print('Invoice URL: $invoiceUrl'); // Debug print

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invoice',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF9B1B1B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long,
                  color: Color(0xFF9B1B1B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Invoice',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Invoice for order #${_order!['ORDER_NUMBER']}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      try {
                        final uri = Uri.parse(invoiceUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalNonBrowserApplication,
                            webViewConfiguration: const WebViewConfiguration(
                              enableJavaScript: true,
                              enableDomStorage: true,
                            ),
                          );
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not download invoice. Please try viewing instead.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        print('Error launching URL: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF9B1B1B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFFF8F6F9),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF8F6F9),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Order Details',
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
                  ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
                  : _order == null
                      ? const Center(child: Text('Order not found'))
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                color: Colors.white,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8F6F9),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'Order #${_order!['ORDER_NUMBER']}',
                                            style: const TextStyle(
                                              color: Color(0xFF9B1B1B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(_order!['ORDER_STATUS'] ?? '').withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            (_order!['ORDER_STATUS'] ?? '').toString().capitalize(),
                                            style: TextStyle(
                                              color: _getStatusColor(_order!['ORDER_STATUS'] ?? ''),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Order Placed',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(_order!['CREATED_DATE']),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                    _buildPaymentSection(),
                                    _buildRetailerDetails(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Invoice Section
                              _buildInvoiceSection(),
                              const SizedBox(height: 12),
                              // Delivery Address
                              Container(
                                padding: const EdgeInsets.all(16),
                                color: Colors.white,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Delivery Address',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, color: Color(0xFF9B1B1B)),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _order!['DELIVERY_ADDRESS'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${_order!['DELIVERY_CITY'] ?? ''}, ${_order!['DELIVERY_STATE'] ?? ''}, ${_order!['DELIVERY_COUNTRY'] ?? ''} - ${_order!['DELIVERY_PINCODE'] ?? ''}\n${_order!['DELIVERY_LANDMARK'] ?? ''}',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Order Items
                              Container(
                                padding: const EdgeInsets.all(16),
                                color: Colors.white,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Order Items',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _items.length,
                                      separatorBuilder: (_, __) => const Divider(height: 24),
                                      itemBuilder: (context, index) {
                                        final item = _items[index];
                                        return Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: item['PROD_IMAGE_1'] != null && item['PROD_IMAGE_1'].toString().isNotEmpty
                                                  ? Image.network(
                                        '${ApiConfig.baseUrl}/uploads/products/${item['PROD_IMAGE_1']}',
                                                      width: 60,
                                                      height: 60,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Container(
                                                      width: 60,
                                                      height: 60,
                                                      color: Colors.grey.shade200,
                                                      child: const Icon(Icons.image, color: Colors.grey),
                                                    ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['PROD_NAME'] ?? '',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Quantity: ${item['QUANTITY']}',
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Rs. ${item['TOTAL_PRICE']}',
                                                    style: const TextStyle(
                                                      color: Color(0xFF9B1B1B),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Payment Details
                              Container(
                                padding: const EdgeInsets.all(16),
                                color: Colors.white,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Payment Details',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Subtotal',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          'Rs. ${_order!['ORDER_TOTAL']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: const [
                                        Text(
                                          'Delivery Fee',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          'Rs. 0.00',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Total',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          'Rs. ${_order!['ORDER_TOTAL']}',
                                          style: const TextStyle(
                                            color: Color(0xFF9B1B1B),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildActionButtons(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
        ),
        if (_showDeliveryConfirmation)
          Container(
            color: Colors.black54,
            child: Center(
              child: _buildDeliveryConfirmation(),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_order == null) return const SizedBox.shrink();
    
    final orderStatus = _order!['ORDER_STATUS']?.toString().toLowerCase() ?? '';
    final isAdmin = _user?.role?.toLowerCase() == 'admin';
    final isEmployee = _user?.role?.toLowerCase() == 'employee';

    // For delivered orders, show no buttons
    if (orderStatus == 'delivered') {
      return const SizedBox.shrink();
    }

    // For employee users
    if (isEmployee) {
      if (orderStatus == 'confirmed') {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF9B1B1B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isUpdatingStatus ? null : _markAsDelivered,
              child: _isUpdatingStatus
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Mark as Delivered',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    // For admin users
    if (isAdmin) {
      if (orderStatus == 'pending') {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B1B1B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isCancelling ? null : _acceptOrder,
                  child: _isCancelling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Accept Order',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isCancelling ? null : _cancelOrder,
                  child: _isCancelling
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Cancel Order',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                ),
              ),
            ],
          ),
        );
      } else if (orderStatus == 'confirmed') {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isCancelling ? null : _cancelOrder,
              child: _isCancelling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Cancel Order',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
            ),
          ),
        );
      }
    }

    // For regular users, show cancel button only for pending orders
    if (orderStatus == 'pending') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _isCancelling ? null : _cancelOrder,
            child: _isCancelling
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Cancel Order',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
} 