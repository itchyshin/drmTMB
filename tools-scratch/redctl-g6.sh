#!/bin/bash
# G6 RED CONTROL. Plant a defect that makes the consumer LIE about which
# producer made the gradient -- report DRM.jl's :forward (an AD gradient)
# where the bridge actually handed over the fit's own stored callback -- and
# show the suite catches it. Then restore byte-identically (sha256) and show
# the suite passes again.
set -u
cd "$(dirname "$0")/.."
F=R/julia-diagnostics.R
OUT=tools-scratch/redctl-g6.txt
: > "$OUT"
BEFORE_SHA=$(shasum -a 256 "$F" | awk '{print $1}')
echo "BASELINE sha256=$BEFORE_SHA" >> "$OUT"

echo "=== BASELINE SUITE ===" >> "$OUT"
NOT_CRAN=true Rscript -e 'suppressMessages(devtools::load_all(".", quiet=TRUE)); r <- as.data.frame(testthat::test_file("tests/testthat/test-julia-diagnostics.R", reporter="silent")); cat(sprintf("passed=%d failed=%d error=%d skipped=%d\n", sum(r$passed), sum(r$failed), sum(r$error), sum(r$skipped)))' 2>&1 | tail -1 >> "$OUT"

# Plant: a gradient that crossed the bridge is DRM.jl's :stored and nothing
# else (src/bridge.jl:1497 has exactly one producer). Claim :forward instead.
perl -0pi -e 's/  if \(has_gradient\) "stored" else "unknown"/  if (has_gradient) "forward" else "unknown"/' "$F"
if ! grep -q 'if (has_gradient) "forward"' "$F"; then echo "PLANT_FAILED_TO_APPLY" >> "$OUT"; exit 1; fi
echo "=== PLANTED (stored -> forward) ===" >> "$OUT"
grep -n 'if (has_gradient)' "$F" >> "$OUT"

NOT_CRAN=true Rscript -e 'suppressMessages(devtools::load_all(".", quiet=TRUE)); r <- as.data.frame(testthat::test_file("tests/testthat/test-julia-diagnostics.R", reporter="silent")); cat(sprintf("passed=%d failed=%d error=%d skipped=%d\n", sum(r$passed), sum(r$failed), sum(r$error), sum(r$skipped)))' > tools-scratch/g6-planted.txt 2>&1
tail -1 tools-scratch/g6-planted.txt >> "$OUT"
NFAIL=$(grep -o 'failed=[0-9]*' tools-scratch/g6-planted.txt | tail -1 | cut -d= -f2)
NOT_CRAN=true Rscript -e 'suppressMessages(devtools::load_all(".", quiet=TRUE)); testthat::test_file("tests/testthat/test-julia-diagnostics.R", reporter="summary")' 2>&1 | sed -n '/Failed /,/DONE /p' | head -20 >> "$OUT"
NOT_CRAN=true Rscript tools-scratch/vocab-check.R > tools-scratch/g6-vocab.txt 2>&1
echo "vocab-check.R under the plant: exit=$?" >> "$OUT"
tail -3 tools-scratch/g6-vocab.txt >> "$OUT"

if [ "${NFAIL:-0}" -gt 0 ]; then echo "PLANTED_FAILED failures=$NFAIL" >> "$OUT"; else echo "PLANT_NOT_CAUGHT" >> "$OUT"; fi

# Restore byte-identically from the committed blob, not from an edit.
git show HEAD:$F > "$F"
AFTER_SHA=$(shasum -a 256 "$F" | awk '{print $1}')
echo "RESTORED sha256=$AFTER_SHA" >> "$OUT"
if [ "$BEFORE_SHA" = "$AFTER_SHA" ]; then echo "RESTORED_IDENTICAL" >> "$OUT"; else echo "RESTORE_MISMATCH" >> "$OUT"; fi
echo "=== SUITE AFTER RESTORE ===" >> "$OUT"
NOT_CRAN=true Rscript -e 'suppressMessages(devtools::load_all(".", quiet=TRUE)); r <- as.data.frame(testthat::test_file("tests/testthat/test-julia-diagnostics.R", reporter="silent")); cat(sprintf("passed=%d failed=%d error=%d skipped=%d\n", sum(r$passed), sum(r$failed), sum(r$error), sum(r$skipped)))' 2>&1 | tail -1 >> "$OUT"
echo "=== git status (expect only the intended paths) ===" >> "$OUT"
git status --porcelain >> "$OUT"
rm -f tools-scratch/g6-planted.txt tools-scratch/g6-vocab.txt
cat "$OUT"
