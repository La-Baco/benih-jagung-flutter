import 'package:flutter/material.dart';

import '../layanan/api.dart';
import '../tema.dart';
import 'kotak_objek.dart';

String formatTanggal(DateTime waktu) {
  const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  final jam = '${waktu.hour.toString().padLeft(2, '0')}.${waktu.minute.toString().padLeft(2, '0')}';
  return '${waktu.day} ${bulan[waktu.month - 1]} ${waktu.year}, $jam';
}

String formatTanggalSaja(DateTime waktu) {
  const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  return '${waktu.day} ${bulan[waktu.month - 1]} ${waktu.year}';
}

String formatSkor(double skor) => '${skor.toStringAsFixed(2).replaceAll('.', ',')}%';

// Isi halaman Hasil Klasifikasi (Gambar 3.15c): citra yang dikirim, kelas hasil prediksi,
// skor kepercayaan, dan keterangan bahwa hasil didasarkan pada tampilan fisik benih.
class TampilanHasil extends StatelessWidget {
  const TampilanHasil({super.key, required this.riwayat, required this.gambar});

  final Riwayat riwayat;
  final ImageProvider gambar;

  @override
  Widget build(BuildContext context) {
    final warna = warnaHasil(riwayat.hasil);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: GambarBerkotak(gambar: gambar, objek: riwayat.objek, keterangan: 'Foto yang diklasifikasi'),
        ),
        const SizedBox(height: 14),
        Kotak(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Hasil klasifikasi',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Warna.tintaLembut)),
              const SizedBox(height: 2),
              Semantics(
                liveRegion: true,
                child: Text(riwayat.hasil,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: warna, height: 1.25)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(child: Text('Skor kepercayaan:')),
                  Text(formatSkor(riwayat.skor), style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              // Batang berwarna tinta, bukan hijau: batang menunjukkan keyakinan terhadap kelas
              // yang diprediksi, jadi hijau akan menyesatkan saat hasilnya Tidak Layak.
              ExcludeSemantics(
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(color: Warna.batangLatar, borderRadius: BorderRadius.circular(5)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (riwayat.skor / 100).clamp(0, 1),
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Warna.tinta, borderRadius: BorderRadius.circular(5)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(formatTanggal(riwayat.waktu),
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Warna.tintaLembut)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const KotakCatatan(
          child: Text('Hasil didasarkan pada tampilan fisik benih dan tidak menggantikan uji daya berkecambah.'),
        ),
      ],
    );
  }
}
