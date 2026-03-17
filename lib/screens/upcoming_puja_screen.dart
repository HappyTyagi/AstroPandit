import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pandit_puja_models.dart';
import '../services/app_preferences.dart';
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
  bool _isHindi = AppPreferences.isHindiNotifier.value;

  @override
  void initState() {
    super.initState();
    AppPreferences.isHindiNotifier.addListener(_handleLanguageChanged);
    _future = _service.fetchPujas(completedOnly: widget.completedOnly);
  }

  @override
  void dispose() {
    AppPreferences.isHindiNotifier.removeListener(_handleLanguageChanged);
    super.dispose();
  }

  void _handleLanguageChanged() {
    if (!mounted) return;
    setState(() {
      _isHindi = AppPreferences.isHindiNotifier.value;
    });
  }

  String _tr(String en, String hi) => _isHindi ? hi : en;

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
    String? hintText,
  }) async {
    final String effectiveHint =
        hintText ?? _tr('Enter 4-digit OTP', '4 अंकों का OTP दर्ज करें');
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
                  _tr(
                    'OTP is visible on Admin/User app. Pandit side can only start/end using OTP.',
                    'OTP एडमिन/यूज़र ऐप पर दिखेगा। पंडित साइड से सिर्फ OTP डालकर start/end होगा।',
                  ),
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
                    hintText: effectiveHint,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(_tr('Cancel', 'रद्द करें')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.pop(context, controller.text.trim()),
                        child: Text(_tr('Submit', 'सबमिट')),
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
        SnackBar(
            content: Text(_tr('Slot time is not assigned yet.',
                'स्लॉट समय अभी असाइन नहीं है।'))),
      );
      return;
    }
    if (!_isJoinAllowed(slotTime)) {
      final joinOpensAt = slotTime.subtract(const Duration(minutes: 10));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'Start will open at ${DateFormat('dd MMM, hh:mm a').format(joinOpensAt)}',
              'स्टार्ट ${DateFormat('dd MMM, hh:mm a').format(joinOpensAt)} पर खुलेगा',
            ),
          ),
        ),
      );
      return;
    }

    final otp =
        await _promptOtp(title: _tr('Enter Puja OTP', 'पूजा OTP दर्ज करें'));
    if (!mounted) return;
    if (otp == null || otp.trim().isEmpty) {
      return;
    }
    if (!RegExp(r'^[0-9]{4}$').hasMatch(otp)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_tr('Please enter a valid 4-digit OTP',
                'कृपया सही 4 अंकों का OTP दर्ज करें'))),
      );
      return;
    }

    try {
      await _sessionService.startPuja(bookingId: booking.bookingId, otp: otp);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_tr(
                'Puja started successfully', 'पूजा सफलतापूर्वक शुरू हो गई'))),
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
      ).showSnackBar(SnackBar(
          content: Text(
              _tr('Please start puja first.', 'कृपया पहले पूजा शुरू करें।'))));
      return;
    }
    if (booking.completedAt != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_tr('Puja is already completed.',
                'पूजा पहले ही पूरी हो चुकी है।'))),
      );
      return;
    }

    final otp = await _promptOtp(
        title:
            _tr('Enter Puja OTP to End', 'पूजा समाप्त करने का OTP दर्ज करें'));
    if (!mounted) return;
    if (otp == null || otp.trim().isEmpty) {
      return;
    }
    if (!RegExp(r'^[0-9]{4}$').hasMatch(otp)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_tr('Please enter a valid 4-digit OTP',
                'कृपया सही 4 अंकों का OTP दर्ज करें'))),
      );
      return;
    }

    try {
      await _sessionService.endPuja(bookingId: booking.bookingId, otp: otp);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
          content: Text(
              _tr('Puja ended successfully', 'पूजा सफलतापूर्वक समाप्त हुई'))));
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
        SnackBar(
            content: Text(_tr('Slot time is not assigned yet.',
                'स्लॉट समय अभी असाइन नहीं है।'))),
      );
      return;
    }
    if (!_isJoinAllowed(slotTime)) {
      final joinOpensAt = slotTime.subtract(const Duration(minutes: 10));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(
              'Join will open at ${DateFormat('dd MMM, hh:mm a').format(joinOpensAt)}',
              'जॉइन ${DateFormat('dd MMM, hh:mm a').format(joinOpensAt)} पर खुलेगा',
            ),
          ),
        ),
      );
      return;
    }
    if (booking.startedAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_tr('Please start puja with OTP first.',
                'कृपया पहले OTP से पूजा शुरू करें।'))),
      );
      return;
    }
    if (booking.completedAt != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
          content: Text(_tr(
              'Puja already completed.', 'पूजा पहले ही पूरी हो चुकी है।'))));
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final content = Container(
      decoration: AppTheme.pageBackdrop(isDark: isDark),
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
                    widget.completedOnly
                        ? _tr('Complete Puja', 'पूर्ण पूजा')
                        : _tr('Upcoming Puja', 'आगामी पूजा'),
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
                      tooltip: _tr('Refresh', 'रीफ्रेश'),
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
                                _tr(
                                  'Join opens 10 minutes before the scheduled slot.',
                                  'जॉइन निर्धारित स्लॉट से 10 मिनट पहले खुलेगा।',
                                ),
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
                      isHindi: _isHindi,
                      message: error.toString(),
                      onRetry: _reload,
                    ),
                  )
                else if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(
                      completedOnly: widget.completedOnly,
                      isHindi: _isHindi,
                    ),
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
                          isHindi: _isHindi,
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
  final bool isHindi;

  const _EmptyState({required this.completedOnly, required this.isHindi});

  String _tr(String en, String hi) => isHindi ? hi : en;

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
            completedOnly
                ? _tr('No completed pujas yet', 'अभी कोई पूर्ण पूजा नहीं है')
                : _tr('No upcoming pujas', 'कोई आगामी पूजा नहीं है'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Text(
            completedOnly
                ? _tr(
                    'Completed pujas will appear here after you end them with OTP.',
                    'OTP से समाप्त करने के बाद पूर्ण पूजा यहाँ दिखेगी।',
                  )
                : _tr(
                    'When a puja is assigned to you, it will appear here.',
                    'जब पूजा आपको असाइन होगी, वह यहाँ दिखाई देगी।',
                  ),
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
  final bool isHindi;
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.isHindi,
    required this.message,
    required this.onRetry,
  });

  String _tr(String en, String hi) => isHindi ? hi : en;

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
          Text(
            _tr('Something went wrong', 'कुछ गलत हो गया'),
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
            label: Text(_tr('Retry', 'फिर प्रयास करें')),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final PanditPujaBooking booking;
  final bool isHindi;
  final bool Function(DateTime slotTime) isJoinAllowed;
  final Future<void> Function(PanditPujaBooking booking) onStart;
  final Future<void> Function(PanditPujaBooking booking) onJoin;
  final Future<void> Function(PanditPujaBooking booking) onEnd;
  final bool readOnly;

  const _BookingCard({
    required this.booking,
    required this.isHindi,
    required this.isJoinAllowed,
    required this.onStart,
    required this.onJoin,
    required this.onEnd,
    this.readOnly = false,
  });

  String _tr(String en, String hi) => isHindi ? hi : en;

  String _packageLabel() {
    final String explicitName = booking.packageName.trim();
    if (explicitName.isNotEmpty) {
      return explicitName;
    }
    final String code = booking.packageCode.trim().toUpperCase();
    if (code == 'PREMIUM') return _tr('Premium', 'प्रीमियम');
    if (code == 'REGULAR') return _tr('Regular', 'रेगुलर');
    return _tr('Basic', 'बेसिक');
  }

  String _statusText({required bool started, required bool completed}) {
    if (completed) return _tr('Completed', 'पूर्ण');
    if (started) return _tr('In progress', 'चालू');
    return _tr('Pending', 'लंबित');
  }

  Future<void> _openMap(BuildContext context) async {
    final String resolved = booking.mapUrl.trim().isNotEmpty
        ? booking.mapUrl.trim()
        : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(booking.address.trim())}';
    if (booking.address.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(_tr('Address is not available.', 'पता उपलब्ध नहीं है।'))),
      );
      return;
    }
    final Uri uri = Uri.parse(resolved);
    final bool opened =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_tr('Unable to open map.', 'मैप नहीं खुल पाया।'))),
      );
    }
  }

  Future<void> _showDetails(BuildContext context) async {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: AppTheme.glassCard(radius: 28, isDark: dark),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.muted.withValues(alpha: 0.32),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            booking.pujaName.isEmpty
                                ? _tr('Puja', 'पूजा')
                                : booking.pujaName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppTheme.gold.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              '${_tr('Package', 'पैकेज')}: ${_packageLabel()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryIndigo,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusChip(
                      started: booking.startedAt != null,
                      completed: booking.completedAt != null,
                      isHindi: isHindi,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _DetailBlock(
                  icon: Icons.person_rounded,
                  label: _tr('User Name', 'यूज़र नाम'),
                  value: booking.userName.isEmpty
                      ? _tr('Unknown', 'अज्ञात')
                      : booking.userName,
                ),
                const SizedBox(height: 10),
                _DetailBlock(
                  icon: Icons.schedule_rounded,
                  label: _tr('Puja Slot', 'पूजा स्लॉट'),
                  value: booking.slotTime == null
                      ? _tr('Slot pending', 'स्लॉट लंबित')
                      : DateFormat('dd MMM yyyy • hh:mm a')
                          .format(booking.slotTime!),
                ),
                if (booking.bookedAt != null) ...<Widget>[
                  const SizedBox(height: 10),
                  _DetailBlock(
                    icon: Icons.event_note_rounded,
                    label: _tr('Booked At', 'बुकिंग समय'),
                    value: DateFormat('dd MMM yyyy • hh:mm a').format(
                      booking.bookedAt!,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                _DetailBlock(
                  icon: Icons.task_alt_rounded,
                  label: _tr('Status', 'स्थिति'),
                  value: _statusText(
                    started: booking.startedAt != null,
                    completed: booking.completedAt != null,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryIndigo.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryIndigo.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.location_on_rounded,
                        color: AppTheme.primaryIndigo.withValues(alpha: 0.88),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _tr('User Address', 'यूज़र पता'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              booking.address.trim().isEmpty
                                  ? _tr('Address not available',
                                      'पता उपलब्ध नहीं है')
                                  : booking.address.trim(),
                              style: TextStyle(
                                height: 1.4,
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
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: booking.address.trim().isEmpty
                        ? null
                        : () => _openMap(context),
                    icon: const Icon(Icons.navigation_rounded),
                    label: Text(_tr('Navigate on Map', 'मैप पर नेविगेट करें')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final slotTime = booking.slotTime;
    final started = booking.startedAt != null;
    final completed = booking.completedAt != null;
    final joinEnabled =
        started && !completed && slotTime != null && isJoinAllowed(slotTime);
    final startEnabled =
        !started && !completed && slotTime != null && isJoinAllowed(slotTime);
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: AppTheme.glassCard(radius: 24, isDark: dark),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showDetails(context),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      booking.pujaName.isEmpty
                          ? _tr('Puja', 'पूजा')
                          : booking.pujaName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                      started: started, completed: completed, isHindi: isHindi),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showDetails(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.gold.withValues(alpha: 0.32),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.card_membership_rounded,
                    size: 19,
                    color: AppTheme.primaryIndigo.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_tr('Package', 'पैकेज')}: ${_packageLabel()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppTheme.primaryIndigo.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.person_rounded,
            label:
                '${_tr('User', 'यूज़र')}: ${booking.userName.isEmpty ? _tr('Unknown', 'अज्ञात') : booking.userName}',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.schedule_rounded,
            label: slotTime == null
                ? _tr('Slot pending', 'स्लॉट लंबित')
                : DateFormat('dd MMM yyyy • hh:mm a').format(slotTime),
          ),
          if (booking.startedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _InfoRow(
                icon: Icons.play_circle_outline_rounded,
                label:
                    '${_tr('Started', 'शुरू')} • ${DateFormat('dd MMM, hh:mm a').format(booking.startedAt!)}',
              ),
            ),
          if (booking.completedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _InfoRow(
                icon: Icons.verified_rounded,
                label:
                    '${_tr('Ended', 'समाप्त')} • ${DateFormat('dd MMM, hh:mm a').format(booking.completedAt!)}',
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
                    ? _tr('Puja completed', 'पूजा पूरी हो चुकी है')
                    : _tr(
                        'Completion status pending from server',
                        'सर्वर से पूर्ण स्थिति लंबित है',
                      ),
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
                    label: Text(_tr('Start', 'शुरू करें')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.videocam_rounded),
                    label: Text(_tr('Join', 'जॉइन')),
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
                    label: Text(_tr('Join', 'जॉइन')),
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
                    label: Text(_tr('End', 'समाप्त करें')),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DetailBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailBlock({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryIndigo.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primaryIndigo),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.muted.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool started;
  final bool completed;
  final bool isHindi;

  const _StatusChip({
    required this.started,
    required this.completed,
    required this.isHindi,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = completed
        ? (
            isHindi ? 'पूर्ण' : 'Completed',
            AppTheme.success,
            AppTheme.success.withValues(alpha: 0.12),
          )
        : started
            ? (
                isHindi ? 'चालू' : 'In progress',
                AppTheme.primaryIndigo,
                AppTheme.gold.withValues(alpha: 0.16),
              )
            : (
                isHindi ? 'लंबित' : 'Pending',
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
