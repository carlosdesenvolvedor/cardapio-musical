import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/work_repository.dart';
import 'works_event.dart';
import 'works_state.dart';

class WorksBloc extends Bloc<WorksEvent, WorksState> {
  final WorkRepository repository;

  WorksBloc({required this.repository}) : super(WorksInitial()) {
    on<LoadWorks>(_onLoadWorks);
    on<AddWork>(_onAddWork);
    on<UpdateWork>(_onUpdateWork);
    on<DeleteWork>(_onDeleteWork);
  }

  Future<void> _onLoadWorks(LoadWorks event, Emitter<WorksState> emit) async {
    emit(WorksLoading());
    final result = await repository.getWorks(event.userId);
    result.fold(
      (failure) => emit(WorksError(failure.message)),
      (works) => emit(WorksLoaded(works)),
    );
  }

  Future<void> _onAddWork(AddWork event, Emitter<WorksState> emit) async {
    emit(WorksLoading());
    final result = await repository.addWork(event.work, event.file);
    result.fold(
      (failure) => emit(WorksError(failure.message)),
      (_) {
        emit(const WorksOperationSuccess('Trabalho adicionado com sucesso!'));
        add(LoadWorks(event.work.userId));
      },
    );
  }

  Future<void> _onUpdateWork(UpdateWork event, Emitter<WorksState> emit) async {
    emit(WorksLoading());
    final result = await repository.updateWork(event.work);
    result.fold(
      (failure) => emit(WorksError(failure.message)),
      (_) {
        emit(const WorksOperationSuccess('Trabalho atualizado com sucesso!'));
        add(LoadWorks(event.work.userId));
      },
    );
  }

  Future<void> _onDeleteWork(DeleteWork event, Emitter<WorksState> emit) async {
    emit(WorksLoading());
    final result = await repository.deleteWork(event.workId, event.userId);
    result.fold(
      (failure) => emit(WorksError(failure.message)),
      (_) {
        emit(const WorksOperationSuccess('Trabalho removido com sucesso!'));
        add(LoadWorks(event.userId));
      },
    );
  }
}
