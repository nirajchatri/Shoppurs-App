import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/customer_service.dart';
import '../../services/auth_service.dart';
import '../../models/customer_model.dart';
import '../../widgets/error_message_widget.dart';
import '../../widgets/location_picker_map.dart';

class CreateCustomerPage extends StatefulWidget {
  const CreateCustomerPage({Key? key}) : super(key: key);

  @override
  State<CreateCustomerPage> createState() => _CreateCustomerPageState();
}

class _CreateCustomerPageState extends State<CreateCustomerPage> {
  final CustomerService _customerService = CustomerService();
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Controllers for basic info
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _longController = TextEditingController();

  // Address mode - single or multiple
  bool _multipleAddresses = false;
  List<AddressForm> _addresses = [];

  // Loading and error states
  bool _isLoading = false;
  String? _error;
  String? _userRole;
  String _selectedLocationText = '';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    // Initialize with one address for multiple mode
    _addresses.add(AddressForm());
    // Set default password
    _passwordController.text = '123456';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _storeNameController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _zipController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _longController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final user = await _authService.getUser();
    setState(() {
      _userRole = user?.role.toLowerCase();
    });
  }

  void _addAddress() {
    setState(() {
      _addresses.add(AddressForm());
    });
  }

  void _removeAddress(int index) {
    if (_addresses.length > 1) {
      setState(() {
        _addresses.removeAt(index);
      });
    }
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerMap(
          initialLat: _latController.text.isNotEmpty ? double.tryParse(_latController.text) : null,
          initialLng: _longController.text.isNotEmpty ? double.tryParse(_longController.text) : null,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _latController.text = result['latitude'].toString();
        _longController.text = result['longitude'].toString();
        _selectedLocationText = result['address'] ?? 'Location Selected';
      });
    }
  }

  Future<void> _createCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate mobile number
    if (!_customerService.isValidMobile(_mobileController.text)) {
      setState(() {
        _error = 'Please enter a valid 10-digit mobile number starting with 6-9';
      });
      return;
    }

    // Validate email if provided
    if (_emailController.text.isNotEmpty && !_customerService.isValidEmail(_emailController.text)) {
      setState(() {
        _error = 'Please enter a valid email address';
      });
      return;
    }

    // Validate location selection for single address mode
    if (!_multipleAddresses) {
      if (_latController.text.trim().isEmpty || _longController.text.trim().isEmpty) {
        setState(() {
          _error = 'Please select a location on the map';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      CreateCustomerRequest request;
      
      if (_multipleAddresses) {
        // Validate all addresses
        for (int i = 0; i < _addresses.length; i++) {
          if (!_addresses[i].isValid()) {
            setState(() {
              _error = 'Please fill all required fields for address ${i + 1}';
              _isLoading = false;
            });
            return;
          }
        }

        // Create request with multiple addresses
        request = CreateCustomerRequest(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          mobile: _mobileController.text.trim(),
          password: _passwordController.text.trim().isEmpty ? '123456' : _passwordController.text.trim(),
          storeName: _storeNameController.text.trim(),
          city: _cityController.text.trim(),
          province: _provinceController.text.trim(),
          zip: _zipController.text.trim(),
          address: _addressController.text.trim(),
          lat: _latController.text.trim(),
          long: _longController.text.trim(),
          addresses: _addresses.map((addr) => CustomerAddressRequest(
            address: addr.addressController.text.trim(),
            city: addr.cityController.text.trim(),
            state: addr.stateController.text.trim(),
            country: addr.countryController.text.trim(),
            pincode: addr.pincodeController.text.trim(),
            landmark: addr.landmarkController.text.trim().isEmpty ? null : addr.landmarkController.text.trim(),
            addressType: addr.addressType,
            isDefault: addr.isDefault,
          )).toList(),
        );

        await _customerService.createCustomerWithAddresses(request);
      } else {
        // Create request with single address
        request = CreateCustomerRequest(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          mobile: _mobileController.text.trim(),
          password: _passwordController.text.trim().isEmpty ? '123456' : _passwordController.text.trim(),
          storeName: _storeNameController.text.trim(),
          city: _cityController.text.trim(),
          province: _provinceController.text.trim(),
          zip: _zipController.text.trim(),
          address: _addressController.text.trim(),
          lat: _latController.text.trim(),
          long: _longController.text.trim(),
          addressDetails: _addressController.text.trim(),
          addressCity: _cityController.text.trim(),
          addressState: _provinceController.text.trim(),
          addressCountry: 'India',
          addressPincode: _zipController.text.trim(),
          addressType: 'Home',
          isDefaultAddress: true,
        );

        await _customerService.createCustomer(request);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Widget _buildBasicInfoSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9B1B1B),
              ),
            ),
            const SizedBox(height: 16),
            
            // Username
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the customer\'s full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
                helperText: 'Auto-generated if not provided',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Mobile
            TextFormField(
              controller: _mobileController,
              decoration: const InputDecoration(
                labelText: 'Mobile Number *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
                prefixText: '+91 ',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter mobile number';
                }
                if (!_customerService.isValidMobile(value.trim())) {
                  return 'Enter valid 10-digit mobile number starting with 6-9';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Store Name
            TextFormField(
              controller: _storeNameController,
              decoration: const InputDecoration(
                labelText: 'Store Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter store name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Password
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                helperText: 'Default: 123456',
              ),
              obscureText: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressModeSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Address Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9B1B1B),
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Single Address'),
                    value: false,
                    groupValue: _multipleAddresses,
                    onChanged: (value) {
                      setState(() {
                        _multipleAddresses = value!;
                      });
                    },
                    activeColor: const Color(0xFF9B1B1B),
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Multiple Addresses'),
                    value: true,
                    groupValue: _multipleAddresses,
                    onChanged: (value) {
                      setState(() {
                        _multipleAddresses = value!;
                      });
                    },
                    activeColor: const Color(0xFF9B1B1B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleAddressSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Address Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9B1B1B),
              ),
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter address';
                }
                return null;
              },
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // City and Province
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter city';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _provinceController,
                    decoration: const InputDecoration(
                      labelText: 'State/Province *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter state';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ZIP Code
            TextFormField(
              controller: _zipController,
              decoration: const InputDecoration(
                labelText: 'PIN Code *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pin_drop),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter PIN code';
                }
                if (!_customerService.isValidPincode(value.trim())) {
                  return 'Please enter valid 6-digit PIN code';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Location Picker
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: InkWell(
                onTap: _openLocationPicker,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.map, color: Color(0xFF9B1B1B)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedLocationText.isEmpty 
                                  ? 'Select Location *' 
                                  : _selectedLocationText,
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedLocationText.isEmpty 
                                    ? Colors.grey[600] 
                                    : Colors.black87,
                              ),
                            ),
                            if (_latController.text.isNotEmpty && _longController.text.isNotEmpty)
                              Text(
                                'Lat: ${_latController.text}, Lng: ${_longController.text}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleAddressesSection() {
    return Column(
      children: [
        // Header with Add Button
        Card(
          margin: const EdgeInsets.all(16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Multiple Addresses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9B1B1B),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addAddress,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Add Address',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B1B1B),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Address Forms
        ...List.generate(_addresses.length, (index) {
          return _buildAddressForm(index);
        }),
      ],
    );
  }

  Widget _buildAddressForm(int index) {
    final address = _addresses[index];
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Address ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    // Default Address Checkbox
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: address.isDefault,
                          onChanged: (value) {
                            setState(() {
                              // Uncheck all other addresses
                              for (var addr in _addresses) {
                                addr.isDefault = false;
                              }
                              // Check this address
                              address.isDefault = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFF9B1B1B),
                        ),
                        const Text('Default'),
                      ],
                    ),
                    // Remove Button
                    if (_addresses.length > 1)
                      IconButton(
                        onPressed: () => _removeAddress(index),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Address Type Dropdown
            DropdownButtonFormField<String>(
              value: address.addressType,
              decoration: const InputDecoration(
                labelText: 'Address Type',
                border: OutlineInputBorder(),
              ),
              items: ['Home', 'Work', 'Other'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  address.addressType = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Address
            TextFormField(
              controller: address.addressController,
              decoration: const InputDecoration(
                labelText: 'Address *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // City and State
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: address.cityController,
                    decoration: const InputDecoration(
                      labelText: 'City *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: address.stateController,
                    decoration: const InputDecoration(
                      labelText: 'State *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Country and Pincode
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: address.countryController,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: address.pincodeController,
                    decoration: const InputDecoration(
                      labelText: 'PIN Code *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Landmark
            TextFormField(
              controller: address.landmarkController,
              decoration: const InputDecoration(
                labelText: 'Landmark (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.place),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Create Customer',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF9B1B1B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildBasicInfoSection(),
                  _buildAddressModeSection(),
                  if (!_multipleAddresses) _buildSingleAddressSection(),
                  if (_multipleAddresses) _buildMultipleAddressesSection(),
                  
                  // Error Display
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.all(16),
                      child: ErrorMessageWidget(
                        message: _error!,
                        onRetry: () {
                          setState(() {
                            _error = null;
                          });
                        },
                      ),
                    ),
                  
                  const SizedBox(height: 100), // Space for button
                ],
              ),
            ),

            // Create Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B1B1B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                      : const Text(
                          'Create Customer & Retailer Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class for managing address forms
class AddressForm {
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController landmarkController = TextEditingController();
  String addressType = 'Home';
  bool isDefault = false;

  AddressForm() {
    countryController.text = 'India'; // Default country
  }

  bool isValid() {
    return addressController.text.trim().isNotEmpty &&
           cityController.text.trim().isNotEmpty &&
           stateController.text.trim().isNotEmpty &&
           countryController.text.trim().isNotEmpty &&
           pincodeController.text.trim().isNotEmpty &&
           RegExp(r'^\d{6}$').hasMatch(pincodeController.text.trim());
  }

  void dispose() {
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    countryController.dispose();
    pincodeController.dispose();
    landmarkController.dispose();
  }
} 