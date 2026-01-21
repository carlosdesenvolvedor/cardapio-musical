import 'package:equatable/equatable.dart';

class BandMemberEntity extends Equatable {
  final String userId;
  final String role; // leader, member
  final String status; // active, pending_invite, rejected
  final String? instrument;
  final String? userName;
  final String? userPhotoUrl;

  const BandMemberEntity({
    required this.userId,
    required this.role,
    required this.status,
    this.instrument,
    this.userName,
    this.userPhotoUrl,
  });

  @override
  List<Object?> get props =>
      [userId, role, status, instrument, userName, userPhotoUrl];
}
