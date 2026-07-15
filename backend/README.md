# KopDar Backend

Backend API for KopDar — a digital cooperative platform for Indonesian gig workers.

## Quick Start

```bash
cp .env.example .env
# Edit .env with your database credentials

make migrate
make run
```

## API Endpoints

### Auth
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/register` | Send OTP to phone |
| POST | `/api/v1/auth/verify-otp` | Verify OTP, get tokens |
| POST | `/api/v1/auth/login` | Login (register+verify) |
| POST | `/api/v1/auth/refresh` | Refresh access token |
| DELETE | `/api/v1/auth/logout` | Invalidate refresh token |

### Driver
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/driver/register` | Register as driver (multipart) |
| GET | `/api/v1/driver/profile` | Get profile |
| PUT | `/api/v1/driver/profile` | Update profile |
| GET | `/api/v1/driver/status` | Verification status |

### Admin
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/admin/drivers/pending` | List pending drivers |
| GET | `/api/v1/admin/drivers/:id` | Driver detail |
| PUT | `/api/v1/admin/drivers/:id/approve` | Approve driver |
| PUT | `/api/v1/admin/drivers/:id/reject` | Reject driver |
| GET | `/api/v1/admin/stats` | Dashboard stats |

### System
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/health` | Health check |

## Build

```bash
make build    # Build binary
make test     # Run tests
make clean    # Clean artifacts
```

## Docker

```bash
docker build -t kopdar-backend .
docker run -p 8080:8080 --env-file .env kopdar-backend
```
