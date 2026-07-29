import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/external_messages_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_date_utils.dart';
import '../../../data/models/external_message.dart';

class ExternalMessagesScreen extends StatefulWidget {
  const ExternalMessagesScreen({super.key});

  @override
  State<ExternalMessagesScreen> createState() =>
      _ExternalMessagesScreenState();
}

class _ExternalMessagesScreenState extends State<ExternalMessagesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        final source = _tabCtrl.index == 0
            ? null
            : _tabCtrl.index == 1
                ? 'whatsapp'
                : 'email';
        context.read<ExternalMessagesProvider>().fetchMessages(source: source);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExternalMessagesProvider>().fetchMessages();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExternalMessagesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dış Mesajlar'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Tümü'),
            Tab(text: 'WhatsApp'),
            Tab(text: 'E-posta'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => prov.fetchMessages(source: prov.sourceFilter),
          ),
        ],
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : prov.error != null
              ? _ErrorView(
                  message: prov.error!,
                  onRetry: () => prov.fetchMessages(),
                )
              : RefreshIndicator(
                  onRefresh: () => prov.fetchMessages(source: prov.sourceFilter),
                  child: prov.messages.isEmpty
                      ? const _EmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: prov.messages.length,
                          itemBuilder: (ctx, i) => _MessageCard(
                            message: prov.messages[i],
                            onConvert: () => _showConvertDialog(
                                context, prov.messages[i]),
                            onRead: () =>
                                prov.markAsRead(prov.messages[i].id),
                          ),
                        ),
                ),
    );
  }

  void _showConvertDialog(BuildContext context, ExternalMessage msg) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mesajı Talebe Dönüştür',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              msg.content,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/panel/talep-olustur');
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni Talep Oluştur'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final ExternalMessage message;
  final VoidCallback onConvert;
  final VoidCallback onRead;

  const _MessageCard({
    required this.message,
    required this.onConvert,
    required this.onRead,
  });

  Color get _sourceColor {
    switch (message.source) {
      case 'whatsapp':
        return const Color(0xFF25D366);
      case 'email':
        return AppTheme.infoColor;
      default:
        return AppTheme.textHint;
    }
  }

  IconData get _sourceIcon {
    switch (message.source) {
      case 'whatsapp':
        return Icons.chat_rounded;
      case 'email':
        return Icons.email_rounded;
      default:
        return Icons.message_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = message.status == 'new';

    return Card(
      child: InkWell(
        onTap: onRead,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _sourceColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_sourceIcon,
                        color: _sourceColor, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message.sourceLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: _sourceColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isNew) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.errorColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    AppDateUtils.timeAgo(message.createdAt),
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textHint),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (message.senderName != null)
                Text(
                  message.senderName!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              if (message.senderContact != null)
                Text(
                  message.senderContact!,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textHint),
                ),
              const SizedBox(height: 6),
              Text(
                message.content,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textPrimary),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (message.isConverted)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Talep: ${message.linkedTrackingNumber ?? 'Oluşturuldu'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: onConvert,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Talebe Dönüştür',
                      style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                  ),
                ),
            ],
          ),
        ),
      ),
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
          Icon(Icons.inbox_outlined, size: 56, color: AppTheme.textHint),
          SizedBox(height: 12),
          Text('Dış mesaj bulunamadı',
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
