# KopDar — Koperasi Digital untuk Gig Worker Indonesia

> **"Menjadi sistem operasi hidup bagi gig worker Indonesia — yang bekerja untuk pekerja, bukan untuk platform."**

KopDar (Koperasi Digital) is a two-sided platform serving Indonesian gig workers (primarily ride-hailing drivers) and customers who need transportation, food delivery, and package shipping services.

**Key Differentiators:**
- **5-8% commission** (vs Gojek/Grab 20%+)
- Driver-owned data, not platform-owned
- Collective financial tools (savings, micro-insurance)
- Data-driven advocacy & bargaining power
- No surge pricing — ever

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                              │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐ │
│  │  Driver App   │  │ Customer App │  │   Admin Dashboard     │ │
│  │  (Flutter)    │  │  (Flutter)   │  │   (React)             │ │
│  │  Android/iOS  │  │  Android/iOS │  │   Web                 │ │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬────────────┘ │
└─────────┼──────────────────┼──────────────────────┼──────────────┘
          │                  │                      │
          ▼                  ▼                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Backend API (Go)                             │
│              Gin/Fiber · JWT Auth · WebSocket                    │
└────────────────────────────┬────────────────────────────────────┘
                             │
          ┌──────────────────┼──────────────────┐
          ▼                  ▼                  ▼
┌─────────────┐  ┌──────────────┐  ┌───────────────────┐
│ PostgreSQL  │  │    Redis     │  │  External APIs     │
│ + PostGIS   │  │ Cache/Queue  │  │  (Maps, Payment,   │
│             │  │  Pub/Sub     │  │   SMS, Storage)    │
└─────────────┘  └──────────────┘  └───────────────────┘
```

---

## Quick Start

### Prerequisites

- Docker & Docker Compose v2
- Go 1.22+ (for local development)
- Node.js 20+ (for local development)
- Flutter SDK (for mobile development)

### 1. Clone & Configure

```bash
git clone https://github.com/kopdar/kopdar.git
cd kopdar
cp .env.example .env
# Edit .env with your values
```

### 2. Start Everything

```bash
make dev
```

This starts:
| Service | URL |
|---------|-----|
| Backend API | http://localhost:8080 |
| Admin Dashboard | http://localhost:3000 |
| PostgreSQL | localhost:5432 |
| Redis | localhost:6379 |

### 3. Verify

```bash
# Check all services are healthy
make dev-ps

# Check backend health
curl http://localhost:8080/health
```

---

## Project Structure

```
kopdar/
├── .github/
│   └── workflows/
│       └── ci.yml              # CI/CD pipeline
├── admin/                      # React admin dashboard
│   ├── Dockerfile
│   ├── nginx.conf
│   └── ...
├── backend/                    # Go API server
│   ├── Dockerfile
│   ├── cmd/
│   │   └── server/             # Main entrypoint
│   ├── internal/               # Business logic
│   │   ├── handler/            # HTTP handlers
│   │   ├── model/              # Data models
│   │   ├── repository/         # Database layer
│   │   ├── service/            # Business services
│   │   └── middleware/         # Auth, logging, etc.
│   ├── migrations/             # SQL migrations
│   ├── go.mod
│   └── go.sum
├── mobile/                     # Flutter apps (driver + customer)
│   ├── lib/
│   └── ...
├── scripts/
│   └── init-db.sh              # Database initialization
├── docker-compose.yml
├── Makefile
├── .env.example
├── .env.development
├── .env.production
├── .gitignore
└── README.md
```

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Mobile Apps | Flutter (Android/iOS) |
| Backend API | Go (Gin/Fiber) |
| Database | PostgreSQL 16 + PostGIS |
| Cache/Queue | Redis 7 |
| Admin Dashboard | React + Nginx |
| Auth | Firebase Auth + JWT |
| Payment | Midtrans + Xendit |
| Maps | Google Maps Platform |
| CI/CD | GitHub Actions |
| Containerization | Docker + Docker Compose |

---

## Development Commands

```bash
make help              # Show all commands

# Development
make dev               # Start all services
make dev-down          # Stop all services
make dev-logs          # Follow logs

# Build
make build             # Build all images
make build-backend     # Build backend only
make build-admin       # Build admin only

# Test
make test              # Run all tests
make test-backend      # Go tests
make test-admin        # React tests

# Database
make db-migrate        # Run migrations
make db-seed           # Seed sample data
make db-reset          # Drop + recreate (⚠️ destructive)
make db-shell          # Open psql shell

# Lint
make lint              # Lint all code
```

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Standards

- **Go:** Follow [Effective Go](https://go.dev/doc/effective_go), run `golangci-lint`
- **React:** ESLint + Prettier, run `npm run lint`
- **Flutter:** `flutter analyze`, follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- **Commits:** Use [Conventional Commits](https://www.conventionalcommits.org/)

---

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.

---

**KopDar** — Koperasi Digital untuk Gig Worker Indonesia 🇮🇩
