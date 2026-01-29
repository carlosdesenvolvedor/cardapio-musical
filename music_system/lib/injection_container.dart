import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'core/services/storage_service.dart';

import 'core/services/backend_storage_service.dart';
import 'core/services/cloudinary_service.dart';

import 'core/services/notification_service.dart';
import 'core/services/livekit_service.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/repositories/work_repository.dart';
import 'features/auth/data/repositories/work_repository_impl.dart';
import 'features/auth/domain/usecases/log_profile_view.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/works/works_bloc.dart';
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
import 'features/community/domain/repositories/post_repository.dart';
import 'features/community/data/repositories/post_repository_impl.dart';
import 'features/auth/presentation/bloc/profile_view_bloc.dart';
import 'features/community/domain/repositories/social_graph_repository.dart';
import 'features/community/data/repositories/social_graph_repository_impl.dart';
import 'features/community/domain/usecases/get_community_feed.dart';
import 'features/community/domain/usecases/follow_user.dart';
import 'features/community/domain/usecases/unfollow_user.dart';
import 'features/community/domain/repositories/story_repository.dart';
import 'features/community/data/repositories/story_repository_impl.dart';
import 'features/community/domain/usecases/get_active_stories.dart';
import 'features/community/domain/usecases/mark_story_as_viewed.dart';
import 'features/community/domain/repositories/chat_repository.dart';
import 'features/community/data/repositories/chat_repository_impl.dart';
import 'features/community/domain/usecases/send_message.dart';
import 'features/community/domain/usecases/stream_messages.dart';
import 'features/community/domain/usecases/stream_conversations.dart';
import 'features/community/domain/repositories/notification_repository.dart';
import 'features/community/data/repositories/notification_repository_impl.dart';
import 'features/community/presentation/bloc/notifications_bloc.dart';
import 'features/community/presentation/bloc/chat_bloc.dart';
import 'features/community/presentation/bloc/conversations_bloc.dart';
import 'features/community/presentation/bloc/community_bloc.dart';
import 'features/community/presentation/bloc/story_upload_bloc.dart';
import 'features/community/presentation/bloc/post_upload_bloc.dart';

import 'features/bands/domain/repositories/band_repository.dart';
import 'features/bands/data/repositories/band_repository_impl.dart';
import 'features/bands/data/datasources/band_remote_data_source.dart';
import 'features/bands/domain/usecases/create_band.dart';
import 'features/bands/domain/usecases/get_band_members.dart';
import 'features/bands/domain/usecases/invite_member.dart';
import 'features/bands/presentation/bloc/band_bloc.dart';
import 'features/bookings/domain/repositories/booking_repository.dart';
import 'features/bookings/data/repositories/booking_repository_impl.dart';
import 'features/bookings/data/datasources/booking_remote_data_source.dart';
import 'features/calendar/domain/repositories/calendar_repository.dart';
import 'features/calendar/data/repositories/calendar_repository_impl.dart';
import 'features/calendar/data/datasources/calendar_remote_data_source.dart';
import 'features/calendar/data/datasources/calendar_remote_data_source_impl.dart';
import 'features/calendar/domain/usecases/get_artist_calendar.dart';
import 'features/calendar/domain/usecases/save_calendar_event.dart';
import 'features/calendar/domain/usecases/delete_calendar_event.dart';
import 'features/calendar/presentation/bloc/calendar_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Auth
  sl.registerFactory(
    () => AuthBloc(
      repository: sl(),
      notificationService: sl(),
      socialGraphRepository: sl(),
    ),
  );
  sl.registerFactory(() => ProfileViewBloc(repository: sl()));
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(firebaseAuth: sl(), firestore: sl()),
  );
  sl.registerLazySingleton(() => LogProfileView(sl()));

  sl.registerLazySingleton<WorkRepository>(
    () => WorkRepositoryImpl(
      firestore: sl(),
      storage: sl(),
      backendStorage: sl(),
    ),
  );

  sl.registerFactory(() => WorksBloc(repository: sl()));

  //! Features - Song Requests
  sl.registerFactory(
    () => SongRequestBloc(
      createRequest: sl(),
      streamRequests: sl(),
      updateRequestStatus: sl(),
      notifyMusician: sl(),
      deleteRequest: sl(),
    ),
  );
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
  sl.registerFactory(
    () => RepertoireBloc(
      importRepertoire: sl(),
      addSongToRepertoire: sl(),
      getMusicianSongs: sl(),
      updateSong: sl(),
      deleteSong: sl(),
    ),
  );
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
  sl.registerFactory(
      () => RepertoireMenuBloc(getSongs: sl(), authRepository: sl()));
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

  //! Features - Community
  sl.registerLazySingleton<PostRepository>(
    () => PostRepositoryImpl(firestore: sl(), notificationRepository: sl()),
  );
  sl.registerLazySingleton<SocialGraphRepository>(
    () => SocialGraphRepositoryImpl(
      firestore: sl(),
      notificationRepository: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetCommunityFeed(sl()));
  sl.registerLazySingleton(() => FollowUser(sl()));
  sl.registerLazySingleton(() => UnfollowUser(sl()));

  sl.registerLazySingleton<StoryRepository>(
    () => StoryRepositoryImpl(firestore: sl(), notificationRepository: sl()),
  );
  sl.registerLazySingleton(() => GetActiveStories(sl()));
  sl.registerLazySingleton(() => MarkStoryAsViewed(sl()));

  //! Chat
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(firestore: sl()),
  );

  sl.registerFactory(() => NotificationsBloc(repository: sl()));

  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(firestore: sl(), notificationRepository: sl()),
  );
  sl.registerLazySingleton(() => SendMessage(sl()));
  sl.registerLazySingleton(() => StreamMessages(sl()));
  sl.registerLazySingleton(() => StreamConversations(sl()));

  sl.registerFactory(
    () => CommunityBloc(
      getCommunityFeed: sl(),
      postRepository: sl(),
      getActiveStories: sl(),
      notificationRepository: sl(),
    ),
  );

  sl.registerFactory(() => ChatBloc(sendMessage: sl(), streamMessages: sl()));
  sl.registerFactory(
    () => ConversationsBloc(
      streamConversations: sl(),
      authRepository: sl(),
      socialGraphRepository: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => StoryUploadBloc(
      cloudinaryService: sl(),
      storageService: sl(),
      backendStorageService: sl(),
      storyRepository: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => PostUploadBloc(
      cloudinaryService: sl(),
      storageService: sl(),
      backendStorageService: sl(),
      postRepository: sl(),
      authRepository: sl(),
    ),
  );

  //! Bands
  sl.registerFactory(
    () => BandBloc(
      createBand: sl(),
      getBandMembers: sl(),
      inviteMember: sl(),
      repository: sl(),
    ),
  );
  sl.registerLazySingleton(() => CreateBand(sl()));
  sl.registerLazySingleton(() => GetBandMembers(sl()));
  sl.registerLazySingleton(() => InviteMember(sl()));
  sl.registerLazySingleton<BandRepository>(
    () => BandRepositoryImpl(
      remoteDataSource: sl(),
      notificationRepository: sl(),
    ),
  );
  sl.registerLazySingleton<BandRemoteDataSource>(
    () => BandRemoteDataSourceImpl(firestore: sl()),
  );

  //! Bookings
  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(firestore: sl()),
  );

  //! Calendar
  sl.registerFactory(
    () => CalendarBloc(
      getArtistCalendar: sl(),
      saveCalendarEvent: sl(),
      deleteCalendarEvent: sl(),
    ),
  );
  sl.registerLazySingleton(() => GetArtistCalendar(sl()));
  sl.registerLazySingleton(() => SaveCalendarEvent(sl()));
  sl.registerLazySingleton(() => DeleteCalendarEvent(sl()));
  sl.registerLazySingleton<CalendarRepository>(
    () => CalendarRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<CalendarRemoteDataSource>(
    () => CalendarRemoteDataSourceImpl(firestore: sl()),
  );

  //! External
  sl.registerLazySingleton(() => BackendStorageService());
  sl.registerLazySingleton(() => StorageService());

  sl.registerLazySingleton(() => CloudinaryService());
  sl.registerLazySingleton(() => PushNotificationService());
  sl.registerLazySingleton(() => LiveKitService());
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
}
