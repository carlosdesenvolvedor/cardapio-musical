import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/band_entity.dart';

class BandModel extends BandEntity {
  @override
  final BandSubscriptionModel subscription;
  @override
  final BandProfileModel profile;
  @override
  final BandSettingsModel settings;

  const BandModel({
    required super.id,
    required super.name,
    required super.slug,
    required super.leaderId,
    required this.subscription,
    required this.profile,
    required this.settings,
    required super.createdAt,
  }) : super(
          subscription: subscription,
          profile: profile,
          settings: settings,
        );

  factory BandModel.fromEntity(BandEntity entity) {
    return BandModel(
      id: entity.id,
      name: entity.name,
      slug: entity.slug,
      leaderId: entity.leaderId,
      subscription: BandSubscriptionModel.fromEntity(entity.subscription),
      profile: BandProfileModel.fromEntity(entity.profile),
      settings: BandSettingsModel.fromEntity(entity.settings),
      createdAt: entity.createdAt,
    );
  }

  factory BandModel.fromJson(Map<String, dynamic> json, String id) {
    return BandModel(
      id: id,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      leaderId: json['leaderId'] ?? '',
      subscription: BandSubscriptionModel.fromJson(json['subscription'] ?? {}),
      profile: BandProfileModel.fromJson(json['profile'] ?? {}),
      settings: BandSettingsModel.fromJson(json['settings'] ?? {}),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'slug': slug,
      'leaderId': leaderId,
      'subscription': subscription.toJson(),
      'profile': profile.toJson(),
      'settings': settings.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class BandSubscriptionModel extends BandSubscriptionEntity {
  const BandSubscriptionModel({
    required super.planId,
    required super.status,
    required super.expiresAt,
  });

  factory BandSubscriptionModel.fromEntity(BandSubscriptionEntity entity) {
    return BandSubscriptionModel(
      planId: entity.planId,
      status: entity.status,
      expiresAt: entity.expiresAt,
    );
  }

  factory BandSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return BandSubscriptionModel(
      planId: json['planId'] ?? 'none',
      status: json['status'] ?? 'inactive',
      expiresAt: json['expiresAt'] != null
          ? (json['expiresAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'planId': planId,
      'status': status,
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }
}

class BandProfileModel extends BandProfileEntity {
  const BandProfileModel({
    required super.description,
    required super.genres,
    required super.mediaLinks,
    super.techRiderUrl,
    super.biography,
  });

  factory BandProfileModel.fromEntity(BandProfileEntity entity) {
    return BandProfileModel(
      description: entity.description,
      genres: entity.genres,
      mediaLinks: entity.mediaLinks,
      techRiderUrl: entity.techRiderUrl,
      biography: entity.biography,
    );
  }

  factory BandProfileModel.fromJson(Map<String, dynamic> json) {
    return BandProfileModel(
      description: json['description'] ?? '',
      genres: List<String>.from(json['genres'] ?? []),
      mediaLinks: List<String>.from(json['mediaLinks'] ?? []),
      techRiderUrl: json['techRiderUrl'],
      biography: json['biography'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'genres': genres,
      'mediaLinks': mediaLinks,
      'techRiderUrl': techRiderUrl,
      'biography': biography,
    };
  }
}

class BandSettingsModel extends BandSettingsEntity {
  const BandSettingsModel({
    required super.isPromoted,
  });

  factory BandSettingsModel.fromEntity(BandSettingsEntity entity) {
    return BandSettingsModel(
      isPromoted: entity.isPromoted,
    );
  }

  factory BandSettingsModel.fromJson(Map<String, dynamic> json) {
    return BandSettingsModel(
      isPromoted: json['isPromoted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPromoted': isPromoted,
    };
  }
}
