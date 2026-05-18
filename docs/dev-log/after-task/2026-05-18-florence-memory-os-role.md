# Florence Visualization Role And Memory OS Guardrails

Date: 2026-05-18

## Goal

Make the new visualization role durable and use the user-provided Memory OS
materials to improve how future `drmTMB` work is remembered without adding a
new dependency or parallel agent framework.

## What Changed

- Added Florence to the standing review roles in `AGENTS.md`.
- Added Florence to the collaboration design note so future contributors see her
  beside Ada, Darwin, Fisher, Pat, Grace, and Rose.
- Added a Florence figure gate to `docs/design/39-visualization-grammar.md` for
  publication-quality plots, confidence bands, interval provenance,
  accessibility, and composable `ggplot` output.
- Updated `docs/dev-log/team-improvements.md` with the Florence role and the
  conservative Memory OS rule: durable project decisions must live in repository
  docs, check logs, after-task reports, issues, pull requests, or explicit memory
  notes rather than only in conversation.

## Memory OS Assessment

Ada's view is that the PDF and starter pack contain a useful operating pattern:
store decisions in a durable place, inject only compact stable facts at the
start of a task, and search older evidence before trusting memory. Rose's view is
that the main failure mode in this project has been conversational drift, not a
lack of another tool. Grace therefore recommends adopting the memory discipline
now and treating Hermes or MemSearch installation as a separate reproducibility
decision.

## Standing Roles

- Ada: integrated the role and memory-policy changes into existing project
  documents.
- Florence: defined the figure-quality gate for publication-ready plots.
- Pat: kept the rule reader-facing; a beginner should see the biological
  question, fitted parameter, and interval status.
- Fisher: insisted that visual uncertainty must match `conf.status` and
  `interval_source`.
- Grace: kept Hermes, hooks, and MemSearch out of the package until there is a
  separate design decision.
- Rose: recorded the discrepancy and the new memory habit in the team-improvement
  loop.

## Validation

This was a process and documentation slice. No R code or likelihood code changed.
Validation run:

- `air format AGENTS.md docs/design/07-collaboration-and-site.md docs/design/39-visualization-grammar.md docs/dev-log/team-improvements.md docs/dev-log/check-log.md docs/dev-log/after-task/2026-05-18-florence-memory-os-role.md`
- `git diff --check`

## Open Risks

Florence is now documented as a standing role, but the current plotting helpers
still need a separate quality pass. The next visualization slice should improve
examples and figure styling rather than only documenting the standard.
