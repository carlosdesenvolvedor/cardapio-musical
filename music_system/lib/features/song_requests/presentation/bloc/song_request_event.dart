import 'package:equatable/equatable.dart';
import '../../domain/entities/song_request.dart';

abstract class SongRequestEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CreateSongRequest extends SongRequestEvent {
  final SongRequest request;
  CreateSongRequest(this.request);

  @override
  List<Object?> get props => [request];
}

class FetchSongRequests extends SongRequestEvent {
  final String musicianId;
  FetchSongRequests(this.musicianId);

  @override
  List<Object?> get props => [musicianId];
}

class UpdateSongRequestStatus extends SongRequestEvent {
  final String requestId;
  final String status;
  UpdateSongRequestStatus(this.requestId, this.status);

  @override
  List<Object?> get props => [requestId, status];
}

class DeleteSongRequestEvent extends SongRequestEvent {
  final String requestId;
  DeleteSongRequestEvent(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class SongRequestsUpdated extends SongRequestEvent {
  final List<SongRequest> requests;
  SongRequestsUpdated(this.requests);

  @override
  List<Object?> get props => [requests];
}
