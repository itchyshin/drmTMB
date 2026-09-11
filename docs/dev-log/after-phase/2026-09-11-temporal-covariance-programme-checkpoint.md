# After Phase: Temporal covariance programme checkpoint

## Goal

Record the earned stopping point for drmTMB's temporal covariance programme. Keep the
completed AR1/OU, homogeneous Toeplitz and heterogeneous-AR1 work usable; preserve the
failed phylogeny-plus-temporal-OU coverage evidence; and defer later structures until a
scientific use case makes their additional parameters worthwhile.

## Decision

The programme is paused at P3 rather than widened automatically to heterogeneous
Toeplitz, seasonal models, random walks, ARMA or temporal Matern. Temporal covariance
models may differ because they answer different scientific questions; a package menu is
not evidence that every model should be fitted or implemented now.

## Completed and retained work

| Arc | Status at this checkpoint | Receipt |
| --- | --- | --- |
| Direct temporal AR1 and OU | qualified predecessor work | direct OU parent closeout `0d66e62f3` as recorded in the master plan |
| P1 stable phylogeny plus independent temporal OU | interval-feasible only; retained G13 intercept-profile coverage failures prevent a calibrated-inference claim | active owner lane `codex/phylo-ou-g12-prep-20260910`; source `5bd43b3ba487b18e6e1c69e8a5ff7e6a01b4c792` at checkpoint |
| P2 homogeneous Toeplitz | closed | `ceff79d53`; `docs/dev-log/after-task/2026-09-10-temporal-homtoep-p2-closeout.md` |
| P3 heterogeneous AR1 | closed as interval feasibility, not coverage calibration | `0788c78b5`; `docs/dev-log/after-task/2026-09-11-temporal-hetar1-closeout.md` |
| Evolutionary tree OU | closed as a separate phylogenetic covariance choice | `84bd42133`; `docs/dev-log/after-task/2026-09-11-phylogenetic-ou-covariance.md` |

The tree-OU provider is deliberately separate from temporal OU and from the P1
phylogeny-plus-time composition. It has positive evolutionary decay along tree branch
lengths and does not implement a separable phylogeny-by-time field.

## Deferred work and re-entry conditions

P4 heterogeneous Toeplitz remains deferred. It can start only when an ecological data
set supplies a common regular schedule, enough replicated series to identify both
lag-specific correlations and occasion-specific temporal process SDs, and a scientific
comparison showing that homogeneous Toeplitz and heterogeneous AR1 are inadequate.

P5 remains deferred. A future child must name one scientific process: seasonal cycles,
nonstationary trend, moving-average shocks for ARMA, or a smoothness question for
temporal Matern. The child receipt must state its restricted first model, data boundary,
dense oracle, mutations, recovery design, timing estimate and reader question before
source edits begin.

No deferred child inherits P1 campaign authority, its 3,500-task campaign, its failed
coverage rows, or any calibrated-inference claim.

## Validation

- `Rscript --vanilla docs/dev-log/plans/2026-09-09-temporal-covariance-programme/unlazy/check-programme.R G18 --reverify` returned `TEMPORAL_PROGRAMME_G18_PASS REVERIFY`.
- The reverify only checks the programme contract. It did not start a campaign or refit a model.
- `git diff --check` and a scoped decision-language scan are required before this checkpoint is committed.

## Scope boundary

This checkpoint changes planning and evidence records only. It adds no R code, TMB
likelihood, temporal-scale model, forecasting surface, new family, external campaign,
push, merge, release or external message.

## Next action

The P1 owner may independently close its interval-feasibility ledger while preserving
the G13 failure. Otherwise, the next programme action is a fresh, use-case-led child
receipt rather than an automatic P4 or P5 implementation.
