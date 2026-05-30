# After Task: Structured Workflow Registry

## Goal

Make the next autonomous Phase 18 work visible as taskable rows, not as another
spoken checklist. The registry should answer which family surfaces are ready,
diagnostic-only, blocked, or design-only for random slopes, structured
dependence, q=2/q=4 correlation blocks, and family-surface admission.

## Implemented

Added `docs/design/143-phase-18-structured-workflow-registry.md` and
`inst/sim/registry/phase18_structured_workflow_registry.csv`. The design note
gives the human-facing table for Gaussian, bivariate Gaussian, counts, bounded
responses, positive continuous responses, Student-t, Tweedie, zero-truncated
NB2, ordinal, meta-analysis, and mixed-response rows. The CSV gives the same
work as a workflow registry with lane, family, dpar, dependence, q/block,
status, existing Actions task, next autonomous action, and supervision
boundary.

## Mathematical Contract

No likelihood, formula grammar, or parameterization changed. The registry keeps
location `mu`, scale `sigma`, shape `nu`, residual coscale `rho12`, group-level
`corpairs()` rows, structured covariance, and known sampling covariance `V` as
separate layers. q=4 correlation rows remain point-estimate or
derived-unavailable interval rows unless direct interval evidence exists.

## Files Changed

- `docs/design/143-phase-18-structured-workflow-registry.md`
- `inst/sim/registry/phase18_structured_workflow_registry.csv`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-30-structured-workflow-registry.md`

## Checks Run

```sh
air format docs/design/143-phase-18-structured-workflow-registry.md docs/design/41-phase-18-simulation-programme.md ROADMAP.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-30-structured-workflow-registry.md
Rscript --vanilla -e "x <- read.csv('inst/sim/registry/phase18_structured_workflow_registry.csv', stringsAsFactors = FALSE); stopifnot(nrow(x) >= 30L, all(c('lane_id', 'workflow_lane', 'admission_status', 'existing_actions_task') %in% names(x))); stopifnot(!anyDuplicated(x[['lane_id']])); print(table(x[['admission_status']]))"
rg -n "structured workflow registry|phase18_structured_workflow_registry|Slice 1814|random-slope wrapper|correlation-block wrapper|family-surface admission|q=4 derived" docs/design ROADMAP.md docs/dev-log/check-log.md inst/sim/registry
gh issue list --repo itchyshin/drmTMB --state open --search 'structured workflow registry random slopes phylo spatial animal relmat q2 q4 corpairs' --limit 20 --json number,title,state,url,labels
git diff --check
```

Results are recorded in `docs/dev-log/check-log.md`.

## Tests Of The Tests

This slice is documentation and registry data, so no package behaviour test was
added. The CSV parse check is the test of the registry contract: it verifies
that the file is readable, has the expected columns, has at least 30 workflow
rows, and has unique lane IDs.

## Consistency Audit

The registry was checked against `docs/design/02-family-registry.md`,
`docs/design/41-phase-18-simulation-programme.md`, and
`docs/design/46-pre-simulation-readiness-matrix.md`. It does not promote
blocked neighbours such as non-Gaussian structured slopes, labelled count
q=2/q=4 covariance, ordinal mixed models, inflation or hurdle random effects,
Student-t `nu` random effects, or mixed-response bivariate families.

## GitHub Issue Maintenance

The issue search for structured workflow, random slopes, phylogenetic,
spatial, animal, `relmat()`, q=2/q=4, and `corpairs()` returned `[]`. No issue
action was taken because this slice is a local workflow registry and status
synchronization task, not a new feature request or bug fix.

## What Did Not Go Smoothly

The capability table is dense because it must keep family, dpar, dependence
layer, q-level, workflow status, and interval policy separate. The design note
therefore pairs a compact crosswalk with the CSV rather than trying to make one
giant table serve both humans and automation. The first local paste of the CSV
parse command also used `$` inside double quotes, which the shell expanded
before R saw it; the recorded command now uses `[[...]]` indexing.

## Team Learning

Rose's missing-cell audit should happen before every status promotion. Grace
should treat the registry as a dry-run source: workflows may dispatch only rows
whose status is admitted or explicitly diagnostic, and blocked rows should fail
closed.

## Known Limitations

The registry is not yet consumed by an R helper or GitHub Actions workflow.
That is the next implementation slice. The registry also records current
evidence only; it does not itself create simulation recovery evidence.

## Next Actions

1. Add a small registry validator and status-summary helper.
2. Add a random-slope workflow wrapper that filters admitted or source-tested
   rows.
3. Add a structured-dependence wrapper for `phylo()`, `spatial()`, `animal()`,
   and `relmat()` rows.
4. Add a correlation-block wrapper that separates residual `rho12`, q=2 direct
   rows, and q=4 derived-unavailable rows before profile or bootstrap work.
