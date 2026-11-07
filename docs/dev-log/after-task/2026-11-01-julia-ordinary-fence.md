# After task: exempt admitted ordinary sd() routes from the #1551 Julia fence

Reader: a maintainer who needs to know whether `engine = "julia"` can fit an
ordinary mean bar with an `sd()` formula for Poisson, NB2, Gamma, Beta and
Binomial.

## Finding

Commit 4c584b592 (#1551, 2026-10-25) added
`drm_julia_refuse_ordinary_mean_re_unlabelled()`. It refused every ordinary
mean bar, `(1 | g)` or `(0 + x | g)`, for those five families and never looked
at `sd()`. Its own test pins only the bare `(1 | g)`, so the intended scope was
a bar with no `sd()`. A static probe at HEAD confirmed the over-reach: with
`DRM_JL_PATH` unset, `bf(y ~ x + (1 | g), sd(g) ~ w)` returned the "does not
yet send a residual-SD label" refusal for all five families, for both bar
shapes, and for a correlated `(1 + x | g)`.

The live tests that expect these routes to fit (`test-julia-poisson-sd.R`,
`-gamma-sd.R`, `-negbinomial-sd.R`, `-beta-sd.R`, `-binomial-sd.R`) skip
without Julia, so no CI run noticed. All of those files were added on
2026-11-01 (commit b87566680), after the fence, so none of them has ever run
against a tree that carried the fence.

## Change

`drm_julia_refuse_ordinary_mean_re_unlabelled()` now returns early when
`drm_julia_ordinary_mean_bars_have_sd(formula, family_type)` is TRUE. The
helper is TRUE only when every ordinary mean bar has a plain group name, each
such group has an ordinary `sd(<group>)` entry (generic `sd`, no structured
`level`, `dpar` unset or `"mu"`), and, outside Binomial, every bar is an
intercept or an independent slope. Everything else stays fenced: a bare bar, a
bar whose group has no matching `sd()`, an interaction group, and a correlated
`(1 + x | g)` for Poisson, NB2, Gamma and Beta. Binomial correlated bars pass
this gate because the Binomial correlated `sd()` bridge files exist; they are
still subject to the later route gates. This is a Julia R-side gate only; the
native engine is untouched.

## Tests

New file `tests/testthat/test-julia-ordinary-sd-fence-exemption.R`, static,
no Julia started. It checks, for all five families: intercept, independent
slope and constant-SD spellings pass the fence and reach Julia setup; bare bars
are still refused with the fence message; correlated bars with `sd()` stay
fenced outside Binomial and pass for Binomial; an `sd()` for a different group
does not exempt the bar; the helper is exact on groups and families; Gaussian
and fixed-effect Poisson are unaffected. An oracle comparison, structured
providers and emulated-bug sensitivity do not apply, because this slice
changes an admission gate and fits nothing. The refusal checks for neighbours
that stay closed are the bare, other-group and correlated cases above.

Counts, run on Totoro with 4 cores (89 passed, 0 failed, 0 skipped for the new
file): `test-julia-ordinary-mean-re-fence.R` 24 passed; `test-julia-gate-vs-engine.R`
166 passed; `test-julia-poisson-sd.R` 0 passed, 3 skipped; `-gamma-sd.R` 3
passed, 5 skipped; `-negbinomial-sd.R` 6 passed, 2 skipped; `-beta-sd.R` 6
passed, 2 skipped; `-binomial-sd.R` 44 passed, 5 skipped. No test was
loosened or deleted and none needed swapping.

## Live Julia check (Mac, Julia 1.10.0, DRM_JL_PATH = general-sd-julia)

`devtools::test(filter = "julia-poisson-sd")`: the phylogenetic test passed.
The other two Poisson tests (selected-coefficient SD formulas
`sd(id, coef = "(Intercept)")` and `sd(id, coef = "x")`) now get past the
fence but fail at the coefficient-label echo: "no payload label was built for
fixed-effect dpar(s): sd". The R side keys an explicit selector by a hashed
`sdtarget_...` block (b87566680) while this Julia checkout returns the plain
`sd` block. This is a separate R and Julia label-contract mismatch, not the
fence, and it is not fixed here.

A scratch live probe (not committed) with the unselected spelling
`sd(id) ~ z`, 30 groups of 12, fitted live with finite log-likelihoods for
Poisson (-610.3), Gamma (-458.5), NB2 (-661.5), Beta (290.5) and Binomial
(-644.2), each with an ordinary `(1 | id)`. The selected-coefficient Poisson
spelling failed as above. These are single fits that run, with no accuracy,
calibration or parity claim.

## Receipts that predate the fence (2026-10-25)

Julia ordinary-route receipts dated before the fence, to be re-run at HEAD
before they are cited: 2026-10-18 poisson-julia-slope-bridge, julia-beta-sd-bridge
and julia-selected-sd-bridge; 2026-10-19 bernoulli-sd-julia-bridge; 2026-10-20
general-sd-julia-poisson-smoke, julia-gamma-sd-smoke and the
julia-binomial-sd rerun series (current-source, source-bound v2 to v4).

## Not covered

No native change. No Julia coverage for selected-coefficient SD on these
families (the label mismatch above). No live run for the slope spelling of
Gamma, NB2, Beta or Binomial, nor for constant-SD `sd(g) ~ 1`. No claim about
correlated ordinary blocks for Poisson, NB2, Gamma or Beta, which stay refused.
