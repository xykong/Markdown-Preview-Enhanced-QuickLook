#!/usr/bin/env bash
# Layer 3: QuickLook System-Level Benchmark
#
# Measures end-to-end QuickLook thumbnail generation time using qlmanage.
# This captures the full native stack: process spawn, extension load, WKWebView
# init, rendering, and thumbnail output — all in one wall-clock measurement.
#
# Higher variance than JS/Swift layers due to system scheduling; run on idle machine.
#
# Usage:
#   ./ql-bench.sh [--iterations N] [--warmup N] [--fixture PATTERN]
#   ./ql-bench.sh --iterations 10 --warmup 3
#   ./ql-bench.sh --fixture 03-medium-code

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURES_DIR="$(dirname "$SCRIPT_DIR")/fixtures"
RESULTS_DIR="$(dirname "$SCRIPT_DIR")/results"
TEMP_DIR="/tmp/ql-bench-$$"
THUMBNAIL_SIZE=800

WARMUP_RUNS=3
BENCH_RUNS=10
FIXTURE_FILTER=""

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --iterations) BENCH_RUNS="$2"; shift 2 ;;
            --warmup)     WARMUP_RUNS="$2"; shift 2 ;;
            --fixture)    FIXTURE_FILTER="$2"; shift 2 ;;
            *) echo "Unknown arg: $1"; exit 1 ;;
        esac
    done
}

parse_args "$@"

# ─── Dependencies ─────────────────────────────────────────────────────────────
command -v qlmanage &>/dev/null || { echo "ERROR: qlmanage not found"; exit 1; }
command -v python3  &>/dev/null || { echo "ERROR: python3 not found"; exit 1; }
command -v bc       &>/dev/null || { echo "ERROR: bc not found"; exit 1; }

mkdir -p "$TEMP_DIR" "$RESULTS_DIR"
trap 'rm -rf "$TEMP_DIR"' EXIT

# ─── Reset QuickLook cache ─────────────────────────────────────────────────────
reset_ql_cache() {
    qlmanage -r &>/dev/null || true
    qlmanage -r cache &>/dev/null || true
    sleep 0.5
}

# ─── Measure qlmanage -t for one file, return ms ──────────────────────────────
measure_one() {
    local filepath="$1"
    local out_dir="$2"
    
    local start_ns end_ns

    if command -v gdate &>/dev/null; then
        start_ns=$(gdate +%s%N)
    else
        start_ns=$(($(date +%s) * 1000000000))
    fi

    qlmanage -t -s "$THUMBNAIL_SIZE" -o "$out_dir" "$filepath" &>/dev/null

    if command -v gdate &>/dev/null; then
        end_ns=$(gdate +%s%N)
    else
        end_ns=$(($(date +%s) * 1000000000))
    fi

    local elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))
    echo "$elapsed_ms"
}

# ─── Python stats (portable, no jq needed) ────────────────────────────────────
compute_stats_json() {
    local samples_csv="$1"
    python3 - "$samples_csv" <<'PYEOF'
import sys, json, math

csv = sys.argv[1]
samples = [float(x) for x in csv.split(',') if x.strip()]
if not samples:
    print('{}')
    sys.exit(0)

samples_sorted = sorted(samples)
n = len(samples_sorted)
mean = sum(samples_sorted) / n
variance = sum((x - mean) ** 2 for x in samples_sorted) / max(n - 1, 1)
stddev = math.sqrt(variance)

def pct(p):
    idx = max(0, min(int(math.ceil(p / 100 * n)) - 1, n - 1))
    return samples_sorted[idx]

result = {
    'n': n,
    'mean': round(mean, 3),
    'median': round(pct(50), 3),
    'p95': round(pct(95), 3),
    'p99': round(pct(99), 3),
    'min': round(samples_sorted[0], 3),
    'max': round(samples_sorted[-1], 3),
    'stddev': round(stddev, 3),
    'cv': round(stddev / mean, 4) if mean > 0 else 0,
}
print(json.dumps(result))
PYEOF
}

# ─── Benchmark one fixture ─────────────────────────────────────────────────────
log() { echo "$*" >&2; }

benchmark_fixture() {
    local filepath="$1"
    local fixture_name
    fixture_name=$(basename "$filepath")
    local size_kb
    size_kb=$(( $(wc -c < "$filepath") / 1024 ))

    log ""
    log "  📄 $fixture_name (${size_kb}KB)"

    local cold_samples=()
    local warm_samples=()

    local cold_out="$TEMP_DIR/cold"
    mkdir -p "$cold_out"

    local cold_warmup=3
    log "     Cold runs ($cold_warmup warmup + $BENCH_RUNS measured)..."
    for ((i=0; i < cold_warmup + BENCH_RUNS; i++)); do
        reset_ql_cache
        local ms
        ms=$(measure_one "$filepath" "$cold_out")
        rm -f "$cold_out"/*.png 2>/dev/null || true

        if ((i < cold_warmup)); then
            log "     [warmup-${i}] ${ms}ms"
        else
            idx=$((i - cold_warmup))
            log "     [cold-${idx}] ${ms}ms"
            cold_samples+=("$ms")
            if ((idx + 1 >= BENCH_RUNS)); then break; fi
        fi
    done

    log "     Warm runs ($WARMUP_RUNS warmup + $BENCH_RUNS measured)..."
    local warm_out="$TEMP_DIR/warm"
    mkdir -p "$warm_out"

    for ((i=0; i < WARMUP_RUNS; i++)); do
        local ms
        ms=$(measure_one "$filepath" "$warm_out")
        rm -f "$warm_out"/*.png 2>/dev/null || true
        log "     [warmup-${i}] ${ms}ms"
    done

    for ((i=0; i < BENCH_RUNS; i++)); do
        local ms
        ms=$(measure_one "$filepath" "$warm_out")
        rm -f "$warm_out"/*.png 2>/dev/null || true
        log "     [warm-${i}] ${ms}ms"
        warm_samples+=("$ms")
    done

    local cold_csv
    cold_csv=$(IFS=','; echo "${cold_samples[*]}")
    local warm_csv
    warm_csv=$(IFS=','; echo "${warm_samples[*]}")

    local cold_stats warm_stats
    cold_stats=$(compute_stats_json "$cold_csv")
    warm_stats=$(compute_stats_json "$warm_csv")

    echo "$fixture_name|$size_kb|$cold_stats|$warm_stats"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════════"
echo "  FluxMarkdown QuickLook System Benchmark (Layer 3)"
echo "═══════════════════════════════════════════════════════════"
echo "  Fixtures:   $FIXTURES_DIR"
echo "  Warmup:     $WARMUP_RUNS runs"
echo "  Bench runs: $BENCH_RUNS runs"
echo "  QL reset:   qlmanage -r (before each cold run)"
echo ""

if [[ -z "${FIXTURE_FILTER}" ]]; then
    mapfile -t FIXTURE_FILES < <(find "$FIXTURES_DIR" -name "*.md" | sort)
else
    mapfile -t FIXTURE_FILES < <(find "$FIXTURES_DIR" -name "*${FIXTURE_FILTER}*" | sort)
fi

if [[ ${#FIXTURE_FILES[@]} -eq 0 ]]; then
    echo "ERROR: No fixture files found in $FIXTURES_DIR"
    exit 1
fi

echo "  Fixtures: $(basename -a "${FIXTURE_FILES[@]}" | tr '\n' ' ')"
echo ""

declare -a fixture_results=()

for filepath in "${FIXTURE_FILES[@]}"; do
    row=$(benchmark_fixture "$filepath")
    fixture_results+=("$row")
done

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Results Summary (qlmanage wall-clock ms)"
echo "═══════════════════════════════════════════════════════════"
printf "  %-24s %6s %10s %10s %10s %10s\n" "Fixture" "Size" "Cold p50" "Cold p95" "Warm p50" "Warm p95"
echo "  $(printf '─%.0s' {1..76})"

for row in "${fixture_results[@]}"; do
    IFS='|' read -r fname size_kb cold_stats warm_stats <<< "$row"
    cold_p50=$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(d.get('median',0))" "$cold_stats")
    cold_p95=$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(d.get('p95',0))" "$cold_stats")
    warm_p50=$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(d.get('median',0))" "$warm_stats")
    warm_p95=$(python3 -c "import json,sys; d=json.loads(sys.argv[1]); print(d.get('p95',0))" "$warm_stats")
    printf "  %-24s %5sKB %9sms %9sms %9sms %9sms\n" \
        "$fname" "$size_kb" "$cold_p50" "$cold_p95" "$warm_p50" "$warm_p95"
done

# ─── Save JSON results ─────────────────────────────────────────────────────────
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
OUT_FILE="$RESULTS_DIR/ql-bench-${TIMESTAMP}.json"
LATEST_FILE="$RESULTS_DIR/ql-bench-latest.json"

python3 - "${fixture_results[@]}" > "$OUT_FILE" <<'PYEOF'
import sys, json, datetime

rows = sys.argv[1:]
results = []
for row in rows:
    parts = row.split('|', 3)
    if len(parts) != 4:
        continue
    fname, size_kb, cold_json, warm_json = parts
    try:
        cold = json.loads(cold_json)
        warm = json.loads(warm_json)
    except Exception:
        continue
    results.append({
        'fixture': fname,
        'size_kb': int(size_kb),
        'cold': cold,
        'warm': warm,
    })

report = {
    'meta': {
        'layer': 'quicklook',
        'timestamp': datetime.datetime.utcnow().isoformat() + 'Z',
        'tool': 'qlmanage -t',
        'thumbnail_size': 800,
    },
    'results': results,
}
print(json.dumps(report, indent=2))
PYEOF

cp "$OUT_FILE" "$LATEST_FILE"

echo ""
echo "  ✅ Results saved to:"
echo "     $OUT_FILE"
echo "     $LATEST_FILE (latest)"
