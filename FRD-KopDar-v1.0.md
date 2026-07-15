# KopDar — Functional Requirements Document (FRD)
## Koperasi Digital untuk Gig Worker Indonesia
### Version 1.0 — 15 Juli 2026

---

## Daftar Isi

1. [Executive Summary](#1-executive-summary)
2. [Product Vision & Scope](#2-product-vision--scope)
3. [System Architecture Overview](#3-system-architecture-overview)
4. [User Roles & Personas](#4-user-roles--personas)
5. [Driver App — Functional Requirements](#5-driver-app--functional-requirements)
6. [Customer App — Functional Requirements](#6-customer-app--functional-requirements)
7. [Matching Engine & Order Flow](#7-matching-engine--order-flow)
8. [Payment & Billing](#8-payment--billing)
9. [Admin Dashboard & Backend](#9-admin-dashboard--backend)
10. [Non-Functional Requirements](#10-non-functional-requirements)
11. [Data Model Overview](#11-data-model-overview)
12. [Integration Points](#12-integration-points)
13. [Risk & Mitigation](#13-risk--mitigation)
14. [Glossary](#14-glossary)

---

## 1. Executive Summary

**KopDar** (Koperasi Digital) adalah platform dua sisi yang melayani gig worker Indonesia (terutama driver ojol) dan customer yang membutuhkan layanan transportasi, pengantaran makanan, dan pengiriman paket.

**Problem Statement:**
- 7 juta+ driver ojol Indonesia hidup dengan penghasilan tidak stabil, tanpa jaminan sosial, dan tanpa suara kolektif
- Customer membayar premium yang tinggi akibat komisi platform 20-25%
- Tidak ada platform yang benar-benar dimiliki dan menguntungkan pekerja

**Solution:**
- **Driver-side:** Financial dashboard, tabungan kolektif, asuransi mikro, komunitas independen, SOS darurat, advocacy berbasis data
- **Customer-side:** Order ride/food/package dengan harga lebih murah (komisi driver cuma 5-8%), driver favorit, transparansi harga

**Differentiator utama:**
- Komisi 5-8% (vs Gojek/Grab 20%+)
- Data milik driver, bukan milik platform
- Advocacy & bargaining power berbasis data kolektif
- Produk keuangan independen (bukan milik platform)

---

## 2. Product Vision & Scope

### 2.1 Vision
> "Menjadi sistem operasi hidup bagi gig worker Indonesia — yang bekerja untuk pekerja, bukan untuk platform."

### 2.2 Scope — In Scope

| Layer | Fitur | Phase |
|-------|-------|-------|
| Driver App | Income tracker multi-platform | A |
| Driver App | Expense tracker & profit calculator | A |
| Driver App | Pinjol radar | A |
| Driver App | Tabungan kolektif | A |
| Driver App | Asuransi mikro | A |
| Driver App | Komunitas forum | A |
| Driver App | Advocacy dashboard | A |
| Driver App | Profil & kartu anggota | A |
| Driver App | SOS & emergency | A |
| Driver App | Terima order KopDar (matching) | B |
| Customer App | Order ride | B |
| Customer App | Order food delivery | B |
| Customer App | Order package delivery | B |
| Customer App | Payment (cash/QRIS/wallet) | B |
| Customer App | Rating & review | B |
| Customer App | Driver favorit | B |
| Backend | Matching engine | B |
| Backend | Pricing engine | B |
| Backend | Admin dashboard | B |
| Backend | Merchant management (food) | C |
| Backend | Franchise/zone management | C |

### 2.3 Out of Scope (v1)
- Autonomous vehicle integration
- Multi-country expansion
- In-app advertising marketplace
- Vehicle leasing/financing
- Driver training LMS (handled by partner)

---

## 3. System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                              │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐ │
│  │  Driver App   │  │ Customer App │  │   Admin Dashboard     │ │
│  │  (Flutter)    │  │  (Flutter)   │  │   (React/Next.js)     │ │
│  │  Android/iOS  │  │  Android/iOS │  │   Web                 │ │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬────────────┘ │
│         │                  │                      │              │
└─────────┼──────────────────┼──────────────────────┼──────────────┘
          │                  │                      │
          ▼                  ▼                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                        API GATEWAY                               │
│                   (Kong / AWS API Gateway)                       │
│              Rate limiting, Auth, Routing                        │
└────────────────────────────┬────────────────────────────────────┘
                             │
          ┌──────────────────┼──────────────────┐
          ▼                  ▼                  ▼
┌─────────────┐  ┌──────────────┐  ┌───────────────────┐
│   Auth      │  │  Core API    │  │  Matching Engine  │
│   Service   │  │  Service     │  │  Service          │
│  (Firebase  │  │  (Go)        │  │  (Go)             │
│   Auth)     │  │              │  │                   │
└─────────────┘  └──────┬───────┘  └─────────┬─────────┘
                        │                     │
                        ▼                     ▼
              ┌──────────────────┐  ┌──────────────────┐
              │   PostgreSQL     │  │    Redis          │
              │   (Primary DB)   │  │   (Cache/Queue)   │
              └──────────────────┘  └──────────────────┘
                        │
          ┌─────────────┼─────────────┐
          ▼             ▼             ▼
┌──────────────┐ ┌────────────┐ ┌──────────────┐
│  Payment     │ │ Notification│ │  Maps/Geo    │
│  Service     │ │ Service     │ │  Service     │
│  (Midtrans/  │ │ (Firebase   │ │  (Google     │
│   Xendit)    │ │  Cloud Msg) │ │   Maps API)  │
└──────────────┘ └────────────┘ └──────────────┘
```

### 3.1 Tech Stack

| Component | Technology | Alasan |
|-----------|-----------|--------|
| Mobile App (Driver) | Flutter | Cross-platform, offline support, 1 codebase |
| Mobile App (Customer) | Flutter | Shared widget library dengan driver app |
| Backend API | Go (Gin/Fiber) | High performance, low memory, cocok untuk real-time |
| Database | PostgreSQL + PostGIS | Relational + geospatial queries |
| Cache/Queue | Redis | Real-time matching, session, pub/sub |
| Auth | Firebase Auth | Phone OTP, mudah integrate |
| Payment | Midtrans + Xendit | Multi-channel (QRIS, VA, e-wallet, cash) |
| Push Notification | Firebase Cloud Messaging | Cross-platform push |
| Maps | Google Maps Platform | Geocoding, routing, ETA |
| Storage | Google Cloud Storage | Foto profil, dokumen, bukti |
| Monitoring | Grafana + Prometheus | Real-time system monitoring |
| CI/CD | GitHub Actions | Automated build, test, deploy |
| Admin Dashboard | React + Next.js | SSR, fast, modern |

### 3.2 API Design Principles
- RESTful untuk CRUD operations
- WebSocket untuk real-time (matching, location tracking, chat)
- Rate limiting per user tier
- JWT-based authentication
- API versioning (v1, v2, ...)
- Idempotency key untuk payment operations

---

## 4. User Roles & Personas

### 4.1 Driver (Mitra KopDar)

| Attribute | Detail |
|-----------|--------|
| **Demografi** | Laki-laki/perempuan, 20-45 tahun, Android user |
| **Tech literacy** | Rendah-sedang (familiar dengan WhatsApp, Gojek, Grab) |
| **Pain points** | Penghasilan tidak stabil, pinjol, kurang proteksi |
| **Goals** | Penghasilan lebih besar, hidup lebih aman, punya suara |
| **Device** | Android (70%+ budget phone, RAM 2-4GB) |
| **Connectivity** | 4G, kadang tidak stabil |

**Sub-personas:**
- **Budi (Full-time ojol):** Narik 10-14 jam/hari, 1 platform utama, penghasilan Rp 3-5jt/bulan
- **Rina (Part-time gig):** IRT yang narik pagi/sore, penghasilan sampingan Rp 1-2jt/bulan
- **Ahmad (Multi-platform):** Narik di Gojek + Grab + Shopee Food, penghasilan tersebar

### 4.2 Customer (Penumpang/Pengguna)

| Attribute | Detail |
|-----------|--------|
| **Demografi** | 18-55 tahun, urban, smartphone user |
| **Tech literacy** | Sedang-tinggi (sudah pakai Gojek/Grab) |
| **Pain points** | Harga mahal, surge pricing, driver sering cancel |
| **Goals** | Transportasi murah, reliable, driver yang kenal |
| **Device** | Android/iOS |
| **Payment preference** | Cash, GoPay, OVO, QRIS |

### 4.3 Admin (Tim KopDar)

| Attribute | Detail |
|-----------|--------|
| **Role** | Operasional, compliance, support, analytics |
| **Access** | Web dashboard |
| **Tasks** | Verifikasi driver, handle dispute, monitor metrics, kelola zona |

---

## 5. Driver App — Functional Requirements

### 5.1 Module: Registrasi & Onboarding

#### DR-REG-001: Registrasi Akun Driver
- **Actor:** Calon driver
- **Trigger:** Buka app → "Daftar sebagai Driver"
- **Flow:**
  1. Input nomor HP
  2. Kirim OTP via SMS
  3. Verifikasi OTP
  4. Input data diri:
     - Nama lengkap (sesuai KTP)
     - NIK (16 digit)
     - Alamat domisili
     - Foto KTP (OCR auto-extract)
     - Foto selfie dengan KTP
     - Nomor SIM (opsional)
  5. Input data kendaraan:
     - Tipe (motor/mobil)
     - Merek & model
     - Tahun
     - Plat nomor
     - Foto kendaraan
  6. Input data platform aktif:
     - Checklist: Gojek / Grab / Shopee Food / Maxim / InDrive / Lainnya
     - Screenshot profil masing-masing (opsional, untuk verifikasi)
  7. Input rekening bank / e-wallet untuk pencairan
  8. Setuju Syarat & Ketentuan
  9. Submit → status: "Menunggu Verifikasi"

- **Output:** Akun terdaftar, status pending
- **Business Rules:**
  - NIK harus unik (1 akun per NIK)
  - Nomor HP harus unik
  - Foto KTP harus jelas, OCR confidence > 80%
  - Verifikasi manual oleh admin jika OCR gagal
  - Maksimal 24 jam untuk proses verifikasi

#### DR-REG-002: Onboarding Flow
- **Actor:** Driver baru (setelah disetujui)
- **Trigger:** Login pertama setelah verifikasi
- **Flow:**
  1. Welcome screen: "Selamat datang di KopDar!"
  2. Quick tour (3-4 slide): fitur utama app
  3. Setup auto-tabung (opsional, bisa skip)
  4. Pilih zona operasi (kecamatan)
  5. Undang teman (opsional, referral code)
  6. Masuk ke dashboard

---

### 5.2 Module: Dashboard & Income Tracker

#### DR-DASH-001: Home Dashboard
- **Actor:** Driver yang sudah login
- **Trigger:** Buka app / navigasi ke Beranda
- **Tampilkan:**
  - Salam berdasarkan waktu (pagi/siang/sore/malam)
  - Nama driver
  - Penghasilan hari ini (gross & net)
  - Jumlah order hari ini
  - Jam narik hari ini
  - Rata-rata per order
  - Persentase perubahan vs kemarin
  - Quick actions: Tabungan, Asuransi, Komunitas, Keuangan
  - Alert card (jika ada: pinjol, asuransi expired, dll)
  - Progress dana darurat
  - 4 transaksi terakhir

#### DR-DASH-002: Income Tracker Multi-Platform
- **Actor:** Driver
- **Trigger:** Input penghasilan dari platform lain
- **Flow:**
  1. Pilih platform (Gojek/Grab/ShopeeFood/Maxim/InDrive/Cash)
  2. Input:
     - Jumlah order
     - Total penghasilan kotor
     - Total komisi/biaya platform
     - Screenshot struk (opsional, untuk verifikasi)
  3. Sistem hitung penghasilan bersih
- **Opsi input:**
  - Manual input (default)
  - Screenshot → OCR auto-extract (fitur premium)
  - Import dari e-wallet (GoPay/OVO statement)
- **Business Rules:**
  - Bisa input per hari atau per sesi narik
  - Data bisa diedit dalam 24 jam
  - Histori tersimpan permanen

#### DR-DASH-003: Expense Tracker
- **Actor:** Driver
- **Trigger:** Input pengeluaran
- **Kategori default:**
  - ⛽ Bensin / charge
  - 🍚 Makan & minum
  - 🏍️ Angsuran motor
  - 🔧 Servis & perawatan
  - 📱 Pulsa & data
  - 🅿️ Parkir
  - 💊 Kesehatan
  - 📦 Lainnya
- **Flow:**
  1. Pilih kategori
  2. Input nominal
  3. Catatan (opsional)
  4. Foto struk (opsional)
  5. Simpan
- **Business Rules:**
  - Bisa input kapan saja
  - Auto-kategorisasi berdasarkan keyword (AI-powered, v2)
  - Laporan mingguan & bulanan auto-generated

#### DR-DASH-004: Profit Calculator & Insights
- **Actor:** Driver
- **Trigger:** Buka halaman Keuangan / notifikasi mingguan
- **Tampilkan:**
  - Total penghasilan (per minggu/bulan)
  - Total pengeluaran
  - Profit bersih
  - Jam kerja efektif
  - Rata-rata per jam
  - Rata-rata per order
  - Breakdown per platform
  - Breakdown per kategori pengeluaran
  - Chart mingguan (bar chart)
  - **AI Insight:** "Minggu ini kamu narik 60 jam, profit Rp 2.1jt. Bensin naik 15% — coba cari order dekat rumah."
  - Perbandingan dengan rata-rata zona (anonim)

---

### 5.3 Module: Pinjol Radar

#### DR-PINJOL-001: Input Pinjaman Aktif
- **Actor:** Driver
- **Trigger:** Tambah pinjaman baru / dari onboarding
- **Input:**
  - Nama aplikasi pinjaman
  - Jumlah pinjaman
  - Bunga per bulan (%)
  - Jangka waktu
  - Cicilan per bulan
  - Tanggal mulai
- **Business Rules:**
  - Alert otomatis jika bunga > 2%/bulan → kategori "Berisiko Tinggi"
  - Alert otomatis jika total cicilan > 30% penghasilan → kategori "Over-leverage"
  - Simulasi: berapa total bunga yang dibayar jika lunas sesuai jadwal vs lunas lebih awal

#### DR-PINJOL-002: Pinjol Dashboard
- **Tampilkan:**
  - Daftar pinjaman aktif
  - Status per pinjaman (aman/waspada/berbahaya)
  - Total outstanding
  - Total bunga yang sudah dibayar
  - Estimasi hemat jika lunas lebih awal
  - Rekomendasi: "Lunasi Pinjaman X dulu — hemat Rp 90rb bunga"

---

### 5.4 Module: Tabungan Kolektif

#### DR-TABUNG-001: Setup Auto-Tabung
- **Actor:** Driver
- **Trigger:** Pengaturan tabungan
- **Flow:**
  1. Pilih tujuan tabungan (template):
     - 🏥 Dana Darurat (target: 3x penghasilan bulanan)
     - 🏍️ Servis Motor
     - 🎓 Dana Anak
     - 🏠 Dana Nikah / Rumah
     - 📦 Custom
  2. Set nominal harian (Rp 5.000 / 10.000 / 15.000 / custom)
  3. Set sumber: auto-potong dari KopDar wallet atau manual transfer
  4. Set target nominal (opsional)
  5. Konfirmasi → aktif

#### DR-TABUNG-002: Tabungan Dashboard
- **Tampilkan:**
  - Total saldo semua tabungan
  - Per tujuan: saldo, target, progress bar, estimasi tercapai
  - Riwayat setor & tarik
  - Grafik pertumbuhan

#### DR-TABUNG-003: Tarik Tabungan
- **Flow:**
  1. Pilih tujuan tabungan
  2. Input nominal yang mau ditarik
  3. Alasan penarikan (opsional)
  4. Konfirmasi OTP
  5. Dana cair ke rekening/e-wallet dalam 1x24 jam
- **Business Rules:**
  - Minimal saldo setelah tarik: Rp 50.000 (dana darurat)
  - Penarikan dana darurat butuh konfirmasi extra (kecuali emergency)
  - Tidak ada penalti penarikan (ini bukan deposito)

---

### 5.5 Module: Asuransi Mikro

#### DR-ASUR-001: Katalog Asuransi
- **Tampilkan:**
  - Daftar produk asuransi yang tersedia:
    - 🚑 Kecelakaan Kerja — santunan kecelakaan + rawat jalan
    - 🏥 Rawat Inap — cover rawat inap rumah sakit
    - 🛵 Kendaraan — kerusakan & kehilangan motor
    - 👨‍👩‍👧 Keluarga — cover pasangan & anak
  - Per produk: deskripsi, manfaat, harga, harga non-anggota (untuk comparison)
  - Badge "Anggota" untuk harga khusus

#### DR-ASUR-002: Beli Asuransi
- **Flow:**
  1. Pilih produk
  2. Review manfaat & syarat
  3. Isi data tambahan (riwayat kesehatan, data kendaraan, dll)
  4. Pilih metode bayar:
     - Auto-potong dari tabungan (bulanan)
     - Bayar manual via e-wallet/QRIS
  5. Konfirmasi → polis aktif
  6. Polis tersimpan di app (bisa di-download PDF)

#### DR-ASUR-003: Klaim Asuransi
- **Flow:**
  1. Buka halaman "Klaim"
  2. Pilih polis yang mau diklaim
  3. Upload bukti:
     - Foto kecelakaan / surat dokter / nota rumah sakit
     - Kronologi kejadian (text)
  4. Submit → status "Meninjau"
  5. Admin review → approve/reject
  6. Jika approve → dana cair ke rekening
- **Business Rules:**
  - Klaim harus diajukan maksimal 30 hari setelah kejadian
  - Maksimal 3 klaim per tahun per polis
  - Klaim ditolak: beri alasan + cara banding

---

### 5.6 Module: Komunitas & Forum

#### DR-KOM-001: Forum Feed
- **Tampilkan:**
  - Post dari sesama anggota (text + foto)
  - Filter: Zona saya / Terbaru / Populer / Advokasi
  - Interaksi: like, comment, share
  - Badge: zona driver (Jaksel, Depok, dll), platform (Gojek, Grab, dll)

#### DR-KOM-002: Buat Post
- **Flow:**
  1. Input text (maks 500 karakter)
  2. Tambah foto (opsional, maks 3)
  3. Pilih kategori: Tips / Pertanyaan / Keluhan / Info Zona / Advokasi
  4. Pilih visibility: Zona saya / Semua
  5. Posting

#### DR-KOM-003: Zona Channels
- **Deskripsi:** Per kecamatan ada channel khusus
- **Fitur:**
  - Info order ramai di zona
  - Peringatan zona sepi / macet
  - Event komunitas (kopdar offline, dll)

#### DR-KOM-004: Advokasi
- **Deskripsi:** Section khusus untuk isu ketenagakerjaan
- **Fitur:**
  - Data kolektif anonim (rata-rata penghasilan, jam kerja, keluhan)
  - Petisi digital (kumpulkan tanda tangan)
  - Update kebijakan (perubahan tarif, regulasi, dll)
  - Voting: "Setuju gak dengan kebijakan X?"

---

### 5.7 Module: SOS & Emergency

#### DR-SOS-001: Emergency Button
- **Actor:** Driver
- **Trigger:** Tekan tombol SOS di home screen
- **Flow:**
  1. Konfirmasi: "Kirim panggilan darurat?" (5 detik countdown, bisa batal)
  2. Jika dikonfirmasi:
     - Kirim lokasi real-time ke kontak darurat (SMS + push)
     - Kirim notifikasi ke 3 driver KopDar terdekat
     - Tampilkan info medis di layar (bisa diakses tanpa unlock)
     - Auto-call 112 (opsional, tergantung setting)
  3. Driver bisa update status: "Dalam perjalanan ke RS" / "Sudah ditolong" / "False alarm"

#### DR-SOS-002: Crash Detection
- **Deskripsi:** Accelerometer detect benturan keras → auto-trigger SOS
- **Flow:**
  1. Deteksi sudden deceleration (threshold configurable)
  2. Popup: "Kecelakaan terdeteksi! Kirim SOS dalam 10 detik?"
  3. Countdown 10 detik
  4. Jika tidak dibatalkan → auto-kirim SOS
  5. Jika dibatalkan → log false positive
- **Business Rules:**
  - Hanya aktif saat driver mode "Narik"
  - Sensitivity bisa diatur (rendah/sedang/tinggi)
  - Log semua deteksi untuk tuning algoritma

#### DR-SOS-003: Info Medis Darurat
- **Input:**
  - Golongan darah
  - Alergi
  - Riwayat penyakit
  - Obat yang sedang dikonsumsi
  - Kontak darurat (nama + nomor HP)
- **Tampilkan:** Full-screen tanpa unlock (via notification widget)

#### DR-SOS-004: Nearby Driver Response
- **Deskripsi:** Saat SOS aktif, driver terdekat dapat notifikasi
- **Notifikasi:** "Rekan kamu [Nama] mengirim panggilan darurat di [Lokasi]. Bisa bantu?"
- **Response:** Accept / Decline
- **Jika accept:** Tampilkan navigasi ke lokasi + kontak driver

---

### 5.8 Module: Profil & Kartu Anggota

#### DR-PROF-001: Profil Driver
- **Tampilkan:**
  - Foto profil
  - Nama
  - Zona operasi
  - Platform aktif
  - Rating (dari customer KopDar, v2)
  - Total order
  - Hari aktif
  - Level keanggotaan (Bronze/Silver/Gold/Platinum)
  - Kartu anggota digital (ID: KPD-YYYY-XXXXX)

#### DR-PROF-002: Referral Program
- **Flow:**
  1. Driver dapat kode referral unik
  2. Share ke sesama driver
  3. Driver baru daftar pakai kode → kedua dapat bonus tabungan Rp 25.000
- **Tracking:** Jumlah referral, bonus earned, status referral

#### DR-PROF-003: Settings
- **Pengaturan:**
  - Auto-tabung (on/off, nominal)
  - Notifikasi (order, komunitas, promosi)
  - Zona operasi
  - Bahasa (Indonesia / Inggris)
  - Kontak darurat
  - Info medis
  - Keamanan (PIN, fingerprint)
  - Hapus akun

---

### 5.9 Module: Order Management (Phase B — Customer-Side Integration)

#### DR-ORDER-001: Terima Notifikasi Order
- **Trigger:** Customer membuat order, sistem match ke driver
- **Tampilkan:**
  - Jenis order (Ride / Food / Package)
  - Lokasi penjemputan
  - Lokasi tujuan
  - Estimasi harga
  - Jarak ke penjemputan
  - Nama customer + rating
  - Countdown accept (30 detik)
- **Action:** Accept / Reject

#### DR-ORDER-002: Navigate ke Customer
- **Setelah accept:**
  - Tampilkan navigasi ke lokasi penjemputan (Google Maps integration)
  - Status: "Menuju penjemputan"
  - Customer bisa lacak driver real-time
  - Chat / call customer (via in-app, nomor disamarkan)

#### DR-ORDER-003: Proses Order
- **Ride:**
  1. Sampai di titik jemput → tekan "Sampai"
  2. Customer naik → tekan "Mulai Perjalanan"
  3. Navigasi ke tujuan
  4. Sampai → tekan "Selesai"
  5. Tampilkan harga final
  6. Terima pembayaran (cash / QRIS / wallet)
  7. Customer kasih rating
  8. Order selesai

- **Food:**
  1. Navigate ke merchant
  2. Ambil pesanan → tekan "Pesanan Diambil"
  3. Navigate ke customer
  4. Sampai → tekan "Selesai"
  5. Terima pembayaran
  6. Order selesai

- **Package:**
  1. Navigate ke pengirim
  2. Ambil paket → tekan "Paket Diambil"
  3. Navigate ke penerima
  4. Sampai → tekan "Selesai" + foto bukti
  5. Terima pembayaran
  6. Order selesai

#### DR-ORDER-004: Earnings per Order
- **Setelah order selesai, tampilkan:**
  - Harga order
  - Komisi KopDar (5-8%)
  - Penghasilan bersih driver
  - Akumulasi hari ini

---

## 6. Customer App — Functional Requirements

### 6.1 Module: Registrasi & Onboarding

#### CU-REG-001: Registrasi Akun Customer
- **Actor:** Calon customer
- **Flow:**
  1. Input nomor HP
  2. Verifikasi OTP
  3. Input nama lengkap
  4. Set PIN / fingerprint
  5. (Opsional) Set alamat rumah & kantor
  6. Selesai → masuk home screen

#### CU-REG-002: Onboarding
- **Flow:**
  1. Welcome screen
  2. Quick tour (3 slide)
  3. Set payment preference
  4. Masuk home screen

---

### 6.2 Module: Home & Order

#### CU-HOME-001: Home Screen
- **Tampilkan:**
  - Map view (lokasi saya sekarang)
  - Search bar: "Mau ke mana?"
  - Quick actions:
    - 🚗 Ride
    - 🍔 Food
    - 📦 Package
  - Riwayat perjalanan terakhir
  - Promo/banner (jika ada)

#### CU-ORDER-001: Order Ride
- **Flow:**
  1. Input titik jemput (auto-detect GPS + manual adjust)
  2. Input tujuan (search alamat / pilih dari favorit)
  3. Tampilkan:
     - Estimasi harga (flat rate, bukan surge)
     - Estimasi waktu tempuh
     - Estimasi driver terdekat
  4. Pilih tipe kendaraan:
     - 🏍️ Motor (paling murah)
     - 🚗 Mobil (4 penumpang)
  5. (Opsional) Pilih driver favorit → "Minta [Nama]"
  6. Konfirmasi order → sistem mencarikan driver
  7. Menunggu → driver accept → tampilkan driver + ETA
  8. Driver sampai → naik → perjalanan
  9. Sampai → tampilkan harga final
  10. Bayar (cash / QRIS / wallet)
  11. Rating driver (1-5 bintang + komentar)
  12. Selesai

#### CU-ORDER-002: Order Food
- **Flow:**
  1. Tampilkan daftar merchant di zona (filter: jarak, rating, kategori)
  2. Pilih merchant → lihat menu
  3. Tambah ke keranjang
  4. Checkout → pilih alamat antar
  5. Tampilkan:
     - Harga makanan
     - Ongkir (flat rate)
     - Total
  6. Konfirmasi → sistem mencarikan driver
  7. Driver ke merchant → ambil pesanan → antar
  8. Sampai → bayar → rating

#### CU-ORDER-003: Order Package
- **Flow:**
  1. Input alamat penjemputan
  2. Input alamat tujuan
  3. Input detail paket:
     - Ukuran (kecil/sedang/besar)
     - Berat (estimasi)
     - Catatan (fragile, dll)
  4. Tampilkan estimasi harga
  5. Konfirmasi → sistem mencarikan driver
  6. Driver ambil paket → antar
  7. Sampai → foto bukti → bayar → selesai

---

### 6.3 Module: Payment

#### CU-PAY-001: Payment Methods
- **Didukung:**
  - Cash (tunai)
  - QRIS (universal)
  - GoPay
  - OVO
  - Dana
  - ShopeePay
  - KopDar Wallet (internal)
  - Transfer bank (virtual account)

#### CU-PAY-002: KopDar Wallet
- **Fitur:**
  - Top-up via transfer bank / QRIS / e-wallet
  - Saldo untuk bayar order
  - Cashback 5% untuk order pertama
  - Riwayat transaksi

#### CU-PAY-003: Split Bill
- **Fitur:** Patungan ongkos dengan teman
- **Flow:**
  1. Setelah order selesai → "Split Bill"
  2. Pilih kontak / input nomor HP teman
  3. Bagi rata atau custom amount
  4. Kirim link pembayaran

---

### 6.4 Module: Rating & Review

#### CU-RATE-001: Rating Driver
- **Setelah order selesai:**
  - Bintang 1-5
  - Komentar (opsional)
  - Quick tags: "Tepat waktu", "Ramah", "Bersih", "Navigasi lancar"
- **Tersimpan** di profil driver (agregat, bukan per-order publik)

#### CU-RATE-002: Favorite Driver
- **Fitur:** Tandai driver sebagai favorit
- **Benefit:**
  - Saat order, bisa minta driver favorit dulu
  - Notifikasi saat driver favorit online
  - Prioritas matching saat driver favorit available

---

### 6.5 Module: History & Receipt

#### CU-HIST-001: Riwayat Order
- **Tampilkan:**
  - Daftar order (terbaru → terlama)
  - Per order: tanggal, jenis, rute, harga, driver, rating
  - Filter: Ride / Food / Package
  - Search: berdasarkan alamat / tanggal

#### CU-HIST-002: E-Receipt
- **Per order:**
  - Detail rute (map snapshot)
  - Breakdown harga
  - Metode bayar
  - Invoice number
  - Download PDF

---

### 6.6 Module: Profile & Settings

#### CU-PROF-001: Customer Profile
- **Data:**
  - Foto profil
  - Nama
  - Nomor HP
  - Alamat favorit (rumah, kantor, dll)
  - Payment methods
  - Rating (dari driver)

#### CU-PROF-002: Settings
- **Pengaturan:**
  - Keamanan (PIN, fingerprint)
  - Notifikasi
  - Bahasa
  - Alamat favorit
  - Payment methods
  - Hapus akun

---

## 7. Matching Engine & Order Flow

### 7.1 Matching Algorithm

```
Input: order (pickup_location, destination, vehicle_type)
Output: matched_driver

Step 1: Filter eligible drivers
  - Status: online
  - Vehicle type matches
  - Within radius (default: 3km, max: 10km)
  - Not currently on order
  - Rating > 4.0 (configurable)

Step 2: Score drivers
  score = (w1 * proximity) + (w2 * rating) + (w3 * acceptance_rate) + (w4 * favorite_bonus)
  
  Where:
  - proximity: 1 - (distance / max_radius) → closer = higher
  - rating: driver_rating / 5.0
  - acceptance_rate: accepted / (accepted + rejected) last 30 days
  - favorite_bonus: 0.3 if driver is customer's favorite, else 0
  
  Weights (configurable per zone):
  - w1 = 0.4 (proximity paling penting)
  - w2 = 0.25
  - w3 = 0.2
  - w4 = 0.15

Step 3: Offer to top 3 drivers (simultaneous)
  - Send push notification
  - Countdown: 30 seconds
  - First to accept → matched
  - If none accept → expand radius → repeat
  - If still none → notify customer: "No driver available"

Step 4: Matched
  - Notify customer: driver name, ETA, vehicle info
  - Notify driver: customer name, pickup, destination, price
  - Start tracking
```

### 7.2 Pricing Engine

```
Base fare + (per_km_rate * distance) + (per_min_rate * duration)

Ride (Motor):
  - Base fare: Rp 3.000
  - Per km: Rp 2.500
  - Per minute: Rp 300
  - Minimum fare: Rp 8.000

Ride (Car):
  - Base fare: Rp 5.000
  - Per km: Rp 4.000
  - Per minute: Rp 500
  - Minimum fare: Rp 15.000

Food Delivery:
  - Base fare: Rp 3.000
  - Per km: Rp 2.000
  - Minimum fare: Rp 7.000

Package:
  - Base fare: Rp 4.000
  - Per km: Rp 2.500
  - Size multiplier: small=1.0, medium=1.3, large=1.6
  - Minimum fare: Rp 10.000

NO SURGE PRICING (fixed multiplier 1.0x always)
Tipping: optional, 100% goes to driver
```

### 7.3 Order State Machine

```
CREATED → MATCHING → MATCHED → DRIVER_EN_ROUTE → DRIVER_ARRIVED → 
  → IN_PROGRESS → COMPLETED → RATED

                    ↘ CANCELLED (by customer/driver at any point before COMPLETED)
                    
                    ↘ FAILED (no driver found after 5 min retry)
```

---

## 8. Payment & Billing

### 8.1 Payment Flow

```
Order selesai → Harga final ditampilkan
  ├── Cash → Driver terima langsung → Konfirmasi di app
  ├── QRIS → Customer scan → Payment gateway → Konfirmasi
  ├── E-wallet → Redirect ke app → Payment → Konfirmasi
  └── KopDar Wallet → Auto-debit → Konfirmasi

Settlement ke driver:
  - Cash: Driver sudah terima, saldo KopDar driver + 0
  - Digital: T+1 settlement ke rekening driver (setelah dikurangi komisi 5-8%)
```

### 8.2 Komisi Structure

| Jenis Order | Komisi KopDar | Ke Driver |
|------------|---------------|-----------|
| Ride | 6% | 94% |
| Food | 8% | 92% |
| Package | 7% | 93% |

**Perhitungan:**
```
Order Ride: Rp 25.000
Komisi KopDar (6%): Rp 1.500
Driver terima: Rp 23.500

(vs Gojek 20%: driver cuma dapat Rp 20.000)
→ Driver KopDar dapat Rp 3.500 lebih banyak per order
```

### 8.3 Refund & Dispute

| Scenario | Action |
|----------|--------|
| Customer cancel sebelum driver accept | Gratis, no charge |
| Customer cancel setelah driver accept (driver sudah jalan) | Cancel fee Rp 3.000 ke driver |
| Customer cancel saat perjalanan | Bayar pro-rata jarak tempuh |
| Driver cancel | Re-match gratis ke customer, driver kena warning |
| Dispute (customer complain) | Admin review dalam 24 jam |
| Refund | Kembali ke payment method asal dalam 3-5 hari |

---

## 9. Admin Dashboard & Backend

### 9.1 Admin Roles

| Role | Permissions |
|------|-----------|
| **Super Admin** | Full access, manage other admins |
| **Operations** | Verify drivers, handle disputes, manage zones |
| **Finance** | View settlements, manage refunds, financial reports |
| **Support** | Handle customer/driver complaints, chat support |
| **Analytics** | View dashboards, export data, generate reports |

### 9.2 Admin Features

#### ADM-001: Driver Verification Queue
- **Tampilkan:** Daftar driver pending verifikasi
- **Per driver:** Foto KTP, selfie, data diri, status OCR
- **Action:** Approve / Reject (dengan alasan) / Request More Info
- **SLA:** Verifikasi dalam 24 jam

#### ADM-002: Dispute Management
- **Tampilkan:** Daftar dispute dari customer/driver
- **Per dispute:** Order detail, complaint, evidence, history
- **Action:** Refund / Warning / Suspend / No Action
- **SLA:** Resolusi dalam 48 jam

#### ADM-003: Zone Management
- **Fitur:**
  - Tambah/edit/hapus zona operasi
  - Set pricing per zona
  - Set radius matching per zona
  - Monitor driver density per zona
  - Heatmap order density

#### ADM-004: Financial Dashboard
- **Tampilkan:**
  - Total GMV (Gross Merchandise Value)
  - Total komisi
  - Total settlement ke driver
  - Outstanding settlement
  - Refund amount
  - Revenue per zona
  - Revenue per hari/minggu/bulan

#### ADM-005: Analytics Dashboard
- **Metrics:**
  - DAU / MAU (driver & customer)
  - Order volume (harian, mingguan, bulanan)
  - Average order value
  - Driver utilization rate
  - Customer retention rate
  - Churn rate
  - NPS (Net Promoter Score)
  - Rating distribution
  - Top zona by volume
  - Peak hours analysis

#### ADM-006: Support Chat
- **Fitur:** Live chat antara admin dan driver/customer
- **Ticket system:** Auto-create ticket dari complaint
- **Canned responses:** Template jawaban umum

---

## 10. Non-Functional Requirements

### 10.1 Performance

| Metric | Target |
|--------|--------|
| App launch time | < 3 seconds |
| API response time (p95) | < 500ms |
| Matching latency | < 5 seconds |
| Map load time | < 2 seconds |
| Concurrent users per zone | 10.000+ |

### 10.2 Scalability

| Component | Strategy |
|-----------|----------|
| API servers | Horizontal scaling (Kubernetes) |
| Database | Read replicas, partitioning by zone |
| Redis | Cluster mode |
| File storage | CDN + auto-scaling |
| Matching engine | Stateless, zone-partitioned |

### 10.3 Availability

| Metric | Target |
|--------|--------|
| Uptime | 99.5% (4.38 hours downtime/year) |
| RTO (Recovery Time Objective) | < 1 hour |
| RPO (Recovery Point Objective) | < 5 minutes |
| Backup | Daily full, hourly incremental |

### 10.4 Security

| Requirement | Detail |
|-------------|--------|
| Authentication | JWT + refresh token, phone OTP |
| Authorization | RBAC (Role-Based Access Control) |
| Data encryption | TLS 1.3 in transit, AES-256 at rest |
| PII handling | KTP, foto, nomor HP → encrypted storage |
| API security | Rate limiting, input validation, SQL injection prevention |
| Payment security | PCI-DSS compliant (via payment gateway) |
| Audit log | Semua admin action logged |

### 10.5 Offline Support (Driver App)

| Feature | Offline Behavior |
|---------|-----------------|
| Income/expense tracker | Bisa input offline, sync saat online |
| Community forum | Read dari cache, post queue saat online |
| Emergency SOS | Tetap kirim SMS jika internet mati |
| Tabungan | View saldo dari cache, transaksi butuh online |
| Order | Butuh online (real-time matching) |

### 10.6 Accessibility

| Requirement | Detail |
|-------------|--------|
| Font size | Minimum 12sp, adjustable |
| Color contrast | WCAG AA compliant |
| Touch target | Minimum 48dp |
| Screen reader | Basic TalkBack/VoiceOver support |
| Language | Indonesia (default), English |

### 10.7 Device Support

| Platform | Minimum | Recommended |
|----------|---------|-------------|
| Android | API 23 (6.0), RAM 2GB | API 31+ (12+), RAM 4GB |
| iOS | iOS 14 | iOS 16+ |
| App size | < 30MB (initial download) | — |

---

## 11. Data Model Overview

### 11.1 Core Entities

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    User      │────<│   Driver    │     │  Customer   │
│─────────────│     │─────────────│     │─────────────│
│ id (PK)      │     │ id (PK)      │     │ id (PK)      │
│ phone        │     │ user_id (FK) │     │ user_id (FK) │
│ name         │     │ nik          │     │ home_address │
│ role         │     │ ktp_photo    │     │ work_address │
│ created_at   │     │ selfie_photo │     │ fav_drivers  │
│ updated_at   │     │ vehicle_type │     │ rating       │
└─────────────┘     │ vehicle_plat │     └──────┬──────┘
                     │ zone_id      │            │
                     │ status       │            │
                     │ rating       │            │
                     │ level        │            │
                     │ referral_code│            │
                     └──────┬──────┘            │
                            │                    │
                            ▼                    ▼
                     ┌─────────────────────────────┐
                     │           Order               │
                     │─────────────────────────────│
                     │ id (PK)                       │
                     │ customer_id (FK)              │
                     │ driver_id (FK)                │
                     │ type (ride/food/package)      │
                     │ status                        │
                     │ pickup_lat, pickup_lng        │
                     │ pickup_address                │
                     │ dest_lat, dest_lng            │
                     │ dest_address                  │
                     │ distance_km                   │
                     │ duration_min                  │
                     │ price                         │
                     │ commission                    │
                     │ driver_earnings               │
                     │ payment_method                │
                     │ payment_status                │
                     │ customer_rating               │
                     │ driver_rating                 │
                     │ created_at                    │
                     │ completed_at                  │
                     └─────────────┬───────────────┘
                                   │
              ┌────────────────────┼────────────────────┐
              ▼                    ▼                    ▼
    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
    │ Transaction   │    │   Review     │    │  Dispute     │
    │──────────────│    │──────────────│    │──────────────│
    │ id (PK)       │    │ id (PK)       │    │ id (PK)       │
    │ order_id (FK) │    │ order_id (FK) │    │ order_id (FK) │
    │ type          │    │ from_user_id  │    │ from_user_id  │
    │ amount        │    │ to_user_id    │    │ description   │
    │ method        │    │ rating        │    │ evidence_urls │
    │ status        │    │ comment       │    │ status        │
    │ settled_at    │    │ tags          │    │ resolution    │
    └──────────────┘    └──────────────┘    └──────────────┘

┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  Saving       │    │  Insurance   │    │  Community   │
│──────────────│    │──────────────│    │──────────────│
│ id (PK)       │    │ id (PK)       │    │ id (PK)       │
│ driver_id     │    │ driver_id     │    │ driver_id     │
│ goal_name     │    │ product_type  │    │ content       │
│ target_amount │    │ premium       │    │ category      │
│ current_amount│    │ coverage      │    │ zone_id       │
│ daily_amount  │    │ status        │    │ likes         │
│ status        │    │ start_date    │    │ comments      │
│ created_at    │    │ end_date      │    │ created_at    │
└──────────────┘    └──────────────┘    └──────────────┘

┌──────────────┐    ┌──────────────┐
│  Pinjol       │    │  Zone        │
│──────────────│    │──────────────│
│ id (PK)       │    │ id (PK)       │
│ driver_id     │    │ name          │
│ app_name      │    │ city          │
│ principal     │    │ boundaries    │ (GeoJSON polygon)
│ interest_rate │    │ base_fare     │
│ monthly_install│   │ per_km_rate   │
│ start_date    │    │ per_min_rate  │
│ end_date      │    │ status        │
│ risk_level    │    └──────────────┘
└──────────────┘

┌──────────────┐
│  Emergency    │
│──────────────│
│ id (PK)       │
│ driver_id     │
│ type          │ (manual / crash_detected)
│ lat, lng      │
│ status        │ (active / resolved / false_alarm)
│ responders    │ (JSON array of driver_ids)
│ created_at    │
│ resolved_at   │
└──────────────┘
```

---

## 12. Integration Points

### 12.1 Third-Party Services

| Service | Provider | Use Case |
|---------|----------|----------|
| SMS OTP | Twilio / Infobip | Registrasi, login, verifikasi |
| Payment Gateway | Midtrans + Xendit | QRIS, VA, e-wallet |
| Maps | Google Maps Platform | Geocoding, routing, ETA, places |
| Push Notification | Firebase Cloud Messaging | Order, community, emergency |
| Cloud Storage | Google Cloud Storage | Foto KTP, bukti, dokumen |
| OCR | Google Cloud Vision | KTP auto-extraction |
| Email | SendGrid | Laporan, notifikasi, newsletter |
| Analytics | Mixpanel / Amplitude | User behavior tracking |
| Crash Reporting | Firebase Crashlytics | App stability monitoring |

### 12.2 Platform Integration (Future)

| Platform | Integration Type | Status |
|----------|-----------------|--------|
| Gojek | Screenshot OCR (income import) | Phase A |
| Grab | Screenshot OCR (income import) | Phase A |
| BPJS Ketenagakerjaan | API (daftar anggota) | Phase B |
| Bank (BCA, BRI, Mandiri) | Open Banking API (cek saldo) | Phase C |

---

## 13. Risk & Mitigation

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Chicken-and-egg (customer-driver) | Critical | High | Mulai dari zona kecil, driver rekrut customer sendiri |
| Gojek/Grab counter-attack | High | Medium | Stay under radar, fokus niche, jangan head-to-head |
| Insiden keamanan (customer/driver) | Critical | Low | Verifikasi KTP, asuransi wajib, SOS, rating system |
| Burn rate tinggi | High | High | Bootstrap, komisi rendah = butuh volume, jangan subsidi |
| Regulasi | Medium | Low | Sama-sama gray area, proaktif engage pemerintah |
| Fraud (fake orders, dll) | Medium | Medium | Device fingerprint, behavior analysis, manual review |
| Data breach | Critical | Low | Encryption, access control, audit log, pen-test |
| Driver churn | High | Medium | Komunitas kuat, financial tools, referral rewards |
| Customer churn | High | Medium | Harga murah, driver favorit, loyalty program |

---

## 14. Glossary

| Term | Definition |
|------|-----------|
| **Ojol** | Ojek Online — ride-hailing motor |
| **GMV** | Gross Merchandise Value — total nilai order |
| **DAU/MAU** | Daily/Monthly Active Users |
| **NPS** | Net Promoter Score — customer satisfaction metric |
| **RTO/RPO** | Recovery Time/Point Objective — disaster recovery targets |
| **GeoJSON** | Format untuk data geografis (polygon zona) |
| **Multi-homing** | Driver aktif di beberapa platform sekaligus |
| **Surge pricing** | Harga naik saat demand tinggi (KopDar TIDAK pakai ini) |
| **T+1** | Settlement keesokan hari setelah transaksi |

---

*Document ini akan di-update seiring perkembangan produk. Versi berikutnya akan mencakup detailed wireframes, API specification, dan test plan.*

---

**Author:** KopDar Product Team
**Last Updated:** 15 Juli 2026
**Status:** Draft v1.0
