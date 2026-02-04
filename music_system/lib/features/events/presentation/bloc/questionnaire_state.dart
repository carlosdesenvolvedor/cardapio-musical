import 'package:equatable/equatable.dart';
import '../../domain/entities/event_entity.dart';

class QuestionnaireState extends Equatable {
  final EventQuestionnaire questionnaire;
  final int currentStep;

  const QuestionnaireState({
    this.questionnaire = const EventQuestionnaire(),
    this.currentStep = 0,
  });

  QuestionnaireState copyWith({
    EventQuestionnaire? questionnaire,
    int? currentStep,
  }) {
    return QuestionnaireState(
      questionnaire: questionnaire ?? this.questionnaire,
      currentStep: currentStep ?? this.currentStep,
    );
  }

  @override
  List<Object?> get props => [questionnaire, currentStep];
}
