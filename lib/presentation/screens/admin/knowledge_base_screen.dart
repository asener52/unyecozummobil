import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/api_service.dart';

class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  State<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _articles = [];
  bool _loading = false;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final params = <String, dynamic>{};
      if (_search.isNotEmpty) params['search'] = _search;
      final resp = await _api.get('/knowledge-base', params: params);
      final data = resp.data;
      setState(() {
        _articles = List<Map<String, dynamic>>.from(data as List);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = ApiService.parseError(e); _loading = false; });
    }
  }

  Future<void> _openArticle(Map<String, dynamic> article) async {
    // Görüntüleme sayısını artır
    try { await _api.get('/knowledge-base/${article['id']}'); } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _ArticleDetailScreen(article: article),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bilgi Bankası')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Makalelerde ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                          _fetch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onChanged: (v) => setState(() => _search = v),
              onSubmitted: (_) => _fetch(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                            const SizedBox(height: 12),
                            Text(_error!, textAlign: TextAlign.center,
                                style: const TextStyle(color: AppTheme.textSecondary)),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _fetch, child: const Text('Tekrar Dene')),
                          ],
                        ),
                      )
                    : _articles.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.library_books_outlined,
                                    size: 56, color: AppTheme.textHint),
                                const SizedBox(height: 12),
                                Text(
                                  _search.isEmpty ? 'Henüz makale yok' : '"$_search" için sonuç bulunamadı',
                                  style: const TextStyle(color: AppTheme.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _articles.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, i) {
                                final a = _articles[i];
                                return Card(
                                  child: ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.article_outlined,
                                          color: AppTheme.primaryGreen, size: 20),
                                    ),
                                    title: Text(
                                      a['title'] as String? ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (a['category'] != null)
                                          Text(a['category'] as String,
                                              style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen)),
                                        Row(
                                          children: [
                                            const Icon(Icons.visibility_outlined, size: 12, color: AppTheme.textHint),
                                            const SizedBox(width: 4),
                                            Text('${a['views_count'] ?? 0} görüntülenme',
                                                style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textHint),
                                    isThreeLine: true,
                                    onTap: () => _openArticle(a),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _ArticleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> article;
  const _ArticleDetailScreen({required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(article['title'] as String? ?? 'Makale'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article['category'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  article['category'] as String,
                  style: const TextStyle(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              article['title'] as String? ?? '',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              article['content'] as String? ?? '',
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.7),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.visibility_outlined, size: 14, color: AppTheme.textHint),
                const SizedBox(width: 4),
                Text('${article['views_count'] ?? 0} görüntülenme',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textHint)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
