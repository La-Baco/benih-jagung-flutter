import 'package:flutter/material.dart';

import '../layanan/api.dart';
import '../tema.dart';
import '../widget/kartu_hasil.dart';

// Halaman Akun (Gambar 3.16b): nama, email, peran, ringkasan jumlah klasifikasi, dan logout.
class HalamanAkun extends StatefulWidget {
  const HalamanAkun({super.key, required this.api, required this.onSesiBerakhir, required this.onKeluar});

  final Api api;
  final VoidCallback onSesiBerakhir;
  final VoidCallback onKeluar;

  @override
  State<HalamanAkun> createState() => _HalamanAkunState();
}

class _HalamanAkunState extends State<HalamanAkun> {
  DaftarRiwayat? _data;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    try {
      final data = await widget.api.riwayat();
      if (mounted) setState(() => _data = data);
    } on GagalApi catch (e) {
      if (e.sesiBerakhir) widget.onSesiBerakhir();
      // Gagal memuat ringkasan tidak menghalangi logout; angka tetap tampil "-".
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final bergabung = data?.ringkasan.bergabung;
    return Scaffold(
      appBar: AppBar(title: const Text('Akun')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Kotak(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            child: Column(
              children: [
                const Icon(Icons.person_outline, size: 48, color: Warna.tinta),
                const SizedBox(height: 6),
                Text(widget.api.sesi.nama ?? '',
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text(widget.api.sesi.email ?? '',
                    textAlign: TextAlign.center, style: const TextStyle(color: Warna.tintaLembut)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(color: Warna.tinta),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Petani', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Ringkasan', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: KartuAngka(label: 'Klasifikasi', nilai: data == null ? '-' : '${data.total}')),
              const SizedBox(width: 10),
              Expanded(
                child: KartuAngka(
                  label: 'Bergabung',
                  nilai: bergabung == null ? '-' : formatTanggalSaja(bergabung),
                  besar: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const KotakCatatan(
            child: Text('Hasil klasifikasi didasarkan pada tampilan fisik benih dan tidak menggantikan uji '
                'daya berkecambah.'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: widget.onKeluar,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
