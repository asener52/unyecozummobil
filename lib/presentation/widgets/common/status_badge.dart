import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool small;

  const StatusBadge({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig[status] ?? _StatusConfig('Bilinmiyor', AppTheme.textHint);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.color,
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  const _StatusConfig(this.label, this.color);
}

const _statusConfig = <String, _StatusConfig>{
  'pending':     _StatusConfig('Beklemede',   Color(0xFFfaad14)),
  'in_progress': _StatusConfig('İşleme Alındı', AppTheme.warningColor),
  'resolved':    _StatusConfig('Onay Bekliyor', Color(0xFF13c2c2)),
  'approved':    _StatusConfig('Onaylandı',   AppTheme.successColor),
  'returned':    _StatusConfig('İade Edildi', Color(0xFF722ed1)),
  'rejected':    _StatusConfig('Reddedildi',  AppTheme.errorColor),
  'cancelled':   _StatusConfig('İptal',       AppTheme.textHint),
};
