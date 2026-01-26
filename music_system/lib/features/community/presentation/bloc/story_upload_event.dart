import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user_profile.dart';

abstract class StoryUploadEvent extends Equatable {
  const StoryUploadEvent();

  @override
  List<Object?> get props => [];
}

class StartStoryUploadRequested extends StoryUploadEvent {
  final Uint8List mediaBytes;
  final String mediaType;
  final UserProfile profile;
  final String? filterId;
  final String? caption;

  const StartStoryUploadRequested({
    required this.mediaBytes,
    required this.mediaType,
    required this.profile,
    this.filterId,
    this.caption,
  });

  @override
  List<Object?> get props =>
      [mediaBytes, mediaType, profile, filterId, caption];
}

class UploadProgressUpdated extends StoryUploadEvent {
  final double progress;

  const UploadProgressUpdated(this.progress);

  @override
  List<Object?> get props => [progress];
}

class UploadFinished extends StoryUploadEvent {
  final bool success;
  final String? error;

  const UploadFinished({required this.success, this.error});

  @override
  List<Object?> get props => [success, error];
}

class ResetUploadStatusRequested extends StoryUploadEvent {
  const ResetUploadStatusRequested();
}
