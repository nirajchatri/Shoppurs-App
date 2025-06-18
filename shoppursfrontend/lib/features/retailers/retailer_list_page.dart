import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/retailer_service.dart';
import '../../widgets/common_bottom_navbar.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';

class RetailerListPage extends StatefulWidget {
  const RetailerListPage({Key? key}) : super(key: key);

  @override
  State<RetailerListPage> createState() => _RetailerListPageState();
}

class _RetailerListPageState extends State<RetailerListPage> {
  final RetailerService _retailerService = RetailerService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _retailers = [];
  Map<String, dynamic>? _pagination;
  int _currentPage = 1;
  final int _limit = 5;
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRetailers();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getUser();
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_isSearching && _scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_pagination != null && _currentPage < _pagination!['totalPages']) {
        _loadMoreRetailers();
      }
    }
  }

  Future<void> _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
      });
      await _loadRetailers();
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _retailerService.searchRetailers(query);
      setState(() {
        _retailers = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRetailers() async {
    if (_isSearching) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _retailerService.getRetailerList(page: 1, limit: _limit);
      setState(() {
        _retailers = List<Map<String, dynamic>>.from(data['retailers']);
        _pagination = data['pagination'];
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreRetailers() async {
    if (_isLoading || _isSearching) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _retailerService.getRetailerList(
        page: _currentPage + 1,
        limit: _limit,
      );
      
      setState(() {
        _retailers.addAll(List<Map<String, dynamic>>.from(data['retailers']));
        _pagination = data['pagination'];
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openQRScanner() async {
    // Check camera permission
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required for QR code scanning'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Navigate to QR scanner
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerPage(
          onQRScanned: _getRetailerByQR,
          title: 'Scan Retailer QR Code',
        ),
      ),
    );
  }

  Future<void> _getRetailerByQR(String qrValue) async {
    try {
      print('Scanning QR code: $qrValue');
      
      Map<String, dynamic> retailerData;
      
      // Use different API based on user role
      if (_user?.role.toLowerCase() == 'employee') {
        // For employees, use the employee-specific API
        final token = await _authService.getToken();
        if (token == null) throw Exception('No authentication token found');
        
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/employee/get-retailer-by-phone/$qrValue'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          retailerData = data['data'];
        } else {
          throw Exception(data['message'] ?? 'Retailer not found');
        }
      } else {
        // For admin and other roles, use the existing service method
        retailerData = await _retailerService.getRetailerByPhone(qrValue);
      }
      
      print('Retailer found: ${retailerData['RET_NAME']}');
      
      if (mounted) {
        // Navigate to retailer detail page
        Navigator.pushNamed(
          context,
          '/retailer-detail',
          arguments: retailerData['RET_ID'],
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Retailer found: ${retailerData['RET_NAME']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error in _getRetailerByQR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
          'Retailer List',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, shop, or mobile',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: _openQRScanner,
                            tooltip: 'Scan QR Code',
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged();
                              },
                            ),
                        ],
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => _onSearchChanged(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadRetailers,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadRetailers,
                    child: _retailers.isEmpty && !_isLoading
                        ? const Center(
                            child: Text(
                              'No retailers found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _retailers.length + (_isLoading && !_isSearching ? 1 : 0),
                            separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.transparent),
                            itemBuilder: (context, index) {
                              if (index == _retailers.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final retailer = _retailers[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/retailer-detail',
                                    arguments: retailer['RET_ID'],
                                  );
                                },
                                child: Container(
                                  color: Colors.white,
                                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: retailer['RET_PHOTO'] != null && retailer['RET_PHOTO'].toString().isNotEmpty
                                            ? Image.network(
                                                retailer['RET_PHOTO'].toString().startsWith('http')
                                                    ? retailer['RET_PHOTO']
                                                    : 'http://192.168.29.96:3000/uploads/retailers/profiles/${retailer['RET_PHOTO']}',
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Container(
                                                  width: 60,
                                                  height: 60,
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey.shade200,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Icon(Icons.store, color: Colors.grey),
                                                ),
                                              )
                                            : Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade200,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(Icons.store, color: Colors.grey),
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              retailer['RET_NAME'] ?? 'N/A',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            if (retailer['RET_SHOP_NAME'] != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                retailer['RET_SHOP_NAME'],
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 2),
                                            Text(
                                              retailer['RET_MOBILE_NO']?.toString() ?? 'N/A',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${retailer['RET_ADDRESS']}, ${retailer['RET_CITY']}, ${retailer['RET_STATE']}',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: CommonBottomNavBar(
        currentIndex: 2, // Retailer list page is the RETAILERS tab
        user: _user,
      ),
    );
  }
}

class QRScannerPage extends StatefulWidget {
  final Future<void> Function(String) onQRScanned;
  final String title;
  
  const QRScannerPage({
    Key? key,
    required this.onQRScanned,
    this.title = 'Scan QR Code',
  }) : super(key: key);

  @override
  _QRScannerPageState createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  bool isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.white);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                return const Icon(Icons.camera_front, color: Colors.white);
              },
            ),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) async {
              if (!isProcessing) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final barcode = barcodes.first;
                  if (barcode.rawValue != null) {
                    setState(() {
                      isProcessing = true;
                    });
                    
                    try {
                      print('QR Code detected: ${barcode.rawValue!}');
                      
                      // Close the scanner first
                      Navigator.pop(context);
                      
                      // Then call the callback function
                      await widget.onQRScanned(barcode.rawValue!);
                    } catch (e) {
                      print('Error processing QR code: $e');
                      // Reset processing state on error
                      if (mounted) {
                        setState(() {
                          isProcessing = false;
                        });
                      }
                    }
                  }
                }
              }
            },
          ),
          // Overlay with scanning area
          Container(
            decoration: ShapeDecoration(
              shape: ScannerOverlayShape(
                borderColor: const Color(0xFF9B1B1B),
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 4,
                cutOutSize: 250,
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                isProcessing 
                    ? 'Processing...' 
                    : 'Place the QR code inside the frame to scan',
                style: TextStyle(
                  color: isProcessing ? Colors.yellow : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayShape extends ShapeBorder {
  const ScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    double? cutOutSize,
    double? cutOutWidth,
    double? cutOutHeight,
  })  : cutOutWidth = cutOutWidth ?? cutOutSize ?? 250,
        cutOutHeight = cutOutHeight ?? cutOutSize ?? 250;

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutWidth;
  final double cutOutHeight;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(rect.left, rect.top, rect.left + borderRadius, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderHeightSize = height / 2;
    final cutOutWidth =
        this.cutOutWidth < width ? this.cutOutWidth : width - borderWidth;
    final cutOutHeight =
        this.cutOutHeight < height ? this.cutOutHeight : height - borderWidth;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromLTWH(
      rect.left + (width - cutOutWidth) / 2 + borderWidth,
      rect.top + (height - cutOutHeight) / 2 + borderWidth,
      cutOutWidth - borderWidth * 2,
      cutOutHeight - borderWidth * 2,
    );

    canvas
      ..drawPath(
          Path.combine(
            PathOperation.difference,
            Path()..addRect(rect),
            Path()
              ..addRRect(RRect.fromRectAndRadius(
                  cutOutRect, Radius.circular(borderRadius)))
              ..close(),
          ),
          backgroundPaint)
      ..drawRRect(
          RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
          borderPaint);

    // Draw corner borders
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Top left corner
    canvas.drawPath(
        Path()
          ..moveTo(cutOutRect.left - borderWidth, cutOutRect.top)
          ..lineTo(cutOutRect.left - borderWidth, cutOutRect.top - borderLength)
          ..moveTo(cutOutRect.left, cutOutRect.top - borderWidth)
          ..lineTo(cutOutRect.left + borderLength, cutOutRect.top - borderWidth),
        cornerPaint);

    // Top right corner
    canvas.drawPath(
        Path()
          ..moveTo(cutOutRect.right + borderWidth, cutOutRect.top)
          ..lineTo(cutOutRect.right + borderWidth, cutOutRect.top - borderLength)
          ..moveTo(cutOutRect.right, cutOutRect.top - borderWidth)
          ..lineTo(cutOutRect.right - borderLength, cutOutRect.top - borderWidth),
        cornerPaint);

    // Bottom left corner
    canvas.drawPath(
        Path()
          ..moveTo(cutOutRect.left - borderWidth, cutOutRect.bottom)
          ..lineTo(cutOutRect.left - borderWidth, cutOutRect.bottom + borderLength)
          ..moveTo(cutOutRect.left, cutOutRect.bottom + borderWidth)
          ..lineTo(cutOutRect.left + borderLength, cutOutRect.bottom + borderWidth),
        cornerPaint);

    // Bottom right corner
    canvas.drawPath(
        Path()
          ..moveTo(cutOutRect.right + borderWidth, cutOutRect.bottom)
          ..lineTo(cutOutRect.right + borderWidth, cutOutRect.bottom + borderLength)
          ..moveTo(cutOutRect.right, cutOutRect.bottom + borderWidth)
          ..lineTo(cutOutRect.right - borderLength, cutOutRect.bottom + borderWidth),
        cornerPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return ScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
} 