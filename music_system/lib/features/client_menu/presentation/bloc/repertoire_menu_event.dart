import 'package:equatable/equatable.dart';
import '../../domain/entities/song.dart';

abstract class RepertoireMenuEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchRepertoireMenu extends RepertoireMenuEvent {
  final String musicianId;
  FetchRepertoireMenu(this.musicianId);

  @override
  List<Object?> get props => [musicianId];
}
