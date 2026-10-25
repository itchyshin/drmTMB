# After Task: FX3 fail-closed MLE existence (t4 silent wrong answers)

## Goal

Sweep-oct16 lane t4 named three drmTMB cells that returned
`is_converged() = TRUE` with no warning while the maximum-likelihood
estimate did not exist: `gauss_n8` (6/50 unbounded location-scale),
`bin_complete` (50/50 complete separation), and `pois_n8_lowmean`
(13/50 all-zero or extreme-x Poisson). The same lane counted 238/750
R versus Julia `is_converged()` disagreements (#1554). The task was
to make those three cells warn, refuse, or set `converged = FALSE`,
and either share one twin convergence rule or report the methods
options.

The reader of this note is the next reviewer of the honesty layer
(Gauss / Emmy / Rose), not an applied first-fit user.

## Implemented

drmTMB now classifies three fixed-effect geometries as
`convergence_status() = "degenerate"`, so `is_converged()` is FALSE
and `check_drm()` adds a warning-level `mle_existence` row:

- binomial / Bernoulli (quasi-)complete separation (Albert and
  Anderson 1984; Konis 2007), using the Lawson–Hanson / Farkas cone
  already specified for #1442;
- Poisson / NB2 rays with no finite MLE (Haberman 1974; Santos Silva
  and Tenreyro 2010), the same cone with `s = 1{y > 0}` and
  `ntr = 1 + s`;
- unbounded continuous location-scale: a scale predictor drives an
  exactly fitted observation onto the lower `log(sigma)` clamp, the
  Pearson residual at that row is smaller than `1e-3` in absolute
  value, and `max(log_sigma) - min(log_sigma) > log(1e4)`.

Point estimates and `vcov()` are unchanged. Random-effect,
phylogenetic, `mi()` predictor, and MSPL routes are not screened.
Zero-inflated Poisson is not screened, because a zero can come from
the inflation process rather than the count cone.

DRModels.jl applies the same count cone on the Poisson and NB2
fixed-effect routes (#1109). It warns, names the coefficients, and
sets those standard errors to `Inf`. `is_converged` stays true,
which is the existing binomial policy on that package.

The 238/750 twin-flag contract (#1554) is not decided. The shared
work in this change is the geometry screen, not the boolean. #1554
already states the owner choice: (a) stationary point versus (b)
usable optimum, plus whether both twins should expose
`convergence_status()` and how each named case is classified.
Choosing either rule would reverse an existing per-case decision
(#1270 / #1333 versus Julia #731 / #1109). This task therefore
stops at the options rather than picking a boolean.

## Mathematical Contract

For a full-rank design \(X\), a binomial or Poisson log-link MLE
fails to exist iff some direction \(d \neq 0\) has \(x_i^\top d \ge 0\)
on every success row and \(x_i^\top d \le 0\) on every failure row,
with a strict inequality on at least one row (Albert and Anderson
1984; Konis 2007). Poisson uses successes \(s_i = 1\{y_i > 0\}\) and
trials \(n_i = 1 + s_i\), so a positive count contributes an equality
constraint (Haberman 1974; Santos Silva and Tenreyro 2010, *Econ.
Lett.* 107:310–312). The R call is still
`drmTMB(bf(y ~ x), family = poisson(), data = d)`; the screen does
not change the formula grammar. The continuous location-scale case
is the clamp-plus-exact-fit geometry already described for #1469:
the Gaussian (or sibling) log-density \(\to +\infty\) when an
exactly fitted row is driven to \(\sigma \to 0\).

## Files Changed

drmTMB, branch `cursor/fx3-silent-mle-b05e` from pin `ca3ddefa`:

- `R/mle-existence.R` (new)
- `R/check.R` (`convergence_status()`, `check_drm()`, roxygen)
- `tests/testthat/test-mle-existence.R` (new)
- `man/check_drm.Rd`, `man/convergence_status.Rd`
- `NEWS.md`, `docs/design/174-controls-and-convergence.md`,
  `docs/dev-log/check-log.md`, `docs/dev-log/known-limitations.md`,
  this after-task note

`R/drmTMB.R`, `R/methods.R`, `R/mi-weights.R`, and `src/` were not
edited, so C17 was not recertified.

DRModels.jl, same branch name from pin `f71b292`:

- `src/separation.jl` (`_count_mle_existence_guard`)
- `src/poisson.jl`, `src/negbinomial.jl`
- `test/test_poisson_mle_existence.jl` (auto-discovered)
- `NEWS.md`, `news/1109-poisson-mle-existence.md`

## Checks Run

Recorded in `docs/dev-log/check-log.md` and updated after the
closeout suite in this session. Targeted red-proof and sibling
files are `test-mle-existence.R`, `test-check-drm.R`,
`test-fit-convergence-warning.R`, `test-binomial-response.R`,
`test-poisson-mean.R`, `test-gaussian-location-scale.R`, and
`test-nbinom2-location-scale.R`. Julia 1.11.6 was installed for this
closeout. `test/test_poisson_mle_existence.jl` passed 17/17 after the
guard; on the pin the all-zero Poisson fit was `is_converged=true`
with SE ≈ 2.62e7 and `check_drm.ok=true`. Sibling
`test_binomial_separation.jl` passed 86/86. The full Julia package
suite was not run.

## Tests Of The Tests

The new drmTMB file failed on the installed pin `ca3ddefa`
(`bin_complete` r01, `pois_n8_lowmean` r03, and `gauss_n8` r06 all
returned `is_converged() = TRUE`) and passed after
`pkgload::load_all()`. The cone unit test covers complete
separation, quasi-complete separation, overlapping Bernoulli,
all-zero Poisson, extreme-x Poisson, and ordinary Poisson overlap.
Sibling paths include overlapping binomial, ordinary Poisson n = 20,
NB2 all-zero, healthy Gaussian location-scale, and the continuous
sibling family list. The Julia file uses the published #1109 r03
and r27 designs plus an ordinary Poisson control.

## Consistency Audit

Patterns run:

```sh
rg "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" .
rg "is_converged|mle_existence|binomial_separation|count_mle_nonexistent" R docs NEWS.md
rg "full.*rejected|block.*rejected|only diagonal|planned.*implemented" README.md docs/dev-log/internal-roadmap.md NEWS.md docs vignettes
```

`NEWS.md`, `docs/design/174-controls-and-convergence.md`,
`docs/dev-log/known-limitations.md`, and `?convergence_status` now
name the same three geometries. `internal-roadmap.md` and
`_pkgdown.yml` were left unchanged: this is a diagnostic honesty
layer, not a new family or grammar. Formula-grammar docs were not
edited.

## GitHub Issue Maintenance

Draft PRs say `Refs #1553`, `Refs #1270`, `Refs #1469` on drmTMB and
`Refs #1109` on DRModels.jl. They mention #1554 as an open methods
choice and do not say Closes or Fixes. Existing dirty PRs #1442
(binomial screen) and #1509 (unbounded scale) were not rebased.
No new issues were opened.

## What Did Not Go Smoothly

The environment had no R toolchain at first and no Julia binary at
all. The honesty layer was written against the published t4 seeds
and the #1553 / #1109 inline designs rather than by re-running the
750-cell grid. Applying drmTMB's degenerate boolean to Julia, or
Julia's optimiser-gate boolean to drmTMB, would raise twin-flag
agreement on the grid but would reverse an existing per-case
decision; that is why this task reports #1554 instead of flipping
`is_converged` in both packages.

## Team Learning

A geometry screen can be shared while the boolean stays an owner
choice. The t4 pass bar asked for both “never `converged=TRUE` with
a silent wrong answer” and “R and Julia agree on the flag”; those
two sentences conflict until #1554 is decided. Future sweep lanes
should treat flag-meaning disagreements as a methods issue, not as
a silent-fit bug.

## Known Limitations

Random-effect, phylogenetic, `mi()`, MSPL, and zero-inflated
Poisson routes are unscreened. Coefficients and `vcov()` stay at
the optimiser stop. Julia still reports `is_converged = true` on
the same Poisson geometries. The 238/750 twin-flag census is
unchanged except that drmTMB will now flag the three silent t4
cells as degenerate.

## Next Actions

Owner decision on #1554 (a versus b, shared `convergence_status()`,
case table, numeric predicates). After that decision, a second
small PR can align the boolean and `engine = "julia"`. Reviewers
should not merge this honesty layer with #1442 / #1509 without
checking the duplicated cone.
