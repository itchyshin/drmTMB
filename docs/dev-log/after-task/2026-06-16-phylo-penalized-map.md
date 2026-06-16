# After Task: Penalized / MAP phylogenetic estimator (Phase 3, slice 1)

## Goal

Add an optional penalized / maximum-a-posteriori (MAP) estimator so a
weakly-identified phylogenetic component (the scale-side phylogenetic field at
about one observation per tip) can return a finite, regularised, honestly
labeled estimate instead of diverging under plain maximum likelihood. This is
the frequentist analog of what a preregistered Bayesian fit does; it
**complements** that workflow, it does not replace it.

## Why (the corrected framing)

The scale-side phylogenetic field is **weakly identified, not non-identified**
at ~1 obs/tip (de Villemereuil & Nakagawa 2014; Nakagawa et al. 2025). The
published Bayesian fits return a bounded but prior-sensitive estimate because the
prior regularises the weak direction; frequentist ML has no prior and sits on a
near-flat ridge. A documented prior/penalty closes that gap.

## Implemented

- `R/penalty.R` (new): `drm_phylo_penalty(sd_u, sd_alpha, cor_sd)` (exported)
  builds a PC-prior penalty spec (Simpson et al. 2017; rate
  `lambda = -log(sd_alpha)/sd_u`). `drm_parse_phylo_penalty()` validates it.
  `drm_apply_phylo_penalty_spec()` attaches the DATA fields to every
  `spec$tmb_data` (so TMB always sees them and plain ML stays bit-identical),
  records `estimator = "MAP"` and the penalty when penalizing, and aborts when
  there is no `phylo()` term or a direct `sd_phylo()` formula is in use.
- `R/drmTMB.R`: new `penalty = NULL` argument; parsed; applied after the
  estimator spec; `engine = "julia"` rejects it. The fit records
  `logLik = -opt$objective + phylo_penalty` (the unpenalized data
  log-likelihood), plus `penalty` and `phylo_penalty`.
- `src/drmTMB.cpp`: `drm_phylo_penalty_value()` helper and a guarded
  `if (penalize_phylo == 1)` block at the univariate and bivariate phylo NLL
  sites. The penalty is added to the objective and `REPORT`ed.
- `R/methods.R`: `print()` shows a penalty line (estimator already shows `MAP`).
- `R/check.R`: a `penalized_map` note row.

## Mathematical contract

Per penalized SD endpoint `sd_k = exp(log_sd_phylo(k))`, the negative log-prior
added (with the log-scale Jacobian) is `lambda*sd_k - log_sd_phylo(k) -
log(lambda)`. An optional `N(0, cor_sd)` penalises the live correlation
parameter (`eta_cor_phylo` for `q == 2`, each `theta_phylo` for `q > 2`). The
total is `REPORT`ed as `phylo_penalty`. A unit test checks the reported penalty
equals this analytic value at the optimum.

## Honesty contract

- Plain ML is the default and bit-identical when `penalty = NULL`
  (`penalize_phylo = 0` adds nothing; the full suite is the bit-identity guard).
- A penalized fit is labeled `MAP`; `logLik()` returns the unpenalized data
  log-likelihood (penalty stored separately); `check_drm()` notes that LRT/AIC
  across penalized fits are not standard.
- The penalty regularises a weak component; it does not manufacture
  identifiability. A prior-sensitivity analysis is required before
  interpretation.

## Files Changed

- `R/penalty.R` (new), `R/drmTMB.R`, `R/methods.R`, `R/check.R`,
  `src/drmTMB.cpp`, `NAMESPACE` + `man/drm_phylo_penalty.Rd` (generated),
  `tests/testthat/test-phylo-penalized-map.R` (new),
  `docs/design/172-phylo-penalized-map.md`, this note, `check-log.md`.

## Checks Run

```sh
Rscript -e "devtools::document()"
Rscript -e "devtools::test(filter = 'phylo-penalized-map', reporter = 'summary')"
Rscript -e "devtools::test(reporter = 'summary')"   # full suite, bit-identity guard
git diff --check
```

Results:

- `phylo-penalized-map`: all assertions pass. The C++ penalty helper compiled
  cleanly. Confirmed: (1) `drm_phylo_penalty()` validates inputs and computes
  the PC-prior rate; (2) `penalty = NULL` returns `estimator = "ML"` with
  `phylo_penalty = 0` (no `phylo_penalty` REPORTed); (3) a penalty shrinks the
  phylogenetic location SD relative to ML, labels the fit `MAP`, keeps
  `logLik()` as the unpenalized data log-likelihood, and the REPORTed penalty
  equals the analytic PC-prior value `sum(lambda*exp(log_sd) - log_sd -
  log(lambda))` at the optimum.
- Full suite: 0 failures (bit-identity guard for `penalty = NULL`; no existing
  phylo/biv/check tests regressed). One pre-existing Julia-bridge stacktrace may
  print without failing its test; it is unrelated to this native-TMB slice.
- `devtools::document()`: regenerated `NAMESPACE`, `man/drm_phylo_penalty.Rd`,
  and `man/drmTMB.Rd` (new `penalty` argument). The pre-existing
  `man/rho_latent.Rd` drift was reverted as out of scope.
- `git diff --check`: clean.

## Tests Of The Tests

Each behavioural assertion was written first and watched fail (the constructor
was absent; the `penalty` argument was unknown) before the implementation
existed. The penalty-value assertion checks the engine against the closed-form
PC-prior negative log-prior (with the log-scale Jacobian), so a sign or Jacobian
error in the C++ would fail the test rather than pass silently.

## Scope / Deferred

- The SD penalty applies to all phylo SD endpoints with the same PC prior;
  per-endpoint targeting (scale-only in a q4 model) is deferred.
- The MAP calibration simulation (prior-domination vs data-domination;
  sensitivity sweep) is the Phase 5 companion lane.
- The DRM.jl counterpart is coordinated with the twin team (R-only here).

## Team Perspective

Gauss owns the TMB penalty and the DATA switch; Noether checks the Jacobian and
that the reported penalty recovers the unpenalized logLik; Fisher holds the
inference guard (MAP label, unpenalized `logLik()`, the LRT/AIC caveat); Boole
owns the `penalty`/`drm_phylo_penalty()` API surface; Emmy the fitted-object and
print labeling; Rose the honesty/scope language; Ada gates. No subagents are
running.

## References

- Simpson et al. 2017, *Statistical Science* (PC priors).
- Chung et al. 2013, *Psychometrika* (nondegenerate penalized variance estimation).
- de Villemereuil & Nakagawa 2014; Nakagawa et al. 2025, *MEE* (PLSM).
