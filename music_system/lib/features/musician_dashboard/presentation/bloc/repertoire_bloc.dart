import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/import_repertoire.dart';
import '../../domain/usecases/add_song_to_repertoire.dart';
import '../../domain/usecases/get_musician_songs.dart';
import '../../domain/usecases/update_song.dart';
import '../../domain/usecases/delete_song.dart';
import '../../../client_menu/domain/entities/song.dart';

// Events
abstract class RepertoireEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartImportEvent extends RepertoireEvent {
  final Uint8List fileBytes;
  final String musicianId;
  StartImportEvent(this.fileBytes, this.musicianId);
  @override
  List<Object?> get props => [fileBytes, musicianId];
}

class AddSongEvent extends RepertoireEvent {
  final Song song;
  AddSongEvent(this.song);
  @override
  List<Object?> get props => [song];
}

class LoadRepertoireEvent extends RepertoireEvent {
  final String musicianId;
  LoadRepertoireEvent(this.musicianId);
}

class UpdateSongEvent extends RepertoireEvent {
  final Song song;
  UpdateSongEvent(this.song);
}

class DeleteSongEvent extends RepertoireEvent {
  final String songId;
  DeleteSongEvent(this.songId);
}

// States
abstract class RepertoireState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RepertoireInitial extends RepertoireState {}
class RepertoireLoading extends RepertoireState {}
class RepertoireLoaded extends RepertoireState {
  final List<Song> songs;
  RepertoireLoaded(this.songs);
}
class RepertoireOperationSuccess extends RepertoireState {
   final String message;
   RepertoireOperationSuccess(this.message);
}
class RepertoireError extends RepertoireState {
  final String message;
  RepertoireError(this.message);
  @override
  List<Object?> get props => [message];
}

// Bloc
class RepertoireBloc extends Bloc<RepertoireEvent, RepertoireState> {
  final ImportRepertoire importRepertoire;
  final AddSongToRepertoire addSongToRepertoire;
  final GetMusicianSongs getMusicianSongs;
  final UpdateSong updateSong;
  final DeleteSong deleteSong;

  RepertoireBloc({
    required this.importRepertoire,
    required this.addSongToRepertoire,
    required this.getMusicianSongs,
    required this.updateSong,
    required this.deleteSong,
  }) : super(RepertoireInitial()) {
    on<StartImportEvent>((event, emit) async {
      emit(RepertoireLoading());
      final result = await importRepertoire(ImportRepertoireParams(
        fileBytes: event.fileBytes,
        musicianId: event.musicianId,
      ));
      result.fold(
        (failure) => emit(RepertoireError(failure.message)),
        (_) => emit(RepertoireOperationSuccess('Importação concluída!')),
      );
    });

    on<AddSongEvent>((event, emit) async {
      emit(RepertoireLoading());
      final result = await addSongToRepertoire(event.song);
      result.fold(
        (failure) => emit(RepertoireError(failure.message)),
        (_) => emit(RepertoireOperationSuccess('Música adicionada!')),
      );
    });

    on<LoadRepertoireEvent>((event, emit) async {
      emit(RepertoireLoading());
      final result = await getMusicianSongs(event.musicianId);
      result.fold(
        (failure) => emit(RepertoireError(failure.message)),
        (songs) => emit(RepertoireLoaded(songs)),
      );
    });

    on<UpdateSongEvent>((event, emit) async {
      emit(RepertoireLoading());
      final result = await updateSong(event.song);
      result.fold(
        (failure) => emit(RepertoireError(failure.message)),
        (_) => emit(RepertoireOperationSuccess('Música atualizada!')),
      );
    });

    on<DeleteSongEvent>((event, emit) async {
      emit(RepertoireLoading());
      final result = await deleteSong(event.songId);
      result.fold(
        (failure) => emit(RepertoireError(failure.message)),
        (_) => emit(RepertoireOperationSuccess('Música excluída!')),
      );
    });
  }
}
