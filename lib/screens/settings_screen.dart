import 'package:flutter/material.dart';
import '../controllers/theme_controller.dart';
import '../controllers/auth_controller.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricsEnabled = false;

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
                  leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                  title: const Text('John Doe'),
                  subtitle: const Text('you@example.com'),
                  trailing: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit profile tapped (demo)')),
                      );
                    },
                    child: const Text('Edit'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change password'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Change password tapped (demo)')),
                    );
                  },
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
                const Divider(height: 1),
                SwitchListTile(
                  value: _notificationsEnabled,
                  onChanged: (bool value) {
                    setState(() => _notificationsEnabled = value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Notifications ${value ? 'enabled' : 'disabled'} (demo)')),
                    );
                  },
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Enable notifications'),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _biometricsEnabled,
                  onChanged: (bool value) {
                    setState(() => _biometricsEnabled = value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Biometrics ${value ? 'enabled' : 'disabled'} (demo)')),
                    );
                  },
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('Use biometrics'),
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
                await AuthController.instance.signOut();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
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
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }
}


