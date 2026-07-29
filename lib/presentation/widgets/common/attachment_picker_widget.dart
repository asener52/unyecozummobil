import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class AttachedFile {
  final String path;
  final String name;
  final int? sizeBytes;

  const AttachedFile({
    required this.path,
    required this.name,
    this.sizeBytes,
  });

  String get extension => name.split('.').last.toLowerCase();

  bool get isImage =>
      ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  bool get isVideo => ['mp4', 'mpeg', 'mov', 'avi'].contains(extension);
  bool get isPdf => extension == 'pdf';
  bool get isWord => ['doc', 'docx'].contains(extension);
  bool get isExcel => ['xls', 'xlsx'].contains(extension);
  bool get isText => extension == 'txt';
  bool get isDocument => isPdf || isWord || isExcel || isText;

  String get mimeType {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mpeg':
        return 'video/mpeg';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  IconData get icon {
    if (isImage) return Icons.image_outlined;
    if (isVideo) return Icons.videocam_outlined;
    if (isPdf) return Icons.picture_as_pdf_outlined;
    if (isWord) return Icons.description_outlined;
    if (isExcel) return Icons.table_chart_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Color get iconColor {
    if (isImage) return Colors.blue;
    if (isVideo) return Colors.purple;
    if (isPdf) return Colors.red;
    if (isWord) return const Color(0xFF2B579A);
    if (isExcel) return const Color(0xFF217346);
    return Colors.grey;
  }

  String get sizeLabel {
    if (sizeBytes == null) return '';
    final kb = sizeBytes! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}

// ─── Widget ───────────────────────────────────────────────────────────────────

/// Evrensel dosya ekleme widget'ı.
/// Fotoğraf (kamera/galeri), video ve belge (PDF/Word/Excel/TXT) destekler.
class AttachmentPickerWidget extends StatelessWidget {
  final List<AttachedFile> files;
  final ValueChanged<List<AttachedFile>> onChanged;
  final int maxFiles;
  final int maxMb;

  const AttachmentPickerWidget({
    super.key,
    required this.files,
    required this.onChanged,
    this.maxFiles = 10,
    this.maxMb = 10,
  });

  // ── Picker yöntemleri ────────────────────────────────────────────────────

  Future<void> _pickCamera(BuildContext context) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked != null) _addFile(context, picked.path, picked.name);
  }

  Future<void> _pickGalleryImage(BuildContext context) async {
    final list = await ImagePicker().pickMultiImage(
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    for (final f in list) {
      _addFile(context, f.path, f.name);
    }
  }

  Future<void> _pickGalleryVideo(BuildContext context) async {
    final picked = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    if (picked != null) _addFile(context, picked.path, picked.name);
  }

  Future<void> _pickDocument(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
    );
    if (result == null) return;
    for (final f in result.files) {
      if (f.path != null) _addFile(context, f.path!, f.name, f.size);
    }
  }

  void _addFile(BuildContext context, String path, String name, [int? size]) {
    final stat = size ?? File(path).statSync().size;
    final maxBytes = maxMb * 1024 * 1024;
    if (stat > maxBytes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '"$name" dosyası çok büyük. Maksimum $maxMb MB yüklenebilir.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    if (files.length >= maxFiles) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('En fazla $maxFiles dosya eklenebilir.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    onChanged([...files, AttachedFile(path: path, name: name, sizeBytes: stat)]);
  }

  void _remove(int index) {
    final updated = [...files]..removeAt(index);
    onChanged(updated);
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Dosya Ekle',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            _SheetItem(
              icon: Icons.camera_alt_rounded,
              color: Colors.blue,
              label: 'Kamera ile Fotoğraf Çek',
              onTap: () {
                Navigator.pop(context);
                _pickCamera(context);
              },
            ),
            _SheetItem(
              icon: Icons.photo_library_rounded,
              color: Colors.teal,
              label: 'Galeriden Fotoğraf Seç',
              onTap: () {
                Navigator.pop(context);
                _pickGalleryImage(context);
              },
            ),
            _SheetItem(
              icon: Icons.videocam_rounded,
              color: Colors.purple,
              label: 'Galeriden Video Seç (MP4)',
              onTap: () {
                Navigator.pop(context);
                _pickGalleryVideo(context);
              },
            ),
            _SheetItem(
              icon: Icons.upload_file_rounded,
              color: Colors.orange,
              label: 'Belge Seç (PDF, Word, Excel, TXT)',
              onTap: () {
                Navigator.pop(context);
                _pickDocument(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dosya listesi
        if (files.isNotEmpty) ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: files.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) => _FileCard(
              file: files[i],
              onRemove: () => _remove(i),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Ekle butonu
        OutlinedButton.icon(
          onPressed: () => _showSheet(context),
          icon: const Icon(Icons.attach_file_rounded),
          label: Text(files.isEmpty ? 'Dosya / Medya Ekle' : 'Başka Dosya Ekle'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: BorderSide(color: AppTheme.primaryGreen.withValues(alpha: 0.6)),
            foregroundColor: AppTheme.primaryGreen,
          ),
        ),

        if (files.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${files.length} dosya seçildi  •  Maks $maxMb MB/dosya',
              style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
            ),
          ),
      ],
    );
  }
}

// ─── Yardımcı widget'lar ─────────────────────────────────────────────────────

class _FileCard extends StatelessWidget {
  final AttachedFile file;
  final VoidCallback onRemove;

  const _FileCard({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.dividerColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Önizleme / ikon
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 52,
              height: 52,
              child: file.isImage
                  ? Image.file(
                      File(file.path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _iconBox(file),
                    )
                  : _iconBox(file),
            ),
          ),
          const SizedBox(width: 10),
          // Ad + boyut
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                if (file.sizeBytes != null)
                  Text(
                    file.sizeLabel,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textHint),
                  ),
              ],
            ),
          ),
          // Kaldır butonu
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded,
                color: AppTheme.errorColor, size: 20),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }

  Widget _iconBox(AttachedFile f) {
    return Container(
      color: f.iconColor.withValues(alpha: 0.1),
      child: Center(
        child: Icon(f.icon, color: f.iconColor, size: 28),
      ),
    );
  }
}

class _SheetItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _SheetItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onTap: onTap,
    );
  }
}
