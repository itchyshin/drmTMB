# Phase 18 Structured Workflow Registry

This note turns the current capability audit into a workflow map. The goal is
not to open new likelihoods or syntax. The goal is to let Ada and Grace dispatch
repeatable lanes for random slopes, structured dependence, correlation blocks,
and family-surface admission without asking the project owner to re-triage the
same table every time.

The machine-readable companion is
`inst/sim/registry/phase18_structured_workflow_registry.csv`. Each row names a
family surface, the distributional parameter, the dependence layer, the q-level
or block class, current admission status, the existing Actions task when one
exists, and the next autonomous action. A row marked `blocked` or
`design_only` is a stop sign for implementation work, not a request to push
through a parser or likelihood boundary.

## Slice 1814 Capability Crosswalk

Location is the mean-like parameter `mu`, scale is `sigma`, shape is `nu` or a
family-specific equivalent, and coscale is the residual bivariate correlation
parameter `rho12`. Group-level and structured correlations exposed through
`corpairs()` are separate from residual `rho12` and from known sampling
covariance `V`.

| Family surface | Ordinary random slope status | `phylo()` | `spatial()` | `animal()` | `relmat()` | q=2 / `corpairs()` | q=4 / `corpairs()` | Workflow state |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Gaussian location-scale | Ready for ordinary `mu` q > 2 and independent `sigma` slopes | Ready for Gaussian `mu` one-slope and intercept/direct-SD subsets | Ready for Gaussian `mu` one-slope, `mu`/`sigma` intercepts, and q=2 spatial location covariance | Ready for dense-pedigree Gaussian `mu` and `sigma` intercepts plus one `mu` slope | Ready for known-matrix Gaussian `mu` and `sigma` intercepts plus one `mu` slope | Ready for selected ordinary and structured q=2 rows; direct intervals only where profile targets exist | Fitted for selected ordinary and structured constant blocks, but many q=4 correlations are derived-unavailable | Add a random-slope wrapper and structured-dependence wrapper that dispatch existing smoke surfaces by status |
| Bivariate Gaussian and residual `rho12` | Ready only for matching slope-only `mu1`/`mu2`; intercept-plus-slope q=4 and p8/q8 stay closed | Ready for selected `mu1`/`mu2` and location-scale subsets; hard real-data q2/q4 cases remain diagnostic | Ready for constant q=2 location and constant q=4 location-scale smoke/artifact subsets | Ready for q=2 smoke artifacts and q=4 point-estimate smoke artifacts | Ready for q=2 smoke artifacts and q=4 point-estimate smoke artifacts | Ready for residual `rho12`, selected group/structured q=2 `corpairs()` rows, and slope-only `mu1`/`mu2` | q=4 rows are visible point estimates with explicit interval limits unless direct targets exist | Add a correlation-block wrapper that separates residual `rho12`, q=2 direct rows, and q=4 derived rows |
| Counts: Poisson and NB2 | Ready for ordinary non-zero-inflated `mu` independent slopes; NB2 `sigma` has only an ordinary intercept gate | Smoke/formal-admission only for q=1 `mu` intercepts; no count slopes or labelled covariance | Source-tested and artifacted for q=1 `mu` intercepts via `count_structured_q1`; no count slopes or labels | Source-tested and artifacted for q=1 `mu` intercepts via `count_structured_q1`; no count slopes or labels | Source-tested and artifacted for q=1 `mu` intercepts via `count_structured_q1`; no count slopes or labels | Blocked for labelled count q=2 covariance | Blocked for labelled count q=4 covariance | Keep using `poisson_phylo_q1_formal`, `nbinom2_phylo_q1_formal`, and `count_structured_q1`; add a count-admission audit wrapper before any promotion |
| Zero-inflated and hurdle counts | Fixed-effect `zi` or `hu` routes only | Blocked | Blocked | Blocked | Blocked | Blocked | Blocked | Failure-ledger rows only until a new likelihood design opens random effects |
| Bounded and binary-like responses: `beta()`, `beta_binomial()`, `zero_one_beta()` | `beta()` and `beta_binomial()` have ordinary `mu` intercept artifacts and focused independent-slope tests; `zero_one_beta()` is fixed-effect only | Blocked | Blocked | Blocked | Blocked | Blocked | Blocked | Existing fixed and ordinary `mu` lanes can be audited; structured bounded-response work needs design |
| Positive continuous: `lognormal()` and `Gamma(link = "log")` | Ready for ordinary `mu` intercept artifact lanes and focused independent-slope tests | Blocked | Blocked | Blocked | Blocked | Blocked | Blocked | Existing positive-continuous task can run; structured or `sigma` random effects need family-specific gates |
| Student-t | Ready for ordinary `mu` intercept artifact lanes and focused independent-slope tests | Blocked | Blocked | Blocked | Blocked | Blocked | Blocked | Keep `nu` as fixed-effect shape; no `nu` random-effect workflow until a design gate opens it |
| Tweedie | Fixed-effect only with intercept-only `nu` | Blocked | Blocked | Blocked | Blocked | Blocked | Blocked | Existing `tweedie_fixed_effect` task is the workflow; random effects are outside this slice |
| Zero-truncated NB2 | Ready for ordinary `mu` intercept artifact lanes and focused independent-slope tests | Blocked | Blocked | Blocked | Blocked | Blocked | Blocked | Existing positive-count task can run; hurdle and structured paths stay planned |
| Ordinal `cumulative_logit()` | Blocked; fixed-effect location only | Blocked | Blocked | Blocked | Blocked | Blocked | Blocked | Existing `ordinal_fixed_effect` task is the workflow; mixed ordinal models need design |
| Gaussian meta-analysis with known `V` | Ordinary Gaussian random effects are separate from known sampling covariance | Planned only as a future latent-relatedness plus study design | Planned | Planned | Planned | Not a `corpairs()` layer | Not a q=4 layer | Existing meta-`V` smoke surfaces stay in the fixed known-covariance lane |
| Mixed-response bivariate families | Planned | Planned | Planned | Planned | Planned | Planned | Planned | Failure-ledger rows only until a joint likelihood or copula/latent contract is designed |

The practical reading is simple. Most Gaussian, ordinary non-Gaussian `mu`, and
q=1 count-structured rows can move through workflow plumbing and artifact
audits today. The cells that still need supervision are the ones that would
change the likelihood, formula grammar, or covariance target: non-Gaussian
structured slopes, labelled count q=2/q=4 covariance, ordinal mixed models,
inflation or hurdle random effects, Student-t `nu` random effects, and
mixed-response bivariate families.

## Workflow Lanes

| Lane | Purpose | Existing entry point | Next autonomous step | Stop condition |
| --- | --- | --- | --- | --- |
| Registry and dry-run validator | Keep the table above parseable and synchronized with current Actions tasks | `inst/sim/registry/phase18_structured_workflow_registry.csv` | Add a small validator that checks status values, task names, and no accidental promotion of blocked rows | Any row changes fitted status without source evidence |
| Random-slope workflow | Dispatch ordinary and structured one-slope surfaces separately from blocked correlated-slope neighbours | Existing first-wave and surface-specific smoke runners | Add a wrapper that filters registry rows where `workflow_lane == "random_slopes"` and status is `ready_grid` or `ready_source_test` | Correlated non-Gaussian slopes, multiple structured slopes, or slope-level mean-scale covariance are requested |
| Structured-dependence workflow | Run or audit `phylo()`, `spatial()`, `animal()`, and `relmat()` surfaces without mixing them with residual `rho12` | `poisson_phylo_q1_formal`, `nbinom2_phylo_q1_formal`, `count_structured_q1`, plus Gaussian smoke/grid helpers | Add one wrapper that groups rows by dependence layer and prints the allowed task and required artifact audit | A requested row is `blocked`, `design_only`, or diagnostic-only without an audit plan |
| Correlation-block workflow | Separate residual `rho12`, group/structured q=2 direct rows, and q=4 derived-unavailable rows | `interval_heavy_summary`, bivariate smoke helpers, `corpairs()` artifacts | Add a wrapper that requires the row's interval policy before dispatching profile or bootstrap work | q=4 derived rows are treated as interval-ready |
| Family-surface admission workflow | Show which distributions are fixed-effect, ordinary random-effect, structured, or blocked | Current Phase 18 family tasks and readiness matrix | Add a report table from the registry before each broad-looking simulation report | A report borrows evidence from a neighbouring family or dpar |
| Formal sharded workflow | Scale only admitted rows after a pilot passes boundary and interval gates | Existing Actions inputs for shards, profiles, cores, and `require_complete` | Extend sharding only after the registry row names the formal gate and audit helper | A smoke or diagnostic row is promoted to recovery evidence without MCSE and artifact audit |

## Slice 1815 Registry Validator

Slice 1815 adds the first executable contract for the registry in
`inst/sim/run/sim_phase18_structured_workflow_registry.R`. The helper reads the
CSV, validates required columns, checks unique `lane_id` values, restricts
`workflow_lane` and `admission_status` to declared vocabularies, and compares
`existing_actions_task` values with the current Phase 18 Actions task choices.
Rows marked `blocked` or `design_only` must keep `existing_actions_task ==
"none"`, so a blocked family surface cannot be promoted accidentally by naming
an Actions task.

The helper also provides summary and filter functions:

- `phase18_read_structured_workflow_registry()` reads and validates the CSV.
- `phase18_structured_workflow_registry_summary()` counts rows by workflow
  lane and status, or by another requested set of registry columns.
- `phase18_filter_structured_workflow_registry()` filters rows by lane,
  status, dependence, or family group.
- `phase18_admitted_structured_workflow_rows()` returns only rows whose status
  is dispatchable by workflow plumbing: `ready_grid`, `ready_or_smoke`,
  `ready_smoke`, `ready_source_test`, or `smoke_formal_admission`.

The Actions runner now exposes `phase18_actions_task_choices()`, which lets the
registry validator share the same task vocabulary as manual GitHub Actions
dispatch. The validator is still workflow plumbing: it does not run
simulations, change likelihood code, or promote diagnostic rows to recovery or
coverage evidence.

## Slice 1816 Random-Slope Workflow Plan

Slice 1816 adds `phase18_random_slope_workflow_plan()`. The helper filters the
registry to admitted `workflow_lane == "random_slopes"` rows, then returns a
dispatch plan with the family group, family route, distributional parameter,
dependence layer, block class, admission status, dispatch status, Actions task
when one exists, wrapper helper, audit focus, next autonomous action, and
supervision boundary.

The current random-slope plan has nine admitted rows:

- five `ready_grid` rows already routed through existing Actions tasks:
  Gaussian ordinary `mu` slopes, Gaussian independent `sigma` slopes, Poisson
  `mu` random effects, NB2 `mu` random effects, and the bivariate Gaussian
  slope-only row;
- four `ready_source_test` rows for bounded responses, positive-continuous
  responses, Student-t, and zero-truncated NB2 `mu` random effects.

The bivariate Gaussian slope-only row is marked `needs_wrapper_target` because
the registry intentionally names `needed:random_slope_wrapper` rather than an
existing manual Actions task. Existing-task rows are marked
`ready_existing_task` or `source_test_audit`; source-tested rows must gain an
artifact lane before any recovery or coverage claim. The wrapper excludes
blocked, design-only, and diagnostic-only rows from the plan.

## Slice 1817 Structured-Dependence Workflow Plan

Slice 1817 adds `phase18_structured_dependence_workflow_plan()`. The helper
filters the registry to `workflow_lane == "structured_dependence"`, excludes
blocked and design-only rows, and labels each remaining row by dispatch or
audit state. This lane needs more status detail than the random-slope lane
because admitted Gaussian wrapper rows, count formal-admission rows, held smoke
rows, and diagnostic-only rows all need to stay visible but not equivalent.

The current structured-dependence plan has seven rows:

- four Gaussian `ready_grid` rows for `phylo()`, `spatial()`, `animal()`, and
  `relmat()`, all marked `needs_wrapper_target` with
  `workflow_helper = "structured_dependence_wrapper"`;
- one Poisson `phylo()` q=1 row marked `formal_admission_task`;
- one NB2 `phylo()` q=1 row marked `hold_smoke_audit`;
- one count q=1 `spatial()`/`animal()`/`relmat()` row marked
  `diagnostic_audit`.

Callers can set `include_held = FALSE` to keep only admitted rows. That keeps
the four Gaussian wrapper targets and Poisson formal-admission task while
dropping held-smoke and diagnostic-only count rows.

## Slice 1818 Correlation-Block Workflow Plan

Slice 1818 adds `phase18_correlation_block_workflow_plan()`. The helper filters
the registry to `workflow_lane == "correlation_blocks"`, excludes blocked and
design-only rows, and adds an explicit `interval_policy` column so residual
`rho12`, q=2 `corpairs()` rows, and q=4 diagnostic rows cannot be collapsed
into one interval-ready bucket.

The current correlation-block plan has six rows:

- three `ready_grid` rows routed through `interval_heavy_summary`: Gaussian
  `mu`/`sigma` q=2 mean-scale covariance, residual `rho12`, and selected
  bivariate Gaussian q=2 `corpairs()` rows;
- one structured Gaussian q=2 row marked `needs_wrapper_target` with
  `workflow_helper = "correlation_block_wrapper"`;
- two q=4 rows marked `diagnostic_wrapper_target` with
  `interval_policy = "q4_derived_interval_unavailable"`.

The count labelled q=2/q=4 covariance row is blocked and stays out of the
plan. Callers can set `include_diagnostic = FALSE` to drop q=4 diagnostic rows
and keep only direct or layer-specific q=2/residual work.

## Slice 1819 Family-Surface Admission Plan

Slice 1819 adds `phase18_family_surface_workflow_plan()`. This helper is the
executable version of the broad distribution table: it keeps admitted,
smoke-only, blocked, and design-only family rows visible by default, but labels
their status so reporting and dispatch do not blur them together.

The current family-surface plan has eleven rows:

- six admitted grid rows: Gaussian location-scale, zero-one beta fixed effects,
  positive-continuous fixed effects, Tweedie fixed effects, ordinal fixed
  effects, and meta-known-`V` Gaussian rows;
- one smoke-only row: NB2 `sigma` random intercepts;
- three blocked rows: zero-inflated or hurdle count random effects, Student-t
  `nu` random effects, and ordinal random effects;
- one design-only row: mixed-response bivariate families.

Blocked and design-only rows have no Actions task. Callers can set
`include_blocked = FALSE` to keep only admitted or smoke-only family rows for a
dispatch-oriented report.

## Slice 1820 Workflow Plan Bundle

Slice 1820 adds `phase18_structured_workflow_plan_bundle()` and
`phase18_structured_workflow_plan_counts()`. The bundle returns the registry
summary, the four plan tables, and a compact count table for reporting current
workflow coverage.

The current bundled count table is:

| Workflow plan | Rows | Existing Actions tasks | Wrapper targets | Diagnostics | Blocked | Design-only |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Random slopes | 9 | 8 | 1 | 0 | 0 | 0 |
| Structured dependence | 7 | 3 | 4 | 1 | 0 | 0 |
| Correlation blocks | 6 | 3 | 3 | 2 | 0 | 0 |
| Family surface | 11 | 7 | 0 | 0 | 3 | 1 |

This table is not a simulation result. It is the executable routing summary
for deciding which workflow wrapper, artifact audit, or design gate should run
next.

## Slice 1821 Dry-Run Printers

Slice 1821 adds dry-run formatters and printers for the structured workflow
plan bundle. `phase18_format_structured_workflow_bundle_dry_run()` returns a
character vector with the bundle count table and one compact table per workflow
plan. `phase18_print_structured_workflow_bundle_dry_run()` writes those lines
to the console or a file and returns them invisibly. The single-plan helpers
`phase18_format_structured_workflow_plan_dry_run()` and
`phase18_print_structured_workflow_plan_dry_run()` use the same table
formatter.

The printer is intentionally read-only. Its header says that no simulations,
GitHub Actions jobs, likelihoods, or status promotions are dispatched. It is a
pre-dispatch status view for Ada and Grace, not evidence that a model row has
been run.

## Autonomous Work Plan

| Can continue without supervision | Why it is safe |
| --- | --- |
| Maintain the registry and status table | It records existing evidence; it does not change model behaviour. |
| Add dry-run validators and report builders | They fail closed when a row is blocked or missing an Actions task. |
| Dispatch existing manual Actions tasks for small pilots | The workflows already run named tasks and upload auditable artifacts. |
| Download and audit artifacts, then update check logs and after-task notes | Artifact audits compare declared cells, replicate counts, warnings, intervals, and stop rules. |
| Add wrappers around admitted rows | Wrappers only call existing DGP, smoke, or grid helpers. |

| Needs explicit design before code | Why it should pause |
| --- | --- |
| New family likelihoods, such as COM-Poisson or skew-normal | New likelihoods require parameterization, simulation tests, docs, and family registry updates. |
| New formula grammar for direct-SD, structured slopes, or `gr(..., by = ...)` sugar | Grammar changes affect parsing, documentation, examples, and user expectations. |
| Non-Gaussian structured slopes or labelled q=2/q=4 count covariance | These change identifiability, covariance dimension, extractors, and interval targets. |
| Ordinal mixed models or inflation/hurdle random effects | These are family-specific likelihood changes, not workflow plumbing. |
| Treating q=4 derived correlations as interval-ready | Current rows intentionally expose unavailable interval status unless a direct or derived interval method is implemented and tested. |

## Team Roles For The Workflow Phase

Ada keeps the lane order and branch scope. Boole checks task names and formula
boundaries. Gauss and Noether check that a registry row does not claim a
likelihood or parameterization that is absent from source. Curie checks that a
row has the right simulation grain and MCSE target before it becomes formal.
Grace checks workflow inputs, artifact retention, and failure modes. Rose runs
the missing-cell audit before any status promotion. Florence joins once a
report or figure consumes the registry, because plots should show support
status and interval provenance instead of hiding unsupported rows.
