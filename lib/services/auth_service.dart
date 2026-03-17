import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../config/api_config.dart';

// Models
class OtpSendResponse {
  final bool success;
  final String message;
  final String sessionId;

  OtpSendResponse({
    required this.success,
    required this.message,
    required this.sessionId,
  });

  factory OtpSendResponse.fromJson(Map<String, dynamic> json) {
    return OtpSendResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? 'OTP sent successfully',
      sessionId: json['sessionId'] ?? '',
    );
  }
}

class AuthResponse {
  final bool success;
  final String message;
  final String token;
  final String? refreshToken;
  final int? userId;
  final String? name;
  final String? mobileNo;
  final String? email;
  final String? role;
  final bool? isProfileComplete;
  final bool? isNewUser;

  AuthResponse({
    required this.success,
    required this.message,
    required this.token,
    this.refreshToken,
    this.userId,
    this.name,
    this.mobileNo,
    this.email,
    this.role,
    this.isProfileComplete,
    this.isNewUser,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: json['token'] ?? '',
      refreshToken: json['refreshToken'],
      userId: json['userId'],
      name: json['name'],
      mobileNo: json['mobileNo'],
      email: json['email'],
      role: json['role'],
      isProfileComplete: json['isProfileComplete'],
      isNewUser: json['isNewUser'],
    );
  }
}

class AuthService {
  String _normalizeMobile(String value) {
    final String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length <= 10) return digits;
    return digits.substring(digits.length - 10);
  }

  bool _isAllowedPanditMobile(String mobileNo) {
    final configured = _normalizeMobile(ApiConfig.panditMobileNo);
    if (configured.isEmpty) return true;
    return _normalizeMobile(mobileNo) == configured;
  }

  // Send Mobile OTP
  Future<OtpSendResponse> sendMobileOtp(String mobileNo) async {
    try {
      final dio = Dio(BaseOptions(headers: ApiConfig.headers));
      final response = await dio.post(
        '${ApiConfig.baseUrl}${ApiConfig.sendOtp}',
        data: {'mobileNo': mobileNo},
        options: Options(contentType: 'application/json'),
      );

      if (response.statusCode == 200) {
        return OtpSendResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to send OTP: ${response.statusMessage}');
      }
    } catch (e) {
      throw Exception('Mobile OTP error: $e');
    }
  }

  // Verify Mobile OTP
  Future<AuthResponse> verifyMobileOtp({
    required String mobileNo,
    required String otp,
    required String sessionId,
  }) async {
    try {
      final dio = Dio(BaseOptions(headers: ApiConfig.headers));
      final response = await dio.post(
        '${ApiConfig.baseUrl}${ApiConfig.verifyOtp}',
        data: {'mobileNo': mobileNo, 'otp': otp, 'sessionId': sessionId},
        options: Options(contentType: 'application/json'),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final authResponse = AuthResponse.fromJson(data);
        final resolvedMobile = (authResponse.mobileNo ?? mobileNo).trim();
        if (!_isAllowedPanditMobile(resolvedMobile)) {
          return AuthResponse(
            success: false,
            message: 'Only approved pandit mobile number can login',
            token: '',
          );
        }

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('otpVerifyResponseJson', jsonEncode(data));
        await prefs.setInt('userId', authResponse.userId ?? 0);
        await prefs.setString('token', authResponse.token);
        await prefs.setString('mobileNo', authResponse.mobileNo ?? mobileNo);
        if (authResponse.name != null) {
          prefs.setString('name', authResponse.name!);
        }
        if ((authResponse.role ?? '').trim().isNotEmpty) {
          prefs.setString('role', authResponse.role!.trim().toUpperCase());
        }
        if (authResponse.isProfileComplete != null) {
          prefs.setBool('profileComplete', authResponse.isProfileComplete!);
        }
        if (authResponse.isNewUser != null) {
          prefs.setBool('isNewUser', authResponse.isNewUser!);
        }

        debugPrint('Auth data saved for userId: ${authResponse.userId}');
        return authResponse;
      } else {
        return AuthResponse(
          success: false,
          message: response.data['message'] ?? 'OTP verification failed',
          token: '',
        );
      }
    } catch (e) {
      throw Exception('OTP verification error: $e');
    }
  }
}
