import 'package:flutter/material.dart';

import '../layanan/api.dart';
import 'akun.dart';
import 'beranda.dart';
import 'klasifikasi.dart';
import 'masuk.dart';
import 'riwayat.dart';

// Kerangka setelah masuk: menu bawah Beranda, Klasifikasi, Riwayat, dan Akun (Gambar 3.15-3.16).
class HalamanUtama extends StatefulWidget {
  const HalamanUtama({super.key, required this.api});

  final Api api;

  @override
  State<HalamanUtama> createState() => _HalamanUtamaState();
}

class _HalamanUtamaState extends State<HalamanUtama> {
  int _tab = 0;
  // Dinaikkan setiap ada hasil baru, supaya Beranda, Riwayat, dan Akun dimuat ulang.
  int _versi = 0;

  // Beranda, Riwayat, dan Akun memuat data bersamaan; bila token ditolak, ketiganya melapor.
  // Pindah ke halaman masuk cukup sekali.
  bool _sudahKeluar = false;

  void _keHalamanMasuk(String? pesan) {
    if (_sudahKeluar || !mounted) return;
    _sudahKeluar = true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => HalamanMasuk(api: widget.api, pesanAwal: pesan)),
      (_) => false,
    );
  }

  void _sesiBerakhir() => _keHalamanMasuk('Sesi berakhir. Silakan masuk lagi.');

  Future<void> _keluar() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari aplikasi?'),
        content: const Text('Anda perlu memasukkan email dan kata sandi lagi untuk masuk.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (yakin != true) return;
    await widget.api.keluar();
    if (mounted) _keHalamanMasuk(null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          HalamanBeranda(
            key: ValueKey('beranda-$_versi'),
            api: widget.api,
            onSesiBerakhir: _sesiBerakhir,
            onKlasifikasi: () => setState(() => _tab = 1),
          ),
          HalamanKlasifikasi(
            api: widget.api,
            onSesiBerakhir: _sesiBerakhir,
            onHasilBaru: () => setState(() => _versi++),
            onKeBeranda: () => setState(() => _tab = 0),
          ),
          HalamanRiwayat(key: ValueKey('riwayat-$_versi'), api: widget.api, onSesiBerakhir: _sesiBerakhir),
          HalamanAkun(key: ValueKey('akun-$_versi'), api: widget.api, onSesiBerakhir: _sesiBerakhir, onKeluar: _keluar),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        // Beranda, Riwayat, dan Akun dimuat ulang setiap kali dibuka, supaya hasil terbaru
        // (termasuk dari perangkat lain) langsung terlihat. Halaman Klasifikasi tidak, agar
        // foto yang sedang dipilih tidak hilang.
        onDestinationSelected: (i) => setState(() {
          if (i != _tab && i != 1) _versi++;
          _tab = i;
        }),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(
              icon: Icon(Icons.photo_camera_outlined), selectedIcon: Icon(Icons.photo_camera), label: 'Klasifikasi'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Riwayat'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Akun'),
        ],
      ),
    );
  }
}
