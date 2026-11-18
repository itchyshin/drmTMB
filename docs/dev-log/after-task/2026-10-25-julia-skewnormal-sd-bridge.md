# After Task: SkewNormal SD regression through the Julia bridge

## Goal

Admit one narrow SkewNormal random-effect SD route through the R-to-Julia
bridge and verify it on the same synthetic data as native TMB.

## Implemented

The bridge now admits one complete-response ordinary `mu` intercept or one
independent numeric `mu` slope with a matching `sd()` formula, provided
`sigma ~ 1` and `nu ~ 1`. Correlated slopes, structured terms, mismatched SD
targets, predictor-dependent `sigma` or `nu`, and random terms inside the SD
formula remain fenced. The payload labels this route with DRM.jl's observed
`sd` coefficient block.

## Mathematical Contract

For the tested slope, the latent effect is

```text
b_g ~ Normal(0, tau_g^2),  log(tau_g) = alpha_0 + alpha_1 w_g,
mu_ig = beta_0 + beta_1 x_ig + b_g x_ig.
```

The response is SkewNormal with fixed residual SD and fixed slant. The bridge
uses the same public moment parameters as native TMB. TMB integrates random
effects with a Laplace approximation; Julia uses adaptive quadrature.

## Files Changed

- `R/julia-bridge.R`: exact route admission and `sd` payload-label mapping.
- `R/julia-family-registry.R`: clarify the family-level fence and narrow SD
  exception.
- `tests/testthat/test-julia-skewnormal-sd-bridge.R`: route refusals and a
  same-data TMB/Julia slope fixture.
- `NEWS.md`, `docs/design/02-family-registry.md`,
  `docs/design/37-worked-example-inventory.md`,
  `docs/design/41-phase-18-simulation-programme.md`,
  `docs/design/149-missing-data-design.md`,
  `docs/dev-log/general-sd-regression/inventory.md`,
  `docs/dev-log/internal-roadmap.md`, and
  `docs/dev-log/known-limitations.md`: align current capability and limitation
  claims.
- `vignettes/julia-engine.Rmd` and
  `vignettes/predictor-dependent-random-sd.Rmd`: document the formula and its
  evidence boundary.
- `LOOP/lanes/general-sd-regression/arcs.md` and `checkpoint.md`: record
  progress without closing the wider programme.

## Checks Run

The final command used the paired candidate checkout and the local Julia 1.10
runtime:

```sh
TMPDIR=/private/tmp DRMTMB_JULIA_TESTS=true NOT_CRAN=true \
DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia" \
DRM_JL_JULIA_HOME="/Users/z3437171/.juliaup/bin" \
JULIA_DEPOT_PATH="/private/tmp/julia-depot:/Users/z3437171/.julia" \
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 JULIA_NUM_THREADS=4 \
Rscript -e 'devtools::test(filter = "skew-normal-sd-regression|julia-skewnormal-sd-bridge", reporter = "summary", stop_on_failure = TRUE)'
```

Result: exit status 0. The Julia bridge test ran live, and the focused suite
passed 36 expectations across the new route/refusal checks, the same-data TMB
and Julia fits, and the existing native SkewNormal SD regression test. The
new test checks convergence, positive SD-trend recovery, coefficient target
names, group SD predictions, and rowwise prediction mapping.

`pkgdown::check_pkgdown()` reported no problems; Pandoc emitted existing
`--mathml` deprecation warnings. Targeted `git diff --check` passed. The
after-task report, NEWS, Julia-engine guide, direct-SD guide, family design,
and limitations prose checks each ended with `FINDINGS: 0`. The full site and
article examples were not rendered in this slice.

## Tests Of The Tests

Before the implementation, the route test failed because the family fence
rejected the exact matching slope. After route admission, the live Julia fit
exposed a second failure: the payload did not label the returned `sd` block.
The final test passes after mapping the exact SkewNormal route to that block.
The test also refuses a correlated slope, a random `nu` predictor, a wrong
group target, and a wrong coefficient target.

## Consistency Audit

The focused Julia-engine guide, general SD vignette, family registry, formula
support notes, implementation inventory, and limitations now describe the
same narrow route. Response masking remains a separate fixed-effect-only
SkewNormal evidence row. Historical NEWS and dated planning records were left
as records of the states they described at the time.

Searches included:

```sh
rg -n -i 'skew.?normal.{0,120}(random|fixed.effect.only|not available|not yet implemented|remain planned|out)' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/02-family-registry.md docs/design/06-distribution-roadmap.md docs/design/37-worked-example-inventory.md docs/design/41-phase-18-simulation-programme.md docs/design/149-missing-data-design.md vignettes/formula-grammar.Rmd vignettes/julia-engine.Rmd vignettes/model-map.Rmd vignettes/predictor-dependent-random-sd.Rmd
rg -n 'Random-effect scale formulae are implemented|Skew-normal.*fixed-effect only|skew-normal random effects' docs/dev-log/known-limitations.md docs/design/37-worked-example-inventory.md docs/design/41-phase-18-simulation-programme.md docs/design/149-missing-data-design.md
```

## GitHub Issue Maintenance

`gh issue list --repo itchyshin/drmTMB --state open --search 'SkewNormal SD Julia bridge' --json number,title,url --limit 10`
returned no open matching issues. No issue was opened, closed, or changed.

## What Did Not Go Smoothly

The first live run without `DRM_JL_PATH` skipped Julia, so it did not exercise
the engine. With the paired checkout configured, the first live fit found the
missing `sd` label. A later JuliaCall run also needed `TMPDIR=/private/tmp` to
avoid a temporary-file creation error. The shared lane-lease registry was
locked, so ownership was checked directly; the matching older leases were
expired and no live lease covered the edited paths. No unrelated source files
were changed.

## Team Learning

An admission guard test alone did not reveal the output-block naming mismatch.
For each new family bridge exception, retain one live fit in addition to
route-unit tests so payload labels and public extraction are exercised.

## Known Limitations

Evidence covers one seeded independent-slope fixture with point-recovery and
output checks. Interval calibration, broad numerical parity,
profile/bootstrap workflows, structured effects, correlated blocks, and the
wider SkewNormal intercept and slope domain remain untested. The paired Julia
tree is a dirty development candidate; this does not establish release
support. The wider all-family, all-effect, two-engine SD-regression goal
remains open.

## Next Actions

Continue with the next unimplemented required family/effect/backend row after
checking the live ownership ledger and both worktrees. Keep calibration
deferred as approved and retain the exact row-level limitation in the
capability inventory.
