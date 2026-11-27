# Changelog

Semua perubahan penting pada proyek ini didokumentasikan di file ini.

Format mengikuti [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versi terbaru ada di atas.

## v0.47.0

Update besar yang menambahkan tag pada tautan tersimpan dan filter berdasarkan tag.

### Fitur baru

- **Tag tautan tersimpan.** Dialog ubah kini menerima tag. Tag tampil di baris tersimpan dan filter chip menampilkan satu grup saja.

### Peningkatan

- **107 test lulus**, termasuk cakupan persistensi tag.
- **Kompatibel mundur.** Baris lama tanpa tag tetap berfungsi dan ditampilkan tanpa label tag.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.47.0-windows-x64.zip`. Linux: `Talos-v0.47.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.46.0

Update besar yang menambahkan perlindungan penyimpanan dan kepadatan antarmuka adaptif.

### Fitur baru

- **Jaga penyimpanan.** Di Android, unduhan baru menunggu saat ruang kosong di bawah 500 MB, 1 GB, atau 5 GB, lalu lanjut otomatis.
- **Chip status.** Beranda menampilkan WiFi atau seluler, pengisian daya, dan baterai rendah di Android.
- **Kartu ringkas.** Pilih kartu tugas dan riwayat ringkas atau nyaman.
- **Umpan balik getar.** Getar ringan opsional saat batal dan coba ulang, aktif secara default.

### Peningkatan

- **106 test lulus**, termasuk regresi gate ruang kosong.

### Ditunda

- Jalur paralel, kontrol di notifikasi, dan app shortcuts masih memerlukan kerja engine dan service yang lebih dalam.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.46.0-windows-x64.zip`. Linux: `Talos-v0.46.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.45.0

Update besar yang menyelesaikan peta jalan desain dengan onboarding dan wawasan penyimpanan.

### Fitur baru

- **Penyiapan cepat.** Beranda menampilkan daftar kecil yang bisa ditutup untuk izin, kesiapan engine, dan unduhan pertama.
- **Folder penyimpanan.** Wawasan mengelompokkan unduhan selesai berdasarkan folder induk beserta jumlah dan total ukuran.

### Peningkatan

- **105 test lulus**, termasuk cakupan pengelompokan folder.
- **Path lintas platform.** Pengelompokan folder menangani separator garis miring dan terbalik.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.45.0-windows-x64.zip`. Linux: `Talos-v0.45.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.44.0

Update besar yang merancang ulang pengalaman Unduhan dengan komponen dan gerak bersama.

### Fitur baru

- **Status pill.** Kartu tugas kini menampilkan label status jelas dengan ikon dan warna untuk mengantre, mengunduh, selesai, gagal, dan dibatalkan.
- **Empty state bersama.** Tab Aktif dan Selesai memakai komponen empty state yang sama dan dapat diakses, dengan satu aksi lanjutan.
- **Masuk bertahap.** Kartu tugas muncul dengan fade dan naik singkat secara bertahap, otomatis dimatikan saat reduced motion aktif.

### Peningkatan

- **104 test lulus**, analyzer bersih, dan nol em/en dash.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.44.0-windows-x64.zip`. Linux: `Talos-v0.44.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.43.0

Update besar yang meletakkan fondasi desain untuk gelombang antarmuka berikutnya.

### Fitur baru

- **Token desain.** Spacing, radius, dan warna status semantik bersama menggantikan nilai yang dibuat spontan.
- **Konstanta gerak.** Satu keluarga easing, tiga durasi, dan helper reduced motion membuat gerak konsisten.
- **Komponen bersama.** Status pill, wait reason banner, progress ring, dan empty state kini menjadi widget bersama.
- **Status menunggu lebih jelas.** Tab Aktif kini menjelaskan penantian karena hanya saat mengisi daya dengan banner komponen yang sama seperti gate lainnya.

### Peningkatan

- **104 test lulus**, analyzer bersih, dan nol em/en dash.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.43.0-windows-x64.zip`. Linux: `Talos-v0.43.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.42.0

Update besar yang menyelesaikan peta jalan otomatisasi dengan kontrol pengisian daya, berbagi banyak tautan, dan bantuan offline.

### Fitur baru

- **Hanya saat mengisi.** Di Android, unduhan tertunda bisa menunggu sampai perangkat dicolok. Hasil bridge yang tidak diketahui tetap mengizinkan antrean, bukan memblokirnya.
- **Bagikan banyak tautan.** Membagikan beberapa URL dari aplikasi lain kini meneruskan semuanya ke Beranda, sehingga alur batch yang sudah ada bisa menanganinya.
- **Bantuan offline.** Tentang kini menautkan FAQ bawaan tentang penyimpanan, alasan menunggu, cookie, membuka file, cadangan, dan masalah engine.

### Peningkatan

- **104 test lulus**, termasuk regresi gate pengisian daya.

### Catatan

- Jalur unduhan paralel dan kontrol di notifikasi tetap ditunda karena membutuhkan isolasi engine yang lebih dalam. Kunci biometrik juga ditunda karena menambah dependency dan izin baru.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.42.0-windows-x64.zip`. Linux: `Talos-v0.42.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.41.0

Update besar yang menambahkan berbagi massal dan pembersihan duplikat pada pustaka selesai.

### Fitur baru

- **Bagikan banyak.** Mode pilih di tab Selesai kini bisa membagikan beberapa file sekaligus lewat share sheet sistem.
- **Cari duplikat.** Wawasan bisa menghapus baris lama yang memiliki URL atau judul sama, menyisakan baris terbaru dan seluruh file di penyimpanan.

### Peningkatan

- **103 test lulus**, termasuk cakupan deteksi duplikat.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.41.0-windows-x64.zip`. Linux: `Talos-v0.41.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.40.0

Update besar yang menambahkan kontrol lanjutan per unduhan, otomatisasi keandalan, dan aturan alur file.

### Fitur baru

- **Opsi lanjutan.** Kecepatan, proxy, dan header HTTP bisa ditimpa untuk satu unduhan tanpa mengubah pengaturan global.
- **Urutan playlist.** Playlist bisa dijalankan sesuai urutan asli, terbalik, atau acak.
- **Aturan folder.** Aturan domain ke folder mengarahkan unduhan otomatis, termasuk pencocokan subdomain.
- **Backoff retry.** Pilih jeda linier atau eksponensial yang dibatasi untuk coba ulang otomatis.
- **Pengawas mandek.** Opsional coba ulang unduhan yang berhenti melaporkan progres selama beberapa menit.
- **Aksi setelah unduhan.** Opsional buka, bagikan, atau tambahkan file ke favorit setelah unduhan satu file berhasil.
- **Bersih saat start.** Opsional hapus file sementara lama saat aplikasi dibuka.
- **Yang baru.** Setelah update, dialog menautkan ke catatan rilis.

### Peningkatan

- **102 test lulus**, termasuk pencocokan aturan folder.
- **Timer gate** dibatalkan saat antrean tertunda dikosongkan atau cadangan dipulihkan.

### Ditunda ke gelombang berikutnya

- Jalur unduhan paralel dan kontrol di notifikasi membutuhkan isolasi engine yang lebih dalam dan akan dirilis setelah versi ini.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.40.0-windows-x64.zip`. Linux: `Talos-v0.40.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.39.0

Update besar yang membuat pengingat izin akurat dan menyelesaikan audit terfokus.

### Fitur baru

- **Status izin langsung.** Pengingat di Beranda kini hilang segera setelah semua izin yang dibutuhkan diberikan, termasuk saat pengguna kembali dari pengaturan sistem.

### Perbaikan bug

- **Izin gambar.** Menolak hanya akses gambar media tidak lagi membuat pengingat penyimpanan tetap muncul, karena unduhan membutuhkan akses video atau audio, bukan gambar sampul.
- **Timer antrean.** Mengosongkan antrean tertunda kini membatalkan timer WiFi, baterai, dan jendela unduhan yang tersisa.
- **Pulihkan cadangan.** Memulihkan pengaturan kini langsung memeriksa ulang antrean, sehingga gate yang hilang tidak membuat unduhan menunggu.

### Peningkatan

- **101 test lulus**, analyzer bersih, dan nol em/en dash.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.39.0-windows-x64.zip`. Linux: `Talos-v0.39.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.38.0

Update besar yang menambahkan pengingat izin di beranda.

### Fitur baru

- **Pengingat izin.** Jika akses notifikasi atau penyimpanan ditolak, Beranda menampilkan kartu pengingat dengan pintasan langsung ke pengaturan aplikasi sistem, alih-alih gagal diam-diam kemudian.

### Peningkatan

- **101 test lulus**, termasuk perilaku bridge izin yang tidak aktif di luar Android.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.38.0-windows-x64.zip`. Linux: `Talos-v0.38.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.37.0

Update besar yang menyempurnakan izin saat pertama kali dibuka dan menambahkan tinjauan izin di dalam aplikasi.

### Fitur baru

- **Akses penyimpanan saat awal.** Izin penyimpanan dan media kini diminta dalam dialog startup yang sama dengan notifikasi, memakai izin yang tepat untuk tiap level Android: akses media terperinci di API 33+, akses baca di API 29 sampai 32, serta baca dan tulis di API 24 sampai 28.
- **Tinjau izin.** Pengaturan kini menampilkan status izin notifikasi dan penyimpanan, dengan pintasan ke pengaturan aplikasi di sistem.

### Peningkatan

- **100 test lulus**, analyzer bersih, dan nol em/en dash.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.37.0-windows-x64.zip`. Linux: `Talos-v0.37.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.36.0

Update besar yang menambahkan simpan banyak tautan dan implementasi coba ulang yang lebih aman.

### Fitur baru

- **Simpan semua tautan.** Saat teks tempelan berisi beberapa URL, aksi Simpan semua menyimpan semua tautan yang terdeteksi sekaligus, melewati duplikat dan baris kosong.

### Peningkatan

- **Coba ulang lebih aman.** Retry kini menyalin request yang tersimpan alih-alih membangunnya satu per satu, sehingga opsi baru tidak pernah terhilang.
- **100 test lulus**, termasuk tautan tersimpan massal dan pelestarian field saat retry.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.36.0-windows-x64.zip`. Linux: `Talos-v0.36.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.35.0

Update besar yang meningkatkan akses ke detail unduhan aktif.

### Fitur baru

- **Salin URL tugas.** Setiap tugas aktif atau gagal kini punya aksi Salin URL, sehingga tautan bisa dipakai ulang tanpa membuka entri riwayat.
- **Log tugas langsung.** Penampil log tersedia di semua tahap, termasuk saat unduhan masih berjalan, bukan hanya setelah gagal.

### Peningkatan

- **98 test lulus**, analyzer bersih, dan nol em/en dash.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.35.0-windows-x64.zip`. Linux: `Talos-v0.35.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.34.0

Update besar yang memperbaiki anomali gate antrean dari audit terfokus, plus alasan menunggu yang terlihat di tab Aktif.

### Fitur baru

- **Alasan menunggu.** Tab Aktif kini menampilkan mengapa unduhan tertunda menunggu, dengan pesan terlokalisasi untuk antrean dijeda, WiFi, baterai rendah, dan jendela unduhan.

### Perbaikan bug

- **Jam jendela sama.** Jam mulai dan berakhir yang sama kini berarti tanpa pembatasan waktu, bukan memblokir antrean selamanya.
- **Probe gate tidak tersedia.** Saat bridge WiFi atau baterai tidak menghasilkan hasil, antrean tetap berjalan alih-alih menunggu tanpa batas.

### Peningkatan

- **98 test lulus**, termasuk cakupan fallback gate dan jam yang sama.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.34.0-windows-x64.zip`. Linux: `Talos-v0.34.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.33.0

Update besar yang menambahkan pembatas baterai rendah native untuk antrean unduhan.

### Fitur baru

- **Hemat baterai.** Di Android, unduhan baru menunggu saat baterai di bawah ambang pilihan (5, 10, 20, atau 30 persen) dan perangkat tidak sedang diisi. Tugas lanjut otomatis setelah kondisi membaik.

### Peningkatan

- **97 test lulus**, termasuk regresi gating baterai rendah dengan probe yang bisa disuntik.
- **Tanpa izin tambahan.** Status baterai dibaca dari broadcast sistem sticky, sehingga tidak ada prompt runtime baru.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.33.0-windows-x64.zip`. Linux: `Talos-v0.33.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.32.0

Update besar yang menambahkan pembersihan file sementara agar penyimpanan lokal tetap ringan.

### Fitur baru

- **Bersih file sementara.** Aksi di Pengaturan menghapus file `.tmp`, `.part`, `.ytdl`, dan `.download` lama dari data aplikasi serta folder output. File yang lebih baru dari satu jam dan unduhan selesai tetap disimpan.

### Peningkatan

- **96 test lulus**, termasuk perilaku pembersihan untuk file lama, baru, dan file yang tidak terkait.
- **Konfirmasi eksplisit.** Aksi pembersihan menjelaskan jenis file yang dihapus sebelum dijalankan.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.32.0-windows-x64.zip`. Linux: `Talos-v0.32.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.31.0

Update besar yang menambahkan jendela unduhan yang bisa diatur untuk antrean.

### Fitur baru

- **Jendela unduhan.** Unduhan yang antre bisa dibatasi pada jam mulai dan berakhir tertentu. Rentang lintas malam seperti 22 sampai 6 didukung. Tugas menunggu di antrean dan lanjut otomatis saat jendela terbuka.

### Peningkatan

- **95 test lulus**, termasuk kasus jendela normal, lintas malam, dan jam sama.
- **Lanjut langsung.** Mematikan jendela atau mengubah batasnya langsung menjalankan pengecekan antrean.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.31.0-windows-x64.zip`. Linux: `Talos-v0.31.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.30.0

Update besar yang menambahkan filter playlist berdasarkan durasi dan judul.

### Fitur baru

- **Filter playlist.** Configure kini punya dialog filter yang memilih entri playlist otomatis berdasarkan durasi minimal, durasi maksimal, dan teks judul. Filter tanpa hasil membiarkan pilihan saat ini dan menampilkan pesan.

### Peningkatan

- **93 test lulus**, termasuk cakupan filter durasi dan judul.
- **Durasi tidak diketahui.** Entri tanpa durasi dikecualikan saat batas durasi diatur, agar filter tidak menerima panjang yang tidak terverifikasi.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.30.0-windows-x64.zip`. Linux: `Talos-v0.30.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.29.0

Update besar yang menambahkan pengelolaan tautan tersimpan, plus penyempurnaan ekspor data.

### Fitur baru

- **Ubah tautan tersimpan.** Setiap tautan tersimpan kini punya aksi Salin dan Ubah. Mengubah tautan mempertahankan id dan tanggal asli, sehingga urutan daftar dan referensi riwayat tetap utuh.

### Peningkatan

- **92 test lulus**, termasuk uji persistensi perubahan tautan tersimpan.
- **Umpan balik.** Menyalin atau mengubah tautan tersimpan menampilkan konfirmasi snackbar terlokalisasi.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.29.0-windows-x64.zip`. Linux: `Talos-v0.29.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.28.0

Update besar yang menambahkan ekspor riwayat CSV dan perbaikan pembatalan native saat penggabungan FFmpeg.

### Fitur baru

- **Ekspor CSV.** Riwayat selesai bisa disalin atau dibagikan sebagai CSV berisi judul, URL, jenis, path, ukuran, tanggal, dan status favorit. Kolom yang mengandung koma, tanda kutip, atau baris baru di-escape dengan benar.

### Perbaikan bug

- **Batal saat gabung.** Bridge Android kini membatalkan sesi FFmpegKit aktif, sehingga tombol Batal saat penggabungan stream menghentikan proses, bukan hanya menandai flag yang tidak bisa dilihat oleh panggilan yang sedang memblokir.

### Peningkatan

- **91 test lulus**, termasuk cakupan escape CSV.
- **Bagikan ekspor.** Teks CSV riwayat bisa dibagikan lewat share sheet sistem, seperti cadangan.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.28.0-windows-x64.zip`. Linux: `Talos-v0.28.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.27.0

Update besar yang menambahkan kontrol antrean eksplisit dan cakupan pemilihan aset engine desktop.

### Fitur baru

- **Jeda dan lanjutkan antrean.** Unduhan baru bisa ditahan tanpa menghentikan tugas yang sedang berjalan. State jeda bertahan setelah restart, dan melanjutkan langsung menjalankan antrean.
- **Hapus unduhan tertunda.** Aksi dengan konfirmasi membatalkan semua tugas yang belum dimulai, tanpa menyentuh unduhan aktif.

### Peningkatan

- **90 test lulus**, termasuk cakupan jeda/lanjut dan pemilihan aset desktop.
- **Ikon berbeda.** Bersihkan yang selesai dan hapus yang tertunda kini memakai ikon berbeda agar tidak membingungkan.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.27.0-windows-x64.zip`. Linux: `Talos-v0.27.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.26.0

Update besar yang menambahkan header HTTP kustom, plus perbaikan urutan stream penggabungan native.

### Fitur baru

- **Header kustom.** Pengaturan menerima header `Nama: nilai` satu per baris. Setiap baris diteruskan ke yt-dlp lewat `--add-headers`, sehingga situs yang membutuhkan Referer tertentu bekerja tanpa file cookies.

### Perbaikan bug

- **Urutan stream gabungan.** Penggabung Android kini menaruh bagian yang lebih besar terlebih dahulu, sehingga FFmpeg memilih stream video saat yt-dlp mencantumkan audio lebih dulu.

### Peningkatan

- **88 test lulus**, termasuk uji argumen header kustom.
- **Header tersimpan.** Header kustom ikut tersimpan di pengaturan dan terbawa pada unduhan yang antre maupun yang dipulihkan.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.26.0-windows-x64.zip`. Linux: `Talos-v0.26.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.25.0

Update besar yang menambahkan pembatas unduhan WiFi-only di Android dengan pemeriksaan konektivitas native.

### Fitur baru

- **Hanya WiFi.** Saat diaktifkan di Android, unduhan yang antre dijeda dan lanjut otomatis ketika koneksi WiFi aktif terdeteksi. Tugas mempertahankan posisi dan pengaturannya saat menunggu. Mematikan pengaturan langsung menjalankan kembali antrean.

### Perbaikan bug

- **Izin jaringan.** ACCESS_NETWORK_STATE kini dideklarasikan eksplisit sebagai izin normal untuk pemeriksaan konektivitas. Tidak ada prompt runtime baru.

### Peningkatan

- **87 test lulus**, termasuk regresi gating WiFi dengan probe yang bisa disuntik.
- **Umpan antrean.** Tugas yang menunggu menampilkan tahap khusus alih-alih terlihat macet.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.25.0-windows-x64.zip`. Linux: `Talos-v0.25.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.24.0

Update besar yang menambahkan daftar lisensi runtime dan retensi riwayat otomatis, plus perbaikan memori engine dan penyelarasan versi.

### Fitur baru

- **Lisensi runtime.** Tentang kini menautkan daftar eksplisit lisensi yt-dlp, Chaquopy, FFmpegKit, binary engine desktop, FFmpeg terkelola, dan paket Dart.
- **Retensi riwayat.** Baris riwayat lama bisa dihapus otomatis saat aplikasi dibuka setelah 7, 30, atau 90 hari. File di penyimpanan tidak pernah dihapus oleh pengaturan ini.

### Perbaikan bug

- **Memori ekstraksi FFmpeg.** Binary FFmpeg Windows terkelola ditulis langsung ke disk alih-alih didekompresi penuh di memori.
- **Selisih versi engine.** Pin yt-dlp Android kini sama dengan versi terkelola desktop.
- **Label penulis.** Layar Tentang memakai label GitHub terlokalisasi alih-alih teks Inggris tetap.

### Peningkatan

- **86 test lulus**, termasuk cakupan retensi riwayat.
- **Transparansi lisensi.** Pertanyaan terbuka tentang komponen GPL dan LGPL kini didokumentasikan di dalam aplikasi.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.24.0-windows-x64.zip`. Linux: `Talos-v0.24.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.23.0

Update besar yang menambahkan antrean bertahan, plus perbaikan kecil dari audit mendalam yang berkelanjutan.

### Fitur baru

- **Antrean bertahan.** Unduhan tertunda disimpan secara atomik dan dilanjutkan setelah aplikasi dimulai ulang dengan request dan jumlah coba ulang yang utuh. Tugas yang terhenti saat berjalan kembali ke antrean alih-alih hilang.
- **Antrean dalam cadangan.** Cadangan portabel kini mencakup antrean tertunda di samping pengaturan, riwayat, tautan tersimpan, preset, dan perintah.

### Perbaikan bug

- **Hari terlokalisasi.** Label aktivitas Wawasan mengikuti bahasa aktif alih-alih inisial Inggris yang ditulis tetap.
- **Tooltip favorit.** Tombol bintang kini mengatakan Tambahkan ke favorit atau Hapus dari favorit, bukan label umum.

### Peningkatan

- **85 test lulus**, termasuk cakupan serialisasi request lengkap dan pemulihan antrean.
- **Dependensi intl eksplisit.** Formatter tanggal kini mendeklarasikan paket yang dipakainya.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.23.0-windows-x64.zip`. Linux: `Talos-v0.23.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.22.0

Update besar yang menambahkan coba ulang otomatis, plus audit mendalam putaran kedua pada navigasi, pesan error, startup native, dan performa UI.

### Fitur baru

- **Coba ulang otomatis.** Unduhan yang gagal bisa diulang otomatis hingga tiga kali dengan jeda singkat. Error izin penyimpanan dan pembatalan tidak pernah diulang.

### Perbaikan bug

- **Pemilih format.** Membuka kembali pemilih format tidak lagi menghapus selector kustom tersimpan seperti `bv*[height<=720]+ba`.
- **Error terlokalisasi.** Pengaturan, Unduhan, dan Beranda sekarang memakai satu resolver yang sama, sehingga error engine diterjemahkan alih-alih menampilkan teks Inggris di UI Indonesia.
- **Template perintah.** Gagal memuat menampilkan tombol coba lagi, bukan spinner tanpa akhir.
- **Bersihkan selesai.** Konfirmasi kini menjelaskan bahwa hanya daftar yang dihapus dan file di penyimpanan tetap ada.
- **Pembersihan Wawasan.** Pembersihan sebagian melaporkan berapa file yang gagal dihapus alih-alih mengklaim sukses penuh.
- **Pembuat cookie.** Tombol Tutup yang jelas keluar dari layar tanpa menelusuri seluruh riwayat WebView.
- **Rebuild tab.** Berpindah tab tidak lagi membangun ulang daftar pada notifikasi TabController yang duplikat.
- **Teks hardcoded.** Nama kanal engine dan label penulis GitHub kini terlokalisasi.
- **aria2c.** Mengaktifkan aria2 tanpa binary yang terpasang menghasilkan pesan jelas alih-alih menggagalkan setiap unduhan tanpa sebab.
- **Startup Python.** Lock di level proses mencegah dua Flutter engine memulai Python Chaquopy bersamaan.
- **FileProvider.** Berbagi penyimpanan eksternal dibatasi pada direktori Download/Talos milik aplikasi.
- **Memori Gradle.** Heap daemon diturunkan untuk mengurangi kegagalan out-of-memory native pada build Chaquopy.
- **Simbol.** Build rilis ter-obfuscate kini mengunggah file simbol bersama artifact APK.

### Peningkatan

- **Resolusi nama file async.** Pemindaian direktori tidak lagi memblokir UI isolate saat unduhan antre.
- **83 test lulus**, termasuk uji coba ulang kegagalan sementara.
- **Kode mati dihapus.** Field Activity yang tidak dipakai tidak lagi menyimpan referensi Activity.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.22.0-windows-x64.zip`. Linux: `Talos-v0.22.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.21.0

Update besar yang menambahkan cadangan dan pemulihan portabel, plus perbaikan audit mendalam untuk pembatalan, penyimpanan Android, penggabungan playlist, dan bootstrap engine.

### Fitur baru

- **Cadangkan dan pulihkan.** Pengaturan, riwayat, tautan tersimpan, preset, dan template perintah bisa diekspor sebagai JSON portabel lalu dipulihkan di perangkat yang sama atau yang baru. File yang sudah diunduh tidak diubah.

### Perbaikan bug

- **Batal saat pasca-proses.** Pembatalan yang datang setelah engine selesai tidak lagi menulis baris riwayat atau meninggalkan salinan file.
- **Hasil playlist.** Penggabungan playlist Android kini melaporkan semua hasil, sehingga semua entri tersimpan dan masuk riwayat, bukan hanya yang terakhir.
- **Gabungan gagal.** Kegagalan gabungan FFmpeg dilaporkan sebagai error, bukan menyimpan stream parsial sebagai file selesai.
- **JSON probe.** Diagnostik yt-dlp di stderr tidak lagi merusak payload JSON dari probe Android.
- **Hapus MediaStore.** File yang disimpan lewat MediaStore kini dihapus dengan ContentResolver, sehingga aksi hapus berjalan di API 29 ke atas.
- **Gagal hapus.** File yang gagal dihapus mempertahankan baris riwayatnya dan menampilkan pesan, bukan meninggalkan file tanpa jejak.
- **Gagal status engine.** Configure menampilkan aksi coba lagi alih-alih membiarkan tombol Unduh mati tanpa penjelasan.
- **Path Windows.** Perintah kustom mempertahankan backslash pada path seperti `C:\Users\me\cookies.txt`.
- **Injeksi opsi URL.** Penanda akhir opsi kini mendahului URL, sehingga tautan tersimpan yang diawali tanda dash tidak bisa menyuntikkan flag yt-dlp.
- **Bootstrap engine desktop.** Linux memilih build glibc atau musl yang mandiri, dan armv7 mengekstrak binary dari aset zip. Setup FFmpeg mewajibkan ffmpeg.exe dan ffprobe.exe.
- **Antrean macet.** Kegagalan start proses atau dekode stream selalu menyelesaikan outcome sesi, sehingga antrean berurutan tidak bisa menggantung.
- **Nama file unik.** Setelah banyak tabrakan, Talos memakai akhiran waktu alih-alih jatuh kembali ke nama yang sudah terpakai.
- **MIME.** File `.3gp`, `.3g2`, dan `.mov` kini diindeks dengan tipe MediaStore yang benar.
- **Putus folder.** Menghapus folder SAF kini melepaskan izin URI yang tersimpan.
- **Tanda tangan rilis.** Build rilis gagal jelas saat kunci tanda tangan tidak ada, alih-alih diam-diam memakai kunci debug.
- **Lokalisasi.** UI Bahasa Indonesia kini memakai tagline terjemahan di Beranda, Intro, dan Tentang.
- **Umpan balik Fetch.** Teks tanpa URL valid kini menampilkan petunjuk lokal alih-alih tidak melakukan apa pun.

### Peningkatan

- **82 test lulus**, termasuk uji cadangan pulih pergi-balik dan regresi command builder.
- **Gerbang CI.** Job build kini menunggu job verify sehingga artifact tidak dibuat dari kode yang gagal.
- **Deteksi engine.** Engine terkelola dikenali dari path aslinya, bukan dari substring path, sehingga instalasi sistem dilaporkan benar.
- **Timeout proses.** Proses versi dan probe dihentikan saat timeout, alih-alih dibiarkan berjalan.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah ini. Android: `app-release.apk`. Windows: `Talos-v0.21.0-windows-x64.zip`. Linux: `Talos-v0.21.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24), Windows 10, atau Linux dengan GTK3 terbaru.

## v0.20.0

Update besar yang menambahkan aksi unduh ulang untuk entri selesai, plus perbaikan folder Android, penggabungan playlist, dan unduhan massal tautan tersimpan dari audit mendalam baru.

### Fitur baru

- **Unduh lagi.** Setiap entri selesai sekarang punya aksi "Unduh lagi" di menunya. Aksi ini mem-probe URL tersimpan dan membuka Configure dengan info media terbaru agar pengaturan bisa diubah sebelum mengunduh ulang.

### Perbaikan bug

- **Folder per-jenis Android.** Folder video atau audio yang dipilih pengguna kini menjadi acuan di API 29+; file tidak lagi dipindahkan diam-diam ke Downloads/Talos dan folder pilihan dikosongkan.
- **Playlist Android.** Bagian video/audio kini dikelompokkan per nama dasar dan digabung per entri, sehingga playlist tidak lagi selesai dengan satu fragmen rusak dan stream lain tercecer.
- **Unduh semua tautan tersimpan.** Semua URL kini diratakan lewat detektor yang sama dengan kolom input, sehingga tautan multi-URL tetap lengkap dan satu tautan tersimpan berhasil diunduh alih-alih tidak melakukan apa pun.
- **Deteksi sukses Android.** Baris `ERROR:` sesaat tidak lagi menandai unduhan sukses sebagai gagal; status native yang menjadi acuan.
- **Parsing baris error.** Error yt-dlp berprefiks `[site] ERROR:` kini terdeteksi, tanpa salah mencocokkan kata lain.
- **Memori setup FFmpeg.** Arsip essentials didekode sebagai stream, bukan dibuffer penuh di memori.
- **Helper nama file.** Loop keunikan dibatasi dan pemindaian direktori lebih ringan.
- **MIME MediaStore.** File `.m4a` kini diindeks sebagai `audio/mp4`, bukan video.
- **Salinan SAF.** Dokumen kosong tidak lagi ditinggalkan saat salinan gagal.
- **Lokalisasi.** Metadata `@appTitle` ditambahkan ke ARB Bahasa Indonesia.

### Peningkatan

- **78 test lulus**, dengan ekspektasi stabil untuk resolusi nama file async.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah. Android: `app-release.apk` (universal, untuk perangkat Android 64-bit). Windows: `Talos-v0.20.0-windows-x64.zip`. Linux: `Talos-v0.20.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24) ke atas, Windows 10, atau Linux dengan GTK3 terbaru.

## v0.19.0

Update besar yang dipimpin oleh unduhan massal untuk tautan tersimpan, plus perbaikan konkurensi dan keandalan dari audit mendalam baru.

### Fitur baru

- **Unduh semua tautan tersimpan.** Bagian Tautan tersimpan punya aksi "Unduh semua" yang membuka dialog batch Video/Audio yang sama seperti tautan yang ditempel. Setiap tautan tersimpan antre dengan pengaturan saat ini, dan kolom input tidak diubah.

### Perbaikan bug

- **Konkurensi engine Android.** Lock di level modul kini menyerialkan entry point Python, sehingga memulai probe saat unduhan berjalan tidak lagi menukar stdout/stderr global dari tugas aktif dan merusak progres atau hasil probe.
- **Batal di desktop.** Membatalkan unduhan tepat setelah dimulai sekarang menghentikan proses yt-dlp, alih-alih membiarkannya menulis file tanpa baris riwayat.
- **Penulisan JSON bersamaan.** Setiap tulis atomik memakai file tmp unik, sehingga mutasi pengaturan, riwayat, tautan tersimpan, atau preset yang bersamaan tidak saling memotong.
- **Penghapusan template.** Template perintah bawaan kini hanya disisipkan saat instalasi baru; menghapus semua template tetap terhapus.
- **Skala teks.** Batas atas dinaikkan dari 1.3 ke 2.0, sehingga ukuran teks aksesibilitas sistem dihormati.
- **Nama file playlist.** Nama yang diketik kini dimasukkan ke template bernomor playlist, bukan diabaikan.
- **Ekspor cookie.** Cookie diambil dari URL yang benar-benar dimuat di WebView, bukan dari URL lain yang diketik tanpa dinavigasi.
- **Performa Wawasan.** Ringkasan di-cache berdasarkan revisi riwayat, bukan mengurutkan ulang seluruh pustaka pada setiap rebuild progres.
- **Lokalisasi.** Menambahkan metadata placeholder Bahasa Indonesia untuk pesan jumlah playlist dan cookie tersimpan; tes parity kini memeriksa metadata di kedua bahasa.

### Peningkatan

- **78 test lulus**, termasuk tes parity metadata ARB dua bahasa.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah. Android: `app-release.apk` (universal, untuk perangkat Android 64-bit). Windows: `Talos-v0.19.0-windows-x64.zip`. Linux: `Talos-v0.19.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24) ke atas, Windows 10, atau Linux dengan GTK3 terbaru.

## v0.18.0

Rilis keandalan dan performa. Rilis ini menangani kegagalan instalasi Android yang dilaporkan lewat verifikasi artefak di CI, dan membuat aplikasi lebih ringan serta lebih lancar tanpa menambah keluarga fitur baru.

### Perbaikan bug

- **Gabung Android.** Path ffmpeg yang diketik pengguna tidak lagi menonaktifkan penggabungan stream di Android. FFmpegKit selalu dipakai, sehingga unduhan tidak berakhir dengan dua file stream terpisah. Kolom path ffmpeg kini hanya ada di desktop.
- **Layanan latar depan.** Menghapus callback berulang 1 detik yang membangunkan isolate Dart selama setiap unduhan tanpa melakukan kerja.
- **Tombol Back native.** WebView cookie sekarang memakai Back untuk riwayat browser, dan Back perangkat keluar dari mode multi-seleksi Finished sebelum menutup layar.
- **Teks aksesibilitas.** Skala teks sistem dibatasi agar baris padat tidak meluap pada ukuran font sangat besar.

### Peningkatan

- **Keandalan instalasi.** CI sekarang memverifikasi setiap APK rilis dengan `apksigner` (tanda tangan v2 dan sertifikat Talos), memeriksa tidak ada library x86_64 yang masuk ke artefak arm64, memvalidasi alignment 16 KB, dan mencatat checksum SHA-256. README menjelaskan penyebab umum "paket tampaknya tidak valid" dan cara memverifikasi unduhan.
- **APK lebih kecil.** Mengaktifkan R8 dan resource shrinking dengan aturan keep untuk bridge Flutter, Chaquopy, dan FFmpegKit, serta obfuscation Dart dan split debug info. Ukuran rilis turun dari sekitar 66,8 MB menjadi 62,7 MB.
- **Startup lebih cepat.** Pengaturan, riwayat, tautan tersimpan, preset, level SDK Android, dan status SAF sekarang dimuat bersamaan, bukan berurutan.
- **Unduhan lebih lancar.** Daftar Finished menyimpan hasil urut/filter berdasarkan revisi riwayat, sehingga tick progres tidak lagi mengurutkan ulang hingga 300 entri. Shell membangun halaman sekali saja, bukan pada setiap rebuild.
- **Bundle lebih ringan.** Menghapus dependensi `cupertino_icons` yang tidak dipakai dan berhenti mengemas file teks lisensi sebagai aset aplikasi.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah. Android: `app-release.apk` (universal, untuk perangkat Android 64-bit). Windows: `Talos-v0.18.0-windows-x64.zip`. Linux: `Talos-v0.18.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24) ke atas, Windows 10, atau Linux dengan GTK3 terbaru.

## v0.17.0

Update besar yang menambahkan preset unduhan yang bisa dipakai ulang dan memperbaiki temuan kehilangan data, kebenaran, serta performa dari audit mendalam baru.

### Fitur baru

- **Preset unduhan.** Simpan pilihan Configure saat ini (mode video/audio, kualitas, format, bitrate, opsi subtitle dan metadata, selector format) sebagai preset bernama. Preset tersimpan lokal, bisa diterapkan sekali ketuk, diganti nama dengan menyimpan ulang, dan dihapus. Pengaturan global seperti folder, proxy, dan arsip sengaja tidak ditimpa.

### Perbaikan bug

- **Keamanan nama file playlist.** Nama file yang diketik tidak lagi diterapkan ke playlist, yang sebelumnya menulis semua entri ke path yang sama sehingga hanya file terakhir yang tersisa. Playlist dengan nama ketik sekarang memakai template judul bernomor.
- **Kejujuran pengaturan clip.** Kontrol rentang clip disembunyikan di Android dan iOS, tempat tidak ada ffmpeg yang bisa dipakai dan pengaturannya diam-diam diabaikan. Di desktop, dialog rentang sekarang menolak nilai bukan angka, negatif, dan terbalik alih-alih menyimpan nilai invalid.
- **Satuan clip dilokalisasi.** Label detik pada ringkasan clip sekarang memakai kunci terjemahan.
- **Reset lengkap.** "Reset semua data" sekarang juga menghapus tautan tersimpan dan preset, sesuai teks konfirmasinya.
- **Performa progres.** Notifikasi progres unduhan digabungkan maksimal 10 kali per detik, menghindari rebuild seluruh pohon widget pada setiap baris yt-dlp.
- **Tautan dan preset bersama.** Kedua store kini ada di manager aplikasi, sehingga penambahan, penghapusan, atau reset langsung diperbarui di semua layar.
- **Performa daftar besar.** Tautan tersimpan dan entri playlist sekarang memakai lazy list builder, bukan mengalokasikan semua baris pada setiap rebuild.
- **Pembersihan Wawasan.** Referensi messenger yang usang setelah penghapusan file tidak lagi melempar error jika layar ditutup.
- **Kontras oxblood.** Aksen oxblood tema gelap diterangkan agar memenuhi persyaratan kontras teks.
- **Keamanan tautan tersimpan.** Tombol bookmark sekarang mensyaratkan URL yang valid, dan membuka tautan tidak lagi melempar error pada teks invalid.
- **Keandalan tempel.** Kegagalan clipboard tidak lagi menghasilkan error async yang tidak tertangani.
- **Aksesibilitas bar.** Bar aktivitas sekarang mengumumkan tanggal lengkap dan jumlah, bukan huruf tunggal yang ambigu.

### Peningkatan

- **77 test lulus**, termasuk cakupan baru untuk penyimpanan preset dan wiring reset.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah. Android: `app-release.apk` (universal, untuk perangkat Android 64-bit). Windows: `Talos-v0.17.0-windows-x64.zip`. Linux: `Talos-v0.17.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24) ke atas, Windows 10, atau Linux dengan GTK3 terbaru.

## v0.16.0

Update besar yang menambahkan tautan tersimpan dan memperbaiki kebenaran perintah unduhan, target platform, serta akurasi data dari audit mendalam baru.

### Fitur baru

- **Tautan tersimpan.** Tandai URL saat ini dari kolom Home dengan tombol bookmark baru. Tautan tersimpan secara lokal, tampil di bagian "Tautan tersimpan", dan bisa dibuka di browser, diunduh langsung, atau dihapus. Seluruh batch yang ditempel ikut tersimpan, bukan hanya URL pertama, dan duplikat diabaikan.

### Perbaikan bug

- **Bagian unduhan clip.** Clip yang hanya punya awal atau akhir sekarang menghasilkan bagian yt-dlp `*start-awal-akhir` yang valid, bukan selector rusak yang selalu gagal. Flag hanya dikeluarkan saat ffmpeg tersedia, sehingga unduhan mobile tidak gagal karena pasca-pemrosesan yang tidak didukung.
- **Gating ffmpeg.** Konversi subtitle dan penghapusan bab SponsorBlock sekarang mengikuti ketersediaan ffmpeg, selaras dengan perlindungan embed subtitle dan metadata yang sudah ada.
- **Label waktu pemutar.** Durasi lebih dari satu jam tidak lagi menampilkan nilai seperti `1:62:05`.
- **Bar jenis Wawasan.** Proporsi audio sekarang dihitung dari ukuran audio sebenarnya, bukan `1 - proporsi video`, sehingga pustaka tanpa data ukuran tidak menampilkan bar audio penuh.
- **Tanggal aktivitas.** Pengelompokan hari memakai tanggal kalender UTC sehingga perubahan waktu musim panas tidak menggeser unduhan ke bar yang salah.
- **Minimum macOS.** Target deployment dikembalikan ke macOS 10.15 sesuai dokumentasi.
- **Linux ARM.** Unduhan sekarang memakai biner yt-dlp yang benar untuk Linux arm64 dan armv7, bukan yang x86_64.
- **Pemilihan format.** Format muxed tidak lagi ditawarkan sebagai stream video-murni, dan id format awal yang tidak dikenal tidak lagi dipaksa menjadi selector yang invalid.
- **Pembuat cookie.** Menyimpan cookie sekarang memvalidasi URL seperti saat memuat ulang, alih-alih diam-diam memakai situs bawaan.
- **Gabung Android.** Mengenali id format yt-dlp yang mengandung huruf, sehingga stream dari lebih banyak situs berhasil digabung.
- **UI tautan tersimpan.** Menambah atau menghapus tautan sekarang langsung membangun ulang layar Home.

### Peningkatan

- **76 test lulus**, termasuk cakupan baru untuk bagian clip, penyimpanan tautan, dan share Wawasan tanpa ukuran.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah. Android: `app-release.apk` (universal, untuk perangkat Android 64-bit). Windows: `Talos-v0.16.0-windows-x64.zip`. Linux: `Talos-v0.16.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24) ke atas, Windows 10, atau Linux dengan GTK3 terbaru.

## v0.15.0

Update besar yang dipimpin oleh tab Wawasan baru, dibarengi audit platform dan konkurensi terluas sejauh ini. Perbaikan mencakup native macOS, siklus hidup Android, antrean berurutan, dan penanganan file lintas platform.

### Fitur baru

- **Tab Wawasan.** Tab keempat merangkum pustaka selesai: total unduhan, total ukuran, dan jumlah 30 hari terakhir, grafik aktivitas 7 hari, rincian video/audio beserta favorit, lima unduhan terbesar, serta aksi pembersihan yang menghapus unduhan lebih tua dari 30 hari setelah konfirmasi. Semua angka berasal dari helper murni yang diuji.

### Perbaikan bug

- **Jaringan dan penyimpanan macOS.** Sandbox sekarang mendeklarasikan entanglement network-client dan akses baca-tulis Downloads, sehingga setup engine, pengecekan pembaruan, dan unduhan media berjalan di build macOS bertanda tangan.
- **Error setup engine.** Banner engine di Home sekarang menangkap kegagalan dan menampilkan satu pesan ramah, bukan error async yang tidak tertangani. iOS menampilkan pesan "belum tersedia" yang jelas tanpa tombol Pasang yang mustahil.
- **Jendela pembatalan.** Batal sekarang menghentikan unduhan setelah engine selesai tetapi sebelum penyalinan file dan penulisan riwayat. Batal saat pasca-pemrosesan tidak menulis baris riwayat, dan layanan latar depan berhenti saat tugas antre terakhir dibatalkan.
- **Sesi usang.** Run yang telah selesai tidak lagi menghapus referensi sesi unduhan yang lebih baru setelah reset dan antre ulang.
- **Batal perintah kustom.** Membatalkan perintah kustom sekarang menghentikan proses OS dan melaporkan kode keluar bukan nol, alih-alih membiarkan yt-dlp tetap berjalan.
- **Race startup Chaquopy.** Inisialisasi runtime Python kini tersinkronisasi, sehingga handler bersamaan tidak bisa memulainya dua kali.
- **Event engine terminal.** Android menampung event yang muncul di antara langganan Dart dan memutarnya ulang, sehingga unduhan cepat tidak mengunci antrean.
- **Ketahanan pengaturan SAF.** Error native sesaat tidak lagi menghapus folder unduhan yang dipilih pengguna.
- **Tulis atomik Windows.** Penyimpanan pengaturan dan riwayat sekarang mengganti file yang ada secara atomik di Windows, bukan diam-diam jatuh ke tulis biasa.
- **Reset lengkap.** Reset semua data sekarang mengembalikan folder unduhan bawaan.
- **Langganan intent.** Layar Home yang dibuang tidak lagi membocorkan langganan share-intent, dan bagikan saat aplikasi berjalan tetap berfungsi jika pencarian tautan awal gagal.
- **Path Android lama.** API 24-28 sekarang mengembalikan path absolut biasa, sehingga file bisa dibuka, dibagikan, dan dihapus lewat UI.
- **Ekstensi file SAF.** File yang disalin mempertahankan nama lengkapnya sehingga tidak kehilangan ekstensi.
- **Pemilih folder.** Pemilihan kedua tidak lagi membiarkan permintaan pertama menggantung.
- **Prompt izin.** Flag "sudah diminta" kini disimpan hanya setelah permintaan benar-benar dikirim.
- **Timeout pengecekan update.** Body rilis yang mandek tidak lagi menggantung pengecekan update.
- **Lokalisasi.** Menambahkan pesan engine iOS dan memperbarui string Bahasa Indonesia yang tersisa.

### Peningkatan

- **73 test lulus**, termasuk cakupan baru untuk agregasi wawasan.
- **Helper hapus bersama** dipakai oleh hapus banyak di Finished dan pembersihan Wawasan.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah. Android: `app-release.apk` (universal, untuk perangkat Android 64-bit). Windows: `Talos-v0.15.0-windows-x64.zip`. Linux: `Talos-v0.15.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24) ke atas, Windows 10, atau Linux dengan GTK3 terbaru.

## v0.14.0

Update besar yang dipimpin oleh intro beranimasi halus, dibarengi audit mendalam lain yang menutup temuan pada alur unduhan, pengaturan, dan pemutar.

### Fitur baru

- **Intro beranimasi.** Reveal brand singkat saat aplikasi dibuka: helm muncul dengan skala dan fade halus disertai halo lembut, wordmark naik, garis progres perunggu tergambar, lalu seluruh adegan memudar ke aplikasi. Ketuk di mana saja untuk melewati. Pengguna reduced-motion melihat versi statis dan instan. Waktu memakai motion token bersama.
- **Splash native mengikuti tema.** Latar peluncuran Android sekarang mengikuti tema sistem, sehingga pengguna tema terang tidak melihat kilatan gelap sebelum aplikasi terbuka. Mark helm yang sama dipakai di splash native dan intro.

### Perbaikan bug

- **Switch embedding subtitle.** Toggle di Configure sekarang benar-benar mengontrol `--embed-subs`; subtitle tidak lagi selalu disematkan di desktop atau tidak pernah di Android.
- **Batal saat startup.** Mengetuk Batal saat izin atau probing ffmpeg masih berjalan sekarang menghentikan unduhan, alih-alih diabaikan. Reset juga menghentikan tugas yang sedang berjalan sebelum sempat menulis riwayat.
- **Folder perintah kustom.** Folder output yang dikonfigurasi sekarang diteruskan ke perintah kustom sebagai direktori kerja.
- **Fetch satu tautan.**Menempelkan tautan dengan teks di sekitarnya atau tanda baca di akhir sekarang memakai URL yang diekstrak, sama seperti mode batch.
- **Error lebih jelas.** Kegagalan setup engine menampilkan satu pesan ramah, bukan error mentah plus duplikat. Kegagalan penyimpanan kini dilokalisasi, bukan bahasa Inggris yang tertanam.
- **Tampilan rentang clip.** Rentang yang hanya punya waktu akhir tidak lagi menampilkan "null detik".
- **Filter format audio.** Format muxed video+audio tidak lagi tercantum sebagai audio-murni, yang sebelumnya menghasilkan selector unduhan yang tidak valid.
- **Keamanan seleksi.** Mengubah pencarian atau filter sekarang menghapus multi-seleksi, sehingga hapus banyak tidak menyentuh entri yang tidak lagi terlihat.
- **Ketahanan pengaturan.** Nilai dropdown yang usang atau diedit manual dinormalisasi saat dimuat, mencegah crash di layar Pengaturan.
- **Fallback tautan.** Tombol Download pada pembaruan sekarang menyalin URL dan menampilkan pesan jika tidak ada browser.
- **Bersihkan pemutar.** Gagal initialize/play sekarang membuang controller, dan kontrol tidak lagi rebuild dua kali per update posisi.
- **Race share-intent.** Tautan yang dibagikan saat cold start kini ditampung native dan diputar ulang setelah Dart berlangganan, sehingga tidak hilang.

### Peningkatan

- **String belum diterjemahkan.** Frasa bahasa Inggris yang tersisa di Bahasa Indonesia diterjemahkan, dan layar About sekarang menandai aria2 sebagai alat eksternal opsional.
- **Chrome konsisten.** Navigation rail (layout lebar) sekarang memakai warna tema; tanda centang swatch aksen menyesuaikan kecerahan tiap aksen.
- **72 test lulus**, termasuk cakupan baru untuk embedding subtitle dan normalisasi pengaturan.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah. Android: `app-release.apk` (universal, untuk perangkat Android 64-bit). Windows: `Talos-v0.14.0-windows-x64.zip`. Linux: `Talos-v0.14.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24) ke atas, Windows 10, atau Linux dengan GTK3 terbaru.

## v0.13.0

Fokus stabilitas dan desain untuk fitur yang sudah ada di Talos. Tidak ada keluarga fitur baru: rilis ini memperbaiki temuan audit mendalam dan membuat layar yang ada lebih rapi serta lebih mudah dipakai.

### Perbaikan bug

- **Perintah kustom.** Menjalankan template tidak lagi mengulang perintah selamanya saat selesai. Ada aksi Batal saat perintah berjalan, dan text controller dialog dibuang.
- **Urutan antrean.** Unduhan sekarang dimulai sesuai urutan yang terlihat di tab Active, sehingga tarik-urut benar-benar berpengaruh.
- **Mengosongkan pengaturan.** Folder video, folder audio, folder perintah kustom, dan rentang clip sekarang bisa dikosongkan dan tetap kosong.
- **Reset semua data.** Reset sekarang membatalkan unduhan aktif, menghapus tugas yang antre atau gagal, dan mencegah unduhan yang sedang berjalan menulis baris riwayat baru.
- **Unduhan batch.** Pengaturan arsip dan rentang clip sekarang ikut diterapkan di mode batch, sama seperti unduhan tunggal.
- **Umpan balik tautan.** Mengetuk tautan tanpa aplikasi pembuka sekarang menyalin URL dan menampilkan pesan, alih-alih tidak melakukan apa pun.
- **Label tema gelap.** Label segmen format kembali mewarisi tema aplikasi alih-alih tampil hitam.
- **Lokalisasi.** Menghapus string bahasa Inggris yang tertanam di Format selection, Player, About, dan Settings, serta memperbaiki teks error FFmpeg Android.

### Peningkatan

- **Penekanan navigasi.** Tab yang aktif sekarang memakai warna aksen untuk ikon dan label di kedua tema.
- **Tata letak tab Finished.** Pencarian punya baris penuh tersendiri dengan hint yang terlihat lengkap; Favorites, filter jenis, dan urutan berada di baris kedua yang ringkas.
- **Pemilih tema.** Selektor tema sekarang penuh lebar sehingga ketiga opsi muat di layar kecil.
- **Area sentuh.** Swatch aksen dan gagang tarik sekarang punya area sentuh 48dp dengan label aksesibilitas.
- **Kontrol konsisten.** Tombol, dialog, indikator progres, dan switch sekarang memakai satu tema. Crop artwork memakai switch selebar baris.
- **70 test lulus.** Menambah cakupan untuk urutan antrean dan pengosongan pengaturan.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah. Android: `app-release.apk` (universal, untuk perangkat Android 64-bit). Windows: `Talos-v0.13.0-windows-x64.zip`. Linux: `Talos-v0.13.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24) ke atas, Windows 10, atau Linux dengan GTK3 terbaru.

## v0.12.0

Update fokus kontrol untuk pustaka Finished. Urutkan, filter, dan bersihkan unduhan selesai tanpa meninggalkan tab.

### Fitur baru

- **Urutkan unduhan selesai.** Buka menu urutkan di tab Finished untuk mengurutkan entri berdasarkan Terbaru, Terlama, Terbesar, Terkecil, atau Judul A-Z. Pengurutan ukuran menganggap entri tanpa ukuran yang diketahui sebagai nol.
- **Filter menurut jenis.** Menu jenis mengganti daftar Finished antara Semua, Video, dan Audio. Filter ini digabung dengan chip Favorites dan kotak pencarian.
- **Hapus banyak.** Tahan lama entri selesai untuk masuk mode pilih, tekan entri lain untuk menambahnya, lalu gunakan Pilih semua atau Hapus yang dipilih. Penghapusan menghapus file dan baris riwayatnya setelah satu konfirmasi.

### Peningkatan

- **68 test lulus.** Menambah cakupan untuk semua mode urutan, penghapusan riwayat banyak, baris riwayat rusak, dan keluaran progres yang malformed.
- **Audit mendalam.** Memperbaiki anomali yang ditemukan pada setup engine, penanganan antrean, pengaturan, dan daftar Finished.

### Perbaikan bug

- **Setup engine Windows.** Setup FFmpeg sekarang membaca checksum terbaru untuk build rolling latest, bukan hash tetap yang basi setiap rilis, dan Update Engine mengganti binary yang ada alih-alih gagal di Windows.
- **Ketahanan riwayat.** Satu baris tersimpan yang rusak tidak lagi menghilangkan seluruh daftar selesai saat startup.
- **Unduhan batch.** Mode batch sekarang menerapkan proxy, cookies, kualitas, dan pengaturan transfer lain yang dikonfigurasi, alih-alih membuangnya diam-diam.
- **Keamanan antrean.** Kegagalan memulai engine Android tidak lagi mengunci antrean, dan membatalkan tugas yang tidak aktif tidak lagi menghentikan unduhan yang sedang berjalan.
- **Parsing progres.** Angka yang rusak pada keluaran yt-dlp tidak lagi melempar error di listener progres.
- **Bersihkan pengaturan.** Menghapus entri Subtitle language yang dobel dan membuang text controller dialog.

### Download / Instalasi

Download file sesuai platformmu dari Assets di bawah. Android: `app-release.apk` (universal, untuk perangkat Android 64-bit). Windows: `Talos-v0.12.0-windows-x64.zip`. Linux: `Talos-v0.12.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24) ke atas, Windows 10, atau Linux dengan GTK3 terbaru.

## v0.11.0

Rilis identitas baru yang dipimpin oleh mark helm Talos, plus upgrade kecil tapi berguna di daftar Finished.

### Fitur baru

- **Identitas baru.** Project sekarang memakai helm perunggu di atas tile gelap, menggantikan simbol mata sebelumnya. Logo, ikon aplikasi, layar pembuka, dan aset README semuanya diperbarui.
- **Unduhan favorit.** Di tab Finished, setiap entri sekarang punya ikon bintang di samping menu. Tekan untuk menandai atau mencabut favorit. Chip "Favorites" memfilter daftar hanya ke entri yang kamu tandai.

### Peningkatan

- **Aset native konsisten.** Ikon Android, iOS, macOS, Windows, dan Linux semuanya merender mark baru dari sumber SVG yang sama.

### Download / Instalasi

Download file untuk platformmu dari Assets di bawah. Android: `app-release.apk` (universal, untuk perangkat Android 64-bit). Windows: `Talos-v0.11.0-windows-x64.zip`. Linux: `Talos-v0.11.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24) ke atas, Windows 10, atau Linux dengan GTK3 terbaru.

## v0.10.0

Rilis ini membuat Talos lebih pintar saat bekerja dengan banyak link sekaligus dan membantu pemulihan download yang macet.

### Fitur baru

- **Batch fetch.** Tempel beberapa link di kolom input lalu tap Fetch all; Talos mengekstrak satu per satu dan memasukkan ke antrian dengan pengaturan default kamu. Pilih Video 720p atau Audio MP3 192k di dialog. Label tombol berubah ke "Fetch all" secara otomatis.
- **Retry all untuk task gagal.** Tab Active menampilkan tombol "Retry all" di atas daftar kalau ada task yang gagal atau dibatalkan, sehingga kamu bisa memasukkan ulang semuanya dengan sekali tap.

### Peningkatan

- **Clipboard auto-fill menangani banyak link.** Kalau beberapa URL ada di clipboard, semuanya ditempel ke field siap untuk batch fetch.
- **63 test lulus.**

### Download / Instalasi

Download file untuk platformmu dari Assets di bawah. Android: `app-release.apk` (universal, untuk perangkat Android 64-bit). Windows: `Talos-v0.10.0-windows-x64.zip`. Linux: `Talos-v0.10.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24) ke atas, Windows 10, atau Linux dengan GTK3 terbaru.

## v0.9.0

Rilis reliabilitas dan fitur untuk power-user: antrian download sekarang bisa diurutkan, kegagalan merge terbaca sebagai error sungguhan, dan satu tombol menghapus semua data Talos untuk memulai bersih.

### Fitur baru

- **Geser untuk mengurutkan Active queue.** Task yang menunggu bisa dinaikkan atau diturunkan agar download berikutnya mulai lebih cepat.
- **Deteksi link di clipboard.** Saat Talos dibuka dan kolom link kosong, URL yang ditemukan di clipboard langsung ditempel otomatis supaya bisa langsung diambil.
- **Reset di Danger zone.** Pengaturan > Danger zone > Reset all data menghapus pengaturan, riwayat unduhan selesai, template perintah khusus, dan shortcut folder SAF, meninggalkan Talos dalam keadaan bersih.

### Perbaikan bug

- **Kegagalan merge saat Android menampilkan sebagai sukses.** Baris `[Merger] Merge failed` sekarang diparse sebagai error, sehingga penggabungan video+audio yang rusak tampil sebagai task gagal dengan pesan yang jelas alih-alih entri "selesai" dengan file yang tidak bisa diputar.

### Peningkatan

- **Tidak ada API usang.** Active list sekarang memakai callback `onReorderItem` yang baru.
- **63 test lulus.**

### Download / Instalasi

Download file untuk platformmu dari Assets di bawah. Android: `app-release.apk` (universal, untuk perangkat Android 64-bit). Windows: `Talos-v0.9.0-windows-x64.zip`. Linux: `Talos-v0.9.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24) ke atas, Windows 10, atau Linux dengan GTK3 terbaru.

## v0.8.0

Rilis fitur terbesar sejauh ini: Talos sekarang bisa memutar unduhan langsung di dalam aplikasi, dan tab Finished bisa dicari plus punya thumbnail.

### Fitur baru

- **Pemutar bawaan.** Unduhan yang sudah selesai terbuka di pemutar dalam aplikasi: play/pause, slider seek, tombol mundur 10 detik, dan tombol maju 30 detik. Berfungsi untuk video maupun audio. Kalau file tidak bisa diputar di dalam aplikasi, kamu masih bisa membukanya dengan pemutar sistem.
- **Cari unduhan selesai.** Tab Finished punya kolom pencarian yang memfilter berdasarkan judul video, nama channel, atau URL.
- **Thumbnail di Finished.** Unduhan yang tercatat mulai sekarang menampilkan thumbnail videonya.

### Perbaikan bug

- **Instalasi baru bisa dianggap "tidak merespons" saat dialog izin muncul selama cold start.** Dialog izin sekarang menunggu sampai frame pertama selesai tampil, jadi aplikasi tidak pernah memblokir input saat dialog menunggu jawabanmu.
- **Entri selesai dengan content URI tidak bisa dibuka.** Handler Android asli dipakai untuk content URI, jadi buka dan bagikan berfungsi untuk file yang tersimpan lewat MediaStore maupun folder SAF.

### Peningkatan

- **Riwayat menyimpan thumbnail** untuk unduhan selesai mulai sekarang. Entri lama tetap memakai ikon generik.

### Download / Instalasi

Download file untuk platformmu dari Assets di bawah. Android: `app-release.apk` (universal, untuk perangkat Android 64-bit). Windows: `Talos-v0.8.0-windows-x64.zip`. Linux: `Talos-v0.8.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24) ke atas, Windows 10, atau Linux dengan GTK3 terbaru.

## v0.7.0

Rilis reliabilitas: unduhan sekarang langsung tersimpan di folder publik Downloads/Talos secara default, dan video yang sama bisa diunduh berkali-kali tanpa batas.

### Fitur baru

- **Download publik secara default.** Unduhan baru tersimpan ke Downloads/Talos di ponsel kamu, terlihat oleh file manager dan semua aplikasi media. Di Android 10 ke atas, Talos menulis lewat MediaStore, jadi tidak butuh izin penyimpanan. Di Android lebih lama, Talos meminta sekali izin penyimpanan warisan saat aplikasi pertama dibuka.
- **Download video yang sama selamanya.** Talos tidak lagi melewati unduhan hanya karena file sudah ada. Setiap unduhan ulang berjalan lagi dan disimpan dengan suffix baru tepat setelah judul, misalnya `Big Buck Bunny(1).mkv` dan `Big Buck Bunny(2).mkv`. Penomoran berlaku di mana pun: nama lokal, di dalam folder SAF, dan di folder publik Downloads. Tidak ada yang pernah ditimpa.
- **Permintaan izin penyimpanan dan notifikasi saat instalasi pertama.** Aplikasi yang baru dipasang langsung meminta yang dibutuhkan: akses notifikasi di Android 13 ke atas, dan akses penyimpanan warisan di Android 9 ke bawah.

### Perbaikan bug

- **Unduhan berulang bisa selesai dengan hasil kosong tanpa peringatan.** Jika file tujuan sudah ada, yt-dlp melewati unduhan dan aplikasi tetap melaporkan sukses. Talos sekarang memilih nama unik sebelum setiap unduhan dimulai, jadi unduhan berulang selalu menghasilkan file lengkap.
- **Entri selesai tidak bisa dibuka atau dibagikan.** File dari versi sebelumnya bisa berakhir di path pribadi atau tidak terjangkau. Sekarang file disimpan di folder publik, dan membuka atau membagikan entri selesai memakai handler Android asli untuk content URI alih-alih gagal diam-diam.
- **Folder SAF bisa menimpa file dengan nama yang sama.** Talos sekarang membuat `nama(N).ext` unik alih-alih memakai ulang entri yang ada.
- **Ukuran file di Riwayat tidak tercatat dengan benar.** Ukuran sekarang diukur sebelum file dipindahkan ke folder tujuannya.

### Peningkatan

- **Pengaturan > Downloads lebih eksplisit.** Tile lokasi sekarang bertuliskan "Unduhan (default)" dengan penjelasan lengkap, dan tombol Ubah memilih folder kustom. Kembalikan ke default kapan saja.
- **Terverifikasi end-to-end.** Alur instalasi baru, unduhan ulang tanpa batas, dan penyalinan ke folder publik dicakup test unit dan diverifikasi di emulator, termasuk membuka file selesai di pemutar bawaan.

### Download / Instalasi

Download file untuk platformmu dari Assets di bawah. Android: `app-release.apk` (universal, untuk perangkat Android 64-bit). Windows: `Talos-v0.7.0-windows-x64.zip`. Linux: `Talos-v0.7.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24) ke atas, Windows 10, atau Linux dengan GTK3 terbaru.

## v0.6.0

Rilis reliabilitas dan polesan: mengganti nama unduhan tidak lagi berisiko menghasilkan file rusak, dan seluruh UI dirapikan agar konsisten.

### Fitur baru

- **Ganti nama sebelum download.** Layar Configure sekarang punya kolom File name. Ketik nama file output beserta ekstensinya (misalnya `Video Saya.mp4`) untuk mengganti nama unduhan. Kosong berarti nama otomatis berdasarkan judul.
- **Penanganan duplikat otomatis.** Kalau nama file yang kamu ketik sudah ada di folder output, Talos menulis `nama (1).ext` alih-alih menimpa atau gagal. Dedupe yang sama berlaku saat aplikasi menggabungkan stream video dan audio di dalam app, jadi unduhan berulang dengan nama sama tidak akan berakhir sebagai file rusak.

### Peningkatan

- **Audit konsistensi UI.** Semua heading section memakai satu widget bersama, skala spacing dinormalkan, dan empty state disatukan. Layar Downloads menampilkan tombol Go to Home saat kosong, Fetch tetap nonaktif sampai kamu mengisi link, dan titik accent color tampil benar di mode light dan dark.
- **Kerapian changelog.** Menghapus baris ganda di section v0.5.0.

### Download / Instalasi

Download file untuk platformmu dari Assets di bawah. Android: `app-release.apk` (universal, untuk perangkat Android 64-bit). Windows: `Talos-v0.6.0-windows-x64.zip`. Linux: `Talos-v0.6.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24) ke atas, Windows 10, atau Linux dengan GTK3 terbaru.

## v0.5.0

Rilis fitur audit plus: sekarang kamu bisa cek apakah ada versi terbaru dari dalam app, plus beberapa perbaikan audit.

### Fitur baru

- **Cek versi terbaru.** Halaman About sekarang punya tombol "Check for updates" yang mengambil data rilis dari GitHub. Kalau ada versi baru, langsung link ke halaman download. Kalau kamu sudah di versi terbaru, akan muncul pesan bahwa kamu sudah up-to-date.

### Perbaikan bug

- **Batalkan picker storage tidak pernah me-release pending result.** Jika system folder picker dibatalkan, app akan menunggu selamanya untuk result yang tidak pernah datang. Sekarang langsung return, dan tombol picker bisa dipakai lagi.
- **Download jatuh ke private storage tanpa peringatan saat SAF gagal.** Task sekarang di-tag Failed dengan pesan yang jelas agar user pilih lokasi ulang atau clear SAF folder.
- **File dan folder open intent silent tidak bekerja di Android 10+.** Aplikasi tidak lagi meng-gate intent dengan `canLaunchUrl` (yang selalu mengembalikan false di Android 10+); sekarang langsung launch dan tampilkan snackbar error kalau gagal.

### Peningkatan

- **Audit translation.** Sekarang ada test yang memastikan app_en.arb dan app_id.arb memiliki set key yang sama.
- **Metadata placeholder.** Metadata placeholder ARB juga divalidasi supaya placeholder masuk dalam ARB terdaftar dengan benar.

### Download / Instalasi

Download file untuk platformmu dari Assets di bawah. Android: `app-release.apk` (universal, untuk perangkat Android 64-bit). Windows: `Talos-v0.5.0-windows-x64.zip`. Linux: `Talos-v0.5.0-linux-x64.tar.gz`. Build macOS belum diterbitkan; build dari source. Membutuhkan Android 7.0 (API 24) ke atas, Windows 10, atau Linux dengan GTK3 terbaru.

## v0.4.0

Rilis quality-of-life: kamu bebas memilih folder penyimpanan, tab Finished menampilkan dan membuka path file sungguhan, dan format diberi indikator rekomendasi dari sumber.

### Fitur baru

- **Picker folder storage di Android (SAF).** Pengaturan > Download > Pick folder membuka picker sistem. Pilih folder mana pun yang bisa di-write (misalnya Download > Talos), dan setiap unduhan barumu akan masuk ke <folder><pemisah>Talos. Clear untuk kembali ke storage internal app.
- **Format rekomendasi.** Di picker format, video rekomendasi platform (resolusi tertinggi, prioritas MP4/H.264) dan audio rekomendasi (bitrate tertinggi, prioritas M4A/AAC) ditandai dengan awalan bintang. Resolusi video tertinggi tampil paling atas.
- **Halaman Sponsor.** Halaman Tentang sekarang mencantumkan author GitHub dan link Sponsor: GitHub Sponsors, Saweria, SociaBuzz dan BagiBagi.
- **Tab Finished menampilkan path file.** Setiap entry menampilkan path, membuka file dengan aplikasi default, menyalin path folder di Android, dan tetap menampilkan aksi open/share/remove/delete.
- **Hapus file langsung.** Menu long-press dapat menghapus history node dan file hasil download dalam satu tap. Sebelumnya "bersihin selesai" hanya membersihkan list; sekarang tersedia tombol "Hapus file" yang langsung terlihat per entry.

### Peningkatan

- **History langsung refresh.** Membersihkan tab selesai, menghapus daftar, dan menghapus file langsung memperbarui tab Finished; sebelumnya bisa tertinggal sampai event lain memicu rebuild.
- **Picker folder via SAF.** Grant SAF divalidasi saat app start; grant basi di-discard daripada menyebabkan unduhan diam-diam gagal ke storage internal.

## v0.3.0

Peningkatan engine: unduhan YouTube di Android kini bisa menghasilkan kualitas jauh lebih tinggi lewat penggabungan di dalam aplikasi, plus perbaikan cold-start, stabilitas, dan lisensi.

### Fitur baru

- **FFmpeg tertanam di Android.** Talos kini menggabungkan stream video dan audio yang yt-dlp unduh terpisah, jadi build embedded tidak lagi terjebak pada format muxed ~360p. Stream hingga 720p60+ tersedia lewat DASH dengan URL langsung dan digabung di dalam app.
- **Auto-pick codec terbaik.** Dengan penggabungan tersedia, Android memilih stream DASH terbaik yang sama seperti desktop, sehingga batas kualitas benar-benar hilang.

### Peningkatan

- **Cold start lebih ringan.** Warm-up Python kini berjalan di background thread saat engine di-attach, bukan dipicu oleh status check paksa. Status tidak lagi langsung men-start Python.
- **Paket debug mendukung dua ABI.** Debug build mencakup arm64-v8a dan x86_64 untuk verifikasi emulator terperinci; release hanya arm64-v8a.

### Lisensi

- **FFmpegKit (LGPL-3.0, dynamic linkage)** diperlukan untuk menggabungkan stream. Talos tidak melakukan static link ke FFmpeg dan tidak menyertakan encoder GPL.

## v0.2.3

Rilis stabilitas dan engine: perbaikan pemilihan format yang membuka jalan unduhan YouTube di Android, plus serangkaian perbaikan ketahanan.

### Perbaikan bug

- **Unduhan video YouTube di Android gagal dengan "Requested format is not available".** YouTube tidak mengembalikan format muxed pada client bawaan, dan Android tidak punya FFmpeg untuk menggabungkan stream, jadi tidak ada yang bisa dipilih. Build embedded kini mematok client yang masih menyediakan MP4 muxed (hingga 360p) untuk mode video; mode audio tidak berubah.
- **Desktop engine bisa kehilangan baris output terakhir.** Stream stdout dan stderr kini di-drain sebelum sesi selesai, sehingga output path dan baris progres tidak lagi hilang saat keluar.
- **Retry mengabaikan folder video atau audio terpisah.** Retry kini menargetkan folder sesuai jenis media yang dikonfigurasi, bukan folder bawaan.
- **Pengaturan, history dan template perintah bisa rusak setengah jalan.** Penulisan kini atomic; crash di tengah menulis tidak lagi merusak file-file ini.
- **File cookie export bisa dibaca siapa pun di POSIX.** File cookies kini owner-only dan ditulis secara atomic.

### Peningkatan

- **Font bundled.** Marcellus dan Inter masuk ke dalam aplikasi, tidak lagi diambil dari jaringan saat peluncuran pertama. Startup lebih cepat dan bisa offline.
- **Memori lebih rendah saat mengunduh engine.** Unduhan yt-dlp dan FFmpeg terkelola mengalir ke disk alih-alih memuat puluhan megabyte di memori.
- **Sapuan i18n.** Semua teks yang tampil kini berasal dari file lokalisasi; tidak ada string yang tertinggal.
- **iOS tidak lagi crash saat start.** Engine melapor belum tersedia sampai backend iOS dibuat.

## v0.2.2

Rilis perbaikan bug. Tidak ada fitur baru.

### Perbaikan bug

- **Pengunduhan Android gagal di setiap percobaan.** Engine tertanam tidak lagi meneruskan objek Java ke Python; baris output di-buffer dan di-polling oleh host, dan error engine kini membawa pesan yt-dlp yang sebenarnya.
- **UI Pengaturan memperbarui dengan delay.** Mengubah pengaturan kini langsung menggambar ulang layar dan UI terkait.
- **Versi yang salah dilaporkan.** Aplikasi melaporkan 0.1.0 di setiap rilis; kini melaporkan versi sebenarnya, dan sebuah test menjaga sinkronisasi pubspec.yaml dan layar Tentang.
- **Crash saat membuka di iOS.** Aplikasi tidak lagi crash saat dijalankan di iOS; engine melapor belum tersedia sampai backend iOS dibuat.

## v0.2.1

Polish lanjutan dari fitur v0.2.0: toggle notifikasi persisten, penanganan subtitle yang lebih lengkap, dan pilihan channel untuk engine terkelola.

### Fitur baru

- **Toggle notifikasi.** Matikan notifikasi foreground selama unduhan tanpa menghentikan unduhan.
- **Kontrol subtitle.** Aktifkan subtitle otomatis, simpan file subtitle terpisah, dan konversi ke format lain.
- **Channel engine.** Pilih rilis stabil atau nightly yt-dlp untuk update terkelola. Tersedia juga untuk auto update.
- **Folder perintah kustom.** Direktori khusus untuk output dari template perintah kustom.

## v0.2.0

Rilis ini menutup gap fitur utama dengan aplikasi serupa: pemilihan format manual, cookie generator di dalam aplikasi, log engine per tugas, dan folder output terpisah.

### Fitur baru

- **Pemilihan format manual.** Pilih format video dan audio per unduhan dengan detail codec, bitrate, resolusi dan ukuran lengkap.
- **Cookie generator di dalam aplikasi.** Masuk ke situs di WebView tertanam lalu simpan cookies sesi untuk yt-dlp. Berjalan di Android dan iOS.
- **Log tugas.** Setiap tugas gagal menyimpan hingga 500 baris output engine mentah, dengan tombol salin sekali ketuk untuk laporan bug.
- **Arsip unduhan.** Lewati item yang sudah pernah diunduh lewat file arsip persisten.
- **Crop sampul album.** Sampul bujur sangkar untuk berkas audio, diminta oleh Android Auto dan pemutar musik.
- **Urutan format.** String `-S` yt-dlp untuk memprioritaskan ekstensi dan resolusi, misal `ext,res`.
- **Remux ke mp4, mkv atau webm.** Pilih wadah output tanpa re-encoding.
- **Klip video.** Unduh hanya sebagian video dengan waktu mulai dan berakhir.
- **Ukuran file maksimal.** Lewati item yang melebihi batas, misal `50M`.
- **Folder video dan audio terpisah.** Direktori unduhan khusus untuk tiap jenis media.
- **Update engine otomatis.** Cek engine mingguan di latar belakang, aktifkan di Pengaturan.
- **User-Agent kustom.** Ganti header User-Agent HTTP untuk situs yang membutuhkannya.

### Peningkatan

- **Penataan ulang SponsorBlock dan cookies.** Opsi tersebut sekarang ditempatkan di bagian yang sesuai, dengan teks penjelas.

### Perbaikan bug

- **Tombol log** pada tugas gagal sekarang membuka output engine, bukan potongan satu baris.

## v0.1.1

Perilaku bawaan yang lebih baik: setup engine otomatis, FFmpeg terkelola di Windows, error yang lebih jelas, dan APK lebih kecil (45 MB, arm64-v8a).

### Fitur baru

- **Setup engine otomatis.** Menekan Ambil saat engine belum terpasang akan mengunduh yt-dlp (dan FFmpeg di Windows) lalu mengambil data.
- **FFmpeg terkelola di Windows.** FFmpeg diunduh otomatis dengan verifikasi SHA-256, sehingga penyematan metadata, thumbnail dan subtitle bekerja tanpa setup manual.
- **Notifikasi persisten.** Notifikasi ditampilkan selama download berlangsung dan hilang saat antrean kosong.

### Peningkatan

- **APK lebih kecil.** Build rilis hanya untuk arm64-v8a, menyusutkan APK dari sekitar 80 MB menjadi 45 MB.

### Perbaikan bug

- **Unduhan tidak lagi gagal tanpa penjelasan.** Error engine yang umum (403, bot check, video privat, siaran langsung, FFmpeg hilang) tampil sebagai pesan yang bisa dibaca, bukan output Python mentah.
- **Aksi file di Android.** Membuka file hasil unduhan lewat share sheet di Android; desktop tetap punya Buka dan Lihat di folder.
- **Teks error lebih panjang** (hingga tiga baris) dan mengetuk error menyalinnya ke papan klip untuk bantuan/dukungan.
- **Prioritas FFmpeg terkelola.** FFmpeg terkelola di Windows dipilih lebih dulu dari PATH sistem.

## v0.1.0

Rilis pertama Talos, pengunduh video dan audio untuk Android, iOS, Windows, macOS dan Linux.

### Fitur baru

- **Unduhan video dan audio.** Unduh dari situs yang didukung yt-dlp, sebagai video sampai 2160p atau audio sebagai MP3, M4A, Opus, FLAC atau format asli.
- **Dukungan playlist.** Pemilihan per entri dengan pilih semua atau tidak sama sekali, dan progres per item selama unduh.
- **Penyematan metadata dan thumbnail.** Sematkan judul, artis, sampul album dan metadata lain ke file yang diunduh di desktop dengan FFmpeg, termasuk sampul di file audio.
- **Penyematan subtitle.** Sematkan subtitle ke video yang diunduh dengan bahasa yang bisa dipilih.
- **SponsorBlock.** Hapus segmen sponsor, self-promo dan lainnya per kategori.
- **File cookies.** Unduh dari situs yang butuh login dengan file cookies.txt.
- **Proxy, batas kecepatan, fragment konkuren dan aria2c.** Opsi untuk unduhan berat dan jaringan yang rapuh.
- **Perintah kustom.** Jalankan yt-dlp dengan template argumen buatanmu sendiri, dikelola di dalam aplikasi.
- **Layar Downloads.** Antrean berurutan dengan batal dan coba lagi, kecepatan dan ETA, serta riwayat unduhan selesai dengan ukuran dan tanggal.
- **Mode privat.** Lewati riwayat sama sekali bila diinginkan.
- **Mesin Android.** yt-dlp berjalan in-process lewat Chaquopy, dengan foreground service yang menjaga unduhan tetap hidup dan share-to-Talos dari aplikasi lain.
- **Mesin desktop.** yt-dlp diunduh sekali dan dikelola oleh aplikasi, atau memakai yt-dlp sistem, dengan deteksi FFmpeg otomatis.
- **Desain gelap hangat.** Tema gelap hangat dengan aksen perunggu, mode terang dan mengikuti sistem, lima warna aksen, antarmuka dwibahasa (English dan Bahasa Indonesia).
- **Merek Talos.** Mark orisinal, app icon untuk Android, iOS, Windows dan macOS, serta splash screen gelap.
- **Continuous integration.** Analyze, test dan build di setiap push dan pull request.
