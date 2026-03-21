import '../config/api_config.dart';
import '../models/pandit_puja_models.dart';
import 'api_client.dart';

class PanditPagedResult<T> {
  final List<T> items;
  final int page;
  final int size;
  final int total;
  final bool hasNext;

  const PanditPagedResult({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
    required this.hasNext,
  });
}

class PanditPujaService {
  final ApiClient _client = ApiClient();

  Future<List<PanditPujaBooking>> fetchPujas({
    bool completedOnly = false,
  }) async {
    final view = completedOnly ? 'COMPLETED' : 'UPCOMING';
    final response = await _client.get(
      '${ApiConfig.panditUpcomingPujas}?view=$view',
    );
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
          (dynamic item) => PanditPujaBooking.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
    return items;
  }

  Future<PanditPagedResult<PanditPujaBooking>> fetchPujasPage({
    required bool completedOnly,
    required int page,
    int size = 12,
    String search = '',
  }) async {
    final view = completedOnly ? 'COMPLETED' : 'UPCOMING';
    final int safePage = page < 0 ? 0 : page;
    final int safeSize = size <= 0 ? 12 : size;
    final String trimmedSearch = search.trim();
    final response = await _client.get(
      ApiConfig.panditUpcomingPujas,
      queryParameters: <String, dynamic>{
        'view': view,
        'page': safePage,
        'size': safeSize,
        if (trimmedSearch.isNotEmpty) 'search': trimmedSearch,
      },
    );
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
          (dynamic item) => PanditPujaBooking.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
    final int total =
        _readInt(map['count'] ?? map['total'] ?? map['totalCount']) ??
        items.length;
    final bool hasNext =
        _readBool(map['hasNext']) ?? ((safePage + 1) * safeSize < total);
    return PanditPagedResult<PanditPujaBooking>(
      items: items,
      page: _readInt(map['page']) ?? safePage,
      size: _readInt(map['size']) ?? safeSize,
      total: total,
      hasNext: hasNext,
    );
  }

  int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString());
  }

  bool? _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final String text = (value ?? '').toString().trim().toLowerCase();
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
    return null;
  }
}
