import 'dart:convert';

import 'dart:io';

import 'package:benih_jagung/halaman/klasifikasi.dart';
import 'package:benih_jagung/layanan/api.dart';
import 'package:benih_jagung/layanan/sesi.dart';
import 'package:benih_jagung/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Server Laravel diganti MockClient, jadi tes ini menguji tampilan dan alur, bukan model.
http.Response json(Object isi, int kode) =>
    http.Response(jsonEncode(isi), kode, headers: {'content-type': 'application/json'});

Future<Api> buatApi(MockClient klien, {Map<String, String> tersimpan = const {}}) async {
  FlutterSecureStorage.setMockInitialValues(Map.of(tersimpan));
  final sesi = Sesi();
  await sesi.muat();
  return Api(sesi, klien: klien);
}

void main() {
  testWidgets('tanpa token, aplikasi membuka halaman masuk dan memvalidasi isian kosong', (tester) async {
    final api = await buatApi(MockClient((_) async => json({}, 500)));
    await tester.pumpWidget(AplikasiBenih(api: api));

    expect(find.widgetWithText(FilledButton, 'Masuk'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pump();

    expect(find.text('Email wajib diisi.'), findsOneWidget);
    expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);
  });

  testWidgets('kata sandi salah menampilkan pesan dari server', (tester) async {
    final api = await buatApi(MockClient((_) async => json({'message': 'Login gagal. Email atau kata sandi salah.'}, 401)));
    await tester.pumpWidget(AplikasiBenih(api: api));

    await tester.enterText(find.byType(TextFormField).at(0), 'petani@benih.test');
    await tester.enterText(find.byType(TextFormField).at(1), 'salah');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Login gagal. Email atau kata sandi salah.'), findsOneWidget);
  });

  testWidgets('login berhasil membuka beranda dan menyimpan token', (tester) async {
    final api = await buatApi(MockClient((permintaan) async {
      if (permintaan.url.path.endsWith('/login')) {
        return json({'token': '1|abc', 'pengguna': {'id': 2, 'nama': 'Petani Contoh', 'email': 'petani@benih.test'}}, 200);
      }
      return json({'data': [], 'halaman': 1, 'halaman_terakhir': 1, 'total': 0}, 200);
    }));
    await tester.pumpWidget(AplikasiBenih(api: api));

    await tester.enterText(find.byType(TextFormField).at(0), 'petani@benih.test');
    await tester.enterText(find.byType(TextFormField).at(1), '12345678');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Petani Contoh'), findsOneWidget);
    expect(find.text('Klasifikasi benih'), findsOneWidget);
    expect(api.sesi.token, '1|abc');
  });

  testWidgets('token tersimpan langsung membuka beranda, riwayat kosong punya keterangan', (tester) async {
    final api = await buatApi(
      MockClient((_) async => json({'data': [], 'halaman': 1, 'halaman_terakhir': 1, 'total': 0}, 200)),
      tersimpan: {'token': '1|abc', 'nama': 'Petani Contoh', 'email': 'petani@benih.test'},
    );
    await tester.pumpWidget(AplikasiBenih(api: api));
    await tester.pumpAndSettle();
    expect(find.text('Petani Contoh'), findsOneWidget);
    expect(find.text('Jumlah klasifikasi'), findsOneWidget);

    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Belum ada riwayat'), findsOneWidget);
  });

  testWidgets('riwayat gagal dimuat menampilkan pesan dan tombol coba lagi', (tester) async {
    final api = await buatApi(
      MockClient((_) async => json({'message': 'Server sedang sibuk.'}, 503)),
      tersimpan: {'token': '1|abc', 'nama': 'Petani Contoh', 'email': 'petani@benih.test'},
    );
    await tester.pumpWidget(AplikasiBenih(api: api));
    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();

    expect(find.text('Server sedang sibuk.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('token ditolak server mengembalikan petani ke halaman masuk', (tester) async {
    final api = await buatApi(
      MockClient((_) async => json({'message': 'Sesi berakhir. Silakan masuk lagi.'}, 401)),
      tersimpan: {'token': '1|lama', 'nama': 'Petani Contoh', 'email': 'petani@benih.test'},
    );
    await tester.pumpWidget(AplikasiBenih(api: api));
    await tester.pumpAndSettle();

    expect(find.text('Sesi berakhir. Silakan masuk lagi.'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(api.sesi.token, isNull);
  });

  testWidgets('ikon mata menampilkan dan menyembunyikan kata sandi bergantian', (tester) async {
    final api = await buatApi(MockClient((_) async => json({}, 500)));
    await tester.pumpWidget(AplikasiBenih(api: api));

    EditableText kolomSandi() => tester.widget<EditableText>(find.byType(EditableText).at(1));
    expect(kolomSandi().obscureText, isTrue);
    await tester.tap(find.byTooltip('Tampilkan kata sandi'));
    await tester.pump();
    expect(kolomSandi().obscureText, isFalse);
    await tester.tap(find.byTooltip('Sembunyikan kata sandi'));
    await tester.pump();
    expect(kolomSandi().obscureText, isTrue);
  });

  testWidgets('registrasi berhasil langsung membuka beranda', (tester) async {
    Map<String, String>? dikirim;
    final api = await buatApi(MockClient((permintaan) async {
      if (permintaan.url.path.endsWith('/register')) {
        dikirim = Uri.splitQueryString(permintaan.body);
        return json({'token': '2|baru', 'pengguna': {'id': 3, 'nama': 'Petani Baru', 'email': 'baru@benih.test'}}, 201);
      }
      return json({'data': [], 'halaman': 1, 'halaman_terakhir': 1, 'total': 0}, 200);
    }));
    await tester.pumpWidget(AplikasiBenih(api: api));
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Petani Baru');
    await tester.enterText(find.byType(TextFormField).at(1), 'baru@benih.test');
    await tester.enterText(find.byType(TextFormField).at(2), 'rahasia123');
    await tester.enterText(find.byType(TextFormField).at(3), 'rahasia123');
    await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
    await tester.pumpAndSettle();

    expect(dikirim?['password_confirmation'], 'rahasia123');
    expect(find.text('Petani Baru'), findsOneWidget);
    expect(api.sesi.token, '2|baru');
  });

  testWidgets('registrasi menampilkan pesan email terdaftar dan konfirmasi berbeda', (tester) async {
    final api = await buatApi(MockClient((_) async => json({
          'message': 'Email sudah terdaftar.',
          'errors': {'email': ['Email sudah terdaftar.']},
        }, 422)));
    await tester.pumpWidget(AplikasiBenih(api: api));
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Petani');
    await tester.enterText(find.byType(TextFormField).at(1), 'ada@benih.test');
    await tester.enterText(find.byType(TextFormField).at(2), 'rahasia123');
    await tester.enterText(find.byType(TextFormField).at(3), 'beda12345');
    await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
    await tester.pump();
    expect(find.text('Konfirmasi kata sandi tidak sama.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(3), 'rahasia123');
    await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
    await tester.pumpAndSettle();
    expect(find.text('Email sudah terdaftar.'), findsOneWidget);
  });

  testWidgets('lupa kata sandi menampilkan pesan terkirim dan pesan email tidak terdaftar', (tester) async {
    final api = await buatApi(MockClient((permintaan) async {
      final email = Uri.splitQueryString(permintaan.body)['email'];
      return email == 'petani@benih.test'
          ? json({'message': 'Tautan atur ulang kata sandi sudah dikirim ke email Anda.'}, 200)
          : json({'message': 'Email tidak terdaftar.'}, 422);
    }));
    await tester.pumpWidget(AplikasiBenih(api: api));
    await tester.tap(find.text('Lupa kata sandi?'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'petani@benih.test');
    await tester.tap(find.text('Kirim tautan'));
    await tester.pumpAndSettle();
    expect(find.text('Tautan atur ulang kata sandi sudah dikirim ke email Anda.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'asing@benih.test');
    await tester.tap(find.text('Kirim tautan'));
    await tester.pumpAndSettle();
    expect(find.text('Email tidak terdaftar.'), findsOneWidget);
  });

  test('pemeriksaan berkas citra menolak format lain dan ukuran di atas 10 MB', () async {
    final folder = await Directory.systemTemp.createTemp('citra');
    Future<File> tulis(String nama, List<int> isi) => File('${folder.path}/$nama').writeAsBytes(isi);

    expect(await periksaBerkasCitra(await tulis('a.jpg', [0xFF, 0xD8, 0xFF, 0xE0, 1, 2])), isNull);
    expect(await periksaBerkasCitra(await tulis('b.png', [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A])), isNull);
    expect(await periksaBerkasCitra(await tulis('c.webp', 'RIFF0000WEBP'.codeUnits)),
        'Citra tidak valid. Pilih citra berformat JPEG atau PNG.');
    final besar = List<int>.filled(batasUkuranCitra + 1, 0)..setAll(0, [0xFF, 0xD8, 0xFF]);
    expect(await periksaBerkasCitra(await tulis('d.jpg', besar)), 'Citra tidak valid. Ukuran citra maksimal 10 MB.');
    await folder.delete(recursive: true);
  });

  test('riwayat lama "Bukan Jagung Ketan Putih" tetap terbaca beserta bounding box-nya', () {
    final riwayat = Riwayat.dariJson({
      'id': 7,
      'hasil_prediksi': 'Bukan Jagung Ketan Putih',
      'skor_kepercayaan': 99.12,
      'waktu': '2026-11-25T10:00:00+07:00',
      'url_gambar': 'https://contoh.test/gambar/7',
      'objek': [
        {'x': 0.31, 'y': 0.3, 'w': 0.35, 'h': 0.33, 'prediksi': 'Bukan Jagung Ketan Putih', 'skor_kepercayaan': 99.12},
      ],
    });
    expect(riwayat.bukan, isTrue);
    expect(riwayat.layak, isFalse);
    expect(riwayat.objek.single.x, 0.31);

    // Riwayat lama (sebelum tahap penyaring) tidak punya kolom objek.
    final lama = Riwayat.dariJson({
      'id': 1, 'hasil_prediksi': 'Layak', 'skor_kepercayaan': 97.3,
      'waktu': '2026-11-20T10:00:00+07:00', 'url_gambar': 'https://contoh.test/gambar/1',
    });
    expect(lama.objek, isEmpty);

    final benih = ObjekTerdeteksi.dariJson(
        {'x': 0.1, 'y': 0.1, 'w': 0.2, 'h': 0.2, 'prediksi': 'Tidak Layak', 'skor_kepercayaan': 50.01, 'peluang_layak': 0.4999});
    expect(benih.layak, isFalse);
    expect(benih.peluangLayak, 0.4999);
  });

  testWidgets('beranda menampilkan jumlah klasifikasi, layak, tidak layak, dan riwayat terakhir', (tester) async {
    final api = await buatApi(
      MockClient((_) async => json({
            'data': [
              {'id': 5, 'hasil_prediksi': 'Layak', 'skor_kepercayaan': 99.5, 'waktu': '2026-11-27T10:00:00+07:00',
               'url_gambar': 'https://contoh.test/gambar/5', 'objek': []},
            ],
            'halaman': 1, 'halaman_terakhir': 1, 'total': 3,
            'ringkasan': {'layak': 2, 'tidak_layak': 1, 'bergabung': '2026-11-20T08:00:00+07:00'},
          }, 200)),
      tersimpan: {'token': '1|abc', 'nama': 'Petani Contoh', 'email': 'petani@benih.test'},
    );
    await tester.pumpWidget(AplikasiBenih(api: api));
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Klasifikasi terakhir'), findsOneWidget);
    expect(find.text('Skor kepercayaan: '), findsNothing);
    expect(find.text('Layak'), findsWidgets);

    await tester.tap(find.text('Akun'));
    await tester.pumpAndSettle();
    expect(find.text('petani@benih.test'), findsOneWidget);
    expect(find.text('20 Nov 2026'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('menu bawah sesuai rancangan dan tidak ada lagi mode kamera langsung', (tester) async {
    final api = await buatApi(
      MockClient((_) async => json({'data': [], 'halaman': 1, 'halaman_terakhir': 1, 'total': 0}, 200)),
      tersimpan: {'token': '1|abc', 'nama': 'Petani Contoh', 'email': 'petani@benih.test'},
    );
    await tester.pumpWidget(AplikasiBenih(api: api));
    await tester.pumpAndSettle();

    for (final menu in ['Beranda', 'Klasifikasi', 'Riwayat', 'Akun']) {
      expect(find.widgetWithText(NavigationDestination, menu), findsOneWidget);
    }
    expect(find.textContaining('Kamera Langsung'), findsNothing);

    await tester.tap(find.widgetWithText(NavigationDestination, 'Klasifikasi'));
    await tester.pumpAndSettle();
    expect(find.text('Klasifikasi Benih'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Format JPEG atau PNG, maksimal 10 MB'), 200);
    expect(find.text('Format JPEG atau PNG, maksimal 10 MB'), findsOneWidget);
    // Tombol kirim baru aktif setelah citra dipilih.
    final kirim = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Kirim dan klasifikasikan'));
    expect(kirim.onPressed, isNull);
  });
}
