# Panduan Best Practice — Menggunakan Kilo AI Agent

Panduan ini membantu Anda mendapatkan hasil terbaik dari AI agent. Tidak perlu bisa coding — cukup ikuti tips di bawah.

---

## Cara Memberi Task yang Baik

### Prinsip Dasar

Bayangkan Anda sedang brief seorang developer freelance. Semakin jelas Anda menjelaskan, semakin baik hasilnya.

**Buruk:**
```
"Buatkan aplikasi"
```

**Baik:**
```
"Buatkan aplikasi kasir untuk warung kopi. Fiturnya: pilih menu, hitung total, cetak struk."
```

**Lebih baik:**
```
"Buatkan aplikasi kasir untuk warung kopi saya.
Fitur yang dibutuhkan:
- Input pesanan (pilih menu, jumlah)
- Hitung total harga otomatis
- Cetak struk ke printer
- Laporan penjualan harian
User-nya adalah pegawai warung yang gaptek, jadi tampilannya harus simpel."
```

### Template yang Bisa Dipakai

```
Saya butuh [jenis aplikasi] untuk [kegunaan].
Fitur utama:
- [fitur 1]
- [fitur 2]
- [fitur 3]
User-nya adalah [siapa yang pakai].
Catatan tambahan: [hal penting lain]
```

---

## Jelaskan Masalah, Bukan Solusi

Anda tidak perlu tahu teknologi. Cukup jelaskan apa masalahnya dan apa yang ingin dicapai.

**Tidak perlu:**
```
"Buatkan REST API dengan Express.js dan PostgreSQL"
```

**Cukup bilang:**
```
"Saya butuh sistem untuk menyimpan data pelanggan dan bisa dicari namanya"
```

AI akan memilih teknologi yang tepat untuk Anda.

---

## Beri Konteks Bisnis

Semakin AI mengerti tujuan bisnis Anda, semakin baik hasilnya.

**Contoh:**
```
"Saya punya toko online kecil, jualan baju. Saya butuh sistem untuk kelola
stok barang. Saya capek catat manual di Excel. Kadang barang habis tapi
saya tidak tahu."
```

Dari konteks ini, AI bisa:
- Membuat sistem stok yang sederhana
- Menambahkan notifikasi stok menipis
- Membuat laporan yang mudah dibaca

---

## Mulai dari yang Kecil

Jangan langsung minta aplikasi besar. Mulai dari fitur inti, lalu tambah bertahap.

**Langkah 1 — Minta fitur dasar:**
```
"Buatkan aplikasi untuk catat pesanan pelanggan"
```

**Langkah 2 — Tambah fitur setelah dasar jalan:**
```
"Tambahkan fitur cetak faktur"
```

**Langkah 3 — Tambah lagi:**
```
"Tambahkan laporan penjualan bulanan"
```

Ini lebih baik daripada langsung minta 20 fitur sekaligus. Hasilnya lebih rapi dan Anda bisa koreksi di setiap tahap.

---

## Review dan Koreksi

Setelah AI selesai membuat sesuatu, selalu:

1. **Cek hasilnya** — buka di browser atau jalankan aplikasinya
2. **Coba fitur-fiturnya** — apakah sesuai harapan?
3. **Beri feedback** — jika ada yang kurang, bilang saja

**Contoh feedback:**
```
"Tombolnya terlalu kecil, perbesar"
"Warnanya kurang cocok, ganti ke biru"
"Halaman login-nya pindahin ke depan"
"Hitungannya salah, harga x jumlah seharusnya..."
```

AI tidak tersinggung. Semakin banyak feedback, semakin baik hasilnya.

---

## Infrastruktur dan Docker

### Apa itu Docker?

Docker adalah cara menjalankan aplikasi beserta semua yang dibutuhkannya dalam satu paket rapi. Anda tidak perlu paham detailnya — AI akan mengatur semuanya.

### Komponen yang Otomatis Disertakan

Saat AI membuat aplikasi, Docker Compose akan otomatis menyertakan komponen yang dibutuhkan berdasarkan jenis aplikasi Anda. Misalnya:
- Ada penyimpanan data → database (PostgreSQL)
- Ada login/session → cache (Redis)
- Ada upload file → object storage (MinIO)
- Ada fitur search → search engine
- Ada kirim email → email testing tool

AI menentukan sendiri mana yang diperlukan — Anda tidak perlu minta secara khusus. Aturan lengkapnya ada di panduan teknis AI. Yang perlu Anda tahu: semua komponen ini sudah dikonfigurasi dan tinggal pakai.

### Contoh: Anda Bilang "Buatkan Aplikasi E-commerce"

AI akan otomatis membuat docker-compose.yml yang berisi:
- **App** — kode aplikasi Anda
- **PostgreSQL** — untuk menyimpan data produk, pesanan, user
- **Redis** — untuk cache dan session login
- **MinIO** — untuk upload gambar produk

Semua sudah dikonfigurasi. Anda cukup jalankan:
```bash
docker compose up
```

---

## Pola Penggunaan Umum

### Buat Aplikasi dari Awal
```
"Saya mau bikin [jenis aplikasi]. Fiturnya: [daftar fitur]."
```

### Perbaiki Masalah
```
"Aplikasi saya error waktu [apa yang terjadi]. Tolong periksa."
```

### Tambah Fitur
```
"Tambahkan fitur [nama fitur] di [bagian mana]"
```

### Ubah Tampilan
```
"Tampilan [bagian] kurang [masalah]. Tolong perbaiki."
```

### Minta Penjelasan
```
"Jelaskan cara kerja [bagian aplikasi] dalam bahasa yang mudah dipahami"
```

### Deploy ke Server
```
"Saya mau aplikasi ini bisa diakses dari internet. Bantu setup."
```

---

## Tips Mendapatkan Hasil Terbaik

### Jelaskan Siapa User-nya
```
"User-nya adalah orang tua yang tidak terbiasa komputer"
"User-nya adalah admin toko yang butuh input cepat"
```

AI akan menyesuaikan tampilan dan kompleksitas berdasarkan siapa yang pakai.

### Sebutkan Jika Ada Constraint
```
"Budget hosting-nya terbatas, jangan pakai yang mahal"
"Saya butuh ini selesai hari ini"
"Aplikasi harus bisa dipakai di HP"
```

### Minta AI Menjelaskan
```
"Jelaskan apa yang sudah kamu buat dan cara pakainya"
"Buatkan panduan singkat untuk user"
```

### Minta Rekomendasi
```
"Menurut kamu, fitur apa yang kurang untuk aplikasi kasir?"
"Ada saran untuk membuat aplikasi ini lebih baik?"
```

---

## Yang Tidak Perlu Dilakukan

- **Tidak perlu pilih framework** — AI akan pilihkan yang terbaik
- **Tidak perlu pilih bahasa pemrograman** — AI akan tentukan
- **Tidak perlu tahu istilah teknis** — bicara saja dalam bahasa sehari-hari
- **Tidak perlu setup manual** — installer sudah mengatur semua
- **Tidak perlu takut salah** — AI bisa memperbaiki kapan saja

---

## Contoh Sesi Lengkap

Berikut contoh percakapan dari awal sampai selesai:

**Anda:**
```
Saya mau bikin sistem booking untuk salon kecantikan.
Fitur yang dibutuhkan:
- Customer bisa pilih layanan dan waktu
- Admin bisa lihat jadwal booking
- Notifikasi ke admin ada booking baru
User customer-nya orang umum, admin-nya pegawai salon.
```

**AI akan:**
1. Menganalisa kebutuhan
2. Menampilkan rencana pembangunan
3. Membuat project dengan struktur yang rapi
4. Mengatur database PostgreSQL untuk data booking
5. Mengatur Redis untuk session dan cache
6. Membuat halaman customer (pilih layanan, booking)
7. Membuat halaman admin (lihat jadwal, kelola)
8. Mengatur Docker supaya gampang dijalankan
9. Menjelaskan cara pakai

**Anda (setelah review):**
```
Tampilannya bagus. Tapi saya mau tambah:
- Pilih pegawai juga saat booking
- Customer bisa lihat status booking-nya
```

**AI akan:**
1. Menambahkan fitur pilih pegawai
2. Membuat halaman status booking untuk customer
3. Mengupdate database

Dan seterusnya. Prosesnya iteratif — terus berkembang sesuai kebutuhan Anda.

---

## Integrasi dengan Layanan Eksternal

Terkadang aplikasi butuh terhubung ke layanan luar: Google Drive, Gmail,
WhatsApp, payment gateway, dll. AI akan memandu Anda menyiapkannya.

### Yang Akan Terjadi

Saat AI mendeteksi aplikasi butuh layanan eksternal:

1. AI memberitahu Anda — menjelaskan dengan bahasa sederhana apa yang
   dibutuhkan dan kenapa
2. AI memberi panduan step-by-step — daftar berurut apa yang harus dilakukan
3. AI menunggu Anda — tidak akan lanjut sampai Anda memberikan credential
4. AI menyimpan dengan aman — credential di file khusus (.env), bukan di kode

### Contoh: Aplikasi Perlu Akses Google Drive

AI akan bilang kira-kira seperti ini:

"Untuk fitur upload laporan ke Google Drive, saya butuh Service Account.
Ini seperti kunci khusus agar aplikasi bisa akses Drive Anda.

Cara membuatnya (sekitar 5 menit):
1. Buka https://console.cloud.google.com
2. Buat project baru (atau pilih yang sudah ada)
3. Klik 'APIs & Services' → 'Enable APIs and Services'
4. Cari 'Google Drive API' → klik Enable
5. Klik 'Credentials' di sidebar
6. Klik 'Create Credentials' → 'Service Account'
7. Isi nama, klik 'Create and Continue'
8. Role: pilih 'Editor', klik Done
9. Klik service account yang baru dibuat
10. Tab 'Keys' → 'Add Key' → 'Create New Key' → pilih JSON
11. File JSON akan terdownload — copy seluruh isinya, lalu paste ke sini"

Anda tinggal ikuti langkahnya, lalu paste credential-nya.

### Jenis Credential yang Mungkin Diminta

| Layanan | Yang Dibutuhkan | Untuk Apa |
|---------|----------------|-----------|
| Google Drive | File JSON (Service Account) | Upload atau simpan file |
| Google Sheets | File JSON (Service Account) | Baca/tulis spreadsheet |
| Gmail | App Password (16 karakter) | Kirim email dari aplikasi |
| WhatsApp | Access Token | Kirim notifikasi WhatsApp |
| Midtrans | Server Key + Client Key | Terima pembayaran |
| Xendit | API Key | Payment gateway |
| Twilio | Account SID + Token | Kirim SMS |

### Yang Perlu Diingat

- Anda tidak perlu paham teknis — ikuti saja langkah dari AI
- Credential disimpan aman, tidak tersebar di kode
- Kalau bingung, bilang saja — AI akan jelaskan lebih sederhana
- Selalu ada alternatif lokal yang lebih mudah (misal: simpan file di
  komputer dulu daripada Google Drive)
