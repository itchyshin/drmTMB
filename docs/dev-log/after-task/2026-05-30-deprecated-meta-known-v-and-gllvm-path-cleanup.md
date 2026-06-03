# After Task: Deprecated meta_known_V and GLLVM Path Cleanup

## Goal

Remove stale historical wording that could make deprecated `meta_known_V(V = V)`
look current or make a local `GLLVM.jl` checkout path look like a separate Julia
package.

## Implemented

- `docs/dev-log/after-phase/2026-05-16-phase-6e-tutorial-maturation-closure.md`
  now names `meta_V(V = V)` as the current additive known-covariance syntax and
  `meta_known_V(V = V)` as a deprecated compatibility alias.
- `docs/dev-log/after-task/2026-05-16-slice-90-flagship-location-scale.md`
  now uses the same current/deprecated split.
- `docs/dev-log/after-task/2026-05-29-claude-gllvmjl-transfer-audit.md`
  now qualifies `gllvmTMB.jl/src/confint_derived_wald.jl` as a `GLLVM.jl`
  local checkout path, not a package name.

## Boundary

This was a wording cleanup only. It did not change meta-analysis formula
grammar, compatibility behavior, Julia package dependencies, or provenance
requirements.

## Validation

Validation is recorded in `docs/dev-log/check-log.md` for 2026-05-30. The
checks covered stale syntax, positive current/deprecated wording, local-checkout
path qualification, and diff hygiene.

## Team Learning

Cicero's audit caught that historical after-task prose can still behave like
current documentation when users search the repo. Future syntax deprecations
should include a targeted dev-log stale scan, not only README and vignette
updates.
