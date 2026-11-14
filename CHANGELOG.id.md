# Changelog

Semua perubahan penting pada proyek ini didokumentasikan di file ini.

Format mengikuti [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versi terbaru ada di atas.

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
