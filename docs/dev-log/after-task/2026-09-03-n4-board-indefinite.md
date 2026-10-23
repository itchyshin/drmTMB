## 1. Goal

Arc N4 of the overnight true-parity lane: two small, unrelated deliverables in
`docs/design/capability-status.md` (the R-side half of the R<->Julia
mission-control board) and `tests/testthat/test-check-conditioning.R` (a
platform-independent deterministic test for `check_drm()`'s
`hessian_conditioning` warning path).

## 2. (a) Board row

`DRM.jl`'s `docs/design/capability-status.md` (pinned clone,
`scratchpad/drmjl-objat`) lists a row this file did not have:
`Non-Gaussian phylogenetic location-scale (μ + log σ)`, `implemented`. This
file's own "Row-name match against DRM.jl" section already flagged the
asymmetry without asserting a status, deferring the question to
`cells.tsv`.

Re-derived from `docs/dev-log/dashboard/capability-ledger/cells.tsv`
(`dpar = sigma`, `structure_provider = phylo`, excluding `gaussian`, whose
family-scoped structured-effect row already exists separately):

- `implemented`: `nbinom2` (`evidence_tier = interval_feasible`, mc-0421),
  `zero_one_beta` (`evidence_tier = point_fit_recovery`, mc-0593).
- `rejected_by_design`: `beta`, `beta_binomial` (x2), `gamma`,
  `hurdle_nbinom2` (x2), `lognormal`, `skew_normal`, `student`,
  `truncated_nbinom2`, `tweedie`, `zi_nbinom2` (x2) -- 10 distinct families.
- Also present but not counted in either bucket: `nbinom2` has a second,
  `rejected_by_design` cell (mc-0420, a different route/axis variant) and a
  third `not_implemented` cell (mc-0426); `zero_one_beta` has two further
  `rejected_by_design` cells (mc-0598, mc-0700). The family lists above are
  the *union of distinct status values per family*, matching the brief's
  prescribed list exactly.

Added to the "Random-effect structure" table (the natural home, next to the
existing `Non-Gaussian phylogenetic random intercept (mean)` row) at
`scope-limited`, with a sentence under the table citing the two implemented
cells and the ten rejected families. Row name copied byte-for-byte from the
pinned clone (confirmed via `python3 -c "..."` reading both files as UTF-8
and comparing `repr()` of the matching lines).

Updated the counts that referenced "42 rows" in two places: the "Snapshot"
bullet (42 -> 43 capabilities) and the "Row-name match against DRM.jl"
table (`rows in this file` 42->43, `matched exactly` 42->43, `present only
in DRM.jl's file` 4->3). The DRM.jl-only bullet list dropped this row (now
matched) and the "fourth is different in kind" paragraph was replaced with a
short note that the row is now added and resolved from the ledger. Verified
the new row count (43) by a small awk pass over the four capability tables
(`Response families`, `Random-effect structure`, `Estimation and inference`,
`Bivariate structure and missing data`), excluding header/separator rows.

**Lane check:** the pre-edit hook flagged two other branches
(`claude/night-n2-accessors`, `claude/capability-surface-aghq-parity`) with
pending commits touching this same file. `night-n2-accessors`'s diff is in
the "Estimation and inference" section (a different row,
`Heritability/repeatability/ICC accessors`), non-overlapping with this edit.
`capability-surface-aghq-parity` is a stale/pre-restructure branch (its diff
against current `HEAD` touches hundreds of unrelated files across the repo,
including deleting this entire section) and is not comparable without its
own rebase; not merged with here.

## 3. (b) Deterministic indefinite-Hessian test

The two existing "indefinite"/"near-singular" tests in
`test-check-conditioning.R` carry premise guards (`skip_if`/`skip_if_not`)
because a 1e-7-collinear design lands on either side of the PD boundary
depending on the platform's LAPACK. Read `R/check.R`'s
`check_hessian_conditioning()` / `hessian_conditioning_cov_row()`: for a
non-MSPL fit it reads only `object$sdr$cov.fixed` (never `object$sdr$pdHess`,
never `obj$he()`), decomposes it with `eigen()`, and reports `"warning"`
whenever the covariance's smallest eigenvalue is negative beyond a
`sqrt(.Machine$double.eps)`-scaled floor.

Tried construction (1) first: a rank-deficient design (`x2 = 2 * x1`) fit
with `bf(y ~ x1 + x2, sigma ~ 1)`. Not pursued to completion because
construction (2) is strictly more direct for this code path (it reads
`sdr$cov.fixed` only, so injecting the covariance directly is the more
faithful test of the actual branch, and avoids depending on whether
`drmTMB()` drops/keeps an aliased column before calling TMB, which was not
otherwise established in this timebox).

**Construction (2) worked**: fit an ordinary well-conditioned Gaussian model,
copy the fit object (`fit2 <- fit`), and inject
`diag(c(-1, rep(1, p - 1)))` (one robustly negative eigenvalue, `p =
nrow(fit2$sdr$cov.fixed)`) into `fit2$sdr$cov.fixed`, plus
`fit2$sdr$pdHess <- FALSE` for realism (unused by the function under test).
New test: `"check_drm() reports hessian_conditioning as a warning for a
deterministic injected-indefinite covariance"` (name contains
"deterministic"). Asserts `row$status == "warning"`,
`expect_match(row$value, "min_eig=-")`, `attr(chk, "ok")` is `FALSE`. The two
existing premise-guarded tests are untouched.

### Red control (G4)

Disabled the negative-eigenvalue branch in `R/check.R`
(`hessian_conditioning_cov_row()`) by forcing
`mu_min_trusted_negative <- FALSE` (was `mu_min < -tol_cov`), leaving
everything else unchanged. Re-ran the test file:

```
── Failed ──────────────────────────────────────────────────────────────────
1. Failure ('test-check-conditioning.R:60:3'):
   ...genuinely (resolvably) indefinite fit
   Expected `row$status` to equal "warning". Actual: "note"
2. Failure ('test-check-conditioning.R:61:3'): same test
   Expected `row$value` to match "min_eig=-".
   Actual: "min_eig=159.9; cond=128956873186204."
3. Failure ('test-check-conditioning.R:100:3'):
   ...deterministic injected-indefinite covariance
   Expected `row$status` to equal "warning". Actual: "ok"
4. Failure ('test-check-conditioning.R:101:3'): same test
   Expected `row$value` to match "min_eig=-".
   Actual: "min_eig=1.000; cond=1.000"
```

4 failures (2 from the pre-existing "genuinely (resolvably) indefinite" test,
which on this Mac run was not skipped and also caught the disabled branch;
2 from the new deterministic test). Restored `R/check.R` and confirmed
`git diff --quiet R/check.R` (byte-identical). Re-ran the full test file:
0 failures, deterministic test not skipped.

## 4. Verification

```
env -u DRM_JL_PATH -u DRMTMB_JULIA_TESTS \
  Rscript -e 'devtools::load_all(".", quiet=TRUE); \
    testthat::test_file("tests/testthat/test-check-conditioning.R", reporter="summary")'
```
0 failures, 10 `test_that()` blocks, all pass; the new deterministic test and
the two existing indefinite/near-singular tests were all *not* skipped on
this run (macOS LAPACK resolved both boundary cases to the expected side
this time).

Gate CHECKs (`.unlazy/night/gates/leaf-n4.md`) N4-G1, N4-G2, N4-G3, N4-G5 all
passed their literal `CHECK` commands (`BOARD_ROW_OK`, `NAME_MATCH_OK`,
`DETERMINISTIC_OK`, `CI_LIKE_OK` / `N4_CI_OK`). N4-G4 is the manual red
control above. No `gate-check` binary exists under `.unlazy/night/` (only
`.unlazy/true-parity/bin/reverify-all.sh` and
`.unlazy/rev-parity/bin/drmjl-fence.sh` for the other two lanes), so gates
were verified by running each leaf's literal `CHECK` command directly rather
than through a `--reverify --approve` wrapper.

## 5. Files touched

- `docs/design/capability-status.md` -- one new row + updated counts/prose.
- `tests/testthat/test-check-conditioning.R` -- one new deterministic test.
- `docs/dev-log/after-task/2026-09-03-n4-board-indefinite.md` -- this note.

`R/check.R` was edited transiently for the G4 red control and restored
byte-identically (`git diff --quiet R/check.R`); it does not appear in the
final diff. No receipt regeneration was needed: neither touched file is
pinned by the C17 receipt (which pins `R/drmTMB.R`, `R/methods.R`, `src/`,
`test-zero-one-beta.R`) or by the lss-tip-identity receipt (which pins all of
`R/`, untouched here).

## 6. Deviations from the brief

- Construction (1) (rank-deficient design) was not attempted to completion;
  went directly to construction (2), the brief's own second-preference
  option, because it is the more direct exercise of the exact function under
  test (`sdr$cov.fixed`-only) and the brief flagged construction (1) as
  contingent on an as-yet-unestablished fact (whether `drmTMB()` drops the
  aliased column before TMB).
- `gate-check --reverify --approve` does not exist for the `night` pipeline;
  gates were verified by running each leaf's literal `CHECK` command by hand
  (see §4).
