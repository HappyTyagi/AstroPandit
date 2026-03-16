import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import '../config/app_strings.dart';
import 'otp_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isMobileValid = false;

  String tr(String key) => AppStrings.tr(key, ref.watch(languageProvider));

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final String mobileNo = _mobileController.text.trim();

    if (mobileNo.isEmpty) {
      _showSnack(tr('pleaseEnterMobileNumber'));
      return;
    }

    if (mobileNo.length != 10) {
      _showSnack(tr('mobileNumberMustBe10Digits'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.sendMobileOtp(mobileNo);
      if (!mounted) {
        return;
      }
      if (!response.success || response.sessionId.trim().isEmpty) {
        _showSnack(
          response.message.trim().isEmpty ? tr('unableToSendOtp') : response.message,
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            mobileNo: mobileNo,
            sessionId: response.sessionId,
          ),
        ),
      );
    } catch (error) {
      final String message = error.toString();
      String errorMessage = tr('unableToSendOtp');
      if (message.contains('Connection refused') ||
          message.contains('SocketException') ||
          message.contains('connection error')) {
        errorMessage = tr('unableToConnect');
      } else if (message.contains('500')) {
        errorMessage = tr('serverError');
      } else if (message.contains('401') || message.contains('400')) {
        errorMessage = tr('invalidMobileNumber');
      } else if (message.contains('timeout')) {
        errorMessage = tr('requestTimeout');
      } else if (message.contains('Mobile OTP error')) {
        errorMessage = tr('unableToSendOtp');
      }
      _showSnack(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Widget _buildHeroBadge() {
    return Center(
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.95),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    AppTheme.primaryIndigo.withValues(alpha: 0.96),
                    AppTheme.gold.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
            const Icon(
              Icons.self_improvement_rounded,
              size: 44,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(7.5),
        border: Border.all(
          color:
              _isMobileValid ? AppTheme.primaryIndigo : const Color(0xFFE0E0E0),
          width: _isMobileValid ? 2.5 : 1.5,
        ),
      ),
      child: Row(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              '+91',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF333333),
              ),
            ),
          ),
          Container(
            width: 2,
            height: 32,
            color: const Color(0xFFE0E0E0),
          ),
          Expanded(
            child: TextField(
              controller: _mobileController,
              keyboardType: TextInputType.number,
              maxLength: 10,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (String value) {
                setState(() {
                  _isMobileValid = RegExp(r'^[0-9]{10}$').hasMatch(value);
                });
              },
              decoration: const InputDecoration(
                hintText: 'Enter mobile number',
                hintStyle: TextStyle(
                  color: Color(0xFFBBBBBB),
                  fontSize: 14,
                ),
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 20,
                ),
              ),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return Container(
      width: double.infinity,
      height: 46,
      decoration: BoxDecoration(
        color: _isMobileValid ? AppTheme.gold : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(7.5),
        boxShadow: _isMobileValid
            ? <BoxShadow>[
                BoxShadow(
                  color: AppTheme.gold.withValues(alpha: 0.4),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ]
            : <BoxShadow>[],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isMobileValid && !_isLoading ? _sendOtp : null,
          borderRadius: BorderRadius.circular(7.5),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    tr('sendOtp'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 25),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryIndigo.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.phone_android_rounded,
                      color: AppTheme.primaryIndigo,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      tr('phoneNumber'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'We will send OTP for pandit verification',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),
            _buildPhoneInput(),
            const SizedBox(height: 28),
            _buildPrimaryButton(),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(height: 1, color: const Color(0xFFE0E0E0)),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'PANDIT ONLY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(height: 1, color: const Color(0xFFE0E0E0)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'Only approved pandit mobile numbers can continue',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.gold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: <Widget>[
          Container(color: AppTheme.gold),
          Positioned(
            top: -40,
            right: -30,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
          Positioned(
            top: 130,
            left: -50,
            child: IgnorePointer(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: screenHeight * 0.6,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomInset + 20),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 40),
                  _buildHeroBadge(),
                  const SizedBox(height: 28),
                  Text(
                    tr('welcomeBack'),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      'Manage your upcoming pujas and join scheduled video calls',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildLoginCard(),
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'By accessing, you agree to the secured pandit workflow and verified staff-only access rules.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
