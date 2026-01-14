import 'package:equatable/equatable.dart';

class Lyrics extends Equatable {
  final String songName;
  final String artist;
  final String content; // Text with chords
  final bool isVip; // If it's a premium/verified lyric

  const Lyrics({
    required this.songName,
    required this.artist,
    required this.content,
    this.isVip = false,
  });

  @override
  List<Object?> get props => [songName, artist, content, isVip];
}
