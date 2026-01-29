import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/work.dart';

class WorkModel extends Work {
  const WorkModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.description,
    super.fileUrl,
    super.fileType,
    super.links,
    required super.createdAt,
  });

  factory WorkModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      fileUrl: data['fileUrl'],
      fileType: data['fileType'],
      links: (data['links'] as List<dynamic>?)
              ?.map((l) => WorkLinkModel.fromJson(l))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toDocument() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'links': links.map((l) => (l as WorkLinkModel).toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class WorkLinkModel extends WorkLink {
  const WorkLinkModel({required super.title, required super.url});

  factory WorkLinkModel.fromJson(Map<String, dynamic> json) {
    return WorkLinkModel(
      title: json['title'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'url': url,
    };
  }
}
