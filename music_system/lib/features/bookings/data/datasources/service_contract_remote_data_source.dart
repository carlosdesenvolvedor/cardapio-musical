import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_contract_model.dart';
import '../../domain/entities/service_contract_entity.dart';

class ServiceContractRemoteDataSource {
  final FirebaseFirestore firestore;

  ServiceContractRemoteDataSource({required this.firestore});

  Future<void> createContract(ServiceContractModel contract) async {
    await firestore
        .collection('service_contracts')
        .doc(contract.id.isEmpty ? null : contract.id)
        .set(contract.toFirestore());
  }

  Future<void> updateContractStatus(
      String contractId, ContractStatus status) async {
    await firestore.collection('service_contracts').doc(contractId).update({
      'status': status.toString().split('.').last,
    });
  }

  Stream<List<ServiceContractModel>> streamProviderContracts(
      String providerId) {
    return firestore
        .collection('service_contracts')
        .where('providerId', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ServiceContractModel.fromFirestore(doc))
            .toList());
  }
}
