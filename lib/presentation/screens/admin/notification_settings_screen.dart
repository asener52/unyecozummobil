import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/services/api_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabController;
  bool _loading = true;
  String? _error;
  List<dynamic> _rules = [];
  List<dynamic> _templates = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      dynamic rulesData;
      dynamic templatesData;
      try {
        final r = await _api.get(ApiConstants.notificationRules);
        rulesData = r.data;
      } catch (_) {}
      try {
        final r = await _api.get(ApiConstants.notificationTemplates);
        templatesData = r.data;
      } catch (_) {}
      setState(() {
        _rules = rulesData is List ? rulesData : (rulesData?['rules'] ?? rulesData?['data'] ?? []);
        _templates = templatesData is List ? templatesData : (templatesData?['templates'] ?? templatesData?['data'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = ApiService.parseError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Ayarları'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Kurallar'),
            Tab(text: 'Şablonlar'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRulesList(),
                    _buildTemplatesList(),
                  ],
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Tekrar Dene')),
        ],
      ),
    );
  }

  Widget _buildRulesList() {
    if (_rules.isEmpty) {
      return const Center(child: Text('Bildirim kuralı bulunamadı'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _rules.length,
        itemBuilder: (_, i) => _buildRuleCard(_rules[i]),
      ),
    );
  }

  Widget _buildRuleCard(dynamic rule) {
    final name = rule['name'] ?? rule['title'] ?? 'Kural';
    final trigger = rule['trigger_event'] ?? rule['event'] ?? '';
    final channels = rule['channels'] ?? [];
    final isActive = rule['is_active'] ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Switch(
                  value: isActive,
                  activeThumbColor: AppTheme.primaryGreen,
                  onChanged: null,
                ),
              ],
            ),
            if (trigger.toString().isNotEmpty)
              Text('Tetikleyici: $trigger',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            if (channels is List && channels.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: (channels as Iterable).map((ch) {
                  IconData icon;
                  switch (ch.toString()) {
                    case 'sms':
                      icon = Icons.sms_rounded;
                      break;
                    case 'email':
                      icon = Icons.email_rounded;
                      break;
                    case 'whatsapp':
                      icon = Icons.chat_rounded;
                      break;
                    default:
                      icon = Icons.notifications_rounded;
                  }
                  return Chip(
                    label: Text(ch.toString()),
                    avatar: Icon(icon, size: 14),
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesList() {
    if (_templates.isEmpty) {
      return const Center(child: Text('Şablon bulunamadı'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _templates.length,
        itemBuilder: (_, i) => _buildTemplateCard(_templates[i]),
      ),
    );
  }

  Widget _buildTemplateCard(dynamic tpl) {
    final name = tpl['name'] ?? tpl['title'] ?? 'Şablon';
    final type = tpl['type'] ?? tpl['channel'] ?? '';
    final subject = tpl['subject'] ?? '';
    final body = tpl['body'] ?? tpl['content'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
          child: Icon(_channelIcon(type.toString()),
              color: AppTheme.primaryGreen, size: 18),
        ),
        title: Text(name.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: type.toString().isNotEmpty
            ? Text(type.toString(),
                style: const TextStyle(fontSize: 12))
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subject.toString().isNotEmpty) ...[
                  const Text('Konu:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(subject.toString(), style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                ],
                if (body.toString().isNotEmpty) ...[
                  const Text('İçerik:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(body.toString(), style: const TextStyle(fontSize: 13)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _channelIcon(String type) {
    switch (type.toLowerCase()) {
      case 'sms':
        return Icons.sms_rounded;
      case 'email':
        return Icons.email_rounded;
      case 'whatsapp':
        return Icons.chat_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
