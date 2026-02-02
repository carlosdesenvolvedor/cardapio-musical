import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../domain/entities/service_entity.dart';
import '../bloc/service_registration_bloc.dart';
import '../widgets/common_details_form.dart';
import '../widgets/technical_details_forms.dart';
import '../pages/service_preview_page.dart';
import 'package:uuid/uuid.dart';

class ServiceRegistrationFormPage extends StatefulWidget {
  final ServiceCategory category;
  final String providerId;
  final ServiceEntity? initialService;

  const ServiceRegistrationFormPage({
    super.key,
    required this.category,
    required this.providerId,
    this.initialService,
  });

  @override
  State<ServiceRegistrationFormPage> createState() =>
      _ServiceRegistrationFormPageState();
}

class _ServiceRegistrationFormPageState
    extends State<ServiceRegistrationFormPage> {
  int _currentStep = 0;
  final _commonFormKey = GlobalKey<FormState>();

  // Controllers for Common Details
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _priceDescController = TextEditingController();
  final _locationController = TextEditingController();

  // State for Technical Details
  TechnicalDetails? _technicalDetails;

  @override
  void initState() {
    super.initState();
    if (widget.initialService != null) {
      _nameController.text = widget.initialService!.name;
      _descController.text = widget.initialService!.description;
      _priceController.text = widget.initialService!.basePrice.toString();
      _priceDescController.text = widget.initialService!.priceDescription;
      _locationController.text = widget.initialService!.location ?? '';
      _technicalDetails = widget.initialService!.technicalDetails;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _priceDescController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.instance<ServiceRegistrationBloc>(),
      child: BlocConsumer<ServiceRegistrationBloc, ServiceRegistrationState>(
        listener: (context, state) {
          if (state is ServiceRegistrationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Serviço cadastrado com sucesso!')),
            );
            Navigator.pop(context); // Go back to dashboard/selection
            Navigator.pop(context);
          } else if (state is ServiceRegistrationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro: ${state.message}')),
            );
          }
        },
        builder: (context, state) {
          if (state is ServiceRegistrationLoading) {
            return const Scaffold(
              backgroundColor: Color(0xFF101010),
              body: Center(
                  child: CircularProgressIndicator(color: Color(0xFFFFC107))),
            );
          }

          return Scaffold(
            backgroundColor: const Color(0xFF101010),
            appBar: AppBar(
              title: Text(
                widget.initialService != null
                    ? 'EDITAR SERVIÇO: ${_getCategoryLabel(widget.category)}'
                    : 'NOVO CADASTRO: ${_getCategoryLabel(widget.category)}',
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, letterSpacing: 1.5),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                if (_nameController.text.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      final service = _createServiceFromCurrentState();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ServicePreviewPage(service: service),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility,
                        color: Color(0xFFFFC107), size: 18),
                    label: const Text(
                      'Prévia',
                      style: TextStyle(color: Color(0xFFFFC107), fontSize: 12),
                    ),
                  ),
              ],
            ),
            body: Theme(
              data: Theme.of(context).copyWith(
                  colorScheme:
                      const ColorScheme.dark(primary: Color(0xFFFFC107))),
              child: Stepper(
                type: StepperType.vertical,
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep == 0) {
                    if (_commonFormKey.currentState!.validate()) {
                      setState(() => _currentStep += 1);
                    }
                  } else if (_currentStep == 1) {
                    // Technical details are saved via the button in the form widget,
                    // which should ideally trigger validation and then step advance or submit.
                    // Here we assume if _technicalDetails is not null, we can proceed to submit.
                    if (_technicalDetails != null) {
                      _submitForm(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Confirme os detalhes técnicos primeiro.')),
                      );
                    }
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep -= 1);
                  } else {
                    Navigator.pop(context);
                  }
                },
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      children: [
                        if (_currentStep == 0)
                          ElevatedButton(
                            onPressed: details.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFC107),
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Próximo'),
                          ),
                        if (_currentStep == 1)
                          const SizedBox(), // Hide default button, use the one in form or custom
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Voltar',
                              style: TextStyle(color: Colors.white54)),
                        ),
                      ],
                    ),
                  );
                },
                steps: [
                  Step(
                    title: const Text('Informações Gerais',
                        style: TextStyle(color: Colors.white)),
                    content: CommonDetailsForm(
                      formKey: _commonFormKey,
                      nameController: _nameController,
                      descriptionController: _descController,
                      basePriceController: _priceController,
                      priceDescController: _priceDescController,
                      locationController: _locationController,
                    ),
                    isActive: _currentStep >= 0,
                    state: _currentStep > 0
                        ? StepState.complete
                        : StepState.editing,
                  ),
                  Step(
                    title: const Text('Detalhes Técnicos',
                        style: TextStyle(color: Colors.white)),
                    content: _buildTechnicalForm(context),
                    isActive: _currentStep >= 1,
                    state: _technicalDetails != null
                        ? StepState.complete
                        : StepState.editing,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTechnicalForm(BuildContext context) {
    final saveCallback = (TechnicalDetails details) {
      setState(() {
        _technicalDetails = details;
      });
      // Auto submit or allow review? Let's just submit for MVP
      _submitForm(context);
    };

    switch (widget.category) {
      case ServiceCategory.artist:
        return ArtistForm(
          onSaved: saveCallback,
          initialDetails: _technicalDetails as ArtistDetails?,
        );
      case ServiceCategory.infrastructure:
        return InfrastructureForm(
          onSaved: saveCallback,
          initialDetails: _technicalDetails as InfrastructureDetails?,
        );
      case ServiceCategory.catering:
        return CateringForm(
          onSaved: saveCallback,
          initialDetails: _technicalDetails as CateringDetails?,
        );
      case ServiceCategory.security:
        return SecurityForm(
          onSaved: saveCallback,
          initialDetails: _technicalDetails as SecurityDetails?,
        );
      case ServiceCategory.media:
        return MediaForm(
          onSaved: saveCallback,
          initialDetails: _technicalDetails as MediaDetails?,
        );
    }
  }

  void _submitForm(BuildContext context) {
    if (_technicalDetails == null) return;
    final service = _createServiceFromCurrentState();

    if (widget.initialService != null) {
      context.read<ServiceRegistrationBloc>().add(SubmitUpdate(service));
    } else {
      context.read<ServiceRegistrationBloc>().add(SubmitRegistration(service));
    }
  }

  ServiceEntity _createServiceFromCurrentState() {
    return ServiceEntity(
      id: widget.initialService?.id ?? const Uuid().v4(),
      providerId: widget.providerId,
      name: _nameController.text,
      description: _descController.text,
      category: widget.category,
      basePrice: double.tryParse(_priceController.text) ?? 0,
      priceDescription: _priceDescController.text,
      status: widget.initialService?.status ?? ServiceStatus.pending,
      technicalDetails:
          _technicalDetails ?? const ArtistDetails(genre: 'Não definido'),
      location: _locationController.text,
      createdAt: widget.initialService?.createdAt ?? DateTime.now(),
    );
  }

  String _getCategoryLabel(ServiceCategory category) {
    switch (category) {
      case ServiceCategory.artist:
        return 'ARTÍSTICO';
      case ServiceCategory.infrastructure:
        return 'TÉCNICA & ESTRUTURA';
      case ServiceCategory.catering:
        return 'ALIMENTAÇÃO';
      case ServiceCategory.security:
        return 'SEGURANÇA';
      case ServiceCategory.media:
        return 'MÍDIA';
    }
  }
}
