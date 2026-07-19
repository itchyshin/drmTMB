# Arc 4c Fir library-path repair

## 1. Goal

Repair the fail-closed worker setup exposed by the first approved Arc 4c smoke
array, without patching the verified Fir clone or widening the statistical
campaign.

## 2. Implemented

All three Arc 4c Slurm workers now export the fresh campaign `R_LIBS` and
`DRMTMB_RLIB` before validating the preflight receipt. A static regression test
enforces this setup order.

## 3a. Decisions and Rejected Alternatives

The repair uses a new branch and PR from `origin/main`. Directly patching the
verified Fir clone was rejected because it would break source authentication.
Treating the 12 failures as model-smoke failures was rejected because no fit was
attempted.

## 4. Files Touched

- `tools/slurm/arc4c-mu-slope-coverage.sbatch`
- `tools/slurm/arc4c-mu-slope-coverage-smoke.sbatch`
- `tools/slurm/arc4c-mu-slope-coverage-aggregate.sbatch`
- `tests/testthat/test-arc4c-drac-dispatch.R`
- `docs/dev-log/check-log.md`
- this report

## 5. Checks Run

All three shell workers pass `bash -n`. The focused dispatch test passes 159/159
expectations. A test-of-test replay applies the new ordering predicate to the
merged PR-A scripts and the repaired scripts: all three old scripts fail it and
all three new scripts pass it.

## 6. Tests of the Tests

The regression assertion does not merely search for an `R_LIBS` export. It
requires an export before `PREFLIGHT_DIR`, which precedes receipt validation.
This distinguishes the repaired scripts from the merged PR-A versions, where
the only regular-worker export came after validation.

## 7a. Issue Ledger

No GitHub issue was opened or changed. This is a narrow repair to the Arc 4c
campaign infrastructure introduced in PR #797 and will be linked through its
repair PR.

## 8. Consistency Audit

The repair covers the smoke, full-fit, and aggregate workers, each of which runs
an R/TMB environment check. Thread pins,
account, QOS assumptions, manifests, checksums, atomic copy-back, and statistical
rules are unchanged. No symbolic equation, R syntax, example, vignette, design
document, generated pkgdown page, roadmap item, NEWS item, or known limitation
describes this internal environment setup, so none requires synchronization.

## 9. What Did Not Go Smoothly

Fir preflight job `49624077` passed, but smoke array `49625624` failed 12/12
before fitting because `TMB` was invisible to `Rscript` during receipt
validation. The preflight path masked the defect by exporting the library inside
its compile function.

## 10. Known Residuals

The repair must merge before compute resumes from a fresh clone at the new merge
SHA. Preflight and all 12 N=1 smoke cells must then be rerun. The failed attempts
are infrastructure evidence only; they cannot select families or contribute to
coverage. No N=1200 certification array has been submitted.

## 11. Team Learning

Static worker tests must check setup order when later commands depend on exported
state. Testing only for the presence of an environment variable is insufficient.

## 12. Cross-Product Coverage

This repair is internal to drmTMB's Fir campaign workers. It changes neither the
drmTMB public interface nor any Julia twin, gllvmTMB, CRAN, or pkgdown surface.
It covers the Arc 4c smoke, full-fit, and aggregate workers; it does NOT cover
other campaigns, estimator behavior, model families, ledger claims, or downstream
package providers.
