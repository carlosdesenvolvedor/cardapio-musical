import '../../domain/entities/song.dart';

class SongModel extends Song {
  const SongModel({
    required super.id,
    required super.title,
    required super.artist,
    super.albumCoverUrl,
    required super.genre,
    required super.musicianId,
  });

  factory SongModel.fromJson(Map<String, dynamic> json, String id) {
    return SongModel(
      id: id,
      title: json['title'] ?? '',
      artist: json['artist'] ?? '',
      albumCoverUrl: json['albumCoverUrl'],
      genre: json['genre'] ?? 'Other',
      musicianId: json['musicianId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'artist': artist,
      'albumCoverUrl': albumCoverUrl,
      'genre': genre,
      'musicianId': musicianId,
    };
  }
}
