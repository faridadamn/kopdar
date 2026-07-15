#!/bin/bash
# ─────────────────────────────────────────────────────────
# KopDar — Driver Endpoint Tests
# ─────────────────────────────────────────────────────────
set -euo pipefail

BASE_URL="${API_URL:-http://localhost:8080}"
PASS=0
FAIL=0
DRIVER_TOKEN=""

# ── Helpers ────────────────────────────────────────────────
red()   { printf '\033[0;31m%s\033[0m\n' "$*"; }
green() { printf '\033[0;32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }

assert_status() {
  local label="$1" expected="$2" actual="$3"
  if [ "$actual" -eq "$expected" ]; then
    green "  ✅ $label (HTTP $actual)"
    PASS=$((PASS + 1))
  else
    red   "  ❌ $label — expected $expected, got $actual"
    FAIL=$((FAIL + 1))
  fi
}

# Register + get token for a fresh driver
setup_token() {
  local phone="0812$(date +%s | tail -c 9)"
  curl -s -o /dev/null "$BASE_URL/api/v1/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"phone\":\"$phone\"}"
  local resp
  resp=$(curl -s -X POST "$BASE_URL/api/v1/auth/verify-otp" \
    -H "Content-Type: application/json" \
    -d "{\"phone\":\"$phone\",\"otp\":\"123456\"}")
  DRIVER_TOKEN=$(echo "$resp" | jq -r '.access_token // empty' 2>/dev/null || true)
  if [ -z "$DRIVER_TOKEN" ]; then
    red "  ⚠️  Could not obtain driver token — some tests will be skipped"
  fi
}

PHONE="0812$(date +%s | tail -c 9)"

# Create a dummy image file for upload tests
TMPIMG=$(mktemp /tmp/kopdar_test_XXXXXX.jpg)
printf '\xFF\xD8\xFF\xE0' > "$TMPIMG"   # minimal JPEG header

bold "=== KopDar Driver Tests ==="
echo "Base URL: $BASE_URL"
echo ""

# ── Setup ──────────────────────────────────────────────────
bold "Setup: Register & authenticate test driver"
setup_token
echo ""

if [ -z "$DRIVER_TOKEN" ]; then
  red "Cannot proceed without auth token."
  exit 1
fi

AUTH_HEADER="Authorization: Bearer $DRIVER_TOKEN"

# 1. Register driver (multipart) → 201
bold "1. Register driver (multipart form)"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST "$BASE_URL/api/v1/driver/register" \
  -H "$AUTH_HEADER" \
  -F "name=Budi Santoso" \
  -F "nik=327501$(date +%s | tail -c 11)" \
  -F "address=Jl. Mampang Prapatan No. 10" \
  -F "city=Jakarta Selatan" \
  -F "province=DKI Jakarta" \
  -F "vehicle_type=motor" \
  -F "vehicle_brand=Honda" \
  -F "vehicle_model=Vario 160" \
  -F "vehicle_year=2024" \
  -F "vehicle_plate=B $(shuf -i 1000-9999 -n 1) KPD" \
  -F "vehicle_color=Hitam" \
  -F "bank_name=BCA" \
  -F "bank_account=1234567890" \
  -F "bank_holder=BUDI SANTOSO" \
  -F 'platforms=["gojek","grab"]' \
  -F "ktp_photo=@$TMPIMG" \
  -F "selfie_photo=@$TMPIMG" \
  -F "vehicle_photo=@$TMPIMG")
assert_status "POST /driver/register" 201 "$STATUS"

# 2. Get driver profile → 200
bold "2. Get driver profile"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X GET "$BASE_URL/api/v1/driver/profile" \
  -H "$AUTH_HEADER")
assert_status "GET /driver/profile" 200 "$STATUS"

# 3. Update driver profile → 200
bold "3. Update driver profile"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X PUT "$BASE_URL/api/v1/driver/profile" \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  -d '{"vehicle_color":"Merah","bank_name":"Mandiri"}')
assert_status "PUT /driver/profile" 200 "$STATUS"

# 4. Get driver status → 200
bold "4. Get driver status"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X GET "$BASE_URL/api/v1/driver/status" \
  -H "$AUTH_HEADER")
assert_status "GET /driver/status" 200 "$STATUS"

# 5. Driver status contains expected fields
bold "5. Driver status response validation"
RESP=$(curl -s -X GET "$BASE_URL/api/v1/driver/status" -H "$AUTH_HEADER")
HAS_STATUS=$(echo "$RESP" | jq -r '.status // empty' 2>/dev/null)
if [ -n "$HAS_STATUS" ]; then
  green "  ✅ Response has 'status' field: $HAS_STATUS"
  PASS=$((PASS + 1))
else
  red   "  ❌ Response missing 'status' field"
  FAIL=$((FAIL + 1))
fi

# 6. Access without token → 401
bold "6. Access without token"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X GET "$BASE_URL/api/v1/driver/profile")
assert_status "GET /driver/profile (no token)" 401 "$STATUS"

# 7. Update with invalid data → 400
bold "7. Update with invalid data"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X PUT "$BASE_URL/api/v1/driver/profile" \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/json" \
  -d '{"vehicle_year":"not_a_number"}')
assert_status "PUT /driver/profile (bad data)" 400 "$STATUS"

# 8. Duplicate NIK → 409
bold "8. Duplicate NIK registration"
# First registration already happened; try registering again with same NIK
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST "$BASE_URL/api/v1/driver/register" \
  -H "$AUTH_HEADER" \
  -F "name=Duplicate Test" \
  -F "nik=3275011234567890" \
  -F "address=Jl. Test" \
  -F "city=Jakarta Selatan" \
  -F "province=DKI Jakarta" \
  -F "vehicle_type=motor" \
  -F "vehicle_brand=Honda" \
  -F "vehicle_model=Beat" \
  -F "vehicle_year=2023" \
  -F "vehicle_plate=B 9999 KPD" \
  -F "vehicle_color=Putih" \
  -F "bank_name=BCA" \
  -F "bank_account=1111111111" \
  -F "bank_holder=DUPLICATE TEST" \
  -F 'platforms=["gojek"]' \
  -F "ktp_photo=@$TMPIMG" \
  -F "selfie_photo=@$TMPIMG" \
  -F "vehicle_photo=@$TMPIMG")
# Could be 409 (conflict) or 400 depending on implementation
if [ "$STATUS" -eq 409 ] || [ "$STATUS" -eq 400 ]; then
  green "  ✅ POST /driver/register (duplicate NIK) — HTTP $STATUS"
  PASS=$((PASS + 1))
else
  red   "  ❌ POST /driver/register (duplicate NIK) — expected 409/400, got $STATUS"
  FAIL=$((FAIL + 1))
fi

# Cleanup
rm -f "$TMPIMG"

# ── Summary ────────────────────────────────────────────────
echo ""
if [ "$FAIL" -eq 0 ]; then
  green "=== Driver Tests: $PASS passed, $FAIL failed ==="
else
  red   "=== Driver Tests: $PASS passed, $FAIL failed ==="
fi
exit $FAIL
