import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import 'profile_selection_page.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.black,
              surface: AppTheme.surfaceColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // After successful registration, go to Profile Selection
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfileSelectionPage(),
            ),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
          setState(() => _isLoading = false);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back_ios, color: AppTheme.primaryColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'CRIAR CONTA',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'MixArt',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFE5B80B),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontFamily: 'Outfit',
                    fontSize: 32,
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
                const SizedBox(height: 32),

                _buildTextField(
                  controller: _nameController,
                  hint: 'Nome Artístico / Completo',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _nicknameController,
                  hint: 'Nickname (ex: @meu_perfil)',
                  icon: Icons.alternate_email,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _emailController,
                  hint: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _passwordController,
                  hint: 'Senha',
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _confirmPasswordController,
                  hint: 'Confirmar Senha',
                  icon: Icons.lock_clock_outlined,
                  obscureText: true,
                  validator: (val) {
                    if (val != _passwordController.text) {
                      return 'As senhas não coincidem';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date of Birth (Lei Felca consideration)
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.white54, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate == null
                              ? 'Data de Nascimento'
                              : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                          style: TextStyle(
                            color: _selectedDate == null
                                ? Colors.white38
                                : Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '* Necessário para conformidade com normas de proteção de menores.',
                  style: TextStyle(color: Colors.white24, fontSize: 10),
                ),

                const SizedBox(height: 40),

                if (_isLoading)
                  const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryColor))
                else
                  ElevatedButton(
                    onPressed: _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'CONTINUAR',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
      validator: validator ??
          (val) {
            if (val == null || val.isEmpty) return 'Campo obrigatório';
            return null;
          },
    );
  }

  void _handleSignUp() {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      setState(() => _isLoading = true);
      context.read<AuthBloc>().add(
            SignUpRequested(
              _emailController.text.trim(),
              _passwordController.text.trim(),
              _nameController.text.trim(),
            ),
          );
      // Note: We'll update the rest of the profile fields in the ProfileSelectionPage
      // or after successful account creation.
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Por favor, selecione sua data de nascimento.')),
      );
    }
  }
}
