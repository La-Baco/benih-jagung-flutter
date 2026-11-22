import 'package:flutter/material.dart';

import '../layanan/api.dart';
import '../tema.dart';

String formatTanggal(DateTime waktu) {
  const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  final jam = '${waktu.hour.toString().padLeft(2, '0')}.${waktu.minute.toString().padLeft(2, '0')}';
  return '${waktu.day} ${bulan[waktu.month - 1]} ${waktu.year}, $jam';
}

String formatSkor(double skor) => '${skor.toStringAsFixed(2).replaceAll('.', ',')}%';

class KartuHasil extends StatelessWidget {
  const KartuHasil({super.key, required this.riwayat, required this.gambar});

  final Riwayat riwayat;
  final Widget gambar;

  @override
  Widget build(BuildContext context) {
    final warna = riwayat.layak ? Warna.hasilLayak : Warna.hasilTidakLayak;
    return Kotak(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Hasil klasifikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: AspectRatio(aspectRatio: 1, child: ColoredBox(color: const Color(0xFF222222), child: gambar)),
          ),
          const SizedBox(height: 14),
          Semantics(
            liveRegion: true,
            child: Text(
              riwayat.hasil,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: warna, height: 1.2),
            ),
          ),
          const SizedBox(height: 6),
          Text('Skor kepercayaan: ${formatSkor(riwayat.skor)}'),
          const SizedBox(height: 8),
          // Batang berwarna tinta, bukan hijau: batang menunjukkan keyakinan terhadap kelas
          // yang diprediksi, jadi hijau akan menyesatkan saat hasilnya Tidak Layak.
          ExcludeSemantics(
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: Warna.batangLatar,
                border: Border.all(color: Warna.tinta),
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (riwayat.skor / 100).clamp(0, 1),
                child: const ColoredBox(color: Warna.tinta),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(formatTanggal(riwayat.waktu), style: const TextStyle(fontSize: 13, color: Warna.tintaLembut)),
          const SizedBox(height: 4),
          const Text(
            'Hasil didasarkan pada tampilan fisik benih dan tidak menggantikan uji daya berkecambah. '
            'Model dilatih di perangkat pengembang (laptop peneliti); server hanya menjalankan prediksi.',
            style: TextStyle(fontSize: 13, color: Warna.tintaLembut),
          ),
        ],
      ),
    );
  }
}
