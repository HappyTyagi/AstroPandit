import 'api_client.dart';

class PujaSessionService {
  final ApiClient _client = ApiClient();

  Future<void> startPuja({required int bookingId, required String otp}) async {
    final response = await _client.post(
      '/puja/$bookingId/start',
      data: <String, dynamic>{'otp': otp},
    );

    final data = response.data;
    if (data is! Map) {
      throw Exception('Invalid response from server');
    }

    final payload = Map<String, dynamic>.from(data);
    final bool ok = payload['status'] == true || payload['success'] == true;
    if (!ok) {
      throw Exception(
        (payload['message'] ?? 'Unable to start puja').toString().trim(),
      );
    }
  }

  Future<void> endPuja({required int bookingId, required String otp}) async {
    final response = await _client.post(
      '/puja/$bookingId/end',
      data: <String, dynamic>{'otp': otp},
    );

    final data = response.data;
    if (data is! Map) {
      throw Exception('Invalid response from server');
    }

    final payload = Map<String, dynamic>.from(data);
    final bool ok = payload['status'] == true || payload['success'] == true;
    if (!ok) {
      throw Exception(
        (payload['message'] ?? 'Unable to end puja').toString().trim(),
      );
    }
  }
}

