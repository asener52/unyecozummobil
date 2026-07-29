import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/topics_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/topic.dart';

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({super.key});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TopicsProvider>().fetchTopics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TopicsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konular & Kategoriler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => prov.fetchTopics(),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showTopicDialog(context, prov),
          ),
        ],
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : prov.error != null
              ? _ErrorView(
                  message: prov.error!,
                  onRetry: () => prov.fetchTopics(),
                )
              : RefreshIndicator(
                  onRefresh: () => prov.fetchTopics(),
                  child: prov.topics.isEmpty
                      ? const _EmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: prov.topics.length,
                          itemBuilder: (ctx, i) => _TopicCard(
                            topic: prov.topics[i],
                            onEdit: () => _showTopicDialog(context, prov,
                                topic: prov.topics[i]),
                            onDelete: () => _confirmDelete(
                                context, prov, prov.topics[i]),
                          ),
                        ),
                ),
    );
  }

  void _showTopicDialog(BuildContext context, TopicsProvider prov,
      {Topic? topic}) {
    final nameCtrl = TextEditingController(text: topic?.name ?? '');
    final descCtrl = TextEditingController(text: topic?.description ?? '');
    final daysCtrl = TextEditingController(
        text: topic?.deadlineDays?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(topic == null ? 'Yeni Konu' : 'Konuyu Düzenle'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Konu Adı'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ad zorunludur' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Açıklama'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: daysCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'SLA Süre (gün)',
                  hintText: 'Örn: 3',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final days = int.tryParse(daysCtrl.text.trim());
              bool ok;
              if (topic == null) {
                ok = await prov.createTopic({
                  'name': nameCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  if (days != null) 'deadline_days': days,
                });
              } else {
                ok = await prov.updateTopic(topic.id, {
                  'name': nameCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  if (days != null) 'deadline_days': days,
                });
              }
              if (context.mounted) {
                Navigator.pop(ctx);
                if (!ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(prov.error ?? 'Hata oluştu')),
                  );
                }
              }
            },
            child: Text(topic == null ? 'Oluştur' : 'Güncelle'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, TopicsProvider prov, Topic topic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konuyu Sil'),
        content:
            Text('"${topic.name}" konusunu silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await prov.deleteTopic(topic.id);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(prov.error ?? 'Silinemedi')),
                );
              }
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final Topic topic;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TopicCard(
      {required this.topic, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.accentGold.withValues(alpha: 0.15),
          child: const Icon(Icons.label_rounded,
              color: AppTheme.accentGold, size: 20),
        ),
        title: Text(topic.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (topic.description != null && topic.description!.isNotEmpty)
              Text(topic.description!,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            Row(
              children: [
                if (topic.deadlineDays != null)
                  _tag('${topic.deadlineDays} gün SLA', AppTheme.warningColor),
                if (topic.requestCount != null) ...[
                  const SizedBox(width: 6),
                  _tag('${topic.requestCount} talep', AppTheme.infoColor),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: onEdit,
              color: AppTheme.primaryGreen,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: onDelete,
              color: AppTheme.errorColor,
            ),
          ],
        ),
        isThreeLine: (topic.description != null &&
                topic.description!.isNotEmpty) ||
            topic.deadlineDays != null,
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w500)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.label_outline, size: 56, color: AppTheme.textHint),
          SizedBox(height: 12),
          Text('Konu bulunamadı',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppTheme.errorColor),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: onRetry, child: const Text('Tekrar Dene')),
          ],
        ),
      ),
    );
  }
}
