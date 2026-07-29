import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gizlilik Politikası'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: _PolicyContent(),
      ),
    );
  }
}

class _PolicyContent extends StatelessWidget {
  const _PolicyContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Title('Gizlilik Politikası'),
        _Meta('Son güncelleme: Temmuz 2026'),
        SizedBox(height: 20),

        _Section('1. Veri Sorumlusu'),
        _Body(
          'Bu gizlilik politikası, Ünye Belediyesi tarafından geliştirilen ve '
          'işletilen Ünye Çözüm Merkezi mobil uygulaması ve web portalına ilişkindir.\n\n'
          'Adres: Ünye Belediyesi, Ünye / Ordu\n'
          'E-posta: unye@unye.bel.tr\n'
          'Web: www.unye.bel.tr',
        ),

        _Section('2. Toplanan Kişisel Veriler'),
        _Body('Uygulama aşağıdaki kişisel verileri işlemektedir:'),
        _Bullet('Kimlik bilgileri: Ad, soyad, T.C. kimlik numarası (isteğe bağlı)'),
        _Bullet('İletişim bilgileri: Telefon numarası, e-posta adresi'),
        _Bullet('Talep içeriği: Başvuru konusu, açıklama, yüklenen dosya ve fotoğraflar'),
        _Bullet('Konum: Talep kaydı sırasında paylaşılan adres bilgisi'),
        _Bullet('Cihaz bilgisi: Bildirim gönderimi için FCM token'),

        _Section('3. Verilerin İşlenme Amacı'),
        _Bullet('Vatandaş başvurularının alınması, işlenmesi ve sonuçlandırılması'),
        _Bullet('Başvuru durumu hakkında SMS ve anlık bildirim gönderimi'),
        _Bullet('Memnuniyet anketi iletimi'),
        _Bullet('Yasal yükümlülüklerin yerine getirilmesi'),

        _Section('4. Hukuki Dayanak'),
        _Body(
          'Kişisel verileriniz; 6698 sayılı Kişisel Verilerin Korunması Kanunu (KVKK) '
          'kapsamında, kanunlarda açıkça öngörülmesi ve ilgili kişinin temel hak ve '
          'özgürlüklerine zarar vermemek kaydıyla veri sorumlusunun meşru menfaatleri '
          'hukuki sebeplerine dayalı olarak işlenmektedir.',
        ),

        _Section('5. Verilerin Paylaşımı'),
        _Body(
          'Kişisel verileriniz; yetkili kamu kurum ve kuruluşlarının talepleri dışında '
          'üçüncü taraflarla paylaşılmamaktadır. SMS gönderimi için yalnızca yetkili SMS '
          'hizmet sağlayıcısı kullanılmakta olup bu sağlayıcı verilerinizi başka amaçlarla '
          'işleyememektedir.',
        ),

        _Section('6. Saklama Süresi'),
        _Body(
          'Başvuru ve iletişim verileri, ilgili mevzuatta öngörülen süreler boyunca '
          'saklanmaktadır. Yasal zorunluluk bulunmayan veriler, işleme amacı ortadan '
          'kalktığında silinmektedir.',
        ),

        _Section('7. Çerezler ve Analitik'),
        _Body(
          'Uygulama; reklam takibi, üçüncü taraf analitik veya profil oluşturma amacıyla '
          'çerez kullanmamaktadır. Oturum yönetimi için yalnızca yerel depolama kullanılmaktadır.',
        ),

        _Section('8. KVKK Kapsamındaki Haklarınız'),
        _Body('6698 sayılı Kanun\'un 11. maddesi uyarınca aşağıdaki haklara sahipsiniz:'),
        _Bullet('Kişisel verilerinizin işlenip işlenmediğini öğrenme'),
        _Bullet('İşlenmişse buna ilişkin bilgi talep etme'),
        _Bullet('Verilerin düzeltilmesini veya silinmesini isteme'),
        _Bullet('İşlemenin kısıtlanmasını talep etme'),
        _Bullet('Verilerin aktarıldığı üçüncü kişileri öğrenme'),
        SizedBox(height: 6),
        _Body(
          'Başvurularınızı unye@unye.bel.tr adresine veya '
          'Ünye Belediyesi\'ne yazılı olarak iletebilirsiniz.',
        ),

        _Section('9. İletişim'),
        _Body(
          'Gizlilik politikamıza ilişkin sorularınız için:\n'
          'E-posta: unye@unye.bel.tr\n'
          'Telefon: 0 (452) 323 19 41',
        ),

        SizedBox(height: 32),
        _Footer('© 2026 Ünye Belediyesi — Tüm hakları saklıdır.'),
        SizedBox(height: 16),
      ],
    );
  }
}

// ── Yardımcı widget'lar ──────────────────────────────────────────────────────

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryGreen,
        ),
      );
}

class _Meta extends StatelessWidget {
  final String text;
  const _Meta(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
        ),
      );
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      );
}

class _Body extends StatelessWidget {
  final String text;
  const _Body(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.6,
          ),
        ),
      );
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 7),
              child: Icon(Icons.circle, size: 5, color: AppTheme.primaryGreen),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      );
}

class _Footer extends StatelessWidget {
  final String text;
  const _Footer(this.text);
  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
        ),
      );
}
