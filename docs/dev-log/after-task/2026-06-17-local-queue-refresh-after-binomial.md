# After Task: Local-R Queue Refresh After Binomial Comparator Artifact

## Goal

Keep the master local-R queue truthful after #591 merged the first fixed-effect
binomial `stats::glm()` parity comparator artifact.

## Implemented

Updated `docs/design/157-capability-completion-worklist.md` so the
non-Ayumi issue-led path is now a closed checkpoint rather than the next
implementation blocker. The document now records that #577, #544, #569, #588,
#589, #590, and #591 are on `main`, and that the plain binomial route is fitted
and parity-banked for fixed-effect `stats::binomial(link = "logit")` models.

Updated `docs/design/46-pre-simulation-readiness-matrix.md` so its "Next
Surface Decisions" section treats binomial work as evidence depth. The next
binomial-specific promotion would be an MCSE-backed interval-calibration grid;
random effects, structured effects, bivariate/mixed responses, and the Julia
bridge stay out of scope.

Corrected the #591 check-log entry so the command block records the scoped
hard-framing scan that was actually used for that slice.

## Mathematical Contract

No model surface changed. The binomial contract remains:

```text
Y_i ~ Binomial(n_i, mu_i)
logit(mu_i) = X_mu[i, ] beta_mu
```

Supported public syntax remains fixed-effect native TMB only:
`family = stats::binomial(link = "logit")` with explicit 0/1 responses or
`cbind(successes, failures)`.

## Files Changed

- `docs/design/157-capability-completion-worklist.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-17-local-queue-refresh-after-binomial.md`

## Checks Run

```sh
git diff --check
rg -n '^(<<<<<<<|=======|>>>>>>>)' docs/design/157-capability-completion-worklist.md docs/design/46-pre-simulation-readiness-matrix.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-06-17-local-queue-refresh-after-binomial.md
rg -n 'non-identified|nonidentified|impossible|flat/unbounded|Bayesian only reads back the prior|REML on scale|REML.*scale' docs/design/157-capability-completion-worklist.md docs/design/46-pre-simulation-readiness-matrix.md
```

## Tests Of The Tests

This is a queue/documentation slice, not a package-code slice. The relevant
checks are scoped prose and status checks: the diff must contain only queue
wording, conflict-marker scans must be empty, and the hard-framing scan over
the changed current-state design docs must not introduce the forbidden Ayumi
wording.

## Consistency Audit

#569, #544, and #577 are already closed on GitHub. #591 merged with green
macOS, Ubuntu, and Windows R-CMD-check before this refresh. The refreshed docs
now match that issue state: binomial is no longer listed as the first pending
implementation blocker, but binomial interval calibration and Julia bridge
support are still unclaimed.

## GitHub Issue Maintenance

This slice updates the repository side of #491. A PR comment should be added to
#491 after the PR exists, then a merged-status comment after the PR merges.

## What Did Not Go Smoothly

The merged #591 check-log entry had an inconsistent command block: it showed a
broad hard-framing scan while the result text described the scoped scan. This
refresh corrects the command block and leaves the substantive #591 evidence
unchanged.

## Team Learning

Rose's queue rule is the same as the dashboard rule: after a capability slice
lands, the master queue should stop naming it as the next blocker. Otherwise
the team keeps re-planning around a solved problem and misses the real next
fork.

## Known Limitations

No package tests were rerun because no R, C++, tests, roxygen, dashboard
schema, or package runtime files changed. The refresh does not start release
prep, does not promote binomial interval calibration, and does not change the
Julia bridge status.

## Next Actions

Post the PR to #491. After this queue refresh merges, the next local-R choices
are: MCSE-backed binomial interval calibration if interval language matters
now, q8 coverage/power hardening, skew-normal evidence depth, or the structured
`mu` slope queue.
