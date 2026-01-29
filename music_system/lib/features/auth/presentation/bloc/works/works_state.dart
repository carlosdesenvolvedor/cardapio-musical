import 'package:equatable/equatable.dart';
import '../../../domain/entities/work.dart';

abstract class WorksState extends Equatable {
  const WorksState();

  @override
  List<Object?> get props => [];
}

class WorksInitial extends WorksState {}

class WorksLoading extends WorksState {}

class WorksLoaded extends WorksState {
  final List<Work> works;

  const WorksLoaded(this.works);

  @override
  List<Object?> get props => [works];
}

class WorksOperationSuccess extends WorksState {
  final String message;

  const WorksOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class WorksError extends WorksState {
  final String message;

  const WorksError(this.message);

  @override
  List<Object?> get props => [message];
}
