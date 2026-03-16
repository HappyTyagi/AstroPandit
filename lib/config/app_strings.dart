// English & Hindi Localization Strings for AstroPandit
class AppStrings {
  // Authentication
  static const String login = 'Login';
  static const String otpVerification = 'OTP Verification';
  static const String enterOtp = 'Enter OTP';
  static const String sendOtp = 'Send OTP';
  static const String verifyOtp = 'Verify OTP';
  static const String phoneNumber = 'Phone Number';
  static const String pleaseEnterMobileNumber = 'Please enter mobile number';
  static const String mobileNumberMustBe10Digits =
      'Mobile number must be 10 digits';
  static const String unableToSendOtp = 'Unable to send OTP. Please try again';
  static const String otpResentSuccessfully = 'OTP resent successfully';
  static const String invalidOtp = 'Invalid OTP. Please try again';
  static const String verifyAndLogin = 'VERIFY & LOGIN';
  static const String resendOtp = 'RESEND OTP';
  static const String yourNumber = 'Your Number';
  static const String edit = 'Edit';

  // Common
  static const String welcomeBack = 'Welcome Back';
  static const String dashboard = 'Dashboard';

  static const String unableToConnect =
      'Unable to connect to server. Please check your internet connection';
  static const String serverError = 'Server error. Please try again later';
  static const String requestTimeout =
      'Request timeout. Please check your connection and try again';
  static const String invalidMobileNumber =
      'Invalid mobile number. Please check and try again';

  static Map<String, String> get hindiTranslations => {
    'login': 'लॉगिन',
    'otpVerification': 'OTP सत्यापन',
    'enterOtp': 'OTP दर्ज करें',
    'sendOtp': 'OTP भेजें',
    'verifyOtp': 'OTP सत्यापित करें',
    'phoneNumber': 'फोन नंबर',
    'pleaseEnterMobileNumber': 'कृपया मोबाइल नंबर दर्ज करें',
    'mobileNumberMustBe10Digits': 'मोबाइल नंबर 10 अंकों का होना चाहिए',
    'unableToSendOtp': 'OTP भेजा नहीं जा सका। कृपया पुनः प्रयास करें',
    'otpResentSuccessfully': 'OTP दोबारा भेज दिया गया',
    'invalidOtp': 'गलत OTP। कृपया पुनः प्रयास करें',
    'verifyAndLogin': 'सत्यापित करें और लॉगिन करें',
    'resendOtp': 'OTP दोबारा भेजें',
    'yourNumber': 'आपका नंबर',
    'edit': 'बदलें',
    'welcomeBack': 'वापसी पर स्वागत है',
    'dashboard': 'डैशबोर्ड',
    'unableToConnect':
        'सर्वर से कनेक्ट नहीं हो पाया। कृपया इंटरनेट कनेक्शन जांचें',
    'serverError': 'सर्वर त्रुटि। कृपया बाद में पुनः प्रयास करें',
    'requestTimeout':
        'अनुरोध का समय समाप्त हो गया। कृपया कनेक्शन जांचकर पुनः प्रयास करें',
    'invalidMobileNumber': 'अमान्य मोबाइल नंबर। कृपया जांचकर पुनः प्रयास करें',
  };

  static Map<String, String> get englishTranslations => {
    'login': login,
    'otpVerification': otpVerification,
    'enterOtp': enterOtp,
    'sendOtp': sendOtp,
    'verifyOtp': verifyOtp,
    'phoneNumber': phoneNumber,
    'pleaseEnterMobileNumber': pleaseEnterMobileNumber,
    'mobileNumberMustBe10Digits': mobileNumberMustBe10Digits,
    'unableToSendOtp': unableToSendOtp,
    'otpResentSuccessfully': otpResentSuccessfully,
    'invalidOtp': invalidOtp,
    'verifyAndLogin': verifyAndLogin,
    'resendOtp': resendOtp,
    'yourNumber': yourNumber,
    'edit': edit,
    'welcomeBack': welcomeBack,
    'dashboard': dashboard,
    'unableToConnect': unableToConnect,
    'serverError': serverError,
    'requestTimeout': requestTimeout,
    'invalidMobileNumber': invalidMobileNumber,
  };

  static String tr(String key, bool isHindi) {
    if (isHindi) {
      return hindiTranslations[key] ?? englishTranslations[key] ?? key;
    }
    return englishTranslations[key] ?? key;
  }
}
