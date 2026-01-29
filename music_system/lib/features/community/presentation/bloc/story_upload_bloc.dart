import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/backend_storage_service.dart';
import '../../data/models/story_model.dart';
import '../../domain/entities/story_effects.dart';
import '../../domain/repositories/story_repository.dart';
import 'story_upload_event.dart';
import 'story_upload_state.dart';

class StoryUploadBloc extends Bloc<StoryUploadEvent, StoryUploadState> {
  final CloudinaryService cloudinaryService;
  final StorageService storageService;
  final BackendStorageService backendStorageService;
  final StoryRepository storyRepository;

  StoryUploadBloc({
    required this.cloudinaryService,
    required this.storageService,
    required this.backendStorageService,
    required this.storyRepository,
  }) : super(const StoryUploadState()) {
    on<StartStoryUploadRequested>(_onStartStoryUploadRequested);
    on<UploadProgressUpdated>(_onUploadProgressUpdated);
    on<UploadFinished>(_onUploadFinished);
    on<ResetUploadStatusRequested>(_onResetUploadStatusRequested);
  }

  Future<void> _onStartStoryUploadRequested(
    StartStoryUploadRequested event,
    Emitter<StoryUploadState> emit,
  ) async {
    emit(state.copyWith(status: StoryUploadStatus.uploading, progress: 0.1));

    try {
      String? url;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      if (event.mediaType == 'image') {
        try {
          // MIGRATION: Using Self-Hosted Backend (MinIO)
          final path = await backendStorageService.uploadBytes(event.mediaBytes,
              'story_${event.profile.id}_$timestamp.jpg', 'stories/images');
          url = "https://136.248.64.90.nip.io/media/$path";
          add(const UploadProgressUpdated(0.8));

          /* OLD LOGIC
          url = await cloudinaryService.uploadImage(
            event.mediaBytes,
            'story_${event.profile.id}_$timestamp',
            onProgress: (p) => add(UploadProgressUpdated(
                p * 0.8)), // Reserved 20% for metadata save
          );
          */
        } catch (e) {
          // Fallback
          url = await storageService.uploadImage(
            event.mediaBytes,
            'stories/${event.profile.id}_$timestamp.jpg',
          );
        }
      } else {
        try {
          // MIGRATION: Using Self-Hosted Backend (MinIO)
          final path = await backendStorageService.uploadBytes(event.mediaBytes,
              'story_${event.profile.id}_$timestamp.mp4', 'stories/videos');
          url = "https://136.248.64.90.nip.io/media/$path";
          add(const UploadProgressUpdated(0.8));

          /* OLD LOGIC
          url = await cloudinaryService.uploadVideo(
            event.mediaBytes,
            'story_${event.profile.id}_$timestamp',
            onProgress: (p) => add(UploadProgressUpdated(
                p * 0.8)), // Reserved 20% for metadata save
          );
          */
        } catch (e) {
          url = await storageService.uploadFile(
            fileBytes: event.mediaBytes,
            fileName: 'stories/${event.profile.id}_$timestamp.mp4',
            contentType: 'video/mp4',
          );
        }
      }

      if (url != null) {
        emit(state.copyWith(progress: 0.8));

        // No sanitization needed for MinIO.
        // If reusing CloudinarySanitizer for something, keep it, but here it was mainly for Cloudinary URLs.
        final sanitizedUrl = url;

        final story = StoryModel(
          id: '',
          authorId: event.profile.id,
          authorName: event.profile.artisticName,
          authorPhotoUrl: event.profile.photoUrl,
          mediaUrl: sanitizedUrl,
          mediaType: event.mediaType,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
          viewers: const [],
          effects: event.filterId != null
              ? StoryEffects(filterId: event.filterId)
              : null,
          caption: event.caption,
        );

        await storyRepository.createStory(story);
        add(const UploadFinished(success: true));
      } else {
        add(const UploadFinished(
            success: false, error: 'Erro ao obter URL da mídia'));
      }
    } catch (e) {
      add(UploadFinished(success: false, error: e.toString()));
    }
  }

  void _onUploadProgressUpdated(
    UploadProgressUpdated event,
    Emitter<StoryUploadState> emit,
  ) {
    emit(state.copyWith(progress: event.progress));
  }

  void _onUploadFinished(
    UploadFinished event,
    Emitter<StoryUploadState> emit,
  ) {
    if (event.success) {
      emit(state.copyWith(status: StoryUploadStatus.success, progress: 1.0));
      // Reset to initial after a delay to clear the progress bar
      // We use add() instead of emit() inside Future.delayed to avoid illegal emit calls
      Future.delayed(const Duration(seconds: 3), () {
        if (!isClosed) add(const ResetUploadStatusRequested());
      });
    } else {
      emit(state.copyWith(
        status: StoryUploadStatus.failure,
        errorMessage: event.error,
      ));
    }
  }

  void _onResetUploadStatusRequested(
    ResetUploadStatusRequested event,
    Emitter<StoryUploadState> emit,
  ) {
    emit(state.copyWith(status: StoryUploadStatus.initial, progress: 0.0));
  }
}
