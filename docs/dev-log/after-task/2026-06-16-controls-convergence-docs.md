# After Task: Controls + convergence documentation (Phase 6 docs slice)

## Goal

Record, durably and team-visibly, (a) the **generalization-via-controls
principle** the maintainer asked for — features added for one dataset ship as
general controls with generic defaults, never dataset-specific tuning — and
(b) the **convergence and control guidance** for users, including the new
penalized/MAP estimator and the interval-method findings. Driven by the one-
dataset (Ayumi) location-scale work; this slice leaves the general record behind.

## Implemented (docs only; no package R/src change)

- `docs/design/174-controls-and-convergence.md` (new): the durable design
  record — the generalization principle, the control catalog (`optimizer_preset`,
  `penalty`/`drm_phylo_penalty`, the `log(sigma)` clamp, `se`, `missing`, `REML`),
  the convergence diagnostics, and the interval-method guidance with the
  data-vs-prior `cor_sd` rule. States plainly that `cor_sd` has no universal
  value (sweep it; never a default) and that the Ayumi data is a validation case,
  not a special case in the code.
- `vignettes/convergence.Rmd`: new user-facing section "Penalized / MAP
  estimation for weakly-identified phylogenetic components" — when to use the
  penalty, the `drm_phylo_penalty()` call, the MAP/honesty contract (label,
  unpenalized `logLik`, LRT/AIC caveat), the mandatory prior-sensitivity sweep,
  and that it complements (not replaces) simplification / replication / a
  Bayesian fit. New chunks are `eval = FALSE` / `purl = FALSE` (illustrative).
- `NEWS.md`: a bullet for the penalty/MAP estimator (catching up #581) + the
  article and doc-174 additions.

## Interval-method findings recorded (from a penalized n=300 coupled-q4 fit)

- **Wald** (`pdHess = TRUE`): instant, finite SD/correlation intervals.
- **Profile**: works but requires explicit target names (`parm = "sd:mu:..."`);
  calling it with no target errors by design.
- **Parametric bootstrap**: works on a PD fit but slow (~17 min at n=300;
  returned intervals for all 12 targets). It fails (0 refits) only on the
  non-PD flat ridge (Guedon et al. 2024). So restoring a PD fit via the penalty
  also restores bootstrap as an option.

## Checks

- `convergence.Rmd` rendered to confirm the article builds (new chunks are
  `eval = FALSE`, so they are parsed but not executed; the existing fitted-figure
  chunks still run).
- No package `R/` / `src/` code changed; the merged CI-green state carries.

## Honesty / scope

The penalty makes a model fittable, not identified; the docs say so. `cor_sd`
is data-specific (sweep it). The clean route to a fully identified coupled model
is within-group replication. The `log(sigma)` clamp is documented as a fixed
numerical guard with a user-configurable band still planned (Phase 4).

## Team

documentation_writer + pkgdown_editor (the article), Rose (the generalization
principle + honesty language), Fisher (interval-method guidance), Gauss (control
catalog), Boole (control naming), Ada (gate). Built during the autonomous block;
outward-facing items (the Ayumi reply, the Julia coordination spec) remain held.
