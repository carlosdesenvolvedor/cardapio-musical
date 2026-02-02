import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/backend_storage_service.dart';
import '../../domain/entities/post_entity.dart';

import '../../domain/repositories/post_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import 'post_upload_event.dart';
import 'post_upload_state.dart';

class PostUploadBloc extends Bloc<PostUploadEvent, PostUploadState> {
  final CloudinaryService cloudinaryService;
  final StorageService storageService;
  final BackendStorageService backendStorageService;
  final PostRepository postRepository;
  final AuthRepository authRepository;

  PostUploadBloc({
    required this.cloudinaryService,
    required this.storageService,
    required this.backendStorageService,
    required this.postRepository,
    required this.authRepository,
  }) : super(const PostUploadState()) {
    on<StartPostUploadRequested>(_onStartPostUploadRequested);
    on<PostUploadProgressUpdated>(_onPostUploadProgressUpdated);
    on<PostUploadFinished>(_onPostUploadFinished);
    on<ResetPostUploadStatusRequested>(_onResetPostUploadStatusRequested);
  }

  Future<void> _onStartPostUploadRequested(
    StartPostUploadRequested event,
    Emitter<PostUploadState> emit,
  ) async {
    emit(state.copyWith(status: PostUploadStatus.uploading, progress: 0.05));

    try {
      // 1. Sincronizar Nome Artístico se necessário
      String finalAuthorName =
          event.customArtisticName ?? event.profile.artisticName;
      if (event.customArtisticName != null &&
          event.customArtisticName != event.profile.artisticName) {
        await authRepository.updateProfile(
          event.profile.copyWith(artisticName: event.customArtisticName),
        );
      }

      // 2. Upload de Arquivos
      List<String> uploadedUrls = [];
      int totalFiles = event.filesBytes.length;

      for (int i = 0; i < totalFiles; i++) {
        String? url;
        final bytes = event.filesBytes[i];
        final name = event.fileNames[i];

        // Atualizar progresso base
        double baseProgress = (i / totalFiles) * 0.8;
        emit(state.copyWith(progress: 0.05 + baseProgress));

        try {
          // MIGRATION: Using Self-Hosted Backend (MinIO)
          // We prefer MinIO over Cloudinary/Firebase for cost reasons.

          if (event.isVideo) {
            // Upload Video
            final path = await backendStorageService.uploadBytes(
                bytes, name, 'posts/videos');
            url = "http://localhost/media/$path";
          } else {
            // Upload Image
            final path = await backendStorageService.uploadBytes(
                bytes, name, 'posts/images');
            url = "http://localhost/media/$path";
          }

          /* OLD LOGIC
          if (event.isVideo) {
            url = await cloudinaryService.uploadVideo(bytes, name);
          } else {
            url = await cloudinaryService.uploadImage(bytes, name);
          }
          */
        } catch (e) {
          // Fallback to old storage if MinIO fails (Optional)
          url = await storageService.uploadImage(bytes, name);
        }

        if (url != null) {
          // No need to sanitize Cloudinary URL anymore if using MinIO
          uploadedUrls.add(url);
        }
      }

      if (uploadedUrls.isNotEmpty) {
        emit(state.copyWith(progress: 0.9));

        String postType = 'image';
        if (event.isVideo) {
          postType = 'video';
        } else if (uploadedUrls.length > 1) {
          postType = 'carousel';
        }

        final post = PostEntity(
          id: '',
          authorId: event.profile.id,
          authorName: finalAuthorName,
          authorPhotoUrl: event.profile.photoUrl,
          imageUrl: uploadedUrls.first,
          mediaUrls: uploadedUrls,
          postType: postType,
          caption: event.caption,
          likes: const [],
          createdAt: DateTime.now(),
          taggedUserIds: event.taggedUserIds,
          collaboratorIds: event.collaboratorIds,
          musicData: event.musicData,
        );

        await postRepository.createPost(post);
        add(const PostUploadFinished(success: true));
      } else {
        add(const PostUploadFinished(
            success: false, error: 'Falha ao fazer upload dos arquivos.'));
      }
    } catch (e) {
      add(PostUploadFinished(success: false, error: e.toString()));
    }
  }

  void _onPostUploadProgressUpdated(
    PostUploadProgressUpdated event,
    Emitter<PostUploadState> emit,
  ) {
    emit(state.copyWith(progress: event.progress));
  }

  void _onPostUploadFinished(
    PostUploadFinished event,
    Emitter<PostUploadState> emit,
  ) {
    if (event.success) {
      emit(state.copyWith(status: PostUploadStatus.success, progress: 1.0));
      Future.delayed(const Duration(seconds: 3), () {
        if (!isClosed) add(const ResetPostUploadStatusRequested());
      });
    } else {
      emit(state.copyWith(
        status: PostUploadStatus.failure,
        errorMessage: event.error,
      ));
    }
  }

  void _onResetPostUploadStatusRequested(
    ResetPostUploadStatusRequested event,
    Emitter<PostUploadState> emit,
  ) {
    emit(state.copyWith(status: PostUploadStatus.initial, progress: 0.0));
  }
}
