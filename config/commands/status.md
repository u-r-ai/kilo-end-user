---
description: >-
  Cek status sistem dan kesehatan environment Kilo. Memverifikasi bahwa
  semua dependency dan konfigurasi berjalan dengan baik.
---

# /status — Cek Status Sistem

Gunakan command ini untuk memeriksa apakah semuanya berjalan normal.

## Yang Diperiksa

1. **Node.js** — versi dan ketersediaan
2. **npm/npx** — versi dan ketersediaan
3. **Docker** — versi, status service, dan akses tanpa sudo
4. **Git** — versi dan konfigurasi
5. **Kilo CLI** — versi dan koneksi
6. **API Key** — apakah terkonfigurasi dan bisa connect ke provider
7. **MCP Servers** — status setiap MCP yang aktif
8. **Disk Space** — ketersediaan ruang disk

## Format Output

Tampilkan hasil dalam format tabel sederhana:

```
Komponen      Status    Versi
──────────    ──────    ──────
Node.js       ✅ OK     v20.x.x
npm           ✅ OK     10.x.x
Docker        ✅ OK     24.x.x
Git           ✅ OK     2.x.x
Kilo CLI      ✅ OK
API Key       ✅ OK     (Anthropic)
Disk Space    ✅ OK     45GB tersisa
```

## Jika Ada Masalah

Untuk setiap komponen yang bermasalah:
- Tampilkan pesan error yang jelas
- Berikan solusi untuk memperbaiki
- Tunjukkan command yang perlu dijalankan
