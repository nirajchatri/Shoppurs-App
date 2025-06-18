import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';

class SelfRetailerDetailPage extends StatefulWidget {
  const SelfRetailerDetailPage({Key? key}) : super(key: key);

  @override
  State<SelfRetailerDetailPage> createState() => _SelfRetailerDetailPageState();
}

class _SelfRetailerDetailPageState extends State<SelfRetailerDetailPage> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? retailerData;
  bool isLoading = true;
  String? error;
  bool isLocationLoading = false;
  double? currentLat;
  double? currentLong;

  @override
  void initState() {
    super.initState();
    _fetchRetailerData();
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

  Future<void> _useMapLocation() async {
    setState(() {
      isLocationLoading = true;
    });

    try {
      final location = await _getCurrentLocation();
      
      if (location['lat'] != null && location['long'] != null) {
        setState(() {
          currentLat = location['lat'];
          currentLong = location['long'];
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Refresh data with new location
        _fetchRetailerData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get location. Please try again.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error getting location. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        isLocationLoading = false;
      });
    }
  }

  Future<void> _fetchRetailerData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) throw Exception('No authentication token found');

      // Build URL with location parameters if available
      String url = 'http://192.168.29.96:3000/api/retailers/my-retailer';
      Map<String, String> queryParams = {};
      
      if (currentLat != null && currentLong != null) {
        queryParams['lat'] = currentLat.toString();
        queryParams['long'] = currentLong.toString();
      }
      
      if (queryParams.isNotEmpty) {
        final uri = Uri.parse(url).replace(queryParameters: queryParams);
        url = uri.toString();
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          retailerData = data['data'];
          isLoading = false;
        });
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch retailer data');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
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
          'My Retailer Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.my_location,
              color: currentLat != null && currentLong != null ? Colors.green : Colors.black,
            ),
            onPressed: isLocationLoading ? null : _useMapLocation,
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () => Navigator.pushNamed(
              context, 
              '/edit-retailer',
              arguments: retailerData?['retailer']
            ).then((_) => _fetchRetailerData()),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchRetailerData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        if (isLocationLoading)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Getting location...',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (currentLat != null && currentLong != null)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.green.shade600,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Location: ${currentLat!.toStringAsFixed(4)}, ${currentLong!.toStringAsFixed(4)}',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (isLocationLoading || (currentLat != null && currentLong != null))
                          const SizedBox(height: 8),
                        _buildShopInfo(),
                        const SizedBox(height: 16),
                        _buildSalesSummary(),
                        const SizedBox(height: 18),
                        _buildSalesChart(),
                        const SizedBox(height: 18),
                        _buildTopProducts(),
                        const SizedBox(height: 18),
                        _buildRecentOrders(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF9B1B1B),
        unselectedItemColor: Colors.grey,
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/orders');
              break;
            case 1:
              Navigator.pushNamed(context, '/home');
              break;
            case 2:
              // Already on self retailer detail page
              break;
            case 3:
              Navigator.pushNamed(context, '/home');
              break;
            case 4:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'ORDERS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'PRODUCTS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            label: 'RETAILERS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'SEARCH',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'ACCOUNT',
          ),
        ],
      ),
    );
  }

  Widget _buildShopInfo() {
    final retailer = retailerData?['retailer'];
    if (retailer == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            retailer['RET_SHOP_NAME'] ?? 'Shop Name',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(height: 16),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: retailer['RET_PHOTO'] != null
                ? Image.network(
                    retailer['RET_PHOTO'].toString().startsWith('http')
                        ? retailer['RET_PHOTO']
                        : '${ApiConfig.baseUrl}/uploads/retailers/profiles/${retailer['RET_PHOTO']}',
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Image.asset(
                          'assets/images/user2.png',
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                  )
                : Image.asset(
                    'assets/images/user2.png',
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, size: 18, color: Color(0xFF9B1B1B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${retailer['RET_ADDRESS']}, ${retailer['RET_CITY']}, ${retailer['RET_STATE']} - ${retailer['RET_PIN_CODE']}',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 18, color: Color(0xFF9B1B1B)),
                        const SizedBox(width: 8),
                        Text(
                          retailer['RET_MOBILE_NO']?.toString() ?? 'N/A',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 18, color: Color(0xFF9B1B1B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            retailer['RET_EMAIL_ID'] ?? 'N/A',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSalesSummary() {
    final salesSummary = retailerData?['sales_summary'];
    if (salesSummary == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Summary',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                'Total Orders',
                salesSummary['total_orders']?.toString() ?? '0',
                Icons.shopping_cart,
                Colors.blue,
              ),
              _buildSummaryItem(
                'Total Sales',
                'Rs. ${salesSummary['total_sales_amount']?.toString() ?? '0'}',
                Icons.currency_rupee,
                Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                'Items Sold',
                salesSummary['total_items_sold']?.toString() ?? '0',
                Icons.inventory,
                Colors.orange,
              ),
              _buildSummaryItem(
                'Avg Order',
                'Rs. ${salesSummary['average_order_value']?.toString() ?? '0'}',
                Icons.analytics,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart() {
    final graphData = retailerData?['graph_data'];
    if (graphData == null) return const SizedBox();

    final dailySales = graphData['daily_sales'] as List? ?? [];
    
    // If no data, show placeholder
    if (dailySales.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sales Trend (Last 7 Days)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'No sales data available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    // Create chart with actual data
    final maxValue = dailySales.fold<double>(0, (max, item) => 
        (item['sales_amount'] as num).toDouble() > max ? (item['sales_amount'] as num).toDouble() : max);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales Trend (Last 7 Days)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: dailySales.take(7).map<Widget>((item) {
                final amount = (item['sales_amount'] as num).toDouble();
                final height = maxValue > 0 ? (amount / maxValue) * 100 : 0.0;
                final colors = [
                  Colors.orange,
                  Colors.cyan,
                  Colors.purple,
                  Colors.amber,
                  Colors.pink,
                  Colors.blue,
                  Colors.red,
                ];
                final colorIndex = dailySales.indexOf(item) % colors.length;
                
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: height.clamp(10.0, 100.0),
                    decoration: BoxDecoration(
                      color: colors[colorIndex],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '₹${amount.toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: dailySales.take(7).map<Widget>((item) {
              final date = DateTime.parse(item['date']);
              final dayName = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][date.weekday % 7];
              
              return Expanded(
                child: Text(
                  dayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    final topProducts = retailerData?['top_products'] as List? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Products',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          if (topProducts.isEmpty)
            const Center(
              child: Text(
                'No top products data available',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...topProducts.take(5).map((product) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shopping_bag, color: Colors.grey, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['product_name'] ?? 'Product',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Sold: ${product['total_quantity']} units',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${product['total_amount']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildRecentOrders() {
    final recentOrders = retailerData?['recent_orders'] as List? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Orders',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          if (recentOrders.isEmpty)
            const Center(
              child: Text(
                'No recent orders',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...recentOrders.take(5).map((order) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shopping_bag, color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order['order_number']}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${order['total_quantity']} items • ${order['customer_name']}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${order['total_amount']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        order['status']?.toString().toUpperCase() ?? 'PENDING',
                        style: TextStyle(
                          fontSize: 12,
                          color: order['status'] == 'completed' ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )).toList(),
        ],
      ),
    );
  }
} 