import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/service_entity.dart';

class ServiceModel extends ServiceEntity {
  const ServiceModel({
    required super.id,
    required super.providerId,
    required super.name,
    required super.description,
    required super.category,
    required super.basePrice,
    required super.priceDescription,
    required super.status,
    required super.technicalDetails,
    super.location,
    super.imageUrl,
    required super.createdAt,
  });

  factory ServiceModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServiceModel.fromJson(data, doc.id);
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json, String id) {
    final categoryStr = json['category'] as String;
    final category = ServiceCategory.values.firstWhere(
      (e) => e.toString().split('.').last == categoryStr,
      orElse: () => ServiceCategory.artist,
    );

    final statusStr = json['status'] as String;
    final status = ServiceStatus.values.firstWhere(
      (e) => e.toString().split('.').last == statusStr,
      orElse: () => ServiceStatus.pending,
    );

    DateTime createdAtDate;
    final rawCreatedAt = json['createdAt'];
    if (rawCreatedAt is Timestamp) {
      createdAtDate = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      createdAtDate = DateTime.parse(rawCreatedAt);
    } else {
      createdAtDate = DateTime.now();
    }

    return ServiceModel(
      id: id,
      providerId: json['providerId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: category,
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      priceDescription: json['priceDescription'] ?? '',
      status: status,
      technicalDetails:
          _technicalDetailsFromJson(json['technicalDetails'], category),
      imageUrl: json['imageUrl'],
      createdAt: createdAtDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // Included ID for the backend API
      'providerId': providerId,
      'name': name,
      'description': description,
      'category': category.toString().split('.').last,
      'basePrice': basePrice,
      'priceDescription': priceDescription,
      'status': status.toString().split('.').last,
      'technicalDetails': technicalDetails.toJson(),
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static TechnicalDetails _technicalDetailsFromJson(
      Map<String, dynamic>? json, ServiceCategory category) {
    if (json == null) return const ArtistDetails(genre: '');

    switch (category) {
      case ServiceCategory.artist:
        return ArtistDetails(
          stageMapUrl: json['stageMapUrl'],
          repertoireUrl: json['repertoireUrl'],
          genre: json['genre'] ?? '',
        );
      case ServiceCategory.infrastructure:
        return InfrastructureDetails(
          powerRequirements:
              Map<String, bool>.from(json['powerRequirements'] ?? {}),
          kva: (json['kva'] ?? 0).toDouble(),
          vehicleHeight: (json['vehicleHeight'] ?? 0).toDouble(),
          loadInTime: json['loadInTime'] ?? '',
          implementationMapUrl: json['implementationMapUrl'],
        );
      case ServiceCategory.catering:
        return CateringDetails(
          menuImageUrls: List<String>.from(json['menuImageUrls'] ?? []),
          dietaryTags: List<String>.from(json['dietaryTags'] ?? []),
          needsKitchenOnSite: json['needsKitchenOnSite'] ?? false,
          tastingAvailable: json['tastingAvailable'] ?? false,
        );
      case ServiceCategory.security:
        return SecurityDetails(
          certificationUrls: List<String>.from(json['certificationUrls'] ?? []),
          hasWeapon: json['hasWeapon'] ?? false,
          uniformType: json['uniformType'] ?? 'formal',
          staffPerShift: json['staffPerShift'] ?? 0,
        );
      case ServiceCategory.media:
        return MediaDetails(
          portfolioUrls: List<String>.from(json['portfolioUrls'] ?? []),
          equipmentList: List<String>.from(json['equipmentList'] ?? []),
          deliveryTimeDays: json['deliveryTimeDays'] ?? 0,
        );
    }
  }
}
