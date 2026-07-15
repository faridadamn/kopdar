#!/bin/bash
# ─────────────────────────────────────────────────────────
# KopDar — Run All Tests
# ─────────────────────────────────────────────────────────
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
API_URL="${API_URL:-http://localhost:8080}"
TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_SUITES=0
FAILED_SUITES=0

export API_URL

red()   { printf '\033[0;31m%s\033[0m\n' "$*"; }
green() { printf '\033[0;32m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
blue()  { printf '\033[0;34m%s\033[0m\n' "$*"; }

echo ""
bold "╔══════════════════════════════════════════════════════╗"
bold "║           KopDar API — Test Runner                  ║"
bold "╚══════════════════════════════════════════════════════╝"
echo ""
blue "API URL: $API_URL"
echo ""

run_suite() {
  local name="$1" script="$2"
  TOTAL_SUITES=$((TOTAL_SUITES + 1))
  bold "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  bold "  Running: $name"
  bold "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  local output exit_code=0
  output=$(bash "$script" 2>&1) || exit_code=$?

  echo "$output"

  # Extract pass/fail counts from the summary line
  local pass fail
  pass=$(echo "$output" | grep -oP '\d+ passed' | grep -oP '\d+' | tail -1 || echo "0")
  fail=$(echo "$output" | grep -oP '\d+ failed' | grep -oP '\d+' | tail -1 || echo "0")

  TOTAL_PASS=$((TOTAL_PASS + pass))
  TOTAL_FAIL=$((TOTAL_FAIL + fail))

  if [ "$exit_code" -ne 0 ]; then
    FAILED_SUITES=$((FAILED_SUITES + 1))
  fi
  echo ""
}

# ── Pre-flight check ───────────────────────────────────────
bold "Pre-flight: Checking API availability..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL/api/v1/health" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
  green "✅ API is reachable (HTTP $HTTP_CODE)"
else
  red "❌ API not reachable at $API_URL (HTTP $HTTP_CODE)"
  red "   Start the backend first: cd kopdar/backend && go run ./cmd/api"
  exit 1
fi
echo ""

# ── Run suites ─────────────────────────────────────────────
run_suite "Auth Tests"   "$SCRIPT_DIR/test_auth.sh"
run_suite "Driver Tests" "$SCRIPT_DIR/test_driver.sh"
run_suite "Admin Tests"  "$SCRIPT_DIR/test_admin.sh"

# ── Grand summary ──────────────────────────────────────────
bold "╔══════════════════════════════════════════════════════╗"
bold "║                  TEST SUMMARY                       ║"
bold "╠══════════════════════════════════════════════════════╣"
printf "║  Suites run:    %-5s                                ║\n" "$TOTAL_SUITES"
printf "║  Suites failed: %-5s                                ║\n" "$FAILED_SUITES"
printf "║  Total passed:  %-5s                                ║\n" "$TOTAL_PASS"
printf "║  Total failed:  %-5s                                ║\n" "$TOTAL_FAIL"
bold "╚══════════════════════════════════════════════════════╝"

if [ "$TOTAL_FAIL" -eq 0 ] && [ "$FAILED_SUITES" -eq 0 ]; then
  green ""
  green "🎉 All tests passed!"
  exit 0
else
  red ""
  red "💥 $TOTAL_FAIL test(s) failed across $FAILED_SUITES suite(s)."
  exit 1
fi
