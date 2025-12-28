import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lansia_care_mobile/src/features/content/view_models/content_view_model.dart';
import 'package:lansia_care_mobile/src/features/content/presentation/embedded_player.dart';
import 'package:lansia_care_mobile/src/features/content/presentation/multimedia_card.dart';

class ContentScreen extends StatefulWidget {
  final String? category;
  
  const ContentScreen({
    super.key,
    this.category,
  });

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    
    // Load initial content
    Future.microtask(() {
      final viewModel = context.read<ContentViewModel>();
      if (widget.category != null) {
        viewModel.setCategoryFilter(widget.category!);
      }
      viewModel.fetchContent();
    });
    
    // Setup scroll listener for infinite scroll
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == 
        _scrollController.position.maxScrollExtent) {
      _loadMoreContent();
    }
  }

  Future<void> _loadMoreContent() async {
    if (_isLoadingMore) return;
    
    final viewModel = context.read<ContentViewModel>();
    if (viewModel.hasNextPage && !viewModel.isLoading) {
      setState(() {
        _isLoadingMore = true;
      });
      
      await viewModel.fetchContent(refresh: false);
      
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _openContentDetail(Map<String, dynamic> content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmbeddedPlayer(
          content: content,
          onBack: () => Navigator.pop(context),
          onCompleted: () {
            // Track content completion
            context.read<ContentViewModel>().trackContentCompletion(
              content['id'],
              completionPercentage: 100,
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = [
      {'id': 'semua', 'name': 'Semua', 'icon': Icons.all_inclusive},
      {'id': 'senam_lansia', 'name': 'Senam', 'icon': Icons.fitness_center},
      {'id': 'kesehatan_praktis', 'name': 'Kesehatan', 'icon': Icons.healing},
      {'id': 'obat_dan_pengobatan', 'name': 'Obat', 'icon': Icons.medication},
      {'id': 'bansos_info', 'name': 'Bansos', 'icon': Icons.attach_money},
      {'id': 'komunitas_cerita', 'name': 'Cerita', 'icon': Icons.people},
      {'id': 'keluarga_tips', 'name': 'Keluarga', 'icon': Icons.family_restroom},
    ];

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = widget.category == category['id'] || 
                            (widget.category == null && category['id'] == 'semua');

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category['name']!),
              selected: isSelected,
              onSelected: (selected) {
                final viewModel = context.read<ContentViewModel>();
                if (category['id'] == 'semua') {
                  viewModel.setCategoryFilter(null);
                } else {
                  viewModel.setCategoryFilter(category['id']!);
                }
                viewModel.fetchContent(refresh: true);
              },
              avatar: Icon(category['icon'] as IconData, size: 18),
              backgroundColor: Colors.grey[200],
              selectedColor: Colors.blue.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              checkmarkColor: Colors.blue,
              shape: StadiumBorder(
                side: BorderSide(
                  color: isSelected ? Colors.blue : Colors.grey[300]!,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Konten Lansia',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Consumer<ContentViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.contentList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Memuat konten...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (viewModel.error != null && viewModel.contentList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat konten',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    viewModel.error!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      viewModel.fetchContent(refresh: true);
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (viewModel.contentList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.video_library_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada konten',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Konten untuk kategori ini akan segera tersedia',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Category Filter Chips
              _buildCategoryChips(),
              
              const SizedBox(height: 8),
              
              // Content Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${viewModel.contentList.length} konten',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (widget.category != null)
                      Text(
                        'Kategori: ${widget.category!.replaceAll('_', ' ').toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Content List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await viewModel.fetchContent(refresh: true);
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: viewModel.contentList.length + 
                        (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == viewModel.contentList.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      final content = viewModel.contentList[index];
                      
                      return MultimediaCard(
                        content: content.toMobileFormat(),
                        onTap: () => _openContentDetail(
                          content.toMobileFormat(),
                        ),
                        autoPlay: false,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      
      // Floating Action Button for Elderly
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Show content type filter
          showModalBottomSheet(
            context: context,
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
                      'Filter Tipe Konten',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Video Filter
                    ListTile(
                      leading: const Icon(Icons.videocam, color: Colors.red),
                      title: const Text('Video Saja'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        final viewModel = context.read<ContentViewModel>();
                        viewModel.setTypeFilter('video');
                        viewModel.fetchContent(refresh: true);
                        Navigator.pop(context);
                      },
                    ),
                    
                    // Audio Filter
                    ListTile(
                      leading: const Icon(Icons.audiotrack, color: Colors.purple),
                      title: const Text('Audio Saja'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        final viewModel = context.read<ContentViewModel>();
                        viewModel.setTypeFilter('audio');
                        viewModel.fetchContent(refresh: true);
                        Navigator.pop(context);
                      },
                    ),
                    
                    // Article Filter
                    ListTile(
                      leading: const Icon(Icons.article, color: Colors.blue),
                      title: const Text('Artikel Saja'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        final viewModel = context.read<ContentViewModel>();
                        viewModel.setTypeFilter('article');
                        viewModel.fetchContent(refresh: true);
                        Navigator.pop(context);
                      },
                    ),
                    
                    // Clear Filter
                    ListTile(
                      leading: const Icon(Icons.clear_all, color: Colors.grey),
                      title: const Text('Semua Tipe'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        final viewModel = context.read<ContentViewModel>();
                        viewModel.setTypeFilter(null);
                        viewModel.fetchContent(refresh: true);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        icon: const Icon(Icons.filter_alt),
        label: const Text('Filter'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
        extendedIconLabelSpacing: 12,
      ),
    );
  }
}