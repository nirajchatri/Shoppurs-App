import 'package:flutter/material.dart';
import '../models/user_model.dart';

class CommonBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final User? user;

  const CommonBottomNavBar({
    Key? key,
    required this.currentIndex,
    this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF9B1B1B),
      unselectedItemColor: Colors.grey,
      currentIndex: currentIndex,
      onTap: (index) {
        _handleNavigation(context, index);
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
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/orders');
        break;
      case 1:
        Navigator.pushNamed(context, '/home');
        break;
      case 2:
        if (user?.role?.toLowerCase() == 'admin' || user?.role?.toLowerCase() == 'employee') {
          Navigator.pushNamed(context, '/retailer-list');
        } else {
          Navigator.pushNamed(context, '/self-retailer-detail');
        }
        break;
      case 3:
        Navigator.pushNamed(context, '/home');
        break;
      case 4:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }
} 