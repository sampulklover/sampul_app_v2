import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';
import '../config/trust_constants.dart';
import '../controllers/auth_controller.dart';
import '../models/user_profile.dart';
import '../services/image_upload_service.dart';
import '../utils/form_decoration_helper.dart';
import '../utils/card_decoration_helper.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nricNameController = TextEditingController();
  final _phoneNoController = TextEditingController();
  final _emailController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postcodeController = TextEditingController();
  String? _selectedGender;
  String? _selectedCountry;
  
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  bool _isUploadingImage = false;
  UserProfile? _userProfile;
  String? _imagePath;
  File? _selectedImage;
  final ImageUploadService _imageUploadService = ImageUploadService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await AuthController.instance.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoadingProfile = false;
        });
        _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  void _loadUserData() {
    if (_userProfile != null) {
      _usernameController.text = _userProfile!.username ?? '';
      _nricNameController.text = _userProfile!.nricName ?? '';
      _phoneNoController.text = _userProfile!.phoneNo ?? '';
      _emailController.text = _userProfile!.email;
      _address1Controller.text = _userProfile!.address1 ?? '';
      _address2Controller.text = _userProfile!.address2 ?? '';
      _cityController.text = _userProfile!.city ?? '';
      _stateController.text = _userProfile!.state ?? '';
      _postcodeController.text = _userProfile!.postcode ?? '';
      _imagePath = _userProfile!.imagePath;
      _selectedGender = _userProfile!.gender;
      _selectedCountry = _userProfile!.country;
    } else {
      // Fallback to auth user data
      final user = AuthController.instance.currentUser;
      if (user != null) {
        _emailController.text = user.email ?? '';
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nricNameController.dispose();
    _phoneNoController.dispose();
    _emailController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      // Show image source selection dialog
      final ImageSource? source = await _showImageSourceDialog();
      if (source == null) return;

      // Pick image
      final File? imageFile = await _imageUploadService.pickImage(source: source);
      if (imageFile == null) return;

      // Validate image
      if (!_imageUploadService.validateImage(imageFile)) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.invalidImage),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isUploadingImage = true);

      // Get current user ID
      final user = AuthController.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      // Upload image
      final uploadedPath = await _imageUploadService.uploadProfileImage(
        imageFile: imageFile,
        userId: user.id,
      );

      // Update local state
      setState(() {
        _imagePath = uploadedPath;
        _selectedImage = imageFile;
        _isUploadingImage = false;
      });

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.imageUploadedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingImage = false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToUploadImage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.selectImageSource),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(l10n.camera),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l10n.gallery),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthController.instance.updateProfile(
        username: _usernameController.text.trim().isNotEmpty ? _usernameController.text.trim() : null,
        nricName: _nricNameController.text.trim().isNotEmpty ? _nricNameController.text.trim() : null,
        phoneNo: _phoneNoController.text.trim().isNotEmpty ? _phoneNoController.text.trim() : null,
        gender: _selectedGender,
        imagePath: _imagePath,
        address1: _address1Controller.text.trim().isNotEmpty ? _address1Controller.text.trim() : null,
        address2: _address2Controller.text.trim().isNotEmpty ? _address2Controller.text.trim() : null,
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        state: _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : null,
        postcode: _postcodeController.text.trim().isNotEmpty ? _postcodeController.text.trim() : null,
        country: _selectedCountry,
      );

      if (!mounted) return;
      
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.profileUpdatedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.of(context).pop(true); // Return true to indicate successful update
    } catch (e) {
      if (!mounted) return;
      
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToUpdateProfile(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoadingProfile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.editProfile),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfile),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Picture Section
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        child: _isUploadingImage
                            ? const SizedBox(
                                width: 120,
                                height: 120,
                                child: CircularProgressIndicator(),
                              )
                            : _selectedImage != null
                                ? ClipOval(
                                    child: Image.file(
                                      _selectedImage!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : _userProfile?.fullImageUrl != null
                                    ? ClipOval(
                                        child: Image.network(
                                          _userProfile!.fullImageUrl!,
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Colors.grey,
                                            );
                                          },
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: IconButton(
                            icon: _isUploadingImage
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.camera_alt, color: Colors.white),
                            onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                    icon: _isUploadingImage
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.photo_camera),
                    label: Text(_isUploadingImage ? l10n.uploading : l10n.changePhoto),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Form Fields
            CardDecorationHelper.styledCardWithTitle(
              context: context,
              title: l10n.personalInformation,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: FormDecorationHelper.roundedInputDecoration(
                      context: context,
                      labelText: l10n.username,
                      hintText: l10n.enterYourUsername,
                      prefixIcon: Icons.person_outline,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _nricNameController,
                    decoration: FormDecorationHelper.roundedInputDecoration(
                      context: context,
                      labelText: l10n.fullNameNric,
                      hintText: l10n.enterYourFullNameAsPerNric,
                      prefixIcon: Icons.badge_outlined,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _phoneNoController,
                    decoration: FormDecorationHelper.roundedInputDecoration(
                      context: context,
                      labelText: l10n.phoneNumber,
                      hintText: l10n.enterYourPhoneNumber,
                      prefixIcon: Icons.phone_outlined,
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_outlined),
                    decoration: FormDecorationHelper.roundedInputDecoration(
                      context: context,
                      labelText: l10n.gender,
                      prefixIcon: Icons.wc_outlined,
                    ),
                    items: TrustConstants.genders
                        .map(
                          (Map<String, String> item) => DropdownMenuItem<String>(
                            value: item['value'],
                            child: Text(item['name']!),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) => setState(() => _selectedGender = value),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _emailController,
                    decoration: FormDecorationHelper.roundedInputDecoration(
                      context: context,
                      labelText: l10n.email,
                      hintText: l10n.enterYourEmail,
                      prefixIcon: Icons.email_outlined,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: false, // Email cannot be changed
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  Text(
                    l10n.emailCannotBeChanged,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Address Information Card
            CardDecorationHelper.styledCardWithTitle(
              context: context,
              title: l10n.addressInformation,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    
                    TextFormField(
                      controller: _address1Controller,
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: l10n.addressLine1,
                        hintText: l10n.enterYourAddress,
                        prefixIcon: Icons.home_outlined,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _address2Controller,
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: l10n.addressLine2,
                        hintText: l10n.enterAdditionalAddressDetails,
                        prefixIcon: Icons.home_work_outlined,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _cityController,
                            decoration: FormDecorationHelper.roundedInputDecoration(
                              context: context,
                              labelText: l10n.city,
                              hintText: l10n.enterCity,
                              prefixIcon: Icons.location_city_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _stateController,
                            decoration: FormDecorationHelper.roundedInputDecoration(
                              context: context,
                              labelText: l10n.state,
                              hintText: l10n.enterState,
                              prefixIcon: Icons.map_outlined,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _postcodeController,
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: l10n.postcode,
                        hintText: l10n.enterPostcode,
                        prefixIcon: Icons.local_post_office_outlined,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedCountry,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_outlined),
                      decoration: FormDecorationHelper.roundedInputDecoration(
                        context: context,
                        labelText: l10n.country,
                        prefixIcon: Icons.public_outlined,
                      ),
                      items: TrustConstants.countries
                          .map(
                            (Map<String, String> item) => DropdownMenuItem<String>(
                              value: item['value'],
                              child: Text(item['name']!),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) => setState(() => _selectedCountry = value),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

}
