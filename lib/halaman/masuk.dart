import 'package:flutter/material.dart';

import '../layanan/api.dart';
import '../tema.dart';
import 'daftar.dart';
import 'lupa_sandi.dart';
import 'utama.dart';

class HalamanMasuk extends StatefulWidget {
  const HalamanMasuk({super.key, required this.api, this.pesanAwal});

  final Api api;
  final String? pesanAwal;

  @override
  State<HalamanMasuk> createState() => _HalamanMasukState();
}

class _HalamanMasukState extends State<HalamanMasuk> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _kataSandi = TextEditingController();
  bool _memproses = false;
  bool _sandiTerlihat = false;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _galat = widget.pesanAwal;
  }

  @override
  void dispose() {
    _email.dispose();
    _kataSandi.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _memproses = true;
      _galat = null;
    });
    try {
      await widget.api.masuk(_email.text.trim(), _kataSandi.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HalamanUtama(api: widget.api)));
    } on GagalApi catch (e) {
      setState(() {
        _galat = e.pesan;
        _memproses = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Tata letak mengikuti Gambar 3.14a: logo, judul, kolom email dan kata sandi.
                      Image.asset('assets/logo.png', width: 72, height: 72, excludeFromSemantics: true),
                      const SizedBox(height: 12),
                      Semantics(
                        header: true,
                        child: const Text('Masuk',
                            textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(height: 4),
                      const Text('Klasifikasi Kelayakan Tanam\nBenih Jagung Ketan Putih',
                          textAlign: TextAlign.center, style: TextStyle(color: Warna.tintaLembut, height: 1.4)),
                      const SizedBox(height: 24),
                      if (_galat != null) ...[
                        PesanGalat(_galat!),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                            labelText: 'Email', hintText: 'nama@email.com', prefixIcon: Icon(Icons.mail_outline)),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        validator: (isi) => (isi == null || isi.trim().isEmpty) ? 'Email wajib diisi.' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _kataSandi,
                        decoration: InputDecoration(
                          labelText: 'Kata sandi',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _sandiTerlihat ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi',
                            icon: Icon(_sandiTerlihat ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _sandiTerlihat = !_sandiTerlihat),
                          ),
                        ),
                        obscureText: !_sandiTerlihat,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _memproses ? null : _masuk(),
                        validator: (isi) => (isi == null || isi.isEmpty) ? 'Kata sandi wajib diisi.' : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _memproses
                              ? null
                              : () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => HalamanLupaSandi(api: widget.api, emailAwal: _email.text.trim()))),
                          child: const Text('Lupa kata sandi?'),
                        ),
                      ),
                      const SizedBox(height: 6),
                      FilledButton(
                        onPressed: _memproses ? null : _masuk,
                        child: _memproses
                            ? const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  ),
                                  SizedBox(width: 10),
                                  Text('Memeriksa akun...'),
                                ],
                              )
                            : const Text('Masuk'),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Belum punya akun?', style: TextStyle(fontSize: 14, color: Warna.tintaLembut)),
                          TextButton(
                            onPressed: _memproses
                                ? null
                                : () => Navigator.of(context)
                                    .push(MaterialPageRoute(builder: (_) => HalamanDaftar(api: widget.api))),
                            child: const Text('Daftar'),
                          ),
                        ],
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
