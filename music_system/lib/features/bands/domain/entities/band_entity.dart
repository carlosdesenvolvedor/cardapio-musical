import 'package:equatable/equatable.dart';

class BandEntity extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String leaderId;
  final BandSubscriptionEntity subscription;
  final BandProfileEntity profile;
  final BandSettingsEntity settings;
  final DateTime createdAt;

  const BandEntity({
    required this.id,
    required this.name,
    required this.slug,
    required this.leaderId,
    required this.subscription,
    required this.profile,
    required this.settings,
    required this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, name, slug, leaderId, subscription, profile, settings, createdAt];
}

class BandSubscriptionEntity extends Equatable {
  final String planId; // basic_monthly, pro_monthly
  final String status; // active, past_due, canceled
  final DateTime expiresAt;

  const BandSubscriptionEntity({
    required this.planId,
    required this.status,
    required this.expiresAt,
  });

  @override
  List<Object?> get props => [planId, status, expiresAt];
}

class BandProfileEntity extends Equatable {
  final String description;
  final List<String> genres;
  final List<String> mediaLinks;
  final String? techRiderUrl;
  final String? biography;

  const BandProfileEntity({
    required this.description,
    required this.genres,
    required this.mediaLinks,
    this.techRiderUrl,
    this.biography,
  });

  @override
  List<Object?> get props =>
      [description, genres, mediaLinks, techRiderUrl, biography];
}

class BandSettingsEntity extends Equatable {
  final bool isPromoted;

  const BandSettingsEntity({
    required this.isPromoted,
  });

  @override
  List<Object?> get props => [isPromoted];
}
