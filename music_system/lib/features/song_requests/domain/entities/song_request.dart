import 'package:equatable/equatable.dart';

class SongRequest extends Equatable {
  final String id;
  final String songName;
  final String artistName;
  final String? clientName;
  final String musicianId; // ID do músico que recebeu o pedido
  final double tipAmount; // 0.0 se não houver gorjeta
  final bool isCustomRequest; // True se não estava no repertório
  final String status; // 'pending', 'accepted', 'declined', 'completed'
  final DateTime createdAt;

  const SongRequest({
    required this.id,
    required this.songName,
    required this.artistName,
    this.clientName,
    required this.musicianId,
    this.tipAmount = 0.0,
    this.isCustomRequest = false,
    this.status = 'pending',
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        songName,
        artistName,
        clientName,
        musicianId,
        tipAmount,
        isCustomRequest,
        status,
        createdAt,
      ];
}
