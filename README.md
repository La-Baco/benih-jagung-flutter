# Cek Benih Jagung (aplikasi Android petani)

Aplikasi Flutter untuk petani. Isinya memeriksa kelayakan tanam benih jagung ketan putih dari foto, mode kamera langsung, dan riwayat. Klasifikasi dikerjakan server: aplikasi mengirim foto ke API Laravel, dan Laravel meneruskannya ke layanan Flask. Model tidak ada di HP. Model dilatih di perangkat pengembang (laptop peneliti), dan server hanya menjalankan prediksi.

- **Versi:** Flutter 3.47.5, Dart 3.13.4, Android 7.0 (API 24) ke atas
- **Paket:** `http`, `image_picker`, `camera`, dan `flutter_secure_storage`
- **APK siap pasang:** `Cek-Benih-Jagung.apk` di folder proyek

## Layar

| Layar | Isi |
|---|---|
| Masuk | Email dan kata sandi petani. Login cukup sekali, karena token disimpan di Android Keystore sampai menekan Keluar |
| Periksa | Ambil foto atau pilih dari galeri, pratinjau, lalu kirim. Hasil Layak/Tidak Layak, skor kepercayaan, dan batang skor |
| Kamera | Mode percobaan. Setiap benih di atas alas hitam diberi kotak dan skor 0-1 (0,50 ke atas = layak). Bisa dijeda. Hasil tidak disimpan |
| Riwayat | Daftar hasil pemeriksaan, tarik ke bawah untuk memuat ulang, ketuk satu baris untuk melihat fotonya |

Setiap layar yang memuat data punya keadaan memuat, kosong, dan galat. Bila token ditolak server, aplikasi kembali ke halaman masuk dengan pesan "Sesi berakhir".

## Struktur kode

| Berkas | Isi |
|---|---|
| `lib/main.dart` | Memuat token tersimpan, lalu membuka halaman masuk atau beranda |
| `lib/layanan/api.dart` | Pemanggil API (`/masuk`, `/klasifikasi`, `/deteksi`, `/riwayat`, `/keluar`), batas waktu, dan pesan galat |
| `lib/layanan/sesi.dart` | Simpan dan hapus token |
| `lib/halaman/masuk.dart` | Halaman masuk |
| `lib/halaman/beranda.dart` | Tab Periksa, Kamera, dan Riwayat, serta tombol Keluar |
| `lib/halaman/periksa.dart` | Pilih foto (diperkecil ke lebar 3.000 px, sama dengan lebar acuan prapemrosesan) dan kirim |
| `lib/halaman/kamera.dart` | Kamera langsung. Satu frame dikirim setelah jawaban frame sebelumnya diterima, jadi permintaan tidak menumpuk |
| `lib/halaman/riwayat.dart` | Daftar riwayat bertahap dan detail |
| `lib/widget/kartu_hasil.dart` | Kartu hasil klasifikasi |
| `lib/tema.dart` | Warna dan gaya yang sama dengan web (garis tegas 2 px, warna hasil hanya untuk kelas) |
| `assets/` | Logo jagung putih dan huruf Plus Jakarta Sans (lisensi OFL) |
| `android/` | Nama aplikasi, ikon adaptif, izin internet dan kamera (izin mikrofon dari plugin kamera dibuang) |
| `test/widget_test.dart` | Uji alur masuk, beranda, riwayat kosong, galat, dan sesi berakhir |

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
