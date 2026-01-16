import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/profile_view_bloc.dart';
import '../../domain/entities/user_profile.dart';
import 'package:music_system/core/services/storage_service.dart';
import 'package:music_system/core/services/cloudinary_service.dart';
import '../../../../injection_container.dart';
import 'package:music_system/features/community/domain/repositories/post_repository.dart';
import 'package:music_system/features/community/presentation/widgets/artist_feed_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:music_system/core/error/failures.dart';

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
  DateTime? _lastActiveAt;
  bool _isLive = false;

  bool get _isOwner => FirebaseAuth.instance.currentUser?.uid == widget.userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<ProfileViewBloc>()..add(LoadProfileRequested(widget.userId)),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: widget.showAppBar
            ? AppBar(
                title: const Text('Perfil'),
                backgroundColor: Colors.black,
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
                  if (_isOwner)
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () {
                        context.read<AuthBloc>().add(SignOutRequested());
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                    ),
                ],
              )
            : null,
        body: BlocConsumer<ProfileViewBloc, ProfileViewState>(
          listener: (context, state) {
            if (state is ProfileViewError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
            if (state is ProfileViewLoaded) {
              if (_artisticNameController.text.isEmpty) {
                _artisticNameController.text = state.profile.artisticName;
                _bioController.text = state.profile.bio ?? '';
                _pixKeyController.text = state.profile.pixKey;
                _instagramController.text = state.profile.instagramUrl ?? '';
                _youtubeController.text = state.profile.youtubeUrl ?? '';
                _facebookController.text = state.profile.facebookUrl ?? '';
                _currentPhotoUrl = state.profile.photoUrl;
                _galleryUrls = state.profile.galleryUrls ?? [];
                _lastActiveAt = state.profile.lastActiveAt; // Populate
                _isLive = state.profile.isLive;
              }
            }
          },
          builder: (context, state) {
            if (state is ProfileViewLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ProfileViewLoaded) {
              return NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverToBoxAdapter(
                      child: Container(
                        color: Colors.black,
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: const Color(0xFFE5B80B),
                          labelColor: const Color(0xFFE5B80B),
                          unselectedLabelColor: Colors.grey,
                          tabs: const [
                            Tab(text: 'Sobre'),
                            Tab(text: 'Posts'),
                            Tab(text: 'Social'),
                            Tab(text: 'Galeria'),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAboutTab(),
                    _buildPostsTab(),
                    _buildSocialTab(),
                    _buildGalleryTab(),
                  ],
                ),
              );
            }
            return const Center(child: Text('Carregando...'));
          },
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    return FutureBuilder<Either<Failure, PostResponse>>(
      future: sl<PostRepository>().getPostsByUser(userId: widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erro ao carregar posts: ${snapshot.error}',
              style: const TextStyle(color: Colors.white),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Text(
              'Nenhuma publicação.',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return snapshot.data!.fold(
          (failure) => Center(
            child: Text(
              'Erro: ${failure.message}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          (response) {
            if (response.posts.isEmpty) {
              return const Center(
                child: Text(
                  'Nenhuma publicação ainda.',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: response.posts.length,
              itemBuilder: (context, index) {
                return ArtistFeedCard(
                  post: response.posts[index],
                  currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndUploadImage({bool isGallery = false}) async {
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

        String? url;
        try {
          url = await sl<CloudinaryService>().uploadImage(bytes, image.name);
          if (url == null) throw Exception('Cloudinary retornou nulo');
        } catch (e) {
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
          _showToast(isGallery ? 'Foto adicionada!' : 'Perfil atualizado!');
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
          fcmToken: _fcmToken,
          isLive: _isLive,
        ),
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
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[900],
              backgroundImage: _currentPhotoUrl != null
                  ? CachedNetworkImageProvider(_currentPhotoUrl!)
                  : null,
              child: _currentPhotoUrl == null
                  ? const Icon(Icons.person, size: 50, color: Colors.white24)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _artisticNameController.text.isEmpty
                ? 'Artista'
                : _artisticNameController.text,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (_isOwner)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: _isLive,
                    onChanged: (value) {
                      setState(() => _isLive = value);
                      // Trigger save automatically or just visual?
                      // Ideally we should auto-save or let the user hit Save.
                      // Since there is a Save button, we rely on it, but for "Live" status, instant is better.
                      // However, to keep consistency with other fields, let's keep it in "Save" for now or trigger a separate update?
                      // Given the "Status" nature, instant update is expected.
                      // But the Save button handles ProfileUpdateRequested.
                      // Let's rely on _saveProfile for simplicity, user toggles and hits Save.
                      // Wait, "Tocando Agora" implies strictly NOW.
                      // Let's add a visual cue.
                    },
                    activeColor: const Color(0xFFE5B80B),
                  ),
                  const Text(
                    'Tocando Agora',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          if (_lastActiveAt != null &&
              DateTime.now().difference(_lastActiveAt!).inMinutes < 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Online',
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ),
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
          label: 'Nome Artístico',
          icon: Icons.star,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _bioController,
          label: 'Sobre',
          icon: Icons.info,
          maxLines: 5,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _pixKeyController,
          label: 'PIX',
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
          label: 'Instagram',
          icon: Icons.camera_alt,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _youtubeController,
          label: 'YouTube',
          icon: Icons.play_circle,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _facebookController,
          label: 'Facebook',
          icon: Icons.facebook,
        ),
      ],
    );
  }

  Widget _buildGalleryTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (_isOwner)
            ElevatedButton.icon(
              onPressed: () => _pickAndUploadImage(isGallery: true),
              icon: const Icon(Icons.add_a_photo, color: Colors.black),
              label: const Text(
                'Adicionar Foto',
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
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: _galleryUrls[index],
                  fit: BoxFit.cover,
                ),
              ),
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
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      readOnly: !_isOwner,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFE5B80B)),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
