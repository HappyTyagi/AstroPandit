import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../services/app_preferences.dart';
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
  bool _isHindi = AppPreferences.isHindiNotifier.value;
  bool _isDark = AppPreferences.themeModeNotifier.value == ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    AppPreferences.isHindiNotifier.addListener(_onLanguageChanged);
    AppPreferences.themeModeNotifier.addListener(_onThemeChanged);
    _loadProfile();
  }

  @override
  void dispose() {
    AppPreferences.isHindiNotifier.removeListener(_onLanguageChanged);
    AppPreferences.themeModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (!mounted) return;
    setState(() {
      _isHindi = AppPreferences.isHindiNotifier.value;
    });
  }

  void _onThemeChanged() {
    if (!mounted) return;
    setState(() {
      _isDark = AppPreferences.themeModeNotifier.value == ThemeMode.dark;
    });
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _name = (prefs.getString('name') ?? '').trim();
      _mobileNo = (prefs.getString('mobileNo') ?? '').trim();
    });
  }

  String _tr(String en, String hi) => _isHindi ? hi : en;

  Future<void> _setHindi(bool value) async {
    await AppPreferences.setHindi(value);
  }

  Future<void> _setDarkMode(bool value) async {
    await AppPreferences.setDarkMode(value);
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
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_rounded),
            selectedIcon: const Icon(Icons.calendar_month_rounded),
            label: _tr('Upcoming Puja', 'आगामी पूजा'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.task_alt_rounded),
            selectedIcon: const Icon(Icons.task_alt_rounded),
            label: _tr('Complete Puja', 'पूर्ण पूजा'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_rounded),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: _tr('Setting', 'सेटिंग'),
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
          isHindi: _isHindi,
          isDark: _isDark,
          tr: _tr,
          onSetHindi: _setHindi,
          onSetDarkMode: _setDarkMode,
          onReloadProfile: _loadProfile,
          onLogout: _logout,
        );
    }
  }
}

class _SettingsTab extends StatelessWidget {
  final String name;
  final String mobileNo;
  final bool isHindi;
  final bool isDark;
  final String Function(String en, String hi) tr;
  final Future<void> Function(bool value) onSetHindi;
  final Future<void> Function(bool value) onSetDarkMode;
  final Future<void> Function() onReloadProfile;
  final Future<void> Function() onLogout;

  const _SettingsTab({
    required this.name,
    required this.mobileNo,
    required this.isHindi,
    required this.isDark,
    required this.tr,
    required this.onSetHindi,
    required this.onSetDarkMode,
    required this.onReloadProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: AppTheme.pageBackdrop(isDark: dark),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          children: <Widget>[
            Text(
              tr('Setting', 'सेटिंग'),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              tr(
                'Manage pandit profile and session',
                'पंडित प्रोफ़ाइल और ऐप सेटिंग संभालें',
              ),
              style: TextStyle(
                color: AppTheme.muted.withValues(alpha: 0.95),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: AppTheme.glassCard(radius: 24, isDark: dark),
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
                          name.isEmpty
                              ? tr('Pandit Account', 'पंडित अकाउंट')
                              : name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          mobileNo.isEmpty
                              ? tr(
                                  'Mobile number not available',
                                  'मोबाइल नंबर उपलब्ध नहीं',
                                )
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
              decoration: AppTheme.glassCard(radius: 24, isDark: dark),
              padding: const EdgeInsets.all(14),
              child: Column(
                children: <Widget>[
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: const Icon(Icons.refresh_rounded),
                    title: Text(
                      tr('Refresh Profile', 'प्रोफ़ाइल रीफ्रेश करें'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      tr('Sync latest name and number',
                          'नया नाम और नंबर सिंक करें'),
                    ),
                    onTap: onReloadProfile,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    secondary: const Icon(Icons.language_rounded),
                    value: isHindi,
                    title: Text(
                      tr('Hindi Language', 'हिंदी भाषा'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      tr('Toggle Hindi / English', 'हिंदी / अंग्रेज़ी बदलें'),
                    ),
                    onChanged: onSetHindi,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    secondary: const Icon(Icons.dark_mode_rounded),
                    value: isDark,
                    title: Text(
                      tr('Dark Theme', 'डार्क थीम'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      tr('Enable premium dark UI',
                          'प्रीमियम डार्क UI चालू करें'),
                    ),
                    onChanged: onSetDarkMode,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: AppTheme.danger,
                    ),
                    title: Text(
                      tr('Logout', 'लॉगआउट'),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.danger,
                      ),
                    ),
                    subtitle: Text(
                      tr(
                        'Sign out from this device',
                        'इस डिवाइस से साइन आउट करें',
                      ),
                    ),
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
