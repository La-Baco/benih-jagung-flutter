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

// Halaman Klasifikasi Benih (Gambar 3.15b) dan Hasil Klasifikasi (Gambar 3.15c).
class HalamanKlasifikasi extends StatefulWidget {
  const HalamanKlasifikasi({
    super.key,
    required this.api,
    required this.onSesiBerakhir,
    required this.onHasilBaru,
    required this.onKeBeranda,
  });

  final Api api;
  final VoidCallback onSesiBerakhir;
  final VoidCallback onHasilBaru;
  final VoidCallback onKeBeranda;

  @override
  State<HalamanKlasifikasi> createState() => _HalamanKlasifikasiState();
}

class _HalamanKlasifikasiState extends State<HalamanKlasifikasi> {
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
    setState(() {
      _foto = masalah == null ? File(berkas!.path) : null;
      _hasil = null;
      _galat = masalah;
    });
  }

  Future<void> _kirim() async {
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
    final hasil = _hasil;
    if (hasil != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(tooltip: 'Kembali', icon: const Icon(Icons.arrow_back), onPressed: _ulang),
          title: const Text('Hasil Klasifikasi'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TampilanHasil(riwayat: hasil, gambar: FileImage(_foto!)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: _ulang, child: const Text('Klasifikasi lagi'))),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      _ulang();
                      widget.onKeBeranda();
                    },
                    child: const Text('Ke beranda'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Klasifikasi Benih')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Isi petunjuk mengikuti protokol pengambilan citra (Tabel 3.2), karena model hanya
          // dilatih dengan foto seperti itu.
          const KotakCatatan(
            child: Text.rich(TextSpan(children: [
              TextSpan(text: 'Petunjuk: ', style: TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(
                  text: 'satu butir benih di atas alas hitam, foto tegak lurus dari atas, tanpa lampu kilat.'),
            ])),
          ),
          const SizedBox(height: 14),
          if (_galat != null) ...[
            PesanGalat(_galat!),
            const SizedBox(height: 14),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: _foto == null ? Warna.kertas : const Color(0xFF222222),
                  border: Border.all(color: Warna.garisTegas),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _foto == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined, size: 48, color: Warna.tintaLembut),
                          SizedBox(height: 8),
                          Text('Pratinjau citra benih', style: TextStyle(color: Warna.tintaLembut)),
                        ],
                      )
                    : Image.file(_foto!, fit: BoxFit.contain, semanticLabel: 'Foto benih yang dipilih'),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _memproses ? null : () => _pilih(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Kamera'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _memproses ? null : () => _pilih(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galeri'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _foto == null || _memproses ? null : _kirim,
            child: _memproses
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 10),
                      Text('Mengklasifikasi...'),
                    ],
                  )
                : const Text('Kirim dan klasifikasikan'),
          ),
          const SizedBox(height: 8),
          const Text('Format JPEG atau PNG, maksimal 10 MB',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Warna.tintaLembut)),
        ],
      ),
    );
  }
}
