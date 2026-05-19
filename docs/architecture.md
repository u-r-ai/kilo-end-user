# Arsitektur Kilo End-User

Dokumen ini menjelaskan bagaimana Kilo End-User bekerja dan bagaimana komponen-komponennya saling terhubung.

## Gambaran Umum

Kilo End-User adalah konfigurasi siap pakai untuk [Kilo CLI](https://kilo.ai) — AI software builder yang berjalan di terminal. Proyek ini menyediakan agen AI berbahasa Indonesia, skill bawaan, dan konfigurasi yang sudah dioptimalkan agar user non-teknis bisa langsung membuat software.

```
┌─────────────────────────────────────────────────────┐
│                    Kilo CLI                          │
│  ┌─────────────┐  ┌────────────┐  ┌──────────────┐ │
│  │   Agents    │  │  Commands  │  │    Skills     │ │
│  │ assistant.md│  │ start.md   │  │ project-     │ │
│  │             │  │ status.md  │  │ builder/     │ │
│  └──────┬──────┘  └────────────┘  └──────┬───────┘ │
│         │                                 │         │
│         └──────────┬──────────────────────┘         │
│                    ▼                                │
│         ┌──────────────────┐                        │
│         │   kilo.jsonc     │ (konfigurasi utama)    │
│         └──────────────────┘                        │
└─────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────────┐
│                  Environment                          │
│  ┌──────────┐  ┌───────────┐  ┌───────────────────┐ │
│  │  Docker   │  │  Node.js   │  │  MCP Servers      │ │
│  │ Compose   │  │ npm/npx   │  │  filesystem, git,  │ │
│  │           │  │           │  │  docker, memory    │ │
│  └──────────┘  └───────────┘  └───────────────────┘ │
└─────────────────────────────────────────────────────┘
```

## Komponen Utama

### 1. Kilo CLI

Inti dari sistem. Kilo CLI adalah AI coding agent yang berjalan di terminal. Ia membaca konfigurasi, memuat agen dan skill, lalu berinteraksi dengan user melalui chat.

- **Runtime:** Node.js (via npm)
- **Konfigurasi:** `~/.config/kilo/kilo.jsonc`
- **Komunikasi:** CLI chat di terminal

### 2. Agent Config (`config/agents/assistant.md`)

Agen utama yang mendefinisikan perilaku AI. File ini dalam format frontmatter YAML + markdown yang berisi:

- **Description & Mode:** Menentukan peran agen (primary = agen default)
- **Permissions:** Izin yang dimiliki agen (bash, edit, read, glob, grep)
- **Instruksi:** Panduan perilaku — selalu pakai Bahasa Indonesia, fokus pada outcome, user non-teknis
- **Error Recovery:** Prosedur identifikasi → perbaiki → retry → eskalasi
- **Response Style:** Format output yang ringkas dan actionable

### 3. Commands (`config/commands/`)

Command khusus yang bisa dipanggil user di chat Kilo:

| Command | File | Fungsi |
|---------|------|--------|
| `/start` | `start.md` | Memulai project baru dengan struktur rapi |
| `/status` | `status.md` | Mengecek komponen sistem |

Commands ini memberi user cara cepat memicu tindakan spesifik tanpa harus mengetik panjang.

### 4. Skills (`config/skills/project-builder/SKILL.md`)

Skill adalah panduan teknis yang memperluas kemampuan agen untuk tugas tertentu. Project Builder skill berisi:

- Cara menganalisa kebutuhan user
- Template struktur project
- Panduan Docker setup (satu-satunya sumber kebenaran untuk aturan infrastruktur)
- Checklist kualitas dan keamanan

Skills berbeda dengan agent config — agent menentukan *perilaku*, skill menentukan *pengetahuan teknis*.

### 5. MCP (Model Context Protocol)

Kilo menggunakan MCP untuk memberikan akses ke lingkungan lokal via protocol standar. Server MCP yang dikonfigurasi:

| Server | Fungsi |
|--------|--------|
| filesystem | Akses file di direktori project (`~/kilo-projects`) |
| git | Operasi Git — commit, branch, log |
| docker | Kelola container Docker |
| memory | Simpan konteks antar sesi |

MCP memungkinkan agen AI berinteraksi dengan lingkungan nyata — membaca file, menjalankan Git, mengelola Docker — tanpa perlu tool terpisah.

### 6. Konfigurasi Utama (`kilo.jsonc`)

File JSON yang mengatur:

- **model & provider:** AI model yang dipakai
- **permissions:** Izin default (bash: ask, edit: allow)
- **MCP servers:** Daftar server yang aktif
- **TUI settings:** Pengaturan tampilan terminal

## Alur Kerja

### Saat User Membuka Kilo

```
User ketik "kilo" di terminal
        │
        ▼
Kilo CLI membaca kilo.jsonc
        │
        ▼
Memuat agent assistant.md (primary)
        │
        ▼
Mengaktifkan MCP servers
        │
        ▼
Menampilkan prompt — siap menerima input
        │
        ▼
User memberi task → AI memproses → menampilkan rencana
```

### Saat AI Membuat Aplikasi

```
User: "Buat aplikasi kasir"
        │
        ▼
1. Analisa kebutuhan (membaca instruksi agent)
        │
        ▼
2. Buat rencana (PLAN MODE)
        │
        ▼
3. Buat struktur project
        │
        ▼
4. Tulis kode + docker-compose.yml (dengan panduan SKILL.md)
        │
        ▼
5. Setup database via Docker (via MCP docker)
        │
        ▼
6. Jalankan dan verifikasi
        │
        ▼
7. Jelaskan cara pakai ke user
```

## Docker Lifecycle

Setiap project yang dibuat oleh Kilo menggunakan Docker Compose:

1. **Create** — AI menulis `docker-compose.yml` dengan service yang dibutuhkan (app, database, cache, dll.)
2. **Build** — `docker compose build` atau `docker compose up --build`
3. **Run** — `docker compose up -d` (background) atau `docker compose up` (foreground)
4. **Stop** — `docker compose down`
5. **Rebuild** — `docker compose up --build` setelah ada perubahan

Docker memastikan aplikasi berjalan konsisten di lingkungan manapun — Linux, WSL, atau server.

## Keamanan

- **File permission:** `kilo.jsonc` diset chmod 600 (hanya user bisa baca)
- **MCP scope:** Filesystem server dibatasi ke `~/kilo-projects`
- **Bash default:** Diset ke `ask` — minta konfirmasi sebelum menjalankan perintah
- **API key:** Disimpan di `kilo.jsonc`, tidak pernah di-commit atau dibagikan
- **Credential layanan eksternal:** Disimpan di `.env`, bukan di kode

## Teknologi yang Digunakan

| Komponen | Teknologi |
|----------|-----------|
| AI runtime | Kilo CLI (Node.js) |
| Container | Docker + Docker Compose |
| AI models | DeepSeek, Anthropic, OpenAI, Gemini, OpenRouter |
| Protocol | MCP (Model Context Protocol) |
| Package manager | npm / npx |
| Database | PostgreSQL (via Docker) |
| Cache | Redis (via Docker) |
| File storage | MinIO (via Docker) |
