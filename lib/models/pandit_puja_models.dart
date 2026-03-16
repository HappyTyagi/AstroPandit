class PanditPujaBooking {
  final int bookingId;
  final int userId;
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
  final double totalPrice;
  final String? agoraChannel;

  const PanditPujaBooking({
    required this.bookingId,
    required this.userId,
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
    required this.totalPrice,
    required this.agoraChannel,
  });

  factory PanditPujaBooking.fromJson(Map<String, dynamic> json) {
    return PanditPujaBooking(
      bookingId: _readInt(json['bookingId'] ?? json['id']),
      userId: _readInt(json['userId']),
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
