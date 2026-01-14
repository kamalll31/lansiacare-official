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
  bool _isSaving = false;

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
    _youtubeController?.dispose(); // Hapus controller lama agar hemat memori
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
      final result = await viewModel.analyzeUrl(url);
      
      if (!mounted) return;

      if (result['success'] == true) {
        // [FIX] Mengambil data dari Map sesuai standar Backend
        final data = result['data']; 
        setState(() {
          _isValidUrl = true;
          _analysisResult = '✅ URL valid - ${data['provider']?.toString().toUpperCase()}';
          _embedProvider = data['provider'];
          _embedId = data['id'];
          _embedType = data['type'];
          _thumbnailUrl = data['thumbnail'];
          
          if (_titleController.text.isEmpty) _titleController.text = data['title'] ?? '';
          
          if (_embedProvider == 'youtube' && _embedId != null) {
            _initYoutubeController(_embedId!);
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
        _analysisResult = '❌ Terjadi kesalahan analisis';
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
      setState(() => _uploadError = 'Gagal memilih file');
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
      final result = await viewModel.uploadMedia(file, type);
      
      if (mounted && result['success'] == true) {
        setState(() {
          _mediaUrl = result['url'];
          if (result['duration'] != null) {
            _durationController.text = _formatDuration(result['duration']);
          }
        });
      } else {
        setState(() => _uploadError = result['error'] ?? 'Gagal unggah');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  int? _parseDuration() {
    final text = _durationController.text.trim();
    if (text.isEmpty) return null;
    try {
      if (text.contains(':')) {
        final parts = text.split(':');
        return int.parse(parts[0]) * 60 + int.parse(parts[1]);
      }
      return int.parse(text);
    } catch (_) { return null; }
  }
  
  Future<void> _saveContent() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final content = ContentItem(
        id: widget.contentId ?? 0,
        title: _titleController.text,
        excerpt: _excerptController.text,
        contentType: _selectedType,
        category: _selectedCategory,
        embedUrl: _selectedType.isEmbedded ? _urlController.text : null,
        embedProvider: _embedProvider,
        embedId: _embedId,
        mediaUrl: _mediaUrl,
        thumbnailUrl: _thumbnailUrl,
        contentText: _contentTextController.text,
        duration: _parseDuration(),
        isPublished: _isPublished,
        isFeatured: _isFeatured,
        isPinned: _isPinned,
        isAudioOnly: _isAudioOnly,
        hasSubtitles: _hasSubtitles,
        hasTranscript: _hasTranscript,
        hasAudioDescription: _hasAudioDescription,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final viewModel = context.read<ContentViewModel>();
      final bool success = widget.contentId != null 
          ? await viewModel.updateContent(content)
          : await viewModel.createContent(content);
      
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Konten berhasil disimpan'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _TypeSelector(selectedType: _selectedType, onChanged: (t) => setState(() => _selectedType = t)),
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
                  onAnalyze: _analyzeUrl,
                  onClear: () => _urlController.clear(),
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
              if (_isSaving) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
// BAGIAN 2: WIDGETS UI (MODULAR)
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
            const Text('Tipe Konten', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ContentType.values.map((type) {
                final isSelected = selectedType == type;
                return ChoiceChip(
                  label: Text(type.displayName),
                  selected: isSelected,
                  onSelected: (_) => onChanged(type),
                  avatar: Icon(type.icon, size: 16, color: isSelected ? Colors.white : type.color),
                );
              }).toList(),
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
          children: [
            TextFormField(controller: titleController, decoration: const InputDecoration(labelText: 'Judul')),
            TextFormField(controller: excerptController, decoration: const InputDecoration(labelText: 'Ringkasan')),
            const SizedBox(height: 16),
            DropdownButtonFormField<ContentCategory>(
              value: selectedCategory,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: ContentCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.displayName))).toList(),
              onChanged: (v) => onCategoryChanged(v!),
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
  final VoidCallback onAnalyze;
  final VoidCallback onClear;

  const _EmbeddedForm({
    required this.urlController,
    required this.isAnalyzing,
    required this.isValidUrl,
    required this.analysisResult,
    this.youtubeController,
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
                labelText: 'Link Video (YouTube)',
                suffixIcon: IconButton(icon: const Icon(Icons.search), onPressed: onAnalyze),
              ),
            ),
            if (isAnalyzing) const LinearProgressIndicator(),
            Text(analysisResult, style: TextStyle(color: isValidUrl ? Colors.green : Colors.red)),
            if (isValidUrl && youtubeController != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
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
          children: [
            if (mediaUrl == null)
              ElevatedButton.icon(icon: const Icon(Icons.upload), label: const Text('Unggah File'), onPressed: onPickAndUpload)
            else
              ListTile(title: const Text('File Unggahan'), subtitle: Text(mediaUrl!), trailing: IconButton(icon: const Icon(Icons.delete), onPressed: onClear)),
            if (isUploading) const LinearProgressIndicator(),
            const Divider(),
            SwitchListTile(title: const Text('Subtitle'), value: hasSubtitles, onChanged: onSubtitlesChanged),
            SwitchListTile(title: const Text('Transkrip'), value: hasTranscript, onChanged: onTranscriptChanged),
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
        child: TextFormField(controller: controller, maxLines: 10, decoration: const InputDecoration(labelText: 'Konten Artikel')),
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
      child: Column(
        children: [
          SwitchListTile(title: const Text('Publikasikan'), value: isPublished, onChanged: onPublishedChanged),
          SwitchListTile(title: const Text('Konten Utama'), value: isFeatured, onChanged: onFeaturedChanged),
        ],
      ),
    );
  }
}