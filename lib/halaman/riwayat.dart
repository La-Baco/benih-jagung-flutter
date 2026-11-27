import 'package:flutter/material.dart';

import '../layanan/api.dart';
import '../tema.dart';
import '../widget/kartu_hasil.dart';

// Halaman Riwayat Klasifikasi (Gambar 3.16a): hanya riwayat milik petani yang masuk.
class HalamanRiwayat extends StatefulWidget {
  const HalamanRiwayat({super.key, required this.api, required this.onSesiBerakhir});

  final Api api;
  final VoidCallback onSesiBerakhir;

  @override
  State<HalamanRiwayat> createState() => _HalamanRiwayatState();
}

class _HalamanRiwayatState extends State<HalamanRiwayat> {
  final List<Riwayat> _isi = [];
  int _halaman = 0;
  int _halamanTerakhir = 1;
  bool _memuat = false;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat({bool ulang = false}) async {
    if (_memuat) return;
    setState(() {
      _memuat = true;
      _galat = null;
    });
    try {
      final hasil = await widget.api.riwayat(halaman: ulang ? 1 : _halaman + 1);
      setState(() {
        if (ulang) _isi.clear();
        _isi.addAll(hasil.isi);
        _halaman = hasil.halaman;
        _halamanTerakhir = hasil.halamanTerakhir;
      });
    } on GagalApi catch (e) {
      if (e.sesiBerakhir) {
        widget.onSesiBerakhir();
        return;
      }
      setState(() => _galat = e.pesan);
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Klasifikasi')),
      body: _isi.isEmpty && _memuat
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [CircularProgressIndicator(), SizedBox(height: 12), Text('Memuat riwayat...')],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _muat(ulang: true),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_isi.isEmpty && _galat == null)
                    const Kotak(
                      child: Text('Belum ada riwayat. Hasil setiap klasifikasi benih akan tersimpan di sini.',
                          style: TextStyle(color: Warna.tintaLembut)),
                    ),
                  for (final r in _isi) BarisRiwayat(riwayat: r, header: widget.api.headerToken),
                  if (_galat != null) ...[
                    PesanGalat(_galat!),
                    const SizedBox(height: 8),
                    OutlinedButton(onPressed: () => _muat(ulang: _isi.isEmpty), child: const Text('Coba lagi')),
                  ] else if (_halaman < _halamanTerakhir) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _memuat ? null : _muat,
                      child: Text(_memuat ? 'Memuat...' : 'Tampilkan riwayat sebelumnya'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

// Satu baris riwayat: citra, kelas hasil, skor kepercayaan, dan waktu (Gambar 3.15a dan 3.16a).
class BarisRiwayat extends StatelessWidget {
  const BarisRiwayat({super.key, required this.riwayat, required this.header});

  final Riwayat riwayat;
  final Map<String, String> header;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => HalamanDetailRiwayat(riwayat: riwayat, header: header),
      )),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Warna.garis))),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(width: 56, height: 56, child: _gambar(riwayat, header)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LencanaHasil(riwayat.hasil),
                  const SizedBox(height: 4),
                  Text.rich(TextSpan(children: [
                    const TextSpan(text: 'Skor kepercayaan: '),
                    TextSpan(text: formatSkor(riwayat.skor), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ])),
                  Text(formatTanggal(riwayat.waktu), style: const TextStyle(fontSize: 12, color: Warna.tintaLembut)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Warna.tintaLembut),
          ],
        ),
      ),
    );
  }
}

// Foto riwayat hanya bisa diambil dengan token pemiliknya.
Widget _gambar(Riwayat riwayat, Map<String, String> header) {
  return ColoredBox(
    color: const Color(0xFF222222),
    child: Image.network(
      riwayat.urlGambar,
      headers: header,
      fit: BoxFit.cover,
      cacheWidth: 168,
      semanticLabel: 'Foto benih',
      errorBuilder: (_, _, _) => const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white70, semanticLabel: 'Foto tidak dapat dimuat'),
      ),
    ),
  );
}

class HalamanDetailRiwayat extends StatelessWidget {
  const HalamanDetailRiwayat({super.key, required this.riwayat, required this.header});

  final Riwayat riwayat;
  final Map<String, String> header;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Klasifikasi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [TampilanHasil(riwayat: riwayat, gambar: NetworkImage(riwayat.urlGambar, headers: header))],
      ),
    );
  }
}
