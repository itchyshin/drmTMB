# After Task: FX3b shared three-valued `convergence_status`

## Goal

Shinichi chose this at 5:21 PM MT on 16 October 2026. The reader is
the next reviewer of the twin honesty layer (Gauss / Emmy / Rose).
Give drmTMB and DRModels.jl one shared `convergence_status` with
values `converged`, `boundary`, and `degenerate`. Keep
`is_converged()` and `converged()` as the same boolean, defined as
`status == "converged"`. Put identical numeric predicates in both
engines, in the PR body, and in
`docs/design/278-twin-convergence-status.md`. Show the status in
print, summary, and `check_drm()`. On the Julia side, also keep FX3's
all-zero Poisson / NB2 cone guard. Rescore the 750-fit t4 grid from
`sweep-oct16/t4` and list remaining disagreements.

## Implemented

Both engines now classify a fit in this order: optimiser gate and
sentinel log-likelihood `-1e15`; geometry screen (R: binomial /
Poisson / NB2 / unbounded location-scale; Julia: the same Poisson/NB2
cone plus the existing Gaussian all-sigma collapse); positive-definite
finite `vcov`; finite SEs; inflated SE (`SE >= 50` and
`SE >= 1000 ×` the median of SEs `< 50`, with a min-SE fallback);
design rank at tolerance `1e-8`; then `|rho12| > 0.98` or random-effect
SD `< 1e-4` as `"boundary"`; otherwise `"converged"`.

`is_converged(fit)` and `converged(fit)` are `TRUE` only for
`"converged"`. On FX3 a mutated RE-SD of `1e-8` still returned
`is_converged() = TRUE`; after this change it returns `FALSE` with
`convergence_status() = "boundary"`. Print, `summary()`, and
`check_drm()` show the three-valued status (`ok` / `note` /
`warning` in R).

DRModels.jl also applies `_count_mle_existence_guard` on fixed-effect
Poisson and NB2 (Haberman 1974; Santos Silva and Tenreyro 2010), so
an all-zero Poisson fit warns, stores `Inf` SEs, and reads
`:degenerate`.

## Mathematical Contract

The cuts are bitwise the same in `R/check.R` and
`src/convergence_status.jl`:

```
rank_tol              = 1e-8
inflated_se_floor     = 50
inflated_se_ratio     = 1000
re_sd_boundary        = 1e-4
rho12_boundary        = 0.98
sentinel_loglik       = -1e15
```

Shape-at-limit cases (NB2 Poisson limit, Student `ν → ∞`) stay
`"degenerate"` via the inflated-SE / Hessian screens, not a new
boundary class (#1535 remains a follow-up).

## Files Changed

drmTMB, branch `cursor/fx3b-convergence-status-1f29` from FX3 head
`28ceb1f98`:

- `R/check.R`, `R/methods.R`, `R/julia-bridge.R`, `R/julia-diagnostics.R`
- `tests/testthat/test-convergence-status-twin.R` (new)
- `docs/design/278-twin-convergence-status.md` (new)
- `docs/design/174-controls-and-convergence.md`, `NEWS.md`,
  `docs/dev-log/known-limitations.md`, this note, the t4 evidence files
- `man/is_converged.Rd`, `man/convergence_status.Rd`,
  `man/check_drm.Rd`, `man/summary.drmTMB.Rd`, `NAMESPACE`

`R/drmTMB.R`, `R/mi-weights.R`, and `src/` were not edited. `R/methods.R`
changed, so C17 was recertified.

DRModels.jl, same branch name from pin `f71b292`:

- `src/convergence_status.jl` (new)
- `src/separation.jl`, `src/poisson.jl`, `src/negbinomial.jl`
- `src/summary.jl`, `src/gaussian_core.jl`, `src/inference.jl`,
  `src/DRModels.jl`, `src/temporal.jl`, `src/introspection.jl`
- `test/test_convergence_status.jl`, `test/test_poisson_mle_existence.jl`
- `news/1109-fx3b-convergence-status.md`

## Checks Run

Red-proof: FX3 semantics on a mutated RE-SD of `1e-8` give
`is_converged = TRUE`; after this change `FALSE` /
`status = "boundary"`. `test-convergence-status-twin.R` 32 pass;
`test-mle-existence.R` 39 pass; `test-check-drm.R` 263 pass / 1 skip;
`test-fit-convergence-warning.R` 16 pass.

Julia 1.11.6: `test_convergence_status.jl` 28 pass (constants, Gaussian
print/`check_drm`, all-zero Poisson #1109 red-proof, ordinary Poisson);
`test_poisson_mle_existence.jl` 5 pass; `test_check_drm.jl` 82 pass;
`test_binomial_separation.jl` 86 pass; `test_j2_convergence_vcov.jl`
including #949 9 pass; `test_api_stability.jl` 198 pass.

t4 rescore (750/750 both engines, no timeouts): boolean
`is_converged` agreement **716/750** (pin: 512/750). Three-valued
status agreement **689/750**. Evidence:
`docs/dev-log/evidence/2026-10-16-fx3b-t4-rescore.md`.

C17 recertified because `R/methods.R` changed (print/summary show
the status).

## Tests Of The Tests

The red-proof mutates `sdpars$mu[[1]]` to `1e-8` on an interior
random-intercept Gaussian (`n = 200`, 8 groups of 25, group SD 0.8).
On FX3 that fit still has `is_converged() = TRUE`. Constants tests
assert the six shared cuts and the inflated-SE min-SE fallback. The
#1109 Julia file uses the published all-zero and extreme-x Poisson
designs plus an ordinary Poisson control.

## Consistency Audit

Patterns run:

```sh
rg "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" .
rg "is_converged|convergence_status|inflated_se|re_sd_boundary" R docs NEWS.md
rg "full.*rejected|block.*rejected|only diagonal|planned.*implemented" README.md docs/dev-log/internal-roadmap.md NEWS.md docs vignettes
```

`NEWS.md`, `docs/design/174-controls-and-convergence.md`,
`docs/design/278-twin-convergence-status.md`,
`docs/dev-log/known-limitations.md`, `?is_converged`, and
`?convergence_status` name the same three values and the same cuts.
`_pkgdown.yml` already listed `is_converged` and `convergence_status`;
`converged()` is the alias on the same page.

## GitHub Issue Maintenance

Draft PR says `Refs #1554 #1333 #731 #1109` and does not say Closes
or Fixes. Stacked on FX3 #1564. No new issues opened.

## What Did Not Go Smoothly

The first red-proof used `n = 40` with 10 groups of 4; that fit
already had RE SD `≈ 9e-6`, so it was `"boundary"` before mutation.
`cli` print capture needs `type = "message"`. Julia `check_drm`
NamedTuple gained `convergence_status` as the first field; the
partial-vcov fixture is now `:degenerate` rather than a true
`is_converged`. GitHub 403 on DRModels.jl is handled as a patch
when it occurs.

## Team Learning

A shared three-valued status can raise twin-flag agreement without
forcing the engines to share an optimiser. The remaining t4 splits
are `g_tol` / pseudo-inverse SEs, not the predicate table.

## Known Limitations

Random-effect, phylogenetic, `mi()`, MSPL, and zero-inflated Poisson
routes are still unscreened by the geometry cone. Coefficients and
`vcov()` stay at the optimiser stop. Shape-at-limit reporting is
still `"degenerate"` via inflated SE (#1535). 61/750 t4 status
disagreements remain, listed in the evidence CSV.

## Next Actions

Reviewers should not merge this with #1442 / #1509 without checking
the duplicated cone. #1535 is the shape-boundary follow-up. Julia
`g_tol` vs R `nlminb` on `re_sd1e-4` is DRModels.jl #983.
