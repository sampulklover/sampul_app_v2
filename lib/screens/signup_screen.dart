import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import '../controllers/auth_controller.dart';
import '../utils/form_decoration_helper.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final FormState? form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final AuthResponse response = await AuthController.instance.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Print response.user to console for debugging
      print('Signup response.user: ${response.user}');
      print('Signup response.user.id: ${response.user?.id}');
      print('Signup response.user.email: ${response.user?.email}');
      print('Signup response.user.emailConfirmedAt: ${response.user?.emailConfirmedAt}');

      if (!mounted) return;

      if (response.user != null) {
        // Successfully signed up
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please check your email to verify your account.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to login screen
        Navigator.of(context).pop();
      } else {
        // Handle case where user is null
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign up failed. Please try again.')),
        );
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: ${error.message}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $error')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isGoogleSubmitting) return;
    setState(() {
      _isGoogleSubmitting = true;
    });

    try {
      final AuthResponse? response = await AuthController.instance.signInWithGoogle();

      if (!mounted) return;

      if (response?.user != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const MainShell()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in was cancelled or failed')),
        );
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: ${error.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isGoogleSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign up'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SvgPicture.asset('assets/sampul-icon-white.svg', width: 72, height: 72),
                  const SizedBox(height: 24),
                  Text(
                    'Create your account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign up to get started with Sampul',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: FormDecorationHelper.roundedInputDecoration(
                      context: context,
                      labelText: 'Full name',
                      prefixIcon: Icons.person_outline,
                    ),
                    validator: (String? value) {
                      final String v = (value ?? '').trim();
                      if (v.isEmpty) return 'Name is required';
                      if (v.length < 2) return 'Enter a valid name';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: FormDecorationHelper.roundedInputDecoration(
                      context: context,
                      labelText: 'Email',
                      hintText: 'you@example.com',
                      prefixIcon: Icons.email_outlined,
                    ),
                    validator: (String? value) {
                      final String v = (value ?? '').trim();
                      if (v.isEmpty) return 'Email is required';
                      final RegExp emailRegex = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@]+$");
                      if (!emailRegex.hasMatch(v)) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    textInputAction: TextInputAction.next,
                    decoration: FormDecorationHelper.roundedInputDecoration(
                      context: context,
                      labelText: 'Password',
                      prefixIcon: Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        ),
                      ),
                    ),
                    validator: (String? value) {
                      final String v = (value ?? '').trim();
                      if (v.isEmpty) return 'Password is required';
                      if (v.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: FormDecorationHelper.roundedInputDecoration(
                      context: context,
                      labelText: 'Confirm password',
                      prefixIcon: Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          });
                        },
                        icon: Icon(
                          _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        ),
                      ),
                    ),
                    validator: (String? value) {
                      final String v = (value ?? '').trim();
                      if (v.isEmpty) return 'Please confirm your password';
                      if (v != _passwordController.text.trim()) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Create account',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onPrimary,
                                  ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: const <Widget>[
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('OR'),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isGoogleSubmitting ? null : _signInWithGoogle,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      icon: _isGoogleSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : SvgPicture.asset(
                              'assets/google-icon-logo-svgrepo-com.svg',
                              width: 20,
                              height: 20,
                            ),
                      label: Text(
                        _isGoogleSubmitting ? 'Signing in…' : 'Continue with Google',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text('Already have an account?'),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: const Text('Log in'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


