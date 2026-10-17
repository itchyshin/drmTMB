# After Task: parametric bootstrap null for anova() (FX6b)

## Goal

Give an applied ecology user a finite-sample p-value for a boundary
likelihood-ratio test without replacing the packaged default. On 16 Oct
2026 at 5:23 PM MT Shinichi chose to keep the Self–Liang / Stram–Lee
50:50 chi-bar mixture as the default and add a parametric bootstrap
under the null as an option. That work lands on PR #1563
(`cursor/fx6-boundary-lrt-3f95`) and answers the type-I calibration
filed as #1559, #1560, and the Julia twins #1116 and #1118.

## Implemented

`anova(..., test = "bootstrap", nsim, seed)` and the unexported
`drm_lrtest(..., test = "bootstrap", nsim, seed)` simulate new responses
from the reduced (null) fit, refit both models, and report the
Davison–Hinkley p-value

\[
p = \frac{1 + \#\{T^* \ge T_{\mathrm{obs}}\}}{1 + n_{\mathrm{ok}}}.
\]

The table (or the pairwise list) carries `nsim`, `seed`, and the number
of failed refits. `attr(*, "p.method")` is `"bootstrap"`. The default
path is unchanged: a clean one-SD or Poisson ⊂ NB2 nest still uses
`lrt_boundary()` (`"chibar"`), and `drm_lrtest()` still keeps naive χ²
when `test` is omitted.

The 50:50 default is conservative when there are few groups. Type-I
error at α = 0.05 is at most 5% and has no lower bound. On the t10
500-rep grids the recorded chi-bar rates were 3.0% (NB2 vs Poisson,
n = 250) and 3.4% (`(1 | g)`, G = 25, m = 12). Those values are
expected for this default, not a packaging error.

## Mathematical Contract

The bootstrap draws `y*` from the fitted reduced model
(`stats::simulate(reduced, nsim, seed)`), then refits the same formulas
and families on the new response. A draw fails when either refit errors,
fails to converge, or returns a non-finite log-likelihood. Failed draws
are counted in `failed` and dropped from `n_ok`. This is a parametric
null, not a residual or case bootstrap.

## Files Changed

`R/model-comparison.R` (test parser, bootstrap refits, `anova` /
`drm_lrtest` paths), `R/methods.R` (`anova.drmTMB` signature and
roxygen), `R/lrt-boundary.R` (conservatism note), matching `man/` pages,
`tests/testthat/test-anova-lrt.R`, `NEWS.md`,
`docs/design/capability-status.md`, `docs/dev-log/known-limitations.md`,
`tools/fx6b-t10-bootstrap.R`, this report, and the t10 receipt.

`R/drmTMB.R`, `R/mi-weights.R`, and `src/` were not edited.
`R/methods.R` changed in the `anova()` method and its roxygen, so C17
was recertified (`python3 tools/recertify-c17.py --label fx6b-bootstrap
--tolerance 1e-10`): `|change| 0.000e+00` on mc-0568 / mc-0569 / mc-0576,
receipt
`docs/dev-log/implementation-recovery/2026-10-17-fx6b-bootstrap-c17c2-c14-final-source-compatibility`,
source sha `28474c624`.

DRModels.jl (pin `f71b292`, local branch `cursor/fx6b-bootstrap-null-8e8d`
at `047c12f7f`): `src/comparison.jl`, `test/test_bootstrap_lrt.jl`,
`NEWS.md`. `git push` returned 403. The twin patch is
`docs/dev-log/after-task/2026-10-16-fx6b-DRModels.jl.patch`.

## Checks Run

Red-proof on FX6 head `132a0490` before the option existed, then the
same calls after (`pkgload::load_all`,
`testthat::test_file("tests/testthat/test-anova-lrt.R")`,
`NOT_CRAN=true`):

| test | before | after |
| --- | --- | --- |
| `anova(..., test = "bootstrap")` | error: `test` must be "Chisq", "LRT", or NULL | `"p.method" = "bootstrap"` with nsim, seed, failed |
| `drm_lrtest(..., test = "bootstrap")` | error: unused argument | same p-value as `anova()`, plus nsim/seed/failed |
| existing #1240 / #1557 anova tests | 56 pass | 56 pass |
| new skip_on_cran bootstrap tests | helper missing | 3 pass (interior, Poisson–NB2, `(1 \| g)`) |

Sibling files after the fix: `test-model-comparison.R` 68 pass / 2 Julia
skips; `test-lrt-boundary.R` 66 pass / 2 Julia skips.

Julia on pin `f71b292` plus the FX6 warning patch:
`test/test_bootstrap_lrt.jl` 12 pass;
`test/test_family_boundary_lrt.jl` 11 pass;
`test/test_comparison.jl` 12 pass.

## Tests Of The Tests

The red-proof used the exact FX6 abort (`test` must be "Chisq", "LRT",
or NULL) and the unused-argument error on `drm_lrtest()`. The unit tests
are small (`nsim = 19`, `skip_on_cran`). They check that anova and
`drm_lrtest` agree, that nsim/seed/failed are returned, and that both
boundary nests (Poisson ⊂ NB2 and `(1 | g)`) accept the option. The
t10 type-I bar lives in the receipt, not in the unit file.

## Consistency Audit

Searched:

```sh
rg "Changing mixture weights or adding a parametric bootstrap" docs
rg "test = .bootstrap|p.method|3.0%|3.4%" R tests docs NEWS.md
rg "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" .
```

`docs/design/capability-status.md`, `?anova.drmTMB`, `?lrt_boundary`,
`NEWS.md`, and `docs/dev-log/known-limitations.md` now name the
bootstrap option and record 3.0% / 3.4% as expected for the default.
Formula grammar and likelihood parameterization did not change. `sigma`
stays the public scale name.

## GitHub Issue Maintenance

PR #1563 says Closes #1557 (the Poisson ⊂ NB2 detector). #1559 and
#1560 stay Refs: at `nsim = 99` the bootstrap `p < 0.05` rates were
3.8% (NB2, one shy of 4.0%) and 3.0% (`(1 | g)`), so the campaign
`[4%, 6%]` bar is not met on both cells. Julia twins #1115 #1116
#1118 stay Refs because `git push` to DRModels.jl returned 403. The
default chi-bar p-value is unchanged; 3.0% and 3.4% remain expected.

## What Did Not Go Smoothly

`git push` to `itchyshin/DRModels.jl` returned 403
(`Permission to itchyshin/DRModels.jl.git denied to cursor[bot]`), as
on FX6. The twin is the patch above. Official seed `20261017000` still
overflows R `set.seed`; the t10 map `official - 1.9e10` is reused.

Roxygen 7.3.1 in this environment is older than the package pin 7.3.2
and rewrote unrelated `man/` pages. Those extras were reverted; only
`anova.drmTMB.Rd` and `lrt-boundary.Rd` were kept.

## Team Learning

A 50:50 chi-bar p-value is an asymptotic boundary null. Treating
`[4%, 6%]` as a finite-sample bar for that default will keep failing
whenever the χ²₀ atom exceeds 50%. Document the "at most 5%, no lower
bound" contract on the default, and put the finite-sample bar on the
bootstrap option.

## Known Limitations

The unit tests do not claim a 5% type-I rate. The t10 receipt
(`docs/dev-log/after-task/fx6b-t10-logs/RECEIPT_fx6b_t10.md`,
`nsim = 99`, 500 official seeds) recorded bootstrap `p < 0.05` of
3.8% (NB2) and 3.0% (`(1 | g)`). `test = "bootstrap"` is slower than
chi-bar (4.7 s per NB2 draw and 10.5 s per RE draw at `nsim = 99` on
this host). Julia still reports naive χ² unless `test = :bootstrap` is
passed, and that path needs the original `data` table because a
`DrmFit` does not retain it.

## Next Actions

Wait for PR #1563 CI after this receipt push. A user who wants the
asymptotic boundary p-value should keep the default `anova()`. A user
who wants a finite-sample null should pass `test = "bootstrap"`. A
`[4%, 6%]` `p < 0.05` bar on `(1 | g)` with G = 25 needs a larger
`nsim` than 99; the function default is 199.
