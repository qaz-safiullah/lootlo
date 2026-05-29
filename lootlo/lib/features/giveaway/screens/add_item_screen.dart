import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/item_service.dart';
import '../../../core/constants/api_constants.dart';

class AddItemScreen extends StatefulWidget {
  final Map<String, dynamic>? existingItem;

  const AddItemScreen({super.key, this.existingItem});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  bool get isEditMode => widget.existingItem != null;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  
  String _selectedCategory = AppConstants.categories[1]; 
  String _selectedCity = AppConstants.cities[0]; 
  
  final List<File?> _images = [null, null, null]; 
  final List<String?> _existingImages = [null, null, null]; 
  
  LatLng _pinLocation = const LatLng(24.8607, 67.0011); 
  bool _isLocationSelected = false;
  bool _isLoading = false;
  bool _isFetchingAddress = false; 
  bool _isMapLoading = false; 

  final ItemService _itemService = ItemService();
  final ImagePicker _picker = ImagePicker();
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    
    _titleController = TextEditingController(text: isEditMode ? widget.existingItem!['title'] : '');
    _descController = TextEditingController(text: isEditMode ? widget.existingItem!['description'] : '');
    _addressController = TextEditingController(text: isEditMode ? widget.existingItem!['address'] : '');
    _phoneController = TextEditingController(text: isEditMode ? widget.existingItem!['phone'] : '');

    if (isEditMode) {
      if (AppConstants.categories.contains(widget.existingItem!['category'])) {
        _selectedCategory = widget.existingItem!['category'];
      }
      if (AppConstants.cities.contains(widget.existingItem!['city'])) {
        _selectedCity = widget.existingItem!['city'];
      }
      _pinLocation = LatLng(
        double.tryParse(widget.existingItem!['lat'].toString()) ?? 24.8607,
        double.tryParse(widget.existingItem!['lng'].toString()) ?? 67.0011,
      );
      _isLocationSelected = true;

      // LOAD ALL IMAGES FROM THE NEW BACKEND ARRAY
      if (widget.existingItem!['images'] != null && widget.existingItem!['images'] is List) {
        List<dynamic> imgs = widget.existingItem!['images'];
        for (int i = 0; i < imgs.length && i < 3; i++) {
          _existingImages[i] = imgs[i].toString(); 
        }
      } else if (widget.existingItem!['main_image'] != null) {
        // Fallback just in case
        _existingImages[0] = widget.existingItem!['main_image']; 
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  String _parseImageUrl(String url) {
    if (url.startsWith('http')) return url;
    String cleanBase = ApiConstants.baseUrl.replaceAll('/api', '');
    String cleanPath = url.replaceAll('\\', '/');
    if (!cleanPath.startsWith('/')) cleanPath = '/$cleanPath';
    return '$cleanBase$cleanPath';
  }

  Future<void> _pickImage(int index, ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _images[index] = File(pickedFile.path);
        _existingImages[index] = null; // Replaces existing DB image if overwritten
      });
    }
  }

  Future<void> _fetchAddressFromCoordinates(double lat, double lng) async {
    setState(() => _isFetchingAddress = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String autoAddress = '';
        if (place.street != null && place.street!.isNotEmpty) autoAddress += '${place.street}, ';
        if (place.subLocality != null && place.subLocality!.isNotEmpty) autoAddress += '${place.subLocality}';
        
        setState(() {
          _addressController.text = autoAddress.trim().replaceAll(RegExp(r',$'), '');
        });
      }
    } catch (e) {
      _showToast('Could not fetch address text.', isError: true);
    } finally {
      setState(() => _isFetchingAddress = false);
    }
  }

  Future<void> _openOSMMapPicker() async {
    if (_isMapLoading) return; 
    setState(() => _isMapLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showToast('Please enable location services.', isError: true);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showToast('Location permission is required.', isError: true);
          return;
        }
      }
      
      if (!isEditMode && !_isLocationSelected) {
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
        _pinLocation = LatLng(position.latitude, position.longitude);
      }
    } catch (e) {
      debugPrint("Using default coordinates.");
    } finally {
      if (mounted) setState(() => _isMapLoading = false);
    }

    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              alignment: Alignment.center,
              child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10))),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Drag Map to Pin Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  IconButton(icon: Icon(CupertinoIcons.xmark_circle_fill, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 28), onPressed: () => Navigator.pop(context))
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(initialCenter: _pinLocation, initialZoom: 16.0),
                    children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.lootlo.app', keepBuffer: 3)],
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40.0), 
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(top: 35, child: Container(width: 15, height: 5, decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)]))),
                          const Icon(Icons.location_pin, color: AppColors.primary, size: 50),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
              child: ElevatedButton(
                onPressed: () {
                  LatLng finalLocation = _mapController.camera.center;
                  setState(() { _pinLocation = finalLocation; _isLocationSelected = true; });
                  Navigator.pop(context);
                  _fetchAddressFromCoordinates(finalLocation.latitude, finalLocation.longitude);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                child: const Text('Confirm Pickup Spot', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _submitItem() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!isEditMode && _images[0] == null) {
      _showToast('The Main Cover Image is required!', isError: true);
      return;
    }
    if (!_isLocationSelected) {
      _showToast('Please select a pickup point on the map!', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    bool success;
    
    // Sort our new files
    List<File> filesToUpload = _images.whereType<File>().toList();

    if (isEditMode) {
      // Gather the old DB paths that the user didn't hit 'Remove' on
      List<String> retained = [];
      for (var img in _existingImages) {
        if (img != null && img.isNotEmpty) {
          retained.add(img); 
        }
      }

      success = await _itemService.updateItem(
        itemId: widget.existingItem!['id'],
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _selectedCategory,
        city: _selectedCity,
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        retainedImages: retained,
        newImages: filesToUpload,
      );
    } else {
      success = await _itemService.createItem(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _selectedCategory,
        city: _selectedCity,
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        lat: _pinLocation.latitude,
        lng: _pinLocation.longitude,
        images: filesToUpload,
      );
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      _showToast(isEditMode ? 'Listing updated successfully!' : 'Giveaway published successfully! 🚀');
      Navigator.pop(context);
    } else if (mounted) {
      _showToast('Operation failed. Please try again.', isError: true);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)), backgroundColor: isError ? AppColors.error : AppColors.primary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: const EdgeInsets.all(16)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7F9FA),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(isEditMode ? 'Edit My Listing' : 'Give Away', style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black, letterSpacing: -0.5)),
        leading: IconButton(icon: Icon(CupertinoIcons.xmark, color: isDark ? Colors.white : Colors.black), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    children: [
                      // --- Photos Card ---
                      _buildSectionCard(
                        isDark: isDark,
                        title: 'Upload Photos',
                        icon: CupertinoIcons.photo_on_rectangle,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildImageBox(0, 'Main Cover\n(Required)', isDark, size: 100),
                            _buildImageBox(1, 'Extra 1\n(Optional)', isDark, size: 85),
                            _buildImageBox(2, 'Extra 2\n(Optional)', isDark, size: 85),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Details Card ---
                      _buildSectionCard(
                        isDark: isDark,
                        title: 'Listing Details',
                        icon: CupertinoIcons.doc_text,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _titleController,
                              validator: (val) => val!.isEmpty ? 'Enter a title' : null,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: _inputDecoration('Item Title', isDark, CupertinoIcons.tag),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              items: AppConstants.categories.where((c) => c != 'All').map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: isDark ? Colors.white : Colors.black)))).toList(),
                              onChanged: (val) => setState(() => _selectedCategory = val!),
                              dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                              decoration: _inputDecoration('Category', isDark, CupertinoIcons.square_grid_2x2),
                              icon: Icon(CupertinoIcons.chevron_down, color: AppColors.primary, size: 18),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _descController,
                              validator: (val) => val!.isEmpty ? 'Enter a description' : null,
                              maxLines: 4,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: _inputDecoration('Item Description / Condition', isDark, CupertinoIcons.info_circle),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              validator: (val) => val!.isEmpty ? 'Contact number is required' : null,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black),
                              decoration: _inputDecoration('Contact Phone Number', isDark, CupertinoIcons.phone),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Location Card ---
                      _buildSectionCard(
                        isDark: isDark,
                        title: 'Pickup Location',
                        icon: CupertinoIcons.location,
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: _selectedCity,
                              items: AppConstants.cities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: isDark ? Colors.white : Colors.black)))).toList(),
                              onChanged: (val) => setState(() => _selectedCity = val!),
                              dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                              decoration: _inputDecoration('City', isDark, CupertinoIcons.building_2_fill),
                              icon: Icon(CupertinoIcons.chevron_down, color: AppColors.primary, size: 18),
                            ),
                            const SizedBox(height: 16),

                            GestureDetector(
                              onTap: _openOSMMapPicker,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: _isLocationSelected ? AppColors.primary.withOpacity(0.1) : (isDark ? AppColors.surfaceDark : Colors.white), borderRadius: BorderRadius.circular(16), border: Border.all(color: _isLocationSelected ? AppColors.primary : (isDark ? Colors.grey[800]! : Colors.grey[300]!), width: _isLocationSelected ? 1.5 : 1)),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: _isLocationSelected ? AppColors.primary : (isDark ? Colors.grey[800] : Colors.grey[100]), borderRadius: BorderRadius.circular(12)),
                                      child: _isMapLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)) : Icon(CupertinoIcons.map_fill, color: _isLocationSelected ? Colors.white : AppColors.primary),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_isLocationSelected ? "Location Pinned" : "Pin Location on Map *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _isLocationSelected ? AppColors.primary : (isDark ? Colors.white : Colors.black87))),
                                          const SizedBox(height: 4),
                                          Text(_isLocationSelected ? "Lat: ${_pinLocation.latitude.toStringAsFixed(4)}, Lng: ${_pinLocation.longitude.toStringAsFixed(4)}" : "Tap to set precise pickup spot", style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : Colors.grey[600]))
                                        ],
                                      ),
                                    ),
                                    Icon(CupertinoIcons.chevron_right, color: isDark ? AppColors.textMutedDark : Colors.grey[400]),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            Stack(
                              alignment: Alignment.centerRight,
                              children: [
                                TextFormField(
                                  controller: _addressController,
                                  validator: (val) => val!.isEmpty ? 'Pickup address is required' : null,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                  decoration: _inputDecoration('Complete Street Address', isDark, CupertinoIcons.map_pin_ellipse),
                                ),
                                if (_isFetchingAddress)
                                  const Padding(padding: EdgeInsets.only(right: 16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40), 
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(color: isDark ? AppColors.backgroundDark : Colors.white, boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitItem,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 56), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) : Text(isEditMode ? 'SAVE CHANGES' : 'PUBLISH GIVEAWAY', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required bool isDark, required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildImageBox(int index, String label, bool isDark, {required double size}) {
    final bool hasNewFile = _images[index] != null;
    final bool hasNetworkImg = _existingImages[index] != null && _existingImages[index]!.isNotEmpty;
    final bool hasImage = hasNewFile || hasNetworkImg;

    return GestureDetector(
      onTap: () => _showImageSourceActionSheet(context, index),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: hasImage ? Colors.transparent : (isDark ? Colors.grey[900] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hasImage ? AppColors.primary : (index == 0 ? AppColors.primary.withOpacity(0.5) : (isDark ? Colors.grey[800]! : Colors.grey[300]!)), width: hasImage || index == 0 ? 2 : 1),
          image: hasNewFile
              ? DecorationImage(image: FileImage(_images[index]!), fit: BoxFit.cover)
              : hasNetworkImg 
                  ? DecorationImage(image: NetworkImage(_parseImageUrl(_existingImages[index]!)), fit: BoxFit.cover)
                  : null,
        ),
        child: hasImage
            ? Align(
                alignment: Alignment.bottomRight,
                child: Container(margin: const EdgeInsets.all(6), padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.edit, size: 14, color: Colors.white)),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.camera, color: index == 0 ? AppColors.primary : Colors.grey[500], size: size * 0.3),
                  const SizedBox(height: 6),
                  Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: index == 0 ? FontWeight.bold : FontWeight.w500, color: index == 0 ? AppColors.primary : Colors.grey[500])),
                ],
              ),
      ),
    );
  }

  void _showImageSourceActionSheet(BuildContext context, int index) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Choose Photo'),
        actions: [
          CupertinoActionSheetAction(onPressed: () { Navigator.pop(context); _pickImage(index, ImageSource.gallery); }, child: const Text('Choose from Gallery', style: TextStyle(color: AppColors.primary))),
          CupertinoActionSheetAction(onPressed: () { Navigator.pop(context); _pickImage(index, ImageSource.camera); }, child: const Text('Take a Photo', style: TextStyle(color: AppColors.primary))),
          if (_images[index] != null || _existingImages[index] != null) 
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () { Navigator.pop(context); setState(() { _images[index] = null; _existingImages[index] = null; }); },
              child: const Text('Remove Photo'),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(isDefaultAction: true, onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, bool isDark, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isDark ? AppColors.textMutedDark : Colors.grey[600], fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: isDark ? AppColors.textMutedDark : Colors.grey[500], size: 22),
      filled: true,
      fillColor: isDark ? Colors.grey[900] : const Color(0xFFF0F2F5),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
    );
  }
}