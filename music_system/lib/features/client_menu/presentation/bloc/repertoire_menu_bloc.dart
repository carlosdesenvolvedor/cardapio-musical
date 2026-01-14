import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_songs.dart';
import 'repertoire_menu_event.dart';
import 'repertoire_menu_state.dart';

class RepertoireMenuBloc extends Bloc<RepertoireMenuEvent, RepertoireMenuState> {
  final GetSongs getSongs;

  RepertoireMenuBloc({required this.getSongs}) : super(RepertoireMenuInitial()) {
    on<FetchRepertoireMenu>((event, emit) async {
      emit(RepertoireMenuLoading());
      final result = await getSongs(event.musicianId);
      result.fold(
        (failure) => emit(RepertoireMenuError(failure.message)),
        (songs) => emit(RepertoireMenuLoaded(songs)),
      );
    });
  }
}
