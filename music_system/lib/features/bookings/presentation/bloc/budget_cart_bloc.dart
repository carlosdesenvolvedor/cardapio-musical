import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../service_provider/domain/entities/service_entity.dart';

// Events
abstract class BudgetCartEvent extends Equatable {
  const BudgetCartEvent();
  @override
  List<Object?> get props => [];
}

class AddServiceToCart extends BudgetCartEvent {
  final ServiceEntity service;
  const AddServiceToCart(this.service);
  @override
  List<Object?> get props => [service];
}

class RemoveServiceFromCart extends BudgetCartEvent {
  final String serviceId;
  const RemoveServiceFromCart(this.serviceId);
  @override
  List<Object?> get props => [serviceId];
}

class ClearBudgetCart extends BudgetCartEvent {}

// State
class BudgetCartState extends Equatable {
  final List<ServiceEntity> items;

  const BudgetCartState({this.items = const []});

  @override
  List<Object?> get props => [items];
}

// Bloc
class BudgetCartBloc extends Bloc<BudgetCartEvent, BudgetCartState> {
  BudgetCartBloc() : super(const BudgetCartState()) {
    on<AddServiceToCart>((event, emit) {
      if (!state.items.any((item) => item.id == event.service.id)) {
        emit(BudgetCartState(items: [...state.items, event.service]));
      }
    });

    on<RemoveServiceFromCart>((event, emit) {
      emit(BudgetCartState(
        items: state.items.where((item) => item.id != event.serviceId).toList(),
      ));
    });

    on<ClearBudgetCart>((event, emit) {
      emit(const BudgetCartState(items: []));
    });
  }
}
