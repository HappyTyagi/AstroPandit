class PanditPujaBooking {
  final int bookingId;
  final int userId;
  final String pujaNumber;
  final String userName;
  final String mobileNumber;
  final String email;
  final int pujaId;
  final String pujaName;
  final String? pujaImage;
  final int? slotId;
  final DateTime? slotTime;
  final DateTime? bookedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String status;
  final String paymentMethod;
  final String transactionId;
  final String packageCode;
  final String packageName;
  final String address;
  final String mapUrl;
  final double? latitude;
  final double? longitude;
  final double totalPrice;
  final String? agoraChannel;

  const PanditPujaBooking({
    required this.bookingId,
    required this.userId,
    required this.pujaNumber,
    required this.userName,
    required this.mobileNumber,
    required this.email,
    required this.pujaId,
    required this.pujaName,
    required this.pujaImage,
    required this.slotId,
    required this.slotTime,
    required this.bookedAt,
    required this.startedAt,
    required this.completedAt,
    required this.status,
    required this.paymentMethod,
    required this.transactionId,
    required this.packageCode,
    required this.packageName,
    required this.address,
    required this.mapUrl,
    required this.latitude,
    required this.longitude,
    required this.totalPrice,
    required this.agoraChannel,
  });

  factory PanditPujaBooking.fromJson(Map<String, dynamic> json) {
    final int bookingId = _readInt(json['bookingId'] ?? json['id']);
    final int userId = _readInt(json['userId']);
    return PanditPujaBooking(
      bookingId: bookingId,
      userId: userId,
      pujaNumber: _readPujaNumber(json, userId: userId, bookingId: bookingId),
      userName: (json['userName'] ?? 'Unknown').toString(),
      mobileNumber: (json['mobileNumber'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      pujaId: _readInt(json['pujaId']),
      pujaName: (json['pujaName'] ?? '').toString(),
      pujaImage: json['pujaImage']?.toString(),
      slotId: _readIntNullable(json['slotId']),
      slotTime: _readDate(json['slotTime']),
      bookedAt: _readDate(json['bookedAt']),
      startedAt: _readDate(json['startedAt']),
      completedAt: _readDate(json['completedAt']),
      status: (json['bookingStatus'] ?? json['status'] ?? '').toString(),
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      transactionId: (json['transactionId'] ?? '').toString(),
      packageCode: (json['packageCode'] ?? 'BASE').toString(),
      packageName: (json['packageName'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      mapUrl: (json['mapUrl'] ?? '').toString(),
      latitude: _readCoordinate(json, <String>[
        'latitude',
        'lat',
        'addressLatitude',
        'addressLat',
        'userLatitude',
        'userLat',
        'locationLatitude',
        'locationLat',
        'geoLatitude',
        'geoLat',
      ]),
      longitude: _readCoordinate(json, <String>[
        'longitude',
        'lng',
        'lon',
        'addressLongitude',
        'addressLng',
        'addressLon',
        'userLongitude',
        'userLng',
        'userLon',
        'locationLongitude',
        'locationLng',
        'geoLongitude',
        'geoLng',
      ]),
      totalPrice: _readDouble(json['totalPrice']),
      agoraChannel: (json['agoraChannel'] ?? json['channelName'])?.toString(),
    );
  }
}

class PujaAgoraLink {
  final bool success;
  final String message;
  final String appId;
  final String token;
  final String channelName;
  final int uid;
  final int? expiresAtEpoch;

  const PujaAgoraLink({
    required this.success,
    required this.message,
    required this.appId,
    required this.token,
    required this.channelName,
    required this.uid,
    required this.expiresAtEpoch,
  });

  factory PujaAgoraLink.fromJson(Map<String, dynamic> json) {
    return PujaAgoraLink(
      success: json['success'] == true || json['status'] == true,
      message: (json['message'] ?? '').toString(),
      appId: (json['appId'] ?? '').toString(),
      token: (json['token'] ?? '').toString(),
      channelName: (json['channelName'] ?? '').toString(),
      uid: _readInt(json['uid']),
      expiresAtEpoch: _readIntNullable(json['expiresAtEpoch']),
    );
  }
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse((value ?? '0').toString()) ?? 0;
}

int? _readIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString());
}

double _readDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse((value ?? '0').toString()) ?? 0.0;
}

DateTime? _readDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

double? _readDoubleNullable(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  final String raw = value.toString().trim();
  if (raw.isEmpty || raw.toLowerCase() == 'null') return null;
  return double.tryParse(raw);
}

double? _readCoordinate(Map<String, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final double? value = _readDoubleNullable(json[key]);
    if (value != null) return value;
  }
  return null;
}

String _readPujaNumber(
  Map<String, dynamic> json, {
  required int userId,
  required int bookingId,
}) {
  final List<dynamic> candidates = <dynamic>[
    json['pujaNumber'],
    json['bookingNumber'],
    json['bookingCode'],
    json['bookingDisplayId'],
    json['displayBookingId'],
    json['orderCode'],
    json['orderId'],
    json['invoiceNumber'],
  ];

  for (final dynamic candidate in candidates) {
    final String raw = (candidate ?? '').toString().trim();
    if (raw.isEmpty || raw.toLowerCase() == 'null') continue;
    return _normalizePujaNumber(raw, userId: userId, bookingId: bookingId);
  }
  return _buildPujaOrderId(userId: userId, bookingId: bookingId);
}

String _normalizePujaNumber(
  String raw, {
  required int userId,
  required int bookingId,
}) {
  final String normalized = raw.trim().toUpperCase();
  if (normalized.isEmpty) {
    return _buildPujaOrderId(userId: userId, bookingId: bookingId);
  }
  if (normalized.startsWith('PUJA-U') && normalized.contains('-B')) {
    return normalized;
  }
  if (normalized.startsWith('PUJA-')) {
    final int? numericId = int.tryParse(
      normalized.replaceFirst('PUJA-', '').trim(),
    );
    if (numericId != null) {
      return _buildPujaOrderId(userId: userId, bookingId: numericId);
    }
  }
  final int? standaloneNumericId = int.tryParse(normalized);
  if (standaloneNumericId != null) {
    return _buildPujaOrderId(userId: userId, bookingId: standaloneNumericId);
  }
  return raw.trim();
}

String _buildPujaOrderId({required int userId, required int bookingId}) {
  final String userCode = (userId < 0 ? 0 : userId).toString().padLeft(5, '0');
  final String bookingCode = (bookingId < 0 ? 0 : bookingId).toString().padLeft(
    6,
    '0',
  );
  return 'PUJA-U$userCode-B$bookingCode';
}
