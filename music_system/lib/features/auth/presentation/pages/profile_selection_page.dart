import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../../../community/presentation/pages/artist_network_page.dart';

class ProfileSelectionPage extends StatefulWidget {
  const ProfileSelectionPage({super.key});

  @override
  State<ProfileSelectionPage> createState() => _ProfileSelectionPageState();
}

class _ProfileSelectionPageState extends State<ProfileSelectionPage> {
  String? _selectedProfile;
  String? _selectedSubType;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _profiles = [
    {'id': 'Artista', 'label': 'ARTISTA', 'icon': Icons.mic},
    {
      'id': 'Contratador',
      'label': 'CONTRATADOR',
      'icon': Icons.business_center
    },
    {'id': 'Maesta', 'label': 'MAESTA', 'icon': Icons.workspace_premium},
    {'id': 'Investidor', 'label': 'INVESTIDOR', 'icon': Icons.attach_money},
  ];

  final List<String> _subTypes = ['MÚSICO', 'CANTOR', 'BANDA', 'OUTROS'];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  void _fetchProfile() {
    final authState = context.read<AuthBloc>().state;
    String? userId;
    if (authState is Authenticated) {
      userId = authState.user.id;
    } else if (authState is ProfileLoaded) {
      userId = authState.profile.id;
    }

    if (userId != null) {
      context.read<AuthBloc>().add(ProfileRequested(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ProfileLoaded && _isLoading) {
          // Profile was updated and re-loaded, now we can go to the network
          if (state.profile.profileType != null &&
              state.profile.subType != null) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const ArtistNetworkPage()),
              (route) => false,
            );
          }
        } else if (state is AuthError && _isLoading) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'SELECIONE SEU PERFIL',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 60),

                // Profiles Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _profiles.map((p) => _buildProfileItem(p)).toList(),
                ),

                const SizedBox(height: 60),

                // Subtypes Grid
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children:
                      _subTypes.map((s) => _buildSubTypeButton(s)).toList(),
                ),

                const Spacer(),

                if (_isLoading)
                  const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryColor))
                else
                  ElevatedButton(
                    onPressed:
                        (_selectedProfile != null && _selectedSubType != null)
                            ? _handleCompleteProfile
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      disabledBackgroundColor: Colors.white10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'CONTINUAR',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(Map<String, dynamic> profile) {
    bool isSelected = _selectedProfile == profile['id'];
    return InkWell(
      onTap: () => setState(() => _selectedProfile = profile['id']),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.white24,
                width: 2,
              ),
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.transparent,
            ),
            child: Icon(
              profile['icon'],
              color: isSelected ? AppTheme.primaryColor : Colors.white54,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            profile['label'],
            style: TextStyle(
              color: isSelected ? AppTheme.primaryColor : Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTypeButton(String type) {
    bool isSelected = _selectedSubType == type;
    return InkWell(
      onTap: () => setState(() => _selectedSubType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white10,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          type,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _handleCompleteProfile() {
    final state = context.read<AuthBloc>().state;
    if (state is ProfileLoaded) {
      setState(() => _isLoading = true);
      final updatedProfile = state.profile.copyWith(
        profileType: _selectedProfile,
        subType: _selectedSubType,
      );
      context.read<AuthBloc>().add(ProfileUpdateRequested(updatedProfile));
    } else {
      // Re-fetch and try again if profile somehow missed
      _fetchProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Sincronizando perfil... Tente novamente.')),
      );
    }
  }
}
