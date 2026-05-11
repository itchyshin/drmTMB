# After Task: Tweedie Likelihood Gate

## Goal

Move the future Tweedie family from a standalone wish-list note into the central
likelihood design contract without implementing the family.

## Implemented

- Added a planned Tweedie mean-scale-shape section to
  `docs/design/03-likelihoods.md`.
- Recorded the working public contract
  `Var[y_i] = sigma_i^2 * mu_i^nu_i` with `1 < nu_i < 2`.
- Stated that comparator tests against software reporting Tweedie dispersion
  should compare `sigma^2` with `phi`.
- Kept the first future slice fixed-effect, univariate, and intercept-only for
  `nu ~ 1`.

## Mathematical Contract

No likelihood code, formula grammar, or family registry code changed. The
planned contract is:

```text
E[y_i] = mu_i
Var[y_i] = sigma_i^2 * mu_i^nu_i
1 < nu_i < 2
```

The note also records the working transform `phi_i = sigma_i^2` for comparator
software that reports Tweedie dispersion directly.

## Files Changed

- `docs/design/03-likelihoods.md`
- `docs/dev-log/after-task/2026-05-11-tweedie-likelihood-gate.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `air format docs/design/03-likelihoods.md docs/dev-log/after-task/2026-05-11-tweedie-likelihood-gate.md docs/dev-log/check-log.md`:
  passed.
- `rg -n "Planned Tweedie|tweedie\\(|sigma_i\\^2 \\* mu_i\\^nu_i|glmmTMB::tweedie|issue #2|Tweedie" docs/design/03-likelihoods.md docs/design/27-tweedie-family-plan.md docs/design/06-distribution-roadmap.md ROADMAP.md docs/dev-log/after-task/2026-05-11-tweedie-likelihood-gate.md`:
  confirmed the design-gate wording.
- `git diff --check`: passed.

## Tests Of The Tests

This was a design documentation change only. The verification checks that the
central likelihood design now contains the future Tweedie equations and that
the text keeps `tweedie()` marked as planned rather than runnable.

## Consistency Audit

The likelihood note, Tweedie design gate, distribution roadmap, and roadmap now
all keep public `sigma = sqrt(phi)` as the working scale, reserve `nu` for the
Tweedie power parameter, and require comparator transforms before code lands.

## What Did Not Go Smoothly

The Tweedie gate already existed, but the central likelihood design still had
no planned Tweedie row. That made issue #2's implementation checklist easier
to miss.

## Team Learning

Noether: future families need their equations in the central likelihood file
before implementation starts, otherwise the family-specific design note can
drift away from the TMB routing contract.

## Known Limitations

- No `tweedie()` family function, likelihood branch, simulation method, or
  comparator test exists yet.
- The planned density still needs an implementation-source decision before code
  lands.

## Next Actions

- Decide the density implementation source and record provenance before adding
  a TMB branch.
- Add simulation and `glmmTMB` comparator tests when the first fixed-effect
  Tweedie likelihood is implemented.
