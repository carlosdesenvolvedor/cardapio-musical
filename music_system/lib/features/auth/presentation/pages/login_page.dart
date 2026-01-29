import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'registration_page.dart';
import '../../../../core/constants/app_version.dart';

import '../../../community/presentation/pages/artist_network_page.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  final Widget? destination;
  final String? title;
  final String? logoPath;

  const LoginPage({super.key, this.destination, this.title, this.logoPath});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  widget.destination ?? const ArtistNetworkPage(),
            ),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black, // Pure black to match logo background
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppTheme.primaryColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Branding MixArt (Replacing fixed logo path with the styled text as requested)
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'MixArt',
                        style: TextStyle(
                          color: Color(0xFFE5B80B),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontFamily: 'Outfit',
                          fontSize: 48, // Larger for the login screen
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSignUp
                            ? 'CRIAR CONTA'
                            : (widget.title ?? 'PAINEL DO ARTISTA'),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Senha',
                    prefixIcon: const Icon(Icons.lock),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is AuthLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (_isSignUp) {
                              context.read<AuthBloc>().add(
                                SignUpRequested(
                                  _emailController.text,
                                  _passwordController.text,
                                  "Músico",
                                ),
                              );
                            } else {
                              context.read<AuthBloc>().add(
                                SignInRequested(
                                  _emailController.text,
                                  _passwordController.text,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(_isSignUp ? 'Cadastrar' : 'Entrar'),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            context.read<AuthBloc>().add(
                              GoogleSignInRequested(),
                            );
                          },
                          icon: Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_\"G\"_logo.svg/768px-Google_\"G\"_logo.svg.png',
                            height: 24,
                          ),
                          label: const Text(
                            'Continuar com Google',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(
                              color: AppTheme.primaryColor,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: AppTheme.primaryColor.withOpacity(
                              0.05,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegistrationPage(),
                      ),
                    );
                  },
                  child: const Text(
                    'Novo por aqui? Crie uma conta',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),

                const SizedBox(height: 32),
                Center(
                  child: Text(
                    'Versão $APP_VERSION',
                    style: const TextStyle(color: Colors.white24, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
