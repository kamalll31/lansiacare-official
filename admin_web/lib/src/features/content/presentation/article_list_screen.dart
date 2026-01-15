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
    // Load data awal
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

  // Listener untuk Search Bar (Debounce)
  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<ContentViewModel>().setSearchQuery(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer untuk mendengarkan perubahan state global (Error/Success)
    return Consumer<ContentViewModel>(
      builder: (context, viewModel, child) {
        
        // Listener Efek Samping (Snackbar)
        // Kita gunakan addPostFrameCallback agar tidak error saat build widget
        if (viewModel.errorMessage != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(viewModel.errorMessage!), backgroundColor: Colors.red),
            );
            viewModel.clearErrors(); // Reset error setelah ditampilkan
          });
        }
        
        if (viewModel.successMessage != null) {
           WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(viewModel.successMessage!), backgroundColor: Colors.green),
            );
            viewModel.clearErrors();
          });
        }

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.grey[50], // Background agak abu agar Card menonjol
          drawer: const AppDrawer(), 
          appBar: AppBar(
            title: const Text('Manajemen Konten', style: TextStyle(color: Colors.black87)),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black87),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => viewModel.fetchContent(refresh: true),
              ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
               // Arahkan ke halaman form (asumsikan rute sudah ada)
               // context.go('/content/add'); 
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Fitur Tambah Konten akan segera aktif di form screen')),
               );
            },
            icon: const Icon(Icons.add),
            label: const Text('Buat Konten'),
          ),
          body: Column(
            children: [
              // 1. HEADER & SEARCH
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Cari judul konten...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // FILTER CHIPS
                    Row(
                      children: [
                        _buildFilterChip('Semua', 'all', viewModel),
                        const SizedBox(width: 8),
                        _buildFilterChip('Artikel', 'article', viewModel),
                        const SizedBox(width: 8),
                        _buildFilterChip('Video', 'video', viewModel),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 2. CONTENT LIST
              Expanded(
                child: viewModel.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : viewModel.contentList.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: viewModel.contentList.length,
                            itemBuilder: (context, index) {
                              final item = viewModel.contentList[index];
                              return _buildContentCard(context, item, viewModel);
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value, ContentViewModel viewModel) {
    final isSelected = (viewModel.typeFilter ?? 'all') == value;
    // Handle 'all' logic secara manual jika typeFilter null
    final effectiveSelected = value == 'all' ? viewModel.typeFilter == null : viewModel.typeFilter == value;

    return ChoiceChip(
      label: Text(label),
      selected: effectiveSelected,
      onSelected: (selected) {
        if (selected) {
          viewModel.setTypeFilter(value == 'all' ? null : value);
        }
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Belum ada konten',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(BuildContext context, ContentItem item, ContentViewModel viewModel) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // THUMBNAIL
            Container(
              width: 80,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
                image: item.thumbnailUrl != null 
                    ? DecorationImage(image: NetworkImage(item.thumbnailUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: item.thumbnailUrl == null 
                  ? Icon(Icons.image, color: Colors.grey[400]) 
                  : null,
            ),
            const SizedBox(width: 12),
            
            // INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.type == 'video' ? Colors.red[50] : Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.type.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: item.type == 'video' ? Colors.red : Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.isPublished ? 'Published' : 'Draft',
                        style: TextStyle(
                          fontSize: 11,
                          color: item.isPublished ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // ACTIONS
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteDialog(context, item, viewModel);
                } else if (value == 'edit') {
                  // context.go('/content/${item.id}/edit');
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ContentItem item, ContentViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Konten?'),
        content: Text('Yakin ingin menghapus "${item.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.deleteContent(item.id!); // ID bisa null di model, jadi pakai bang operator jika yakin
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}