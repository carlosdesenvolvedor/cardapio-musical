import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../../auth/domain/entities/user_profile.dart';

abstract class PostUploadEvent extends Equatable {
  const PostUploadEvent();

  @override
  List<Object?> get props => [];
}

class StartPostUploadRequested extends PostUploadEvent {
  final List<Uint8List> filesBytes;
  final List<String> fileNames;
  final bool isVideo;
  final UserProfile profile;
  final String caption;
  final List<String> taggedUserIds;
  final List<String> collaboratorIds;
  final Map<String, dynamic>? musicData;
  final String? customArtisticName;

  const StartPostUploadRequested({
    required this.filesBytes,
    required this.fileNames,
    required this.isVideo,
    required this.profile,
    required this.caption,
    this.taggedUserIds = const [],
    this.collaboratorIds = const [],
    this.musicData,
    this.customArtisticName,
  });

  @override
  List<Object?> get props => [
        filesBytes,
        fileNames,
        isVideo,
        profile,
        caption,
        taggedUserIds,
        collaboratorIds,
        musicData,
        customArtisticName,
      ];
}

class PostUploadProgressUpdated extends PostUploadEvent {
  final double progress;

  const PostUploadProgressUpdated(this.progress);

  @override
  List<Object?> get props => [progress];
}

class PostUploadFinished extends PostUploadEvent {
  final bool success;
  final String? error;

  const PostUploadFinished({required this.success, this.error});

  @override
  List<Object?> get props => [success, error];
}

class ResetPostUploadStatusRequested extends PostUploadEvent {
  const ResetPostUploadStatusRequested();
}
