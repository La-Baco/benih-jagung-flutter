import 'package:flutter/material.dart';

import '../layanan/api.dart';
import '../tema.dart';
import '../widget/kartu_hasil.dart';

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
  int _total = 0;
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
        _total = hasil.total;
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
    if (_isi.isEmpty && _memuat) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [CircularProgressIndicator(), SizedBox(height: 12), Text('Memuat riwayat...')],
        ),
      );
    }

    if (_isi.isEmpty && _galat != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PesanGalat(_galat!),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () => _muat(ulang: true), child: const Text('Coba lagi')),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => _muat(ulang: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        // Satu baris tambahan di awal untuk jumlah, satu di akhir untuk tombol muat berikutnya.
        itemCount: _isi.length + 2,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i == 0) return _judul();
          if (i == _isi.length + 1) return _bawah();
          return _BarisRiwayat(riwayat: _isi[i - 1], header: widget.api.headerToken);
        },
      ),
    );
  }

  Widget _judul() {
    if (_isi.isEmpty) {
      return const Kotak(
        child: Text('Belum ada riwayat. Hasil setiap pemeriksaan benih akan tersimpan di sini.',
            style: TextStyle(color: Warna.tintaLembut)),
      );
    }
    return Text('$_total pemeriksaan tersimpan', style: const TextStyle(color: Warna.tintaLembut));
  }

  Widget _bawah() {
    if (_galat != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PesanGalat(_galat!),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _muat, child: const Text('Coba lagi')),
        ],
      );
    }
    if (_halaman >= _halamanTerakhir) return const SizedBox.shrink();
    return OutlinedButton(
      onPressed: _memuat ? null : _muat,
      child: Text(_memuat ? 'Memuat...' : 'Tampilkan riwayat sebelumnya'),
    );
  }
}

class _BarisRiwayat extends StatelessWidget {
  const _BarisRiwayat({required this.riwayat, required this.header});

  final Riwayat riwayat;
  final Map<String, String> header;

  @override
  Widget build(BuildContext context) {
    final warna = riwayat.layak ? Warna.hasilLayak : Warna.hasilTidakLayak;
    return Material(
      color: Warna.kertas,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Warna.garis),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => _DetailRiwayat(riwayat: riwayat, header: header),
        )),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(width: 64, height: 64, child: _gambar(riwayat, header, kecil: true)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(riwayat.hasil, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: warna)),
                    Text('Skor ${formatSkor(riwayat.skor)}'),
                    Text(formatTanggal(riwayat.waktu), style: const TextStyle(fontSize: 13, color: Warna.tintaLembut)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Warna.tintaLembut),
            ],
          ),
        ),
      ),
    );
  }
}

// Foto riwayat hanya bisa diambil dengan token pemiliknya.
Widget _gambar(Riwayat riwayat, Map<String, String> header, {bool kecil = false}) {
  return ColoredBox(
    color: const Color(0xFF222222),
    child: Image.network(
      riwayat.urlGambar,
      headers: header,
      fit: BoxFit.cover,
      cacheWidth: kecil ? 192 : null,
      semanticLabel: 'Foto benih',
      errorBuilder: (_, _, _) => const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white70, semanticLabel: 'Foto tidak dapat dimuat'),
      ),
    ),
  );
}

class _DetailRiwayat extends StatelessWidget {
  const _DetailRiwayat({required this.riwayat, required this.header});

  final Riwayat riwayat;
  final Map<String, String> header;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Riwayat')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [KartuHasil(riwayat: riwayat, gambar: _gambar(riwayat, header))],
      ),
    );
  }
}
