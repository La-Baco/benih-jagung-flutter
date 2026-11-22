import 'package:flutter/material.dart';

import '../layanan/api.dart';
import 'kamera.dart';
import 'masuk.dart';
import 'periksa.dart';
import 'riwayat.dart';

class HalamanBeranda extends StatefulWidget {
  const HalamanBeranda({super.key, required this.api});

  final Api api;

  @override
  State<HalamanBeranda> createState() => _HalamanBerandaState();
}

class _HalamanBerandaState extends State<HalamanBeranda> {
  int _tab = 0;
  // Dinaikkan setiap ada hasil baru, supaya daftar riwayat dimuat ulang saat dibuka.
  int _versiRiwayat = 0;

  void _keHalamanMasuk(String? pesan) {
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
      appBar: AppBar(
        title: Text(const ['Periksa Benih', 'Kamera Langsung', 'Riwayat'][_tab]),
        actions: [
          TextButton(onPressed: _keluar, child: const Text('Keluar')),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          HalamanPeriksa(
            api: widget.api,
            onSesiBerakhir: _sesiBerakhir,
            onHasilBaru: () => setState(() => _versiRiwayat++),
          ),
          // Kamera hanya dibuat saat tabnya dibuka, supaya kamera tidak menyala di belakang tab lain.
          _tab == 1 ? HalamanKamera(api: widget.api, onSesiBerakhir: _sesiBerakhir) : const SizedBox.shrink(),
          HalamanRiwayat(
            key: ValueKey(_versiRiwayat),
            api: widget.api,
            onSesiBerakhir: _sesiBerakhir,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.photo_camera_outlined), label: 'Periksa'),
          NavigationDestination(icon: Icon(Icons.center_focus_strong_outlined), label: 'Kamera'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Riwayat'),
        ],
      ),
    );
  }
}
