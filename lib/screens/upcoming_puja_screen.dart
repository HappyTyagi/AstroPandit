import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/pandit_puja_models.dart';
import '../services/pandit_puja_service.dart';
import '../services/puja_call_service.dart';
import '../services/puja_session_service.dart';
import '../theme/app_theme.dart';
import 'puja_video_call_screen.dart';

class UpcomingPujaScreen extends StatefulWidget {
  final bool embedded;
  final bool completedOnly;

  const UpcomingPujaScreen({
    super.key,
    this.embedded = false,
    this.completedOnly = false,
  });

  @override
  State<UpcomingPujaScreen> createState() => _UpcomingPujaScreenState();
}

class _UpcomingPujaScreenState extends State<UpcomingPujaScreen> {
  final PanditPujaService _service = PanditPujaService();
  final PujaCallService _callService = PujaCallService();
  final PujaSessionService _sessionService = PujaSessionService();

  late Future<List<PanditPujaBooking>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchPujas(completedOnly: widget.completedOnly);
  }

  Future<void> _reload() async {
    setState(
      () => _future = _service.fetchPujas(completedOnly: widget.completedOnly),
    );
    await _future;
  }

  bool _isJoinAllowed(DateTime slotTime) {
    final joinOpensAt = slotTime.subtract(const Duration(minutes: 10));
    return DateTime.now().isAfter(joinOpensAt);
  }

  Future<String?> _promptOtp({
    required String title,
    String hintText = 'Enter 4-digit OTP',
  }) async {
    final controller = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: AppTheme.glassCard(radius: 28),
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'OTP Admin/User app par dikhega. Pandit side par sirf OTP enter karke start/end hoga.',
                  style: TextStyle(
                    color: AppTheme.muted.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 14,
                    color: AppTheme.primaryIndigo,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.pop(context, controller.text.trim()),
                        child: const Text('Submit'),
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
    controller.dispose();
    return result;
  }

  Future<void> _startPuja(PanditPujaBooking booking) async {
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
            'Start will open at ${DateFormat('dd MMM, hh:mm a').format(joinOpensAt)}',
          ),
        ),
      );
      return;
    }

    final otp = await _promptOtp(title: 'Enter Puja OTP');
    if (!mounted) return;
    if (otp == null || otp.trim().isEmpty) {
      return;
    }
    if (!RegExp(r'^[0-9]{4}$').hasMatch(otp)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 4-digit OTP')),
      );
      return;
    }

    try {
      await _sessionService.startPuja(bookingId: booking.bookingId, otp: otp);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Puja started successfully')),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _endPuja(PanditPujaBooking booking) async {
    if (booking.startedAt == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please start puja first.')));
      return;
    }
    if (booking.completedAt != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Puja is already completed.')),
      );
      return;
    }

    final otp = await _promptOtp(title: 'Enter Puja OTP to End');
    if (!mounted) return;
    if (otp == null || otp.trim().isEmpty) {
      return;
    }
    if (!RegExp(r'^[0-9]{4}$').hasMatch(otp)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 4-digit OTP')),
      );
      return;
    }

    try {
      await _sessionService.endPuja(bookingId: booking.bookingId, otp: otp);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Puja ended successfully')));
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
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
    if (booking.startedAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please start puja with OTP first.')),
      );
      return;
    }
    if (booking.completedAt != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Puja already completed.')));
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
    final content = Container(
      decoration: AppTheme.pageBackdrop(),
      child: FutureBuilder<List<PanditPujaBooking>>(
        future: _future,
        builder: (context, snapshot) {
          final waiting = snapshot.connectionState == ConnectionState.waiting;
          final error = snapshot.error;
          final items = snapshot.data ?? <PanditPujaBooking>[];

          return RefreshIndicator(
            onRefresh: _reload,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  automaticallyImplyLeading: !widget.embedded,
                  title: Text(
                    widget.completedOnly ? 'Complete Puja' : 'Upcoming Puja',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  leading: widget.embedded
                      ? null
                      : IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                  actions: <Widget>[
                    IconButton(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                if (!widget.completedOnly)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppTheme.primaryIndigo.withValues(
                              alpha: 0.08,
                            ),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.schedule_rounded,
                              color: AppTheme.primaryIndigo.withValues(
                                alpha: 0.85,
                              ),
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
                    ),
                  ),
                if (waiting)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(
                      message: error.toString(),
                      onRetry: _reload,
                    ),
                  )
                else if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(completedOnly: widget.completedOnly),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _BookingCard(
                          booking: items[index],
                          isJoinAllowed: _isJoinAllowed,
                          onStart: _startPuja,
                          onJoin: _join,
                          onEnd: _endPuja,
                          readOnly: widget.completedOnly,
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );

    if (widget.embedded) {
      return content;
    }
    return Scaffold(body: content);
  }
}

class _EmptyState extends StatelessWidget {
  final bool completedOnly;

  const _EmptyState({required this.completedOnly});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppTheme.gold.withValues(alpha: 0.25)),
            ),
            child: const Icon(
              Icons.temple_hindu_rounded,
              size: 42,
              color: AppTheme.primaryIndigo,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            completedOnly ? 'No completed pujas yet' : 'No upcoming pujas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            completedOnly
                ? 'Completed pujas will appear here after you end them with OTP.'
                : 'When a puja is assigned to you, it will appear here.',
            style: TextStyle(
              color: AppTheme.muted.withValues(alpha: 0.95),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: AppTheme.danger.withValues(alpha: 0.24),
              ),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: AppTheme.danger,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Something went wrong',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              color: AppTheme.muted.withValues(alpha: 0.95),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final PanditPujaBooking booking;
  final bool Function(DateTime slotTime) isJoinAllowed;
  final Future<void> Function(PanditPujaBooking booking) onStart;
  final Future<void> Function(PanditPujaBooking booking) onJoin;
  final Future<void> Function(PanditPujaBooking booking) onEnd;
  final bool readOnly;

  const _BookingCard({
    required this.booking,
    required this.isJoinAllowed,
    required this.onStart,
    required this.onJoin,
    required this.onEnd,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final slotTime = booking.slotTime;
    final started = booking.startedAt != null;
    final completed = booking.completedAt != null;
    final joinEnabled =
        started && !completed && slotTime != null && isJoinAllowed(slotTime);
    final startEnabled =
        !started && !completed && slotTime != null && isJoinAllowed(slotTime);

    return Container(
      decoration: AppTheme.glassCard(radius: 24),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  booking.pujaName.isEmpty ? 'Puja' : booking.pujaName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusChip(started: started, completed: completed),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primaryIndigo.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 20,
                  color: AppTheme.primaryIndigo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'User',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.userName.isEmpty ? 'Unknown' : booking.userName,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.schedule_rounded,
            label: slotTime == null
                ? 'Slot pending'
                : DateFormat('dd MMM yyyy • hh:mm a').format(slotTime),
          ),
          if (booking.startedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _InfoRow(
                icon: Icons.play_circle_outline_rounded,
                label:
                    'Started • ${DateFormat('dd MMM, hh:mm a').format(booking.startedAt!)}',
              ),
            ),
          if (booking.completedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _InfoRow(
                icon: Icons.verified_rounded,
                label:
                    'Ended • ${DateFormat('dd MMM, hh:mm a').format(booking.completedAt!)}',
              ),
            ),
          const SizedBox(height: 14),
          Divider(color: AppTheme.primaryIndigo.withValues(alpha: 0.08)),
          const SizedBox(height: 14),
          if (completed || readOnly)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: (completed ? AppTheme.success : AppTheme.primaryIndigo)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: (completed ? AppTheme.success : AppTheme.primaryIndigo)
                      .withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                completed
                    ? 'Puja completed'
                    : 'Completion status pending from server',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            )
          else if (!started)
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: startEnabled ? () => onStart(booking) : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      foregroundColor: AppTheme.ink,
                    ),
                    icon: const Icon(Icons.lock_open_rounded),
                    label: const Text('Start'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.videocam_rounded),
                    label: const Text('Join'),
                  ),
                ),
              ],
            )
          else
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: joinEnabled ? () => onJoin(booking) : null,
                    icon: const Icon(Icons.videocam_rounded),
                    label: const Text('Join'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => onEnd(booking),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.stop_circle_rounded),
                    label: const Text('End'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool started;
  final bool completed;

  const _StatusChip({required this.started, required this.completed});

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = completed
        ? (
            'Completed',
            AppTheme.success,
            AppTheme.success.withValues(alpha: 0.12),
          )
        : started
        ? (
            'In progress',
            AppTheme.primaryIndigo,
            AppTheme.gold.withValues(alpha: 0.16),
          )
        : (
            'Pending',
            AppTheme.muted,
            AppTheme.primaryIndigo.withValues(alpha: 0.06),
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(
          icon,
          size: 18,
          color: AppTheme.primaryIndigo.withValues(alpha: 0.75),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.muted.withValues(alpha: 0.95),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
