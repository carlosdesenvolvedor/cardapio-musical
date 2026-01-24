import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../domain/usecases/get_songs.dart';
import '../../domain/entities/song.dart';
import 'repertoire_menu_event.dart';
import 'repertoire_menu_state.dart';

class RepertoireMenuBloc
    extends Bloc<RepertoireMenuEvent, RepertoireMenuState> {
  final GetSongs getSongs;
  final AuthRepository authRepository;

  RepertoireMenuBloc({
    required this.getSongs,
    required this.authRepository,
  }) : super(RepertoireMenuInitial()) {
    on<FetchRepertoireMenu>((event, emit) async {
      emit(RepertoireMenuLoading());

      try {
        // Fetch songs and profile in parallel
        final results = await Future.wait([
          getSongs(event.musicianId),
          authRepository.getProfile(event.musicianId),
        ]);

        final songsResult = results[0] as Either<Failure, List<Song>>;
        final profileResult = results[1] as Either<Failure, UserProfile>;

        UserProfile? profile;
        profileResult.fold(
          (failure) {
            debugPrint(
                'RepertoireMenuBloc: Profile fetch error: ${failure.message}');
          },
          (p) {
            debugPrint(
                'RepertoireMenuBloc: Profile fetched: ${p.artisticName}, ID: ${p.id}');
            profile = p;
          },
        );

        songsResult.fold(
          (failure) {
            // If we have the profile, we can still show the menu even if songs fail
            if (profile != null) {
              emit(RepertoireMenuLoaded(const [], musicianProfile: profile));
            } else {
              emit(RepertoireMenuError(failure.message));
            }
          },
          (songs) {
            emit(RepertoireMenuLoaded(songs, musicianProfile: profile));
          },
        );
      } catch (e) {
        emit(RepertoireMenuError(e.toString()));
      }
    });
  }
}
