import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';
import 'upcoming_puja_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedTab = 0;
  String _name = '';
  String _mobileNo = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _name = (prefs.getString('name') ?? '').trim();
      _mobileNo = (prefs.getString('mobileNo') ?? '').trim();
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await ApiClient().clearToken();
    await prefs.remove('userId');
    await prefs.remove('role');
    await prefs.remove('otpVerifyResponseJson');
    await prefs.remove('profileComplete');
    await prefs.remove('isNewUser');
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          if (_selectedTab == index) return;
          setState(() => _selectedTab = index);
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.calendar_month_rounded),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Upcoming Puja',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_rounded),
            selectedIcon: Icon(Icons.task_alt_rounded),
            label: 'Complete Puja',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Setting',
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedTab) {
      case 0:
        return const UpcomingPujaScreen(embedded: true);
      case 1:
        return const UpcomingPujaScreen(embedded: true, completedOnly: true);
      default:
        return _SettingsTab(
          name: _name,
          mobileNo: _mobileNo,
          onReloadProfile: _loadProfile,
          onLogout: _logout,
        );
    }
  }
}

class _SettingsTab extends StatelessWidget {
  final String name;
  final String mobileNo;
  final Future<void> Function() onReloadProfile;
  final Future<void> Function() onLogout;

  const _SettingsTab({
    required this.name,
    required this.mobileNo,
    required this.onReloadProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.pageBackdrop(),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          children: <Widget>[
            const Text(
              'Setting',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage pandit profile and session',
              style: TextStyle(
                color: AppTheme.muted.withValues(alpha: 0.95),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: AppTheme.glassCard(radius: 24),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.self_improvement_rounded,
                      color: AppTheme.primaryIndigo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          name.isEmpty ? 'Pandit Account' : name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          mobileNo.isEmpty
                              ? 'Mobile number not available'
                              : '+91 $mobileNo',
                          style: TextStyle(
                            color: AppTheme.muted.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: AppTheme.glassCard(radius: 24),
              padding: const EdgeInsets.all(14),
              child: Column(
                children: <Widget>[
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: const Icon(Icons.refresh_rounded),
                    title: const Text(
                      'Refresh Profile',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text('Sync latest name and number'),
                    onTap: onReloadProfile,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: AppTheme.danger,
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.danger,
                      ),
                    ),
                    subtitle: const Text('Sign out from this device'),
                    onTap: onLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
