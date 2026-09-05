#!/bin/sh
# RED CONTROLS for parity leaf A5: plant one defect per negative gate, show the
# gate oracle FAILS, restore the file byte-identically (diff -q must be empty).
# Usage: sh red_controls.sh [dir]   -- output is the record; see red-controls.log
set -u
D="${1:-$(cd "$(dirname "$0")" && pwd)}"
S="$(mktemp -d)"
rc=0
run_control() { # $1 gate, $2 file, $3 description, $4 planting command (sed program)
  gate="$1"; file="$2"; desc="$3"; plant="$4"
  cp "$D/$file" "$S/$file.bak"
  echo "== RED CONTROL $gate: $desc"
  echo "   plant: sed -i '' -e \"$plant\" $file"
  sed -i '' -e "$plant" "$D/$file"
  if cmp -s "$D/$file" "$S/$file.bak"; then echo "   PLANT FAILED: file unchanged"; rc=1; fi
  out=$(Rscript "$D/check_gates.R" "$gate" "$D" 2>&1); st=$?
  echo "   oracle exit=$st: $out"
  if [ "$st" -eq 0 ]; then echo "   RED CONTROL BROKEN: oracle passed with the defect planted"; rc=1; fi
  cp "$S/$file.bak" "$D/$file"
  if diff -q "$D/$file" "$S/$file.bak" >/dev/null; then echo "   restored byte-identically (diff -q empty)"; else echo "   RESTORE FAILED"; rc=1; fi
  out=$(Rscript "$D/check_gates.R" "$gate" "$D" 2>&1); st=$?
  echo "   oracle after restore exit=$st: $out"
  [ "$st" -eq 0 ] || rc=1
}
# G1: delete the shipped random-slope REML row (a cell silently missing from the census)
run_control G1 census.tsv "delete the shipped/gaussian_random_slope/REML census row" '/^430ef64ccca5642c5abebd72194e00895314dfc2\tshipped\tgaussian_random_slope\t[^\t]*\tREML\t/d'
# G2: delete the SE row of a verified cell (a verified cell with no SE receipt)
run_control G2 parity-se-ordinary-re.tsv "delete the SE row for ordre_gaussian_random_slope_ml" '/\tordre_gaussian_random_slope_ml\t/d'
# G3: strip the engine's own refusal phrase from the random-slope ledger row (a boundary that no longer cites the engine)
run_control G3 ledger.tsv "remove the engine phrase from gaussian_random_slope_mu's claim_boundary" '/^gaussian_random_slope_mu\t/s/method = :REML is not implemented for this model on the generic univariate Gaussian route/REML refused/'
# G4: record the engine-refused random-slope REML cell as SUPPORTED (a downgrade/refusal promoted)
run_control G4 census.tsv "flip shipped/gaussian_random_slope/REML from UNSUPPORTED to SUPPORTED" '/^430ef64ccca5642c5abebd72194e00895314dfc2\tshipped\tgaussian_random_slope\t[^\t]*\tREML\t/s/\tREFUSED\tUNSUPPORTED\t/\tREFUSED\tSUPPORTED\t/'
# G4b: the gate's literal wording -- a requested-REML cell whose engine report says ML, recorded SUPPORTED
run_control G4 census.tsv "rewrite shipped/gaussian_random_slope/REML as DOWNGRADED with estim_method=ML and ledger SUPPORTED" '/^430ef64ccca5642c5abebd72194e00895314dfc2\tshipped\tgaussian_random_slope\t[^\t]*\tREML\t/s/\tREFUSED\tUNSUPPORTED\tNA\t/\tDOWNGRADED\tSUPPORTED\tML\t/'
rm -rf "$S"
echo "== ALL RED CONTROLS $( [ $rc -eq 0 ] && echo OK || echo FAILED )"
exit $rc
