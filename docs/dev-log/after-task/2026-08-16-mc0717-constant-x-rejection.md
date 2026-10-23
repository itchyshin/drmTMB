# After Task: Reject constant-within-group `x` on binomial q2

**Reader:** Fisher / Noether on PR #1059, plus the next Wave 1 reviewer.
**Lane:** `cursor/ng-correlated-slope-impl` (worktree `.worktrees/ng-corr-w1`).
**Quiesce:** draft PR only. Do not merge to `main`.

## Goal

Close the Design 257 ADEMP residual that a slope with no within-group
variation in `x` is unidentified. The auditor confirmed that design still
fitted (`convergence = 0`, `sd1 ≈ 0`, `pdHess = FALSE`, `rho_re ≈ 0.997`).
The contract asked for a rejection test, not a recovery cell.

## Implemented

`drm_validate_binomial_q2_context()` now calls
`drm_validate_binomial_q2_slope_variation()` after the REML and
missing-response fences. The helper aborts when no group has two or more
unique finite slope-design values. That is the fully unidentified case
(`x` equal to the group index, or any other within-group constant). A
design that varies in at least one group still fits; `check_drm()` already
notes weak within-group variation there.

The abort lives in `R/mspl-estimator.R`, not `R/drmTMB.R`, so the C14
current-source receipt for `mc-0568` / `mc-0569` / `mc-0576` is untouched.

R syntax that now errors before TMB construction:

```r
dat$x <- as.numeric(dat$id)
drmTMB(
  bf(cbind(success, failure) ~ x + (1 + x | id)),
  family = binomial(),
  data = dat
)
```

The slope SD and group-level `rho_re` are unidentified in that design.
Residual `rho12` is not involved.

## Files Changed

- `R/mspl-estimator.R` — slope-variation abort on the binomial q2 context fence
- `tests/testthat/test-binomial-correlated-re-mspl-prereq.R` — rejection-matrix row
- `docs/design/257-nongaussian-ordinary-correlated-slope.md` — ADEMP rejection matrix
- `docs/design/01-formula-grammar.md`, `NEWS.md`, `docs/dev-log/known-limitations.md`
- `docs/dev-log/check-log.md` — this slice

Not touched: `R/drmTMB.R`, `R/missing-data.R`, MSPL estimator logic, Ligges /
CRAN, Wave 2 / NB2, #1033.

## Checks Run

| Check | Result |
| --- | --- |
| `devtools::test(filter = 'binomial-correlated-re-mspl-prereq')` | FAIL 0 / WARN 0 / SKIP 0 / PASS 57 |
| `devtools::test(filter = 'reml-binomial-coxreid')` | FAIL 0 / WARN 0 / SKIP 0 / PASS 33 |

## Tests Of The Tests

The new row uses the auditor fixture (`x` set to the group index) and
expects the abort substring `need within-group variation in the slope predictor`.
Before this change that design fitted. The existing recovery test still uses
`mspl_q2_data()` with `x ~ Normal(0, 1)` varying within group.

## Consistency Audit

```sh
rg "need within-group variation|constant within every" R/mspl-estimator.R tests/testthat/test-binomial-correlated-re-mspl-prereq.R docs/design/257-nongaussian-ordinary-correlated-slope.md docs/design/01-formula-grammar.md NEWS.md docs/dev-log/known-limitations.md
rg "experimental q = 2" R/drmTMB.R
rg "rho12" docs/dev-log/after-task/2026-08-16-mc0717-constant-x-rejection.md
```

Grammar, NEWS, and known-limitations name the abort. The parser `i` hint in
`validate_binomial_mu_random_terms()` still says `experimental q = 2`.
Refreshing that string requires a C14 current-source receipt rerun (12
zero-one-beta attempts plus provenance re-point). That is not cheap, so the
hint stays. `rho12` appears only to say this block is not residual
correlation.

## GitHub Issue Maintenance

Comment on draft PR #1059. No merge request. #1033, #1049, #1060, and the
NB2 branch were left untouched.

## What Did Not Go Smoothly

`R/mspl-estimator.R` is also open on parked MSPL evidence branches. Those
diffs touch MSPL link admission, not this q2 context fence. The abort was
kept next to `drm_validate_binomial_q2_context()` and did not adopt or
revert the MSPL work.

## Team Learning

When a C14-pinned file is the obvious home for a user-facing message, look
for an unpinned context fence first. The binomial q2 REML / missing-response
guard was already the right door.

## Known Limitations

- Ceiling remains `point_fit_recovery`. This abort is not a recovery claim.
- Partial designs (some groups constant, at least one group varying) still
  fit; `check_drm()` records a note.
- The parser hint still says `experimental q = 2`.
- Wave 2, REML, AGHQ, intervals, coverage, and `supported` remain closed.

## Next Actions

1. Keep draft PR #1059 unmerged.
2. Do not refresh C14 unless someone owns a dedicated receipt rerun.
3. Stay off #1033, MSPL, Ligges, and the NB2 / Wave 2 branches.
