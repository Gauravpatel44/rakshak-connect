import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../models/alert_model.dart';
import '../services/audio_recorder_service.dart';

/// List tile for displaying an alert history entry with ambient audio evidence playback
class AlertHistoryTile extends StatefulWidget {
  final AlertModel alert;

  const AlertHistoryTile({super.key, required this.alert});

  @override
  State<AlertHistoryTile> createState() => _AlertHistoryTileState();
}

class _AlertHistoryTileState extends State<AlertHistoryTile> {
  static _AlertHistoryTileState? _activePlayingTile;

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  @override
  void dispose() {
    if (_activePlayingTile == this) {
      _activePlayingTile = null;
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    final rawPath = widget.alert.audioPath;
    if (rawPath == null || rawPath.isEmpty) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
      if (_activePlayingTile == this) _activePlayingTile = null;
    } else {
      // Pause any previously playing tile first
      if (_activePlayingTile != null && _activePlayingTile != this) {
        await _activePlayingTile?._audioPlayer.pause();
      }
      _activePlayingTile = this;

      final resolvedPath =
          await AudioRecorderService.resolveAudioPath(rawPath);
      if (resolvedPath == null) return;

      try {
        if (resolvedPath.startsWith('http')) {
          await _audioPlayer.play(UrlSource(resolvedPath));
        } else {
          await _audioPlayer.play(DeviceFileSource(resolvedPath));
        }
      } catch (e) {
        debugPrint('⚠️ AlertHistoryTile: Failed to play audio: $e');
      }
    }
  }

  Future<void> _openLocationMap() async {
    final uri = Uri.parse(widget.alert.locationLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final dateStr = DateFormat('dd MMM yyyy').format(alert.time);
    final timeStr = DateFormat('hh:mm a').format(alert.time);
    final isSuccess = alert.status == AlertStatus.success;
    final isFailed = alert.status == AlertStatus.failed;
    final statusColor = isSuccess
        ? AppColors.success
        : isFailed
            ? AppColors.error
            : Colors.amber.shade800;
    final statusBgColor = isSuccess
        ? AppColors.successLight
        : isFailed
            ? AppColors.errorLight
            : Colors.amber.shade100;
    final hasAudioFile =
        alert.hasAudio && AudioRecorderService.audioFileExists(alert.audioPath);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // ── Alert Icon ───────────────────────────
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (isFailed ? AppColors.error : AppColors.primary)
                        .withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isFailed
                        ? Icons.error_outline_rounded
                        : Icons.notifications_active_rounded,
                    color: isFailed ? AppColors.error : AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // ── Date, Time, Contacts ──────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Emergency Alert',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$dateStr, $timeStr',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sent to ${alert.contactsNotified} contacts',
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Status Badge ──────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    alert.status.label,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            // ── Audio Recording Evidence Player Bar ──────
            if (hasAudioFile) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton.filled(
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(36, 36),
                      ),
                      onPressed: _toggleAudio,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.mic_rounded,
                                  color: AppColors.primary, size: 14),
                              const SizedBox(width: 4),
                              const Text(
                                'Ambient Audio Evidence',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 10),
                            ),
                            child: Slider(
                              value: _position.inMilliseconds
                                  .clamp(0, _duration.inMilliseconds)
                                  .toDouble(),
                              max: (_duration.inMilliseconds > 0
                                      ? _duration.inMilliseconds
                                      : 1)
                                  .toDouble(),
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                _audioPlayer.seek(
                                    Duration(milliseconds: val.toInt()));
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),

            // ── Location Link Quick Button ───────────────
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _openLocationMap,
                icon: const Icon(Icons.map_rounded, size: 16),
                label: const Text(
                  'View GPS Coordinates',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
