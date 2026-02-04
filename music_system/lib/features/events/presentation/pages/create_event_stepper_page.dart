import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_theme.dart';
import '../bloc/questionnaire_bloc.dart';
import '../bloc/questionnaire_event.dart';
import '../bloc/questionnaire_state.dart';
import '../bloc/event_bloc.dart';
import '../bloc/event_event.dart';
import '../../domain/entities/event_entity.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import 'package:uuid/uuid.dart';

class CreateEventStepperPage extends StatefulWidget {
  const CreateEventStepperPage({super.key});

  @override
  State<CreateEventStepperPage> createState() => _CreateEventStepperPageState();
}

class _CreateEventStepperPageState extends State<CreateEventStepperPage> {
  int _currentStep = 0;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => QuestionnaireBloc(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('NOVO EVENTO',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        body: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(primary: AppTheme.primaryColor),
          ),
          child: BlocBuilder<QuestionnaireBloc, QuestionnaireState>(
            builder: (context, state) {
              return Stepper(
                type: StepperType.vertical,
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < 5) {
                    setState(() => _currentStep++);
                  } else {
                    _finishCreation(context, state);
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) setState(() => _currentStep--);
                },
                controlsBuilder: (context, controls) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: controls.onStepContinue,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.black),
                          child:
                              Text(_currentStep == 5 ? 'FINALIZAR' : 'PRÓXIMO'),
                        ),
                        if (_currentStep > 0)
                          TextButton(
                            onPressed: controls.onStepCancel,
                            child: const Text('VOLTAR',
                                style: TextStyle(color: Colors.white54)),
                          ),
                      ],
                    ),
                  );
                },
                steps: [
                  Step(
                    title: const Text('Informações Básicas'),
                    isActive: _currentStep >= 0,
                    content: Column(
                      children: [
                        _buildTextField(_titleController, 'Nome do Evento'),
                        const SizedBox(height: 12),
                        _buildTextField(_descController, 'Descrição',
                            maxLines: 3),
                        const SizedBox(height: 12),
                        ListTile(
                          title: const Text('Data do Evento',
                              style: TextStyle(color: Colors.white70)),
                          subtitle: Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: const TextStyle(
                                  color: AppTheme.primaryColor)),
                          trailing: const Icon(Icons.calendar_today,
                              color: AppTheme.primaryColor),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null)
                              setState(() => _selectedDate = date);
                          },
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('Objetivos & Público'),
                    isActive: _currentStep >= 1,
                    content: Column(
                      children: [
                        _buildQuestionField(context, 'primaryObjective',
                            'Qual o objetivo principal?'),
                        _buildQuestionField(context, 'targetAudience',
                            'Quem é o público-alvo?'),
                        _buildQuestionField(
                            context, 'eventSoul', 'Qual a "alma" do evento?'),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('Logística'),
                    isActive: _currentStep >= 2,
                    content: Column(
                      children: [
                        _buildQuestionField(context, 'technicalEquip',
                            'Equipamento Técnico (Som, luz...)'),
                        _buildQuestionField(
                            context, 'staff', 'Staff necessário'),
                        _buildQuestionField(
                            context, 'catering', 'Catering/Alimentação'),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('Segurança & Jurídico'),
                    isActive: _currentStep >= 3,
                    content: Column(
                      children: [
                        _buildSwitchField(context, 'hasPermits',
                            'Possui Alvarás e Licenças?'),
                        _buildSwitchField(
                            context, 'hasInsurance', 'Possui Seguros?'),
                        _buildSwitchField(context, 'hasContracts',
                            'Contratos com fornecedores?'),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('Comunicação'),
                    isActive: _currentStep >= 4,
                    content: Column(
                      children: [
                        _buildQuestionField(
                            context, 'visualIdentity', 'Identidade Visual'),
                        _buildQuestionField(context, 'ticketPlatform',
                            'Plataforma de Ingressos'),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('Financeiro'),
                    isActive: _currentStep >= 5,
                    content: Column(
                      children: [
                        _buildTextField(
                            _budgetController, 'Orçamento Limite (R\$)',
                            isNumeric: true),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1, bool isNumeric = false}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white10)),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.primaryColor)),
      ),
    );
  }

  Widget _buildQuestionField(BuildContext context, String field, String label,
      {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        onChanged: (val) {
          context
              .read<QuestionnaireBloc>()
              .add(QuestionnaireFieldChanged(field, val));
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
          enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white10)),
        ),
      ),
    );
  }

  Widget _buildSwitchField(BuildContext context, String field, String label) {
    final state = context.watch<QuestionnaireBloc>().state;
    bool value = false;
    if (field == 'hasPermits') value = state.questionnaire.hasPermits;
    if (field == 'hasInsurance') value = state.questionnaire.hasInsurance;
    if (field == 'hasContracts') value = state.questionnaire.hasContracts;

    return SwitchListTile(
      title: Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 14)),
      value: value,
      onChanged: (val) {
        context
            .read<QuestionnaireBloc>()
            .add(QuestionnaireFieldChanged(field, val));
      },
    );
  }

  void _finishCreation(BuildContext context, QuestionnaireState qState) {
    final authState = context.read<AuthBloc>().state;
    String ownerId = '';
    if (authState is Authenticated) ownerId = authState.user.id;
    if (authState is ProfileLoaded) ownerId = authState.profile.id;

    final event = EventEntity(
      id: const Uuid().v4(),
      ownerId: ownerId,
      title: _titleController.text,
      description: _descController.text,
      eventDate: _selectedDate,
      status: 'planning',
      questionnaire: qState.questionnaire,
      hiredProviderIds: const [],
      budgetLimit: double.tryParse(_budgetController.text) ?? 0.0,
      currentExpenses: 0.0,
      createdAt: DateTime.now(),
    );

    context.read<EventBloc>().add(CreateEventRequested(event));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Criando evento...')),
    );
  }
}
