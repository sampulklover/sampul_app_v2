import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/theme_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/user_profile.dart';
import 'login_screen.dart';
import 'onboarding_flow_screen.dart';
import '../services/supabase_service.dart';
import '../services/verification_service.dart';
import '../config/didit_config.dart';
import 'edit_profile_screen.dart';
import 'billing_screen.dart';
import 'referral_dashboard_screen.dart';
import 'admin_ai_settings_screen.dart';
import '../utils/admin_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with WidgetsBindingObserver {
  UserProfile? _userProfile;
  bool _isLoadingProfile = true;
  bool _isVerified = false;
  String? _verificationStatus;
  bool _isLoadingVerification = true;
  bool _isAdmin = false;
  bool _isLoadingAdmin = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserProfile();
    _loadVerificationStatus();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await AdminUtils.isAdmin();
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _isLoadingAdmin = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _isLoadingAdmin = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh verification status when app comes back to foreground
    // This handles the case when user returns from Didit verification
    if (state == AppLifecycleState.resumed) {
      _loadVerificationStatus();
    }
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

  Future<void> _loadVerificationStatus() async {
    try {
      final isVerified = await VerificationService.instance.isUserVerified();
      final status = await VerificationService.instance.getUserVerificationStatus();
      if (mounted) {
        setState(() {
          _isVerified = isVerified;
          _verificationStatus = status;
          _isLoadingVerification = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingVerification = false;
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
                                prefixIcon: Icon(Icons.lock_outline, color: const Color.fromRGBO(83, 61, 233, 1)),
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
                                prefixIcon: Icon(Icons.lock_outline, color: const Color.fromRGBO(83, 61, 233, 1)),
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
                                prefixIcon: Icon(Icons.lock_outline, color: const Color.fromRGBO(83, 61, 233, 1)),
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
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            _loadUserProfile(),
            _loadVerificationStatus(),
          ]);
        },
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _buildSectionHeader('Account'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
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
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                    _isLoadingProfile
                        ? 'Loading...'
                        : _userProfile?.displayName ?? 
                          AuthController.instance.currentUser?.email?.split('@')[0] ?? 
                          'User',
                        ),
                      ),
                    ],
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
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    _isVerified ? Icons.verified_user : Icons.verified_user_outlined,
                    color: _isVerified 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  title: const Text('Identity Verification'),
                  subtitle: Text(
                    _isLoadingVerification
                        ? 'Checking status...'
                        : _isVerified
                            ? 'Your identity is verified'
                            : _verificationStatus == 'pending'
                                ? 'Verification in progress'
                                : _verificationStatus == 'declined'
                                    ? 'Verification was declined'
                                    : _verificationStatus == 'rejected'
                                        ? 'Verification was rejected'
                                        : 'Verify your identity',
                  ),
                  trailing: _isLoadingVerification
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _isVerified
                          ? _buildVerificationBadge()
                          : _buildVerificationBadge() ?? Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                  onTap: _isVerified 
                      ? null 
                      : _handleVerification,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _buildSectionHeader('Billing'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.credit_card_outlined),
                  title: const Text('Plans & subscription'),
                  subtitle: const Text('Manage your Sampul plan'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BillingScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _buildSectionHeader('Preferences'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.card_giftcard_outlined),
                  title: const Text('Referrals'),
                  subtitle: const Text('Your code and referrals'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const ReferralDashboardScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                // Admin AI Settings (only visible to admins)
                if (!_isLoadingAdmin && _isAdmin) ...[
                  ListTile(
                    leading: const Icon(Icons.smart_toy_outlined),
                    title: const Text('AI Chat Settings'),
                    subtitle: const Text('Manage Sampul AI responses'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminAiSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                ],
                SwitchListTile(
                  value: ThemeController.instance.themeMode == ThemeMode.dark,
                  onChanged: (bool value) {
                    ThemeController.instance.toggleDarkMode(value);
                    setState(() {});
                  },
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark mode'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.replay_outlined),
                  title: const Text('Restart onboarding'),
                  subtitle: const Text('Run the setup flow again'),
                  onTap: () async {
                    try {
                      final user = AuthController.instance.currentUser;
                      if (user == null) {
                        throw Exception('You must be signed in');
                      }

                      // Update profiles.isOnboard to false
                      await SupabaseService.instance.client
                          .from('profiles')
                          .update(<String, dynamic>{'isOnboard': false})
                          .eq('uuid', user.id);

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Onboarding has been reset')),
                      );

                      // Launch onboarding flow screen
                      // Using push to allow user to complete and return
                      await Navigator.of(context).push(
                        MaterialPageRoute<bool>(
                          builder: (_) => const OnboardingFlowScreen(),
                          fullscreenDialog: true,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to reset onboarding: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _buildSectionHeader('About'),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
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
      ),
    );
  }

  Widget? _buildVerificationBadge() {
    if (_isLoadingVerification) {
      return null;
    }

    final theme = Theme.of(context);
    
    // Show badge based on kyc_status from accounts table
    if (_isVerified) {
      // approved or accepted
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 16,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              'Verified',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      );
    } else if (_verificationStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pending,
              size: 16,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              'Pending',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      );
    } else if (_verificationStatus == 'declined' || _verificationStatus == 'rejected') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cancel,
              size: 16,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 4),
            Text(
              _verificationStatus == 'declined' ? 'Declined' : 'Rejected',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      );
    }
    return null;
  }

  Future<void> _handleVerification() async {
    print('🔵 [VERIFICATION] Button clicked - Showing info modal');
    
    // Check configuration first
    if (!DiditConfig.isConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Didit is not configured. Please set DIDIT_CLIENT_ID (API key) and DIDIT_WORKFLOW_ID in your .env file.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show informational modal first
    final shouldProceed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VerificationInfoModal(
        onStart: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    if (shouldProceed != true) {
      print('🔵 [VERIFICATION] User cancelled');
      return;
    }

    // User clicked "Start Verification", proceed with API call
    await _startVerificationProcess();
  }

  Future<void> _startVerificationProcess() async {
    final theme = Theme.of(context);
    
    print('🔵 [VERIFICATION] Starting verification process...');
    
    // Check configuration
    final configStatus = VerificationService.instance.getConfigurationStatus();
    print('🔵 [VERIFICATION] Configuration status: $configStatus');
    
    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Creating verification session...',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      print('🔵 [VERIFICATION] Getting user profile data...');
      // Get user profile data to pre-fill
      final profile = _userProfile;
      
      Map<String, dynamic>? userData;
      if (profile != null) {
        userData = {
          'email': profile.email,
          if (profile.nricName != null) 'name': profile.nricName,
          if (profile.phoneNo != null) 'phone': profile.phoneNo,
        };
        print('🔵 [VERIFICATION] User data prepared: $userData');
      } else {
        print('🔵 [VERIFICATION] No user profile available');
      }

      print('🔵 [VERIFICATION] Calling createVerificationSession...');
      // Create verification session
      final result = await VerificationService.instance.createVerificationSession(
        userData: userData,
      );

      print('🔵 [VERIFICATION] Session created successfully!');
      print('🔵 [VERIFICATION] Result: $result');
      
      final String verificationUrl = result['url'] as String;
      print('🔵 [VERIFICATION] Verification URL: $verificationUrl');

      if (!mounted) {
        print('🔵 [VERIFICATION] Widget not mounted, returning');
        return;
      }
      
      print('🔵 [VERIFICATION] Closing loading dialog');
      Navigator.of(context).pop(); // Close loading dialog

      print('🔵 [VERIFICATION] Opening verification URL');
      // Open verification URL directly
      final uri = Uri.parse(verificationUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // Refresh verification status when user returns from Didit
        // This will be handled by didChangeAppLifecycleState
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open verification link'),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('🔴 [VERIFICATION] ERROR occurred!');
      print('🔴 [VERIFICATION] Error: $e');
      print('🔴 [VERIFICATION] Stack trace: $stackTrace');
      
      if (!mounted) {
        print('🔴 [VERIFICATION] Widget not mounted, cannot show error');
        return;
      }
      
      print('🔴 [VERIFICATION] Closing loading dialog');
      Navigator.of(context).pop(); // Close loading dialog
      
      print('🔴 [VERIFICATION] Showing error message to user');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start verification: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
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

/// Verification Info Modal
/// Shows information about identity verification before starting the process
class _VerificationInfoModal extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onCancel;

  const _VerificationInfoModal({
    required this.onStart,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.verified_user,
                        size: 64,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Main text
                    Text(
                      'Identity verification is required to establish trust and ensure the legal validity of your will.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Key points
                    _buildRequirementItem(
                      context,
                      theme,
                      Icons.gavel,
                      'Legal Validity',
                      'Establishes the legal validity of your will',
                    ),
                    const SizedBox(height: 12),
                    _buildRequirementItem(
                      context,
                      theme,
                      Icons.handshake,
                      'Builds Trust',
                      'Provides assurance to beneficiaries and executors',
                    ),
                    const SizedBox(height: 12),
                    _buildRequirementItem(
                      context,
                      theme,
                      Icons.verified,
                      'Regulatory Compliance',
                      'Ensures compliance with regulatory requirements',
                    ),
                    const SizedBox(height: 12),
                    _buildRequirementItem(
                      context,
                      theme,
                      Icons.shield,
                      'Fraud Protection',
                      'Protects against fraud and identity theft',
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Privacy note
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Your information is encrypted and secure',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: onStart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Start Verification',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementItem(
    BuildContext context,
    ThemeData theme,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


