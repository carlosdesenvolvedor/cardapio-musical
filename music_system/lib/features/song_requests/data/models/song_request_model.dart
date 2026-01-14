import '../../domain/entities/song_request.dart';

class SongRequestModel extends SongRequest {
  const SongRequestModel({
    required super.id,
    required super.songName,
    required super.artistName,
    super.clientName,
    required super.musicianId,
    super.tipAmount,
    super.isCustomRequest,
    super.status,
    required super.createdAt,
  });

  factory SongRequestModel.fromJson(Map<String, dynamic> json, String id) {
    return SongRequestModel(
      id: id,
      songName: json['songName'] ?? '',
      artistName: json['artistName'] ?? '',
      clientName: json['clientName'],
      musicianId: json['musicianId'] ?? '',
      tipAmount: (json['tipAmount'] as num?)?.toDouble() ?? 0.0,
      isCustomRequest: json['isCustomRequest'] ?? false,
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'songName': songName,
      'artistName': artistName,
      'clientName': clientName,
      'musicianId': musicianId,
      'tipAmount': tipAmount,
      'isCustomRequest': isCustomRequest,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
