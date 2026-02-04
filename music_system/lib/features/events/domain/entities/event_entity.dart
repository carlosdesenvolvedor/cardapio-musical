import 'package:equatable/equatable.dart';

class EventEntity extends Equatable {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final DateTime eventDate;
  final String status; // 'planning', 'confirmed', 'cancelled', 'completed'
  final EventQuestionnaire questionnaire;
  final List<String> hiredProviderIds;
  final double budgetLimit;
  final double currentExpenses;
  final DateTime createdAt;

  const EventEntity({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.status,
    required this.questionnaire,
    required this.hiredProviderIds,
    required this.budgetLimit,
    required this.currentExpenses,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        ownerId,
        title,
        description,
        eventDate,
        status,
        questionnaire,
        hiredProviderIds,
        budgetLimit,
        currentExpenses,
        createdAt,
      ];
}

class EventQuestionnaire extends Equatable {
  // Objetivos
  final String primaryObjective;
  final String targetAudience;
  final String eventSoul;
  final String monetizationStrategy;

  // Logística/Infra
  final String technicalEquip;
  final String staff;
  final String catering;

  // Jurídico/Segurança
  final bool hasPermits;
  final bool hasInsurance;
  final bool hasContracts;

  // Comunicação/Vendas
  final String visualIdentity;
  final String ticketPlatform;
  final String marketingPlan;

  const EventQuestionnaire({
    this.primaryObjective = '',
    this.targetAudience = '',
    this.eventSoul = '',
    this.monetizationStrategy = '',
    this.technicalEquip = '',
    this.staff = '',
    this.catering = '',
    this.hasPermits = false,
    this.hasInsurance = false,
    this.hasContracts = false,
    this.visualIdentity = '',
    this.ticketPlatform = '',
    this.marketingPlan = '',
  });

  @override
  List<Object?> get props => [
        primaryObjective,
        targetAudience,
        eventSoul,
        monetizationStrategy,
        technicalEquip,
        staff,
        catering,
        hasPermits,
        hasInsurance,
        hasContracts,
        visualIdentity,
        ticketPlatform,
        marketingPlan,
      ];
}
