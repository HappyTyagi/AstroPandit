import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/pandit_puja_models.dart';
import '../services/pandit_puja_service.dart';
import '../services/puja_call_service.dart';
import '../theme/app_theme.dart';
import 'puja_video_call_screen.dart';

class UpcomingPujaScreen extends StatefulWidget {
  const UpcomingPujaScreen({super.key});

  @override
  State<UpcomingPujaScreen> createState() => _UpcomingPujaScreenState();
}

class _UpcomingPujaScreenState extends State<UpcomingPujaScreen> {
  final PanditPujaService _service = PanditPujaService();
  final PujaCallService _callService = PujaCallService();

  late Future<List<PanditPujaBooking>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchUpcomingPujas();
  }

  Future<void> _reload() async {
    setState(() => _future = _service.fetchUpcomingPujas());
    await _future;
  }

  bool _isJoinAllowed(DateTime slotTime) {
    final joinOpensAt = slotTime.subtract(const Duration(minutes: 10));
    return DateTime.now().isAfter(joinOpensAt);
  }

  Future<void> _join(PanditPujaBooking booking) async {
    final slotTime = booking.slotTime;
    if (slotTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slot time is not assigned yet.')),
      );
      return;
    }
    if (!_isJoinAllowed(slotTime)) {
      final joinOpensAt = slotTime.subtract(const Duration(minutes: 10));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Join will open at ${DateFormat('dd MMM, hh:mm a').format(joinOpensAt)}',
          ),
        ),
      );
      return;
    }

    try {
      final link = await _callService.generateAgoraLink(
        bookingId: booking.bookingId,
        callType: 'video',
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PujaVideoCallScreen(
            appId: link.appId,
            token: link.token,
            channelName: link.channelName,
            uid: link.uid,
            callType: 'video',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.gold,
        foregroundColor: AppTheme.primaryIndigo,
        title: const Text('Upcoming Puja'),
      ),
      body: FutureBuilder<List<PanditPujaBooking>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 44),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _reload,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final items = snapshot.data ?? <PanditPujaBooking>[];
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Center(child: Text('No upcoming pujas')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = items[index];
                final slotTime = booking.slotTime;
                final joinEnabled = slotTime != null && _isJoinAllowed(slotTime);
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.pujaName.isEmpty ? 'Puja' : booking.pujaName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${booking.userName} • ${booking.mobileNumber}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                slotTime == null
                                    ? 'Slot pending'
                                    : DateFormat('dd MMM yyyy, hh:mm a')
                                        .format(slotTime),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: joinEnabled ? () => _join(booking) : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryIndigo,
                            ),
                            child: const Text('Join Video'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
