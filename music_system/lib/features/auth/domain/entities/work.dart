import 'package:equatable/equatable.dart';

enum WorkType { audio, pdf, link, image, unknown }

class WorkLink extends Equatable {
  final String title;
  final String url;

  const WorkLink({required this.title, required this.url});

  @override
  List<Object?> get props => [title, url];
}

class Work extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String? fileUrl; // URL do arquivo (MP3/PDF)
  final String? fileType; // 'mp3', 'pdf', null
  final List<WorkLink> links; // Links para redes sociais/vídeos
  final DateTime createdAt;

  const Work({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.fileUrl,
    this.fileType,
    this.links = const [],
    required this.createdAt,
  });

  WorkType get type {
    if (fileType == 'mp3') return WorkType.audio;
    if (fileType == 'pdf') return WorkType.pdf;
    // Adicionar lógica para imagem se necessário, ou basear em extensão
    return WorkType.unknown;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        fileUrl,
        fileType,
        links,
        createdAt,
      ];
}
