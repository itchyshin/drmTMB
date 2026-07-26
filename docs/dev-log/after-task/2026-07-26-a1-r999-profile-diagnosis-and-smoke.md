# After Task: A1 R=999 diagnosis and profile-comparator smoke

## Goal

Determine whether finite percentile-tail resolution at `R = 199` explains the
repaired marginal-bootstrap RE-SD coverage shortfall, and implement only the
profile-comparator infrastructure and smoke needed before a separate full
compute decision.

## Implemented

The paired R=999 diagnosis now fails closed on harness hash, interval-arm,
unique seed, exact cell-count, and complete-pair requirements. It reports exact
marginal binomial intervals and a labelled paired normal-approximation interval
for the coverage difference. A fresh scalar Gaussian iid random-intercept
profile/bootstrap/Wald runner, all-attempt summary script, smoke launcher, and
pure interval-accounting helpers were added.

## Mathematical Contract

The target is natural-scale `sd:mu:(1 | g)` under the scalar Gaussian A1 DGP.
Unavailable/non-finite intervals are failures for the primary all-attempt
coverage estimand and are separately counted; complete-case coverage cannot
silently become the headline. The R=999 test calls an effect material only when
the paired gain is at least 0.020 and its paired 95% CI excludes zero.

## Files Changed

All implementation and evidence lives under
`docs/dev-log/simulation-artifacts/2026-07-26-a1-r999-bootstrap-diagnosis/`,
plus `tests/testthat/test-a1-profile-interval-contract.R` and the factual entry
in `docs/dev-log/check-log.md`. No public package API, interval endpoint
semantics, capability ledger, Arc D, or association files changed.

## Checks Run

- Totoro R=999 provenance: frozen harness SHA-256 matched; 200 shards, 2,000
  old rows, 2,000 new rows, zero incomplete pairs, zero duplicate seeds, and
  zero detected error logs.
- Paired results: c01 `+0.001` (95% CI `-0.0080, 0.0100`); c03 `+0.003`
  (95% CI `-0.0051, 0.0111`). Neither is material.
- Totoro smoke: one fit at each of 10/25/50 groups x 10 observations; all
  converged with `pdHess = TRUE`; marginal bootstrap, endpoint profile, and
  Wald intervals were valid in every row.
- Focused test `a1-profile-interval-contract`, R parsing, shell syntax, and
  `git diff --check` passed.
- Full `devtools::test(reporter = "summary")` completed successfully on this
  branch. It retained the repository's expected Julia/DRM.jl and disabled-workflow
  skips plus pre-existing numerical/deprecation warnings; it reported no failures.

## Tests Of The Tests

The new test exercises a missing interval as an all-attempt noncoverage,
profile-boundary extraction, paired-difference accounting, and duplicate-seed
rejection. The first smoke exposed an old local installed package that lacked
`refit_control`; the runner now fails closed on that interface mismatch, and
the smoke was rerun against Totoro's intended `drmTMB` 0.6.0 build.

## Consistency Audit

The stale-wording search used:

```sh
rg -n "R ?= ?199|0\\.8714|marginal-bootstrap|profile.*bootstrap" \
  README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes
```

No public wording was changed because the full profile evidence does not yet
exist. The new local artifact wording consistently identifies profile as the
candidate primary method, Wald as comparator, and bootstrap as robust fallback.

## GitHub Issue Maintenance

`gh issue list --search 'bootstrap interval OR profile interval OR coverage'`
found open issue #682, “Methods: profile likelihood as the featured CI method”.
This narrow diagnostic already fits that existing issue; no duplicate issue,
comment, closure, or PR action was taken because no user-facing recommendation
is ready.

## What Did Not Go Smoothly

The first profile smoke on the laptop used an older installed package and
rejected `refit_control`; this was not a model failure. The runner now refuses
that package interface instead of silently changing bootstrap refits. Fisher
also found missing all-attempt and seed-ledger guards; Rose found missing
helper/package provenance, a source-only test path, the shared-server core-cap
conflict, and missing closeout. All were repaired before this report.

## Team Learning

Do not infer paired provenance from row count alone: require arm identity,
unique `(cell_id, seed)` keys, and frozen counts. For coverage campaigns,
availability and calibration must remain distinct columns, with unavailable
intervals counted against the all-attempt headline. Totoro's default shared
cap is 100 workers unless a later written authorization says otherwise.

## Known Limitations

This is two-cell R=999 evidence only. It rules down R=199 tail resolution as
the dominant explanation for these cells; it does not separate percentile
boundary behavior from low-group Laplace bias. The profile result is a
three-attempt plumbing smoke, not coverage evidence. No structured,
non-Gaussian, slope, scale-side, bivariate, missing-data, Arc D, or association
claim follows.

## Next Actions

The full 3,000-attempt profile-versus-R=999-bootstrap campaign is held. Present
the frozen protocol, Totoro smoke receipt, resolved package commit, exact full
launcher, at-most-100-worker cap, and expected output paths for Shinichi's
explicit compute approval. Only after that approval may the full campaign run;
Fisher and Rose then review any narrow profile-first recommendation proposal.
