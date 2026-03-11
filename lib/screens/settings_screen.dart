import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';
import '../controllers/theme_controller.dart';
import '../controllers/locale_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/user_profile.dart';
import 'login_screen.dart';
import 'onboarding_flow_screen.dart';
import 'onboarding_goal_selection_screen.dart';
import '../services/supabase_service.dart';
import '../services/verification_service.dart';
import '../services/account_service.dart';
import '../config/didit_config.dart';
import 'edit_profile_screen.dart';
import 'referral_dashboard_screen.dart';
import 'admin_ai_settings_screen.dart';
import 'admin_learning_resources_screen.dart';
import '../utils/admin_utils.dart';
import '../services/image_upload_service.dart';
import '../utils/card_decoration_helper.dart';

enum _FeedbackType {
  bug,
  feature,
}

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
            final l10n = AppLocalizations.of(context)!;
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
                child: SingleChildScrollView(
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
                            l10n.changePasswordTitle,
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
                        l10n.enterCurrentPasswordAndChooseNew,
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
                                  labelText: l10n.currentPassword,
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
                                    return l10n.pleaseEnterCurrentPassword;
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
                                  labelText: l10n.newPassword,
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
                                    return l10n.pleaseEnterNewPassword;
                                  }
                                  if (value.length < 6) {
                                    return l10n.passwordMinLength;
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
                                  labelText: l10n.confirmNewPassword,
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
                                    return l10n.pleaseConfirmNewPassword;
                                  }
                                  if (value != newPasswordController.text) {
                                    return l10n.passwordsDoNotMatch;
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
                                l10n.updatingPassword,
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
                                l10n.cancel,
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
                                        successMessage = l10n.passwordChangedSuccessfully;
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
                                l10n.changePasswordTitle,
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
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showFeedbackSheet() async {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final feedbackController = TextEditingController();
    _FeedbackType selectedType = _FeedbackType.bug;
    bool isSending = false;
    String? errorMessage;
    File? screenshotFile;
    String? screenshotError;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.bug_report_outlined,
                            color: theme.colorScheme.onPrimaryContainer,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.sendFeedback,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.reportBugsOrRequestFeatures,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Bug report'),
                          selected: selectedType == _FeedbackType.bug,
                          onSelected: (selected) {
                            if (!selected) return;
                            setModalState(() {
                              selectedType = _FeedbackType.bug;
                              errorMessage = null;
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Feature request'),
                          selected: selectedType == _FeedbackType.feature,
                          onSelected: (selected) {
                            if (!selected) return;
                            setModalState(() {
                              selectedType = _FeedbackType.feature;
                              errorMessage = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      selectedType == _FeedbackType.bug
                          ? 'What went wrong?'
                          : 'What would you like Sampul to do?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: feedbackController,
                      maxLines: 5,
                      onChanged: (_) {
                        if (errorMessage != null) {
                          setModalState(() {
                            errorMessage = null;
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: selectedType == _FeedbackType.bug
                            ? 'Describe the issue, what you expected, and any steps to reproduce.'
                            : 'Describe your idea or feature request in as much detail as possible.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant.withValues(alpha: 0.2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: isSending
                          ? null
                          : () async {
                              try {
                                final file = await ImageUploadService().pickImage();
                                if (file == null) return;

                                if (!ImageUploadService().validateImage(file)) {
                                  setModalState(() {
                                    screenshotError = 'Please choose an image under 5MB (JPG, PNG, GIF, WEBP).';
                                    screenshotFile = null;
                                  });
                                  return;
                                }

                                setModalState(() {
                                  screenshotFile = file;
                                  screenshotError = null;
                                });
                              } catch (e) {
                                setModalState(() {
                                  screenshotError = 'Could not pick image: $e';
                                });
                              }
                            },
                      icon: Icon(
                        screenshotFile == null ? Icons.add_a_photo_outlined : Icons.edit_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      label: Text(
                        screenshotFile == null
                            ? 'Add screenshot (optional)'
                            : 'Change screenshot',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (screenshotError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        screenshotError!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (screenshotFile != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          screenshotFile!,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (errorMessage != null) ...[
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSending
                                ? null
                                : () {
                                    Navigator.of(context).pop();
                                  },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              l10n.cancel,
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
                            onPressed: isSending
                                ? null
                                : () async {
                                    if (feedbackController.text.trim().isEmpty) {
                                      setModalState(() {
                                        errorMessage = 'Please describe your ${selectedType == _FeedbackType.bug ? 'bug' : 'idea'} first.';
                                      });
                                      return;
                                    }

                                    setModalState(() {
                                      isSending = true;
                                      errorMessage = null;
                                    });

                                    final currentUser = AuthController.instance.currentUser;
                                    try {
                                      String? screenshotUrl;
                                      if (screenshotFile != null && currentUser?.id != null) {
                                        try {
                                          final storagePath = await ImageUploadService().uploadFeedbackImage(
                                            imageFile: screenshotFile!,
                                            userId: currentUser!.id,
                                          );
                                          screenshotUrl = ImageUploadService().getPublicUrl(storagePath);
                                        } catch (e) {
                                          // If upload fails, continue without screenshot but show a lightweight message
                                          if (mounted) {
                                            ScaffoldMessenger.of(this.context).showSnackBar(
                                              SnackBar(
                                                content: Text('Screenshot upload failed, but your feedback was sent: $e'),
                                              ),
                                            );
                                          }
                                        }
                                      }

                                      await SupabaseService.instance.client.from('feedback').insert(<String, dynamic>{
                                        'uuid': currentUser?.id,
                                        'email': currentUser?.email,
                                        'type': selectedType == _FeedbackType.bug ? 'bug' : 'feature',
                                        'description': feedbackController.text.trim(),
                                        if (screenshotUrl != null) 'screenshot_url': screenshotUrl,
                                      });

                                      if (mounted) {
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(this.context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Thank you for your feedback – we\'ve received it.'),
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setModalState(() {
                                          isSending = false;
                                        });
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: isSending
                                ? SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                                    ),
                                  )
                                : Text(
                                    'Submit feedback',
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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
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
          _buildSectionHeader(l10n.account),
          CardDecorationHelper.styledCard(
            context: context,
            padding: EdgeInsets.zero,
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
                        ? l10n.loading
                        : _userProfile?.displayName ?? 
                          AuthController.instance.currentUser?.email?.split('@')[0] ?? 
                          l10n.user,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    _isLoadingProfile
                        ? l10n.loading
                        : _userProfile?.email ?? 
                          AuthController.instance.currentUser?.email ?? 
                          l10n.noEmail,
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
                    child: Text(l10n.edit),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    _isVerified ? Icons.verified_user : Icons.verified_user_outlined,
                    color: _isVerified 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  title: Text(l10n.identityVerification),
                  subtitle: Text(
                    _isLoadingVerification
                        ? l10n.checkingStatus
                        : _isVerified
                            ? l10n.yourIdentityIsVerified
                            : _verificationStatus == 'pending'
                                ? l10n.verificationInProgress
                                : _verificationStatus == 'declined'
                                    ? l10n.verificationWasDeclined
                                    : _verificationStatus == 'rejected'
                                        ? l10n.verificationWasRejected
                                        : l10n.verifyYourIdentity,
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
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: Text(l10n.changePassword),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showChangePasswordDialog,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(l10n.logOut),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.logOut),
                      content: Text(l10n.areYouSureYouWantToLogOut),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(l10n.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(l10n.logOut),
                        ),
                      ],
                    ),
                  );

                  if (confirmed != true) return;

                  // Capture context before async operation
                  final navigator = Navigator.of(context);
                  await AuthController.instance.signOut();
                  if (!mounted) return;
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
                ),
              ],
            ),
          ),

          // Billing / subscription section temporarily hidden
          // To re-enable, restore the section header and card below.
          // const SizedBox(height: 16),
          // _buildSectionHeader(l10n.billing),
          // CardDecorationHelper.styledCard(
          //   context: context,
          //   padding: EdgeInsets.zero,
          //   child: Column(
          //     children: <Widget>[
          //       ListTile(
          //         leading: const Icon(Icons.credit_card_outlined),
          //         title: Text(l10n.plansAndSubscription),
          //         subtitle: Text(l10n.manageYourSampulPlan),
          //         trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          //         onTap: () {
          //           Navigator.of(context).push(
          //             MaterialPageRoute<void>(
          //               builder: (_) => const BillingScreen(),
          //             ),
          //           );
          //         },
          //       ),
          //     ],
          //   ),
          // ),

          const SizedBox(height: 16),
          _buildSectionHeader(l10n.preferences),
          CardDecorationHelper.styledCard(
            context: context,
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.card_giftcard_outlined),
                  title: Text(l10n.referrals),
                  subtitle: Text(l10n.yourCodeAndReferrals),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const ReferralDashboardScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                // Admin-only settings
                if (!_isLoadingAdmin && _isAdmin) ...[
                  ListTile(
                    leading: const Icon(Icons.smart_toy_outlined),
                    title: Text(l10n.aiChatSettings),
                    subtitle: Text(l10n.manageSampulAiResponses),
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
                  ListTile(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: const Text('Learning resources'),
                    subtitle: const Text('Manage podcasts and guides for Learn'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminLearningResourcesScreen(),
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
                  title: Text(l10n.darkMode),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: Text(AppLocalizations.of(context)!.language),
                  subtitle: Text(_getLanguageName(context)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showLanguageSelector(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.replay_outlined),
                  title: Text(l10n.restartOnboarding),
                  subtitle: Text(l10n.runTheSetupFlowAgain),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
                        SnackBar(content: Text(l10n.onboardingHasBeenReset)),
                      );

                      // Launch onboarding goal selection screen
                      // Using push to allow user to complete and return
                      await Navigator.of(context).push(
                        MaterialPageRoute<bool>(
                          builder: (_) => const OnboardingGoalSelectionScreen(),
                          fullscreenDialog: true,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.failedToResetOnboarding(e.toString())), backgroundColor: Colors.red),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _buildSectionHeader(l10n.about),
          CardDecorationHelper.styledCard(
            context: context,
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: Text(l10n.sendFeedback),
                  subtitle: Text(l10n.reportBugsOrRequestFeatures),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showFeedbackSheet,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.appVersion),
                  subtitle: Text(l10n.appVersionDemo),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(l10n.termsOfService),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.termsTappedDemo)),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(l10n.privacyPolicy),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.privacyTappedDemo)),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _showDeleteAccountDialog,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: Text(
                l10n.deleteAccount,
                style: const TextStyle(color: Colors.red),
              ),
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
              AppLocalizations.of(context)!.verified,
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
              AppLocalizations.of(context)!.pending,
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
              _verificationStatus == 'declined' ? AppLocalizations.of(context)!.declined : AppLocalizations.of(context)!.rejected,
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.diditNotConfigured),
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
        child: CardDecorationHelper.styledCard(
          context: context,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.creatingVerificationSession,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ],
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
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.couldNotOpenVerificationLink),
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
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.failedToStartVerification(e.toString().replaceFirst('Exception: ', ''))),
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

  Future<void> _showDeleteAccountDialog() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      final bool? shouldDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return const _DeleteAccountDialog();
        },
      );

      if (shouldDelete != true) {
        return;
      }

      final user = AuthController.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.noEmail),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show a simple loading dialog while deleting
      if (!mounted) return;
      final rootNavigator = Navigator.of(context, rootNavigator: true);
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    l10n.loading,
                  ),
                ),
              ],
            ),
          );
        },
      );

      try {
        // Call Supabase Edge Function to delete account (handles subscription checks etc.)
        await AccountService.instance.deleteAccount();

        // Sign out locally after successful deletion.
        // If this throws, we still want to take the user back to login.
        try {
          await AuthController.instance.signOut();
        } catch (_) {
          // Ignore sign-out errors here; session may already be invalidated.
        }

        // Always close loading dialog.
        rootNavigator.pop(); // Close loading dialog

        // Explicitly navigate to login screen and clear navigation stack.
        rootNavigator.pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } catch (e) {
        // Ensure loading dialog is closed even if this widget was unmounted.
        rootNavigator.pop(); // Close loading dialog

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open delete account dialog: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  String _getLanguageName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = LocaleController.instance.locale;
    if (currentLocale.languageCode == 'ms') {
      return l10n.malay;
    }
    return l10n.english;
  }

  Future<void> _showLanguageSelector(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = LocaleController.instance.locale;
    
    final selectedLanguage = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.selectLanguage,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                title: Text(l10n.english),
                value: 'en',
                groupValue: currentLocale.languageCode,
                onChanged: (String? value) {
                  if (value != null) {
                    Navigator.of(context).pop(value);
                  }
                },
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                title: Text(l10n.malay),
                value: 'ms',
                groupValue: currentLocale.languageCode,
                onChanged: (String? value) {
                  if (value != null) {
                    Navigator.of(context).pop(value);
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selectedLanguage != null && selectedLanguage != currentLocale.languageCode) {
      await LocaleController.instance.setLocale(Locale(selectedLanguage));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.languageChanged)),
        );
      }
      setState(() {}); // Refresh the UI to show updated language
    }
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
    final l10n = AppLocalizations.of(context)!;
    
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
                      l10n.identityVerificationRequired,
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
                      l10n.legalValidity,
                      l10n.establishesLegalValidity,
                    ),
                    const SizedBox(height: 12),
                    _buildRequirementItem(
                      context,
                      theme,
                      Icons.handshake,
                      l10n.buildsTrust,
                      l10n.providesAssurance,
                    ),
                    const SizedBox(height: 12),
                    _buildRequirementItem(
                      context,
                      theme,
                      Icons.verified,
                      l10n.regulatoryCompliance,
                      l10n.ensuresCompliance,
                    ),
                    const SizedBox(height: 12),
                    _buildRequirementItem(
                      context,
                      theme,
                      Icons.shield,
                      l10n.fraudProtection,
                      l10n.protectsAgainstFraud,
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
                          l10n.yourInformationIsEncrypted,
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
                        child: Text(l10n.cancel),
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
                        child: Text(
                          l10n.startVerification,
                          style: const TextStyle(
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

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  late final TextEditingController _confirmController;
  static const String _confirmText = 'DELETE';

  @override
  void initState() {
    super.initState();
    print('🔴 [DELETE ACCOUNT] Dialog State initState');
    _confirmController = TextEditingController();
    _confirmController.addListener(_onTextChanged);
    print('🔴 [DELETE ACCOUNT] Controller created and listener added');
  }

  @override
  void dispose() {
    _confirmController.removeListener(_onTextChanged);
    _confirmController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  bool get _isConfirmed {
    return _confirmController.text.trim() == _confirmText;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return AlertDialog(
      title: Text(l10n.deleteAccountTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.areYouSureDeleteAccount,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.toConfirmTypeDelete,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmController,
              decoration: InputDecoration(
                hintText: l10n.typeDeleteToConfirm,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _isConfirmed
              ? () {
                  Navigator.of(context).pop(true);
                }
              : null,
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: Text(l10n.delete),
        ),
      ],
    );
  }
}


