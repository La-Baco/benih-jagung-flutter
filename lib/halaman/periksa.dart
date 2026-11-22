import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../layanan/api.dart';
import '../tema.dart';
import '../widget/kartu_hasil.dart';

const batasUkuranCitra = 10 * 1024 * 1024;

// Mengembalikan pesan kesalahan, atau null bila citra boleh dikirim. Format dibaca dari
// beberapa byte awal berkas, bukan dari nama berkas.
Future<String?> periksaBerkasCitra(File berkas) async {
  final ukuran = await berkas.length();
  if (ukuran == 0) return 'Citra tidak valid. Berkas kosong.';
  final awal = await berkas.openRead(0, 8).fold<List<int>>([], (a, b) => a..addAll(b));
  final jpeg = awal.length >= 3 && awal[0] == 0xFF && awal[1] == 0xD8 && awal[2] == 0xFF;
  final png = awal.length >= 4 && awal[0] == 0x89 && awal[1] == 0x50 && awal[2] == 0x4E && awal[3] == 0x47;
  if (!jpeg && !png) return 'Citra tidak valid. Pilih citra berformat JPEG atau PNG.';
  if (ukuran > batasUkuranCitra) return 'Citra tidak valid. Ukuran citra maksimal 10 MB.';
  return null;
}

class HalamanPeriksa extends StatefulWidget {
  const HalamanPeriksa({super.key, required this.api, required this.onSesiBerakhir, required this.onHasilBaru});

  final Api api;
  final VoidCallback onSesiBerakhir;
  final VoidCallback onHasilBaru;

  @override
  State<HalamanPeriksa> createState() => _HalamanPeriksaState();
}

class _HalamanPeriksaState extends State<HalamanPeriksa> {
  final _pemilih = ImagePicker();
  File? _foto;
  Riwayat? _hasil;
  String? _galat;
  bool _memproses = false;

  Future<void> _pilih(ImageSource sumber) async {
    // Lebar 3000 px sama dengan lebar acuan prapemrosesan (LEBAR_ACUAN di config.py),
    // jadi foto diperkecil di HP tanpa mengubah hasil dan unggahan lebih ringan.
    // Foto galeri diambil apa adanya, supaya ukuran dan formatnya bisa diperiksa sesuai batas
    // Tabel REST API (JPEG atau PNG, maksimal 10 MB) sebelum dikirim.
    final XFile? berkas;
    try {
      berkas = sumber == ImageSource.camera
          ? await _pemilih.pickImage(source: sumber, maxWidth: 3000, imageQuality: 92)
          : await _pemilih.pickImage(source: sumber);
    } catch (_) {
      setState(() => _galat = sumber == ImageSource.camera
          ? 'Kamera tidak dapat dibuka. Periksa izin kamera di pengaturan HP.'
          : 'Galeri tidak dapat dibuka. Periksa izin penyimpanan di pengaturan HP.');
      return;
    }
    if (berkas == null) return;
    final masalah = await periksaBerkasCitra(File(berkas.path));
    if (masalah != null) {
      setState(() {
        _foto = null;
        _hasil = null;
        _galat = masalah;
      });
      return;
    }
    setState(() {
      _foto = File(berkas!.path);
      _hasil = null;
      _galat = null;
    });
  }

  Future<void> _periksa() async {
    setState(() {
      _memproses = true;
      _galat = null;
    });
    try {
      final hasil = await widget.api.klasifikasi(_foto!);
      setState(() {
        _hasil = hasil;
        _memproses = false;
      });
      widget.onHasilBaru();
    } on GagalApi catch (e) {
      if (e.sesiBerakhir) {
        widget.onSesiBerakhir();
        return;
      }
      setState(() {
        _galat = e.pesan;
        _memproses = false;
      });
    }
  }

  void _ulang() => setState(() {
        _foto = null;
        _hasil = null;
        _galat = null;
      });

  @override
  Widget build(BuildContext context) {
    final nama = widget.api.sesi.nama;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_hasil == null && _foto == null && nama != null) ...[
          Text('Halo, $nama', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Foto satu butir benih untuk mengetahui apakah benih layak tanam.',
              style: TextStyle(color: Warna.tintaLembut)),
          const SizedBox(height: 16),
        ],
        if (_galat != null) ...[
          PesanGalat(_galat!),
          const SizedBox(height: 16),
        ],
        if (_hasil != null)
          ..._bagianHasil()
        else if (_foto != null)
          ..._bagianPratinjau()
        else
          ..._bagianPilihFoto(),
      ],
    );
  }

  List<Widget> _bagianPilihFoto() {
    return [
      FilledButton.icon(
        onPressed: () => _pilih(ImageSource.camera),
        icon: const Icon(Icons.photo_camera_outlined),
        label: const Text('Ambil foto benih'),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: () => _pilih(ImageSource.gallery),
        icon: const Icon(Icons.photo_library_outlined),
        label: const Text('Pilih dari galeri'),
      ),
      const SizedBox(height: 20),
      const Kotak(child: _PanduanFoto()),
    ];
  }

  List<Widget> _bagianPratinjau() {
    return [
      Kotak(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Foto yang akan diperiksa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: AspectRatio(
                aspectRatio: 1,
                child: ColoredBox(
                  color: const Color(0xFF222222),
                  child: Image.file(_foto!, fit: BoxFit.contain, semanticLabel: 'Foto benih yang dipilih'),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: _memproses ? null : _periksa,
        child: _memproses
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  SizedBox(width: 10),
                  Text('Memeriksa benih...'),
                ],
              )
            : const Text('Periksa benih ini'),
      ),
      const SizedBox(height: 10),
      OutlinedButton(onPressed: _memproses ? null : _ulang, child: const Text('Ganti foto')),
    ];
  }

  List<Widget> _bagianHasil() {
    return [
      KartuHasil(riwayat: _hasil!, gambar: Image.file(_foto!, fit: BoxFit.cover)),
      const SizedBox(height: 16),
      FilledButton(onPressed: _ulang, child: const Text('Periksa benih lain')),
    ];
  }
}

// Isi panduan mengikuti protokol pengambilan citra (Tabel 3.3), karena model hanya
// dilatih dengan foto seperti itu.
class _PanduanFoto extends StatelessWidget {
  const _PanduanFoto();

  @override
  Widget build(BuildContext context) {
    const langkah = [
      'Letakkan satu butir benih di tengah alas hitam.',
      'Foto tegak lurus dari atas, benih tidak terpotong.',
      'Matikan lampu kilat dan hindari bayangan tangan.',
      'Foto di tempat terang dengan cahaya merata.',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cara memfoto benih', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        for (var i = 0; i < langkah.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 22, child: Text('${i + 1}.', style: const TextStyle(fontWeight: FontWeight.w700))),
                Expanded(child: Text(langkah[i])),
              ],
            ),
          ),
        const SizedBox(height: 4),
        const Text('Foto dengan latar lain atau beberapa benih sekaligus tidak dapat diperiksa.',
            style: TextStyle(fontSize: 13, color: Warna.tintaLembut)),
      ],
    );
  }
}
