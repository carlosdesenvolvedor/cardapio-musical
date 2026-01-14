import '../../domain/entities/lyrics.dart';

class LyricsModel extends Lyrics {
  const LyricsModel({
    required super.songName,
    required super.artist,
    required super.content,
    super.isVip,
  });

  factory LyricsModel.fromJson(Map<String, dynamic> json) {
    return LyricsModel(
      songName: json['songName'] ?? '',
      artist: json['artist'] ?? '',
      content: json['content'] ?? '',
      isVip: json['isVip'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'songName': songName,
      'artist': artist,
      'content': content,
      'isVip': isVip,
    };
  }
}
