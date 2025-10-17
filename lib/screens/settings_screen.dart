import 'package:flutter/material.dart';
import '../controllers/theme_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/user_profile.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserProfile? _userProfile;
  bool _isLoadingProfile = true;

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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    String? errorMessage;
    String? successMessage;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final theme = Theme.of(context);
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.lock_outline,
                            color: theme.colorScheme.onPrimaryContainer,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your current password and choose a new one',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Form
                    Form(
                      key: formKey,
                      child: Column(
                        children: [
                          // Current Password Field
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                            ),
                            child: TextFormField(
                              controller: currentPasswordController,
                              obscureText: obscureCurrentPassword,
                              onChanged: (value) {
                                if (errorMessage != null) {
                                  setModalState(() {
                                    errorMessage = null;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Current Password',
                                labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.onSurfaceVariant),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureCurrentPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    setModalState(() {
                                      obscureCurrentPassword = !obscureCurrentPassword;
                                    });
                                  },
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your current password';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // New Password Field
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                            ),
                            child: TextFormField(
                              controller: newPasswordController,
                              obscureText: obscureNewPassword,
                              onChanged: (value) {
                                if (errorMessage != null) {
                                  setModalState(() {
                                    errorMessage = null;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'New Password',
                                labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.onSurfaceVariant),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureNewPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    setModalState(() {
                                      obscureNewPassword = !obscureNewPassword;
                                    });
                                  },
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a new password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Confirm Password Field
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                            ),
                            child: TextFormField(
                              controller: confirmPasswordController,
                              obscureText: obscureConfirmPassword,
                              onChanged: (value) {
                                if (errorMessage != null) {
                                  setModalState(() {
                                    errorMessage = null;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Confirm New Password',
                                labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.onSurfaceVariant),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    setModalState(() {
                                      obscureConfirmPassword = !obscureConfirmPassword;
                                    });
                                  },
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your new password';
                                }
                                if (value != newPasswordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Error message
                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.onErrorContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: TextStyle(
                                  color: theme.colorScheme.onErrorContainer,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setModalState(() {
                                  errorMessage = null;
                                });
                              },
                              icon: Icon(
                                Icons.close,
                                color: theme.colorScheme.onErrorContainer,
                                size: 18,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Success message
                    if (successMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: theme.colorScheme.onPrimaryContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                successMessage!,
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Loading indicator
                    if (isLoading) ...[
                      Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Updating password...',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading ? null : () {
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: theme.colorScheme.outline),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : () async {
                              if (formKey.currentState!.validate()) {
                                setModalState(() {
                                  isLoading = true;
                                  errorMessage = null;
                                  successMessage = null;
                                });

                                // Capture context before async operation
                                final navigator = Navigator.of(context);

                                try {
                                  await AuthController.instance.changePassword(
                                    currentPassword: currentPasswordController.text,
                                    newPassword: newPasswordController.text,
                                  );

                                  if (mounted) {
                                    setModalState(() {
                                      isLoading = false;
                                      successMessage = 'Password changed successfully!';
                                    });
                                    
                                    // Auto-close modal after 2 seconds
                                    Future.delayed(const Duration(seconds: 2), () {
                                      if (mounted) {
                                        navigator.pop();
                                      }
                                    });
                                  }
                                } catch (e) {
                                  setModalState(() {
                                    isLoading = false;
                                    errorMessage = e.toString().replaceFirst('Exception: ', '');
                                  });
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Change Password',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _buildSectionHeader('Account'),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: CircleAvatar(
                    child: _isLoadingProfile
                        ? const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : _userProfile?.fullImageUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  _userProfile!.fullImageUrl!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.person_outline);
                                  },
                                ),
                              )
                            : const Icon(Icons.person_outline),
                  ),
                  title: Text(
                    _isLoadingProfile
                        ? 'Loading...'
                        : _userProfile?.displayName ?? 
                          AuthController.instance.currentUser?.email?.split('@')[0] ?? 
                          'User',
                  ),
                  subtitle: Text(
                    _isLoadingProfile
                        ? 'Loading...'
                        : _userProfile?.email ?? 
                          AuthController.instance.currentUser?.email ?? 
                          'No email',
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );
                      // Refresh profile data when returning from edit screen
                      if (result == true) {
                        _loadUserProfile();
                      }
                    },
                    child: const Text('Edit'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change password'),
                  onTap: _showChangePasswordDialog,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _buildSectionHeader('Preferences'),
          Card(
            child: Column(
              children: <Widget>[
                SwitchListTile(
                  value: ThemeController.instance.themeMode == ThemeMode.dark,
                  onChanged: (bool value) {
                    ThemeController.instance.toggleDarkMode(value);
                    setState(() {});
                  },
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark mode'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _buildSectionHeader('About'),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('App version'),
                  subtitle: const Text('1.0.0 (demo)'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Service'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Terms tapped (demo)')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy tapped (demo)')),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () async {
                // Capture context before async operation
                final navigator = Navigator.of(context);
                await AuthController.instance.signOut();
                if (!mounted) return;
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}


