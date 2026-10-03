#!/usr/bin/env bash
# Pull live BFF JSON for Play screenshots (flutter test blocks HttpClient).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="${YAKITLA_API_BASE:-http://localhost:3000}"
BASE="${BASE%/}"
OUT="$ROOT/tool/fixtures"
mkdir -p "$OUT"
CITY_ID="${YAKITLA_CITY_ID:-34}"
DISTRICT_ID="${YAKITLA_DISTRICT_ID:-436}"

curl -fsS -m 90 "$BASE/api/v1/fuel/cities" -o "$OUT/cities.json"
curl -fsS -m 90 "$BASE/api/v1/fuel/districts?cityId=$CITY_ID" -o "$OUT/districts.json"
curl -fsS -m 90 "$BASE/api/v1/fuel/stations?cityId=$CITY_ID&districtId=$DISTRICT_ID" \
  -o "$OUT/stations.json"

python3 - <<PY
import json
from pathlib import Path
out = Path("$OUT")
stations = json.loads((out / "stations.json").read_text())
n = len(stations.get("items") or [])
if n == 0:
    raise SystemExit("No stations in fixture — warm cache / pick another district")
print(f"fixture ok: {n} stations → {out}")
PY
