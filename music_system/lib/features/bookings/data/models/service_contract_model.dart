import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/service_contract_entity.dart';

class ServiceContractModel extends ServiceContractEntity {
  const ServiceContractModel({
    required super.id,
    required super.contractorId,
    required super.contractorName,
    required super.providerId,
    required super.serviceId,
    required super.serviceName,
    required super.price,
    required super.status,
    required super.createdAt,
    super.eventDate,
  });

  factory ServiceContractModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceContractModel(
      id: doc.id,
      contractorId: data['contractorId'] ?? '',
      contractorName: data['contractorName'] ?? 'Contratante',
      providerId: data['providerId'] ?? '',
      serviceId: data['serviceId'] ?? '',
      serviceName: data['serviceName'] ?? 'Serviço',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      status: ContractStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (data['status'] ?? 'pending'),
        orElse: () => ContractStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      eventDate: (data['eventDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'contractorId': contractorId,
      'contractorName': contractorName,
      'providerId': providerId,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'price': price,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      if (eventDate != null) 'eventDate': Timestamp.fromDate(eventDate!),
    };
  }
}
