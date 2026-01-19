import 'package:livekit_client/livekit_client.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

class LiveKitService {
  Room? _room;
  EventsListener<RoomEvent>? _listener;

  Room? get room => _room;

  Future<Map<String, String>> getToken(
      String roomName, String participantName) async {
    try {
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('getLiveKitToken');
      final result = await callable.call({
        'roomName': roomName,
        'participantName': participantName,
      });

      return {
        'token': result.data['token'] as String,
        'serverUrl': result.data['serverUrl'] as String,
      };
    } catch (e) {
      debugPrint('Error calling Cloud Function: $e');
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
