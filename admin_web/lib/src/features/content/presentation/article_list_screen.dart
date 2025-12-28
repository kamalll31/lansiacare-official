import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_web/src/features/content/view_models/content_view_model.dart';
import 'package:admin_web/src/shared/models/content.dart';
import 'package:admin_web/src/shared/widgets/app_drawer.dart';

class ArticleListScreen extends StatefulWidget {
  const ArticleListScreen({super.key});

  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ContentViewModel>().fetchContent();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<ContentViewModel>().setSearchQuery(query);
        context.read<ContentViewModel>().fetchContent();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ContentViewModel>();
    
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: const AppDrawer(), // ✅ SELALU ADA DRAWER
      appBar: AppBar( // ✅ GUNAKAN APPBAR STANDARD
        title: const Text('Manajemen Konten'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => viewModel.fetchContent(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/content/new'),
        icon: const Icon(Icons.add),
        label: const Text('Buat Baru'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // SEARCH BAR
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari konten...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),

            // CONTENT AREA
            Expanded(
              child: _buildContent(viewModel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ContentViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.blue,
          strokeWidth: 2,
        ),
      );
    }

    if (viewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                viewModel.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => viewModel.fetchContent(),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
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
            Icon(Icons.article, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Belum ada konten',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Klik tombol + di bawah untuk membuat konten pertama',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await viewModel.fetchContent();
      },
      color: Colors.blue,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80), // Extra bottom padding untuk FAB
        itemCount: viewModel.contentList.length,
        itemBuilder: (context, index) {
          final content = viewModel.contentList[index];
          return _buildContentCard(content);
        },
      ),
    );
  }

  Widget _buildContentCard(ContentItem content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      child: InkWell(
        onTap: () => context.go('/content/${content.id}/edit'),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ICON TYPE
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: content.contentType.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  content.contentType.icon,
                  color: content.contentType.color,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // CONTENT INFO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      content.excerpt.isNotEmpty 
                          ? content.excerpt 
                          : 'Tidak ada deskripsi',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        // STATUS BADGE
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: content.isPublished 
                                ? Colors.green.withOpacity(0.1) 
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: content.isPublished 
                                  ? Colors.green.withOpacity(0.3) 
                                  : Colors.orange.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            content.isPublished ? 'TERBIT' : 'DRAFT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: content.isPublished 
                                  ? Colors.green 
                                  : Colors.orange,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // CATEGORY
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            content.category.displayName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // UPDATED TIME (jika ada)
                        if (content.updatedAt != null)
                          Text(
                            _formatDate(content.updatedAt!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // ACTION MENU
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 18, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Preview'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    context.go('/content/${content.id}/edit');
                  } else if (value == 'view') {
                    // TODO: Implement preview
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preview belum tersedia'),
                      ),
                    );
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(context, content);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m lalu';
      }
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showDeleteConfirmation(BuildContext context, ContentItem content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus "${content.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteContent(content);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _deleteContent(ContentItem content) {
    // TODO: Implement delete logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Menghapus "${content.title}"...'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}