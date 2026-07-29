import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/api_service.dart';

class PhoneDirectoryScreen extends StatefulWidget {
  const PhoneDirectoryScreen({super.key});

  @override
  State<PhoneDirectoryScreen> createState() => _PhoneDirectoryScreenState();
}

class _PhoneDirectoryScreenState extends State<PhoneDirectoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _searchCtrl = TextEditingController();
  String _query = '';

  // Dahili hatlar
  List<_Department> _departments = [];
  bool _loadingDahili = true;
  String? _dahiliError;

  // Kurumsal GSM
  List<_GsmGroup> _gsmGroups = _defaultGsm;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadDahili();
    _loadGsm();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDahili() async {
    setState(() {
      _loadingDahili = true;
      _dahiliError = null;
    });
    try {
      final res = await ApiService().get('/phone-directory');
      final raw = res.data;
      Map<String, dynamic>? data;
      if (raw is Map && raw['data'] is Map) {
        data = Map<String, dynamic>.from(raw['data']);
      } else if (raw is Map && raw['departments'] != null) {
        data = Map<String, dynamic>.from(raw);
      }
      if (data != null && data['departments'] is List) {
        final deps = (data['departments'] as List).map((d) {
          final personnel = (d['personnel'] as List? ?? []).map((p) => _Person(
            id: p['id']?.toString() ?? '',
            name: p['name']?.toString() ?? '',
            title: p['title']?.toString() ?? '',
            ext: p['ext']?.toString() ?? '',
          )).toList();
          return _Department(
            id: d['id']?.toString() ?? '',
            name: d['name']?.toString() ?? '',
            personnel: personnel,
          );
        }).toList();
        if (mounted) setState(() { _departments = deps; _loadingDahili = false; });
      } else {
        if (mounted) setState(() { _dahiliError = 'Dahili hat verisi bulunamadı.'; _loadingDahili = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _dahiliError = 'Dahili hatlar yüklenemedi.'; _loadingDahili = false; });
    }
  }

  Future<void> _loadGsm() async {
    // GSM verisi web'de localStorage'da saklanıyor. Backend'de ayrı endpoint yok.
    // İleride /api/settings/corporate-gsm endpoint'i eklenirse buradan çekilebilir.
    try {
      final res = await ApiService().get('/settings/corporate-gsm');
      final raw = res.data;
      if (raw is Map && raw['groups'] is List) {
        final groups = (raw['groups'] as List).map((g) {
          final entries = (g['entries'] as List? ?? []).map((e) => _GsmEntry(
            id: e['id']?.toString() ?? '',
            name: e['name']?.toString() ?? '',
            gsm: e['gsm']?.toString() ?? '',
            note: e['note']?.toString() ?? '',
          )).toList();
          return _GsmGroup(
            id: g['id']?.toString() ?? '',
            title: g['title']?.toString() ?? '',
            entries: entries,
          );
        }).toList();
        if (mounted) setState(() => _gsmGroups = groups);
      }
    } catch (_) {
      // Yedek: varsayılan veriyi kullan
    }
  }

  Future<void> _call(String number) async {
    final clean = number.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arama başlatılamadı')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telefon Rehberi'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.phone_outlined, size: 18), text: 'Dahili Hatlar'),
            Tab(icon: Icon(Icons.smartphone_outlined, size: 18), text: 'Kurumsal GSM'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Arama kutusu
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'İsim, ünvan veya numara ara...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: AppTheme.backgroundGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _DahiliTab(
                  departments: _departments,
                  loading: _loadingDahili,
                  error: _dahiliError,
                  query: _query,
                  onRetry: _loadDahili,
                  onCall: _call,
                ),
                _GsmTab(
                  groups: _gsmGroups,
                  query: _query,
                  onCall: _call,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dahili Hatlar Sekmesi ────────────────────────────────────────────────────

class _DahiliTab extends StatelessWidget {
  final List<_Department> departments;
  final bool loading;
  final String? error;
  final String query;
  final VoidCallback onRetry;
  final Future<void> Function(String) onCall;

  const _DahiliTab({
    required this.departments,
    required this.loading,
    required this.error,
    required this.query,
    required this.onRetry,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
              const SizedBox(height: 12),
              Text(error!, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _filterDepartments(departments, query);

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: AppTheme.textHint),
            const SizedBox(height: 12),
            Text(
              query.isEmpty ? 'Dahili hat listesi boş.' : '"$query" için sonuç bulunamadı.',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final dept = filtered[i];
        return _DepartmentSection(dept: dept, query: query, onCall: onCall);
      },
    );
  }

  List<_Department> _filterDepartments(List<_Department> deps, String q) {
    if (q.isEmpty) return deps;
    return deps
        .map((d) {
          final matching = d.personnel.where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.title.toLowerCase().contains(q) ||
              p.ext.toLowerCase().contains(q)).toList();
          return _Department(id: d.id, name: d.name, personnel: matching);
        })
        .where((d) => d.personnel.isNotEmpty || d.name.toLowerCase().contains(q))
        .toList();
  }
}

class _DepartmentSection extends StatefulWidget {
  final _Department dept;
  final String query;
  final Future<void> Function(String) onCall;

  const _DepartmentSection({
    required this.dept,
    required this.query,
    required this.onCall,
  });

  @override
  State<_DepartmentSection> createState() => _DepartmentSectionState();
}

class _DepartmentSectionState extends State<_DepartmentSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: _expanded ? Radius.zero : const Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business_outlined,
                      size: 16, color: AppTheme.primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.dept.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                  Text(
                    '${widget.dept.personnel.length} kişi',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textHint),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppTheme.primaryGreen,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            ...widget.dept.personnel.map((p) => _PersonTile(
                  person: p,
                  query: widget.query,
                  onCall: widget.onCall,
                  isLast: p == widget.dept.personnel.last,
                )),
        ],
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  final _Person person;
  final String query;
  final Future<void> Function(String) onCall;
  final bool isLast;

  const _PersonTile({
    required this.person,
    required this.query,
    required this.onCall,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline,
                size: 18, color: AppTheme.primaryGreen),
          ),
          title: _HighlightText(text: person.name, query: query,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          subtitle: person.title.isNotEmpty
              ? _HighlightText(
                  text: person.title,
                  query: query,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                )
              : null,
          trailing: person.ext.isNotEmpty
              ? GestureDetector(
                  onTap: () => onCall(person.ext),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone, size: 13, color: AppTheme.primaryGreen),
                        const SizedBox(width: 4),
                        _HighlightText(
                          text: person.ext,
                          query: query,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        ),
        if (!isLast)
          const Divider(height: 1, indent: 64),
      ],
    );
  }
}

// ── Kurumsal GSM Sekmesi ─────────────────────────────────────────────────────

class _GsmTab extends StatelessWidget {
  final List<_GsmGroup> groups;
  final String query;
  final Future<void> Function(String) onCall;

  const _GsmTab({
    required this.groups,
    required this.query,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = _filterGroups(groups, query);

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: AppTheme.textHint),
            const SizedBox(height: 12),
            Text(
              query.isEmpty ? 'GSM listesi boş.' : '"$query" için sonuç bulunamadı.',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final group = filtered[i];
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withValues(alpha: 0.08),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.smartphone_outlined,
                        size: 16, color: AppTheme.infoColor),
                    const SizedBox(width: 8),
                    Text(
                      group.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppTheme.infoColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (group.entries.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('Bu grupta kayıt yok.',
                      style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
                )
              else
                ...group.entries.map((e) => Column(
                      children: [
                        ListTile(
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.infoColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_outline,
                                size: 18, color: AppTheme.infoColor),
                          ),
                          title: _HighlightText(
                            text: e.name,
                            query: query,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          subtitle: e.note.isNotEmpty
                              ? Text(e.note,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary))
                              : null,
                          trailing: e.gsm.isNotEmpty
                              ? GestureDetector(
                                  onTap: () => onCall(e.gsm),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: AppTheme.infoColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.smartphone,
                                            size: 13, color: AppTheme.infoColor),
                                        const SizedBox(width: 4),
                                        _HighlightText(
                                          text: e.gsm,
                                          query: query,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: AppTheme.infoColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        if (e != group.entries.last)
                          const Divider(height: 1, indent: 64),
                      ],
                    )),
            ],
          ),
        );
      },
    );
  }

  List<_GsmGroup> _filterGroups(List<_GsmGroup> gs, String q) {
    if (q.isEmpty) return gs;
    return gs
        .map((g) {
          final matching = g.entries.where((e) =>
              e.name.toLowerCase().contains(q) ||
              e.gsm.toLowerCase().contains(q) ||
              e.note.toLowerCase().contains(q)).toList();
          return _GsmGroup(id: g.id, title: g.title, entries: matching);
        })
        .where((g) => g.entries.isNotEmpty || g.title.toLowerCase().contains(q))
        .toList();
  }
}

// ── Arama sonucu vurgulama ───────────────────────────────────────────────────

class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;

  const _HighlightText({
    required this.text,
    required this.query,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, style: style);
    final lower = text.toLowerCase();
    final idx = lower.indexOf(query.toLowerCase());
    if (idx == -1) return Text(text, style: style);
    return RichText(
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: style.copyWith(
              backgroundColor: const Color(0xFFfff566),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }
}

// ── Veri modelleri ───────────────────────────────────────────────────────────

class _Department {
  final String id;
  final String name;
  final List<_Person> personnel;
  const _Department({required this.id, required this.name, required this.personnel});
}

class _Person {
  final String id;
  final String name;
  final String title;
  final String ext;
  const _Person({required this.id, required this.name, required this.title, required this.ext});
}

class _GsmGroup {
  final String id;
  final String title;
  final List<_GsmEntry> entries;
  const _GsmGroup({required this.id, required this.title, required this.entries});
}

class _GsmEntry {
  final String id;
  final String name;
  final String gsm;
  final String note;
  const _GsmEntry({required this.id, required this.name, required this.gsm, required this.note});
}

// ── Varsayılan GSM verisi (web FloatingPanel ile senkron) ────────────────────

const List<_GsmGroup> _defaultGsm = [
  _GsmGroup(
    id: '1',
    title: 'Üst Yönetim',
    entries: [
      _GsmEntry(id: '1', name: 'Başkan', gsm: '', note: ''),
      _GsmEntry(id: '2', name: 'Başkan Yardımcısı', gsm: '', note: ''),
    ],
  ),
  _GsmGroup(
    id: '2',
    title: 'Müdürler',
    entries: [],
  ),
];
