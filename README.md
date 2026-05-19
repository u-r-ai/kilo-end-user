# Kilo End-User — AI Software Builder

Asisten pribadi berbasis AI yang bisa bantu Anda bikin aplikasi, website, automasi, dan berbagai software lainnya. Tinggal bilang apa yang Anda butuhkan, biar yang lain dikerjakan.

---

## Apa Ini?

Kilo End-User adalah setup siap pakai untuk Kilo CLI — sebuah AI assistant yang berjalan di komputer Anda dan bisa menulis kode, membuat project, mengatur server, dan banyak lagi.

Anda tidak perlu bisa coding. Cukup bilang dalam bahasa sehari-hari apa yang ingin dibuat, dan AI akan mengerjakannya untuk Anda.

**Bayangkan punya tim engineering pribadi yang siap bantu 24 jam.** Itulah yang Anda dapatkan.

---

## Kemampuan

Apa saja yang bisa dilakukan:

- **Buat aplikasi web** — inventory, booking, e-commerce, dashboard, dan lainnya
- **Buat landing page** — website profesional untuk bisnis Anda
- **Buat API/backend** — sistem yang menghubungkan aplikasi Anda dengan data
- **Buat automasi** — kirim invoice otomatis, backup data, proses file
- **Buat AI workflow** — integrasi dengan layanan AI untuk bisnis Anda
- **Kelola Docker** — menjalankan aplikasi dalam container yang rapi
- **Deploy** — membantu menyiapkan aplikasi untuk diakses online (perlu server/cloud hosting sendiri)

Semua dikerjakan otomatis. Anda cukup memberi arahan.

---

## Struktur

Setelah install, berikut yang ada di komputer Anda:

```
~/.config/kilo/
├── kilo.jsonc              ← Pengaturan utama (model, API key, permissions)
├── agents/
│   └── assistant.md        ← AI assistant utama (berbahasa Indonesia)
├── commands/
│   ├── start.md            ← Command /start untuk memulai project baru
│   └── status.md           ← Command /status untuk cek kondisi sistem
└── skills/
    └── project-builder/
 └── SKILL.md              ← Panduan membangun project dari awal
```

Di atas adalah struktur folder setelah install — file-file config disalin ke `~/.config/kilo/`.

### Struktur Repository

Proyek ini juga menyertakan file tambahan di repositori yang tidak ikut tercopy saat install:

```
kilo-end-user/
├── config/                  ← File yang dicopy ke ~/.config/kilo/
├── docs/
│   ├── architecture.md      ← Penjelasan arsitektur
│   ├── best-practices.md    ← Panduan efektif pakai AI agent
│   └── SECURITY-AUDIT.md    ← Laporan audit keamanan
├── install.sh               ← Installer (entry point)
├── CONTRIBUTING.md          ← Panduan kontribusi
├── CHANGELOG.md             ← Riwayat perubahan
├── README.md                ← Dokumen ini
└── LICENSE                  ← Lisensi MIT
```

File-file di `config/` adalah template — saat install, script `install.sh` menyalinnya ke `~/.config/kilo/` dan mengisinya dengan pilihan provider, model, dan API key Anda.

---

## Cara Install

Satu command saja. Buka terminal, lalu jalankan:

```bash
curl -fsSL https://raw.githubusercontent.com/u-r-ai/kilo-end-user/main/install.sh | bash
```

Installer akan otomatis:
1. Menginstall semua yang dibutuhkan (Node.js, Docker, Git)
2. Menginstall Kilo CLI
3. Menanyakan provider AI yang ingin dipakai
4. Menanyakan API key Anda
5. Mengkonfigurasi semuanya

Tunggu hingga selesai. Biasanya butuh 2-5 menit tergantung kecepatan internet.

> **Sebelum menjalankan:** Sebaiknya inspeksi dulu isi script sebelum di-pipe ke bash. Buka https://raw.githubusercontent.com/u-r-ai/kilo-end-user/main/install.sh di browser untuk melihat isinya. Pastikan Anda nyaman dengan apa yang akan dijalankan. Ini praktik keamanan yang baik untuk script dari internet.

---

## Install di Windows (WSL)

Jika Anda menggunakan **Windows**, Anda perlu menginstall WSL (Windows Subsystem for Linux) terlebih dahulu. WSL memungkinkan Anda menjalankan aplikasi Linux di dalam Windows.

### Apa itu WSL?

WSL adalah fitur Windows yang memungkinkan Anda menjalankan lingkungan Linux langsung di Windows tanpa perlu install virtual machine atau dual boot. Kilo dan semua tools-nya akan berjalan di dalam WSL.

### Langkah Install WSL

1. **Buka PowerShell sebagai Administrator:**
   - Klik kanan tombol Start
   - Pilih **Windows Terminal (Admin)** atau **PowerShell (Admin)**

2. **Jalankan perintah install WSL:**
   ```powershell
   wsl --install
   ```

3. **Restart komputer Anda** setelah install selesai

4. **Buka Ubuntu dari Start Menu:**
   - Setelah restart, cari "Ubuntu" di Start Menu
   - Buka Ubuntu, tunggu proses setup awal
   - Buat username dan password untuk Ubuntu

### Install Kilo di dalam WSL

Setelah WSL siap, buka terminal Ubuntu dan jalankan:

```bash
curl -fsSL https://raw.githubusercontent.com/u-r-ai/kilo-end-user/main/install.sh | bash
```

### Tips WSL

- **Akses file Windows dari WSL:** Folder Windows bisa diakses di `/mnt/c/`. Contoh: `C:\Users\Anda` ada di `/mnt/c/Users/Anda`
- **Docker Desktop:** Jika Anda sudah install Docker Desktop di Windows, aktifkan integrasi WSL di pengaturan Docker Desktop → Settings → Resources → WSL Integration
- **Copy-paste:** Klik kanan di terminal Ubuntu untuk paste teks

---

## Menambahkan API Key

Saat install, Anda akan diminta memilih provider dan memasukkan API key. Berikut cara mendapatkannya:

### DeepSeek (deepseek-chat) — Default

1. Hubungi tim Anda untuk mendapatkan API key DeepSeek
2. Atau buat akun di https://platform.deepseek.com/
3. Masuk ke menu **API Keys**
4. Buat API key baru
5. Copy key-nya dan paste saat install

### Anthropic (Claude)

1. Buka https://console.anthropic.com/
2. Buat akun atau login
3. Masuk ke menu **API Keys**
4. Klik **Create Key**
5. Copy key-nya dan paste saat install

### OpenAI (GPT)

1. Buka https://platform.openai.com/api-keys
2. Buat akun atau login
3. Klik **Create new secret key**
4. Copy key-nya dan paste saat install

### Google Gemini

1. Buka https://aistudio.google.com/apikey
2. Login dengan akun Google
3. Klik **Create API Key**
4. Copy key-nya dan paste saat install

### OpenRouter (Multi-model)

1. Buka https://openrouter.ai/keys
2. Buat akun atau login
3. Klik **Create Key**
4. Copy key-nya dan paste saat install

> **Tips:** Simpan API key Anda di tempat aman. Jangan bagikan ke orang lain.

---

## Menjalankan Agent

Setelah install selesai:

1. **Buka terminal baru** (penting agar semua perubahan dikenali)
2. Ketik: `kilo`
3. Tunggu hingga Kilo siap
4. Mulai bicara dengan AI dalam bahasa Indonesia

---

## Cara Memberi Task

Anda bisa bilang apa saja dalam bahasa sehari-hari. Contoh:

### Membuat Aplikasi

```
"Saya mau bikin aplikasi laundry. Fiturnya: input order, hitung harga, cetak struk."
```

```
"Buatkan aplikasi inventory untuk toko saya. Perlu bisa input barang, stok masuk-keluar, dan laporan."
```

### Membuat Website

```
"Buatkan landing page untuk katering saya. Ada menu, harga, dan form pemesanan."
```

```
"Saya butuh website portofolio untuk usaha desain interior."
```

### Membuat Automasi

```
"Buat automation untuk kirim reminder ke pelanggan via WhatsApp setiap hari."
```

```
"Buat script untuk backup database setiap malam otomatis."
```

### Memperbaiki atau Mengubah

```
"Aplikasi saya error waktu login. Tolong periksa dan perbaiki."
```

```
"Tambahkan fitur cetak PDF di halaman laporan."
```

---

## Contoh Penggunaan

### Contoh 1: Bikin Aplikasi Kasir Sederhana

**Anda bilang:**
```
"Saya butuh aplikasi kasir untuk warung kopi. Fiturnya: pilih menu, hitung total, cetak struk."
```

**AI akan:**
1. Menganalisa kebutuhan Anda
2. Membuat rencana pembangunan
3. Membuat struktur project
4. Menulis kode aplikasi
5. Mengatur database
6. Membuat tampilan yang mudah dipakai
7. Mengatur Docker supaya gampang dijalankan
8. Menjelaskan cara pakai

Anda tinggal tunggu dan ikuti arahan.

### Contoh 2: Bikin Website Bisnis

**Anda bilang:**
```
"Buatkan website untuk usaha katering saya. Ada daftar menu, galeri foto, dan form order."
```

**AI akan:**
1. Mendesain tampilan website
2. Membuat halaman-halaman yang diperlukan
3. Menambahkan form pemesanan
4. Mengatur supaya bisa dibuka di HP juga
5. Menyiapkan untuk diupload ke internet

### Contoh 3: Automasi Laporan

**Anda bilang:**
```
"Saya mau laporan penjualan harian dikirim otomatis ke email setiap malam."
```

**AI akan:**
1. Membuat script untuk mengambil data penjualan
2. Mengatur format laporan
3. Membuat jadwal pengiriman otomatis
4. Mengatur email

---

## Docker

Docker membantu menjalankan aplikasi Anda dengan rapi dan konsisten.

### Menjalankan Aplikasi

```bash
cd nama-project
docker compose up
```

Aplikasi akan berjalan dan bisa dibuka di browser.

### Menghentikan Aplikasi

```bash
docker compose down
```

### Menjalankan Ulang (setelah ada perubahan)

```bash
docker compose up --build
```

### Melihat Aplikasi yang Sedang Jalan

```bash
docker ps
```

> **Catatan:** Anda tidak perlu menghafal command Docker. AI akan mengatur semuanya untuk Anda.

---

## Commands

Kilo punya beberapa command khusus yang bisa Anda pakai:

| Command | Fungsi |
|---------|--------|
| `/start`  | Memulai project baru dengan struktur yang rapi |
| `/status` | Mengecek apakah semua komponen sistem berjalan normal |

Cara pakai: cukup ketik command di chat Kilo.

Selain command di atas, Kilo juga menggunakan **MCP (Model Context Protocol)** — sebuah standar yang memungkinkan AI berinteraksi langsung dengan file, Git, Docker, dan memory di komputer Anda. Semua sudah dikonfigurasi dan siap pakai.

---

## Troubleshooting

### Kilo tidak ditemukan setelah install

Buka terminal baru, lalu coba lagi. Jika masih tidak bisa:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Tambahkan baris di atas ke file `~/.bashrc` atau `~/.zshrc` supaya permanen.

### Docker minta sudo

Setelah install, Anda perlu **logout dan login lagi** supaya bisa pakai Docker tanpa sudo.

### API Key error

Pastikan API key yang Anda masukkan benar dan masih aktif. Anda bisa cek di website provider masing-masing.

### Install gagal di tengah jalan

Jalankan ulang command install. Installer bersifat idempotent — aman dijalankan berkali-kali.

```bash
curl -fsSL https://raw.githubusercontent.com/u-r-ai/kilo-end-user/main/install.sh | bash
```

### Node.js versi lama

Update Node.js menggunakan **nvm** (Node Version Manager):

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
exec bash
nvm install --lts
nvm use --lts
```

> **Catatan:** Metode NodeSource (deb.nodesource.com) sudah deprecated. Gunakan nvm seperti di atas untuk hasil yang lebih stabil dan mudah dikelola.

### Mau ganti provider/model

Edit file `~/.config/kilo/kilo.jsonc`. Ganti bagian `model` dan `provider` sesuai keinginan.

---

## Update

Untuk memperbarui konfigurasi, jalankan ulang installer:

```bash
curl -fsSL https://raw.githubusercontent.com/u-r-ai/kilo-end-user/main/install.sh | bash
```

---

## Pertanyaan Umum

### Apa bedanya Kilo dengan ChatGPT?

ChatGPT adalah chatbot AI serbaguna. Kilo adalah AI coding agent yang berjalan di komputer Anda dan bisa menulis kode, menjalankan Docker, membuat file, dan mengelola project — bukan sekedar ngobrol.

### Apa saya harus bisa coding?

Tidak sama sekali. Kilo dirancang untuk user non-teknis. Cukup bilang dalam bahasa sehari-hari apa yang ingin dibuat.

### Kilo bisa buat aplikasi apa saja?

Aplikasi web, landing page, API/backend, automasi, dashboard, sistem inventory, booking, e-commerce, dan banyak lagi. Intinya aplikasi berbasis web yang jalan di server.

### Apakah aplikasi yang dibuat bisa diakses dari internet?

Bisa, tapi perlu server atau cloud hosting sendiri. Kilo menyiapkan aplikasi dan Docker-nya. Untuk publish ke internet, Anda perlu domain + VPS (Virtual Private Server) atau layanan cloud. AI akan memandu proses deploy-nya.

### Apa itu Docker? Apakah saya perlu install sendiri?

Docker sudah diinstall otomatis oleh installer Kilo. Anda tidak perlu paham cara kerjanya — AI yang akan mengatur semuanya. Docker memastikan aplikasi Anda jalan dengan rapi tanpa konflik.

### Bagaimana cara ganti model AI?

Edit file `~/.config/kilo/kilo.jsonc`. Ganti bagian `model` dan `provider`. Bisa pakai DeepSeek, Claude, GPT, Gemini, atau OpenRouter.

### Apakah data saya aman?

Ya. Semua data dan kode Anda disimpan di komputer lokal. API key disimpan di file konfigurasi yang hanya bisa dibaca oleh user Anda (chmod 600). Tidak ada data yang dikirim ke pihak ketiga selain ke provider AI yang Anda pilih.

### Bisakah saya menggunakan lebih dari 1 provider?

File konfigurasi hanya mendukung satu provider aktif. Untuk ganti provider, edit `kilo.jsonc` dan restart Kilo.

### Kalau bingung, bagaimana cara minta bantuan?

Tinggal tanya AI dalam bahasa Indonesia. Contoh: "Saya bingung, jelaskan langkah-langkahnya lagi pelan-pelan." AI akan merespon dengan bahasa yang lebih sederhana.

---

## Lisensi

MIT License. Bebas dipakai dan dimodifikasi.

---

## Butuh Bantuan?

- **Dokumentasi Kilo:** https://kilo.ai/docs
- **GitHub:** https://github.com/u-r-ai/kilo-end-user
- **Best Practice:** [Panduan menggunakan AI agent dengan efektif](docs/best-practices.md)
