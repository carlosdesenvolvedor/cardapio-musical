import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_system/features/auth/presentation/pages/privacy_settings_page.dart';
import 'package:image_picker/image_picker.dart';

import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/profile_view_bloc.dart';
import '../../domain/entities/user_profile.dart';
import 'package:music_system/core/services/storage_service.dart';
import 'package:music_system/core/services/cloudinary_service.dart';
import '../../../../injection_container.dart';
import 'package:music_system/features/community/domain/repositories/post_repository.dart';
import 'package:music_system/features/community/presentation/widgets/artist_feed_card.dart';
import 'package:music_system/features/community/presentation/widgets/artist_avatar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:music_system/core/error/failures.dart';
import 'package:music_system/features/community/presentation/pages/chat_page.dart';
import 'package:music_system/features/client_menu/presentation/pages/client_menu_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/log_profile_view.dart';
import '../../presentation/bloc/works/works_bloc.dart';
import '../../presentation/widgets/work_list_widget.dart';

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
  final _nicknameController = TextEditingController();
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
  DateTime? _liveUntil;
  List<ShowInfo> _scheduledShows = [];
  DateTime? _birthDate;
  VerificationLevel _verificationLevel = VerificationLevel.none;
  bool _isParentalConsentGranted = false;
  bool _isDobVisible = true;
  bool _isPixVisible = true;
  bool _isEditingSocial = false;

  bool get _isOwner => FirebaseAuth.instance.currentUser?.uid == widget.userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _isOwner ? 5 : 4, vsync: this);
    if (!_isOwner) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _logVisit());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _artisticNameController.dispose();
    _nicknameController.dispose();
    _pixKeyController.dispose();
    _bioController.dispose();
    _instagramController.dispose();
    _youtubeController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              sl<ProfileViewBloc>()..add(LoadProfileRequested(widget.userId)),
        ),
        BlocProvider(
          create: (context) => sl<WorksBloc>(),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is ProfileLoaded) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Perfil atualizado com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Refresh the view data
                context
                    .read<ProfileViewBloc>()
                    .add(LoadProfileRequested(widget.userId));
              } else if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            listenWhen: (previous, current) =>
                previous is AuthLoading &&
                (current is ProfileLoaded || current is AuthError),
          ),
          BlocListener<ProfileViewBloc, ProfileViewState>(
            listener: (context, state) {
              if (state is ProfileViewError) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
              if (state is ProfileViewLoaded) {
                if (_artisticNameController.text.isEmpty) {
                  _artisticNameController.text = state.profile.artisticName;
                  _nicknameController.text = state.profile.nickname != null &&
                          state.profile.nickname!.isNotEmpty
                      ? '@${state.profile.nickname}'
                      : '';
                  _bioController.text = state.profile.bio ?? '';
                  _pixKeyController.text = state.profile.pixKey;
                  _instagramController.text = state.profile.instagramUrl ?? '';
                  _youtubeController.text = state.profile.youtubeUrl ?? '';
                  _facebookController.text = state.profile.facebookUrl ?? '';
                  _currentPhotoUrl = state.profile.photoUrl;
                  _galleryUrls = state.profile.galleryUrls ?? [];
                  _lastActiveAt = state.profile.lastActiveAt; // Populate
                  _isLive = state.profile.isLive;
                  _liveUntil = state.profile.liveUntil;
                  _scheduledShows = state.profile.scheduledShows ?? [];
                  _birthDate = state.profile.birthDate;
                  _isDobVisible = state.profile.isDobVisible;
                  _isPixVisible = state.profile.isPixVisible;
                  _verificationLevel = state.profile.verificationLevel;
                  _isParentalConsentGranted =
                      state.profile.isParentalConsentGranted;
                }
              }
            },
          ),
        ],
        child: BlocBuilder<ProfileViewBloc, ProfileViewState>(
          builder: (context, state) {
            return Scaffold(
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
                            icon: const Icon(Icons.shield_outlined,
                                color: Color(0xFFE5B80B)),
                            onPressed: () {
                              if (state is ProfileViewLoaded) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PrivacySettingsPage(
                                        profile: state.profile),
                                  ),
                                );
                              }
                            },
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
              body: state is ProfileViewLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state is ProfileViewLoaded
                      ? NestedScrollView(
                          headerSliverBuilder: (context, innerBoxIsScrolled) {
                            return [
                              SliverToBoxAdapter(child: _buildHeader(state)),
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: _PersistentHeaderDelegate(
                                  child: Container(
                                    color: Colors.black,
                                    child: TabBar(
                                      controller: _tabController,
                                      indicatorColor: const Color(0xFFE5B80B),
                                      labelColor: const Color(0xFFE5B80B),
                                      unselectedLabelColor: Colors.grey,
                                      tabs: [
                                        const Tab(text: 'Sobre'),
                                        const Tab(text: 'Posts'),
                                        const Tab(text: 'Social'),
                                        const Tab(text: 'Work'),
                                        if (_isOwner)
                                          const Tab(text: 'Visitas'),
                                      ],
                                    ),
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
                              if (_isOwner) _buildVisitorsTab(),
                            ],
                          ),
                        )
                      : const Center(child: Text('Carregando...')),
            );
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

  Future<void> _logVisit() async {
    final authState = context.read<AuthBloc>().state;
    String? viewerId;
    String? viewerName;
    String? viewerPhoto;

    if (authState is Authenticated) {
      viewerId = authState.user.id;
      viewerName = authState.user.displayName;
      viewerPhoto = authState.user.photoUrl;
    } else if (authState is ProfileLoaded) {
      viewerId = authState.currentUser?.id;
      viewerName = authState.currentUser?.displayName;
      viewerPhoto = authState.currentUser?.photoUrl;
    }

    if (viewerId != null && viewerId != widget.userId) {
      await sl<LogProfileView>().call(
        viewedUserId: widget.userId,
        viewerId: viewerId,
        viewerName: viewerName ?? 'Visitante',
        viewerPhotoUrl: viewerPhoto,
      );
    }
  }

  void _saveProfile() {
    context.read<AuthBloc>().add(
          ProfileUpdateRequested(
            UserProfile(
              id: widget.userId,
              email: widget.email,
              artisticName: _artisticNameController.text,
              nickname: (_nicknameController.text.startsWith('@')
                      ? _nicknameController.text.substring(1)
                      : _nicknameController.text)
                  .toLowerCase()
                  .trim(),
              searchName: _artisticNameController.text.toLowerCase().trim(),
              pixKey: _pixKeyController.text,
              photoUrl: _currentPhotoUrl,
              bio: _bioController.text,
              instagramUrl: _instagramController.text,
              youtubeUrl: _youtubeController.text,
              facebookUrl: _facebookController.text,
              galleryUrls: _galleryUrls,
              fcmToken: _fcmToken,
              isLive: _isLive,
              liveUntil: _liveUntil,
              scheduledShows: _scheduledShows,
              birthDate: _birthDate,
              verificationLevel: _verificationLevel,
              isParentalConsentGranted: _isParentalConsentGranted,
              isDobVisible: _isDobVisible,
              isPixVisible: _isPixVisible,
            ),
          ),
        );
  }

  Widget _buildHeader(ProfileViewLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          InkWell(
            onTap:
                _isOwner ? () => _pickAndUploadImage(isGallery: false) : null,
            child: ArtistAvatar(
              photoUrl: _currentPhotoUrl,
              radius: 50,
              isLive: _isLive, // Pass the local state toggle
              isMe: _isOwner,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _artisticNameController.text.isEmpty
                ? 'Artista'
                : _artisticNameController.text,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (state.profile.nickname != null &&
              state.profile.nickname!.isNotEmpty)
            Text(
              '@${state.profile.nickname}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFFE5B80B),
                fontWeight: FontWeight.w500,
              ),
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
                      _saveProfile();
                    },
                    activeColor: const Color(0xFFE5B80B),
                  ),
                  const Text(
                    'Tocando Agora',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  if (_isLive) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _selectTime(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFE5B80B).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Color(0xFFE5B80B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _liveUntil != null
                                  ? 'até ${DateFormat('HH:mm').format(_liveUntil!)}'
                                  : 'até que horas?',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (_scheduledShows.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event, color: Color(0xFFE5B80B), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Próximo: ${DateFormat('dd/MM').format(_scheduledShows.first.date)} @ ${_scheduledShows.first.location}',
                    style: const TextStyle(
                      color: Color(0xFFE5B80B),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatColumn('Fãs', state.profile.followersCount),
              const SizedBox(width: 32),
              _buildStatColumn('Ídolos', state.profile.followingCount),
            ],
          ),
          if (!_isOwner)
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  List<String> followingIds = [];
                  if (authState is ProfileLoaded) {
                    followingIds = authState.currentUser?.followingIds ?? [];
                  } else if (authState is Authenticated) {
                    followingIds = authState.user.followingIds;
                  }
                  final bool isFollowing = followingIds.contains(widget.userId);

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final String currentUserId =
                            FirebaseAuth.instance.currentUser?.uid ?? '';
                        if (currentUserId.isEmpty) return;

                        String? senderName;
                        String? senderPhoto;
                        if (authState is ProfileLoaded) {
                          senderName = authState.profile.artisticName;
                          senderPhoto = authState.profile.photoUrl;
                        }

                        if (isFollowing) {
                          context.read<AuthBloc>().add(
                                UnfollowUserRequested(
                                  currentUserId,
                                  widget.userId,
                                ),
                              );
                        } else {
                          context.read<AuthBloc>().add(
                                FollowUserRequested(
                                  currentUserId,
                                  widget.userId,
                                  senderName: senderName,
                                  senderPhoto: senderPhoto,
                                ),
                              );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing
                            ? Colors.white10
                            : const Color(0xFFE5B80B),
                        foregroundColor:
                            isFollowing ? Colors.white : Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isFollowing ? 'Deixar de ser fã' : 'Virar fã',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (!_isOwner)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: () {
                  final String currentUserId =
                      FirebaseAuth.instance.currentUser?.uid ?? '';
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        currentUserId: currentUserId,
                        targetUserId: widget.userId,
                        targetUserName: _artisticNameController.text,
                        targetUserPhoto: _currentPhotoUrl,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.chat,
                  color: Color(0xFFE5B80B),
                  size: 18,
                ),
                label: const Text(
                  'Falar com artista',
                  style: TextStyle(
                    color: Color(0xFFE5B80B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_lastActiveAt != null &&
              DateTime.now().difference(_lastActiveAt!).inMinutes < 5)
            Padding(
              padding: const EdgeInsets.only(top: 8),
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
                  const SizedBox(width: 6),
                  const Text(
                    'Online',
                    style: TextStyle(color: Colors.green, fontSize: 13),
                  ),
                ],
              ),
            ),
          if (_isOwner)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.email,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
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
          controller: _nicknameController,
          label: 'Nickname (ex: @meunome)',
          icon: Icons.alternate_email,
        ),
        const SizedBox(height: 16),
        // Seção de Data de Nascimento (Dono sempre vê, Visitante só se visível)
        if (_isOwner || (_birthDate != null && _isDobVisible)) ...[
          const Text(
            'Data de Nascimento',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _isOwner
                ? () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _birthDate ?? DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFFE5B80B),
                              onPrimary: Colors.black,
                              surface: Color(0xFF1e293b),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      setState(() => _birthDate = date);
                      _saveProfile();
                    }
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cake, color: Color(0xFFE5B80B), size: 18),
                  const SizedBox(width: 12),
                  Text(
                    _birthDate != null
                        ? DateFormat('dd/MM/yyyy').format(_birthDate!)
                        : 'Não informada',
                    style: TextStyle(
                      color: _birthDate != null ? Colors.white : Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isOwner) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _isDobVisible
                      ? Icons.visibility
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ocultar data de nascimento para outros',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const Spacer(),
                Switch(
                  value: !_isDobVisible,
                  onChanged: (value) {
                    setState(() => _isDobVisible = !value);
                    _saveProfile();
                  },
                  activeColor: const Color(0xFFE5B80B),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
        ],
        ElevatedButton.icon(
          onPressed: _isLive
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ClientMenuPage(musicianId: widget.userId),
                    ),
                  );
                }
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Este artista não está aceitando pedidos no momento.',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                },
          icon: Icon(
            _isLive ? Icons.playlist_add_check_circle : Icons.do_not_disturb_on,
            color: _isLive ? Colors.black : Colors.black45,
          ),
          label: Text(
            _isLive
                ? 'PEDIR MÚSICA (ABRIR CARDÁPIO)'
                : 'PEDIR MÚSICA (OFFLINE)',
            style: TextStyle(
              color: _isLive ? Colors.black : Colors.black45,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isLive ? const Color(0xFFE5B80B) : Colors.grey,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _bioController,
          label: 'Sobre',
          icon: Icons.info,
          maxLines: 5,
        ),
        const SizedBox(height: 16),
        // Seção PIX (Dono sempre vê, Visitante só se visível)
        if (_isOwner ||
            (_pixKeyController.text.isNotEmpty && _isPixVisible)) ...[
          _buildTextField(
            controller: _pixKeyController,
            label: 'PIX (Chave para recebimento)',
            icon: Icons.pix,
          ),
          if (_isOwner) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _isPixVisible
                      ? Icons.visibility
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ocultar chave PIX para outros',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const Spacer(),
                Switch(
                  value: !_isPixVisible,
                  onChanged: (value) {
                    setState(() => _isPixVisible = !value);
                    _saveProfile();
                  },
                  activeColor: const Color(0xFFE5B80B),
                ),
              ],
            ),
          ],
        ],
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'AGENDA DE SHOWS',
            style: TextStyle(
              color: Color(0xFFE5B80B),
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_scheduledShows.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Nenhum show agendado.',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          )
        else
          ..._scheduledShows.asMap().entries.map((entry) {
            final index = entry.key;
            final show = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE5B80B).withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event, color: Color(0xFFE5B80B), size: 20),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          show.location,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat("EEEE, dd/MM 'às' HH:mm", 'pt_BR')
                              .format(show.date),
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isOwner)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: Color(0xFFE5B80B), size: 20),
                          onPressed: () =>
                              _selectDateTime(context, index: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent, size: 20),
                          onPressed: () {
                            setState(() => _scheduledShows.removeAt(index));
                            _saveProfile();
                          },
                        ),
                      ],
                    ),
                ],
              ),
            );
          }),
        if (_isOwner)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: () => _selectDateTime(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('ADICIONAR SHOW À AGENDA'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE5B80B),
                side: const BorderSide(color: Color(0xFFE5B80B)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSocialTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_isOwner)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                if (_isEditingSocial) {
                  _saveProfile();
                }
                setState(() => _isEditingSocial = !_isEditingSocial);
              },
              icon: Icon(
                _isEditingSocial ? Icons.check : Icons.edit,
                size: 18,
                color: const Color(0xFFE5B80B),
              ),
              label: Text(
                _isEditingSocial ? 'SALVAR' : 'EDITAR',
                style: const TextStyle(
                  color: Color(0xFFE5B80B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        _buildSocialField(
          controller: _instagramController,
          label: 'Instagram',
          icon: Icons.camera_alt,
          baseUrl: 'https://instagram.com/',
        ),
        const SizedBox(height: 16),
        _buildSocialField(
          controller: _youtubeController,
          label: 'YouTube',
          icon: Icons.play_circle,
          baseUrl: 'https://youtube.com/',
        ),
        const SizedBox(height: 16),
        _buildSocialField(
          controller: _facebookController,
          label: 'Facebook',
          icon: Icons.facebook,
          baseUrl: 'https://facebook.com/',
        ),
      ],
    );
  }

  Widget _buildSocialField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String baseUrl,
  }) {
    return InkWell(
      onTap: !_isEditingSocial && controller.text.isNotEmpty
          ? () async {
              String url = controller.text;
              if (!url.startsWith('http')) {
                // If it's just a handle, prepend base URL
                url = baseUrl + url.replaceAll('@', '');
              }
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            }
          : null,
      child: TextField(
        controller: controller,
        readOnly: !_isEditingSocial,
        enabled: _isEditingSocial || controller.text.isNotEmpty,
        style: TextStyle(
          color: !_isEditingSocial && controller.text.isNotEmpty
              ? const Color(0xFFE5B80B)
              : Colors.white,
          decoration: !_isEditingSocial && controller.text.isNotEmpty
              ? TextDecoration.underline
              : null,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFFE5B80B)),
          filled: true,
          fillColor: Colors.white10,
          suffixIcon: !_isEditingSocial && controller.text.isNotEmpty
              ? const Icon(Icons.open_in_new, size: 16, color: Colors.white38)
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryTab() {
    return WorkListWidget(userId: widget.userId, isOwner: _isOwner);
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

  Future<void> _selectTime(BuildContext context, bool isLiveUntil) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE5B80B),
              onPrimary: Colors.black,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      final now = DateTime.now();
      final selectedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );

      // Se a hora escolhida já passou hoje, assume que é para amanhã (ou apenas atualiza)
      DateTime finalDateTime = selectedDateTime;
      if (selectedDateTime.isBefore(now)) {
        finalDateTime = selectedDateTime.add(const Duration(days: 1));
      }

      setState(() {
        if (isLiveUntil) {
          _liveUntil = finalDateTime;
        }
      });
      _saveProfile();
    }
  }

  Future<void> _selectDateTime(BuildContext context, {int? index}) async {
    final DateTime initialDate =
        index != null ? _scheduledShows[index].date : DateTime.now();
    final String initialLocation =
        index != null ? _scheduledShows[index].location : '';

    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(DateTime.now()) && index == null
          ? DateTime.now()
          : initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE5B80B),
              onPrimary: Colors.black,
              surface: Color(0xFF1e293b),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFE5B80B),
                onPrimary: Colors.black,
                surface: Color(0xFF1e293b),
                onSurface: Colors.white,
              ),
            ),
            child: MediaQuery(
              data:
                  MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
              child: child!,
            ),
          );
        },
      );

      if (time != null && mounted) {
        final locationController = TextEditingController(text: initialLocation);
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1e293b),
            title: Text(index != null ? 'Editar show' : 'Onde será o show?',
                style: const TextStyle(color: Color(0xFFE5B80B))),
            content: TextField(
              controller: locationController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Ex: Bar do Zé, São Paulo',
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE5B80B))),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('CANCELAR',
                      style: TextStyle(color: Colors.grey))),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, locationController.text.isNotEmpty),
                child: Text(index != null ? 'SALVAR' : 'ADICIONAR',
                    style: const TextStyle(color: Color(0xFFE5B80B))),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          final newShow = ShowInfo(
            date: DateTime(
                date.year, date.month, date.day, time.hour, time.minute),
            location: locationController.text,
          );
          setState(() {
            if (index != null) {
              _scheduledShows[index] = newShow;
            } else {
              _scheduledShows.add(newShow);
            }
            _scheduledShows.sort((a, b) => a.date.compareTo(b.date));
          });
          _saveProfile();
        }
      }
    }
  }

  Widget _buildVisitorsTab() {
    return FutureBuilder<Either<Failure, List<Map<String, dynamic>>>>(
      future: sl<AuthRepository>().getProfileVisitors(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Erro ao carregar visitantes',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final result = snapshot.data;
        if (result == null) return const SizedBox();

        return result.fold(
          (failure) => Center(
            child: Text(
              'Erro: ${failure.message}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          (visitors) {
            final now = DateTime.now();
            final last30Days = now.subtract(const Duration(days: 30));
            final recentVisitorsCount = visitors.where((v) {
              final t = v['viewedAt'] as Timestamp?;
              return t != null && t.toDate().isAfter(last30Days);
            }).length;

            if (visitors.isEmpty) {
              return const Center(
                child: Text(
                  'Ainda não há visitas recentes.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5B80B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFE5B80B).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$recentVisitorsCount',
                        style: const TextStyle(
                          color: Color(0xFFE5B80B),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'visitantes nos últimos 30 dias',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: visitors.length,
                    itemBuilder: (context, index) {
                      final visit = visitors[index];
                      final String name = visit['viewerName'] ?? 'Anônimo';
                      final String? photo = visit['viewerPhotoUrl'];
                      final Timestamp? t = visit['viewedAt'] as Timestamp?;
                      final String time = t != null
                          ? DateFormat('dd/MM HH:mm').format(t.toDate())
                          : '';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              photo != null ? NetworkImage(photo) : null,
                          child:
                              photo == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(name,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(
                          'Visitou em $time',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(
                                userId: visit['viewerId'],
                                email: '',
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _PersistentHeaderDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 48.0;

  @override
  double get minExtent => 48.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
