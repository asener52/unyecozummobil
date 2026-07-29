import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/api_service.dart';

class UserGroupsScreen extends StatefulWidget {
  const UserGroupsScreen({super.key});

  @override
  State<UserGroupsScreen> createState() => _UserGroupsScreenState();
}

class _UserGroupsScreenState extends State<UserGroupsScreen> {
  final _api = ApiService();

  List<Map<String, dynamic>> _groups = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await _api.get('/user-groups');
      setState(() {
        _groups = List<Map<String, dynamic>>.from(resp.data as List);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = ApiService.parseError(e); _loading = false; });
    }
  }

  Future<void> _showGroupDialog({Map<String, dynamic>? existing}) async {
    final nameCtrl = TextEditingController(text: existing?['name'] as String? ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] as String? ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Yeni Grup' : 'Grubu Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Grup Adı *'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Açıklama'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (result != true || !mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;
    try {
      if (existing == null) {
        await _api.post('/user-groups', data: {'name': name, 'description': descCtrl.text.trim()});
      } else {
        await _api.put('/user-groups/${existing['id']}',
            data: {'name': name, 'description': descCtrl.text.trim()});
      }
      _fetch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.parseError(e)), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  Future<void> _deleteGroup(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Grubu Sil'),
        content: const Text('Bu grubu silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.delete('/user-groups/$id');
      _fetch();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.parseError(e)), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanıcı Grupları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetch,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGroupDialog(),
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
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
              : _groups.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group_outlined, size: 56, color: AppTheme.textHint),
                          SizedBox(height: 12),
                          Text('Henüz kullanıcı grubu yok',
                              style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _groups.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final g = _groups[i];
                          final memberCount = g['member_count'] as int? ?? 0;
                          final members = g['members'] as List? ?? [];

                          return Card(
                            child: ExpansionTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.group_outlined,
                                    color: AppTheme.primaryGreen, size: 20),
                              ),
                              title: Text(g['name'] as String? ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text('$memberCount üye',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              trailing: PopupMenuButton<String>(
                                onSelected: (action) {
                                  if (action == 'edit') _showGroupDialog(existing: g);
                                  if (action == 'delete') _deleteGroup(g['id'] as String);
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: 'edit',
                                      child: ListTile(dense: true,
                                          leading: Icon(Icons.edit_outlined, size: 18),
                                          title: Text('Düzenle', style: TextStyle(fontSize: 13)))),
                                  const PopupMenuItem(value: 'delete',
                                      child: ListTile(dense: true,
                                          leading: Icon(Icons.delete_outline, size: 18, color: AppTheme.errorColor),
                                          title: Text('Sil', style: TextStyle(fontSize: 13, color: AppTheme.errorColor)))),
                                ],
                              ),
                              children: [
                                if (g['description'] != null && (g['description'] as String).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    child: Text(g['description'] as String,
                                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                                  ),
                                if (members.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Text('Bu grupta henüz üye yok.',
                                        style: TextStyle(fontSize: 13, color: AppTheme.textHint)),
                                  )
                                else
                                  ...members.map((m) {
                                    final member = m as Map<String, dynamic>;
                                    return ListTile(
                                      dense: true,
                                      leading: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                                        child: Text(
                                          (member['name'] as String? ?? '?')[0].toUpperCase(),
                                          style: const TextStyle(fontSize: 12, color: AppTheme.primaryGreen),
                                        ),
                                      ),
                                      title: Text(member['name'] as String? ?? '',
                                          style: const TextStyle(fontSize: 13)),
                                      subtitle: Text(
                                        [
                                          if (member['unit_name'] != null) member['unit_name'] as String,
                                          if (member['role_name'] != null) member['role_name'] as String,
                                        ].join(' · '),
                                        style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
                                      ),
                                    );
                                  }),
                                const SizedBox(height: 8),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
