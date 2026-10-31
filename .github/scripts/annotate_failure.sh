#!/usr/bin/env bash
# Run a command; if it fails, surface the relevant part of its output as
# GitHub annotations (readable from the API even when raw logs are not).
set -o pipefail
log=$(mktemp)
"$@" 2>&1 | tee "$log"
status=${PIPESTATUS[0]}
if [ "$status" -ne 0 ]; then
  # JET prints its reports after a "JET found" line; put them first
  grep -A120 "JET found" "$log" | head -c 12000 > "$log.sel" || true
  grep -n -E -A12 "Test Failed|Error During Test|ERROR:|LoadError|MethodError|UndefVarError|Unsatisfiable|error:|Error:" "$log" \
    | head -c 22000 >> "$log.sel" || true
  [ -s "$log.sel" ] || tail -c 20000 "$log" > "$log.sel"
  split -b 3500 "$log.sel" "$log.part."
  n=0
  for f in "$log.part."*; do
    n=$((n+1)); [ $n -gt 10 ] && break
    msg=$(sed -e 's/%/%25/g' "$f" | sed -e ':a;N;$!ba;s/\r//g;s/\n/%0A/g')
    echo "::error title=failure part $n::$msg"
  done
fi
exit $status
