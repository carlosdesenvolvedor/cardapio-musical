import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/event_entity.dart';
import 'questionnaire_event.dart';
import 'questionnaire_state.dart';

class QuestionnaireBloc extends Bloc<QuestionnaireEvent, QuestionnaireState> {
  QuestionnaireBloc() : super(const QuestionnaireState()) {
    on<QuestionnaireFieldChanged>(_onFieldChanged);
  }

  void _onFieldChanged(
      QuestionnaireFieldChanged event, Emitter<QuestionnaireState> emit) {
    final q = state.questionnaire;
    EventQuestionnaire newQ = q;

    switch (event.field) {
      case 'primaryObjective':
        newQ = _update(q, primaryObjective: event.value);
        break;
      case 'targetAudience':
        newQ = _update(q, targetAudience: event.value);
        break;
      case 'eventSoul':
        newQ = _update(q, eventSoul: event.value);
        break;
      case 'monetizationStrategy':
        newQ = _update(q, monetizationStrategy: event.value);
        break;
      case 'technicalEquip':
        newQ = _update(q, technicalEquip: event.value);
        break;
      case 'staff':
        newQ = _update(q, staff: event.value);
        break;
      case 'catering':
        newQ = _update(q, catering: event.value);
        break;
      case 'hasPermits':
        newQ = _update(q, hasPermits: event.value);
        break;
      case 'hasInsurance':
        newQ = _update(q, hasInsurance: event.value);
        break;
      case 'hasContracts':
        newQ = _update(q, hasContracts: event.value);
        break;
      case 'visualIdentity':
        newQ = _update(q, visualIdentity: event.value);
        break;
      case 'ticketPlatform':
        newQ = _update(q, ticketPlatform: event.value);
        break;
      case 'marketingPlan':
        newQ = _update(q, marketingPlan: event.value);
        break;
    }

    emit(state.copyWith(questionnaire: newQ));
  }

  EventQuestionnaire _update(
    EventQuestionnaire q, {
    String? primaryObjective,
    String? targetAudience,
    String? eventSoul,
    String? monetizationStrategy,
    String? technicalEquip,
    String? staff,
    String? catering,
    bool? hasPermits,
    bool? hasInsurance,
    bool? hasContracts,
    String? visualIdentity,
    String? ticketPlatform,
    String? marketingPlan,
  }) {
    return EventQuestionnaire(
      primaryObjective: primaryObjective ?? q.primaryObjective,
      targetAudience: targetAudience ?? q.targetAudience,
      eventSoul: eventSoul ?? q.eventSoul,
      monetizationStrategy: monetizationStrategy ?? q.monetizationStrategy,
      technicalEquip: technicalEquip ?? q.technicalEquip,
      staff: staff ?? q.staff,
      catering: catering ?? q.catering,
      hasPermits: hasPermits ?? q.hasPermits,
      hasInsurance: hasInsurance ?? q.hasInsurance,
      hasContracts: hasContracts ?? q.hasContracts,
      visualIdentity: visualIdentity ?? q.visualIdentity,
      ticketPlatform: ticketPlatform ?? q.ticketPlatform,
      marketingPlan: marketingPlan ?? q.marketingPlan,
    );
  }
}
