# After Task: Arc 6 association F0–F2 preparation

## Goal

Freeze the method, audit the private B×NB2 association surface, and complete
the literature/comparator design without implementation, refits, simulation,
remote compute, public inference, or Arc D/F5 work.

## Implemented

Added the F0–F2 preparation receipt. It pins the private engine, independent
oracle runtime/defaults, and test fixture; states the staged Godambe estimand
and derivative contract; records
the fail-closed taxonomy, selects a negative IFM comparator plus the required
future full-refit comparator, and gives separate F3/F4/F5 approval fences.
It does not claim the full F1 deterministic fixture matrix has run or passed.

## Mathematical Contract

The target is link-scale `alpha` for a frozen-margin Bernoulli × ordinary-NB2
latent-normal rectangle association, with `eta = 0.999999*tanh(alpha)` derived
after estimation. The sandwich uses the full stacked score; conditional
stage-two curvature and direct `rho12` are excluded.

## Files Changed

- `docs/dev-log/2026-07-26-arc6-association-f0-f2-preparation-receipt.md`
- this report

## Checks Run

- Read-only source/test/design audit of the private router, its public-method
  fences, numerical derivative ladder, and failure paths.
- `git diff --name-status 1834734a..HEAD` over the engine/reference files:
  no change.
- Blob identity checks at `1834734a` and `ae8d6f5b` for the engine and B×NB2
  test fixture.
- `git diff --check` passed before documentation edits.
- Primary literature and package-documentation review completed.
- Noether, Fisher, and Rose re-reviewed the revised packet and returned READY
  for F0–F2 preparation only.

No tests were run: this task changed no executable behavior, and the request
prohibited refits/simulation. No compute was started.

## Tests Of The Tests

The existing frozen test file uses independent numerical derivatives and an
independent `mvtnorm` rectangle oracle, and forces unavailable paths. This
task did not modify those tests.

## Consistency Audit

The receipt preserves the existing public aborts for `vcov()`, `profile()`, and
`confint()`, leaves the capability ledger untouched, and repeats that direct
`biv_lognormal()` `rho12` evidence does not transfer. No pkgdown, README,
ROADMAP, NEWS, formula grammar, or generated-site change is warranted because
the user-facing contract did not change.

## GitHub Issue Maintenance

No issue action: this is a plan-only, developer-private preparation lane.

## What Did Not Go Smoothly

The local second-brain CLI could not initialise because the sandbox forbids its
attempt to chmod `~/.basic-memory`. The repository plan's recorded brain query
and the workspace memory registry supplied the prior decision; the repo
remained the technical source of truth.

## Team Learning

The `copula` package documents exactly the excluded shortcut: IFM fit through
parametric pseudo-observations with a variance that omits estimated-margin
uncertainty. It is useful as a negative comparator, not as a mixed-discrete
reference implementation.

## Known Limitations

F0–F2 do not validate an SE, interval, recovery, calibration, coverage, or
public API. The zero/negative/tail/near-boundary F1 fixture design and its
execution remain separately approval-gated. F3, F4, and F5 each remain
separately approval-gated.

## Next Actions

Wait for Shinichi's explicit F3 approval under the exact fence in the
preparation receipt. That approval must separately permit the locked F1 fixture
implementation/execution and require it to pass before the F3 smoke. Arc D/F5
remains outside this lane.
