import 'package:equatable/equatable.dart';

class Song extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String? albumCoverUrl;
  final String genre;
  final String musicianId;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    this.albumCoverUrl,
    required this.genre,
    required this.musicianId,
  });

  @override
  List<Object?> get props => [id, title, artist, albumCoverUrl, genre, musicianId];
}
