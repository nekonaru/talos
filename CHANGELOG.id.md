# Changelog

Semua perubahan penting pada proyek ini didokumentasikan di file ini.

Format ini mengikuti [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
dan proyek ini mematuhi [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-11-09

### Added

- **Unduhan video dan audio** dari situs yang didukung yt-dlp, sebagai video sampai 2160p atau audio sebagai MP3, M4A, Opus, FLAC atau format asli.
- **Dukungan playlist** dengan pemilihan per entri, pilih semua atau tidak sama sekali, dan progres per item selama unduh.
- **Penyematan metadata dan thumbnail** ke file yang diunduh di desktop dengan FFmpeg, termasuk sampul di file audio.
- **Penyematan subtitle** dengan bahasa yang bisa dipilih ke video yang diunduh.
- **SponsorBlock** untuk menghapus segmen sponsor, self-promo dan lainnya per kategori.
- **File cookies** untuk situs yang butuh login.
- **Proxy, batas kecepatan, fragment konkuren dan aria2c** untuk unduhan berat dan jaringan yang rapuh.
- **Perintah kustom** untuk menjalankan yt-dlp dengan template argumen buatanmu sendiri, dikelola di dalam aplikasi.
- **Layar Downloads** dengan antrean berurutan, batal dan coba lagi, tampilan kecepatan dan ETA, serta riwayat unduhan selesai dengan ukuran dan tanggal.
- **Mode privat** untuk melewati riwayat sama sekali.
- **Mesin Android**: yt-dlp berjalan in-process lewat Chaquopy, dengan foreground service yang menjaga unduhan tetap hidup dan share-to-Talos dari aplikasi lain.
- **Mesin desktop**: yt-dlp diunduh sekali dan dikelola oleh aplikasi, atau memakai yt-dlp sistem, dengan deteksi FFmpeg otomatis.
- **Desain gelap hangat** dengan aksen perunggu, mode terang dan mengikuti sistem, lima warna aksen, antarmuka dwibahasa (English dan Bahasa Indonesia).
- **Merek Talos**: mark orisinal, lockup bertumpuk dan horizontal, app icon untuk Android, iOS, Windows dan macOS, serta splash screen gelap.
- **Continuous integration**: analyze, test dan build di setiap push dan pull request.

[Unreleased]: https://github.com/nekonaru/talos/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/nekonaru/talos/releases/tag/v0.1.0
