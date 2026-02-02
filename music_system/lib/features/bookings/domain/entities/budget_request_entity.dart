import 'package:equatable/equatable.dart';
import '../../../service_provider/domain/entities/service_entity.dart';

enum BudgetRequestStatus {
  pending,
  partially_responded,
  completed,
  cancelled,
}

class BudgetRequestEntity extends Equatable {
  final String id;
  final String contractorId;
  final List<ServiceEntity> items;
  final DateTime createdAt;
  final BudgetRequestStatus status;
  final String? eventName;
  final DateTime? eventDate;

  const BudgetRequestEntity({
    required this.id,
    required this.contractorId,
    required this.items,
    required this.createdAt,
    required this.status,
    this.eventName,
    this.eventDate,
  });

  @override
  List<Object?> get props => [
        id,
        contractorId,
        items,
        createdAt,
        status,
        eventName,
        eventDate,
      ];
}
