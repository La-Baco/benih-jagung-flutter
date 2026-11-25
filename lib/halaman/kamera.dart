import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../layanan/api.dart';
import '../tema.dart';
import '../widget/kotak_objek.dart';

// Mode kamera: frame dikirim ke server satu per satu, lalu kotak setiap objek digambar
// di atas pratinjau. Ini perluasan di luar Batasan no. 4 (satu benih per citra), jadi
// ditandai sebagai mode percobaan.
class HalamanKamera extends StatefulWidget {
  const HalamanKamera({super.key, required this.api, required this.onSesiBerakhir});

  final Api api;
  final VoidCallback onSesiBerakhir;

  @override
  State<HalamanKamera> createState() => _HalamanKameraState();
}

class _HalamanKameraState extends State<HalamanKamera> with WidgetsBindingObserver {
  CameraController? _kamera;
  List<ObjekTerdeteksi> _benih = [];
  String? _galat;
  bool _jalan = true;
  bool _memindai = false;
  bool _siap = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _buka();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _jalan = false;
    _kamera?.dispose();
    super.dispose();
  }

  // Kamera dilepas saat aplikasi ke latar belakang, supaya aplikasi lain bisa memakainya.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _jalan = false;
      _kamera?.dispose();
      _kamera = null;
      if (mounted) setState(() => _siap = false);
    } else if (state == AppLifecycleState.resumed && _kamera == null) {
      _jalan = true;
      _buka();
    }
  }

  Future<void> _buka() async {
    try {
      final daftar = await availableCameras();
      final belakang = daftar.firstWhere((k) => k.lensDirection == CameraLensDirection.back, orElse: () => daftar.first);
      // 1920 px: pada uji 10_cek_mode_kamera.py kelasnya sama dengan foto penuh untuk 30/30 citra uji.
      final kamera = CameraController(belakang, ResolutionPreset.veryHigh, enableAudio: false);
      await kamera.initialize();
      await kamera.setFlashMode(FlashMode.off);
      if (!mounted) {
        kamera.dispose();
        return;
      }
      setState(() {
        _kamera = kamera;
        _siap = true;
        _galat = null;
      });
      _pindai();
    } on CameraException catch (e) {
      setState(() => _galat = e.code == 'CameraAccessDenied'
          ? 'Izin kamera ditolak. Izinkan kamera untuk aplikasi ini di pengaturan HP.'
          : 'Kamera tidak dapat dibuka.');
    } on StateError {
      setState(() => _galat = 'HP ini tidak memiliki kamera yang bisa dipakai.');
    }
  }

  // Satu frame dikirim setelah jawaban frame sebelumnya diterima, jadi permintaan tidak menumpuk
  // saat sinyal lambat.
  Future<void> _pindai() async {
    while (mounted && _jalan && _kamera != null && _kamera!.value.isInitialized) {
      if (_memindai) return;
      _memindai = true;
      try {
        final frame = await _kamera!.takePicture();
        final benih = await widget.api.deteksi(frame.path);
        File(frame.path).delete().ignore();
        if (!mounted || !_jalan) break;
        setState(() {
          _benih = benih;
          _galat = null;
        });
      } on GagalApi catch (e) {
        if (e.sesiBerakhir) {
          widget.onSesiBerakhir();
          return;
        }
        if (mounted) setState(() => _galat = e.pesan);
        await Future.delayed(const Duration(seconds: 2));
      } on CameraException {
        await Future.delayed(const Duration(milliseconds: 500));
      } finally {
        _memindai = false;
      }
    }
  }

  void _jedaAtauLanjut() {
    setState(() => _jalan = !_jalan);
    if (_jalan) _pindai();
  }

  @override
  Widget build(BuildContext context) {
    final kamera = _kamera;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: Warna.hijauMuda,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: const Text(
            'Mode percobaan. Letakkan benih di atas alas polos dan beri jarak antarbenih. '
            'Atur tinggi HP sampai satu benih kira-kira selebar sepertiga layar. '
            'Skor 0 sampai 1: 0,50 ke atas berarti layak. Kotak oranye: bukan jagung ketan putih.',
            style: TextStyle(fontSize: 13),
          ),
        ),
        Expanded(
          child: ColoredBox(
            color: Colors.black,
            child: Center(
              child: !_siap || kamera == null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: _galat != null
                          ? Text(_galat!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white))
                          : const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 12),
                                Text('Membuka kamera...', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                    )
                  : AspectRatio(
                      // Pratinjau kamera berbentuk lanskap; HP dipegang tegak, jadi rasionya dibalik.
                      aspectRatio: 1 / kamera.value.aspectRatio,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(kamera),
                          CustomPaint(painter: PelukisKotak(_benih, label: (o) => o.labelKamera)),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        Container(
          color: Warna.kertas,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(_status(), style: TextStyle(color: _galat != null && _siap ? Warna.galatTeks : Warna.tinta)),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _siap ? _jedaAtauLanjut : null,
                child: Text(_jalan ? 'Jeda' : 'Lanjutkan'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _status() {
    if (!_siap) return 'Kamera belum siap.';
    if (_galat != null) return _galat!;
    if (!_jalan) return 'Pemindaian dijeda.';
    if (_benih.isEmpty) return 'Belum ada objek terdeteksi.';
    final bukan = _benih.where((b) => b.bukan).length;
    final layak = _benih.where((b) => b.layak).length;
    final ketan = _benih.length - bukan;
    final teks = '$ketan benih: $layak layak, ${ketan - layak} tidak layak.';
    return bukan == 0 ? teks : '$teks $bukan objek bukan jagung ketan putih.';
  }
}
