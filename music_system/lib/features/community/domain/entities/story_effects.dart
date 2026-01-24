import 'package:equatable/equatable.dart';

class StoryEffects extends Equatable {
  final String? filterId;
  final double? startOffset; // seconds
  final double? endOffset; // seconds

  const StoryEffects({
    this.filterId,
    this.startOffset,
    this.endOffset,
  });

  Map<String, dynamic> toJson() => {
        'filterId': filterId,
        'startOffset': startOffset,
        'endOffset': endOffset,
      };

  factory StoryEffects.fromJson(Map<String, dynamic> json) => StoryEffects(
        filterId: json['filterId'],
        startOffset: (json['startOffset'] as num?)?.toDouble(),
        endOffset: (json['endOffset'] as num?)?.toDouble(),
      );

  @override
  List<Object?> get props => [filterId, startOffset, endOffset];
}
