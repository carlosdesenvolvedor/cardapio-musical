import 'package:equatable/equatable.dart';

class ProfileViewer extends Equatable {
  final String id;
  final String viewerId;
  final String viewerName;
  final String? viewerPhotoUrl;
  final DateTime viewedAt;

  const ProfileViewer({
    required this.id,
    required this.viewerId,
    required this.viewerName,
    this.viewerPhotoUrl,
    required this.viewedAt,
  });

  @override
  List<Object?> get props =>
      [id, viewerId, viewerName, viewerPhotoUrl, viewedAt];
}
