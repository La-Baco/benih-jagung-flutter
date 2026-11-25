import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'sesi.dart';

// Alamat bisa diganti saat build, misalnya untuk server di laptop:
// flutter run --dart-define=API_URL=http://192.168.1.10:8000/api
const alamatApi = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://api.skripsi-danur.synvorateknologiindonesia.web.id/api',
);

class GagalApi implements Exception {
  GagalApi(this.pesan, {this.kode = 0});

  final String pesan;
  final int kode;

  bool get sesiBerakhir => kode == 401;

  @override
  String toString() => pesan;
}

class Pengguna {
  Pengguna(this.nama, this.email);

  final String nama;
  final String email;
}

// Hasil untuk objek yang ditolak tahap penyaring (misalnya kerikil atau biji lain).
const hasilBukan = 'Bukan Jagung Ketan Putih';

class Riwayat {
  Riwayat.dariJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        hasil = json['hasil_prediksi'] as String,
        skor = (json['skor_kepercayaan'] as num).toDouble(),
        waktu = DateTime.parse(json['waktu'] as String).toLocal(),
        urlGambar = json['url_gambar'] as String,
        objek = ((json['objek'] as List?) ?? [])
            .map((e) => ObjekTerdeteksi.dariJson(e as Map<String, dynamic>))
            .toList();

  final int id;
  final String hasil;
  final double skor;
  final DateTime waktu;
  final String urlGambar;
  // Bounding box setiap objek di foto (kosong untuk riwayat sebelum tahap penyaring ada).
  final List<ObjekTerdeteksi> objek;

  bool get layak => hasil == 'Layak';
  bool get bukan => hasil == hasilBukan;
}

// Satu objek hasil deteksi (foto atau frame kamera). Koordinat 0-1 terhadap lebar dan tinggi citra.
class ObjekTerdeteksi {
  ObjekTerdeteksi.dariJson(Map<String, dynamic> json)
      : x = (json['x'] as num).toDouble(),
        y = (json['y'] as num).toDouble(),
        w = (json['w'] as num).toDouble(),
        h = (json['h'] as num).toDouble(),
        prediksi = json['prediksi'] as String,
        skor = (json['skor_kepercayaan'] as num).toDouble(),
        peluangLayak = (json['peluang_layak'] as num?)?.toDouble();

  final double x;
  final double y;
  final double w;
  final double h;
  final String prediksi;
  final double skor;
  // Kosong bila objek bukan jagung ketan putih (kelayakannya tidak dinilai).
  final double? peluangLayak;

  bool get layak => prediksi == 'Layak';
  bool get bukan => prediksi == hasilBukan;

  // Mode kamera menampilkan peluang layak 0-1, dipotong ke bawah, jadi 0,4999 tampil 0,49
  // dan tidak terlihat seperti ambang 0,50.
  String get labelKamera {
    final p = peluangLayak;
    if (bukan || p == null) return 'Bukan ketan putih';
    return '${((p * 100).floor() / 100).toStringAsFixed(2).replaceAll('.', ',')} $prediksi';
  }
}

class DaftarRiwayat {
  DaftarRiwayat(this.isi, this.halaman, this.halamanTerakhir, this.total);

  final List<Riwayat> isi;
  final int halaman;
  final int halamanTerakhir;
  final int total;
}

class Api {
  Api(this.sesi, {http.Client? klien}) : _klien = klien ?? http.Client();

  final Sesi sesi;
  final http.Client _klien;

  Map<String, String> get headerToken => {
        'Accept': 'application/json',
        if (sesi.token != null) 'Authorization': 'Bearer ${sesi.token}',
      };

  // Alamat /register, /login, /lupa-sandi, dan /logout mengikuti Tabel REST API di BAB III.
  Future<Pengguna> masuk(String email, String kataSandi) async {
    final data = await _kirim(() => _klien.post(
          Uri.parse('$alamatApi/login'),
          headers: {'Accept': 'application/json'},
          body: {'email': email, 'password': kataSandi, 'perangkat': 'aplikasi-android'},
        ));
    return _simpanSesi(data);
  }

  // Akun dari registrasi selalu berperan petani, lalu langsung masuk.
  Future<Pengguna> daftar(String nama, String email, String kataSandi, String konfirmasi) async {
    final data = await _kirim(() => _klien.post(
          Uri.parse('$alamatApi/register'),
          headers: {'Accept': 'application/json'},
          body: {
            'nama': nama,
            'email': email,
            'password': kataSandi,
            'password_confirmation': konfirmasi,
            'perangkat': 'aplikasi-android',
          },
        ));
    return _simpanSesi(data);
  }

  // Server mengirim tautan atur ulang ke email; halamannya dibuka di browser.
  Future<String> lupaSandi(String email) async {
    final data = await _kirim(() => _klien.post(
          Uri.parse('$alamatApi/lupa-sandi'),
          headers: {'Accept': 'application/json'},
          body: {'email': email},
        ));
    return data['message'] as String;
  }

  Future<Pengguna> _simpanSesi(Map<String, dynamic> data) async {
    final pengguna = data['pengguna'] as Map<String, dynamic>;
    await sesi.simpan(data['token'] as String, pengguna['nama'] as String, pengguna['email'] as String);
    return Pengguna(pengguna['nama'] as String, pengguna['email'] as String);
  }

  Future<void> keluar() async {
    try {
      await _kirim(() => _klien.post(Uri.parse('$alamatApi/logout'), headers: headerToken));
    } on GagalApi {
      // Token di HP tetap dihapus walau server tidak terjangkau, supaya petani bisa keluar.
    }
    await sesi.hapus();
  }

  Future<Riwayat> klasifikasi(File foto) async {
    final permintaan = http.MultipartRequest('POST', Uri.parse('$alamatApi/klasifikasi'))
      ..headers.addAll(headerToken)
      ..files.add(await http.MultipartFile.fromPath('gambar', foto.path));
    final data = await _kirim(() async => http.Response.fromStream(await _klien.send(permintaan)),
        batasWaktu: const Duration(seconds: 90));
    return Riwayat.dariJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<ObjekTerdeteksi>> deteksi(String pathFrame) async {
    final permintaan = http.MultipartRequest('POST', Uri.parse('$alamatApi/deteksi'))
      ..headers.addAll(headerToken)
      ..files.add(await http.MultipartFile.fromPath('frame', pathFrame));
    final data = await _kirim(() async => http.Response.fromStream(await _klien.send(permintaan)),
        batasWaktu: const Duration(seconds: 20));
    return (data['benih'] as List).map((e) => ObjekTerdeteksi.dariJson(e as Map<String, dynamic>)).toList();
  }

  Future<DaftarRiwayat> riwayat({int halaman = 1}) async {
    final data = await _kirim(
        () => _klien.get(Uri.parse('$alamatApi/riwayat?page=$halaman'), headers: headerToken));
    final isi = (data['data'] as List).map((e) => Riwayat.dariJson(e as Map<String, dynamic>)).toList();
    return DaftarRiwayat(isi, data['halaman'] as int, data['halaman_terakhir'] as int, data['total'] as int);
  }

  Future<Map<String, dynamic>> _kirim(Future<http.Response> Function() aksi,
      {Duration batasWaktu = const Duration(seconds: 20)}) async {
    final http.Response respon;
    try {
      respon = await aksi().timeout(batasWaktu);
    } on SocketException {
      throw GagalApi('Tidak ada koneksi internet. Periksa sinyal lalu coba lagi.');
    } on TimeoutException {
      throw GagalApi('Server terlalu lama menjawab. Coba lagi beberapa saat.');
    } on http.ClientException {
      throw GagalApi('Tidak dapat terhubung ke server. Coba lagi beberapa saat.');
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(respon.body) as Map<String, dynamic>;
    } on FormatException {
      throw GagalApi('Server mengalami gangguan (kode ${respon.statusCode}).', kode: respon.statusCode);
    }

    if (respon.statusCode >= 200 && respon.statusCode < 300) {
      return data;
    }
    if (respon.statusCode == 401 && sesi.token != null) {
      await sesi.hapus();
    }

    // Galat validasi Laravel berisi daftar pesan per kolom; yang pertama paling relevan.
    final galat = data['errors'];
    if (galat is Map && galat.isNotEmpty) {
      throw GagalApi((galat.values.first as List).first as String, kode: respon.statusCode);
    }
    throw GagalApi(data['message'] as String? ?? 'Terjadi kesalahan (kode ${respon.statusCode}).',
        kode: respon.statusCode);
  }
}
