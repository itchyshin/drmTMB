# After Task: private general latent-normal association sandwich engine

## 1. Goal

Build a reusable private stacked-score/Godambe diagnostic for all five admitted
fixed-effect, ML, complete-pair latent-normal association classes, without
creating public inference or beginning any validation campaign.

## 2. Implemented

`drm_pair_sandwich_assemble()` now constructs the shared two-margin bread,
uncentred paired-row meat, alpha covariance, and eta delta calculation.
`drm_pair_general_eta_sandwich()` is an unexported router for explicit
Gaussian × Bernoulli, Gaussian × ordinary-NB2, Bernoulli × Bernoulli,
Bernoulli × ordinary-NB2, and ordinary-NB2 × ordinary-NB2 adapters. The
Bernoulli × ordinary-NB2 reference calculation is regression-tested through
the refactor; no public association object is modified.

## 3. Mathematical Contract

The implementation follows design 244: theta is `(psi_1, psi_2, alpha)`, not
eta; the bread is lower block triangular; the meat retains every uncentred
paired-row score cross-product; and eta uncertainty is a post-hoc delta map
from the alpha block. Mixed pairs use canonical family-role order; repeated
pairs retain literal `L = fit_1`, `R = fit_2` order.

## 4. Files Changed

- `R/associate-pairs-sandwich.R` and four pair-specific private adapter files
- focused staged-sandwich, pair-adapter, and router tests
- designs 240 and 244, the ultra-plan, and `docs/dev-log/check-log.md`
- this report and the companion plan-versus-actual receipt

## 5. Checks Run

Focused deterministic suites passed under
`R_PROFILE_USER=/dev/null Rscript --no-init-file`:

- existing Bernoulli × ordinary-NB2 and staged-sandwich tests (69 and 41
  expectations after the provenance additions);
- each new Gaussian × Bernoulli, Gaussian × ordinary-NB2, Bernoulli ×
  Bernoulli, ordinary-NB2 × ordinary-NB2, and router test file;
- the combined five-class focused matrix.

`git diff --check` passed. A full-package test was deliberately not launched:
this approval authorizes deterministic private-engine checks, while the broad
suite includes unrelated simulation-bearing work outside this phase.

## 6. Tests of the Tests

Each adapter checks analytic marginal scores/bread against numerical
derivatives, and its association row kernel against an independent normal
integral or rectangle oracle. The matrix also checks negative/zero/positive
eta, zero factorization, response swaps, repeated-side permutations,
tail/scale behaviour, frozen snapshots, malformed or unresolved objects,
boundaries, step instability, forced bread-rank refusal, no public
`vcov()`/`confint()`, and the real private router path.

## 7. Consistency Audit

The status-inventory scan covered `README.md`, `ROADMAP.md`, `NEWS.md`,
`docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`,
`vignettes/formula-grammar.Rmd`, `_pkgdown.yml`, `docs`, `R`, and `tests` with
the task-specific patterns `staged.*sandwich|sandwich.*staged|Godambe|general.*association|public.*inference`.
No public documentation or pkgdown navigation changed. Design 240 now says the
private diagnostic exists, and design 244 remains the implementation contract.

## 8. GitHub Issue Maintenance

`gh issue list --repo itchyshin/drmTMB --state open --search "staged eta
sandwich association" --limit 30` returned no matching open issue. No issue
was opened or changed because this is a private engineering/freeze lane.

## 9. What Did Not Go Smoothly

The first freeze review found that the refactored Bernoulli × ordinary-NB2
reference had preserved numerical output but not the full snapshot/provenance
contract. It now checks rows, hashes, original rows, snapshots, roles, response
names, and regenerated association design before numerical work. The review
also found that the first failure matrix concentrated derivative/rank checks in
the reference adapter; those checks now exist for every adapter.

## 10. Team Learning

Shared numerical assembly must not make provenance or failure testing
implicitly shared. Every adapter needs its own frozen-input gate and actual
router test, even when it reuses the same bread/meat service.

## 11. Known Limitations

This is not validated inference. It has no public SE, `vcov()`, Wald/profile/
`confint()` interface, full-refit comparison, bootstrap, recovery,
calibration, coverage, random effects, missingness, weights, offsets, REML,
or direct `biv_lognormal()` rho12 claim. No Totoro/DRAC or other compute ran;
no capability ledger tier changed.

## 12. Next Actions

Freeze the exact source, fixtures, tolerance ladder, labels, and failure
taxonomy after final Noether/Fisher/Rose sign-off. Any full-refit comparison,
simulation, compute, or public inference proposal requires fresh owner
approval and a separate bounded plan.
