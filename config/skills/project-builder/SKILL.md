---
name: project-builder
description: >-
  Skill untuk membangun project dari awal hingga selesai. Digunakan ketika
  user meminta pembuatan aplikasi, website, API, automation, atau software
  apapun. Mencakup perencanaan, struktur project, Docker setup, dan
  dokumentasi.
---

# Project Builder

Skill ini memandu proses pembangunan project dari awal hingga siap dijalankan.

## Alur Kerja

### 1. Pahami Kebutuhan

Sebelum mulai coding:
- Pahami apa yang ingin dibuat user
- Pahami siapa yang akan pakai
- Pahami masalah yang ingin diselesaikan
- Jangan tanyakan hal teknis ke user

### 1a. Deteksi Integrasi Eksternal

Saat menganalisa kebutuhan, WAJIB mendeteksi apakah project butuh integrasi
dengan layanan eksternal. Deteksi sendiri — jangan tanya user "mau pakai apa".

| User minta... | Layanan | Credential | Cara Dapat |
|---|---|---|---|
| Upload/simpan file di Google Drive | Google Drive API | Service Account JSON | console.cloud.google.com → IAM → Service Accounts → Create → JSON Key |
| Baca/tulis Google Sheets | Google Sheets API | Service Account JSON | Sama seperti di atas |
| Kirim email otomatis | Gmail SMTP | App Password (16 char) | Google Account → Security → 2FA → App Passwords |
| Notifikasi WhatsApp | WhatsApp Cloud API | Access Token + Phone Number ID | developers.facebook.com → WhatsApp → API Setup |
| Terima pembayaran | Midtrans | Server Key + Client Key | dashboard.midtrans.com → Settings → Access Keys |
| Terima pembayaran | Xendit | API Key (secret) | dashboard.xendit.co → Settings → API Keys |
| Kirim SMS / OTP | Twilio | Account SID + Auth Token | console.twilio.com → Dashboard |
| Verifikasi email user | Resend | API Key | resend.com → API Keys |

CARA MEMANDU USER:

1. Jelaskan kenapa credential dibutuhkan (1-2 kalimat sederhana)

2. Beri panduan step-by-step dalam format checklist:
   - [ ] 1. Buka [URL console]
   - [ ] 2. [Langkah spesifik dengan nama menu/button yang tepat]
   - [ ] 3. [Langkah selanjutnya]
   - ...sampai user punya credential/file yang dibutuhkan

3. TUNGGU sampai user memberikan credential tersebut

4. Setelah dapat, simpan di .env dengan nama variabel deskriptif

5. Tulis kode yang membaca credential dari env var (process.env.XXX)

ALTERNATIF LOKAL:

Sebelum meminta credential eksternal, pertimbangkan alternatif lokal:
- Upload file → MinIO (sudah ada di docker-compose)
- Database → PostgreSQL (sudah ada di docker-compose)
- Email testing → Mailpit (sudah ada di docker-compose)

Tawarkan alternatif jika user terlihat bingung.

### 2. Buat Rencana

Tampilkan rencana dalam format:

```markdown
## Yang Akan Dibuat
[Deskripsi singkat hasil akhir]

## Cara Kerja
[Penjelasan sederhana bagaimana aplikasi bekerja]

## Progress
- [ ] Setup project
- [ ] Buat struktur database
- [ ] Buat halaman utama
- [ ] Tambah fitur login
- [ ] Setup Docker
- [ ] Setup testing (pytest untuk Python / Jest untuk JavaScript)
- [ ] Buat minimal 1 test per endpoint / fitur utama
- [ ] Jalankan test dan pastikan pass
```

### 3. Setup Project

Buat struktur project yang rapi:
- Folder terorganisir dengan jelas
- File konfigurasi sudah siap
- Environment setup otomatis
- Docker sudah dikonfigurasi

### 4. Build Aplikasi

Saat membangun:
- Tulis code production-ready
- Buat reusable component
- Hindari overengineering
- Gunakan dependency yang stabil dan populer
- Buat error handling yang baik

### 5. Docker Setup

Setiap project harus:
- Punya Dockerfile
- Punya docker-compose.yml (jika multi-service)
- Bisa dijalankan dengan `docker compose up`
- Environment variable terdokumentasi di .env.example

#### Docker Compose — Wajib Sertakan Komponen yang Dibutuhkan

Saat membuat docker-compose.yml, **WAJIB** menganalisa kebutuhan aplikasi dan menyertakan service/container berikut secara otomatis. Jangan menunggu user minta — deteksi dari fitur yang diminta.

**Aturan wajib (otomatis berdasarkan jenis aplikasi):**

| Jika aplikasi membutuhkan... | Sertakan container | Image |
|---|---|---|
| Menyimpan data persisten (user, produk, pesanan, transaksi, apapun) | **PostgreSQL** | `postgres:16-alpine` |
| Session login, cache, atau rate limiting | **Redis** | `redis:7-alpine` |
| Upload file / gambar / dokumen | **MinIO** (S3-compatible) | `minio/minio:latest` |
| Background job / async task / queue | **Redis** (sebagai broker) | `redis:7-alpine` |
| Full-text search (pencarian produk, artikel, dll) | **Meilisearch** | `getmeili/meilisearch:latest` |
| Kirim email (development/testing) | **Mailpit** | `axllent/mailpit:latest` |

**Contoh keputusan otomatis:**

- User minta "aplikasi kasir" → butuh simpan data → **wajib PostgreSQL**
- User minta "e-commerce" → butuh simpan data + session + upload gambar → **wajib PostgreSQL + Redis + MinIO**
- User minta "blog" → butuh simpan data + search → **wajib PostgreSQL + Meilisearch**
- User minta "API sederhana" → butuh simpan data → **wajib PostgreSQL**
- User minta "landing page statis" → tidak butuh database → **tidak perlu container tambahan**
- User minta "automation script" → tidak butuh database → **tidak perlu container tambahan**

**Default rules:**
1. Jika aplikasi menyimpan data apapun → **PostgreSQL wajib ada**
2. Jika aplikasi punya login/user → **Redis wajib ada** (untuk session)
3. Jangan pernah pakai SQLite untuk production — selalu PostgreSQL
4. Setiap container harus punya healthcheck
5. Setiap container harus punya volume untuk persistensi data
6. Semua port dan credential harus di `.env.example`, bukan hardcoded

**Template docker-compose.yml minimal untuk web app:**

```yaml
services:
  app:
    build: .
    ports:
      - "${APP_PORT:-3000}:3000"
    environment:
      - DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
      - REDIS_URL=redis://redis:6379
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    restart: unless-stopped

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-app}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-secret}
      POSTGRES_DB: ${POSTGRES_DB:-app}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-app}"]
      interval: 5s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
```

**Tambahkan service lain (MinIO, Meilisearch, Mailpit) hanya jika dibutuhkan.**

> **Test service:** Untuk menjalankan test di CI/local, tambahkan service `test` di docker-compose.yml yang menggunakan perintah test (misal: `command: npm test` atau `command: pytest`). Service test bisa dijalankan dengan `docker compose run test` dan tidak perlu berjalan di background.

### 6. Dokumentasi

Buat README sederhana yang berisi:
- Apa project ini
- Cara menjalankan
- Cara menggunakan
- Cara mengubah konfigurasi
- Siap untuk dipakai user

### 7. Testing

Setiap project WAJIB memiliki testing strategy.

#### Framework Default

| Bahasa/Framework | Framework Test | Perintah |
|---|---|---|
| Python (FastAPI / Flask / Django) | **pytest** | `pytest -v` |
| Python (Django) | Django Test + pytest-django | `python manage.py test` |
| Node.js / Express / Next.js | **Jest** | `npm test` atau `npx jest` |
| React / Vue / Svelte (frontend) | Vitest atau Jest | `npm run test` |
| Go | Go built-in testing | `go test ./...` |

#### Aturan Testing

1. **Minimal 1 test per endpoint/fitur utama** — setidaknya test happy path
2. **Test harus bisa jalan sendiri** — tanpa interaksi manual
3. **Gunakan test database** — jangan pake production database
   - Untuk Python: gunakan `pytest-django` in-memory atau testcontainers
   - Untuk Node.js: gunakan test database terpisah atau in-memory (sqlite:memory)
4. **Jangan test dependency eksternal** — mock layanan seperti payment gateway, WhatsApp API, Google Drive
5. **Test harus pass sebelum dianggap selesai** — jangan skip failing test

#### Cara Integrasi

- Di `package.json`: tambahkan script `"test": "jest"`
- Di `docker-compose.yml`: tambahkan service `test` seperti di atas
- Pastikan `README.md` menyertakan perintah untuk menjalankan test

## Prioritas Teknis

1. **Reliability** — Aplikasi harus stabil
2. **Simplicity** — Kode harus mudah dipahami
3. **Speed** — Cepat selesai dan bisa dipakai
4. **Maintainability** — Mudah diubah nanti

## Standar Output

Project yang dihasilkan harus:
- Bisa langsung dijalankan
- Punya Docker setup
- Punya dokumentasi
- Terstruktur dengan rapi
- Siap untuk dipakai user
