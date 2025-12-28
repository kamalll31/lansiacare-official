import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:admin_web/src/features/content/view_models/content_view_model.dart';
import 'package:admin_web/src/shared/models/content.dart';
import 'package:admin_web/src/shared/widgets/custom_app_bar.dart';

// ==============================================================================
// BAGIAN 1: MAIN STATE & LOGIC
// ==============================================================================

class HybridContentEditor extends StatefulWidget {
  final int? contentId;
  
  const HybridContentEditor({
    super.key,
    this.contentId,
  });

  @override
  State<HybridContentEditor> createState() => _HybridContentEditorState();
}

class _HybridContentEditorState extends State<HybridContentEditor> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late final TextEditingController _titleController;
  late final TextEditingController _excerptController;
  late final TextEditingController _urlController;
  late final TextEditingController _durationController;
  late final TextEditingController _contentTextController;
  
  // State Variables
  ContentType _selectedType = ContentType.embeddedVideo;
  ContentCategory _selectedCategory = ContentCategory.kesehatanPraktis;
  
  // Settings Flags
  bool _isPublished = false;
  bool _isFeatured = false;
  bool _isPinned = false;
  bool _isAudioOnly = false;
  bool _hasSubtitles = false;
  bool _hasTranscript = false;
  bool _hasAudioDescription = false;
  
  // Media Data
  String? _mediaUrl;
  String? _embedUrl;
  String? _thumbnailUrl;
  String? _embedProvider;
  String? _embedId;
  String? _embedType;
  
  // UI State
  bool _isUploading = false;
  String? _uploadError;
  bool _isAnalyzing = false;
  bool _isValidUrl = false;
  String _analysisResult = '';
  bool _isInit = true; 
  bool _isSaving = false; // Tambahan untuk loading save

  // Tools
  YoutubePlayerController? _youtubeController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _excerptController = TextEditingController();
    _urlController = TextEditingController();
    _durationController = TextEditingController();
    _contentTextController = TextEditingController();
    
    _urlController.addListener(_debounceAnalyzeUrl);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      if (widget.contentId != null) {
        _loadContent();
      }
      _isInit = false;
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _excerptController.dispose();
    _urlController.dispose();
    _durationController.dispose();
    _contentTextController.dispose();
    _youtubeController?.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadContent() async {
    final viewModel = context.read<ContentViewModel>();
    await viewModel.fetchContentDetail(widget.contentId!);
    
    final content = viewModel.selectedContent;
    if (content != null && mounted) {
      setState(() {
        _titleController.text = content.title;
        _excerptController.text = content.excerpt;
        _selectedType = content.contentType;
        _selectedCategory = content.category;
        _isPublished = content.isPublished;
        _isFeatured = content.isFeatured;
        _isPinned = content.isPinned;
        _isAudioOnly = content.isAudioOnly;
        _hasSubtitles = content.hasSubtitles;
        _hasTranscript = content.hasTranscript;
        _hasAudioDescription = content.hasAudioDescription;
        _durationController.text = content.durationFormatted;
        _thumbnailUrl = content.thumbnailUrl;
        
        if (content.contentType.isEmbedded) {
          _embedUrl = content.embedUrl;
          _urlController.text = content.embedUrl ?? '';
          _embedProvider = content.embedProvider;
          _embedId = content.embedId;
          _embedType = content.embedType;
          _isValidUrl = true;
          
          if (_embedProvider == 'youtube' && _embedId != null) {
            _initYoutubeController(_embedId!);
          }
        } else if (content.contentType.isUploaded) {
          _mediaUrl = content.mediaUrl;
        } else if (content.contentType == ContentType.article) {
          _contentTextController.text = content.contentText ?? '';
        }
      });
    }
  }

  void _initYoutubeController(String videoId) {
    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );
  }
  
  void _debounceAnalyzeUrl() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), _analyzeUrl);
  }
  
  Future<void> _analyzeUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _isValidUrl = false;
        _analysisResult = '';
        _youtubeController = null;
      });
      return;
    }
    
    setState(() {
      _isAnalyzing = true;
      _analysisResult = 'Menganalisis URL...';
    });
    
    try {
      final viewModel = context.read<ContentViewModel>();
      // ✅ PERBAIKAN: analyzeUrl() return Map<String, dynamic>
      final result = await viewModel.analyzeUrl(url);
      
      if (!mounted) return;

      if (result['success'] == true && result['analysis'] != null) {
        final analysis = result['analysis'] as UrlAnalysis;
        
        setState(() {
          _isValidUrl = analysis.isValid;
          _analysisResult = analysis.isValid 
              ? '✅ URL valid - ${analysis.provider?.toUpperCase()}'
              : '❌ URL tidak valid';
          
          if (analysis.isValid) {
            _embedProvider = analysis.provider;
            _embedId = analysis.id;
            _embedType = analysis.type;
            _thumbnailUrl = analysis.thumbnailUrl;
            
            if (_titleController.text.isEmpty && analysis.title != null) {
              _titleController.text = analysis.title!;
            }
            if (_excerptController.text.isEmpty && analysis.description != null) {
              _excerptController.text = analysis.description!.length > 200
                  ? '${analysis.description!.substring(0, 200)}...'
                  : analysis.description!;
            }
            if (_durationController.text.isEmpty && analysis.duration != null) {
              final minutes = analysis.duration! ~/ 60;
              final seconds = analysis.duration! % 60;
              _durationController.text = '$minutes:${seconds.toString().padLeft(2, '0')}';
            }
            
            if (analysis.provider == 'youtube' || analysis.provider == 'vimeo') {
              _selectedType = ContentType.embeddedVideo;
            } else if (analysis.provider == 'spotify') {
              _selectedType = ContentType.embeddedAudio;
            }
            
            if (analysis.provider == 'youtube' && analysis.id != null) {
              _initYoutubeController(analysis.id!);
            }
          } else {
            _youtubeController = null;
          }
        });
      } else {
        setState(() {
          _isValidUrl = false;
          _analysisResult = '❌ ${result['error'] ?? 'URL tidak valid'}';
          _youtubeController = null;
        });
      }
    } catch (e) {
      setState(() {
        _isValidUrl = false;
        _analysisResult = '❌ Error: $e';
        _youtubeController = null;
      });
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }
  
  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: _selectedType.isVideo ? FileType.video : FileType.audio,
        allowMultiple: false,
        withData: true,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (file.size > 100 * 1024 * 1024) {
          setState(() => _uploadError = 'Ukuran file terlalu besar (Max 100MB)');
          return;
        }

        await _uploadFile(file);
      }
    } catch (e) {
      setState(() => _uploadError = 'Error picking file: $e');
    }
  }
  
  Future<void> _uploadFile(PlatformFile file) async {
    setState(() {
      _isUploading = true;
      _uploadError = null;
    });
    
    try {
      final viewModel = context.read<ContentViewModel>();
      final type = _selectedType.isVideo ? 'video' : 'audio';
      
      // ✅ PERBAIKAN: uploadMedia() return Map<String, dynamic>
      final result = await viewModel.uploadMedia(file, type);
      
      if (!mounted) return;

      // ✅ PERBAIKAN: Akses sebagai Map, bukan class
      if (result['success'] == true) {
        setState(() {
          _mediaUrl = result['url'];
          // ✅ PERBAIKAN: ViewModel return 'duration', bukan 'duration_formatted'
          if (result['duration'] != null) {
            final duration = result['duration'] as int?;
            if (duration != null) {
              _durationController.text = _formatDuration(duration);
            }
          }
          _uploadError = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File berhasil diunggah'), 
            backgroundColor: Colors.green
          ),
        );
      } else {
        setState(() => _uploadError = result['error'] as String? ?? 'Upload gagal');
      }
    } catch (e) {
      setState(() => _uploadError = 'Error uploading: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
  
  // Helper untuk format durasi
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }
  
  int? _parseDuration() {
    final text = _durationController.text.trim();
    if (text.isEmpty) return null;
    
    try {
      if (text.contains(':')) {
        final parts = text.split(':').map((e) => int.tryParse(e) ?? 0).toList();
        if (parts.length == 3) { 
          return parts[0] * 3600 + parts[1] * 60 + parts[2];
        } else if (parts.length == 2) { 
          return parts[0] * 60 + parts[1];
        }
      }
      return int.tryParse(text) ?? 0; 
    } catch (_) {
      return null;
    }
  }
  
  Future<void> _saveContent() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedType.isEmbedded && !_isValidUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL tidak valid'), 
          backgroundColor: Colors.red
        ),
      );
      return;
    }
    
    if (_selectedType.isUploaded && _mediaUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap unggah file'), 
          backgroundColor: Colors.red
        ),
      );
      return;
    }
    
    if (_selectedType == ContentType.article && _contentTextController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konten artikel diperlukan'), 
          backgroundColor: Colors.red
        ),
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final content = ContentItem(
        id: widget.contentId ?? 0,
        title: _titleController.text,
        excerpt: _excerptController.text,
        contentType: _selectedType,
        embedUrl: _selectedType.isEmbedded ? _urlController.text : null,
        embedProvider: _embedProvider,
        embedId: _embedId,
        embedType: _embedType,
        mediaUrl: _selectedType.isUploaded ? _mediaUrl : null,
        thumbnailUrl: _thumbnailUrl,
        contentText: _selectedType == ContentType.article ? _contentTextController.text : null,
        duration: _parseDuration(),
        category: _selectedCategory,
        authorId: 1, 
        authorName: 'Admin',
        isPublished: _isPublished,
        isFeatured: _isFeatured,
        isPinned: _isPinned,
        isAudioOnly: _isAudioOnly,
        hasSubtitles: _hasSubtitles,
        hasTranscript: _hasTranscript,
        hasAudioDescription: _hasAudioDescription,
        accessibilityScore: 0,
        viewCount: 0,
        likeCount: 0,
        shareCount: 0,
        completionRate: 0,
        publishedAt: _isPublished ? DateTime.now() : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final viewModel = context.read<ContentViewModel>();
      bool success;
      
      // ✅ PERBAIKAN: createContent() dan updateContent() return Future<bool>
      if (widget.contentId != null) {
        success = await viewModel.updateContent(content);
      } else {
        success = await viewModel.createContent(content);
      }
      
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        if (success) {
          // Tampilkan success message dari ViewModel atau default
          final message = viewModel.successMessage ?? 
            (widget.contentId != null ? 'Konten diperbarui' : 'Konten dibuat');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          // Tampilkan error dari ViewModel
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(viewModel.error ?? 'Terjadi kesalahan saat menyimpan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.contentId != null ? 'Edit Konten' : 'Konten Baru',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save), 
            onPressed: _isSaving ? null : _saveContent,
            tooltip: 'Simpan',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TypeSelector(
                selectedType: _selectedType,
                onChanged: (type) {
                  setState(() {
                    _selectedType = type;
                    if (!type.isEmbedded) {
                      _isValidUrl = false;
                      _urlController.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              
              _BasicInfoForm(
                titleController: _titleController,
                excerptController: _excerptController,
                durationController: _durationController,
                selectedCategory: _selectedCategory,
                onCategoryChanged: (cat) => setState(() => _selectedCategory = cat),
              ),
              const SizedBox(height: 16),
              
              if (_selectedType.isEmbedded)
                _EmbeddedForm(
                  urlController: _urlController,
                  isAnalyzing: _isAnalyzing,
                  isValidUrl: _isValidUrl,
                  analysisResult: _analysisResult,
                  youtubeController: _youtubeController,
                  thumbnailUrl: _thumbnailUrl,
                  onAnalyze: _analyzeUrl,
                  onClear: () {
                    _urlController.clear();
                    setState(() {
                      _isValidUrl = false;
                      _youtubeController = null;
                    });
                  },
                )
              else if (_selectedType.isUploaded)
                _UploadForm(
                  selectedType: _selectedType,
                  mediaUrl: _mediaUrl,
                  isUploading: _isUploading,
                  uploadError: _uploadError,
                  onPickAndUpload: _pickAndUploadFile,
                  onClear: () => setState(() => _mediaUrl = null),
                  hasSubtitles: _hasSubtitles,
                  hasTranscript: _hasTranscript,
                  hasAudioDescription: _hasAudioDescription,
                  onSubtitlesChanged: (v) => setState(() => _hasSubtitles = v),
                  onTranscriptChanged: (v) => setState(() => _hasTranscript = v),
                  onAudioDescChanged: (v) => setState(() => _hasAudioDescription = v),
                )
              else if (_selectedType == ContentType.article)
                _ArticleForm(controller: _contentTextController),
              
              const SizedBox(height: 16),
              
              _SettingsPanel(
                isPublished: _isPublished,
                isFeatured: _isFeatured,
                isPinned: _isPinned,
                isAudioOnly: _isAudioOnly,
                showAudioOnly: _selectedType.isEmbedded || _selectedType.isAudio,
                onPublishedChanged: (v) => setState(() => _isPublished = v),
                onFeaturedChanged: (v) => setState(() => _isFeatured = v),
                onPinnedChanged: (v) => setState(() => _isPinned = v),
                onAudioOnlyChanged: (v) => setState(() => _isAudioOnly = v),
              ),
              
              const SizedBox(height: 24),
              if (_isSaving)
                const LinearProgressIndicator()
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveContent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// BAGIAN 2: WIDGETS UI (AGAR KODE LEBIH RAPI & RESPONSIF)
// ==============================================================================

class _TypeSelector extends StatelessWidget {
  final ContentType selectedType;
  final ValueChanged<ContentType> onChanged;

  const _TypeSelector({required this.selectedType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Tipe Konten', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.star, color: Colors.blue, size: 16),
                  SizedBox(width: 8),
                  Expanded(child: Text('Rekomendasi: Gunakan Embedded Content', style: TextStyle(fontSize: 12))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ContentType.values.map((type) => _buildTypeItem(type)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeItem(ContentType type) {
    final isSelected = selectedType == type;
    return InkWell(
      onTap: () => onChanged(type),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? type.color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? type.color : Colors.grey[300]!, width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(type.icon, color: type.color, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(type.displayName, style: TextStyle(fontWeight: FontWeight.w500, color: isSelected ? type.color : Colors.black87))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BasicInfoForm extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController excerptController;
  final TextEditingController durationController;
  final ContentCategory selectedCategory;
  final ValueChanged<ContentCategory> onCategoryChanged;

  const _BasicInfoForm({
    required this.titleController,
    required this.excerptController,
    required this.durationController,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Informasi Dasar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: titleController, 
              decoration: const InputDecoration(labelText: 'Judul', border: OutlineInputBorder()),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Judul wajib diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: excerptController, 
              decoration: const InputDecoration(labelText: 'Deskripsi Singkat', border: OutlineInputBorder()), 
              maxLines: 2
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: durationController, 
              decoration: const InputDecoration(labelText: 'Durasi (MM:SS)', border: OutlineInputBorder())
            ),
            const SizedBox(height: 16),
            const Text('Kategori', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ContentCategory.values.map((cat) {
                return FilterChip(
                  label: Text(cat.displayName),
                  selected: selectedCategory == cat,
                  onSelected: (s) => onCategoryChanged(cat),
                  selectedColor: cat.color.withOpacity(0.2),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmbeddedForm extends StatelessWidget {
  final TextEditingController urlController;
  final bool isAnalyzing;
  final bool isValidUrl;
  final String analysisResult;
  final YoutubePlayerController? youtubeController;
  final String? thumbnailUrl;
  final VoidCallback onAnalyze;
  final VoidCallback onClear;

  const _EmbeddedForm({
    required this.urlController,
    required this.isAnalyzing,
    required this.isValidUrl,
    required this.analysisResult,
    this.youtubeController,
    this.thumbnailUrl,
    required this.onAnalyze,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: 'Link Video/Audio',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'URL wajib diisi untuk embedded content';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            if (urlController.text.isNotEmpty && !isValidUrl)
              ElevatedButton.icon(
                onPressed: isAnalyzing ? null : onAnalyze, 
                icon: const Icon(Icons.search), 
                label: Text(isAnalyzing ? 'Menganalisis...' : 'Analisis URL')
              ),
            if (isAnalyzing) const LinearProgressIndicator(),
            if (analysisResult.isNotEmpty) 
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  analysisResult,
                  style: TextStyle(
                    color: isValidUrl ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (isValidUrl && youtubeController != null) 
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: YoutubePlayer(controller: youtubeController!),
              ),
          ],
        ),
      ),
    );
  }
}

class _UploadForm extends StatelessWidget {
  final ContentType selectedType;
  final String? mediaUrl;
  final bool isUploading;
  final String? uploadError;
  final VoidCallback onPickAndUpload;
  final VoidCallback onClear;
  final bool hasSubtitles;
  final bool hasTranscript;
  final bool hasAudioDescription;
  final ValueChanged<bool> onSubtitlesChanged;
  final ValueChanged<bool> onTranscriptChanged;
  final ValueChanged<bool> onAudioDescChanged;

  const _UploadForm({
    required this.selectedType,
    this.mediaUrl,
    required this.isUploading,
    this.uploadError,
    required this.onPickAndUpload,
    required this.onClear,
    required this.hasSubtitles,
    required this.hasTranscript,
    required this.hasAudioDescription,
    required this.onSubtitlesChanged,
    required this.onTranscriptChanged,
    required this.onAudioDescChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upload Media', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            if (mediaUrl == null)
              ElevatedButton.icon(
                icon: const Icon(Icons.upload), 
                label: Text('Upload ${selectedType.displayName}'), 
                onPressed: isUploading ? null : onPickAndUpload,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            
            if (isUploading) 
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
            
            if (uploadError != null) 
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  uploadError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            
            if (mediaUrl != null) 
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('File Berhasil Diunggah'),
                  subtitle: Text(mediaUrl ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClear,
                    tooltip: 'Hapus file',
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            const Divider(),
            
            const Text('Fitur Aksesibilitas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Subtitel'),
              subtitle: const Text('Tersedia teks terjemahan'),
              value: hasSubtitles, 
              onChanged: onSubtitlesChanged,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Transkrip'),
              subtitle: const Text('Tersedia transkrip teks lengkap'),
              value: hasTranscript, 
              onChanged: onTranscriptChanged,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Deskripsi Audio'),
              subtitle: const Text('Deskripsi audio untuk tunanetra'),
              value: hasAudioDescription, 
              onChanged: onAudioDescChanged,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleForm extends StatelessWidget {
  final TextEditingController controller;
  const _ArticleForm({required this.controller});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Isi Artikel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller, 
              maxLines: 10, 
              decoration: const InputDecoration(
                labelText: 'Tulis artikel di sini...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Isi artikel wajib diisi';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  final bool isPublished;
  final bool isFeatured;
  final bool isPinned;
  final bool isAudioOnly;
  final bool showAudioOnly;
  final ValueChanged<bool> onPublishedChanged;
  final ValueChanged<bool> onFeaturedChanged;
  final ValueChanged<bool> onPinnedChanged;
  final ValueChanged<bool> onAudioOnlyChanged;

  const _SettingsPanel({
    required this.isPublished, required this.isFeatured, required this.isPinned, 
    required this.isAudioOnly, required this.showAudioOnly, 
    required this.onPublishedChanged, required this.onFeaturedChanged, 
    required this.onPinnedChanged, required this.onAudioOnlyChanged
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pengaturan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Publikasikan'),
              subtitle: const Text('Tampilkan konten ke publik'),
              value: isPublished, 
              onChanged: onPublishedChanged,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Featured'),
              subtitle: const Text('Tampilkan di halaman utama'),
              value: isFeatured, 
              onChanged: onFeaturedChanged,
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: const Text('Pin'),
              subtitle: const Text('Sematkan di atas daftar'),
              value: isPinned, 
              onChanged: onPinnedChanged,
              contentPadding: EdgeInsets.zero,
            ),
            if (showAudioOnly) 
              SwitchListTile(
                title: const Text('Audio Only'),
                subtitle: const Text('Hanya audio tanpa video'),
                value: isAudioOnly, 
                onChanged: onAudioOnlyChanged,
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
    );
  }
}