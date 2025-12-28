import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

class MultimediaCard extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback? onTap;
  final bool autoPlay;

  const MultimediaCard({
    super.key,
    required this.content,
    this.onTap,
    this.autoPlay = false,
  });

  @override
  State<MultimediaCard> createState() => _MultimediaCardState();
}

class _MultimediaCardState extends State<MultimediaCard> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.content['type'] == 'video' && widget.content['media_url'] != null) {
      _initializeVideoPlayer();
    } else if (widget.content['type'] == 'audio') {
      _audioPlayer = AudioPlayer();
    }
  }

  @override
  void dispose() {
    if (_chewieController != null) {
      _chewieController!.dispose();
    }
    if (_videoController != null) {
      _videoController.dispose();
    }
    if (_audioPlayer != null) {
      _audioPlayer.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      _videoController = VideoPlayerController.network(
        widget.content['media_url'],
      );
      
      await _videoController.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: widget.autoPlay,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blue,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey.shade300,
        ),
        placeholder: Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return const Center(
            child: Text(
              'Video tidak dapat diputar',
              style: TextStyle(color: Colors.grey),
            ),
          );
        },
      );
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chewieController = null;
        });
      }
    }
  }

  Future<void> _playAudio() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      await _audioPlayer.play(UrlSource(widget.content['media_url']));
      
      setState(() {
        _isPlaying = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memutar audio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.content;
    final type = content['type'];
    final isAudioOnly = content['is_audio_only'] ?? false;
    final hasSubtitles = content['has_subtitles'] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail/Video/Audio Player Area
          if (type == 'video')
            _buildVideoPlayer()
          else if (type == 'audio')
            _buildAudioPlayer()
          else
            _buildThumbnail(),

          // Content Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  content['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 18, // Besar untuk lansia
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Category & Duration
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        content['category'] ?? 'Umum',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (content['duration'] != null)
                      Row(
                        children: [
                          Icon(
                            type == 'video' ? Icons.videocam : Icons.audiotrack,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            content['duration'] != null
                                ? _formatDuration(content['duration'])
                                : '-',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Excerpt/Description
                if (content['excerpt'] != null && content['excerpt'].isNotEmpty)
                  Text(
                    content['excerpt'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 12),

                // Accessibility Features
                if (hasSubtitles || isAudioOnly)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (hasSubtitles)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.subtitles,
                                size: 12,
                                color: Colors.green,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Subtitle',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isAudioOnly)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.headphones,
                                size: 12,
                                color: Colors.purple,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Audio Saja',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.purple,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onTap,
                        icon: Icon(
                          type == 'video'
                              ? Icons.play_arrow
                              : type == 'audio'
                                  ? Icons.headphones
                                  : Icons.read_more,
                        ),
                        label: Text(
                          type == 'video'
                              ? 'Tonton'
                              : type == 'audio'
                                  ? 'Dengarkan'
                                  : 'Baca',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        // Share functionality
                      },
                      icon: const Icon(Icons.share),
                      tooltip: 'Bagikan',
                    ),
                    IconButton(
                      onPressed: () {
                        // Bookmark functionality
                      },
                      icon: const Icon(Icons.bookmark_border),
                      tooltip: 'Simpan',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Chewie(controller: _chewieController!),
      );
    } else {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.grey[200],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  'Memuat video...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildAudioPlayer() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple[100]!, Colors.blue[100]!],
        ),
      ),
      child: Stack(
        children: [
          // Background waves
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/images/audio_waves.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Audio controls
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.music_note,
                  size: 40,
                  color: Colors.purple,
                ),
                const SizedBox(height: 8),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  IconButton(
                    onPressed: _isPlaying ? _pauseAudio : _playAudio,
                    icon: Icon(
                      _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      size: 40,
                      color: Colors.blue,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    final thumbnail = widget.content['thumbnail'];
    
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: thumbnail != null
          ? Image.network(
              thumbnail,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.image,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            )
          : Container(
              color: Colors.grey[200],
              child: Center(
                child: Icon(
                  widget.content['type'] == 'article'
                      ? Icons.article
                      : Icons.image,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
            ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}