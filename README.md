# Cek Benih Jagung (aplikasi Android petani)

Aplikasi Flutter untuk petani. Isinya mengklasifikasi kelayakan tanam benih jagung ketan putih dari foto, riwayat, dan akun. Tampilannya mengikuti rancangan antarmuka Subbab 3.20.1 (Gambar 3.14-3.16). Klasifikasi dikerjakan server: aplikasi mengirim foto ke API Laravel, dan Laravel meneruskannya ke layanan Flask. Model tidak ada di HP. Model dilatih di perangkat pengembang (laptop peneliti), dan server hanya menjalankan prediksi.

- **Versi:** Flutter 3.47.5, Dart 3.13.4, Android 7.0 (API 24) ke atas
- **Paket:** `http`, `image_picker`, dan `flutter_secure_storage`
- **Server:** API `https://api.skripsi-danur.synvorateknologiindonesia.web.id/api`
- **Unduh APK:** halaman [Releases](https://github.com/La-Baco/benih-jagung-flutter/releases/latest) (versi 27 November 2026: tampilan sesuai rancangan, tanpa mode kamera langsung)

## Layar

| Layar | Isi |
|---|---|
| Masuk | Email dan kata sandi petani. Login cukup sekali, karena token disimpan di Android Keystore sampai menekan Keluar. Akun admin ditolak, karena admin memakai website |
| Daftar | Registrasi mandiri petani: nama, email, kata sandi, dan konfirmasi. Setelah berhasil langsung masuk ke beranda |
| Lupa kata sandi | Mengirim tautan atur ulang ke email terdaftar. Kata sandi baru diatur di halaman website |
| Beranda | Gambar 3.15a: sapaan, jumlah klasifikasi, jumlah Layak dan Tidak Layak, tombol Klasifikasi benih, dan tiga klasifikasi terakhir |
| Klasifikasi Benih | Gambar 3.15b: petunjuk pemotretan (Tabel 3.2), pratinjau citra, tombol Kamera dan Galeri, lalu Kirim dan klasifikasikan. Format (JPEG/PNG) dan ukuran (maksimal 10 MB) diperiksa sebelum dikirim. Foto yang tidak berisi biji jagung ditolak server dengan pesan |
| Hasil Klasifikasi | Gambar 3.15c: citra dengan bounding box, kelas Layak atau Tidak Layak, skor kepercayaan dan batangnya, keterangan uji daya berkecambah, tombol Klasifikasi lagi dan Ke beranda |
| Riwayat Klasifikasi | Gambar 3.16a: daftar hasil milik petani (citra, lencana kelas, skor, waktu), tarik ke bawah untuk memuat ulang, ketuk untuk detail |
| Akun | Gambar 3.16b: nama, email, peran Petani, ringkasan jumlah klasifikasi dan tanggal bergabung, tombol Logout |

Mode kamera langsung dihapus (27 November 2026): frame dikirim terus-menerus, sehingga kuota validasi objek Gemini di server akan cepat habis.

Setiap layar yang memuat data punya keadaan memuat, kosong, dan galat. Bila token ditolak server, aplikasi kembali ke halaman masuk dengan pesan "Sesi berakhir".

## Struktur kode

| Berkas | Isi |
|---|---|
| `lib/main.dart` | Memuat token tersimpan, lalu membuka halaman masuk atau halaman utama |
| `lib/layanan/api.dart` | Pemanggil API (`/login`, `/register`, `/lupa-sandi`, `/klasifikasi`, `/riwayat`, `/logout`), batas waktu, dan pesan galat |
| `lib/layanan/sesi.dart` | Simpan dan hapus token |
| `lib/halaman/masuk.dart` | Halaman masuk, dengan tautan ke Daftar dan Lupa kata sandi |
| `lib/halaman/daftar.dart` | Registrasi petani |
| `lib/halaman/lupa_sandi.dart` | Permintaan tautan atur ulang kata sandi |
| `lib/halaman/utama.dart` | Menu bawah Beranda, Klasifikasi, Riwayat, Akun |
| `lib/halaman/beranda.dart` | Beranda dengan ringkasan dan klasifikasi terakhir |
| `lib/halaman/klasifikasi.dart` | Pilih foto dan kirim, lalu halaman hasil. Foto kamera diperkecil ke lebar 3.000 px (lebar acuan prapemrosesan); foto galeri dikirim apa adanya setelah format dan ukurannya diperiksa |
| `lib/halaman/akun.dart` | Data akun, ringkasan, dan logout |
| `lib/halaman/riwayat.dart` | Daftar riwayat bertahap dan detail |
| `lib/widget/kartu_hasil.dart` | Isi halaman Hasil Klasifikasi |
| `lib/widget/kotak_objek.dart` | Penggambar bounding box (dipakai halaman hasil); rasio foto dibaca dulu supaya kotak tepat di atas objek |
| `lib/tema.dart` | Warna dan gaya yang sama dengan web (garis tegas 2 px, warna hasil hanya untuk kelas: hijau Layak, merah Tidak Layak, cokelat Bukan Jagung Ketan Putih) |
| `assets/` | Logo jagung putih dan huruf Plus Jakarta Sans (lisensi OFL) |
| `android/` | Nama aplikasi, ikon adaptif, izin internet dan kamera (izin mikrofon dari plugin kamera dibuang) |
| `test/widget_test.dart` | 14 uji: masuk, beranda dan ringkasan, akun, menu bawah tanpa kamera langsung, riwayat kosong, galat, sesi berakhir, ikon mata, registrasi, lupa kata sandi, pemeriksaan format/ukuran citra, dan pembacaan riwayat lama beserta bounding box |

## Membangun dan menguji

```
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Hasilnya ada di `build/app/outputs/flutter-apk/app-release.apk`. Untuk mencoba dengan Laravel di laptop:

```
flutter run --dart-define=API_URL=http://<IP-laptop>:8000/api
```

APK ditandatangani dengan kunci debug karena dibagikan langsung, bukan lewat Play Store. APK dari laptop lain tidak bisa menimpa aplikasi yang sudah terpasang, jadi hapus aplikasi lama lebih dulu.
