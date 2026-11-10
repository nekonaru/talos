# Changelog

Semua perubahan penting pada proyek ini didokumentasikan di file ini.

Format mengikuti [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versi terbaru ada di atas.

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
