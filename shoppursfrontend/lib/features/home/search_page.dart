import 'package:flutter/material.dart';
import '../../services/product_service.dart';
import 'dart:async';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ProductService _productService = ProductService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  String _searchError = '';
  bool _showSearchDropdown = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchDropdown = false;
      });
      return;
    }
    
    // Increased debounce time to reduce API calls
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _searchProducts(query);
    });
  }

  Future<void> _searchProducts(String query) async {
    setState(() {
      _isSearching = true;
      _searchError = '';
      _showSearchDropdown = true;
    });
    
    final result = await _productService.searchProducts(query, context: context);
    
    setState(() {
      _isSearching = false;
      _showSearchDropdown = true;
      
      if (result['success'] == true) {
        _searchResults = List<Map<String, dynamic>>.from(result['data'] ?? []);
        _searchError = '';
      } else {
        _searchResults = [];
        _searchError = result['message'] ?? 'Search failed';
      }
    });
  }

  void _onSearchResultTap(Map<String, dynamic> product) {
    setState(() {
      _showSearchDropdown = false;
    });
    Navigator.pushNamed(context, '/product-detail', arguments: product['PROD_ID']);
  }

  Future<void> _openBarcodeScanner() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerPage(
          onBarcodeScanned: _getProductByBarcode,
          title: 'Scan Product Barcode',
        ),
      ),
    );
  }

  Future<void> _getProductByBarcode(String barcode) async {
    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');
      
      final response = await http.post(
        Uri.parse(ApiConfig.productsGetByBarcode),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'PRDB_BARCODE': barcode,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        final productId = data['data']['productId'];
        
        if (mounted) {
          Navigator.pushNamed(
            context,
            '/product-detail',
            arguments: productId,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Product found successfully'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Product not found'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _highlightSearchTerm(String text, String term) {
    if (term.isEmpty) return Text(text);
    final lcText = text.toLowerCase();
    final lcTerm = term.toLowerCase();
    final start = lcText.indexOf(lcTerm);
    if (start == -1) return Text(text);
    final end = start + term.length;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(text: text.substring(start, end), style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: text.substring(end)),
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
        title: const Text(
          'Search Products',
          style: TextStyle(
            color: Color(0xFF9B1B1B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search for groceries and more',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt_outlined),
                        onPressed: _openBarcodeScanner,
                      ),
                    ),
                  ],
                ),
              ),
              if (_searchResults.isNotEmpty)
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final prod = _searchResults[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: prod['PROD_IMAGE_1'] != null && prod['PROD_IMAGE_1'].toString().isNotEmpty
                              ? Image.network(
                                  prod['PROD_IMAGE_1'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                                )
                              : const Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                        ),
                        title: _highlightSearchTerm(prod['PROD_NAME'] ?? '', _searchController.text.trim()),
                        subtitle: Text(
                          'MRP: ₹${prod['PROD_MRP'] ?? 'N/A'}',
                          style: const TextStyle(
                            color: Color(0xFF9B1B1B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onTap: () => _onSearchResultTap(prod),
                      );
                    },
                  ),
                )
              else if (_isSearching)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF9B1B1B),
                    ),
                  ),
                )
              else if (_searchError.isNotEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      _searchError,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else if (_searchController.text.isNotEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No results found',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Search for products',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class BarcodeScannerPage extends StatefulWidget {
  final Future<void> Function(String) onBarcodeScanned;
  final String title;
  
  const BarcodeScannerPage({
    Key? key,
    required this.onBarcodeScanned,
    this.title = 'Scan Barcode',
  }) : super(key: key);

  @override
  _BarcodeScannerPageState createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
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
                      // Close the scanner first
                      Navigator.pop(context);
                      
                      // Then call the callback function
                      await widget.onBarcodeScanned(barcode.rawValue!);
                    } catch (e) {
                      print('Error processing barcode: $e');
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
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                isProcessing 
                    ? 'Processing...' 
                    : 'Place the barcode inside the frame to scan',
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
    final height = rect.height;
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