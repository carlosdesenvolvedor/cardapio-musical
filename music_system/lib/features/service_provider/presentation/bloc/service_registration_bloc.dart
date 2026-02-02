import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/usecases/register_service.dart';
import '../../domain/usecases/update_service.dart';

// Events
abstract class ServiceRegistrationEvent extends Equatable {
  const ServiceRegistrationEvent();

  @override
  List<Object> get props => [];
}

class SubmitRegistration extends ServiceRegistrationEvent {
  final ServiceEntity service;

  const SubmitRegistration(this.service);

  @override
  List<Object> get props => [service];
}

class SubmitUpdate extends ServiceRegistrationEvent {
  final ServiceEntity service;

  const SubmitUpdate(this.service);

  @override
  List<Object> get props => [service];
}

// States
abstract class ServiceRegistrationState extends Equatable {
  const ServiceRegistrationState();

  @override
  List<Object> get props => [];
}

class ServiceRegistrationInitial extends ServiceRegistrationState {}

class ServiceRegistrationLoading extends ServiceRegistrationState {}

class ServiceRegistrationSuccess extends ServiceRegistrationState {}

class ServiceRegistrationFailure extends ServiceRegistrationState {
  final String message;

  const ServiceRegistrationFailure(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc
class ServiceRegistrationBloc
    extends Bloc<ServiceRegistrationEvent, ServiceRegistrationState> {
  final RegisterService registerService;
  final UpdateService updateService;

  ServiceRegistrationBloc({
    required this.registerService,
    required this.updateService,
  }) : super(ServiceRegistrationInitial()) {
    on<SubmitRegistration>((event, emit) async {
      emit(ServiceRegistrationLoading());
      final result = await registerService(event.service);
      result.fold(
        (failure) => emit(ServiceRegistrationFailure(failure.message)),
        (_) => emit(ServiceRegistrationSuccess()),
      );
    });

    on<SubmitUpdate>((event, emit) async {
      emit(ServiceRegistrationLoading());
      final result = await updateService(event.service);
      result.fold(
        (failure) => emit(ServiceRegistrationFailure(failure.message)),
        (_) => emit(ServiceRegistrationSuccess()),
      );
    });
  }
}
