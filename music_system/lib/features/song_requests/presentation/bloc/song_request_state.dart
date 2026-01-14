import 'package:equatable/equatable.dart';
import '../../domain/entities/song_request.dart';

abstract class SongRequestState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SongRequestInitial extends SongRequestState {}

class SongRequestLoading extends SongRequestState {}

class SongRequestsLoaded extends SongRequestState {
  final List<SongRequest> requests;
  SongRequestsLoaded(this.requests);

  @override
  List<Object?> get props => [requests];
}

class SongRequestError extends SongRequestState {
  final String message;
  SongRequestError(this.message);

  @override
  List<Object?> get props => [message];
}

class SongRequestSuccess extends SongRequestState {}
