import 'package:flutter/material.dart';

import 'halaman/utama.dart';
import 'halaman/masuk.dart';
import 'layanan/api.dart';
import 'layanan/sesi.dart';
import 'tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sesi = Sesi();
  await sesi.muat();
  runApp(AplikasiBenih(api: Api(sesi)));
}

class AplikasiBenih extends StatelessWidget {
  const AplikasiBenih({super.key, required this.api});

  final Api api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cek Benih Jagung',
      debugShowCheckedModeBanner: false,
      theme: buatTema(),
      // Token tersimpan berarti petani pernah masuk dan belum keluar: langsung ke beranda.
      home: api.sesi.masuk ? HalamanUtama(api: api) : HalamanMasuk(api: api),
    );
  }
}
