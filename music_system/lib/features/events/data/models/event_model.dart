import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/event_entity.dart';

class EventModel extends EventEntity {
  const EventModel({
    required super.id,
    required super.ownerId,
    required super.title,
    required super.description,
    required super.eventDate,
    required super.status,
    required super.questionnaire,
    required super.hiredProviderIds,
    required super.budgetLimit,
    required super.currentExpenses,
    required super.createdAt,
  });

  factory EventModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'planning',
      questionnaire:
          EventQuestionnaireModel.fromMap(data['questionnaire'] ?? {}),
      hiredProviderIds: List<String>.from(data['hiredProviderIds'] ?? []),
      budgetLimit: (data['budgetLimit'] ?? 0.0).toDouble(),
      currentExpenses: (data['currentExpenses'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toDocument() {
    return {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'eventDate': Timestamp.fromDate(eventDate),
      'status': status,
      'questionnaire':
          EventQuestionnaireModel.fromEntity(questionnaire).toMap(),
      'hiredProviderIds': hiredProviderIds,
      'budgetLimit': budgetLimit,
      'currentExpenses': currentExpenses,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class EventQuestionnaireModel extends EventQuestionnaire {
  const EventQuestionnaireModel({
    super.primaryObjective,
    super.targetAudience,
    super.eventSoul,
    super.monetizationStrategy,
    super.technicalEquip,
    super.staff,
    super.catering,
    super.hasPermits,
    super.hasInsurance,
    super.hasContracts,
    super.visualIdentity,
    super.ticketPlatform,
    super.marketingPlan,
  });

  factory EventQuestionnaireModel.fromMap(Map<String, dynamic> map) {
    return EventQuestionnaireModel(
      primaryObjective: map['primaryObjective'] ?? '',
      targetAudience: map['targetAudience'] ?? '',
      eventSoul: map['eventSoul'] ?? '',
      monetizationStrategy: map['monetizationStrategy'] ?? '',
      technicalEquip: map['technicalEquip'] ?? '',
      staff: map['staff'] ?? '',
      catering: map['catering'] ?? '',
      hasPermits: map['hasPermits'] ?? false,
      hasInsurance: map['hasInsurance'] ?? false,
      hasContracts: map['hasContracts'] ?? false,
      visualIdentity: map['visualIdentity'] ?? '',
      ticketPlatform: map['ticketPlatform'] ?? '',
      marketingPlan: map['marketingPlan'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primaryObjective': primaryObjective,
      'targetAudience': targetAudience,
      'eventSoul': eventSoul,
      'monetizationStrategy': monetizationStrategy,
      'technicalEquip': technicalEquip,
      'staff': staff,
      'catering': catering,
      'hasPermits': hasPermits,
      'hasInsurance': hasInsurance,
      'hasContracts': hasContracts,
      'visualIdentity': visualIdentity,
      'ticketPlatform': ticketPlatform,
      'marketingPlan': marketingPlan,
    };
  }

  factory EventQuestionnaireModel.fromEntity(EventQuestionnaire entity) {
    return EventQuestionnaireModel(
      primaryObjective: entity.primaryObjective,
      targetAudience: entity.targetAudience,
      eventSoul: entity.eventSoul,
      monetizationStrategy: entity.monetizationStrategy,
      technicalEquip: entity.technicalEquip,
      staff: entity.staff,
      catering: entity.catering,
      hasPermits: entity.hasPermits,
      hasInsurance: entity.hasInsurance,
      hasContracts: entity.hasContracts,
      visualIdentity: entity.visualIdentity,
      ticketPlatform: entity.ticketPlatform,
      marketingPlan: entity.marketingPlan,
    );
  }
}
