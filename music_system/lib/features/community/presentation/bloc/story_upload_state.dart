import 'package:equatable/equatable.dart';

enum StoryUploadStatus { initial, uploading, success, failure }

class StoryUploadState extends Equatable {
  final StoryUploadStatus status;
  final double progress;
  final String? errorMessage;
  final String? lastUploadedUrl;

  const StoryUploadState({
    this.status = StoryUploadStatus.initial,
    this.progress = 0.0,
    this.errorMessage,
    this.lastUploadedUrl,
  });

  StoryUploadState copyWith({
    StoryUploadStatus? status,
    double? progress,
    String? errorMessage,
    String? lastUploadedUrl,
  }) {
    return StoryUploadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage,
      lastUploadedUrl: lastUploadedUrl ?? this.lastUploadedUrl,
    );
  }

  @override
  List<Object?> get props => [status, progress, errorMessage, lastUploadedUrl];
}
