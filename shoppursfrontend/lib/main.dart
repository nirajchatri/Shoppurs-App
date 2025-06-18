import 'package:flutter/material.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/auth/signup_page.dart';
import 'features/auth/login_page.dart';
import 'features/auth/otp_verify_page.dart';
import 'features/auth/reset_password_page.dart';
import 'features/auth/verify_reset_otp_page.dart';
import 'features/auth/new_password_page.dart';
import 'features/product/product_list_page.dart';
import 'features/product/product_detail_page.dart';
import 'features/product/edit_product_page.dart';
import 'features/product/add_product_page.dart';
import 'features/orders/orders_page.dart';
import 'features/orders/order_details_page.dart';
import 'features/orders/employee_orders_page.dart';
import 'features/retailers/retailer_list_page.dart';
import 'features/retailers/retailer_detail_page.dart';
import 'features/retailers/self_retailer_detail_page.dart';
import 'features/retailers/edit_retailer_page.dart';
import 'features/retailers/admin_edit_retailer_page.dart';
import 'features/retailers/retailer_selection_page.dart';
import 'features/home/home_page.dart';
import 'features/cart/cart_page.dart';
import 'features/payment/payment_page.dart';
import 'features/home/search_page.dart';
import 'features/home/profile_page.dart';
import 'features/profile/address_list_page.dart';
import 'features/profile/add_address_page.dart';
import 'features/profile/edit_profile_page.dart';
import 'features/notifications/notification_page.dart';
import 'features/admin/manage_users_page.dart';
import 'features/admin/category_management_page.dart';
import 'features/admin/user_management_page.dart';
import 'features/admin/create_user_page.dart';
import 'features/admin/user_details_page.dart';
import 'startup_page.dart';
import 'debug_helper.dart';
import 'services/http_client.dart';
import 'services/connectivity_service.dart';
import 'services/error_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize HTTP client for mobile
  HttpClient.configureClient();
  
  // Reset all popup states on app start
  ErrorHandler.resetPopupStates();
  
  // Debug: Log all service URLs to verify they're using Render URL
  DebugHelper.logAllServiceUrls();
  
  // Check connectivity on startup (for mobile)
  try {
    final connectivityStatus = await ConnectivityService.checkConnectivity();
    print('Startup Connectivity Status: ${connectivityStatus.message}');
  } catch (e) {
    print('Connectivity check failed: $e');
  }
  
  runApp(const ShoppursShopApp());
}

class ShoppursShopApp extends StatelessWidget {
  const ShoppursShopApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shoppurs Shop',
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'Poppins',
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      // Global navigation observer to set context for error handling
      navigatorObservers: [
        _ErrorHandlingNavigatorObserver(),
      ],
      routes: {
        '/': (context) => const StartupPage(),
        '/onboarding': (context) => const OnboardingPage(),
        '/signup': (context) => SignupPage(),
        '/login': (context) => LoginPage(),
        '/otp-verify': (context) => OtpVerifyPage(),
        '/reset-password': (context) => const ResetPasswordPage(),
        '/verify-reset-otp': (context) => const VerifyResetOtpPage(),
        '/new-password': (context) => const NewPasswordPage(),
        '/product-list': (context) => ProductListPage(),
        '/product-detail': (context) => ProductDetailPage(),
        '/edit-product': (context) => const EditProductPage(),
        '/add-product': (context) => const AddProductPage(),
        '/orders': (context) => OrdersPage(),
        '/order-details': (context) => const OrderDetailsPage(),
        '/employee-orders': (context) => const EmployeeOrdersPage(),
        '/retailers': (context) => RetailerListPage(),
        '/retailer-detail': (context) => RetailerDetailPage(),
        '/self-retailer-detail': (context) => const SelfRetailerDetailPage(),
        '/edit-retailer': (context) => const EditRetailerPage(),
        '/admin-edit-retailer': (context) => const AdminEditRetailerPage(),
        '/retailer-selection': (context) => const RetailerSelectionPage(),
        '/home': (context) => HomePage(),
        '/cart': (context) => CartPage(),
        '/payment': (context) => PaymentPage(),
        '/search': (context) => const SearchPage(),
        '/profile': (context) => const ProfilePage(),
        '/edit-profile': (context) => const EditProfilePage(),
        '/address-list': (context) => const AddressListPage(),
        '/add-address': (context) => const AddAddressPage(),
        '/notifications': (context) => const NotificationPage(),
        '/manage-users': (context) => const ManageUsersPage(),
        '/category-management': (context) => const CategoryManagementPage(),
        '/user-management': (context) => const UserManagementPage(),
        '/retailer-list': (context) => const RetailerListPage(),
      },
    );
  }
}

// Navigator observer to set context for error handling
class _ErrorHandlingNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != null) {
      _setErrorHandlingContext();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _setErrorHandlingContext();
  }

  void _setErrorHandlingContext() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigator?.context;
      if (context != null) {
        HttpClient.setContext(context);
        ErrorHandler.setContext(context);
      }
    });
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
