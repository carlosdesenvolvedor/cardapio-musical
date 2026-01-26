import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_request.dart';
import '../../domain/usecases/stream_requests.dart';
import '../../domain/usecases/update_request_status.dart';
import '../../domain/usecases/notify_musician.dart';
import '../../domain/usecases/delete_request.dart';
import 'song_request_event.dart';
import 'song_request_state.dart';

class SongRequestBloc extends Bloc<SongRequestEvent, SongRequestState> {
  final CreateRequest createRequest;
  final StreamRequests streamRequests;
  final UpdateRequestStatus updateRequestStatus;
  final NotifyMusician notifyMusician;
  final DeleteRequest deleteRequest;
  StreamSubscription? _subscription;

  SongRequestBloc({
    required this.createRequest,
    required this.streamRequests,
    required this.updateRequestStatus,
    required this.notifyMusician,
    required this.deleteRequest,
  }) : super(SongRequestInitial()) {
    on<CreateSongRequest>(_onCreateRequest);
    on<FetchSongRequests>(_onFetchRequests);
    on<UpdateSongRequestStatus>(_onUpdateRequestStatus);
    on<SongRequestsUpdated>(_onRequestsUpdated);
    on<DeleteSongRequestEvent>(_onDeleteRequest);
  }

  Future<void> _onCreateRequest(
      CreateSongRequest event, Emitter<SongRequestState> emit) async {
    emit(SongRequestLoading());
    final result = await createRequest(event.request);

    await result.fold(
      (failure) async => emit(SongRequestError(failure.message)),
      (_) async {
        // After creating the request in Firestore, trigger the notification
        await notifyMusician(NotifyMusicianParams(
          musicianId: event.request.musicianId,
          songName: event.request.songName,
        ));
        emit(SongRequestSuccess());
      },
    );
  }

  Future<void> _onFetchRequests(
      FetchSongRequests event, Emitter<SongRequestState> emit) async {
    emit(SongRequestLoading());
    _subscription?.cancel();
    _subscription = streamRequests(event.musicianId).listen((result) {
      result.fold(
        (failure) => add(SongRequestsUpdated(const [])), // or error event
        (requests) => add(SongRequestsUpdated(requests)),
      );
    });
  }

  Future<void> _onUpdateRequestStatus(
      UpdateSongRequestStatus event, Emitter<SongRequestState> emit) async {
    final result = await updateRequestStatus(UpdateRequestStatusParams(
      requestId: event.requestId,
      status: event.status,
    ));
    result.fold(
      (failure) => emit(SongRequestError(failure.message)),
      (_) => null, // Success handled by stream
    );
  }

  Future<void> _onDeleteRequest(
      DeleteSongRequestEvent event, Emitter<SongRequestState> emit) async {
    final result =
        await deleteRequest(DeleteRequestParams(requestId: event.requestId));
    result.fold(
      (failure) => emit(SongRequestError(failure.message)),
      (_) => null, // Success handled by stream
    );
  }

  void _onRequestsUpdated(
      SongRequestsUpdated event, Emitter<SongRequestState> emit) {
    emit(SongRequestsLoaded(event.requests));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
