import 'package:equatable/equatable.dart';

enum ContractStatus { pending, accepted, declined }

class ServiceContractEntity extends Equatable {
  final String id;
  final String contractorId;
  final String contractorName;
  final String providerId;
  final String serviceId;
  final String serviceName;
  final double price;
  final ContractStatus status;
  final DateTime createdAt;
  final DateTime? eventDate;

  const ServiceContractEntity({
    required this.id,
    required this.contractorId,
    required this.contractorName,
    required this.providerId,
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.status,
    required this.createdAt,
    this.eventDate,
  });

  @override
  List<Object?> get props => [
        id,
        contractorId,
        contractorName,
        providerId,
        serviceId,
        serviceName,
        price,
        status,
        createdAt,
        eventDate,
      ];
}
