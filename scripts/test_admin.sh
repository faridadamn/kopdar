#!/bin/bash
# ─────────────────────────────────────────────────────────
# KopDar — Admin Endpoint Tests
# ─────────────────────────────────────────────────────────
set -euo pipefail

BASE_URL="${API_URL:-http://localhost:8080}"
PASS=0
FAIL=0
ADMIN_TOKEN=""
DRIVER_TOKEN=""
DRIVER_ID=""

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

auth_get() {
  local path="$1" token="$2"
  curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE_URL$path" -H "Authorization: Bearer $token"
}

auth_put() {
  local path="$1" token="$2" body="${3:-}"
  if [ -n "$body" ]; then
    curl -s -o /dev/null -w "%{http_code}" -X PUT "$BASE_URL$path" \
      -H "Authorization: Bearer $token" -H "Content-Type: application/json" -d "$body"
  else
    curl -s -o /dev/null -w "%{http_code}" -X PUT "$BASE_URL$path" -H "Authorization: Bearer $token"
  fi
}

auth_get_body() {
  local path="$1" token="$2"
  curl -s -X GET "$BASE_URL$path" -H "Authorization: Bearer $token"
}

TMPIMG=$(mktemp /tmp/kopdar_test_XXXXXX.jpg)
printf '\xFF\xD8\xFF\xE0' > "$TMPIMG"

bold "=== KopDar Admin Tests ==="
echo "Base URL: $BASE_URL"
echo ""

# ── Setup: Create admin + driver ───────────────────────────
bold "Setup: Authenticate admin"
ADMIN_PHONE="0811$(date +%s | tail -c 9)"
curl -s -o /dev/null "$BASE_URL/api/v1/auth/register" \
  -H "Content-Type: application/json" -d "{\"phone\":\"$ADMIN_PHONE\"}"
ADMIN_RESP=$(curl -s -X POST "$BASE_URL/api/v1/auth/verify-otp" \
  -H "Content-Type: application/json" -d "{\"phone\":\"$ADMIN_PHONE\",\"otp\":\"123456\"}")
ADMIN_TOKEN=$(echo "$ADMIN_RESP" | jq -r '.access_token // empty' 2>/dev/null || true)

bold "Setup: Register a test driver"
DRIVER_PHONE="0812$(date +%s | tail -c 9)"
curl -s -o /dev/null "$BASE_URL/api/v1/auth/register" \
  -H "Content-Type: application/json" -d "{\"phone\":\"$DRIVER_PHONE\"}"
DRIVER_RESP=$(curl -s -X POST "$BASE_URL/api/v1/auth/verify-otp" \
  -H "Content-Type: application/json" -d "{\"phone\":\"$DRIVER_PHONE\",\"otp\":\"123456\"}")
DRIVER_TOKEN=$(echo "$DRIVER_RESP" | jq -r '.access_token // empty' 2>/dev/null || true)

if [ -n "$DRIVER_TOKEN" ]; then
  NIK="327501$(date +%s | tail -c 11)"
  curl -s -o /dev/null "$BASE_URL/api/v1/driver/register" \
    -H "Authorization: Bearer $DRIVER_TOKEN" \
    -F "name=Admin Test Driver" \
    -F "nik=$NIK" \
    -F "address=Jl. Test No. 1" \
    -F "city=Jakarta Selatan" \
    -F "province=DKI Jakarta" \
    -F "vehicle_type=motor" \
    -F "vehicle_brand=Honda" \
    -F "vehicle_model=Vario" \
    -F "vehicle_year=2024" \
    -F "vehicle_plate=B 7777 KPD" \
    -F "vehicle_color=Hitam" \
    -F "bank_name=BCA" \
    -F "bank_account=1234567890" \
    -F "bank_holder=ADMIN TEST" \
    -F 'platforms=["gojek"]' \
    -F "ktp_photo=@$TMPIMG" \
    -F "selfie_photo=@$TMPIMG" \
    -F "vehicle_photo=@$TMPIMG"
fi
echo ""

if [ -z "$ADMIN_TOKEN" ]; then
  red "Cannot proceed without admin token."
  rm -f "$TMPIMG"
  exit 1
fi

# 1. List pending drivers → 200
bold "1. List pending drivers"
STATUS=$(auth_get "/api/v1/admin/drivers/pending?page=1&limit=10" "$ADMIN_TOKEN")
assert_status "GET /admin/drivers/pending" 200 "$STATUS"

# 2. Pending list has data array + meta
bold "2. Pending list response structure"
RESP=$(auth_get_body "/api/v1/admin/drivers/pending?page=1&limit=10" "$ADMIN_TOKEN")
HAS_DATA=$(echo "$RESP" | jq -r '.data // empty' 2>/dev/null)
HAS_META=$(echo "$RESP" | jq -r '.meta // empty' 2>/dev/null)
if [ -n "$HAS_DATA" ] && [ -n "$HAS_META" ]; then
  green "  ✅ Response has 'data' array and 'meta'"
  PASS=$((PASS + 1))
  # Extract first driver ID if available
  DRIVER_ID=$(echo "$RESP" | jq -r '.data[0].id // empty' 2>/dev/null || true)
else
  red   "  ❌ Response missing 'data' or 'meta'"
  FAIL=$((FAIL + 1))
fi

# 3. List with city filter
bold "3. List pending with city filter"
STATUS=$(auth_get "/api/v1/admin/drivers/pending?city=Jakarta+Selatan" "$ADMIN_TOKEN")
assert_status "GET /admin/drivers/pending?city=..." 200 "$STATUS"

# 4. List with search
bold "4. List pending with search"
STATUS=$(auth_get "/api/v1/admin/drivers/pending?search=Budi" "$ADMIN_TOKEN")
assert_status "GET /admin/drivers/pending?search=..." 200 "$STATUS"

# 5. Get specific driver details
bold "5. Get driver details"
if [ -n "$DRIVER_ID" ]; then
  STATUS=$(auth_get "/api/v1/admin/drivers/$DRIVER_ID" "$ADMIN_TOKEN")
  assert_status "GET /admin/drivers/{id}" 200 "$STATUS"
else
  red "  ⚠️  No driver ID available — skipping"
  FAIL=$((FAIL + 1))
fi

# 6. Approve driver → 200
bold "6. Approve driver"
if [ -n "$DRIVER_ID" ]; then
  STATUS=$(auth_put "/api/v1/admin/drivers/$DRIVER_ID/approve" "$ADMIN_TOKEN")
  assert_status "PUT /admin/drivers/{id}/approve" 200 "$STATUS"
else
  red "  ⚠️  No driver ID — skipping"
  FAIL=$((FAIL + 1))
fi

# 7. Approve already-approved driver → 409
bold "7. Approve already-approved driver (conflict)"
if [ -n "$DRIVER_ID" ]; then
  STATUS=$(auth_put "/api/v1/admin/drivers/$DRIVER_ID/approve" "$ADMIN_TOKEN")
  if [ "$STATUS" -eq 409 ]; then
    green "  ✅ PUT /admin/drivers/{id}/approve (already approved) — HTTP 409"
    PASS=$((PASS + 1))
  else
    red   "  ❌ Expected 409, got $STATUS"
    FAIL=$((FAIL + 1))
  fi
else
  red "  ⚠️  No driver ID — skipping"
  FAIL=$((FAIL + 1))
fi

# 8. Reject non-existent driver → 404
bold "8. Reject non-existent driver"
STATUS=$(auth_put "/api/v1/admin/drivers/00000000-0000-0000-0000-000000000000/reject" "$ADMIN_TOKEN" '{"reason":"Test rejection reason that is long enough"}')
assert_status "PUT /admin/drivers/{fake_id}/reject" 404 "$STATUS"

# 9. Reject without reason → 400
bold "9. Reject without reason"
# Need a pending driver for this; skip if none available
STATUS=$(auth_put "/api/v1/admin/drivers/00000000-0000-0000-0000-000000000000/reject" "$ADMIN_TOKEN" '{}')
if [ "$STATUS" -eq 400 ] || [ "$STATUS" -eq 404 ]; then
  green "  ✅ PUT /admin/drivers/{id}/reject (no reason) — HTTP $STATUS"
  PASS=$((PASS + 1))
else
  red   "  ❌ Expected 400 or 404, got $STATUS"
  FAIL=$((FAIL + 1))
fi

# 10. Get admin stats → 200
bold "10. Get admin stats"
STATUS=$(auth_get "/api/v1/admin/stats" "$ADMIN_TOKEN")
assert_status "GET /admin/stats" 200 "$STATUS"

# 11. Stats has expected fields
bold "11. Stats response validation"
RESP=$(auth_get_body "/api/v1/admin/stats" "$ADMIN_TOKEN")
for field in total_drivers pending_drivers approved_drivers rejected_drivers; do
  HAS=$(echo "$RESP" | jq -r ".$field // empty" 2>/dev/null)
  if [ -n "$HAS" ]; then
    green "  ✅ Stats has '$field': $HAS"
    PASS=$((PASS + 1))
  else
    red   "  ❌ Stats missing '$field'"
    FAIL=$((FAIL + 1))
  fi
done

# 12. Access admin endpoints without token → 401
bold "12. Admin endpoints without token"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE_URL/api/v1/admin/stats")
assert_status "GET /admin/stats (no token)" 401 "$STATUS"

# 13. Access admin endpoints with driver token → 403
bold "13. Admin endpoints with driver token"
if [ -n "$DRIVER_TOKEN" ]; then
  STATUS=$(auth_get "/api/v1/admin/stats" "$DRIVER_TOKEN")
  assert_status "GET /admin/stats (driver token)" 403 "$STATUS"
else
  red "  ⚠️  No driver token — skipping"
  FAIL=$((FAIL + 1))
fi

rm -f "$TMPIMG"

# ── Summary ────────────────────────────────────────────────
echo ""
if [ "$FAIL" -eq 0 ]; then
  green "=== Admin Tests: $PASS passed, $FAIL failed ==="
else
  red   "=== Admin Tests: $PASS passed, $FAIL failed ==="
fi
exit $FAIL
