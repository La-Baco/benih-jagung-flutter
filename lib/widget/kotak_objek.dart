import 'package:flutter/material.dart';

import '../layanan/api.dart';
import '../tema.dart';

// Menggambar bounding box setiap objek. Ukuran kanvas harus sama persis dengan citra
// yang ditampilkan, karena koordinat objek berupa pecahan 0-1 dari lebar dan tinggi citra.
class PelukisKotak extends CustomPainter {
  PelukisKotak(this.objek, {this.label});

  final List<ObjekTerdeteksi> objek;
  // Teks label tiap kotak; null berarti kotak tanpa label.
  final String Function(ObjekTerdeteksi)? label;

  @override
  void paint(Canvas canvas, Size ukuran) {
    for (final o in objek) {
      final warna = warnaHasil(o.prediksi);
      final kotak = Rect.fromLTWH(o.x * ukuran.width, o.y * ukuran.height, o.w * ukuran.width, o.h * ukuran.height);
      canvas.drawRect(
        kotak,
        Paint()
          ..color = warna
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      final teksLabel = label?.call(o);
      if (teksLabel == null) continue;

      // Teks putih di atas warna hasil (kontras 5,4:1, 6,5:1, dan 6,8:1).
      final teks = TextPainter(
        text: TextSpan(
          text: teksLabel,
          style: const TextStyle(fontFamily: 'PlusJakartaSans', color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: ukuran.width - 10);
      final atas = (kotak.top - teks.height - 6).clamp(0.0, ukuran.height - teks.height - 6);
      final kiri = kotak.left.clamp(0.0, ukuran.width - teks.width - 10);
      final kotakLabel = Rect.fromLTWH(kiri, atas, teks.width + 10, teks.height + 6);
      canvas.drawRect(kotakLabel, Paint()..color = warna);
      teks.paint(canvas, Offset(kotakLabel.left + 5, kotakLabel.top + 3));
    }
  }

  @override
  bool shouldRepaint(PelukisKotak lama) => lama.objek != objek;
}

// Foto dengan bounding box. Rasio foto dibaca dulu dari berkasnya, supaya kotak tepat
// berada di atas objek walaupun fotonya tidak persegi.
class GambarBerkotak extends StatefulWidget {
  const GambarBerkotak({super.key, required this.gambar, required this.objek, required this.keterangan});

  final ImageProvider gambar;
  final List<ObjekTerdeteksi> objek;
  final String keterangan;

  @override
  State<GambarBerkotak> createState() => _GambarBerkotakState();
}

class _GambarBerkotakState extends State<GambarBerkotak> {
  ImageStream? _aliran;
  ImageStreamListener? _pendengar;
  double? _rasio;
  bool _gagal = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _baca();
  }

  @override
  void didUpdateWidget(GambarBerkotak lama) {
    super.didUpdateWidget(lama);
    if (lama.gambar != widget.gambar) _baca();
  }

  void _baca() {
    _lepas();
    final aliran = widget.gambar.resolve(createLocalImageConfiguration(context));
    final pendengar = ImageStreamListener(
      (info, _) {
        if (mounted) setState(() => _rasio = info.image.width / info.image.height);
      },
      onError: (_, _) {
        if (mounted) setState(() => _gagal = true);
      },
    );
    aliran.addListener(pendengar);
    _aliran = aliran;
    _pendengar = pendengar;
  }

  void _lepas() {
    final pendengar = _pendengar;
    if (pendengar != null) _aliran?.removeListener(pendengar);
  }

  @override
  void dispose() {
    _lepas();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gagal) {
      return const AspectRatio(
        aspectRatio: 1,
        child: ColoredBox(
          color: Color(0xFF222222),
          child: Center(child: Icon(Icons.broken_image_outlined, color: Colors.white70, semanticLabel: 'Foto tidak dapat dimuat')),
        ),
      );
    }
    final rasio = _rasio;
    if (rasio == null) {
      return const AspectRatio(
        aspectRatio: 1,
        child: ColoredBox(color: Color(0xFF222222), child: Center(child: CircularProgressIndicator(color: Colors.white))),
      );
    }
    return AspectRatio(
      aspectRatio: rasio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(image: widget.gambar, fit: BoxFit.fill, semanticLabel: widget.keterangan),
          CustomPaint(painter: PelukisKotak(widget.objek, label: (o) => o.prediksi)),
        ],
      ),
    );
  }
}
