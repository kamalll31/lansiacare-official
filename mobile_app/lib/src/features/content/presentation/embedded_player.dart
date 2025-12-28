import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class EmbeddedPlayer extends StatefulWidget {
  final Map<String, dynamic> content;
  final VoidCallback? onBack;
  final VoidCallback? onCompleted;
  
  const EmbeddedPlayer({
    super.key,
    required this.content,
    this.onBack,
    this.onCompleted,
  });

  @override
  State<EmbeddedPlayer> createState() => _EmbeddedPlayerState();
}

class _EmbeddedPlayerState extends State<EmbeddedPlayer> {
  // YouTube Player
  YoutubePlayerController? _youtubeController;
  
  // Video Player (for uploaded videos)
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  
  // Audio Player
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  
  // Accessibility Features
  bool _showSubtitles = false;
  double _playbackSpeed = 1.0;
  
  // Player state
  PlayerState _playerState = PlayerState.stopped;
  
  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }
  
  @override
  void dispose() {
    _youtubeController?.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }
  
  Future<void> _initializePlayer() async {
    try {
      final content = widget.content;
      final type = content['type'];
      final provider = content['embed_provider'];
      
      // Initialize based on content type
      if (type == 'embedded_video' && provider == 'youtube' && content['embed_id'] != null) {
        // YouTube Player
        _youtubeController = YoutubePlayerController(
          initialVideoId: content['embed_id'],
          flags: YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            enableCaption: true,
            captionLanguage: 'id',
            showLiveFullscreenButton: false,
            controlsVisibleAtStart: true,
            useHybridComposition: true,
            hideControls: false,
          ),
        );
        
        await _youtubeController!.initialize();
        
        // Listen for completion
        _youtubeController!.addListener(() {
          if (_youtubeController!.value.playerState == PlayerState.ended) {
            widget.onCompleted?.call();
          }
        });
        
      } else if (type == 'embedded_audio' && provider == 'spotify') {
        // Spotify - embedded web player
        // For mobile, we'll use a WebView or open externally
        
      } else if (type == 'uploaded_video' && content['media_url'] != null) {
        // Local video player for uploaded videos
        _videoController = VideoPlayerController.network(
          content['media_url'],
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
        );
        
        await _videoController!.initialize();
        
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: true,
          looping: false,
          allowFullScreen: true,
          allowMuting: true,
          showControls: true,
          showControlsOnInitialize: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: Colors.blue,
            handleColor: Colors.blue,
            backgroundColor: Colors.grey,
            bufferedColor: Colors.grey.shade300,
          ),
          placeholder: Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Video tidak dapat diputar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
        
        // Listen for video completion
        _videoController!.addListener(() {
          if (_videoController!.value.position >= _videoController!.value.duration) {
            widget.onCompleted?.call();
          }
        });
        
      } else if (type == 'uploaded_audio' && content['media_url'] != null) {
        // Local audio player for uploaded audio
        _audioPlayer = AudioPlayer();
        
        // Setup event listeners
        _audioPlayer!.onPlayerStateChanged.listen((state) {
          setState(() {
            _playerState = state;
            _isPlaying = state == PlayerState.playing;
          });
          
          if (state == PlayerState.completed) {
            widget.onCompleted?.call();
          }
        });
        
        _audioPlayer!.onDurationChanged.listen((duration) {
          setState(() {
            _duration = duration;
          });
        });
        
        _audioPlayer!.onPositionChanged.listen((position) {
          setState(() {
            _position = position;
          });
        });
        
        _audioPlayer!.onSeekComplete.listen((_) {
          // Seek completed
        });
        
        // Load and play audio
        await _audioPlayer!.setSource(UrlSource(content['media_url']));
        await _audioPlayer!.play();
        
      } else if (type == 'article' && content['content'] != null) {
        // Article content - show text with accessibility features
        
      } else {
        throw Exception('Tipe konten tidak didukung');
      }
      
      setState(() {
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat konten: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
  Future<void> _openInExternalApp() async {
    final content = widget.content;
    final url = content['video_url'] ?? content['embed_url'];
    
    if (url != null) {
      try {
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat membuka aplikasi eksternal'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _togglePlayPause() async {
    if (_audioPlayer != null) {
      if (_isPlaying) {
        await _audioPlayer!.pause();
      } else {
        await _audioPlayer!.play();
      }
    } else if (_youtubeController != null) {
      if (_youtubeController!.value.isPlaying) {
        _youtubeController!.pause();
      } else {
        _youtubeController!.play();
      }
    } else if (_videoController != null) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    }
  }
  
  Future<void> _seekTo(Duration position) async {
    if (_audioPlayer != null) {
      await _audioPlayer!.seek(position);
    } else if (_youtubeController != null) {
      _youtubeController!.seekTo(position);
    } else if (_videoController != null) {
      await _videoController!.seekTo(position);
    }
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
  
  void _toggleSubtitles() {
    setState(() {
      _showSubtitles = !_showSubtitles;
    });
    
    if (_youtubeController != null) {
      // Toggle YouTube captions
      _youtubeController!.toggleCaption();
    }
  }
  
  void _changePlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    
    if (_audioPlayer != null) {
      _audioPlayer!.setPlaybackRate(speed);
    } else if (_videoController != null) {
      _videoController!.setPlaybackSpeed(speed);
    }
  }
  
  Widget _buildYouTubePlayer() {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.blue,
        progressColors: const ProgressBarColors(
          playedColor: Colors.blue,
          handleColor: Colors.blueAccent,
        ),
        onReady: () {
          // Player is ready
        },
        onEnded: (data) {
          widget.onCompleted?.call();
        },
      ),
      builder: (context, player) {
        return Column(
          children: [
            // Player
            AspectRatio(
              aspectRatio: 16 / 9,
              child: player,
            ),
            
            // Controls
            _buildControls(),
          ],
        );
      },
    );
  }
  
  Widget _buildVideoPlayer() {
    return Column(
      children: [
        // Video Player
        AspectRatio(
          aspectRatio: 16 / 9,
          child: _chewieController != null && _videoController!.value.isInitialized
              ? Chewie(controller: _chewieController!)
              : Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                ),
        ),
        
        // Controls
        _buildControls(),
      ],
    );
  }
  
  Widget _buildAudioPlayer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade800,
            Colors.blue.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Album Art / Icon
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.music_note,
              size: 80,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Title
          Text(
            widget.content['title'] ?? 'Audio',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 10),
          
          // Category
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.content['category_display'] ?? 'Audio',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Progress Indicator
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _position.inSeconds.toDouble(),
                    min: 0,
                    max: _duration.inSeconds.toDouble(),
                    onChanged: (value) {
                      _seekTo(Duration(seconds: value.toInt()));
                    },
                  ),
                ),
                
                // Time Labels
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Audio Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Playback Speed
              IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (context) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Kecepatan Pemutaran',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ...<double>[0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
                              return ListTile(
                                leading: Icon(
                                  speed == _playbackSpeed ? Icons.check : null,
                                  color: Colors.blue,
                                ),
                                title: Text(
                                  '${speed}x',
                                  style: TextStyle(
                                    fontWeight: speed == _playbackSpeed ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                onTap: () {
                                  _changePlaybackSpeed(speed);
                                  Navigator.pop(context);
                                },
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  );
                },
                icon: Icon(
                  _playbackSpeed == 1.0 ? Icons.speed : Icons.speed_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              
              // Rewind 10 seconds
              IconButton(
                onPressed: () {
                  final newPosition = _position - const Duration(seconds: 10);
                  if (newPosition.inSeconds > 0) {
                    _seekTo(newPosition);
                  } else {
                    _seekTo(Duration.zero);
                  }
                },
                icon: const Icon(
                  Icons.replay_10,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              
              // Play/Pause
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _togglePlayPause,
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: Colors.purple,
                    size: 56,
                  ),
                ),
              ),
              
              // Forward 10 seconds
              IconButton(
                onPressed: () {
                  final newPosition = _position + const Duration(seconds: 10);
                  if (newPosition < _duration) {
                    _seekTo(newPosition);
                  } else {
                    _seekTo(_duration);
                  }
                },
                icon: const Icon(
                  Icons.forward_10,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              
              // Open in External App
              IconButton(
                onPressed: _openInExternalApp,
                icon: const Icon(
                  Icons.open_in_new,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          
          // Audio Only Indicator
          if (widget.content['is_audio_only'] == true)
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.headphones,
                    size: 14,
                    color: Colors.green,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Audio Saja',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildArticleContent() {
    final content = widget.content['content'] ?? '';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            widget.content['title'] ?? 'Artikel',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          // Category
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.content['category_display'] ?? 'Artikel',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Publish Date
          if (widget.content['published_at'] != null)
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.content['time_ago'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          
          const SizedBox(height: 30),
          
          // Content
          Text(
            content,
            style: const TextStyle(
              fontSize: 18, // Large font for elderly
              height: 1.6,
              letterSpacing: 0.5,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Accessibility Features
          if (widget.content['has_transcript'] == true)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.accessible,
                    color: Colors.green,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konten Aksesibel',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Artikel ini didesain khusus untuk mudah dibaca lansia dengan font besar dan kontras tinggi.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildControls() {
    final content = widget.content;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // Back Button
          if (widget.onBack != null)
            IconButton(
              onPressed: widget.onBack,
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  content['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                // Duration
                Text(
                  content['duration_formatted'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          
          // Accessibility Features
          if (content['has_subtitles'] == true)
            IconButton(
              onPressed: _toggleSubtitles,
              icon: Icon(
                _showSubtitles ? Icons.subtitles : Icons.subtitles_outlined,
                color: _showSubtitles ? Colors.green : Colors.white70,
              ),
              tooltip: 'Subtitle',
            ),
          
          // Open in External
          IconButton(
            onPressed: _openInExternalApp,
            icon: const Icon(
              Icons.open_in_new,
              color: Colors.white70,
            ),
            tooltip: 'Buka di aplikasi lain',
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.blue,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Memuat konten...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Text(
            widget.content['title'] ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 20),
          Text(
            'Gagal memuat konten',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            _errorMessage,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _initializePlayer,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final content = widget.content;
    final type = content['type'];
    
    if (_isLoading) {
      return _buildLoading();
    }
    
    if (_hasError) {
      return _buildError();
    }
    
    // Build appropriate player based on content type
    Widget playerWidget;
    
    if (type == 'embedded_video' && _youtubeController != null) {
      playerWidget = _buildYouTubePlayer();
    } else if (type == 'uploaded_video' && _videoController != null) {
      playerWidget = _buildVideoPlayer();
    } else if ((type == 'embedded_audio' || type == 'uploaded_audio') && _audioPlayer != null) {
      playerWidget = _buildAudioPlayer();
    } else if (type == 'article') {
      playerWidget = _buildArticleContent();
    } else {
      playerWidget = _buildError();
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Player Area
            Expanded(
              child: playerWidget,
            ),
            
            // Elderly-Friendly Controls
            if (type != 'article')
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[900],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Large Play/Pause Button
                    ElevatedButton.icon(
                      onPressed: _togglePlayPause,
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 24,
                      ),
                      label: Text(
                        _isPlaying ? 'Jeda' : 'Mainkan',
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        minimumSize: const Size(120, 60),
                      ),
                    ),
                    
                    // Replay 30 Seconds (for elderly who might miss something)
                    ElevatedButton.icon(
                      onPressed: () {
                        final newPosition = _position - const Duration(seconds: 30);
                        if (newPosition.inSeconds > 0) {
                          _seekTo(newPosition);
                        } else {
                          _seekTo(Duration.zero);
                        }
                      },
                      icon: const Icon(Icons.replay_30, size: 24),
                      label: const Text(
                        'Ulang 30dtk',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    
                    // Slow Down Button
                    ElevatedButton.icon(
                      onPressed: () {
                        _changePlaybackSpeed(0.75);
                      },
                      icon: const Icon(Icons.slow_motion_video, size: 24),
                      label: const Text(
                        'Lambat',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Accessibility Information
            if (content['accessibility_score'] != null)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey[800],
                child: Row(
                  children: [
                    const Icon(
                      Icons.accessible_forward,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Skor Aksesibilitas',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: content['accessibility_score'] / 100,
                            backgroundColor: Colors.grey,
                            color: Colors.green,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${content['accessibility_score']}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}