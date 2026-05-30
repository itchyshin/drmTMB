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
