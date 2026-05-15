# After Task: Phase 6c Random-Slope Roadmap

## Goal

Record random slopes as their own Phase 6c lane and keep the first target
conservative: one structured `mu` slope first, with up to two slopes only as an
advanced path after recovery evidence.

## Implemented

- Created GitHub issue #33 for structured random slopes and biological
  slope-correlation examples.
- Added an issue comment and roadmap wording that Phase 6c includes
  profile-likelihood CIs for random-slope SDs and direct, identifiable
  slope-related correlations.
- Added `ROADMAP.md` Phase 6c with Slices 69-76.
- Updated Phase 6b wording so major tutorials must include more symbolic maths,
  detailed explanations, and biological interpretation.
- Recorded the same decision as a local project memory note because the project
  owner explicitly asked to remember it.

## Mathematical Contract

The first random-slope contract should be:

```text
mu_i = x_i^T beta + a_{0,g[i]} + a_{1,g[i]} z_i
```

For a structured layer such as phylogeny or space, the group-indexed vector
`a_1` should follow the same structured dependence family as the intercept
effect, but as a separate slope field until the covariance story is stable.
Intercept-slope correlations are not part of the first path. A later bivariate
target can focus on slope1-slope2 correlations for the same covariate, such as
a plasticity syndrome.

Profile-likelihood inference belongs in the same Phase 6c lane once those point
estimates are stable. Direct, identifiable random-slope SDs and slope
correlations should become profile-ready targets; derived or weakly identified
correlations should carry explicit unavailable statuses until a supported
profile method exists.

## Files Changed

- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-15-phase-6c-random-slope-roadmap.md`

## Checks Run

- `gh issue create --repo itchyshin/drmTMB --label enhancement --title "Phase 6c: structured random slopes and biological slope-correlation examples" ...`
- `gh issue comment 33 --repo itchyshin/drmTMB ...`
- `PATH=/opt/homebrew/bin:$PATH air format ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-15-phase-6c-random-slope-roadmap.md`
- `git diff --check`
- `Rscript -e 'pkgdown::build_site()'`
- `Rscript -e 'pkgdown::check_pkgdown()'`
- `rg -n "Phase 6c|profile-likelihood CI|random-slope SD|slope-related correlations|slope1-slope2|plasticity syndrome|issues/33" ROADMAP.md pkgdown-site/ROADMAP.html docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-15-phase-6c-random-slope-roadmap.md --glob '!pkgdown-site/search.json'`

## Tests Of The Tests

No tests changed. This is a roadmap and issue-tracking slice only.

## Consistency Audit

The existing roadmap already warned that structured slopes should be staged
conservatively. Phase 6c makes that policy visible in the phase sequence and
keeps the later Phase 10-12 structured-dependence programme from being the only
place random slopes are named.

## What Did Not Go Smoothly

Nothing technical. The main judgment was whether to put this in Phase 6b or a
new phase. The cleaner split is Phase 6b for tutorial quality and Phase 6c for
random-slope design and first slope paths.

## Team Learning

- Ada should keep phase labels aligned with the user's mental map, not only the
  package's internal architecture.
- Boole should make slope syntax and coefficient labels readable before any
  q>2 covariance block grows around them.
- Gauss and Noether should require explicit storage order and covariance
  algebra before any structured slope enters TMB.
- Fisher should insist on simulation recovery and replication diagnostics before
  two slopes are advertised.
- Darwin and Pat should push for biological examples such as thermal plasticity,
  desiccation plasticity, disturbance reaction norms, and bivariate plasticity
  syndromes.
- Rose should prevent intercept-slope and slope-slope correlation claims from
  sneaking into docs before `corpairs()` and tests support them.

## Known Limitations

This slice does not implement random slopes, slope correlations, or
profile-likelihood intervals for slope quantities. It only creates the roadmap
and issue structure.

## Next Actions

After Phase 6 and 6b are stable, Phase 6c should begin with the one-slope math
contract and ordinary grouped baseline before phylogenetic and spatial slopes.
