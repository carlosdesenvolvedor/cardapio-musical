import 'package:equatable/equatable.dart';

enum PostUploadStatus { initial, uploading, success, failure }

class PostUploadState extends Equatable {
  final PostUploadStatus status;
  final double progress;
  final String? errorMessage;

  const PostUploadState({
    this.status = PostUploadStatus.initial,
    this.progress = 0.0,
    this.errorMessage,
  });

  PostUploadState copyWith({
    PostUploadStatus? status,
    double? progress,
    String? errorMessage,
  }) {
    return PostUploadState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, progress, errorMessage];
}
