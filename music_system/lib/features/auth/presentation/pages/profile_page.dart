import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../bloc/auth_bloc.dart';
import '../../domain/entities/user_profile.dart';
import 'package:music_system/core/services/storage_service.dart';
import 'package:music_system/core/services/cloudinary_service.dart';
import '../../../../injection_container.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  final String email;
  final bool showAppBar;

  const ProfilePage({
    super.key,
    required this.userId,
    required this.email,
    this.showAppBar = true,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  final _artisticNameController = TextEditingController();
  final _pixKeyController = TextEditingController();
  final _bioController = TextEditingController();
  final _instagramController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _facebookController = TextEditingController();

  String? _currentPhotoUrl;
  String? _fcmToken; // To preserve the token
  List<String> _galleryUrls = [];
  bool _isUploadingImage = false;

  bool get _isOwner => FirebaseAuth.instance.currentUser?.uid == widget.userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<AuthBloc>().add(ProfileRequested(widget.userId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _artisticNameController.dispose();
    _pixKeyController.dispose();
    _bioController.dispose();
    _instagramController.dispose();
    _youtubeController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage({bool isGallery = false}) async {
    // Diagnostic feedback - Safari Mobile needs a direct user gesture
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Abrindo galeria...'),
          duration: Duration(milliseconds: 700),
        ),
      );
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 800,
      );

      if (image != null) {
        setState(() => _isUploadingImage = true);

        final bytes = await image.readAsBytes();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enviando imagem... Por favor, aguarde.'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        String? url;

        // --- MÉTODO 1: CLOUDINARY (Prioridade conforme solicitado) ---
        try {
          url = await sl<CloudinaryService>().uploadImage(bytes, image.name);
          if (url == null) throw Exception('Cloudinary retornou nulo');
        } catch (e) {
          debugPrint('Falha no Cloudinary, tentando fallback Firebase: $e');

          // --- MÉTODO 2: FIREBASE STORAGE (Fallback) ---
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Servidor 1 ocupado, tentando servidor 2...'),
                backgroundColor: Colors.orange,
              ),
            );
          }

          url = await sl<StorageService>().uploadImage(bytes, image.name);
        }

        if (url != null) {
          setState(() {
            if (isGallery) {
              _galleryUrls.add(url!);
            } else {
              _currentPhotoUrl = url;
            }
          });
          _showToast(
            isGallery
                ? 'Foto adicionada à galeria!'
                : 'Foto de perfil atualizada!',
          );
        } else {
          throw Exception(
            'Não foi possível fazer o upload em nenhum servidor.',
          );
        }
      }
    } catch (e) {
      _showError('Erro: $e');
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _saveProfile() {
    context.read<AuthBloc>().add(
      ProfileUpdateRequested(
        UserProfile(
          id: widget.userId,
          email: widget.email,
          artisticName: _artisticNameController.text,
          pixKey: _pixKeyController.text,
          photoUrl: _currentPhotoUrl,
          bio: _bioController.text,
          instagramUrl: _instagramController.text,
          youtubeUrl: _youtubeController.text,
          facebookUrl: _facebookController.text,
          galleryUrls: _galleryUrls,
          fcmToken: _fcmToken, // Preserve the token!
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(_isOwner ? 'Editar Perfil' : 'Perfil'),
              actions: [
                if (_isOwner)
                  TextButton(
                    onPressed: _isUploadingImage ? null : _saveProfile,
                    child: const Text(
                      'Salvar',
                      style: TextStyle(
                        color: Color(0xFFE5B80B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            )
          : null,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            _artisticNameController.text = state.profile.artisticName;
            _pixKeyController.text = state.profile.pixKey;
            _bioController.text = state.profile.bio ?? '';
            _instagramController.text = state.profile.instagramUrl ?? '';
            _youtubeController.text = state.profile.youtubeUrl ?? '';
            _facebookController.text = state.profile.facebookUrl ?? '';
            _currentPhotoUrl = state.profile.photoUrl;
            _fcmToken = state.profile.fcmToken; // Store it
            _galleryUrls = List<String>.from(state.profile.galleryUrls ?? []);
            setState(() {});
          } else if (state is AuthError) {
            _showError(state.message);
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFFE5B80B),
                    labelColor: const Color(0xFFE5B80B),
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'Sobre'),
                      Tab(text: 'Social'),
                      Tab(text: 'Galeria'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAboutTab(),
                        _buildSocialTab(),
                        _buildGalleryTab(),
                      ],
                    ),
                  ),
                ],
              ),
              if (state is AuthLoading && !_isUploadingImage)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFE5B80B)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          InkWell(
            onTap: _isOwner
                ? () => _pickAndUploadImage(isGallery: false)
                : null,
            borderRadius: BorderRadius.circular(50),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE5B80B),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[900],
                    backgroundImage: _currentPhotoUrl != null
                        ? CachedNetworkImageProvider(_currentPhotoUrl!)
                        : null,
                    child: _currentPhotoUrl == null
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white24,
                          )
                        : null,
                  ),
                ),
                if (_isUploadingImage)
                  const CircularProgressIndicator(color: Color(0xFFE5B80B)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _artisticNameController.text.isEmpty
                ? 'Nome do Artista'
                : _artisticNameController.text,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (_isOwner)
            Text(
              widget.email,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildTextField(
          controller: _artisticNameController,
          label: 'Nome Artístico / Grupo',
          icon: Icons.star,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _bioController,
          label: 'Sobre o Artista',
          hint: 'Conte sua história, estilo musical, etc.',
          icon: Icons.info_outline,
          maxLines: 5,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _pixKeyController,
          label: 'Chave PIX (Para Gorjetas)',
          icon: Icons.pix,
        ),
      ],
    );
  }

  Widget _buildSocialTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildTextField(
          controller: _instagramController,
          label: 'Instagram (@usuario)',
          icon: Icons.camera_alt,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _youtubeController,
          label: 'Canal do YouTube (URL)',
          icon: Icons.play_circle_fill,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _facebookController,
          label: 'Facebook (URL)',
          icon: Icons.facebook,
        ),
      ],
    );
  }

  Widget _buildGalleryTab() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          if (_isOwner)
            ElevatedButton.icon(
              onPressed: () => _pickAndUploadImage(isGallery: true),
              icon: const Icon(Icons.add_a_photo, color: Colors.black),
              label: const Text(
                'Adicionar Foto à Galeria',
                style: TextStyle(color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5B80B),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _galleryUrls.length,
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: _galleryUrls[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.white10),
                      ),
                    ),
                    _isOwner
                        ? Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _galleryUrls.removeAt(index)),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      readOnly: !_isOwner,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFFE5B80B)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (val) {
        if (label == 'Nome Artístico / Grupo') setState(() {});
      },
    );
  }
}
