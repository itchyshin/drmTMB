# After Task: Gaussian ordinary SD parity

## 1. Goal

Add current same-data evidence for the existing ordinary Gaussian mean random-intercept SD route in native TMB and Julia.

## 2. Implemented

Added an independent seeded Gaussian fixture and an R bridge test. It checks signed SD-coefficient recovery, coefficient and log-likelihood agreement, group-SD predictions, and reordered-row predictions. Hash-bound receipts link the native and Julia candidate rows. No model source was changed because both fitting routes already existed.

## 3a. Decisions and Rejected Alternatives

Kept this slice to the Gaussian q1 ordinary mean intercept. The paired Julia candidate already has ordinary Gaussian intercept and slope LSS fitters, so the missing work was same-data bridge evidence. Assumption: matching `sigma ~ 1` formulas make the two likelihoods comparable for this fixture; a general Gaussian comparison still needs other endpoints, slopes, and covariance structures.

## 4. Files Touched

- `tests/testthat/test-julia-gaussian-sd-parity.R`
- `docs/dev-log/general-sd-regression/evidence/gaussian-ordinary-sd-parity-20261024-v1/`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`
- `docs/dev-log/general-sd-regression/inventory.md`
- `.unlazy/general-sd-regression/GATES.md`
- `docs/dev-log/check-log.d/2026-10-24-gaussian-ordinary-sd-parity.md`
- `docs/dev-log/after-task/2026-10-24-gaussian-ordinary-sd-parity.md`
- `LOOP/lanes/general-sd-regression/checkpoint.md`

## 5. Checks Run

- `DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia" DRM_JL_JULIA_HOME="/Users/z3437171/.juliaup/bin" OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "julia-gaussian-sd-parity")'`: 14 passed, 0 failed, 0 warnings, 0 skipped; one live Julia bridge fit; 32.1 seconds.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: PASS; 43 hash-verified receipt records, 34 candidate rows linked, and 19,084 unlinked.
- `gh issue list --search 'Gaussian random effect SD Julia parity' --limit 10`: no matching Gaussian parity issue found.
- `CODEX_ACTION=codex bash ~/shinichi-brain/tools/lane_preflight.sh "$PWD" --file tests/testthat/test-julia-gaussian-sd-parity.R`: identified a genuinely new test path. The adapter-map and checkpoint preflights found no missing-path work in other refs.

## 6. Tests of the Tests

The fixture uses independently generated group effects with known log-SD coefficients. Assertions require recovery direction and point tolerance in both engines, same-data likelihood and coefficient agreement, and consistency between fitted group SDs and reordered-row predictions. The route also shares the Julia Gaussian LSS fitter covered by existing ML/REML oracle and constant-SD equivalence tests.

## 7a. Issue Ledger

No issue was opened or changed. The issue search found no direct Gaussian SD parity issue.

## 8. Consistency Audit

Updated the Gaussian rows in the family inventory, the exact-key evidence overlay, generated reconciliation summary, G3 evidence notes, and the current recovery checkpoint. The new receipts retain the dirty worktree source heads and bind the test hash. This is one ordinary q1 intercept cell; no Gaussian slope or structured row was promoted. The documentation sweep ran `rg -n -i 'gaussian.*(sd|random.effect|parity)|julia.*gaussian|gaussian.*julia' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd vignettes/julia-engine.Rmd`; the wider statements still describe candidate status and open slope/structured coverage, so no public support claim needed changing.

## 9. What Did Not Go Smoothly

The full lane census takes longer than the file-specific result. The required-path checks identified the new test and confirmed no missing work for the adapter map and checkpoint; unrelated active lanes were left untouched.

## 10. Known Residuals

The test covers one complete-data ordinary Gaussian mean intercept with a constant formula `sigma ~ 1`. Gaussian slope parity, structured providers, correlated blocks, broader prediction/simulation/refit semantics, calibrated uncertainty, and programme-wide parity remain open. No programme gate closes.

## 11. Team Learning

When a family already has direct-SD fitters in both engines, a same-data fixture can reveal a valuable parity gap without changing likelihood code. D-93 remains relevant to uncertainty claims. The repository route lookup returned no LOAD-FIRST manifest; Golden Set checks were not in scope.

## 12. Cross-Product Coverage

Covers: native TMB and paired Julia candidate fits for one ordinary Gaussian q1 mean random intercept, including recovery, same-data coefficient and likelihood agreement, fitted group SDs, and reordered-row prediction.

Does NOT cover: Gaussian independent-slope parity, phylogenetic/animal/relatedness/spatial effects, correlated blocks, other distributional endpoints, broad stored-object/refit workflows, interval calibration, or programme-wide parity.
