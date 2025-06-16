import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io';
import '../../models/category_model.dart';
import '../../models/product_unit.dart';
import '../../services/product_service.dart';
import '../../services/category_service.dart';
import 'dart:convert';

class AddProductPage extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  
  const AddProductPage({Key? key, this.initialData}) : super(key: key);

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final ImagePicker _imagePicker = ImagePicker();

  // Controllers for form fields
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descController = TextEditingController();
  final _mrpController = TextEditingController();
  final _spController = TextEditingController();
  final _reorderLevelController = TextEditingController();
  final _qohController = TextEditingController();
  final _hsnCodeController = TextEditingController();
  final _cgstController = TextEditingController();
  final _igstController = TextEditingController();
  final _sgstController = TextEditingController();
  final _mfgDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _mfgByController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subCategories = [];
  int? _selectedCategoryId;
  int? _selectedSubCategoryId;
  String _isBarcodeAvailable = 'N';
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isLoadingSubCategories = false;
  String? _error;
  String? _subCategoriesError;

  // Product units
  List<ProductUnit> _productUnits = [];

  // Controllers for the unit form
  final _unitNameController = TextEditingController();
  final _unitValueController = TextEditingController();
  final _unitRateController = TextEditingController();

  // Image files
  File? _prodImage1;
  File? _prodImage2;
  File? _prodImage3;

  // Barcodes
  List<String> _barcodes = [];
  final _barcodeController = TextEditingController();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load categories from API
      final result = await _categoryService.getCategories(context: context);
      if (mounted) {
        setState(() {
          if (result['success'] == true) {
            final categories = List<Category>.from(result['data'] ?? []);
            _categories = categories.map((category) => {
              'CATEGORY_ID': category.id,
              'CATEGORY_NAME': category.name,
              'sub_categories': category.subCategories ?? [],
            }).toList();
          } else {
            _categories = [];
          }
          _isLoading = false;
        });
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

  Future<void> _loadSubCategories(int categoryId) async {
    print('Loading subcategories for categoryId: $categoryId');
    if (!mounted) return;
    
    setState(() {
      _isLoadingSubCategories = true;
      _subCategoriesError = null;
      _selectedSubCategoryId = null;
      _subCategories = []; // Clear existing subcategories
    });

    try {
      final result = await _categoryService.getSubCategoriesByCategoryId(categoryId, context: context);
      print('Subcategories API Response: $result');
      
      if (!mounted) return;

      setState(() {
        if (result['success'] == true) {
          final subCategoriesData = result['data'] as List<dynamic>? ?? [];
          print('Raw subcategories data: $subCategoriesData');
          
          // Handle both SubCategory objects and raw data
          _subCategories = subCategoriesData.map((subCat) {
            if (subCat is Map<String, dynamic>) {
              // Check if it's a SubCategory object with 'id' field or raw data with 'SUB_CATEGORY_ID'
              if (subCat.containsKey('id')) {
                // SubCategory object format
                return {
                  'SUB_CATEGORY_ID': subCat['id'],
                  'SUB_CATEGORY_NAME': subCat['name'],
                };
              } else {
                // Raw data format
                return {
                  'SUB_CATEGORY_ID': subCat['SUB_CATEGORY_ID'],
                  'SUB_CATEGORY_NAME': subCat['SUB_CATEGORY_NAME'],
                };
              }
            } else {
              // If it's a SubCategory object
              return {
                'SUB_CATEGORY_ID': subCat.id,
                'SUB_CATEGORY_NAME': subCat.name,
              };
            }
          }).toList();
          print('Mapped subcategories: $_subCategories');
        } else {
          _subCategories = [];
          _subCategoriesError = result['message'] ?? 'Failed to load subcategories';
          print('Error from API: ${result['message']}');
        }
        _isLoadingSubCategories = false;
      });
    } catch (e) {
      print('Error loading subcategories: $e');
      print('Error stack trace: ${StackTrace.current}');
      if (!mounted) return;
      setState(() {
        _subCategories = [];
        _subCategoriesError = 'Error loading subcategories: ${e.toString()}';
        _isLoadingSubCategories = false;
      });
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      controller.text = picked.toIso8601String().split('T')[0];
    }
  }

  Future<void> _pickImage(int imageNumber) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        final XFile? image = await _imagePicker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 85,
                          maxWidth: 1920,
                          maxHeight: 1080,
                        );
                        if (image != null) {
                          // Validate file extension
                          final extension = image.path.split('.').last.toLowerCase();
                          if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
                            setState(() {
                              switch (imageNumber) {
                                case 1:
                                  _prodImage1 = File(image.path);
                                  break;
                                case 2:
                                  _prodImage2 = File(image.path);
                                  break;
                                case 3:
                                  _prodImage3 = File(image.path);
                                  break;
                              }
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a valid image file (jpg, png, gif, webp)'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error selecting image: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9B1B1B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Color(0xFF9B1B1B),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Camera',
                            style: TextStyle(
                              color: Color(0xFF9B1B1B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        final XFile? image = await _imagePicker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 85,
                          maxWidth: 1920,
                          maxHeight: 1080,
                        );
                        if (image != null) {
                          // Validate file extension
                          final extension = image.path.split('.').last.toLowerCase();
                          if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
                            setState(() {
                              switch (imageNumber) {
                                case 1:
                                  _prodImage1 = File(image.path);
                                  break;
                                case 2:
                                  _prodImage2 = File(image.path);
                                  break;
                                case 3:
                                  _prodImage3 = File(image.path);
                                  break;
                              }
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a valid image file (jpg, png, gif, webp)'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error selecting image: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9B1B1B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.photo_library,
                            size: 40,
                            color: Color(0xFF9B1B1B),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Gallery',
                            style: TextStyle(
                              color: Color(0xFF9B1B1B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(String label, File? imageFile, int imageNumber, {bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? ' *' : ''),
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: imageFile != null
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        imageFile,
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            switch (imageNumber) {
                              case 1:
                                _prodImage1 = null;
                                break;
                              case 2:
                                _prodImage2 = null;
                                break;
                              case 3:
                                _prodImage3 = null;
                                break;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : GestureDetector(
                  onTap: () => _pickImage(imageNumber),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 40,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add image',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  void _addBarcode() {
    if (_barcodeController.text.trim().isNotEmpty) {
      final barcode = _barcodeController.text.trim();
      if (!_barcodes.contains(barcode)) {
        setState(() {
          _barcodes.add(barcode);
          _barcodeController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Barcode "$barcode" added successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This barcode is already added'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _scanBarcode() async {
    setState(() {
      _isScanning = false; // Reset scanning state
    });
    
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          height: 400,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF9B1B1B),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Scan Barcode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _isScanning = false;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                  child: MobileScanner(
                    onDetect: (capture) {
                      // Prevent multiple detections
                      if (_isScanning) return;
                      
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                          final scannedValue = barcode.rawValue!;
                          
                          // Set scanning flag to prevent multiple detections
                          setState(() {
                            _isScanning = true;
                          });
                          
                          // Close the scanner dialog first
                          Navigator.of(context).pop();
                          
                          // Add barcode and show feedback
                          if (!_barcodes.contains(scannedValue)) {
                            setState(() {
                              _barcodes.add(scannedValue);
                              _isScanning = false; // Reset after successful addition
                            });
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Barcode "$scannedValue" scanned and added successfully'),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          } else {
                            setState(() {
                              _isScanning = false; // Reset after duplicate detection
                            });
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('This barcode is already added'),
                                  backgroundColor: Colors.orange,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                          break;
                        }
                      }
                    },
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Point your camera at a barcode to scan',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarcodesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Barcodes',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF9B1B1B),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Barcode',
                controller: _barcodeController,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B1B1B),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _addBarcode,
              child: const Icon(
                Icons.add,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _scanBarcode,
              child: const Icon(
                Icons.qr_code_scanner,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_barcodes.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No barcodes added yet. Use the scanner or add manually.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _barcodes.map((barcode) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF9B1B1B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF9B1B1B).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code,
                    size: 16,
                    color: const Color(0xFF9B1B1B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    barcode,
                    style: const TextStyle(
                      color: Color(0xFF9B1B1B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _barcodes.remove(barcode);
                      });
                    },
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Color(0xFF9B1B1B),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
      ],
    );
  }

  void _addUnit() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Unit',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                label: 'Unit Name (e.g., KG, G)',
                controller: _unitNameController,
                validator: (value) => value?.isEmpty == true ? 'Unit name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Unit Value',
                controller: _unitValueController,
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty == true ? 'Unit value is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Unit Rate',
                controller: _unitRateController,
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty == true ? 'Unit rate is required' : null,
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
                      onPressed: () {
                        _unitNameController.clear();
                        _unitValueController.clear();
                        _unitRateController.clear();
                        Navigator.pop(context);
                      },
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
                      onPressed: () {
                        if (_unitNameController.text.isNotEmpty &&
                            _unitValueController.text.isNotEmpty &&
                            _unitRateController.text.isNotEmpty) {
                          setState(() {
                            _productUnits.add(
                              ProductUnit(
                                unitName: _unitNameController.text,
                                unitValue: _unitValueController.text,
                                unitRate: _unitRateController.text,
                              ),
                            );
                          });
                          _unitNameController.clear();
                          _unitValueController.clear();
                          _unitRateController.clear();
                          Navigator.pop(context);
                        }
                      },
                      child: const Text(
                        'Add',
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
  }

  Widget _buildUnitsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Product Units',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9B1B1B),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: const Color(0xFF9B1B1B),
              onPressed: _addUnit,
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_productUnits.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No units added yet. Click the + button to add units.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _productUnits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final unit = _productUnits[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            unit.unitName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Value: ${unit.unitValue}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rate: Rs. ${unit.unitRate}',
                            style: const TextStyle(
                              color: Color(0xFF9B1B1B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      onPressed: () {
                        setState(() {
                          _productUnits.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_productUnits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one unit for the product'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_prodImage1 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one product image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Map product units to match API format
      final List<Map<String, dynamic>> formattedUnits = _productUnits.map((unit) => {
        'unitName': unit.unitName,
        'unitValue': double.tryParse(unit.unitValue) ?? 0,
        'unitRate': double.tryParse(unit.unitRate) ?? 0,
      }).toList();

      final productData = {
        'prodSubCatId': _selectedSubCategoryId,
        'prodName': _nameController.text.trim(),
        'prodCode': _codeController.text.trim(),
        'prodDesc': _descController.text.trim(),
        'prodMrp': double.tryParse(_mrpController.text) ?? 0.0,
        'prodSp': double.tryParse(_spController.text) ?? 0.0,
        'prodReorderLevel': int.tryParse(_reorderLevelController.text) ?? 0,
        'prodQoh': int.tryParse(_qohController.text) ?? 0,
        'prodHsnCode': _hsnCodeController.text.trim(),
        'prodCgst': double.tryParse(_cgstController.text) ?? 0.0,
        'prodIgst': double.tryParse(_igstController.text) ?? 0.0,
        'prodSgst': double.tryParse(_sgstController.text) ?? 0.0,
        'prodMfgDate': _mfgDateController.text.isEmpty ? null : _mfgDateController.text,
        'prodExpiryDate': _expiryDateController.text.isEmpty ? null : _expiryDateController.text,
        'prodMfgBy': _mfgByController.text.trim(),
        'prodCatId': _selectedCategoryId,
        'isBarcodeAvailable': _isBarcodeAvailable,
        'productUnits': jsonEncode(formattedUnits),
        'barcodes': jsonEncode(_barcodes),
      };

      // Create files map
      final Map<String, File> files = {};
      if (_prodImage1 != null) files['prodImage1'] = _prodImage1!;
      if (_prodImage2 != null) files['prodImage2'] = _prodImage2!;
      if (_prodImage3 != null) files['prodImage3'] = _prodImage3!;

      // Debug print the request payload
      print('Sending product data to API:');
      print(productData);
      print('Files: ${files.keys.toList()}');

      final result = await _productService.addProductWithImages(productData, files);
      print('API Response:');
      print(result);
      
      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Product added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to add product'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('Error adding product:');
      print(e);
      print('Stack trace:');
      print(stackTrace);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descController.dispose();
    _mrpController.dispose();
    _spController.dispose();
    _reorderLevelController.dispose();
    _qohController.dispose();
    _hsnCodeController.dispose();
    _cgstController.dispose();
    _igstController.dispose();
    _sgstController.dispose();
    _mfgDateController.dispose();
    _expiryDateController.dispose();
    _mfgByController.dispose();
    _unitNameController.dispose();
    _unitValueController.dispose();
    _unitRateController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            maxLines: maxLines,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            validator: validator,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add New Product',
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
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCategories,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Basic Information Section
                          const Text(
                            'Basic Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B1B1B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Product Name *',
                            controller: _nameController,
                            validator: (value) => value?.isEmpty == true ? 'Product name is required' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Product Code *',
                            controller: _codeController,
                            validator: (value) => value?.isEmpty == true ? 'Product code is required' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Description *',
                            controller: _descController,
                            maxLines: 3,
                            validator: (value) => value?.isEmpty == true ? 'Description is required' : null,
                          ),
                          const SizedBox(height: 24),

                          // Category Section
                          const Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B1B1B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            value: _selectedCategoryId,
                            decoration: InputDecoration(
                              labelText: 'Category *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            items: _categories.map((category) {
                              try {
                                final id = category['CATEGORY_ID'];
                                final name = category['CATEGORY_NAME'];
                                
                                // Ensure proper type conversion
                                final intId = id is int ? id : int.tryParse(id.toString()) ?? 0;
                                final stringName = name?.toString() ?? 'Unknown';
                                
                                return DropdownMenuItem<int>(
                                  value: intId,
                                  child: Text(stringName),
                                );
                              } catch (e) {
                                print('Error creating category dropdown item: $e for $category');
                                return DropdownMenuItem<int>(
                                  value: 0,
                                  child: Text('Error: ${category.toString()}'),
                                );
                              }
                            }).toList(),
                            onChanged: (value) async {
                              if (value != null) {
                                setState(() {
                                  _selectedCategoryId = value;
                                  _selectedSubCategoryId = null;
                                });
                                await _loadSubCategories(value);
                              }
                            },
                            validator: (value) => value == null ? 'Category is required' : null,
                          ),
                          const SizedBox(height: 16),
                          if (_isLoadingSubCategories)
                            const Center(child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: CircularProgressIndicator(),
                            ))
                          else if (_subCategoriesError != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                _subCategoriesError!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                          else
                            DropdownButtonFormField<int>(
                              value: _selectedSubCategoryId,
                              decoration: InputDecoration(
                                labelText: 'Sub Category *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                enabled: _selectedCategoryId != null,
                              ),
                              items: _subCategories.map((subCategory) {
                                print('Creating dropdown item for subcategory: $subCategory');
                                try {
                                  final id = subCategory['SUB_CATEGORY_ID'];
                                  final name = subCategory['SUB_CATEGORY_NAME'];
                                  
                                  // Ensure proper type conversion
                                  final intId = id is int ? id : int.tryParse(id.toString()) ?? 0;
                                  final stringName = name?.toString() ?? 'Unknown';
                                  
                                  print('Subcategory ID: $intId (${intId.runtimeType}), Name: $stringName');
                                  
                                  return DropdownMenuItem<int>(
                                    value: intId,
                                    child: Text(stringName),
                                  );
                                } catch (e) {
                                  print('Error creating dropdown item: $e for $subCategory');
                                  return DropdownMenuItem<int>(
                                    value: 0,
                                    child: Text('Error: ${subCategory.toString()}'),
                                  );
                                }
                              }).toList(),
                              onChanged: _selectedCategoryId == null ? null : (int? value) {
                                print('Selected subcategory ID: $value');
                                if (value != null) {
                                  setState(() {
                                    _selectedSubCategoryId = value;
                                  });
                                }
                              },
                              validator: (value) => value == null ? 'Sub Category is required' : null,
                            ),
                          const SizedBox(height: 24),

                          // Pricing Section
                          const Text(
                            'Pricing',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B1B1B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: 'MRP *',
                                  controller: _mrpController,
                                  keyboardType: TextInputType.number,
                                  validator: (value) => value?.isEmpty == true ? 'MRP is required' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  label: 'Selling Price *',
                                  controller: _spController,
                                  keyboardType: TextInputType.number,
                                  validator: (value) => value?.isEmpty == true ? 'Selling price is required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Inventory Section
                          const Text(
                            'Inventory',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B1B1B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: 'Quantity on Hand',
                                  controller: _qohController,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  label: 'Reorder Level',
                                  controller: _reorderLevelController,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Tax Information Section
                          const Text(
                            'Tax Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B1B1B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'HSN Code',
                            controller: _hsnCodeController,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: 'CGST (%)',
                                  controller: _cgstController,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  label: 'SGST (%)',
                                  controller: _sgstController,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'IGST (%)',
                            controller: _igstController,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 24),

                          // Manufacturing Details Section
                          const Text(
                            'Manufacturing Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B1B1B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: 'Manufactured By',
                            controller: _mfgByController,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  label: 'Manufacturing Date',
                                  controller: _mfgDateController,
                                  readOnly: true,
                                  onTap: () => _selectDate(_mfgDateController),
                                  suffixIcon: const Icon(Icons.calendar_today),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  label: 'Expiry Date',
                                  controller: _expiryDateController,
                                  readOnly: true,
                                  onTap: () => _selectDate(_expiryDateController),
                                  suffixIcon: const Icon(Icons.calendar_today),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Product Images Section
                          const Text(
                            'Product Images',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B1B1B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildImagePicker('Product Image 1', _prodImage1, 1, required: true),
                          const SizedBox(height: 16),
                          _buildImagePicker('Product Image 2', _prodImage2, 2),
                          const SizedBox(height: 16),
                          _buildImagePicker('Product Image 3', _prodImage3, 3),
                          const SizedBox(height: 24),

                          // Barcode Section
                          const Text(
                            'Barcode',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B1B1B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown<String>(
                            label: 'Barcode Available',
                            value: _isBarcodeAvailable,
                            items: const [
                              DropdownMenuItem(value: 'Y', child: Text('Yes')),
                              DropdownMenuItem(value: 'N', child: Text('No')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _isBarcodeAvailable = value ?? 'N';
                              });
                            },
                          ),
                          const SizedBox(height: 24),

                          // Barcodes Section
                          _buildBarcodesSection(),
                          const SizedBox(height: 24),

                          // Product Units Section
                          _buildUnitsList(),
                          const SizedBox(height: 32),

                          // Submit Button
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
                              onPressed: _isSubmitting ? null : _handleSubmit,
                              child: _isSubmitting
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'Add Product',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
} 