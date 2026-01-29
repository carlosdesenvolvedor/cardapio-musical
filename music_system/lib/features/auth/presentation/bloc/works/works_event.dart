import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/work.dart';

abstract class WorksEvent extends Equatable {
  const WorksEvent();

  @override
  List<Object?> get props => [];
}

class LoadWorks extends WorksEvent {
  final String userId;

  const LoadWorks(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AddWork extends WorksEvent {
  final Work work;
  final File? file;

  const AddWork(this.work, this.file);

  @override
  List<Object?> get props => [work, file];
}

class UpdateWork extends WorksEvent {
  final Work work;

  const UpdateWork(this.work);

  @override
  List<Object?> get props => [work];
}

class DeleteWork extends WorksEvent {
  final String workId;
  final String userId;

  const DeleteWork(this.workId, this.userId);

  @override
  List<Object?> get props => [workId, userId];
}
