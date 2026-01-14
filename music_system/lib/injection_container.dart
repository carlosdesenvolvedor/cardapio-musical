import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'core/services/storage_service.dart';
import 'core/services/cloudinary_service.dart';
import 'core/services/notification_service.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/client_menu/data/datasources/song_remote_data_source.dart';
import 'features/musician_dashboard/data/repositories/repertoire_repository_impl.dart';
import 'features/musician_dashboard/domain/repositories/repertoire_repository.dart';
import 'features/musician_dashboard/domain/usecases/import_repertoire.dart';
import 'features/musician_dashboard/domain/usecases/add_song_to_repertoire.dart';
import 'features/musician_dashboard/domain/usecases/get_musician_songs.dart';
import 'features/musician_dashboard/domain/usecases/update_song.dart';
import 'features/musician_dashboard/domain/usecases/delete_song.dart';
import 'features/musician_dashboard/presentation/bloc/repertoire_bloc.dart';
import 'features/smart_lyrics/data/datasources/lyrics_remote_data_source.dart';
import 'features/smart_lyrics/data/repositories/lyrics_repository_impl.dart';
import 'features/smart_lyrics/domain/repositories/lyrics_repository.dart';
import 'features/smart_lyrics/domain/usecases/get_lyrics.dart';
import 'features/smart_lyrics/presentation/bloc/lyrics_bloc.dart';
import 'features/song_requests/data/datasources/song_request_remote_data_source.dart';
import 'features/song_requests/data/repositories/song_request_repository_impl.dart';
import 'features/song_requests/domain/repositories/song_request_repository.dart';
import 'features/song_requests/domain/usecases/create_request.dart';
import 'features/song_requests/domain/usecases/stream_requests.dart';
import 'features/song_requests/domain/usecases/update_request_status.dart';
import 'features/client_menu/domain/repositories/song_repository.dart';
import 'features/client_menu/data/repositories/song_repository_impl.dart';
import 'features/client_menu/domain/usecases/get_songs.dart';
import 'features/client_menu/presentation/bloc/repertoire_menu_bloc.dart';
import 'features/song_requests/presentation/bloc/song_request_bloc.dart';

import 'features/song_requests/domain/usecases/notify_musician.dart';
import 'features/song_requests/domain/usecases/delete_request.dart';
import 'features/community/data/services/community_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth
  sl.registerFactory(() => AuthBloc(
        repository: sl(),
        notificationService: sl(),
      ));
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(firebaseAuth: sl(), firestore: sl()),
  );

  //! Features - Song Requests
  sl.registerFactory(() => SongRequestBloc(
        createRequest: sl(),
        streamRequests: sl(),
        updateRequestStatus: sl(),
        notifyMusician: sl(),
        deleteRequest: sl(),
      ));
  sl.registerLazySingleton(() => CreateRequest(sl()));
  sl.registerLazySingleton(() => StreamRequests(sl()));
  sl.registerLazySingleton(() => UpdateRequestStatus(sl()));
  sl.registerLazySingleton(() => NotifyMusician(sl()));
  sl.registerLazySingleton(() => DeleteRequest(sl()));
  sl.registerLazySingleton<SongRequestRepository>(
    () => SongRequestRepositoryImpl(
      remoteDataSource: sl(),
      authRepository: sl(),
      notificationService: sl(),
    ),
  );
  sl.registerLazySingleton<SongRequestRemoteDataSource>(
    () => SongRequestRemoteDataSourceImpl(firestore: sl()),
  );

  //! Features - Repertoire
  sl.registerFactory(() => RepertoireBloc(
        importRepertoire: sl(),
        addSongToRepertoire: sl(),
        getMusicianSongs: sl(),
        updateSong: sl(),
        deleteSong: sl(),
      ));
  sl.registerLazySingleton(() => ImportRepertoire(sl()));
  sl.registerLazySingleton(() => AddSongToRepertoire(sl()));
  sl.registerLazySingleton(() => GetMusicianSongs(sl()));
  sl.registerLazySingleton(() => UpdateSong(sl()));
  sl.registerLazySingleton(() => DeleteSong(sl()));
  sl.registerLazySingleton<RepertoireRepository>(
    () => RepertoireRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<SongRemoteDataSource>(
    () => SongRemoteDataSourceImpl(firestore: sl()),
  );

  //! Features - Client Menu (Repertoire)
  sl.registerFactory(() => RepertoireMenuBloc(getSongs: sl()));
  sl.registerLazySingleton(() => GetSongs(sl()));
  sl.registerLazySingleton<SongRepository>(
    () => SongRepositoryImpl(remoteDataSource: sl()),
  );

  //! Features - Smart Lyrics
  sl.registerFactory(() => LyricsBloc(getLyrics: sl()));
  sl.registerLazySingleton(() => GetLyrics(sl()));
  sl.registerLazySingleton<LyricsRepository>(
    () => LyricsRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<LyricsRemoteDataSource>(
    () => LyricsRemoteDataSourceImpl(dio: sl()),
  );

  //! External
  sl.registerLazySingleton(() => CommunityService());
  sl.registerLazySingleton(() => StorageService());
  sl.registerLazySingleton(() => CloudinaryService());
  sl.registerLazySingleton(() => PushNotificationService());
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
}
