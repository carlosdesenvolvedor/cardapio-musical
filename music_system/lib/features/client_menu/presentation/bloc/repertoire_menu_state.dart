import 'package:equatable/equatable.dart';
import '../../domain/entities/song.dart';

abstract class RepertoireMenuState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RepertoireMenuInitial extends RepertoireMenuState {}
class RepertoireMenuLoading extends RepertoireMenuState {}
class RepertoireMenuLoaded extends RepertoireMenuState {
  final List<Song> songs;
  RepertoireMenuLoaded(this.songs);

  @override
  List<Object?> get props => [songs];
}
class RepertoireMenuError extends RepertoireMenuState {
  final String message;
  RepertoireMenuError(this.message);

  @override
  List<Object?> get props => [message];
}
