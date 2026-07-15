#!/bin/bash
# ─────────────────────────────────────────────────────────
# KopDar — Auth Endpoint Tests
# ─────────────────────────────────────────────────────────
set -euo pipefail

BASE_URL="${API_URL:-http://localhost:8080}"
PASS=0
FAIL=0
DRIVER_TOKEN=""
REFRESH_TOKEN=""

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

post_json() {
  local path="$1" body="$2"
  curl -s -o /dev/null -w "%{http_code}" \
    -X POST "$BASE_URL$path" \
    -H "Content-Type: application/json" \
    -d "$body"
}

post_json_body() {
  local path="$1" body="$2"
  curl -s -X POST "$BASE_URL$path" \
    -H "Content-Type: application/json" \
    -d "$body"
}

auth_get() {
  local path="$1" token="$2"
  curl -s -o /dev/null -w "%{http_code}" \
    -X GET "$BASE_URL$path" \
    -H "Authorization: Bearer $token"
}

auth_delete() {
  local path="$1" token="$2"
  curl -s -o /dev/null -w "%{http_code}" \
    -X DELETE "$BASE_URL$path" \
    -H "Authorization: Bearer $token"
}

PHONE="0812$(date +%s | tail -c 9)"

# ── Tests ──────────────────────────────────────────────────
bold "=== KopDar Auth Tests ==="
echo "Base URL: $BASE_URL"
echo "Test phone: $PHONE"
echo ""

# 1. Register phone → 200
bold "1. Register phone"
STATUS=$(post_json "/api/v1/auth/register" "{\"phone\":\"$PHONE\"}")
assert_status "POST /auth/register" 200 "$STATUS"

# 2. Verify OTP → 200, get tokens
bold "2. Verify OTP"
RESPONSE=$(post_json_body "/api/v1/auth/verify-otp" "{\"phone\":\"$PHONE\",\"otp\":\"123456\"}")
STATUS=$(echo "$RESPONSE" | jq -r '.error // empty' > /dev/null 2>&1 && echo "401" || echo "200")
# Try to extract tokens
DRIVER_TOKEN=$(echo "$RESPONSE" | jq -r '.access_token // empty' 2>/dev/null || true)
REFRESH_TOKEN=$(echo "$RESPONSE" | jq -r '.refresh_token // empty' 2>/dev/null || true)
# Get actual HTTP status
STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST "$BASE_URL/api/v1/auth/verify-otp" \
  -H "Content-Type: application/json" \
  -d "{\"phone\":\"$PHONE\",\"otp\":\"123456\"}")
assert_status "POST /auth/verify-otp" 200 "$STATUS"

# 3. Login → 200
bold "3. Login"
STATUS=$(post_json "/api/v1/auth/login" "{\"phone\":\"$PHONE\",\"otp\":\"123456\"}")
assert_status "POST /auth/login" 200 "$STATUS"

# 4. Access protected route with valid token → 200
bold "4. Access protected route (valid token)"
if [ -n "$DRIVER_TOKEN" ]; then
  STATUS=$(auth_get "/api/v1/driver/status" "$DRIVER_TOKEN")
  assert_status "GET /driver/status (with token)" 200 "$STATUS"
else
  red "  ⚠️  Skipped — no token from step 2"
  FAIL=$((FAIL + 1))
fi

# 5. Refresh token → 200
bold "5. Refresh token"
if [ -n "$REFRESH_TOKEN" ]; then
  STATUS=$(post_json "/api/v1/auth/refresh" "{\"refresh_token\":\"$REFRESH_TOKEN\"}")
  assert_status "POST /auth/refresh" 200 "$STATUS"
else
  red "  ⚠️  Skipped — no refresh token from step 2"
  FAIL=$((FAIL + 1))
fi

# 6. Invalid phone → 400
bold "6. Invalid phone format"
STATUS=$(post_json "/api/v1/auth/register" "{\"phone\":\"123\"}")
assert_status "POST /auth/register (invalid phone)" 400 "$STATUS"

# 7. Wrong OTP → 401
bold "7. Wrong OTP"
STATUS=$(post_json "/api/v1/auth/verify-otp" "{\"phone\":\"$PHONE\",\"otp\":\"000000\"}")
assert_status "POST /auth/verify-otp (wrong OTP)" 401 "$STATUS"

# 8. Expired/invalid token → 401
bold "8. Invalid token"
STATUS=$(auth_get "/api/v1/driver/profile" "invalid.token.here")
assert_status "GET /driver/profile (bad token)" 401 "$STATUS"

# 9. Logout → 200
bold "9. Logout"
if [ -n "$DRIVER_TOKEN" ]; then
  STATUS=$(auth_delete "/api/v1/auth/logout" "$DRIVER_TOKEN")
  assert_status "DELETE /auth/logout" 200 "$STATUS"
else
  red "  ⚠️  Skipped — no token"
  FAIL=$((FAIL + 1))
fi

# 10. Access after logout → 401
bold "10. Access after logout"
if [ -n "$DRIVER_TOKEN" ]; then
  STATUS=$(auth_get "/api/v1/driver/status" "$DRIVER_TOKEN")
  assert_status "GET /driver/status (after logout)" 401 "$STATUS"
else
  red "  ⚠️  Skipped — no token"
  FAIL=$((FAIL + 1))
fi

# ── Summary ────────────────────────────────────────────────
echo ""
if [ "$FAIL" -eq 0 ]; then
  green "=== Auth Tests: $PASS passed, $FAIL failed ==="
else
  red   "=== Auth Tests: $PASS passed, $FAIL failed ==="
fi
exit $FAIL
