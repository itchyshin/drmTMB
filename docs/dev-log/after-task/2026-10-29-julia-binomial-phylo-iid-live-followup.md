# After Task: Live Julia Binomial Phylogenetic plus IID Bridge Follow-up

## 1. Goal

Run the existing mixed phylogenetic plus IID Binomial SD bridge test with the Julia worktree configured, since the earlier receipt only recorded its pure R checks.

## 2. Implemented

The live test passed for probit and cloglog. It exercises the existing R bridge, native TMB and Julia fits, target labels, group-SD predictions, likelihood comparison, and Julia marginal simulation. No model or test source changed in this follow-up.

## 3a. Decisions and Rejected Alternatives

The evidence remains `focused_test`. The fixture checks that both fitted SD slopes are positive and within a broad engine-difference bound, but it does not require their estimates to be close to the generating values. I did not relabel this as recovery evidence.

## 4. Files Touched

- `docs/dev-log/general-sd-regression/evidence/julia-binomial-phylo-iid-live-rerun-20261029/`: source hashes, console log, and live-run receipt.
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv`: two additional unreviewed, exact-row focused-test records.
- `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`: regenerated evidence-only summary.
- This report.

The existing implementation and test remain in the candidate worktree. Source HEADs: drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1`; DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`.

## 5. Checks Run

- `PATH="/Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin:$PATH" JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 NOT_CRAN=true DRMTMB_JULIA_TESTS=true DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia" Rscript -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-julia-binomial-phylo-iid-sd-bridge.R", reporter = "summary")'`: passed with one live JuliaCall test for probit and cloglog.
- The passing console log, source manifest, and receipt are stored under `docs/dev-log/general-sd-regression/evidence/julia-binomial-phylo-iid-live-rerun-20261029/`.
- `python3 tools/general-sd-regression/reconcile_evidence.py`: passed with 20,350 candidate rows and 232 evidence records. The two additional records point to rows already linked; no row status changed.
- `gh issue list --state open --search 'Binomial phylo IID SD' --limit 10`: no matching issue.

## 6. Tests of the Tests

The synthetic fixture creates outcomes from known positive SD slopes on separate IID and phylogenetic intercepts. The test also exercises negative admission cases for missing or mismatched SD targets and a random-slope formula. The test's positive-direction assertions justify only a focused test grade, not close recovery.

## 7a. Issue Ledger

No matching open issue was found, so no issue was changed.

## 8. Consistency Audit

The live run confirms the exact route recorded by the existing after-task note. The test and receipt limit the claim to one phylogenetic intercept plus one IID intercept for two links on the current candidates. No public capability table or support claim changed. The earlier report's skipped-live result remains an accurate record of that earlier run; this report adds a later live result.

## 9. What Did Not Go Smoothly

The earlier run had no `DRM_JL_PATH`, so it skipped the live part. Supplying the paired worktree path enabled the bridge test without changing the code.

## 10. Known Residuals

This does not cover logit for this provider pair, animal or other structured providers, random slopes, other response families, coverage calibration, interval validity, or broad Julia parity. The support status remains unchanged.

The after-task structural checker found 13 acceptance ledgers that are not runnable because Node or `gate-check` is unavailable. Their state remains UNKNOWN, not satisfied.

## 11. Team Learning

When an earlier report records a live test as skipped, rerun that same test with the paired worktree explicitly configured before treating it as an implementation gap.

## 12. Cross-Product Coverage

**Covers:** the R-to-Julia bridge and native TMB comparator for one Binomial phylogenetic-intercept plus IID-intercept route, under probit and cloglog; fitting, SD coefficient labels and predictions, likelihood comparison, and Julia marginal simulation. **Does NOT cover:** logit for this provider pair, other providers or response families, random slopes, save/reload, profile or bootstrap workflows, full suites, broad engine parity, or uncertainty coverage.

Memory receipt: I used the general-SD memory entry to preserve the candidate-only and non-coverage boundaries. `route.py` returned no LOAD-FIRST manifest and `graft` is unavailable in this shell. Golden Set: not run; this provider-input rerun is outside the registered repeated-mistake classes.

## Writing Assessment

**Style:** 2/10, medium confidence; the report is short and names the tested route and limits. **Genre and coverage:** after-task report, whole draft reviewed. **Evidence and repair:** “positive-direction assertions justify only a focused test grade” states the evidence boundary; no change needed. **Gates:** science = pass for the test's stated scope; facts = pass against the saved console log and source manifest; references = not applicable because the report has no external citations. **Provenance:** self-review, draft version 1, 2026-10-29; the earlier mixed-route report was already seen.
