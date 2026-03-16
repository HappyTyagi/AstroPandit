import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

bool _isHindi = false;

final languageProvider = StateNotifierProvider<LanguageNotifier, bool>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<bool> {
  LanguageNotifier() : super(_isHindi) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final isHindi = prefs.getBool('isHindiLanguage') ?? false;
    _isHindi = isHindi;
    state = isHindi;
  }

  Future<void> toggleLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isHindiLanguage', !state);
    _isHindi = !state;
    state = !state;
  }
}
