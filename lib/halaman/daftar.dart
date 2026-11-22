import 'package:flutter/material.dart';

import '../layanan/api.dart';
import '../tema.dart';
import 'beranda.dart';

// Registrasi mandiri petani. Akun yang dibuat dari halaman ini selalu berperan petani.
class HalamanDaftar extends StatefulWidget {
  const HalamanDaftar({super.key, required this.api});

  final Api api;

  @override
  State<HalamanDaftar> createState() => _HalamanDaftarState();
}

class _HalamanDaftarState extends State<HalamanDaftar> {
  final _form = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _kataSandi = TextEditingController();
  final _konfirmasi = TextEditingController();
  bool _memproses = false;
  bool _sandiTerlihat = false;
  bool _konfirmasiTerlihat = false;
  String? _galat;

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _kataSandi.dispose();
    _konfirmasi.dispose();
    super.dispose();
  }

  Future<void> _daftar() async {
    // Pesan dari server sebelumnya dihapus dulu, supaya yang tampil hanya kesalahan isian saat ini.
    setState(() => _galat = null);
    if (!_form.currentState!.validate()) return;
    setState(() {
      _memproses = true;
      _galat = null;
    });
    try {
      await widget.api.daftar(_nama.text.trim(), _email.text.trim(), _kataSandi.text, _konfirmasi.text);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => HalamanBeranda(api: widget.api)), (_) => false);
    } on GagalApi catch (e) {
      setState(() {
        _galat = e.pesan;
        _memproses = false;
      });
    }
  }

  Widget _kolomSandi(TextEditingController kontrol, String label, bool terlihat, VoidCallback ubah,
      String? Function(String?) periksa) {
    return TextFormField(
      controller: kontrol,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          tooltip: terlihat ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi',
          icon: Icon(terlihat ? Icons.visibility_off_outlined : Icons.visibility_outlined),
          onPressed: ubah,
        ),
      ),
      obscureText: !terlihat,
      autofillHints: const [AutofillHints.newPassword],
      validator: periksa,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar akun petani')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Kotak(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_galat != null) ...[
                        PesanGalat(_galat!),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _nama,
                        decoration: const InputDecoration(labelText: 'Nama'),
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        textInputAction: TextInputAction.next,
                        validator: (isi) => (isi == null || isi.trim().isEmpty) ? 'Nama wajib diisi.' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        validator: (isi) => (isi == null || isi.trim().isEmpty) ? 'Email wajib diisi.' : null,
                      ),
                      const SizedBox(height: 14),
                      _kolomSandi(_kataSandi, 'Kata sandi', _sandiTerlihat,
                          () => setState(() => _sandiTerlihat = !_sandiTerlihat),
                          (isi) => (isi == null || isi.length < 8) ? 'Kata sandi minimal 8 karakter.' : null),
                      const SizedBox(height: 14),
                      _kolomSandi(_konfirmasi, 'Konfirmasi kata sandi', _konfirmasiTerlihat,
                          () => setState(() => _konfirmasiTerlihat = !_konfirmasiTerlihat),
                          (isi) => isi != _kataSandi.text ? 'Konfirmasi kata sandi tidak sama.' : null),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _memproses ? null : _daftar,
                        child: Text(_memproses ? 'Mendaftarkan akun...' : 'Daftar'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _memproses ? null : () => Navigator.of(context).pop(),
                        child: const Text('Sudah punya akun? Masuk'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
