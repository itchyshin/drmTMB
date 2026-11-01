#!/bin/bash
# usage: run_one.sh <stem> <evdir-name>
set -u
W="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression"
cd "$W" || exit 99
STEM="$1"; EV="docs/dev-log/general-sd-regression/evidence/$2"
mkdir -p "$EV"
TEST="tests/testthat/test-$STEM.R"
echo "TEST_SHA256_BEFORE $(shasum -a 256 "$TEST")" > "$EV/test-console.log"
echo "START $(date -u +%FT%TZ)" >> "$EV/test-console.log"
NOT_CRAN=true OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
 Rscript -e "res <- devtools::test(filter = '^${STEM}\$', reporter = 'summary', stop_on_failure = FALSE); df <- as.data.frame(res); cat(sprintf('\nCOUNTS expectations=%d failed=%d skipped=%d errors=%d warnings=%d tests=%d\n', sum(df\$nb), sum(df\$failed), sum(df\$skipped), sum(df\$error), sum(df\$warning), nrow(df))); print(df[, c('test','nb','failed','skipped','error','warning')]); if (sum(df\$failed) > 0 || any(df\$error) || any(df\$skipped)) quit(status = 1)" \
 >> "$EV/test-console.log" 2>&1
RC=$?
echo "EXIT_STATUS $RC" >> "$EV/test-console.log"
echo "END $(date -u +%FT%TZ)" >> "$EV/test-console.log"
echo "TEST_SHA256_AFTER $(shasum -a 256 "$TEST")" >> "$EV/test-console.log"
exit $RC
