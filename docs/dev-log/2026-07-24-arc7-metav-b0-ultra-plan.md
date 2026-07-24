# Arc 7 B0 — `meta_V` B3 integration and evidence audit

```text
🎯 GOAL
PLATFORM: Codex.
Deliver Arc 7 B0 as a clean, current-main integration and audit of the existing
meta_V B3 evidence. HEADLINE: retain the negative small-K heterogeneity-interval
result honestly, making the tested ML meta_V contract reproducible without
claiming interval validity or coverage. IN PARALLEL: contract classification and
claim-surface review. DEFER: a new estimator, profile/bootstrap interval method,
remote campaign, tier promotion, public performance claim, Julia, and CRAN.
DISCIPLINE: isolated origin/main worktree; all-attempt denominator; two-cell
local sentinel; Fisher/Rose review; after-task report and clean closeout.
```

## What the brain and repository already know

`meta_V()` is already an implemented Gaussian known-sampling-covariance route,
with DGP, writer, comparator tests, and a reader vignette. It is not a new
family or a new public API. The current main ADEMP was insufficient for an
interval claim: it used `n_study = 36, 72`, named a point `sigma(fit)` extractor,
and proposed only 500 formal repetitions.

The unmerged `codex/meta-v-b3-contract` branch is evidence, not a merge base:
it is 13 commits ahead and 42 commits behind the approved `origin/main`
baseline `d7359df2`. Its retained B3 campaign has 16,800 attempts, including
3,712 `sigma` Wald intervals recorded as `degenerate_zero_infinite`. The
all-attempt finite-and-covering rate is 0.4117--0.8900. This is negative
evidence against a Wald heterogeneity-interval claim over the tested small-K
domain; conditional-on-finite summaries are retained but cannot replace the
primary denominator.

## Prior-work sweep receipt

| Surface | Evidence | Finding | Call |
| --- | --- | --- | --- |
| Current repository | `git fetch origin main`; `origin/main=d7359df2`; `git worktree add -b codex/arc7-metav-b0 /private/tmp/drmtmb-arc7-metav-b0 origin/main` | Arc 6 is merged and its main R-CMD-check/pkgdown workflows are green. The primary checkout is a dirty foreign AGHQ/REML lane. | Work only in this isolated worktree. |
| Existing implementation | `docs/design/48-phase-18-meta-v-ademp.md`; `inst/sim/*meta_v*`; `tests/testthat/test-phase18-meta-v-*.R`; `vignettes/meta-analysis.Rmd` | Existing DGP, runner, writer, comparator tests, and vignette are reusable. | Reconcile; do not build an estimator or new article. |
| Existing B3 branch | `git log origin/main..codex/meta-v-b3-contract`; `git diff --stat origin/main...codex/meta-v-b3-contract`; branch after-task report | A large branch has the intended B3 contract and a retained negative campaign but is stale and bundles unrelated Arc 6 material. | Selectively port reviewed changes; never merge wholesale or repeat the campaign. |
| Twin/sister | `git -C DRM.jl log --all -- src/gaussian_meta.jl` | DRM.jl has the known-V route but no drmTMB small-K ADEMP interval gate. | No algorithm to co-opt. |
| Brain | `basic-memory tool search-notes "drmTMB meta_V B3 small K 12 heterogeneity interval coverage next arc" --hybrid`; local vault fallback | Prior trust evidence confirms comparator parity; no later positive interval result supersedes B3. | Preserve the negative boundary. |

**Verdict:** resume and reconcile the existing B3 contract; the genuine gap is
an honest, current-main evidence boundary, not an unimplemented `meta_V`
feature.

## Decisions locked

- Estimand: Gaussian ML `bf(yi ~ x + meta_V(V = V), sigma ~ 1)` only.
- Interval evidence: record the actual `confint(..., method = "wald")` result
  for `sigma`; a point estimate or a conditional finite-interval summary cannot
  substitute for a primary all-attempt rate.
- Boundary: include the K=12 vector sentinel and a K=36 dense control.
- No remote compute in B0. The existing 16,800-attempt campaign is retained as
  negative evidence; a new campaign requires a separately approved new
  estimand or interval procedure.
- No capability tier, public performance, CRAN, Julia, REML, `sigma ~ x`,
  profile/bootstrap, non-Gaussian, proportional/relatedness, or arbitrary dense
  covariance claim.

## Slice table

| Slice | Member / model / effort | Dispatch | Output | Dependency |
| --- | --- | --- | --- | --- |
| S0 reconciliation inventory | Ada / Sol / high | native orchestration | selective file-and-claim map in this plan/check-log | complete prior sweep |
| S1 contract port | Ada / Sol / high | native orchestration | bounded source, tests, ADEMP, compact B3 evidence | S0 |
| S2 local sentinel | Curie / Terra / medium | native explicit | two retained local results and manifest inspection | S1 |
| S3 claim review | Fisher + Rose / Terra + Sol / high | native explicit | inference/scope verdicts | S1--S2 |
| S4 closeout | Rose / Terra / medium | native explicit | after-task report, check-log, handoff | S3 |

Luna suitability: no. The remaining work crosses the package's simulation
contract, historical evidence provenance, and public-claim boundary; a cheap
mechanical scan already completed in the prior-work receipt. No ultra effort or
remote compute is authorized.

## Verification and closure

Run focused `meta_V` DGP/runner/summary/comparator tests plus the two-cell
sentinel. Re-read every `meta_V`, `sigma` interval, and coverage claim on the
changed reader and design surfaces. Fisher and Rose must agree that the landing
does not promote the route. Close with a single scoped PR, after-task report,
and a handoff that names the next decision: a separate interval-method arc, if
one is desired.

## Team raised

- **Fisher:** B3 is NO-GO for a new campaign or inference claim; the all-attempt
  result is the scientific output. Reconcile it before considering a new method.
- **Rose:** update Mission Control only after plan approval; do not touch the
  dirty primary checkout or merge the stale B3 branch wholesale.
- **Ada:** B0 should end after an honest current-main evidence integration; a
  profile/bootstrap method is a different research arc.

## Questions still open

None for B0. A later decision is needed only if the maintainer wants to develop
and validate a new heterogeneity-interval procedure.
