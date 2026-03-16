import '../config/api_config.dart';
import '../models/pandit_puja_models.dart';
import 'api_client.dart';

class PanditPujaService {
  final ApiClient _client = ApiClient();

  Future<List<PanditPujaBooking>> fetchUpcomingPujas() async {
    final response = await _client.get(ApiConfig.panditUpcomingPujas);
    final data = response.data;
    if (data is! Map) {
      throw Exception('Invalid response from server');
    }
    final map = Map<String, dynamic>.from(data);
    final ok = map['status'] == true;
    if (!ok) {
      throw Exception((map['message'] ?? 'Failed to load upcoming pujas'));
    }
    final items = (map['bookings'] as List<dynamic>? ?? <dynamic>[])
        .map(
          (dynamic item) =>
              PanditPujaBooking.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    return items;
  }
}
