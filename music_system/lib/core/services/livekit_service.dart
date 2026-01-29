import 'package:livekit_client/livekit_client.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class LiveKitService {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  final Dio _dio = Dio();

  Room? get room => _room;

  Future<Map<String, String>> getToken(
      String roomName, String participantName) async {
    try {
      // In a real production app, this URL should be in a configuration file or environment variable
      const String apiUrl = 'http://137.131.245.16/api/live/token';

      final response = await _dio.post(apiUrl, data: {
        'roomName': roomName,
        'participantName': participantName,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        return {
          'token': data['token'] as String,
          'serverUrl': data['serverUrl'] as String,
        };
      } else {
        throw Exception('Failed to get token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error calling backend for LiveKit token: $e');
      rethrow;
    }
  }

  Future<Room> connect(String url, String token) async {
    try {
      // Create a room
      final room = Room();

      // Connect to the room
      await room.connect(url, token);

      _room = room;

      // Setup listeners if needed
      _listener = room.createListener();
      _listener!.on<RoomDisconnectedEvent>((event) {
        debugPrint('Disconnected from room: ${event.reason}');
        _room = null;
      });

      return room;
    } catch (e) {
      debugPrint('Error connecting to LiveKit: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await _room?.disconnect();
    _room = null;
    _listener?.dispose();
    _listener = null;
  }

  Future<void> setMicrophoneEnabled(bool enabled) async {
    await _room?.localParticipant?.setMicrophoneEnabled(enabled);
  }

  Future<void> setCameraEnabled(bool enabled) async {
    await _room?.localParticipant?.setCameraEnabled(enabled);
  }
}
