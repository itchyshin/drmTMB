# PROJECT STATE: drmTMB + DRM.jl Handover

Last updated: 2026-06-15 MDT

Audience: Claude Code and Codex agents taking over `drmTMB` / `DRM.jl`
finish work. This is an operational handover, not a release note.

## Start Here

Read these first, in this order:

1. `AGENTS.md`
2. `docs/dev-log/codex-handover-2026-06-14-ayumi-arc-closeout.md`
3. `docs/design/168-r-julia-finish-capability-matrix.md`
4. `docs/dev-log/dashboard/README.md`
5. This file.

The governing rule from the finish plan still stands: a capability is not
done unless engine support, R bridge support, point estimates, CI/status,
tests, docs/articles, visuals, issue evidence, and Rose audit all agree.

## Mission-Control Widget

Local dashboard:

```text
http://127.0.0.1:8765/
```

Source files:

```text
docs/dev-log/dashboard/index.html
docs/dev-log/dashboard/status.json
docs/dev-log/dashboard/sweep.json
docs/dev-log/dashboard/version.txt
```

Served copy:

```text
/tmp/drm-dashboard
```

Refresh command:

```sh
sh tools/start-mission-control.sh --background
```

Validation just before this handover:

```text
mission_control_ok: 18/68 banked_or_verified, 3 active, 16 matrix rows
dashboard already listening at http://127.0.0.1:8765/
version r4
```

If the in-app browser shows an old file URL or a blank page, reload
`http://127.0.0.1:8765/`. Do not edit `/tmp/drm-dashboard` directly; edit the
source files under `docs/dev-log/dashboard`, then restart the dashboard.

## Current GitHub State

Merged:

- `drmTMB#568` Track bootstrap refit diagnostics.
  Merged to `main` as `1c7ce77b11519610baab532febb2ee6a17273436`.

Open, current:

- `drmTMB#571` Track Ayumi beak and binomial follow-ups.
  Draft PR, clean, all R-CMD-check jobs green. This is the ledger/planning
  PR for Ayumi beak and Santi/binomial follow-ups.
- `drmTMB#572` Harden Gaussian sigma fixed-effect starts.
  Draft PR. It hardens starts but does not solve Ayumi's all-tip beak model.
  The first CI run found a macOS-only tolerance failure in a pre-existing
  bivariate likelihood-weight test; the branch was amended with a targeted
  tolerance fix and CI is rerunning.
- `drmTMB#555` Ayumi 10k q4 Gaussian REML speed and bridge-status harness.
  Open tracking issue.
- `drmTMB#569` Add Bernoulli/binomial response-family first slice.
  Open first-slice issue for Santi's question.
- `drmTMB#570` Rescue Ayumi beak sigma-phylo native optimizer/start failure.
  Open convergence issue.
- `DRM.jl#293` Investigate Ayumi q4 Julia ML `-Inf` point-fit ladder after
  100 tips. Open Julia-side issue.

Important older/open bridge stack:

- `drmTMB#544` is the bridge-gate-drift audit epic and remains high leverage.
- `gllvmTMB#488` is the sister bridge-gate-drift mirror.
- Older `shannon/*` bridge PRs are still open. Treat them as context and
  source material, not as a merge queue. Rebase and audit against the current
  capability matrix before promotion.

## Ayumi State

Ayumi provided a reproducible benchmark for a 10,440-tip bivariate Gaussian
location-scale phylogenetic model:

```r
form <- bf(
  mu1    = Tarsus_Length_z ~ 1 + temp + prec + temp:prec + log_mass_z +
             phylo(1 | p | phylo_id, tree = tree),
  mu2    = Beak_Length_Culmen_z ~ 1 + temp + prec + temp:prec + log_mass_z +
             phylo(1 | p | phylo_id, tree = tree),
  sigma1 = ~ 1 + temp + prec + temp:prec + log_mass_z +
             phylo(1 | p | phylo_id, tree = tree),
  sigma2 = ~ 1 + temp + prec + temp:prec + log_mass_z +
             phylo(1 | p | phylo_id, tree = tree),
  rho12  = ~ 1
)
```

Truth as of this handover:

- Her setup was not simply wrong.
- `engine = "tmb", REML = FALSE` can finish the bivariate q4 point fit quickly
  enough for some checks, but `pdHess = FALSE` makes Wald inference unsafe.
- Native `engine = "tmb"` is not a full REML fallback for the bivariate q4
  sigma-phylo cell. Do not tell Ayumi otherwise.
- Julia q4 point fits now have better small-subset evidence after DRM.jl
  fixes, but the 10k workflow remains too slow for the across-tree protocol.
- Full profile/bootstrap inference for the 10k bivariate q4 model remains
  open.

Posted user-facing reply:

- Ayumi reply was posted at
  `https://github.com/Ayumi-495/LS_ecogeographical-rules/issues/2#issuecomment-4713005283`.

Key local evidence artifacts:

```text
/tmp/drmtmb-ayumi-evidence/beak-pruned-size-ladder-20260615-164203/beak-pruned-size-ladder.csv
/tmp/drmtmb-ayumi-evidence/julia-point-ladder-drm-main-20260615-164757
/tmp/drmtmb-ayumi-evidence/beak-patched-sigma-start-20260615/patched-default.csv
```

Beak diagnostic summary:

- `no_phylo all`: convergence 0, elapsed about 41 s, logLik about 3692.30,
  `sigma` mass slope about 1.238, `sd_mu_phylo` about 0.469.
- `full all default`: convergence 1 / false convergence, elapsed about 102 s,
  logLik about -499921.4, sigma slopes stuck at 0, `sd_mu_phylo = 0.25`,
  `sd_sigma_phylo = 0.2`.
- `full all careful`: same bad basin as default.
- Patched sigma-start run in `#572`: sigma starts moved away from zero, but
  the full all-tip beak fit still returned false convergence with
  `logLik = -499839.4`, `sd_mu_phylo = 0.25`, and `sd_sigma_phylo = 0.2`.

Interpretation:

- The beak blocker is a native optimizer/start/basin problem for the full
  sigma-phylo model, not just a profile interval problem.
- `#572` is useful start hardening, not the Ayumi fix.
- The next `#570` slice should implement a candidate-start/selection ladder
  that rejects starting-like basins before any profile/bootstrap interval
  claim.

## Julia / DRM.jl State

Julia point-fit ladder evidence:

- DRM.jl main used at `9bdea6564661e1d9eb454ed3c6d2d9398522f74f`.
- `engine = "julia", REML = TRUE` returned through 1000 tips in the point-fit
  ladder: 30 = 10.41 s, 100 = 105.50 s, 250 = 67.58 s, 500 = 134.48 s,
  1000 = 274.02 s.
- `engine = "julia", REML = FALSE` worked at 30 and 100, then returned
  `convergence = 1` and `logLik = -Inf` quickly at 250, 500, and 1000.
  This is now tracked as `DRM.jl#293`.

Do not claim AI-REML is implemented for this q4 path. The correct boundary is:

- REML is for Gaussian models.
- AI-REML is a future candidate only for exact Gaussian LMM/MME-style cells.
- Laplace/non-Gaussian DRM paths need observed-information Newton,
  Fisher/natural-gradient, exact AD/implicit gradients, Takahashi/selected
  inverse, or other derived methods. Do not borrow the HSquared terminology
  without checking the estimand and likelihood.

## Santi / Binomial State

Santi asked whether flycatcher onset data should use brms, drmTMB, or both,
and whether binomial models are planned.

Current truth:

- `beta_binomial()` is implemented and exported for two-column
  `cbind(successes, failures)` responses with `mu` and `sigma`.
- Missing-predictor imputation accepts `stats::binomial(link = "logit")` as a
  binary missing-predictor model; that is not the same as a primary binomial
  response family for `drmTMB()`.
- Plain Bernoulli/binomial primary response models are not yet implemented as
  first-class response families. They are planned in `drmTMB#569`.

Suggested honest reply to Santi:

> For the onset project, use brms as the stable analysis path now. drmTMB can be
> used for package-side checks or prototypes, especially if the model maps to
> existing Gaussian, Poisson, NB2, beta, zero-one beta, or beta-binomial cells.
> Plain Bernoulli/binomial response models are planned but not yet a finished
> drmTMB response family. `beta_binomial()` is already available when the data
> are successes out of known trials and overdispersion is scientifically
> expected.

## Current Finish Strategy

The plan was amended during the Ayumi/Santi work:

1. Keep the R-first strategy. Make native `drmTMB` useful, honest, and
   diagnosable now.
2. Continue Julia/DRM.jl acceleration as the real q4 large-tree lane, but do
   not block R-side diagnostics on Julia speed.
3. Do not present `pdHess = FALSE` as total fit failure. Treat it as
   "Wald inference unsafe", keep point fits visible, and route users toward
   profile/bootstrap/status diagnostics where supported.
4. Do not call native TMB a full REML fallback for Ayumi's bivariate q4
   sigma-phylo model.
5. Add Bernoulli/binomial as a real response-family slice, not just as a note
   in the roadmap.
6. Treat speed and robustness as inference work: point estimates, logLik,
   gradients, and CI endpoints/status must all be compared.

## Next Work Order

Highest priority:

1. Wait for `drmTMB#572` CI. If green, make it ready or merge per owner
   preference. If red, inspect the exact failing job before changing code.
2. Merge or mark ready `drmTMB#571` after review. It is green and clean.
3. Continue `drmTMB#570`: implement a candidate-start/selection ladder for
   the Ayumi beak native path. The ladder should try multiple start candidates
   and optimizer presets, record every attempt, and reject fits that are still
   essentially at the starting values.
4. Continue `DRM.jl#293`: fix or explain Julia ML `-Inf` after 100 tips in
   the q4 point-fit ladder.
5. Start `drmTMB#569`: add Bernoulli/binomial first slice with likelihood,
   simulation, tests, docs, and capability-matrix rows.
6. Return to `drmTMB#544`: bridge gate vs engine audit and CI guard.

Suggested `#570` acceptance gates:

- Reproducible small/full fixtures for beak sigma-phylo.
- Candidate starts recorded in `fit$optimizer_attempts` or a similarly stable
  diagnostic table.
- Default and careful/robust presets do not silently accept a starting-like
  basin when a better candidate exists.
- Point-fit recovery is separated from interval recovery.
- No biological interpretation claim until point fit and uncertainty route are
  both defensible.

Suggested `#569` acceptance gates:

- Decide public constructors: likely `bernoulli()` for 0/1 and `binomial()`
  or `family = stats::binomial()` support for successes/trials.
- Add likelihood and simulation before user-facing docs.
- Add fixed-effect tests first, then ordinary random intercept/slope support
  only after fixed-effect recovery is green.
- Document the difference between Bernoulli, binomial, beta-binomial, and
  missing-predictor binary imputation.

## Team Perspective

Use the standing names from `AGENTS.md`:

- Ada: orchestrate and decide next slice.
- Rose: block overclaims and stale "done" language.
- Grace: CI, pkgdown, reproducibility, release gates.
- Fisher/Noether: likelihood, interval status, REML/ML wording, inference
  truth.
- Gauss/Karpinski: TMB starts, optimizer ladders, sparse/AD speed work.
- Hopper/Boole/Emmy: R bridge, formula grammar, S3/API shape.
- Florence/Pat/Darwin: visuals, articles, and applied-user readability.
- Jason: scout GLLVM/gllvmTMB and HSquared/hsquared before borrowing terms or
  algorithms.

## Claim Boundaries To Preserve

- `rho12` is the canonical residual bivariate correlation name.
- `drmTMB` remains one-response and two-response only. Higher-dimensional
  multivariate models belong in `gllvmTMB`.
- Native TMB REML is not yet the bivariate q4 sigma-phylo solution.
- Julia q4 acceleration is promising but not ready for Ayumi's 10k x 50-tree
  protocol.
- `beta_binomial()` exists; plain Bernoulli/binomial primary response support
  is planned, not done.
- No CRAN submission is planned unless Shinichi explicitly decides.

## Useful Commands

```sh
git status --short --branch
sh tools/start-mission-control.sh --background
python3 tools/validate-mission-control.py
Rscript -e "devtools::test(filter = 'optimizer-contract')"
Rscript -e "devtools::test(filter = 'gaussian-location-scale')"
Rscript -e "devtools::test(filter = 'biv-gaussian')"
git diff --check
gh pr view 571 --json mergeStateStatus,statusCheckRollup
gh pr view 572 --json mergeStateStatus,statusCheckRollup
```

For long handoffs or risky pauses:

```sh
Rscript tools/codex-checkpoint.R --goal "handover from PROJECT_STATE.md" --next "inspect #571/#572/#570"
```

