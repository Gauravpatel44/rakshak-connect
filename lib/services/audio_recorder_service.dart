import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Service to handle automatic background ambient audio recording during emergency SOS
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _stopTimer;
  String? _currentRecordingPath;
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  /// Start recording ambient emergency audio for [durationSeconds] (default 20 seconds)
  Future<String?> startEmergencyRecording({int durationSeconds = 20}) async {
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final path = '${dir.path}/emergency_audio_$timestamp.m4a';

        _currentRecordingPath = path;
        _isRecording = true;

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 64000,
            sampleRate: 44100,
          ),
          path: path,
        );

        debugPrint('🎙️ AudioRecorderService: Emergency recording started at $path');

        // Automatically stop after durationSeconds
        _stopTimer?.cancel();
        _stopTimer = Timer(Duration(seconds: durationSeconds), () async {
          await stopRecording();
        });

        return path;
      } else {
        debugPrint('⚠️ AudioRecorderService: Microphone permission denied.');
        return null;
      }
    } catch (e) {
      debugPrint('⚠️ AudioRecorderService: Recording failed to start: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Stop current recording and return the saved audio path
  Future<String?> stopRecording() async {
    _stopTimer?.cancel();
    _stopTimer = null;

    if (!_isRecording) return _currentRecordingPath;

    try {
      final path = await _recorder.stop();
      _isRecording = false;
      debugPrint('🎙️ AudioRecorderService: Recording stopped successfully. File: $path');
      return path ?? _currentRecordingPath;
    } catch (e) {
      debugPrint('⚠️ AudioRecorderService: Failed to stop recording: $e');
      _isRecording = false;
      return _currentRecordingPath;
    }
  }

  /// Check if an audio file exists locally (resolving both absolute and relative document paths)
  static bool audioFileExists(String? path) {
    if (path == null || path.isEmpty) return false;
    if (path.startsWith('http')) return true;
    return File(path).existsSync();
  }

  /// Resolve file path to ensure persistence across Android app directory reallocations
  static Future<String?> resolveAudioPath(String? path) async {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;

    final directFile = File(path);
    if (directFile.existsSync()) return path;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filename = path.split(RegExp(r'[/\\]')).last;
      final resolved = '${dir.path}/$filename';
      if (File(resolved).existsSync()) return resolved;
    } catch (_) {}

    return path;
  }

  void dispose() {
    _stopTimer?.cancel();
    _recorder.dispose();
  }
}
