import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../buyer/become_seller_screen.dart';
import '../../services/buyer_service.dart';
import '../../widgets/common/custom_list_tile.dart';
import '../../routes.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  File? _photoFile;
  String? _existingPhotoUrl;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  MerchUser? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final user = await ref.read(buyerServiceProvider).getCurrentUser();
      if (mounted) {
        setState(() {
          _user = user;
          _nameController.text = user.name ?? '';
          _emailController.text = user.email;
          _phoneController.text = user.phone ?? '';
          _existingPhotoUrl = user.photoUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _photoFile = File(image.path));
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      String? photoUrl = _existingPhotoUrl;

      // Upload new photo if selected
      if (_photoFile != null) {
        final urls = await ref.read(storageServiceProvider).uploadFiles(
          [_photoFile!],
          'users/photos',
        );
        photoUrl = urls.first;
      }

      final updatedUser = _user!.copyWith(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        photoUrl: photoUrl,
      );
      
      await ref.read(buyerServiceProvider).updateProfile(updatedUser);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      );
    }

    if (_user == null) {
      return const Center(child: Text('Error loading profile'));
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.pink,
                      backgroundImage: _user?.photoUrl != null
                          ? NetworkImage(_user!.photoUrl!)
                          : null,
                      child: _user?.photoUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _user!.name ?? 'No name set',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user!.email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Account Settings Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Account Settings',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            CustomListTile(
              leading: const Icon(Icons.person_outline),
              title: 'Edit Profile',
              onTap: () async {
                await Navigator.pushNamed(context, Routes.editProfile);
                _loadUser(); // Refresh profile after returning
              },
            ),
            CustomListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: 'Shipping Address',
              subtitle: Text(
                _user?.address != null && _user?.city != null
                    ? '${_user?.address}, ${_user?.city}${_user?.state != null ? ', ${_user?.state}' : ''}${_user?.country != null ? ', ${_user?.country}' : ''}${_user?.zip != null ? ' ${_user?.zip}' : ''}'
                    : 'No shipping address set',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            CustomListTile(
              leading: const Icon(Icons.store_outlined),
              title: 'Become a Seller',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BecomeSellerScreen(),
                  ),
                );
              },
            ),

            // App Settings Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'App Settings',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            CustomListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: 'Notifications',
              onTap: () {
                Navigator.pushNamed(context, Routes.notificationsSettings);
              },
            ),

            // Legal Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Legal',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            CustomListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: 'Privacy Policy',
              onTap: () {
                Navigator.pushNamed(context, Routes.privacyPolicy);
              },
            ),
            CustomListTile(
              leading: const Icon(Icons.description_outlined),
              title: 'Terms & Conditions',
              onTap: () {
                Navigator.pushNamed(context, Routes.termsConditions);
              },
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            'Logout',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await ref.read(authServiceProvider).signOut();
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        Routes.login,
                        (route) => false,
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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