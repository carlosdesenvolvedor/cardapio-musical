import 'package:equatable/equatable.dart';

abstract class QuestionnaireEvent extends Equatable {
  const QuestionnaireEvent();
  @override
  List<Object?> get props => [];
}

class QuestionnaireFieldChanged extends QuestionnaireEvent {
  final String field;
  final dynamic value;

  const QuestionnaireFieldChanged(this.field, this.value);

  @override
  List<Object?> get props => [field, value];
}
