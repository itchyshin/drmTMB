# Dinnage audit — waves 1 and 2 on claude/audit-dinnage-wave1-20260913

Merged tree (wave 1 plus the wave-2a and wave-2b branches).  Per-file results
under `pkgload::load_all()`, reporter `check`:

| File | Result |
|---|---|
| `test-dinnage-audit-wave1.R` | `[ FAIL 0 \| WARN 0 \| SKIP 0 \| PASS 10 ]` |
| `test-dinnage-audit-wave2a.R` (`NOT_CRAN=true`; its blocks are `skip_on_cran()`) | `[ FAIL 0 \| WARN 0 \| SKIP 0 \| PASS 34 ]` |
| `test-dinnage-audit-wave2b.R` | `[ FAIL 0 \| WARN 1 \| SKIP 0 \| PASS 23 ]` |
| `test-clamp-active-guard.R` | `[ FAIL 0 \| WARN 1 \| SKIP 0 \| PASS 26 ]` |
| `test-clamp-extension.R` | `[ FAIL 0 \| WARN 0 \| SKIP 0 \| PASS 16 ]` |
| `test-missing-response-count-mixtures.R` | `[ FAIL 0 \| WARN 0 \| SKIP 0 \| PASS 174 ]` |
| `test-missing-response-truncated-nbinom2.R` | `[ FAIL 0 \| WARN 0 \| SKIP 0 \| PASS 49 ]` |
| `test-check-drm.R` | `[ FAIL 0 \| WARN 4 \| SKIP 1 \| PASS 263 ]` |

The warnings are the pre-existing `allow_nonconvergence()` pathological-fit
noise those files already carried.

Local `R CMD check --no-manual --as-cran` on a `git archive` export of the
merged HEAD (so the untracked `.unlazy/` ledgers are absent):

Export of `743024b8b` (after the three regression repairs), `rcmdcheck --no-manual
--as-cran`, `NOT_CRAN=true`: **0 errors, 1 warning, 2 notes**; `Running
'testthat.R' [22m/24m]` with no test failure; vignettes rebuilt OK.  The
warning is environmental and pre-existing: the local machine lacks
`checkbashisms`, and the top-level `tools-scratch` and hidden `.scratch`
directories are tracked on `origin/main` and not in `.Rbuildignore` (noted as
a follow-up outside this arc).  The two notes are "new submission" and the
same hidden directory.  A first check on the pre-repair export (`be8475095`)
had surfaced the eight failing files recorded in the after-task report; all
eight passed on a clean export of `origin/main`, which is how they were
classified as regressions before being fixed.

Ledgers re-verified by `gate-check.mjs --reverify` rather than read:
leaf-A3 (wave 1), leaf-A4a (wave 2a: 2 met, 1 abandoned for M3 with the
#1130 citation), leaf-A4b (wave 2b: 4 met after the M4 follow-up).  No
campaign, no remote compute, no evidence bytes on the 071 lane.
