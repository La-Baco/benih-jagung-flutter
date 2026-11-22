import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Token disimpan sampai petani menekan Keluar, jadi login cukup sekali.
class Sesi {
  Sesi({FlutterSecureStorage? penyimpanan}) : _penyimpanan = penyimpanan ?? const FlutterSecureStorage();

  final FlutterSecureStorage _penyimpanan;

  String? token;
  String? nama;
  String? email;

  bool get masuk => token != null;

  Future<void> muat() async {
    token = await _penyimpanan.read(key: 'token');
    nama = await _penyimpanan.read(key: 'nama');
    email = await _penyimpanan.read(key: 'email');
  }

  Future<void> simpan(String tokenBaru, String namaBaru, String emailBaru) async {
    await _penyimpanan.write(key: 'token', value: tokenBaru);
    await _penyimpanan.write(key: 'nama', value: namaBaru);
    await _penyimpanan.write(key: 'email', value: emailBaru);
    token = tokenBaru;
    nama = namaBaru;
    email = emailBaru;
  }

  Future<void> hapus() async {
    await _penyimpanan.deleteAll();
    token = null;
    nama = null;
    email = null;
  }
}
