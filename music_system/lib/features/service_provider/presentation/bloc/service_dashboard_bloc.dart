import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/usecases/get_provider_services.dart';
import '../../domain/usecases/update_service_status.dart';
import '../../domain/usecases/delete_service.dart';

// Events
abstract class ServiceDashboardEvent extends Equatable {
  const ServiceDashboardEvent();

  @override
  List<Object> get props => [];
}

class FetchServices extends ServiceDashboardEvent {
  final String providerId;

  const FetchServices(this.providerId);

  @override
  List<Object> get props => [providerId];
}

class UpdateStatus extends ServiceDashboardEvent {
  final String providerId;
  final String serviceId;
  final ServiceStatus status;

  const UpdateStatus({
    required this.providerId,
    required this.serviceId,
    required this.status,
  });

  @override
  List<Object> get props => [providerId, serviceId, status];
}

class DeleteServiceEvent extends ServiceDashboardEvent {
  final String providerId;
  final String serviceId;

  const DeleteServiceEvent({
    required this.providerId,
    required this.serviceId,
  });

  @override
  List<Object> get props => [providerId, serviceId];
}

// States
abstract class ServiceDashboardState extends Equatable {
  const ServiceDashboardState();

  @override
  List<Object> get props => [];
}

class ServiceDashboardInitial extends ServiceDashboardState {}

class ServiceDashboardLoading extends ServiceDashboardState {}

class ServiceDashboardLoaded extends ServiceDashboardState {
  final List<ServiceEntity> services;

  const ServiceDashboardLoaded(this.services);

  @override
  List<Object> get props => [services];
}

class ServiceDashboardError extends ServiceDashboardState {
  final String message;

  const ServiceDashboardError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc
class ServiceDashboardBloc
    extends Bloc<ServiceDashboardEvent, ServiceDashboardState> {
  final GetProviderServices getProviderServices;
  final UpdateServiceStatus updateServiceStatus;
  final DeleteService deleteService;

  ServiceDashboardBloc({
    required this.getProviderServices,
    required this.updateServiceStatus,
    required this.deleteService,
  }) : super(ServiceDashboardInitial()) {
    on<FetchServices>((event, emit) async {
      emit(ServiceDashboardLoading());
      final result = await getProviderServices(event.providerId);
      result.fold(
        (failure) => emit(ServiceDashboardError(failure.message)),
        (services) => emit(ServiceDashboardLoaded(services)),
      );
    });

    on<UpdateStatus>((event, emit) async {
      final result = await updateServiceStatus(UpdateServiceStatusParams(
        providerId: event.providerId,
        serviceId: event.serviceId,
        status: event.status,
      ));

      result.fold(
        (failure) => emit(ServiceDashboardError(failure.message)),
        (_) => add(FetchServices(event.providerId)),
      );
    });

    on<DeleteServiceEvent>((event, emit) async {
      final result = await deleteService(DeleteServiceParams(
        providerId: event.providerId,
        serviceId: event.serviceId,
      ));

      result.fold(
        (failure) => emit(ServiceDashboardError(failure.message)),
        (_) => add(FetchServices(event.providerId)),
      );
    });
  }
}
