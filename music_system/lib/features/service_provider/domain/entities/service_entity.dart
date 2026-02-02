import 'package:equatable/equatable.dart';

enum ServiceCategory {
  artist,
  infrastructure,
  catering,
  security,
  media,
}

enum ServiceStatus {
  pending,
  active,
  rejected,
}

abstract class TechnicalDetails extends Equatable {
  const TechnicalDetails();

  Map<String, dynamic> toJson();
}

class ServiceEntity extends Equatable {
  final String id;
  final String providerId;
  final String name;
  final String description;
  final ServiceCategory category;
  final double basePrice;
  final String priceDescription;
  final ServiceStatus status;
  final TechnicalDetails technicalDetails;
  final DateTime createdAt;

  const ServiceEntity({
    required this.id,
    required this.providerId,
    required this.name,
    required this.description,
    required this.category,
    required this.basePrice,
    required this.priceDescription,
    required this.status,
    required this.technicalDetails,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        providerId,
        name,
        description,
        category,
        basePrice,
        priceDescription,
        status,
        technicalDetails,
        createdAt,
      ];
}

// --- Specific Technical Details Implementations ---

class ArtistDetails extends TechnicalDetails {
  final String? stageMapUrl;
  final String? repertoireUrl;
  final String genre;

  const ArtistDetails(
      {this.stageMapUrl, this.repertoireUrl, required this.genre});

  @override
  Map<String, dynamic> toJson() => {
        'stageMapUrl': stageMapUrl,
        'repertoireUrl': repertoireUrl,
        'genre': genre,
      };

  @override
  List<Object?> get props => [stageMapUrl, repertoireUrl, genre];
}

class InfrastructureDetails extends TechnicalDetails {
  final Map<String, bool> powerRequirements; // '110v': true, '220v': false...
  final double kva;
  final double vehicleHeight;
  final String loadInTime;
  final String? implementationMapUrl;

  const InfrastructureDetails({
    required this.powerRequirements,
    required this.kva,
    required this.vehicleHeight,
    required this.loadInTime,
    this.implementationMapUrl,
  });

  @override
  Map<String, dynamic> toJson() => {
        'powerRequirements': powerRequirements,
        'kva': kva,
        'vehicleHeight': vehicleHeight,
        'loadInTime': loadInTime,
        'implementationMapUrl': implementationMapUrl,
      };

  @override
  List<Object?> get props =>
      [powerRequirements, kva, vehicleHeight, loadInTime, implementationMapUrl];
}

class CateringDetails extends TechnicalDetails {
  final List<String> menuImageUrls;
  final List<String> dietaryTags; // vegan, gluten_free...
  final bool needsKitchenOnSite;
  final bool tastingAvailable;

  const CateringDetails({
    required this.menuImageUrls,
    required this.dietaryTags,
    required this.needsKitchenOnSite,
    required this.tastingAvailable,
  });

  @override
  Map<String, dynamic> toJson() => {
        'menuImageUrls': menuImageUrls,
        'dietaryTags': dietaryTags,
        'needsKitchenOnSite': needsKitchenOnSite,
        'tastingAvailable': tastingAvailable,
      };

  @override
  List<Object?> get props =>
      [menuImageUrls, dietaryTags, needsKitchenOnSite, tastingAvailable];
}

class SecurityDetails extends TechnicalDetails {
  final List<String> certificationUrls;
  final bool hasWeapon;
  final String uniformType; // 'formal', 'tactical'
  final int staffPerShift;

  const SecurityDetails({
    required this.certificationUrls,
    required this.hasWeapon,
    required this.uniformType,
    required this.staffPerShift,
  });

  @override
  Map<String, dynamic> toJson() => {
        'certificationUrls': certificationUrls,
        'hasWeapon': hasWeapon,
        'uniformType': uniformType,
        'staffPerShift': staffPerShift,
      };

  @override
  List<Object?> get props =>
      [certificationUrls, hasWeapon, uniformType, staffPerShift];
}

class MediaDetails extends TechnicalDetails {
  final List<String> portfolioUrls;
  final List<String> equipmentList;
  final int deliveryTimeDays;

  const MediaDetails({
    required this.portfolioUrls,
    required this.equipmentList,
    required this.deliveryTimeDays,
  });

  @override
  Map<String, dynamic> toJson() => {
        'portfolioUrls': portfolioUrls,
        'equipmentList': equipmentList,
        'deliveryTimeDays': deliveryTimeDays,
      };

  @override
  List<Object?> get props => [portfolioUrls, equipmentList, deliveryTimeDays];
}
