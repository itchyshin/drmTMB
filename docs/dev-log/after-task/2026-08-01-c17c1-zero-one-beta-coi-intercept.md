# After Task: C17-C1 Zero-One-Beta `coi` Random Intercept

## Goal

Implement and adjudicate only `mc-0570`: the complete-response ML-Laplace
zero-one-beta model

```r
bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1 + (1 | id))
```

The earned ceiling is `implemented / verified / point_fit_recovery`. This task
does not claim profiles, intervals, coverage, inference readiness, `coi`
slopes, joint atom effects, structured effects, q2-plus, missing responses,
REML, or AGHQ.

## Implemented

The R specification, start/map machinery, TMB data, independent `u_coi` and
`log_sd_coi` random-effect carrier, Gaussian penalty, reports, `sdpars()`,
`ranef()`, prediction, simulation boundary, and profile-target status now carry
one unlabelled `coi` random intercept. The parser rejects slopes, labels,
correlation, multiple or simultaneous random components, structured effects,
missing responses, and other neighbouring forms.

The canonical ledger promotes only `mc-0570`. Its model-surface census becomes
329 implemented, 340 rejected by design, and 18 not implemented. `mc-0578`
remains not implemented for the separate C17-C2 slope milestone.

## Mathematical Contract

The implemented predictor is

\[
\operatorname{logit}(coi_i)=X_{coi,i}\beta_{coi}
+Z_{coi,i}\operatorname{diag}\{\exp(\ell_{coi})\}u_{coi},
\qquad u_{coi}\sim N(0,I).
\]

For `y = 0`, the boundary contribution is
`log(zoi) + log(1 - coi)`; for `y = 1`, it is
`log(zoi) + log(coi)`. Interior beta likelihood terms do not depend on `coi`.
The independent R oracle checks the full mixture, normalized Gaussian prior,
objective, and finite-difference gradient.

## Files Changed

Implementation and focused tests touch the existing zero-one-beta R/TMB,
method, profile, and test paths. Ledger inputs and generated census files record
the one-cell promotion. README, NEWS, ROADMAP, family documentation, source and
implementation maps, family registry, evidence-goal, readiness, validation-debt,
and known-limitation pages now describe the exact point-fit scope and warning.

`docs/dev-log/check-log.md` remains untouched because PR #869 is still open,
as explicitly requested. Formula grammar and likelihood-parameterization
documents also remain untouched under the locked C17 boundary; their stale
sentences are recorded below rather than silently widening this task.

## Checks Run

- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::document()'`:
  pass; `man/zero_one_beta.Rd` regenerated.
- Focused zero-one-beta tests: pass.
- Full `devtools::test(reporter = "summary")`: reached the end with only four
  line-number-pinned estimator-conformance failures caused by the inserted C1
  code. The four evidence pointers were updated, and the focused
  `estimator-surface-conformance` rerun passed.
- `python3 tools/capability_ledger.py --check`: pass, 30 generated outputs.
- `python3 -m unittest tools.tests.test_capability_ledger`: 47 tests pass; the
  sole remaining error is the intentionally unchanged strict C14 fingerprint
  guard (`mc-0568: C14 target fingerprint differs`).
- `python3 tools/capability_ledger.py --check-c14-receipt-equivalence`: same
  expected pending-authorization error.
- The 12/12 authenticated C14 model-15 compatibility receipt remains retained
  and fingerprint-equivalent for the relevant source files. It is evidence,
  not a claim that the persistent strict landing guard has been changed.

Package check, pkgdown build/check, CI, and post-merge Mission Control read-back
remain PR landing gates.

## Tests Of The Tests

The focused suite includes an independent full-likelihood and numerical-gradient
oracle, verifies that `log_sd_coi` changes the objective, checks extractors and
prediction, and rejects malformed slopes, labels, covariance, simultaneous
random components, structured effects, missing responses, and direct profiles.
It therefore does not rely only on a self-comparison of package outputs.

## Consistency Audit

The exact stale-wording searches were:

```sh
rg -n 'coi random effects|`coi` random effects|random effects in `coi`|other zero-one-beta random effects|other zero-one beta random effects|other atom random effects' README.md ROADMAP.md NEWS.md docs/design vignettes R man --glob '!docs/design/01-formula-grammar.md' --glob '!docs/design/03-likelihoods.md' --glob '!docs/dev-log/after-task/**' --glob '!docs/dev-log/handover/**' --glob '!*.html'
rg -n 'coi.*(profile|interval|coverage|inference_ready|supported)|point-fit-only.*coi|coi.*point-fit-only' README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes R man --glob '!*.html'
```

Current reader surfaces name `coi ~ 1 + (1 | id)` and keep `coi` slopes,
profiles, intervals, coverage, and broader atom effects unavailable. Historical
notes remain historical. Two locked current documents still have stale blanket
wording: `docs/design/01-formula-grammar.md` / `vignettes/formula-grammar.Rmd`
and `docs/design/03-likelihoods.md`. They require a separately authorized
documentation-only synchronization because this arc explicitly forbids formula
grammar and likelihood-parameterization document changes.

The generated `man/drmTMB.Rd` missing-response paragraph was restored to the
canonical `origin/main` artifact after roxygen work, without altering missingness
implementation or claims.

## GitHub Issue Maintenance

PR #869 was checked live and remains open. Its overlap keeps the shared
check-log entry deferred. No issue was opened or closed because C17-C1 is being
landed through its focused branch and forthcoming PR.

## What Did Not Go Smoothly

The original prospective contract required every group in all four M=64
attempts to contain at least two observed zeroes, two observed ones, and ten
interior observations. Only two of four attempts met that all-groups rule even
though all four estimator and recovery attempts passed. The raw receipt remains
`BLOCKED_POINT_RECOVERY`; it was not rewritten.

An exact audit showed that a correct campaign meets that all-four rule with
probability only 0.3700719. Shinichi therefore authorized promotion with a
sample-information warning. Historical M=32 boundary failure and all sparse-
support attempts remain retained.

The existing C14 equivalence checker also rejects the new model-15 fingerprint.
Two attempted guard edits were stopped by the safety review. The guard remains
unchanged pending explicit authorization of the exact compatibility bridge.

## Team Learning

Support-count thresholds should be calibrated under the frozen DGP before they
become all-attempt hard gates. A low-attainability group-support rule is useful
as an identifiability warning, but it should not erase otherwise stable
population-level point recovery unless the sparse support directly breaks the
declared estimand.

Line-number-pinned source evidence must be refreshed whenever a shared source
file gains code above the cited region. The conformance test correctly caught
four such drifts without exposing a REML behavioural regression.

## Known Limitations

The recovery claim is narrow: four retained M=64 attempts, 50 observations per
group, at one frozen DGP. Groups with few observed zeroes or ones can have
weakly identified conditional modes, so users should inspect within-group atom
counts before interpreting individual modes. No interval, coverage, robustness,
or broad family-level claim follows.

The strict C14 landing guard is unresolved. Formula-grammar and likelihood
design wording is intentionally deferred. The shared check log is deferred
until PR #869 lands or closes.

## Next Actions

1. Obtain explicit permission, if desired, for the strict C17-C1 C14
   current-source compatibility bridge while keeping the immutable C14 receipt
   and fingerprint unchanged.
2. Run package check and pkgdown verification, then obtain a fresh Rose landing
   reread.
3. Open a focused PR, require CI green on one unchanged head SHA, and request
   fresh merge authorization.
4. After merge, verify canonical `origin/main`, the 329/340/18 ledger census,
   and Mission Control runtime with no overlay.
5. Begin `mc-0578` only as a separate C17-C2 milestone after C17-C1 merges.
