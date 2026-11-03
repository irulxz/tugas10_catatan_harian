import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // data tanggal bahasa Indonesia
import 'package:intl/intl.dart'; // paket intl: format tanggal & waktu
import 'package:shared_preferences/shared_preferences.dart'; // paket penyimpanan lokal

Future<void> main() async {
  // Wajib dipanggil jika ada proses async sebelum runApp()
  WidgetsFlutterBinding.ensureInitialized();
  // Mengaktifkan nama hari/bulan bahasa Indonesia untuk paket intl
  await initializeDateFormatting('id_ID', null);
  runApp(const CatatanHarianApp());
}

// ---------------------------------------------------------------------------
// TAMPILAN DASAR
// ---------------------------------------------------------------------------

/// Palet warna: biru tinta, latar abu kebiruan, dan satu aksen kuning sorot.
class Warna {
  static const latar = Color(0xFFEEF1F6);
  static const tinta = Color(0xFF1F2A44);
  static const tintaSamar = Color(0xFF6B7488);
  static const sorot = Color(0xFFE9B44C);
  static const sorotMuda = Color(0xFFF8E8BF);
  static const garis = Color(0xFFD5DAE4);
}

/// Gaya huruf untuk judul (serif bawaan perangkat).
TextStyle fontJudul({
  double fontSize = 16,
  FontWeight fontWeight = FontWeight.w600,
  Color? color,
  double? height,
}) {
  return TextStyle(
    fontFamily: 'Georgia',
    fontFamilyFallback: const ['serif'],
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}

/// Gaya kolom isian yang dipakai berulang (putih, sudut membulat).
InputDecoration gayaIsian({
  String? hint,
  String? galat,
  EdgeInsets padding = const EdgeInsets.all(18),
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Warna.tintaSamar),
    errorText: galat,
    filled: true,
    fillColor: Colors.white,
    contentPadding: padding,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Warna.garis),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Warna.tinta, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.6),
    ),
  );
}

// ---------------------------------------------------------------------------
// MODEL DATA
// ---------------------------------------------------------------------------

/// Pilihan suasana hati untuk setiap catatan.
class Suasana {
  final String emoji;
  final String nama;
  const Suasana(this.emoji, this.nama);
}

const List<Suasana> daftarSuasana = [
  Suasana('😊', 'Senang'),
  Suasana('😐', 'Biasa'),
  Suasana('😢', 'Sedih'),
  Suasana('😡', 'Marah'),
  Suasana('😴', 'Lelah'),
];

/// Model data satu catatan.
class Catatan {
  final String id; // pengenal unik, dipakai untuk edit/hapus
  final String judul;
  final String isi;
  final DateTime tanggal; // waktu dibuat
  final DateTime? diedit; // waktu terakhir diedit (null jika belum pernah)
  final int suasana; // indeks pada daftarSuasana
  final bool penting; // ditandai bintang atau tidak

  const Catatan({
    required this.id,
    this.judul = '',
    required this.isi,
    required this.tanggal,
    this.diedit,
    this.suasana = 1,
    this.penting = false,
  });

  /// Membuat salinan catatan dengan sebagian data diubah.
  Catatan copyWith({
    String? judul,
    String? isi,
    DateTime? diedit,
    int? suasana,
    bool? penting,
  }) {
    return Catatan(
      id: id,
      judul: judul ?? this.judul,
      isi: isi ?? this.isi,
      tanggal: tanggal,
      diedit: diedit ?? this.diedit,
      suasana: suasana ?? this.suasana,
      penting: penting ?? this.penting,
    );
  }

  // Mengubah objek menjadi Map agar bisa di-encode ke JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'judul': judul,
    'isi': isi,
    'tanggal': tanggal.toIso8601String(),
    'diedit': diedit?.toIso8601String(),
    'suasana': suasana,
    'penting': penting,
  };

  // Membuat objek dari Map hasil decode JSON.
  // Data lama (tanpa judul/id/suasana/penting) tetap bisa dibaca.
  factory Catatan.fromJson(Map<String, dynamic> json) {
    final tanggal = DateTime.parse(json['tanggal'] as String);
    final suasana = (json['suasana'] as int?) ?? 1;
    return Catatan(
      id: (json['id'] as String?) ?? tanggal.toIso8601String(),
      judul: (json['judul'] as String?) ?? '',
      isi: json['isi'] as String,
      tanggal: tanggal,
      diedit: json['diedit'] == null
          ? null
          : DateTime.parse(json['diedit'] as String),
      suasana: suasana >= 0 && suasana < daftarSuasana.length ? suasana : 1,
      penting: (json['penting'] as bool?) ?? false,
    );
  }
}

// ---------------------------------------------------------------------------
// APLIKASI
// ---------------------------------------------------------------------------

class CatatanHarianApp extends StatelessWidget {
  const CatatanHarianApp({super.key});

  @override
  Widget build(BuildContext context) {
    final teksDasar = ThemeData.light().textTheme.apply(
      bodyColor: Warna.tinta,
      displayColor: Warna.tinta,
    );

    return MaterialApp(
      title: 'Catatan Harian',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Warna.latar,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Warna.tinta,
          primary: Warna.tinta,
          surface: Warna.latar,
        ),
        textTheme: teksDasar,
      ),
      home: const HalamanUtama(),
    );
  }
}

class HalamanUtama extends StatefulWidget {
  const HalamanUtama({super.key});

  @override
  State<HalamanUtama> createState() => _HalamanUtamaState();
}

class _HalamanUtamaState extends State<HalamanUtama> {
  // Kunci penyimpanan di shared_preferences
  static const String _kunciCatatan = 'daftar_catatan';

  final List<Catatan> _daftarCatatan = [];
  final TextEditingController _cari = TextEditingController();
  String _kataKunci = '';
  bool _hanyaPenting = false;

  // Format tanggal memakai intl
  final DateFormat _formatHariIni = DateFormat('EEEE, d MMMM y', 'id_ID');
  final DateFormat _formatKartu = DateFormat('EEE, d MMM y', 'id_ID');
  final DateFormat _formatJam = DateFormat('HH:mm', 'id_ID');

  @override
  void initState() {
    super.initState();
    _muatCatatan(); // baca data tersimpan saat aplikasi dibuka
  }

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  // ----------------------- PENYIMPANAN (shared_preferences) ----------------

  /// MEMBACA catatan dari penyimpanan perangkat.
  Future<void> _muatCatatan() async {
    final prefs = await SharedPreferences.getInstance();
    final dataJson = prefs.getString(_kunciCatatan);
    if (dataJson == null) return; // belum ada data tersimpan

    final List<dynamic> hasilDecode = jsonDecode(dataJson);
    setState(() {
      _daftarCatatan
        ..clear()
        ..addAll(
          hasilDecode.map((e) => Catatan.fromJson(e as Map<String, dynamic>)),
        );
    });
  }

  /// MENYIMPAN seluruh daftar catatan ke penyimpanan perangkat.
  Future<void> _simpanKePenyimpanan() async {
    final prefs = await SharedPreferences.getInstance();
    final dataJson = jsonEncode(_daftarCatatan.map((c) => c.toJson()).toList());
    await prefs.setString(_kunciCatatan, dataJson);
  }

  // ----------------------- AKSI CATATAN ------------------------------------

  /// Membuka halaman editor layar penuh. Jika [catatan] diisi, berarti edit.
  Future<void> _bukaEditor({Catatan? catatan}) async {
    final hasil = await Navigator.of(context).push<(String, String, int)>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => EditorCatatan(awal: catatan),
      ),
    );
    if (hasil == null) return; // dibatalkan

    final (judul, isi, suasana) = hasil;
    if (catatan == null) {
      _tambahCatatan(judul, isi, suasana);
    } else {
      _ubahCatatan(catatan, judul, isi, suasana);
    }
  }

  /// Menambah catatan baru.
  Future<void> _tambahCatatan(String judul, String isi, int suasana) async {
    final sekarang = DateTime.now();
    setState(() {
      // Catatan terbaru ditaruh paling atas
      _daftarCatatan.insert(
        0,
        Catatan(
          id: sekarang.microsecondsSinceEpoch.toString(),
          judul: judul,
          isi: isi,
          tanggal: sekarang,
          suasana: suasana,
        ),
      );
    });
    await _simpanKePenyimpanan();
  }

  /// Mengubah judul/isi/suasana catatan yang sudah ada (EDIT).
  Future<void> _ubahCatatan(
    Catatan lama,
    String judul,
    String isi,
    int suasana,
  ) async {
    if (judul == lama.judul && isi == lama.isi && suasana == lama.suasana) {
      return; // tidak ada ubahan
    }
    final index = _daftarCatatan.indexWhere((c) => c.id == lama.id);
    if (index == -1) return;
    setState(() {
      _daftarCatatan[index] = lama.copyWith(
        judul: judul,
        isi: isi,
        suasana: suasana,
        diedit: DateTime.now(),
      );
    });
    await _simpanKePenyimpanan();
  }

  /// Menandai / melepas tanda penting (bintang).
  Future<void> _gantiPenting(Catatan catatan) async {
    final index = _daftarCatatan.indexWhere((c) => c.id == catatan.id);
    if (index == -1) return;
    setState(() {
      _daftarCatatan[index] = catatan.copyWith(penting: !catatan.penting);
    });
    await _simpanKePenyimpanan();
  }

  /// Menghapus catatan, dengan opsi urungkan lewat SnackBar.
  Future<void> _hapusCatatan(Catatan catatan) async {
    final index = _daftarCatatan.indexWhere((c) => c.id == catatan.id);
    if (index == -1) return;
    setState(() {
      _daftarCatatan.removeAt(index);
    });
    await _simpanKePenyimpanan();

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Catatan dihapus'),
          action: SnackBarAction(
            label: 'Urungkan',
            onPressed: () async {
              final posisi = index > _daftarCatatan.length
                  ? _daftarCatatan.length
                  : index;
              setState(() {
                _daftarCatatan.insert(posisi, catatan);
              });
              await _simpanKePenyimpanan();
            },
          ),
        ),
      );
  }

  /// Daftar yang tampil setelah disaring oleh pencarian dan filter.
  List<Catatan> get _daftarTampil {
    final kata = _kataKunci.trim().toLowerCase();
    return _daftarCatatan.where((c) {
      if (_hanyaPenting && !c.penting) return false;
      if (kata.isNotEmpty &&
          !c.judul.toLowerCase().contains(kata) &&
          !c.isi.toLowerCase().contains(kata)) {
        return false;
      }
      return true;
    }).toList();
  }

  // ----------------------- TAMPILAN ----------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaEditor(),
        backgroundColor: Warna.tinta,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Tulis catatan'),
      ),
      body: SafeArea(
        // LayoutBuilder: tata letak menyesuaikan lebar layar (responsif)
        child: LayoutBuilder(
          builder: (context, constraints) {
            final lebarLayar = constraints.maxWidth;
            final layarLebar = lebarLayar >= 720;
            final jarakSisi = layarLebar ? 40.0 : 20.0;
            final jumlahKolom = lebarLayar >= 1500
                ? 4
                : lebarLayar >= 1100
                ? 3
                : lebarLayar >= 720
                ? 2
                : 1;

            return SingleChildScrollView(
              // Ruang bawah agar item terakhir tidak tertutup tombol melayang
              padding: EdgeInsets.fromLTRB(jarakSisi, 28, jarakSisi, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bagianJudul(),
                  const SizedBox(height: 20),
                  _bagianCari(layarLebar),
                  const SizedBox(height: 24),
                  _bagianDaftar(jumlahKolom),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Judul besar + tanggal hari ini + ringkasan jumlah catatan.
  Widget _bagianJudul() {
    final jumlah = _daftarCatatan.length;
    final jumlahPenting = _daftarCatatan.where((c) => c.penting).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catatan harian',
          style: fontJudul(fontSize: 38, color: Warna.tinta, height: 1.1),
        ),
        const SizedBox(height: 6),
        Text(
          _formatHariIni.format(DateTime.now()),
          style: const TextStyle(fontSize: 16, color: Warna.tintaSamar),
        ),
        if (jumlah > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '$jumlah catatan, $jumlahPenting penting',
              style: const TextStyle(fontSize: 14, color: Warna.tintaSamar),
            ),
          ),
      ],
    );
  }

  /// Kolom pencarian + filter Semua/Penting.
  /// Di layar lebar keduanya sejajar; di layar sempit disusun ke bawah.
  Widget _bagianCari(bool layarLebar) {
    final kolomCari = TextField(
      controller: _cari,
      onChanged: (nilai) => setState(() => _kataKunci = nilai),
      decoration:
          gayaIsian(
            hint: 'Cari judul atau isi catatan',
            padding: const EdgeInsets.symmetric(vertical: 14),
          ).copyWith(
            prefixIcon: const Icon(Icons.search, color: Warna.tintaSamar),
            suffixIcon: _kataKunci.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, color: Warna.tintaSamar),
                    tooltip: 'Hapus pencarian',
                    onPressed: () {
                      _cari.clear();
                      setState(() => _kataKunci = '');
                    },
                  ),
          ),
    );

    final filter = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chipFilter(
          'Semua',
          !_hanyaPenting,
          () => setState(() => _hanyaPenting = false),
        ),
        const SizedBox(width: 8),
        _chipFilter(
          'Penting',
          _hanyaPenting,
          () => setState(() => _hanyaPenting = true),
          ikon: Icons.star_rounded,
        ),
      ],
    );

    if (layarLebar) {
      return Row(
        children: [
          SizedBox(width: 400, child: kolomCari),
          const SizedBox(width: 16),
          filter,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [kolomCari, const SizedBox(height: 10), filter],
    );
  }

  Widget _chipFilter(
    String label,
    bool terpilih,
    VoidCallback saatDipilih, {
    IconData? ikon,
  }) {
    return ChoiceChip(
      label: Text(label),
      avatar: ikon == null
          ? null
          : Icon(ikon, size: 18, color: terpilih ? Warna.tinta : Warna.sorot),
      selected: terpilih,
      showCheckmark: false,
      selectedColor: Warna.sorotMuda,
      backgroundColor: Colors.white,
      side: BorderSide(color: terpilih ? Warna.sorot : Warna.garis),
      labelStyle: const TextStyle(color: Warna.tinta),
      onSelected: (_) => saatDipilih(),
    );
  }

  /// Kartu-kartu catatan disusun dalam beberapa kolom sesuai lebar layar.
  Widget _bagianDaftar(int jumlahKolom) {
    final tampil = _daftarTampil;

    if (tampil.isEmpty) {
      final adaData = _daftarCatatan.isNotEmpty;
      return Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Center(
          child: Text(
            adaData
                ? 'Tidak ada catatan yang cocok.\nCoba kata kunci atau filter lain.'
                : 'Belum ada catatan.\nTekan "Tulis catatan" untuk memulai.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Warna.tintaSamar,
              height: 1.5,
            ),
          ),
        ),
      );
    }

    // Bagi catatan bergiliran ke tiap kolom (susunan rapi tanpa celah)
    final kolom = List.generate(jumlahKolom, (_) => <Widget>[]);
    for (var i = 0; i < tampil.length; i++) {
      kolom[i % jumlahKolom].add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _kartuCatatan(tampil[i]),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var k = 0; k < jumlahKolom; k++) ...[
          if (k > 0) const SizedBox(width: 16),
          Expanded(child: Column(children: kolom[k])),
        ],
      ],
    );
  }

  Widget _kartuCatatan(Catatan catatan) {
    final suasana = daftarSuasana[catatan.suasana];
    final punyaJudul = catatan.judul.trim().isNotEmpty;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // Catatan penting diberi garis tepi kuning
        side: BorderSide(
          color: catatan.penting ? Warna.sorot : Warna.garis,
          width: catatan.penting ? 1.8 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _bukaEditor(catatan: catatan), // ketuk untuk mengedit
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris atas: tanggal + bintang + menu
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_formatKartu.format(catatan.tanggal)}  •  ${_formatJam.format(catatan.tanggal)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Warna.tintaSamar,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      catatan.penting
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: catatan.penting ? Warna.sorot : Warna.tintaSamar,
                    ),
                    tooltip: catatan.penting
                        ? 'Lepas tanda penting'
                        : 'Tandai penting',
                    onPressed: () => _gantiPenting(catatan),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Warna.tintaSamar),
                    tooltip: 'Menu',
                    onSelected: (pilihan) {
                      if (pilihan == 'edit') _bukaEditor(catatan: catatan);
                      if (pilihan == 'hapus') _hapusCatatan(catatan);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                    ],
                  ),
                ],
              ),
              // Judul catatan
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  punyaJudul ? catatan.judul : 'Tanpa judul',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: fontJudul(
                    fontSize: 21,
                    height: 1.25,
                    color: punyaJudul ? Warna.tinta : Warna.tintaSamar,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Cuplikan isi catatan
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  catatan.isi,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
              const SizedBox(height: 14),
              // Baris bawah: suasana hati + keterangan diedit
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Warna.latar,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${suasana.emoji} ${suasana.nama}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    if (catatan.diedit != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        'diedit ${_formatJam.format(catatan.diedit!)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Warna.tintaSamar,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HALAMAN EDITOR LAYAR PENUH (catatan baru dan edit)
// ---------------------------------------------------------------------------

class EditorCatatan extends StatefulWidget {
  final Catatan? awal; // null = catatan baru

  const EditorCatatan({super.key, this.awal});

  @override
  State<EditorCatatan> createState() => _EditorCatatanState();
}

class _EditorCatatanState extends State<EditorCatatan> {
  late final TextEditingController _judul = TextEditingController(
    text: widget.awal?.judul ?? '',
  );
  late final TextEditingController _isi = TextEditingController(
    text: widget.awal?.isi ?? '',
  );
  late int _suasana = widget.awal?.suasana ?? 1;
  String? _galatJudul;
  String? _galatIsi;

  @override
  void dispose() {
    _judul.dispose();
    _isi.dispose();
    super.dispose();
  }

  void _simpan() {
    final judul = _judul.text.trim();
    final isi = _isi.text.trim();

    setState(() {
      _galatJudul = judul.isEmpty ? 'Judul tidak boleh kosong' : null;
      _galatIsi = isi.isEmpty ? 'Isi catatan tidak boleh kosong' : null;
    });
    if (judul.isEmpty || isi.isEmpty) return;

    // Mengirim hasil (judul, isi, suasana) kembali ke halaman utama
    Navigator.pop(context, (judul, isi, _suasana));
  }

  @override
  Widget build(BuildContext context) {
    final modeEdit = widget.awal != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Warna.latar,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Batal',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          modeEdit ? 'Edit catatan' : 'Catatan baru',
          style: fontJudul(fontSize: 20, color: Warna.tinta),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton(
              onPressed: _simpan,
              style: FilledButton.styleFrom(
                backgroundColor: Warna.tinta,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(modeEdit ? 'Simpan perubahan' : 'Simpan'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          // Lebar dibatasi agar baris tulisan tetap nyaman dibaca
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kolom judul
                  TextField(
                    controller: _judul,
                    autofocus: !modeEdit,
                    maxLines: 1,
                    textInputAction: TextInputAction.next,
                    style: fontJudul(fontSize: 28, color: Warna.tinta),
                    onChanged: (_) {
                      if (_galatJudul != null) {
                        setState(() => _galatJudul = null);
                      }
                    },
                    decoration: gayaIsian(
                      hint: 'Judul catatan',
                      galat: _galatJudul,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Pilihan suasana hati
                  const Text(
                    'Suasana hati',
                    style: TextStyle(fontSize: 14, color: Warna.tintaSamar),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < daftarSuasana.length; i++)
                        ChoiceChip(
                          label: Text(
                            '${daftarSuasana[i].emoji} ${daftarSuasana[i].nama}',
                          ),
                          selected: _suasana == i,
                          showCheckmark: false,
                          selectedColor: Warna.sorotMuda,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: _suasana == i ? Warna.sorot : Warna.garis,
                          ),
                          labelStyle: const TextStyle(color: Warna.tinta),
                          onSelected: (_) => setState(() => _suasana = i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Kolom isi: mengisi seluruh sisa tinggi layar
                  Expanded(
                    child: TextField(
                      controller: _isi,
                      expands: true,
                      maxLines: null,
                      minLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(fontSize: 17, height: 1.6),
                      onChanged: (_) {
                        if (_galatIsi != null) {
                          setState(() => _galatIsi = null);
                        }
                      },
                      decoration: gayaIsian(
                        hint: 'Tulis ceritamu hari ini...',
                        galat: _galatIsi,
                        padding: const EdgeInsets.all(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
