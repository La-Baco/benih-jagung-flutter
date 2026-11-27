import 'package:flutter/material.dart';

import '../layanan/api.dart';
import '../tema.dart';
import 'riwayat.dart';

// Halaman Beranda (Gambar 3.15a): jumlah klasifikasi, jumlah Layak dan Tidak Layak,
// tombol menuju klasifikasi, dan klasifikasi terakhir milik petani.
class HalamanBeranda extends StatefulWidget {
  const HalamanBeranda({super.key, required this.api, required this.onSesiBerakhir, required this.onKlasifikasi});

  final Api api;
  final VoidCallback onSesiBerakhir;
  final VoidCallback onKlasifikasi;

  @override
  State<HalamanBeranda> createState() => _HalamanBerandaState();
}

class _HalamanBerandaState extends State<HalamanBeranda> {
  DaftarRiwayat? _data;
  String? _galat;
  bool _memuat = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _memuat = true;
      _galat = null;
    });
    try {
      final data = await widget.api.riwayat();
      if (mounted) setState(() => _data = data);
    } on GagalApi catch (e) {
      if (e.sesiBerakhir) {
        widget.onSesiBerakhir();
        return;
      }
      if (mounted) setState(() => _galat = e.pesan);
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    String angka(int? n) => data == null ? '-' : '${n ?? 0}';
    return Scaffold(
      appBar: AppBar(title: const Text('Beranda')),
      body: RefreshIndicator(
        onRefresh: _muat,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Selamat datang,', style: TextStyle(color: Warna.tintaLembut)),
            Text(widget.api.sesi.nama ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            KartuAngka(label: 'Jumlah klasifikasi', nilai: angka(data?.total)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: KartuAngka(label: 'Layak', nilai: angka(data?.ringkasan.layak))),
                const SizedBox(width: 10),
                Expanded(child: KartuAngka(label: 'Tidak layak', nilai: angka(data?.ringkasan.tidakLayak))),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: widget.onKlasifikasi,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Klasifikasi benih'),
            ),
            const SizedBox(height: 20),
            const Text('Klasifikasi terakhir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            if (_galat != null) ...[
              const SizedBox(height: 6),
              PesanGalat(_galat!),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: _muat, child: const Text('Muat ulang')),
            ] else if (data == null && _memuat)
              const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
            else if (data != null && data.isi.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Belum ada klasifikasi. Tekan tombol Klasifikasi benih untuk memulai.',
                    style: TextStyle(color: Warna.tintaLembut)),
              )
            else if (data != null)
              for (final r in data.isi.take(3)) BarisRiwayat(riwayat: r, header: widget.api.headerToken),
          ],
        ),
      ),
    );
  }
}
