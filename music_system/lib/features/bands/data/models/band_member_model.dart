import '../../domain/entities/band_member_entity.dart';

class BandMemberModel extends BandMemberEntity {
  const BandMemberModel({
    required super.userId,
    required super.role,
    required super.status,
    super.instrument,
    super.userName,
    super.userPhotoUrl,
  });

  factory BandMemberModel.fromJson(Map<String, dynamic> json) {
    return BandMemberModel(
      userId: json['userId'] ?? '',
      role: json['role'] ?? 'member',
      status: json['status'] ?? 'pending_invite',
      instrument: json['instrument'],
      userName: json['userName'],
      userPhotoUrl: json['userPhotoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'role': role,
      'status': status,
      'instrument': instrument,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
    };
  }
}
