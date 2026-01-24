import 'package:equatable/equatable.dart';
import '../../domain/entities/song.dart';
import '../../../auth/domain/entities/user_profile.dart';

abstract class RepertoireMenuState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RepertoireMenuInitial extends RepertoireMenuState {}

class RepertoireMenuLoading extends RepertoireMenuState {}

class RepertoireMenuLoaded extends RepertoireMenuState {
  final List<Song> songs;
  final UserProfile? musicianProfile;

  RepertoireMenuLoaded(this.songs, {this.musicianProfile});

  @override
  List<Object?> get props => [songs, musicianProfile];
}

class RepertoireMenuError extends RepertoireMenuState {
  final String message;
  RepertoireMenuError(this.message);

  @override
  List<Object?> get props => [message];
}
