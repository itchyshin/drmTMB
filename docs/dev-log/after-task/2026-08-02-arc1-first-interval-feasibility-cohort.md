# After Task: Arc 1 Current-Source Interval-Feasibility Cohort

## 1. Goal

Promote only current-source point-fit targets whose retained likelihood profiles
are finite, ordered, two-sided, unclamped, and reproducible. This bounded arc
tests five high-yield Gaussian targets and retains one Poisson
`phylo_interaction()` failure without widening any claim to coverage.

## 2. Implemented

At source `c8e04258d9d550384b037b1e2a91734c22aaaab5`, three Totoro seeds passed for
each exact target:

- `mc-0260::fixef:mu:x`, ML Gaussian location slope at `n = 240`;
- `mc-0262::fixef:sigma:x`, ML Gaussian log-`sigma` slope at `n = 240`;
- `mc-0260m::fixef:mu:(Intercept)`, ML `meta_V(V = vi)` pooled effect at `K = 48`;
- `mc-0266::sd:sigma:(1 | id)`, ML residual log-SD random-intercept SD at 48
  groups and 20 observations per group.
- `mc-0269::sd:mu:(0 + x | id)`, Gaussian REML independent location
  random-slope SD at 64 groups and 12 observations per group.

These five cells move from `point_fit_recovery` to `interval_feasible`. The
model-surface ledger now contains 161 `interval_feasible` and 77
`point_fit_recovery` cells. The change is target-specific: it does not promote
sibling coefficients or complete model routes.

The Arc 0 manifest freezes all 82 source candidates and reconciles them into
5 promoted, 16 retained STOP, 18 remaining executable, 23 profile-fenced,
4 estimator/row-structure holds, and 16 q12-excluded cells. Its SHA-256 is
`c9bf43b167011a2b4f289ff24bd966cc688d29caf93b4f83317bdc60526f2ea2`.

`mc-0438::sd:mu:phylo_interaction(1 | plant:pollinator)` remains
`point_fit_recovery`. Both retained attempts used 64 pair-level latent effects
and returned nonfinite interval endpoints at 8 and 20 observations per pair.

## 3a. Decisions and Rejected Alternatives

For fitted target estimate \(\hat\theta\) and profile endpoints \((L,U)\), a
receipt passes only when

\[
L,\hat\theta,U \in \mathbb{R}, \qquad L < \hat\theta < U,
\]

the optimization convergence code is zero, `pdHess = TRUE`, and the profile is
neither boundary- nor clamp-limited. Each retained trace must span both sides of
\(\hat\theta\), and its target, estimate, and endpoints must equal the interval
sidecar and receipt. This is an interval-existence contract, not a coverage or
calibration statement.

For `mc-0260m`, \(\theta\) is only the pooled-effect intercept. The
between-study heterogeneity SD is excluded; its retained `K = 12`, generating
`tau = 0.10`, `[0, Inf]` failure remains binding.

## 4. Files Touched

Four small profile runners and one retained-STOP runner now write explicit
estimator and direct-target fields, immutable fixture hashes, current runner
hashes, and trace/interval hashes. Four cohort reconcilers share
`tools/arc1_profile_reconcile.py`, which parses rather than merely hashes the
sidecars. `tools/tests/test_arc1_profile_reconcilers.py` exercises the retained
denominators and adversarial mutations. The Linux capability-ledger CI step now
runs that test.

The capability ledger, generated census/surface, and live parity-triage rows
record the five exact promotions and the dated `mc-0438` STOP. No `R/`, `src/`,
formula grammar, likelihood, vignette, README, NEWS, or public API file changed.

## 5. Checks Run

- `python3 tools/reconcile-arc1-gaussian-fixed-profiles.py ...`: `mc-0260` 3/3
  PASS and `mc-0262` 3/3 PASS.
- `python3 tools/reconcile-arc1-meta-v-profiles.py ...`: `mc-0260m` 3/3 PASS.
- `python3 tools/reconcile-arc1-gaussian-sigma-re-profiles.py ...`: `mc-0266`
  3/3 PASS.
- `python3 tools/reconcile-arc1-gaussian-reml-slope-profiles.py ...`:
  `mc-0269` 3/3 PASS.
- `python3 -B tools/capability_ledger.py --check`: all 30 generated outputs
  current.
- `python3 -m unittest tools.tests.test_capability_ledger
  tools.tests.test_arc1_profile_reconcilers`: 53 tests passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  'pkgload::load_all(".", quiet=TRUE); devtools::test(filter="profile-targets")'`:
  861 passed, 0 failed, 6 existing `sd_phylo1()`/`sd_phylo2()` deprecation
  warnings.
- `git diff --check`: passed.
- The manifest contains exactly 82 unique `mc-*` cell IDs and has the frozen
  SHA-256 recorded above.

Fisher returned GO for all five targets. Rose returned GO for the computational
evidence after the immutable receipt repair, then identified live-triage and
closure discrepancies that this report repairs. Grace's provenance review
identified the missing CI invocation and tracked-reconciliation comparison;
both are now enforced.

## 6. Tests of the Tests

The adversarial test copies retained evidence into a temporary directory and
confirms rejection after changing the estimator, runner hash, target, fixture,
interval endpoint, or trace status. It also rejects duplicate and missing seeds
for the fixed, `meta_V`, residual-scale RE, and REML-slope reconcilers. On the positive
path, each freshly recomputed reconciliation table must be byte-identical to the
tracked table. These mutations demonstrate that hashes alone cannot satisfy the
contract.

## 8. Consistency Audit

The status inventory used this exact search:

```sh
rg -n "mc-0260|mc-0262|mc-0260m|mc-0266|mc-0438|fixef:mu:x|fixef:sigma:x|fixef:mu:\\(Intercept\\)|sd:sigma:\\(1 \\| id\\)|sd:mu:phylo_interaction" README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml docs/dev-log/dashboard/parity-triage.tsv docs/dev-log/dashboard/capability-ledger/cells.tsv
rg -n "mc-0262.*QUARANTINED|mc-0266.*no comparator or interval|mc-0260m.*No CI/coverage|mc-0438.*pdHess" docs/dev-log/dashboard/parity-triage.tsv docs/dev-log/dashboard/capability-ledger/cells.tsv
```

The first search confirmed that only live capability and parity surfaces needed
target-scoped updates. The second search is empty for the repaired parity rows;
the remaining `mc-0438` `pdHess` wording belongs to authenticated historical
point-recovery evidence, not the new `se = FALSE` feasibility receipts. A new
ledger guard now requires dated exact-target supersessions for all five
promotions and a dated nonfinite-endpoint STOP for `mc-0438`.

## 7a. Issue Ledger

The open-issue inventory found issue #682, “Methods: profile likelihood as the
featured CI method,” as the nearest overlap. No issue was opened, closed, or
commented on: this cohort supplies internal target-level feasibility evidence,
does not change the public profile method, and the larger candidate-ranking goal
continues.

## 9. What Did Not Go Smoothly

The first receipts recorded neither the ML estimator nor immutable fixture
hashes, and their reconcilers trusted receipt fields while only hashing the
sidecars. They also called `profile()` and `confint()` separately. The repaired
runners derive endpoints from the one retained profile execution and bind every
artifact semantically.

The first `mc-0438` record treated `pdHess = FALSE` as a result even though the
fit used `se = FALSE`. It now records the Hessian as unavailable. That cleanup
also revealed that a profile object may say `profile.message = "ok"` while its
endpoints are nonfinite; boundary status therefore depends on the endpoints,
not the message alone.

The first parity-triage edits appended supersession text to stale sentences
instead of replacing the contradiction. Target-scoped dated supersessions plus
a ledger validator now make that failure mode visible.

## 11. Team Learning

A retained interval receipt is only as strong as the chain that binds source,
estimator, target, fixture, profile trace, interval, and denominator. Reviewers
should require semantic sidecar equality and a mutation test before accepting a
hash table as evidence. Adjacent decision surfaces need machine guards when a
promotion supersedes historical prose.

## 10. Known Residuals

No result estimates coverage, calibration, bias, or nominality. One of the
three `mc-0260m` pooled-effect intervals misses the generating value; this is
compatible with feasibility and reinforces why coverage is withheld. The
`mc-0260m` heterogeneity SD, every sibling coefficient, REML fixed effects,
zero-one-beta profile-fenced targets, q12 candidates, missing-response routes,
and public interval guidance remain outside this cohort.

## 12. Cross-Product Coverage

This slice does NOT cover coverage, calibration, missing responses, q12,
profile-fenced targets, public guidance, or model-wide inference. Its estimator
products are explicit ML for four targets and explicit Gaussian REML for
`mc-0269::sd:mu:(0 + x | id)` only. Neither inherits to other coefficients,
providers, information rungs, estimators, or families.

Stop execution here and hand the frozen remaining candidate ranking to Claude.
The next session should start from the Arc 0 manifest, select only its highest
ranked remaining exact target, and preserve the same one-profile immutable
receipt contract. Do not run q12, coverage, or calibration in that slice.
