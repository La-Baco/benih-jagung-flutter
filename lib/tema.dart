import 'package:flutter/material.dart';

// Warna sama dengan aplikasi web (public/css/app.css), alasan pemilihannya ada di
// PLANNING_SISTEM.md bagian 4.4. Tema terang saja, karena HP dipakai di lahan saat siang.
class Warna {
  static const tinta = Color(0xFF1F2A1F);
  static const tintaLembut = Color(0xFF59614F);
  static const latar = Color(0xFFF3F4EF);
  static const kertas = Color(0xFFFFFFFF);
  static const garis = Color(0xFFD8DBD0);
  static const garisTegas = Color(0xFFA9AE9F);
  static const hijau = Color(0xFF2F6B3A);
  static const hijauMuda = Color(0xFFEEF1E8);
  static const hasilLayak = Color(0xFF1F7A33);
  static const hasilTidakLayak = Color(0xFFB3261E);
  static const galatTeks = Color(0xFF8C1D18);
  static const galatLatar = Color(0xFFFBECEB);
  static const batangLatar = Color(0xFFE4E7DC);
}

ThemeData buatTema() {
  final dasar = ThemeData(
    useMaterial3: true,
    fontFamily: 'PlusJakartaSans',
    colorScheme: ColorScheme.fromSeed(
      seedColor: Warna.hijau,
      primary: Warna.hijau,
      onPrimary: Colors.white,
      surface: Warna.latar,
      onSurface: Warna.tinta,
      error: Warna.hasilTidakLayak,
    ),
    scaffoldBackgroundColor: Warna.latar,
  );

  final sudut = RoundedRectangleBorder(borderRadius: BorderRadius.circular(6));

  return dasar.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: Warna.kertas,
      foregroundColor: Warna.tinta,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Warna.tinta,
      ),
      // Garis tegas di bawah judul: motif yang sama dengan halaman web.
      shape: Border(bottom: BorderSide(color: Warna.tinta, width: 2)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      // Saat memproses, tombol tetap terbaca (putih di atas abu kehijauan, 5,5:1) seperti .tombol:disabled di web.
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        disabledBackgroundColor: const Color(0xFF5F6D61),
        disabledForegroundColor: Colors.white,
        shape: sudut,
        textStyle: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        foregroundColor: Warna.tinta,
        side: const BorderSide(color: Warna.tinta),
        shape: sudut,
        textStyle: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: Warna.tinta,
        textStyle: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Warna.kertas,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Warna.garisTegas),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Warna.tinta, width: 2),
      ),
      labelStyle: const TextStyle(color: Warna.tintaLembut),
      floatingLabelStyle: const TextStyle(color: Warna.tinta, fontWeight: FontWeight.w600),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Warna.kertas,
      indicatorColor: Warna.hijauMuda,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (state) => TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 13,
          color: Warna.tinta,
          fontWeight: state.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: Warna.hijau),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

// Kotak putih bergaris tipis, padanan .kotak di CSS web.
class Kotak extends StatelessWidget {
  const Kotak({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Warna.kertas,
        border: Border.all(color: Warna.garis),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class PesanGalat extends StatelessWidget {
  const PesanGalat(this.pesan, {super.key});

  final String pesan;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Warna.galatLatar,
          border: Border.all(color: const Color(0xFFEFB8B3)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(pesan, style: const TextStyle(color: Warna.galatTeks)),
      ),
    );
  }
}
