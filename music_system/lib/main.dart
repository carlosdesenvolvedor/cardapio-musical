import 'package:flutter/material.dart';
import 'features/service_provider/presentation/pages/artist_cache_page.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter/foundation.dart';
import 'core/services/notification_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'config/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/client_menu/presentation/pages/client_menu_page.dart';
import 'features/musician_dashboard/presentation/pages/musician_dashboard_page.dart';
import 'features/musician_dashboard/presentation/bloc/repertoire_bloc.dart';
import 'features/smart_lyrics/presentation/bloc/lyrics_bloc.dart';
import 'features/client_menu/presentation/bloc/repertoire_menu_bloc.dart';
import 'features/song_requests/presentation/bloc/song_request_bloc.dart';
import 'features/community/presentation/bloc/community_bloc.dart';
import 'features/community/presentation/bloc/conversations_bloc.dart';
import 'features/community/presentation/bloc/chat_bloc.dart';
import 'features/community/presentation/bloc/notifications_bloc.dart';
import 'features/community/presentation/bloc/notifications_event.dart';
import 'features/community/presentation/bloc/conversations_event.dart';
import 'features/community/presentation/bloc/story_upload_bloc.dart';
import 'features/community/presentation/bloc/post_upload_bloc.dart';
import 'features/bookings/presentation/bloc/budget_cart_bloc.dart';
import 'firebase_options.dart';
import 'injection_container.dart' as di;
import 'features/community/presentation/pages/artist_network_page.dart';
import 'features/bands/presentation/pages/band_public_profile_page.dart';
import 'features/bands/presentation/bloc/band_bloc.dart';
import 'features/calendar/presentation/bloc/calendar_bloc.dart';
import 'features/bookings/presentation/pages/budget_cart_page.dart';
import 'core/constants/app_version.dart';
import 'package:intl/date_symbol_data_local.dart';

final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  // Configures the URL strategy to remove the '#' from the URL
  if (kIsWeb) {
    try {
      usePathUrlStrategy();
    } catch (e) {
      debugPrint('UrlStrategy already set or failed: $e');
    }
  }

  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('pt_BR', null);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Specific logic for Web to handle potential persistence locks during development
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
    }

    await di.init();

    // Initialize Push Notifications (can fail on web without proper setup)
    try {
      await di.sl<PushNotificationService>().initialize();
    } catch (e) {
      debugPrint('Push Notification initialization failed: $e');
    }
  } catch (e) {
    debugPrint('App initialization failed: $e');
  }

  runApp(const MusicSystemApp());
}

class MusicSystemApp extends StatelessWidget {
  const MusicSystemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AuthBloc>()..add(AppStarted())),
        BlocProvider(create: (_) => di.sl<SongRequestBloc>()),
        BlocProvider(create: (_) => di.sl<RepertoireBloc>()),
        BlocProvider(create: (_) => di.sl<LyricsBloc>()),
        BlocProvider(create: (_) => di.sl<RepertoireMenuBloc>()),
        BlocProvider(create: (_) => di.sl<CommunityBloc>()),
        BlocProvider(create: (_) => di.sl<ConversationsBloc>()),
        BlocProvider(create: (_) => di.sl<ChatBloc>()),
        BlocProvider(create: (_) => di.sl<NotificationsBloc>()),
        BlocProvider(create: (_) => di.sl<BandBloc>()),
        BlocProvider(create: (_) => di.sl<CalendarBloc>()),
        BlocProvider(create: (_) => di.sl<StoryUploadBloc>()),
        BlocProvider(create: (_) => di.sl<PostUploadBloc>()),
        BlocProvider(create: (_) => di.sl<BudgetCartBloc>()),
      ],
      child: MaterialApp(
        title: 'MusicRequest System',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        scaffoldMessengerKey: messengerKey,
        builder: (context, child) {
          if (child == null) return const SizedBox.shrink();
          return ResponsiveBreakpoints.builder(
            child: child,
            breakpoints: [
              const Breakpoint(start: 0, end: 450, name: MOBILE),
              const Breakpoint(start: 451, end: 800, name: TABLET),
              const Breakpoint(start: 801, end: 1920, name: DESKTOP),
            ],
          );
        },
        onGenerateRoute: (settings) {
          final uri = Uri.parse(settings.name ?? '/');
          String path = uri.path;

          // Normalize path: ensure leading slash, remove trailing slash
          if (!path.startsWith('/')) path = '/$path';
          if (path.length > 1 && path.endsWith('/')) {
            path = path.substring(0, path.length - 1);
          }

          // Root path
          if (path == '/' || path == '/index.html') {
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const SplashPage(),
            );
          }

          // /menu/ID
          if (path.startsWith('/menu/')) {
            final segments =
                path.split('/').where((s) => s.isNotEmpty).toList();
            if (segments.length >= 2) {
              final musicianId = segments[1];
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => ClientMenuPage(musicianId: musicianId),
              );
            }
          }

          // /band/SLUG
          if (path.startsWith('/band/')) {
            final segments =
                path.split('/').where((s) => s.isNotEmpty).toList();
            if (segments.length >= 2) {
              final slug = segments[1];
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => BandPublicProfilePage(slug: slug),
              );
            }
          }

          if (path == '/musician') {
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const LoginPage(),
            );
          }

          if (path == '/client') {
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const ClientMenuPage(musicianId: ''),
            );
          }

          if (path == '/home' || path == '/welcome') {
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const HomePage(),
            );
          }
          if (path == '/network') {
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const ArtistNetworkPage(),
            );
          }
          if (path == '/dashboard') {
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const MusicianDashboardPage(),
            );
          }
          if (path == '/cart') {
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const BudgetCartPage(),
            );
          }
          if (path == '/artist-cache') {
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const ArtistCachePage(),
            );
          }

          return MaterialPageRoute(
            settings: settings,
            builder: (context) => const SplashPage(),
          );
        },
      ),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _handleState(context.read<AuthBloc>().state);
      }
    });
  }

  bool _isRedirecting = false;

  void _handleState(AuthState state) {
    if (!mounted || _isRedirecting) return;

    if (state is ProfileLoaded && state.currentUser != null) {
      _isRedirecting = true;
      if (mounted) {
        context.read<NotificationsBloc>().add(
              NotificationsStarted(state.profile.id),
            );
        context.read<ConversationsBloc>().add(
              ConversationsStarted(state.profile.id),
            );
      }

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) Navigator.pushReplacementNamed(context, '/network');
      });
    } else if (state is Unauthenticated) {
      _isRedirecting = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) Navigator.pushReplacementNamed(context, '/musician');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _handleState(state),
      child: const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo_dark.jpg',
              height: 180,
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Onde a inspiração cria conexões',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Selecione seu modo de acesso'),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ModeButton(
                  title: 'Sou Artista',
                  icon: Icons.dashboard,
                  onPressed: () {
                    final authState = context.read<AuthBloc>().state;
                    if (authState is Authenticated ||
                        (authState is ProfileLoaded &&
                            authState.currentUser != null)) {
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(
                              destination: MusicianDashboardPage()),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 20),
                _ModeButton(
                  title: 'Sou Cliente',
                  icon: Icons.restaurant_menu,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClientMenuPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton.icon(
                onPressed: () {
                  final authState = context.read<AuthBloc>().state;
                  if (authState is Authenticated ||
                      (authState is ProfileLoaded &&
                          authState.currentUser != null)) {
                    Navigator.pushReplacementNamed(context, '/network');
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(
                          destination: ArtistNetworkPage(),
                          title: 'Junte-se a Rede MixArt!',
                          logoPath: 'assets/images/logo_mixArt_Gilmar.jpeg',
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.people_alt, size: 28),
                label: const Text(
                  'Junte-se à nossa rede de artistas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'version $APP_VERSION',
              style: const TextStyle(color: Colors.white24, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onPressed;

  const _ModeButton({
    required this.title,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(title),
        ],
      ),
    );
  }
}
