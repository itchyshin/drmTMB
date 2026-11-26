# After Task: Poisson vs NB2 boundary LRT detection (#1557)

## Goal

An applied user who compares a Poisson fit with a nested NB2 fit through
`anova()` should see the same boundary treatment `anova()` already gives an
added `(1 | g)` standard deviation. The extra NB2 `sigma` is tested at 0
(`Var(y) = μ + σ² μ²`; `σ → 0` is Poisson). That is a Self–Liang / Stram–Lee
boundary null, not an interior χ²₁ test. Lane t10 filed the silent naive
χ² as drmTMB #1557 and the matching Julia gap as DRModels.jl #1115.

This report also records why #1559, #1560, #1116, and #1118 are **not**
closed here. Putting type-I at α = 0.05 into the t10 bar `[4%, 6%]` needs a
methods choice. The lane rules say stop and list options instead of choosing
mixture weights or a parametric bootstrap.

## Implemented

`anova(pois, nb)` now detects `poisson` ⊂ `nbinom2` when the only extra
parameter is the `sigma` intercept. It warns with class
`drmTMB_anova_boundary_warning` and reports the 50:50 chi-bar p-value from
`lrt_boundary(nb, pois, q = 1)`. `attr(*, "p.method")` is `"chibar"`. That
is the same packaged contract #1240 already chose for one added random-effect
SD.

The unexported `drm_lrtest()` warns with class
`drmTMB_lrtest_boundary_warning` and keeps the naive χ² p-value. That is the
existing pairwise-helper contract: warn, do not swap.

Sibling family nests stay off the detector: Poisson vs `zi_poisson`,
binomial vs `beta_binomial`, and NB2 vs `zi_nbinom2` still use silent χ².
A unit test pins that scope. Interior Gaussian `sigma ~ 1` vs `sigma ~ x`
still does not warn.

DRModels.jl `lrtest` / `anova` (they are the same function) now warn on
`Poisson()` ⊂ `NegBinomial2()` and still report naive χ². That follows
Julia issue #304: do not silently swap the reference. Call
`lrt_boundary(nb, pois; q = 1)` to match drmTMB `anova()`'s p-value.

## Mathematical Contract

For one non-negative parameter tested at 0, with every other parameter
interior, Self and Liang (1987) and Stram and Lee (1994) give the null

\[
\bar\chi^2 = 0.5\,\chi^2_0 + 0.5\,\chi^2_1,
\]

so `p = 0.5 P(χ²₁ > stat)` for `stat > 0`, and `p = 0.5` at `stat = 0`.
NB2 uses `log(σ) = η_σ` and `size = 1 / σ²`. The Poisson model is the
`σ = 0` boundary of that family. The packaged R `anova()` p-value is
exactly `chibar_pvalue(stat, 1)`. Julia `lrtest` still reports
`P(χ²₁ > stat)` and tells the user to call `lrt_boundary`.

This is an asymptotic mixture. It is not a finite-sample calibration.

## Files Changed

drmTMB: `R/model-comparison.R` (detector and `anova` / `drm_lrtest` paths),
`R/methods.R` and `R/lrt-boundary.R` (roxygen), matching `man/` pages,
`tests/testthat/test-anova-lrt.R`, `NEWS.md`,
`docs/design/capability-status.md`, this report, and the check-log.

DRModels.jl (pin `f71b292`, branch `cursor/fx6-boundary-lrt-3f95`):
`src/comparison.jl`, `test/test_family_boundary_lrt.jl`, `NEWS.md`, and
the Julia after-task.

`R/drmTMB.R`, `R/mi-weights.R`, and `src/` were not edited.

## Checks Run

Red-proof on the pinned tree `ca3ddef` before the detector existed, then
the same file after the change (`pkgload::load_all`,
`testthat::test_file("tests/testthat/test-anova-lrt.R")`):

| test | before | after |
| --- | --- | --- |
| `anova()` uses chi-bar for Poisson vs NB2 and warns (#1557) | 2 pass / 7 fail (`p.method = "chisq"`, p = 1 vs chi-bar 0.5, no warning) | 7 pass / 0 fail |
| `drm_lrtest()` warns and keeps naive p (#1557) | no warning | warning + naive p |
| mixture does not apply when df ≠ 1 | no warning | `"does not apply"` + `"chisq"` |
| detector is Poisson → NB2 only | error: helper missing | 5 pass; zi and beta-binomial stay off |
| existing #1240 anova tests | 38 pass | 38 pass |

Sibling paths after the fix: `test-model-comparison.R` 68 pass / 0 fail /
2 Julia-bridge skips; `test-lrt-boundary.R` 62 pass / 0 fail / 2 skips.

C17 recertified after the `R/methods.R` roxygen edit:
`python3 tools/recertify-c17.py --label fx6-1557 --tolerance 1e-10`.
`mean_tau_relative_error` was bit-identical (|change| 0.000e+00) on
mc-0568, mc-0569, and mc-0576. Receipt:
`docs/dev-log/implementation-recovery/2026-10-16-fx6-1557-c17c2-c14-final-source-compatibility`.
Source sha `3180adfd5`.

Julia on pin `f71b292`: `test/test_family_boundary_lrt.jl` 11 pass;
`test/test_comparison.jl` 12 pass.

## Tests Of The Tests

The new anova test failed on the unfixed source with the exact #1557
symptoms (silent `"chisq"`, p = 1, `lrt_boundary` p = 0.5 on the mapped
seed). It compares the packaged p-value to `lrt_boundary()` and to half
the naive p-value. The df ≠ 1 branch is a malformed-nest path. The
detector unit test checks the neighbouring families that share the
pattern and are intentionally unwired.

## Consistency Audit

Searched:

```sh
rg "anova\\(.*nbinom2|p.method|chi-bar-square p-value when" R tests docs NEWS.md
rg "exactly one or two random-effect SDs" docs
```

`docs/design/capability-status.md` and `?anova.drmTMB` now name the Poisson
vs NB2 nest. Formula grammar and likelihood parameterization did not
change. `sigma` stays the public scale name.

## GitHub Issue Maintenance

Refs #1557, #1559, #1560 on drmTMB and #1115, #1116, #1118 on DRModels.jl.
Draft PRs say "Refs", never Closes or Fixes. #1559 / #1560 / #1116 / #1118
remain open because type-I is still 3.0% and 3.4% under the 50:50 mixture
on the t10 500-rep grids.

## What Did Not Go Smoothly

The two engines already disagreed on the packaged RE p-value: drmTMB
`anova()` applies chi-bar; Julia `lrtest` warns and keeps χ². Making the
packaged p-values identical would reverse Julia #304. This change follows
each engine's existing policy and documents how to match p-values
(`lrt_boundary` on Julia).

Official seed `20261017000` still overflows R `set.seed` and Julia
`UInt32`. Tests use the t10 map `official - 1.9e10`.

## Team Learning

A boundary detector that only inspects `sdpars` / `corpars` will miss
every family-dispersion nest. If another nest is wired later, add it to
`drm_family_boundary_nest()` / `_family_boundary_nest` with a red-proof
pair, and do not treat 50:50 chi-bar as a 5% finite-sample test.

## Known Limitations

The 50:50 mixture is the project's existing asymptotic boundary null. On
the t10 Poisson-null grid (n = 250, 500 reps) chi-bar type-I is 3.0%
(15/500) and 55.0% of statistics sit on the χ²₀ atom. On the RE-null grid
(G = 25, m = 12, 500 reps) chi-bar type-I is 3.4% (17/500) and the atom
is 58.6%. Both miss `[4%, 6%]`. Naive χ² is worse (1.8% and 1.2%). R and
Julia likelihood-ratio statistics already agree to 1e-8 on those CSVs.

## Next Actions

Owner decision on type-I calibration. Do not implement an option below
without that decision.

1. **Keep 50:50 chi-bar as the published p-value** and treat `[4%, 6%]` as
   the wrong finite-sample bar for these n. Document the extra atom.
   Cheapest; honest about asymptotics; leaves #1559 / #1560 / #1116 /
   #1118 open or recasts them as documentation.
2. **Estimate mixture weights from the atom**, for example replace 0.5/0.5
   with the observed 0.55/0.45 on this DGP. That can move type-I nearer 5%
   here and is not a general Self–Liang weight. It would overfit one grid.
3. **Parametric bootstrap under the Poisson or no-RE null.** This is the
   usual finite-sample repair. It needs B, a refit-failure rule, and a
   decision about whether `anova()` runs the bootstrap by default or only
   through a new argument. Expensive relative to the current table.
4. **Score / Rao overdispersion tests** for NB2 vs Poisson only. Different
   statistic; not a drop-in `anova()` p-value; does not help `(1 | g)`.
5. **Wire sibling nests** (Poisson vs `zi_poisson`, binomial vs
   `beta_binomial`, NB2 vs `zi_nbinom2`) onto the same 50:50 path once the
   owner wants that scope. Same asymptotic theory; no t10 type-I evidence.

A user who needs a p-value today should read `anova()`'s chi-bar p-value
on drmTMB, or call `lrt_boundary(full, reduced, q = 1)` on both engines,
and should not treat the packaged Julia χ² p-value as calibrated.
