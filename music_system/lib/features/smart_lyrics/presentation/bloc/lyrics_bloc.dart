import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/lyrics.dart';
import '../../domain/usecases/get_lyrics.dart';

// Events
abstract class LyricsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchLyricsEvent extends LyricsEvent {
  final String songName;
  final String artist;

  FetchLyricsEvent({required this.songName, required this.artist});

  @override
  List<Object?> get props => [songName, artist];
}

// States
abstract class LyricsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LyricsInitial extends LyricsState {}
class LyricsLoading extends LyricsState {}
class LyricsLoaded extends LyricsState {
  final Lyrics lyrics;
  LyricsLoaded(this.lyrics);
  @override
  List<Object?> get props => [lyrics];
}
class LyricsError extends LyricsState {
  final String message;
  LyricsError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class LyricsBloc extends Bloc<LyricsEvent, LyricsState> {
  final GetLyrics getLyrics;

  LyricsBloc({required this.getLyrics}) : super(LyricsInitial()) {
    on<FetchLyricsEvent>((event, emit) async {
      emit(LyricsLoading());
      final result = await getLyrics(GetLyricsParams(
        songName: event.songName,
        artist: event.artist,
      ));
      result.fold(
        (failure) => emit(LyricsError(failure.message)),
        (lyrics) => emit(LyricsLoaded(lyrics)),
      );
    });
  }
}
