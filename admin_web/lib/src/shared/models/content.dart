import 'package:flutter/material.dart';

// ==============================
// ENUMS
// ==============================
enum ContentType {
  embeddedVideo('embedded_video', 'Video Embedded', Icons.video_library, Colors.red),
  embeddedAudio('embedded_audio', 'Audio Embedded', Icons.audiotrack, Colors.green),
  uploadedVideo('uploaded_video', 'Video Upload', Icons.upload_file, Colors.orange),
  uploadedAudio('uploaded_audio', 'Audio Upload', Icons.upload_file, Colors.purple),
  article('article', 'Artikel', Icons.article, Colors.blue),
  infographic('infographic', 'Infografis', Icons.image, Colors.teal);

  final String value;
  final String displayName;
  final IconData icon;
  final Color color;

  const ContentType(this.value, this.displayName, this.icon, this.color);

  static ContentType fromString(String value) {
    return ContentType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ContentType.article,
    );
  }

  bool get isEmbedded => value.startsWith('embedded');
  bool get isUploaded => value.startsWith('uploaded');
  bool get isVideo => value.contains('video');
  bool get isAudio => value.contains('audio');
}

enum ContentCategory {
  kesehatanPraktis('kesehatan_praktis', 'Tips Kesehatan', Icons.healing, Colors.green),
  senamLansia('senam_lansia', 'Senam Lansia', Icons.fitness_center, Colors.orange),
  obatDanPengobatan('obat_dan_pengobatan', 'Obat & Terapi', Icons.medication, Colors.red),
  bansosInfo('bansos_info', 'Info Bansos', Icons.attach_money, Colors.blue),
  komunitasCerita('komunitas_cerita', 'Komunitas', Icons.people, Colors.purple),
  keluargaTips('keluarga_tips', 'Tips Keluarga', Icons.family_restroom, Colors.teal),
  beritaRingan('berita_ringan', 'Berita', Icons.newspaper, Colors.brown),
  tutorialAplikasi('tutorial_aplikasi', 'Tutorial HP', Icons.phone_android, Colors.indigo),
  umum('umum', 'Umum', Icons.category, Colors.grey);

  final String value;
  final String displayName;
  final IconData icon;
  final Color color;

  const ContentCategory(this.value, this.displayName, this.icon, this.color);

  static ContentCategory fromString(String value) {
    return ContentCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ContentCategory.umum,
    );
  }
}

// ==============================
// MAIN CONTENT MODEL
// ==============================
class ContentItem {
  final int id;
  final String title;
  final String excerpt; 
  final ContentType contentType;
  
  // Embedded fields
  final String? embedUrl;
  final String? embedProvider;
  final String? embedId;
  final String? embedType;
  final String? embedCode;
  
  // Uploaded fields
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? contentText; 
  
  // Common fields
  final int? duration;
  final ContentCategory category;
  final int authorId;
  final String authorName;
  final bool isPublished;
  final bool isFeatured;
  final bool isPinned;
  
  // Accessibility
  final bool isAudioOnly;
  final bool hasSubtitles;
  final bool hasTranscript;
  final bool hasAudioDescription;
  final int accessibilityScore;
  
  // Engagement
  final int viewCount;
  final int likeCount;
  final int shareCount;
  final double completionRate;
  
  // Timestamps
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ContentItem({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.contentType,
    this.embedUrl,
    this.embedProvider,
    this.embedId,
    this.embedType,
    this.embedCode,
    this.mediaUrl,
    this.thumbnailUrl,
    this.contentText,
    this.duration,
    required this.category,
    required this.authorId,
    required this.authorName,
    required this.isPublished,
    required this.isFeatured,
    required this.isPinned,
    required this.isAudioOnly,
    required this.hasSubtitles,
    required this.hasTranscript,
    required this.hasAudioDescription,
    required this.accessibilityScore,
    required this.viewCount,
    required this.likeCount,
    required this.shareCount,
    required this.completionRate,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      excerpt: json['excerpt'] ?? json['body'] ?? '',
      contentType: ContentType.fromString(json['content_type'] ?? ''),
      embedUrl: json['embed_url'],
      embedProvider: json['embed_provider'],
      embedId: json['embed_id'],
      embedType: json['embed_type'],
      embedCode: json['embed_code'],
      mediaUrl: json['media_url'] ?? json['video_url'],
      thumbnailUrl: json['thumbnail_url'],
      contentText: json['content_text'] ?? json['body'],
      duration: json['duration'],
      category: ContentCategory.fromString(json['category'] ?? ''),
      authorId: json['author_id'] ?? 0,
      authorName: json['author_name'] ?? 'Admin',
      isPublished: json['is_published'] ?? false,
      isFeatured: json['is_featured'] ?? false,
      isPinned: json['is_pinned'] ?? false,
      isAudioOnly: json['is_audio_only'] ?? false,
      hasSubtitles: json['has_subtitles'] ?? false,
      hasTranscript: json['has_transcript'] ?? false,
      hasAudioDescription: json['has_audio_description'] ?? false,
      accessibilityScore: json['accessibility_score'] ?? 0,
      viewCount: json['view_count'] ?? 0,
      likeCount: json['like_count'] ?? 0,
      shareCount: json['share_count'] ?? 0,
      completionRate: (json['completion_rate'] ?? 0).toDouble(),
      publishedAt: json['published_at'] != null ? DateTime.tryParse(json['published_at']) : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'excerpt': excerpt,
      'content_type': contentType.value,
      'embed_url': embedUrl,
      'embed_provider': embedProvider,
      'embed_id': embedId,
      'embed_type': embedType,
      'embed_code': embedCode,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'content_text': contentText,
      'duration': duration,
      'category': category.value,
      'is_published': isPublished,
      'is_featured': isFeatured,
      'is_pinned': isPinned,
      'is_audio_only': isAudioOnly,
      'has_subtitles': hasSubtitles,
      'has_transcript': hasTranscript,
      'has_audio_description': hasAudioDescription,
    };
  }

  // [BARU] copyWith untuk memudahkan update state di ViewModel
  ContentItem copyWith({
    String? title,
    String? excerpt,
    ContentType? contentType,
    bool? isPublished,
    bool? isFeatured,
    ContentCategory? category,
  }) {
    return ContentItem(
      id: id,
      title: title ?? this.title,
      excerpt: excerpt ?? this.excerpt,
      contentType: contentType ?? this.contentType,
      category: category ?? this.category,
      isPublished: isPublished ?? this.isPublished,
      isFeatured: isFeatured ?? this.isFeatured,
      isPinned: isPinned,
      authorId: authorId,
      authorName: authorName,
      isAudioOnly: isAudioOnly,
      hasSubtitles: hasSubtitles,
      hasTranscript: hasTranscript,
      hasAudioDescription: hasAudioDescription,
      accessibilityScore: accessibilityScore,
      viewCount: viewCount,
      likeCount: likeCount,
      shareCount: shareCount,
      completionRate: completionRate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      embedUrl: embedUrl,
      embedProvider: embedProvider,
      embedId: embedId,
      embedType: embedType,
      embedCode: embedCode,
      mediaUrl: mediaUrl,
      thumbnailUrl: thumbnailUrl,
      contentText: contentText,
      duration: duration,
      publishedAt: publishedAt,
    );
  }

  String get durationFormatted {
    if (duration == null) return '-';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get timeAgo {
    final date = publishedAt ?? createdAt;
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()} tahun lalu';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} bulan lalu';
    if (diff.inDays > 0) return '${diff.inDays} hari lalu';
    if (diff.inHours > 0) return '${diff.inHours} jam lalu';
    return '${diff.inMinutes} menit lalu';
  }
}

// ==============================
// URL ANALYSIS MODEL
// ==============================
class UrlAnalysis {
  final bool isValid;
  final String? provider;
  final String? type;
  final String? id;
  final Map<String, dynamic> metadata;
  final String embedCode;
  final bool supportsEmbed;
  final String? contentType;
  final List<String> recommendedCategories;

  UrlAnalysis({
    required this.isValid,
    this.provider,
    this.type,
    this.id,
    required this.metadata,
    required this.embedCode,
    required this.supportsEmbed,
    this.contentType,
    required this.recommendedCategories,
  });

  factory UrlAnalysis.fromJson(Map<String, dynamic> json) {
    return UrlAnalysis(
      isValid: json['is_valid'] ?? false,
      provider: json['provider'],
      type: json['type'],
      id: json['id'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      embedCode: json['embed_code'] ?? '',
      supportsEmbed: json['supports_embed'] ?? false,
      contentType: json['content_type'],
      recommendedCategories: List<String>.from(json['recommended_categories'] ?? []),
    );
  }

  String? get thumbnailUrl => metadata['thumbnail_url'];
  String? get title => metadata['title'];
  String? get description => metadata['description'];
  int? get duration => metadata['duration'];
}

// ==============================
// ANALYTICS MODELS
// ==============================
class ContentStats {
  final int total;
  final int published;
  final Map<String, int> byType;
  final Map<String, int> categories;
  final List<ContentView> mostViewed;

  ContentStats({
    required this.total,
    required this.published,
    required this.byType,
    required this.categories,
    required this.mostViewed,
  });

  factory ContentStats.fromJson(Map<String, dynamic> json) {
    return ContentStats(
      total: json['total'] ?? 0,
      published: json['published'] ?? 0,
      byType: Map<String, int>.from(json['by_type'] ?? {}),
      categories: Map<String, int>.from(json['categories'] ?? {}),
      mostViewed: (json['most_viewed'] as List?)
          ?.map((item) => ContentView.fromJson(item))
          .toList() ?? [],
    );
  }
}

class ContentView {
  final int id;
  final String title;
  final int views;
  ContentView({required this.id, required this.title, required this.views});
  factory ContentView.fromJson(Map<String, dynamic> json) {
    return ContentView(id: json['id'], title: json['title'] ?? '', views: json['views'] ?? 0);
  }
}