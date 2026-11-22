import 'package:flutter/material.dart';

import '../layanan/api.dart';
import '../tema.dart';

// Meminta tautan atur ulang kata sandi. Tautan dikirim ke email dan dibuka di browser (halaman website).
class HalamanLupaSandi extends StatefulWidget {
  const HalamanLupaSandi({super.key, required this.api, this.emailAwal = ''});

  final Api api;
  final String emailAwal;

  @override
  State<HalamanLupaSandi> createState() => _HalamanLupaSandiState();
}

class _HalamanLupaSandiState extends State<HalamanLupaSandi> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.emailAwal);
  bool _memproses = false;
  String? _galat;
  String? _terkirim;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _memproses = true;
      _galat = null;
      _terkirim = null;
    });
    try {
      final pesan = await widget.api.lupaSandi(_email.text.trim());
      setState(() => _terkirim = pesan);
    } on GagalApi catch (e) {
      setState(() => _galat = e.pesan);
    } finally {
      if (mounted) setState(() => _memproses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lupa kata sandi')),
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
                      const Text(
                        'Masukkan email akun Anda. Tautan untuk mengatur ulang kata sandi akan dikirim ke email tersebut.',
                        style: TextStyle(fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      if (_galat != null) ...[
                        PesanGalat(_galat!),
                        const SizedBox(height: 16),
                      ],
                      if (_terkirim != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Warna.hijauMuda,
                            border: Border.all(color: Warna.hijau),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Semantics(
                            liveRegion: true,
                            child: Text(_terkirim!, style: const TextStyle(color: Warna.hijau, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        validator: (isi) => (isi == null || isi.trim().isEmpty) ? 'Email wajib diisi.' : null,
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _memproses ? null : _kirim,
                        child: Text(_memproses ? 'Mengirim...' : 'Kirim tautan'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Kembali ke halaman masuk'),
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
