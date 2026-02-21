#!/usr/bin/env python3
"""Compare two benchmark result sets and print a regression/improvement table."""

import json
import sys
from pathlib import Path

RESULTS_DIR = Path(__file__).parent / "results"


def load(path: Path) -> dict:
    with open(path) as f:
        return json.load(f)


def extract_warm_median(result: dict, metric: str = "t2_roundtrip") -> float:
    warm = result.get("warm", {})
    if isinstance(warm, dict):
        if metric in warm:
            return warm[metric].get("median", 0)
        return warm.get("median", 0)
    return 0


def fmt_delta(before: float, after: float) -> str:
    if before == 0:
        return "N/A"
    delta = after - before
    pct = delta / before * 100
    arrow = "▲" if delta > 0 else "▼"
    return f"{arrow}{abs(pct):.1f}% ({delta:+.1f}ms)"


def compare(before_path: Path, after_path: Path):
    before = load(before_path)
    after = load(after_path)

    b_layer = before["meta"]["layer"]
    a_layer = after["meta"]["layer"]
    if b_layer != a_layer:
        print(f"Warning: comparing different layers ({b_layer} vs {a_layer})")

    b_results = {r["fixture"]: r for r in before["results"]}
    a_results = {r["fixture"]: r for r in after["results"]}

    all_fixtures = sorted(set(b_results) | set(a_results))

    print(f"\nLayer: {b_layer}")
    print(f"Before: {before_path.name}  ({before['meta']['timestamp'][:10]})")
    print(f"After:  {after_path.name}  ({after['meta']['timestamp'][:10]})")
    print()
    print(f"  {'Fixture':<24} {'Before p50':>10} {'After p50':>10} {'Delta':>20} {'Status':>8}")
    print("  " + "─" * 76)

    regressions = 0
    improvements = 0

    for fixture in all_fixtures:
        if fixture not in b_results or fixture not in a_results:
            print(f"  {fixture:<24} {'(missing)':>10}")
            continue

        b_val = extract_warm_median(b_results[fixture])
        a_val = extract_warm_median(a_results[fixture])

        delta_str = fmt_delta(b_val, a_val)
        pct = (a_val - b_val) / b_val * 100 if b_val else 0

        if pct > 5:
            status = "❌ REGR"
            regressions += 1
        elif pct < -5:
            status = "✅ IMPR"
            improvements += 1
        else:
            status = "  SAME"

        print(f"  {fixture:<24} {b_val:>9.1f}ms {a_val:>9.1f}ms {delta_str:>20} {status:>8}")

    print()
    print(f"  Regressions: {regressions}  Improvements: {improvements}")


def main():
    args = sys.argv[1:]

    if len(args) == 2:
        before_path = Path(args[0])
        after_path = Path(args[1])
    elif len(args) == 0:
        jsons = sorted(RESULTS_DIR.glob("js-bench-*.json"), key=lambda p: p.stat().st_mtime)
        jsons = [p for p in jsons if "latest" not in p.name]
        if len(jsons) < 2:
            print("Need at least 2 result files to compare.")
            print(f"Usage: {sys.argv[0]} <before.json> <after.json>")
            sys.exit(1)
        before_path, after_path = jsons[-2], jsons[-1]
        print(f"Auto-selected: comparing last two results")
    else:
        print(f"Usage: {sys.argv[0]} [<before.json> <after.json>]")
        sys.exit(1)

    compare(before_path, after_path)


if __name__ == "__main__":
    main()
