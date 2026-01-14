import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/services/notification_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/client_menu/presentation/pages/client_menu_page.dart';
import 'features/musician_dashboard/presentation/bloc/repertoire_bloc.dart';
import 'features/smart_lyrics/presentation/bloc/lyrics_bloc.dart';
import 'features/client_menu/presentation/bloc/repertoire_menu_bloc.dart';
import 'features/song_requests/presentation/bloc/song_request_bloc.dart';
import 'firebase_options.dart';
import 'injection_container.dart' as di;
import 'features/community/presentation/pages/artist_network_page.dart';
import 'core/constants/app_version.dart';

void main() async {
  // Configures the URL strategy to remove the '#' from the URL
  usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

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
      ],
      child: MaterialApp(
        title: 'MusicRequest System',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        builder: (context, child) => ResponsiveBreakpoints.builder(
          child: child ?? const SizedBox(),
          breakpoints: [
            const Breakpoint(start: 0, end: 450, name: MOBILE),
            const Breakpoint(start: 451, end: 800, name: TABLET),
            const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          ],
        ),
        initialRoute: '/',
        onGenerateRoute: (settings) {
          final uri = Uri.parse(settings.name ?? '/');

          // Improved path detection for /menu/ID
          if (uri.path.startsWith('/menu/')) {
            final segments = uri.pathSegments;
            if (segments.length >= 2) {
              final musicianId = segments[1];
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => ClientMenuPage(musicianId: musicianId),
              );
            }
          }

          if (uri.path == '/musician') {
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const LoginPage(),
            );
          }

          if (uri.path == '/client') {
            return MaterialPageRoute(
              settings: settings,
              builder: (context) => const ClientMenuPage(musicianId: ''),
            );
          }

          return MaterialPageRoute(
            settings: settings,
            builder: (context) => const HomePage(),
          );
        },
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
            const Icon(
              Icons.music_note,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              'MusicRequest System',
              style: Theme.of(context).textTheme.displayLarge,
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    );
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
                  if (authState is Authenticated) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ArtistNetworkPage(),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const LoginPage(destination: ArtistNetworkPage()),
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
