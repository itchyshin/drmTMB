# After Task: Meuwissen-Luo inbreeding for pedigree F (#1424)

Date: 2026-09-24
Lane: Cursor, `cursor/meuwissen-luo-1424-20260924`
Worktree: `~/local-scratch/lanes/drmTMB-meuwissen-luo-1424-20260924` off `origin/main`
Active lenses: Ada, Shannon, Rose, Hopper, Curie (perspectives; no spawned subagents)
Current lane: R (drmTMB)

Reader: anyone fitting `animal(1 | id, pedigree = ped)` after #1422, and anyone auditing whether this slice still forms dense `A` to obtain inbreeding.

## Goal

Stop the fit path from building dense `A` only to read `F = diag(A) - 1`. S4 (`docs/dev-log/plans/2026-09-24-tmb-1422-animal-fit-wall-receipt.md`) showed that leftover on the post-#1422 route: at n = 10 000, construction is 59.719 s of a 67.008 s fit (89%), with construction ratios 4.2 and 4.0 across doublings of n. #740 / #1422 already closed A-inverse assembly. This slice is the remaining construction cost.

## Implemented

`drm_pedigree_sparse_precision()` now calls `drm_pedigree_inbreeding_meuwissen_luo()` (T-row / max-heap walk), then `drm_pedigree_quaas_ainv()` (the vectorised Quaas assembly extracted from the post-#1422 inline path). `drm_pedigree_sparse_precision_dense_F()` keeps `diag(A) - 1` as the oracle for tests and the identity ladder. `drm_pedigree_additive_relationship()` stays for tests and simulation DGPs; it is not on the fit path.

Public `animal()` syntax is unchanged. Selfing is accepted when the pedigree supplies `sire == dam` (the walk is defined); there is no new `allow_selfing` flag.

## Mathematical Contract

Meuwissen and Luo (1992) compute `F` without forming `A`. `A = T D T'` with Mendelian sampling variances on `diag(D)`:

```
d_j = 0.5 - 0.25 (F_sire(j) + F_dam(j)),   F_0 = -1
F_i = A_ii - 1,   A_ii = sum_j L_ij^2 d_j
```

Unknown-parent sentinels recode to `0L` before the walk. One unknown parent forces `F_i = 0`. The heap pops the largest live row index first. After pop, `L[j]` is zeroed. Parents are pushed only when `L[p] == 0`, then `L[p] += 0.5 * L[j]`. Pedigree must already be ancestors-before-descendants (`drm_pedigree_topological_order()`).

Quaas then assembles sparse `A^{-1}` from `{F_i}`: each animal adds `(1/d_i) * [1, -1/2, -1/2]` over itself and known parents. `A^{-1}` is this construction, not `solve(A)` or `chol2inv(A)`.

Identity vs the dense-F oracle: coefficients and logLik at 1e-8. Random-effect SD is recorded, not gated.

## Files Changed

- `R/phylo-utils.R`: fit-path `F` walk; dense-F oracle; extracted Quaas helper
- `inst/COPYRIGHTS`: HSquared.jl MIT pin `eee5f7aa7640abafa6b2efd2b71a66182db77459`; source not vendored
- `tests/testthat/test-pedigree-sparse-ainv.R`: 18 expectations (was 6 after #1422)
- `docs/dev-log/check-log.d/2026-09-24-meuwissen-luo-1424.md`
- `tools/meuwissen-luo-s4-ladder.R`: same-build identity / construct split (not a user tool)

Do not ship `LOOP/lanes/` from this worktree. NEWS, README, and pkgdown were left alone (no speed wording).

## Checks Run

```
pkgload::load_all()
testthat::test_file("tests/testthat/test-pedigree-sparse-ainv.R")
# 18 pass / 0 fail
```

Official ladder (`~/local-scratch/tmb-1424-parallel/receipt-harness/run-1424-ladder.R`, S4 DGP, seed `100 + n`, BLAS threads = 1, R 4.6.0, TMB 1.9.21, `load_all` of this worktree):

| n | construct (s) | fit (s) | fit minus construct (s) | nnz | conv |
|---:|---:|---:|---:|---:|---:|
| 1500 | 2.237 | 3.276 | 1.039 | 9570 | 0 |
| 3000 | 7.494 | 11.966 | 4.472 | 19162 | 0 |
| 6000 | 41.793 | 48.520 | 6.727 | 38334 | 0 |
| 10000 | 137.965 | 151.254 | 13.289 | 63878 | 0 |

Same-build A/B vs dense-F (`tools/meuwissen-luo-s4-ladder.R`, seed `1424 + n`): identity pass at n in {1500, 3000, 6000}. n = 10 000 A/B is not in that CSV.

Scratch receipt: `~/local-scratch/lanes/GLLVM.jl-s9cov-20260921/docs/dev-log/plans/2026-09-24-drmtmb-1424-meuwissen-luo-receipt.md`. Official n = 10 000 row taken from `1424-candidate.csv` after that cell finished.

`test-animal-relmat-gaussian.R` and `devtools::check()` were not re-run in the session that drafted this report.

## Tests Of The Tests

The new blocks compare Meuwissen-Luo `F` to `diag(A) - 1`. The n = 80 connected pedigree also compares sparse `A^{-1}` from both `F` routes. One unknown parent pins `F = (0, 0)`. Selfing pins `F = 0, 0.5, 0.75, 0.875`. Reciprocal sire/dam swap is an identity for `F` and `A^{-1}`. The small animal fit swaps `drm_pedigree_relatedness_precision` in the namespace so both arms share one compiled DLL; it asserts `coef(mu)`, `coef(sigma)`, and logLik. The older nnz test still bounds stored nonzeros by `9n`.

Identity against installed 0.7.1 is the wrong comparator: that library is still the pre-#1422 dense invert (nnz at n = 1500 was 2 123 030). The post-#1422 route is the dense-F oracle in this worktree.

## Consistency Audit

```
rg "Meuwissen|meuwissen_luo|eee5f7aa" R/phylo-utils.R inst/COPYRIGHTS tests/testthat/test-pedigree-sparse-ainv.R
rg "chol2inv|diag\\(A\\) - 1" R/phylo-utils.R
rg "times faster|speedup|speed multiplier" NEWS.md README.md docs/dev-log/after-task
```

Fit-path `F` is the Meuwissen-Luo walk. `diag(A) - 1` remains only on the oracle helper and in tests. `chol2inv` is still gone. NEWS and README were not given a speed line.

## GitHub Issue Maintenance

https://github.com/itchyshin/drmTMB/issues/1424 is the issue. The PR closes it (`Closes #1424`). Do not reopen #740. Do not comment a speed multiplier on #1424; point at the receipt and `1424-candidate.csv`. #914 and #1148 stay deferred.

## What Did Not Go Smoothly

The R heap walk can be slower than dense `A` at mid n on this machine. Same-build construct at n = 6000: dense-F 22.546 s, Meuwissen-Luo 41.032 s (`.unlazy/meuwissen-luo-1424/s4-ladder.csv`; different seed from the official ladder). The walk was left as published. Rewriting it for wall time is a later slice if one is wanted.

The official n = 10 000 cell finished after the sibling draft: construct 137.965 s, fit 151.254 s, nnz 63 878, conv 0. The check-log is updated to those numbers in the same commit as this report.

## Team Learning

S4 already inverted the clock: after #1422 the thing to measure is construction inside the fit, in absolute seconds, on the same DGP. Installed 0.7.1 is not an identity partner for a post-#1422 change. Totoro wall numbers stay host-specific (S4's n = 300 pre-arm was 473.4 s there against 1.031 s on the Mac). Launch long cells with `launch.py` (double-fork + `setsid`); session `nohup` is reaped.

gllvmTMB has no Meuwissen-Luo walk. Its `F` is still `diag(A) - 1`. Co-opt the F walk from HSquared.jl (MIT). Keep Quaas from the post-#1422 / gllvmTMB assembly. Do not pull gllvmTMB's dense tabular `A` back onto the fit path.

## Known Limitations

- Claim is the Gaussian `animal(1 | id, pedigree = )` route with one observation per animal. Non-Gaussian families, repeated records, and `relmat()` / supplied-`A` routes are untested here.
- No NEWS or README speed multiplier. No fit-level speed ratio.
- Official n = 10 000 is in `1424-candidate.csv`. Same-build A/B at n = 10 000 is still missing from `.unlazy/meuwissen-luo-1424/s4-ladder.csv`.
- gllvmTMB still forms dense tabular `F` (optional later twin).
- Does not reopen #740, #914, or #1148.

## Next Actions

1. PR https://github.com/itchyshin/drmTMB/pull/1427 is open (`closes #1424`). Merge-when-green on green CI.
2. Comment on #1424 with the receipt path after merge. Do not add README or NEWS speed wording.
3. Optional later: gllvmTMB twin if that package still forms dense `A` for `F`.
