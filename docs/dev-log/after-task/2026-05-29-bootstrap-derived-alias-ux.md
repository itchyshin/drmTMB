# After Task: Bootstrap Derived-Target Alias UX

## Goal

Make bootstrap target-set aliases honest when they would otherwise mix direct
bootstrap targets with unsupported derived targets.

## Implemented

`confint(..., method = "bootstrap")` now checks requested target rows against
the full `profile_targets()` inventory before filtering to direct
bootstrap-supported targets. Exact character requests, numeric row requests, and
broad aliases all share that gate.

The user-facing effect is that `parm = "correlations"` errors before bootstrap
simulation when the alias would include derived q4 unstructured-correlation
rows, and `parm = "variance_components"` errors before bootstrap simulation
when the alias would include derived modelled `sd(group)` surfaces. The error
uses the same direct-target-only message as exact derived requests.

## Mathematical Contract

No likelihood, transformation, or interval estimator changed. This is a target
selection contract: bootstrap remains limited to direct fitted-object targets
that already pass the Wald target gate. Derived rows such as q4 endpoint
correlations, modelled group-SD surfaces, repeatability, and phylogenetic signal
remain point-estimate/status rows until a validated derived-interval method
exists.

## Files Changed

- `R/profile.R`
- `tests/testthat/test-profile-targets.R`
- `NEWS.md`
- `docs/design/12-profile-likelihood-cis.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-29-bootstrap-derived-alias-ux.md`

## Checks Run

```sh
air format R/profile.R tests/testthat/test-profile-targets.R docs/design/12-profile-likelihood-cis.md NEWS.md
Rscript --vanilla -e "devtools::test(filter = 'profile-targets', reporter = 'summary')"
git diff --check
rg -n "direct-target-only|direct fitted-object targets only|broad alias|variance_components|correlations.*bootstrap|bootstrap.*correlations|bootstrap.*variance_components|silently dropping|unknown-target|target set" README.md NEWS.md ROADMAP.md docs/design R tests/testthat man --glob '!docs/dev-log/**'
gh issue list --repo itchyshin/drmTMB --state open --search 'bootstrap alias correlations variance_components derived target confint' --limit 20 --json number,title,state,url,labels
```

## Tests Of The Tests

The new tests exercise failure paths rather than only successful output:
`parm = "correlations"` with derived q4 unstructured-correlation rows,
`parm = "variance_components"` with derived modelled `sd(group)` rows, and a
numeric `parm` selecting a derived repeatability row. Each path must stop before
simulate/refit work and include the direct-target-only message.

## Consistency Audit

The stale-wording scan found the intended NEWS, design, code, and test hits. It
also found existing direct-target examples in `README.md`, `man/confint.drmTMB.Rd`,
and `docs/design/68-gllvmtmb-profile-ci-audit.md`. Those remain compatible:
ordinary `variance_components` bootstrap examples are still valid when the
alias selects only direct scale or SD targets. The new boundary applies when an
alias would include unsupported derived rows.

## GitHub Issue Maintenance

The issue search returned no exact open issue for bootstrap alias error UX. The
broader bootstrap issue remains a larger design lane and was not updated for
this narrow implementation slice.

## What Did Not Go Smoothly

The subtle bug was numeric `parm` handling. Once bootstrap had to inspect the
full inventory before filtering, numeric rows also needed full-inventory
semantics; otherwise a numeric row could be reinterpreted against the filtered
direct-target table.

## Team Learning

- Ada should keep using after-task "next actions" to choose slices that are
  small enough to validate and publish.
- Boole should treat broad aliases as user-facing API, not just internal
  conveniences.
- Fisher should keep direct-bootstrap claims separate from derived-interval
  design.
- Curie should include at least one alias or malformed-selection failure path
  when target matching changes.
- Grace should keep focused `profile-targets` validation as the fast gate for
  confidence-interval target edits.
- Rose should scan old design-note examples before marking new wording stale.

No spawned subagents were running.

## Known Limitations

This slice does not add derived bootstrap intervals, derived profile intervals,
bootstrap coverage simulations, or bootstrap integration into `summary()`,
`corpairs()`, or prediction tables.

## Next Actions

After this PR lands, the next bootstrap/profile slice can move to a small
direct-bootstrap coverage simulation design, or return to the Phase 18 count
structured q1 formal-pilot design note.
