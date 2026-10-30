# 2026-10-16: large-argument kernels (lane f12)

Reader: a package contributor who reviews `src/` changes, and an applied user whose Student-t, Gamma or Beta fit sits at large `nu`, small CV or large `phi`.

## Task goal

Remove the `eps * x log(x)` rounding from three response log-densities, so the compiled objective agrees with the exact density to 1e-12 per observation from 1e2 to 1e8, and sweep the rest of `src/drm_response_kernels.h` for the same pattern. Stacked on #1504, whose Student kernel it replaces.

## What changed

- `drm_student_log_density()`: `D(nu) = lgamma((nu+1)/2) - lgamma(nu/2) - log(nu/2)/2` is the exact difference below `nu = 100` and the series `-1/(4nu) + 1/(24nu^3) - 1/(20nu^5) + 17/(112nu^7) - 31/(36nu^9)` from 100 (residual 7.8e-22, checked in mpmath). The kernel factor uses `drm_log1p_pos(z^2/nu)`. #1504's switch at `nu = 1e4` left a direct lgamma difference with about 1e-11 error just below it.
- `drm_gamma_log_density()` (new): `log(s)/2 - log(2 pi)/2 - B(s) - s (e^w - 1 - w) - log y`, `s = 1/sigma^2`, `w = log y - eta`, `B` the Stirling remainder. Used by the `mi()` leaf and the main loop.
- `drm_beta_log_density()` (new): log-beta through three Stirling remainders; `u = y p / a - 1` formed with an exact product error (Dekker 1971) because `a u eps` is otherwise the surviving error. Used by the `mi()` leaf, the main loop and the zero-one-inflated block.
- bivariate Student: `drm_log1p_nonnegative` replaced by `drm_log1p_pos` (the old helper is plain `log(1 + x)` above 1e-5).
- `src/drm_numeric.h`: `drm_expm1_minus_x`, `drm_x_minus_log1p`, `drm_log1p_pos`, `drm_stirling_remainder`, `drm_two_prod_err`. TMB 1.9.10's CppAD has no `log1p` or `expm1` for AD types, so these are built from series, `logspace_add` and `exp`.

## Not changed, and why

- Beta-binomial: now covered here too (tracking issue #1548 asks for every copy). `drm_beta_binomial_log_density` and its helpers are byte-identical to #1514's, so the two PRs merge cleanly in either order; this PR also swaps the `mi()` leaf, the main loop and the two `mi()` beta-binomial prior copies (`src/drmTMB.cpp` about 1801 and 1825) that #1514 left. Measured against the exact `sum log(alpha + j)` it is within 1.1e-13 at phi 1e2 to 1e8; the 1e-12 ship test is in `test-large-argument-kernels.R`.
- NB2 (`src/drm_count_kernels.h`): per the C++ TMB reviewer, no code change. `log1p` is correct, but the `lgamma(y + 1/alpha) - lgamma(1/alpha)` branch (used when `alpha y >= 1e-2`) has the same pattern: 2.1e-9 at size 1e6 with mean 2e4 and 4.7e-8 at size 1e8 with mean 2e6. The series branch is 1.9e-12 at size 1e4, y = 99. Proposed fix: `drm_lgamma_ratio(1/alpha, y)` from #1514. R's `dnbinom()` is itself 2e-9 off at size 1e8, so NB2 tests must use an exact reference.
- `mi()` priors in `src/drmTMB.cpp` (Beta 1536-1735, beta-binomial 1801-1833, Gamma 2259-2309) and the `log_choose` terms for trials above about 1e5: same pattern, follow-up after #1513 round 5.

## Evidence

Per-observation errors against mpmath at 60 digits are in the PR body. The Beta figure through the model is bounded by one rounding of `plogis(eta)` upstream of the kernel (`phi |u| eps`, 8e-12 at phi = 1e8 for a 4-sd row); the kernel alone, given alpha and beta, is 2.3e-13.

Tests: `tests/testthat/test-large-argument-kernels.R` (Student vs `dt()` and the Gaussian limit, Gamma and Beta vs pinned mpmath values and vs `dgamma()` and `dbeta()`, NB2 at `alpha y < 1e-2`, AD gradient and Hessian either side of every branch switch).

## Open

- `summary()` on a false-convergence fit prints the bare convergence code with no "not converged" wording and no warning (`print()` and the fit-time warning do flag it). Left for the Issue writer to file; not changed here.
- The C17 model-15 receipt is recertified after the `src/drmTMB.cpp` hunks (see the commit that carries `tools/recertify-c17.py` output).

## 2026-10-18: rebase onto `main` after #1504

#1504 was rebased onto `main` (`af2ee2501` to `b56ecfa07`), so this branch was first rebased onto `b56ecfa07`. While the checks below ran, #1504 was squash-merged as `e17921e9b`, whose tree is identical to `b56ecfa07`. The branch was then moved onto `e17921e9b` with every commit keeping its tree, so the results below apply to it unchanged. The five original commits replay with `src/` and test patches byte-identical to the pre-rebase ones (`git patch-id --stable`). Two files conflicted. `NEWS.md` keeps both sides: `main`'s profile, trace and `configure.win` bullets, then this PR's kernel bullet. The C17 ledger TSV took this branch's row and was then recertified.

C17: the rebase brought `main`'s `src/drmTMB.cpp` changes under this branch, so the f12b receipt was stale. `python3 tools/recertify-c17.py --label pr-1547 --tolerance 1e-12` on Totoro (R 4.6.1, TMB 1.9.25) gave a worst `|change|` of 2.570e-13 (mc-0569) against the f12b receipt. The same runner on the unchanged #1504 head, on the same machine, moves 1.306e-11 from #1504's own receipt, so the residual is machine noise and not the rebase. From that #1504 head to this branch on one machine the change is 2.56e-11 (mc-0568), the kernel effect measured before.

Red proof, rerun on the new base: `test-large-argument-kernels.R` on the bare #1504 head fails 25 expectations in 6 blocks (Student 1, Gamma 6, Beta 12, beta-binomial 6), and `test-numeric-kernel-oracle.R` with this PR's Gamma pin fails 1. Both pass on this branch.

Full suite on Totoro (`testthat::test_local()`, `NOT_CRAN=true`, 8 shards, CI unset): 452 files, PASS 49300, FAIL 2, ERROR 0, SKIP 104. This PR's files: `test-large-argument-kernels.R` 153 pass, `test-numeric-kernel-oracle.R` 392 pass, `test-guard-branch-continuity.R` 59 pass, no failures. The two failures are `skip_fragile_recovery()` tests, which CI skips: `test-nbinom2-sigma-structured-recovery.R:80` (sigma-phylo logLik gain 14.5, bar 3) and `test-reml-structured-location.R:244` (the independent R reference returns `optim` code 52 for spatial `one_slope`). Both fail the same way on the unchanged #1504 head on the same machine, and neither path reaches a changed kernel. The CI ledger, profile-fence, evidence-citation and source-tree-manifest gates pass. `R CMD check --as-cran --no-manual --no-tests` passes examples, `--run-donttest` examples and all vignettes; its one WARNING is the missing `checkbashisms` script on Totoro, and its NOTE is a compiler flag from Totoro's R build.

`devtools::document()` (roxygen2 8.0.0) rewrites 39 `man/*.Rd` files on this branch and on its base alike, because #1400 edited `man/` directly and the roxygen sources in `R/` still carry the old wording. Committing that output would undo #1400, so it is not committed here. The fix belongs in `R/` in its own PR.

## 2026-10-19: review round after #1581

Rebased onto `4f151444f` (#1581, after #1590). Only the C17 ledger TSV conflicted, in its receipt columns; `claim_boundary` was identical on both sides. `git diff 0902529bd HEAD -- src/` is empty, and `git range-diff` shows the eight earlier commits identical apart from that TSV's context lines.

Review points, all test or documentation changes:

- `test-large-argument-kernels.R` calls `skip_on_cran()` at the top; `inst/extdata/env-skip-census.tsv` gains one `cran-lane` row, regenerated with `tools/write-env-skip-census.R`. With `NOT_CRAN` unset the file records one skip.
- The Gamma shape-1e8 failure on macOS (5.35e-12 against the 1.5e-12 bar) was the fixture, not the kernel. R without long double (arm64 macOS) parses `0.9162907318741551` as `0x1.d5240f0e0e079p-1`, one ulp above the correctly rounded value that mpmath and Linux R use, and at shape 1e8 one ulp of `eta` moves the density by 4.4e-12 for a 4-sd row. With `eta` written as the hex double, the Mac's worst errors are 2.1e-14, 1.4e-13 and 9.10e-13 at shape 1e4, 1e6 and 1e8, matching the Linux figures. On the Mac `log(y)` is correctly rounded on all 24 rows, and the kernel matches a 200-bit evaluation of its own formula to within 1e-15 given its double inputs. The bar stays 1.5e-12; the PR body's "2e-12" was corrected.
- `test-beta-binomial.R`: the perfectly separated fixture keeps its finiteness checks and drops the strict `0 < mu < 1` checks, because its MLE is on the boundary and the Mac fit on this branch reaches `mu` of exactly 0 and 1 (link -3347.7 and +3347.7; `main` stops at link ±28.12). A new nearly separated test (one success in the low group, one failure in the high group) has fitted `mu` 0.01 and 0.99 and keeps the strict check. On that fixture `main` reports convergence code 1 and a logLik 1.1e-5 above the exact supremum (-6.595136685, the binomial limit); this branch converges to it.

C17: `tools/recertify-c17.py --label pr-1547-1581 --tolerance 1e-10` on the Mac, with the runner folder from `2d2db519f` moved aside and restored, gave 12/12 and a worst `|change|` of 0.000e+00 against this branch's previous receipt. `capability_ledger.py --check` and `--check-c14-receipt-equivalence` pass; `tools/ci-receipt-staleness.sh` reports the lss-tip-identity receipt fresh (57 of 57 R/ files), so it was not regenerated.

Full suite on this Mac (R 4.6.0, TMB 1.9.21, `NOT_CRAN=true`, 4 shards with `DRMTMB_TEST_SHARD`'s file split, `numeric-kernel-oracle` run on its own): 455 of 457 files, PASS 49247, FAIL 3, ERROR 0, SKIP 95. This PR's files pass: `test-large-argument-kernels.R` 153, `test-beta-binomial.R` 84, `test-guard-branch-continuity.R` 69, `test-env-skip-census.R` 5. The three failures are `test-associate-pairs-bernoulli-bernoulli.R:40` (eta 0.551583976 against 0.551583956) and `test-nbinom2-sigma-structured-recovery.R:52-53` (logLik gain 9.0 against bars 15 and 10). Both test files are unchanged from `main`, and with `origin/main` `4f151444f` built on the same Mac they fail with the same numbers. `julia-tmb-parity` skips at file level (no Julia). `numeric-kernel-oracle` passed 365 of 365 expectations, every kernel this PR touches included, and then stalled in the tweedie test (TMB 1.9.21's series loop, as on `main` on this Mac); it was stopped there.

`devtools::document()` (exit 0) rewrites 39 `man/*.Rd` files (+208/-180) and nothing outside `man/`, as recorded on 2026-10-18. `R/`, `NAMESPACE` and `DESCRIPTION` are identical to `origin/main`, so `main` gets the same output. Not committed.

Not covered: no Linux rerun of the new nearly separated test before CI, and the Julia twin gap (DRModels.jl Beta has no squeeze on `mu`; its Gamma `logpdf` is about 5e-3 off at CV 1e-6) is out of scope here (#1514, #1547).
