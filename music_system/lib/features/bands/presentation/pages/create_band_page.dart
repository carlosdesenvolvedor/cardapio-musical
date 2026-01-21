import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/band_entity.dart';
import '../bloc/band_bloc.dart';

class CreateBandPage extends StatefulWidget {
  const CreateBandPage({super.key});

  @override
  State<CreateBandPage> createState() => _CreateBandPageState();
}

class _CreateBandPageState extends State<CreateBandPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _selectedGenres = [];
  String _selectedPlan = 'basic_monthly';

  final List<String> _availableGenres = [
    'Rock',
    'Pop',
    'Sertanejo',
    'Pagode',
    'Axé',
    'Forró',
    'Jazz',
    'Blues',
    'MPB'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Nova Banda')),
      body: BlocListener<BandBloc, BandState>(
        listener: (context, state) {
          if (state is BandOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.pop(context);
          } else if (state is BandError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro: ${state.message}')),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informações Básicas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Banda',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Campo obrigatório'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descrição/Bio',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Gêneros Musicais',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _availableGenres.map((genre) {
                    final isSelected = _selectedGenres.contains(genre);
                    return FilterChip(
                      label: Text(genre),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedGenres.add(genre);
                          } else {
                            _selectedGenres.remove(genre);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Escolha seu Plano',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                RadioListTile<String>(
                  title: const Text('Plano Básico ("Existir")'),
                  subtitle: const Text('Perfil, Agenda e Membros'),
                  value: 'basic_monthly',
                  groupValue: _selectedPlan,
                  onChanged: (value) => setState(() => _selectedPlan = value!),
                ),
                RadioListTile<String>(
                  title: const Text('Plano PRO ("Ser Vista")'),
                  subtitle: const Text('Boost na busca + Selo de Verificado'),
                  value: 'pro_monthly',
                  groupValue: _selectedPlan,
                  onChanged: (value) => setState(() => _selectedPlan = value!),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5B80B),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _submit,
                    child: const Text('PAGAR E CRIAR BANDA'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedGenres.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione pelo menos um gênero')),
        );
        return;
      }

      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated) {
        final newBand = BandEntity(
          id: '', // Firestore will generate
          name: _nameController.text,
          slug: _nameController.text.toLowerCase().replaceAll(' ', '-'),
          leaderId: authState.user.id,
          subscription: BandSubscriptionEntity(
            planId: _selectedPlan,
            status: 'active',
            expiresAt: DateTime.now().add(const Duration(days: 30)),
          ),
          profile: BandProfileEntity(
            description: _descriptionController.text,
            genres: _selectedGenres,
            mediaLinks: const [],
          ),
          settings: BandSettingsEntity(
            isPromoted: _selectedPlan == 'pro_monthly',
          ),
          createdAt: DateTime.now(),
        );

        context.read<BandBloc>().add(CreateBandEvent(newBand));
      }
    }
  }
}
