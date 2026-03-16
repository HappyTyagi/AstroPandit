import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pandit_puja_models.dart';
import '../services/api_client.dart';
import '../services/pandit_puja_service.dart';
import '../theme/app_theme.dart';
import 'upcoming_puja_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final PanditPujaService _pujaService = PanditPujaService();

  late Future<List<PanditPujaBooking>> _upcomingFuture;
  String _name = '';
  String _mobileNo = '';

  @override
  void initState() {
    super.initState();
    _upcomingFuture = _pujaService.fetchUpcomingPujas();
    _loadProfile();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _name = (prefs.getString('name') ?? '').trim();
      _mobileNo = (prefs.getString('mobileNo') ?? '').trim();
    });
  }

  Future<void> _openUpcoming() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UpcomingPujaScreen()),
    );
    if (!mounted) return;
    setState(() => _upcomingFuture = _pujaService.fetchUpcomingPujas());
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
      body: Container(
        decoration: AppTheme.pageBackdrop(),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'AstroPandit',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Verified pandit dashboard',
                        style: TextStyle(
                          color: AppTheme.muted.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton.filledTonal(
                    onPressed: _logout,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryIndigo,
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    tooltip: 'Logout',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                decoration: AppTheme.glassCard(radius: 26),
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.self_improvement_rounded,
                        color: AppTheme.primaryIndigo,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _name.isEmpty ? _greeting : '$_greeting, $_name',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _mobileNo.isEmpty
                                ? 'Manage your upcoming pujas and join scheduled video calls.'
                                : 'Signed in as +91 $_mobileNo',
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
              const SizedBox(height: 16),
              Container(
                decoration: AppTheme.glassCard(radius: 26),
                padding: const EdgeInsets.all(18),
                child: FutureBuilder<List<PanditPujaBooking>>(
                  future: _upcomingFuture,
                  builder: (context, snapshot) {
                    final bool loading =
                        snapshot.connectionState == ConnectionState.waiting;
                    final bool hasError = snapshot.hasError;
                    final items = snapshot.data ?? <PanditPujaBooking>[];

                    DateTime? nextSlot;
                    for (final booking in items) {
                      final slotTime = booking.slotTime;
                      if (slotTime == null) continue;
                      if (nextSlot == null || slotTime.isBefore(nextSlot)) {
                        nextSlot = slotTime;
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Text(
                              'Upcoming Pujas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _upcomingFuture =
                                      _pujaService.fetchUpcomingPujas();
                                });
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              tooltip: 'Refresh',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (loading)
                          Row(
                            children: <Widget>[
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.6,
                                  color: AppTheme.primaryIndigo.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Loading your schedule...',
                                style: TextStyle(
                                  color: AppTheme.muted.withValues(alpha: 0.95),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        else if (hasError)
                          Text(
                            'Unable to load upcoming pujas right now.',
                            style: TextStyle(
                              color: AppTheme.danger.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        else
                          Text(
                            items.isEmpty
                                ? 'No upcoming pujas assigned.'
                                : '${items.length} puja(s) scheduled${nextSlot == null ? '' : ' • Next: ${_formatShort(nextSlot)}'}',
                            style: TextStyle(
                              color: AppTheme.muted.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: _openUpcoming,
                          icon: const Icon(Icons.temple_hindu_rounded),
                          label: const Text('View Upcoming Pujas'),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.primaryIndigo.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppTheme.primaryIndigo.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Join opens 10 minutes before the scheduled slot.',
                        style: TextStyle(
                          color: AppTheme.muted.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatShort(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')} $hour:$minute $suffix';
  }
}
