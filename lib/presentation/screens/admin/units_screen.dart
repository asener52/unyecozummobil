import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/units_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/unit.dart';

class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UnitsProvider>().fetchUnits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<UnitsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Birimler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => prov.fetchUnits(),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showUnitDialog(context, prov),
          ),
        ],
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : prov.error != null
              ? _ErrorView(
                  message: prov.error!,
                  onRetry: () => prov.fetchUnits(),
                )
              : RefreshIndicator(
                  onRefresh: () => prov.fetchUnits(),
                  child: prov.units.isEmpty
                      ? const _EmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: prov.units.length,
                          itemBuilder: (ctx, i) => _UnitCard(
                            unit: prov.units[i],
                            onEdit: () =>
                                _showUnitDialog(context, prov, unit: prov.units[i]),
                            onDelete: () =>
                                _confirmDelete(context, prov, prov.units[i]),
                          ),
                        ),
                ),
    );
  }

  void _showUnitDialog(BuildContext context, UnitsProvider prov, {Unit? unit}) {
    final nameCtrl = TextEditingController(text: unit?.name ?? '');
    final descCtrl = TextEditingController(text: unit?.description ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(unit == null ? 'Yeni Birim' : 'Birimi Düzenle'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Birim Adı'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ad zorunludur' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Açıklama'),
                maxLines: 2,
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
              bool ok;
              if (unit == null) {
                ok = await prov.createUnit({
                  'name': nameCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                });
              } else {
                ok = await prov.updateUnit(unit.id, {
                  'name': nameCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
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
            child: Text(unit == null ? 'Oluştur' : 'Güncelle'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, UnitsProvider prov, Unit unit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Birimi Sil'),
        content: Text('"${unit.name}" birimini silmek istediğinize emin misiniz?'),
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
              final ok = await prov.deleteUnit(unit.id);
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

class _UnitCard extends StatelessWidget {
  final Unit unit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _UnitCard(
      {required this.unit, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.12),
          child: const Icon(Icons.business_rounded,
              color: AppTheme.primaryGreen, size: 20),
        ),
        title: Text(unit.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (unit.description != null && unit.description!.isNotEmpty)
              Text(unit.description!,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            if (unit.requestCount != null)
              Text('${unit.requestCount} talep',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textHint)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!unit.isActive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Pasif',
                    style: TextStyle(
                        fontSize: 10, color: AppTheme.errorColor)),
              ),
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
        isThreeLine: unit.description != null && unit.description!.isNotEmpty,
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
          Icon(Icons.business_outlined, size: 56, color: AppTheme.textHint),
          SizedBox(height: 12),
          Text('Birim bulunamadı',
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
