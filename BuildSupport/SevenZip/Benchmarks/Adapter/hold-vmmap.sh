#!/bin/bash
# Usage: hold-vmmap.sh <bridge-binary> <Large256-dataset> <new-work-dir> <output-prefix> [cycles]
# Runs the OR-11 pipeline, holds the process and captures vmmap/footprint/heap.
set -euo pipefail
binary="$1"; dataset="$2"; work="$3"; prefix="$4"; cycles="${5:-1}"
rm -rf "$work"; mkdir -p "$work"
ZF_BENCH_HOLD_SECONDS=60 "$binary" memory "$dataset" "$work" "$cycles" 0 > "$prefix.jsonl" &
child=$!
until grep -q '"hold"' "$prefix.jsonl" 2>/dev/null; do sleep 0.5; done
pid=$(python3 -I -c "import json,sys;print([json.loads(l) for l in open(sys.argv[1])][-1]['pid'])" "$prefix.jsonl")
vmmap -summary "$pid" > "$prefix.vmmap.txt" 2>&1 || true
vmmap "$pid" > "$prefix.vmmap-full.txt" 2>&1 || true
footprint "$pid" > "$prefix.footprint.txt" 2>&1 || true
heap "$pid" > "$prefix.heap.txt" 2>&1 || true
kill "$child" || true
wait "$child" 2>/dev/null || true
echo "captured $pid"
