# Kontribusi

Terima kasih sudah tertarik berkontribusi ke Kilo End-User! Proyek ini berupa setup siap pakai untuk Kilo CLI dengan agen AI berbahasa Indonesia. Kontribusi dari komunitas sangat membantu untuk terus meningkatkan kualitasnya.

## Cara Berkontribusi

### 1. Laporkan Masalah

Jika Anda menemukan bug atau punya saran:

1. Buka [Issues](https://github.com/u-r-ai/kilo-end-user/issues)
2. Cek apakah sudah ada issue serupa
3. Klik **New Issue**
4. Pilih template yang sesuai:
   - **Bug Report** — ada yang tidak berfungsi seperti seharusnya
   - **Feature Request** — saran fitur atau perbaikan
5. Isi detailnya selengkap mungkin

### 2. Pull Request

Proses untuk mengirim perubahan kode:

**Sebelum mulai:**
- Cek Issues — pastikan tidak ada yang sedang mengerjakan hal serupa
- Kalau perubahannya besar, buka issue dulu untuk diskusi
- Fork repositori ini

**Branch naming:**
- `fix/deskripsi-singkat` — untuk perbaikan bug
- `feat/deskripsi-singkat` — untuk fitur baru
- `docs/deskripsi-singkat` — untuk perubahan dokumentasi
- `refactor/deskripsi-singkat` — untuk refactoring kode

**Langkah-langkah:**
1. Fork repositori ke akun GitHub Anda
2. Clone fork Anda:
   ```bash
   git clone https://github.com/username-anda/kilo-end-user.git
   cd kilo-end-user
   ```
3. Buat branch baru:
   ```bash
   git checkout -b fix/nama-perbaikan
   ```
4. Lakukan perubahan
5. Commit dengan pesan yang jelas:
   ```bash
   git commit -m "fix: deskripsi singkat perbaikan"
   ```
6. Push ke fork Anda:
   ```bash
   git push origin fix/nama-perbaikan
   ```
7. Buka Pull Request ke branch `main`

### 3. Pull Request Checklist

Sebelum mengirim PR, pastikan:

- [ ] Perubahan sudah diuji secara manual
- [ ] Tidak ada konflik dengan branch `main`
- [ ] Tidak ada perubahan yang tidak perlu (formatting yang tidak sengaja)
- [ ] Jika mengubah behavior, update dokumentasi yang relevan
- [ ] Commit messages jelas dan informatif

## Area yang Membutuhkan Bantuan

Beberapa area yang selalu terbuka untuk kontribusi:

- **Dokumentasi** — terjemahan, perbaikan typo, contoh penggunaan
- **Installer** — dukungan distribusi Linux lain, perbaikan edge case
- **Agent config** — prompt engineering untuk agen AI yang lebih baik
- **Testing** — skrip pengujian dan validasi

## Pedoman

- **Bahasa:** Dokumentasi dan komentar sebaiknya dalam Bahasa Indonesia, karena proyek ini ditujukan untuk user Indonesia
- **Sederhana:** Jaga agar tetap mudah dipahami — target user adalah non-teknis
- **Aman:** Jangan menyertakan API key, token, atau credential apapun
- **Kompatibel:** Pastikan perubahan tidak merusak instalasi yang sudah ada

## Maintainer

Untuk informasi lebih lanjut, hubungi maintainer melalui GitHub Issues atau diskusi di repositori.

---

Terima kasih sudah membantu membuat Kilo End-User lebih baik!
