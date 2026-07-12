# Ultra-plan: missing-response masking across all fitted drmTMB routes

**Status:** MR-T0 is merged; MR-T1 has an independent DONE verdict and is
awaiting its PR/Ubuntu gate for the shared contract and legacy six. The maintainer reports that the CRAN email confirmation is
complete. No missing-response family implementation has begun.

## 1. Outcome

Extend response-missingness handling from the six currently admitted routes to
all 18 user-visible fitted routes, while turning the capability surface into the
auditable execution board for the work.

The arc is complete only when every route has its own builder/kernel evidence,
sentinel-invariance test, output/accounting checks, and known-DGP recovery test.
A route never inherits a tick from its base family. Missing-response completion
does not promote `supported`, `inference_ready`, REML, structured-effect, interval,
or missing-predictor claims.

## 2. Scope and boundaries

### In scope

- The 18 fitted routes already shown on the capability surface:
  `gaussian`, `biv_gaussian`, `student`, `lognormal`, `gamma`, `poisson`,
  `nbinom2`, `zi_poisson`, `zi_nbinom2`, `truncated_nbinom2`,
  `hurdle_nbinom2`, `beta`, `zero_one_beta`, `beta_binomial`, `binomial`,
  `cumulative_logit`, `tweedie`, and `skew_normal`.
- Ignorable response missingness: the observed-data likelihood under MCAR, or
  MAR conditional on included observed variables with parameter distinctness.
- Fixed effects and at least one representative latent/random route where that
  route is already supported by the family.
- Full-length fitted values, `NA` residuals for missing responses, likelihood-row
  `nobs()`, and retained original row identity.

### Explicitly out of scope

- MNAR models or a missingness mechanism.
- New families, mixed-response bivariate families, or more than two responses.
- Response missingness combined with predictor `mi()`.
- Broadening missing-predictor support, bivariate `mi()`, or the pigauto bridge.
- Non-Gaussian REML; REML remains Gaussian-only.
- Promotion of interval or coverage evidence. Replicated coverage campaigns are
  a later, separately authorized inference lane.
- DRM.jl as an implementation dependency. Its cross-family tests are a useful
  parity inventory, but the R/TMB mask remains authoritative.

## 3. Baseline corrections before implementation

The current visual is useful but not yet safe as a tick ledger.

1. Correct `zi_poisson` and `zi_nbinom2`: the current surface says they inherit
   response-missingness support, but their builders explicitly reject the
   combination. Seed both as `rejected / planned`, not ✓.
2. Preserve the existing 668-cell model census, but do not multiply this arc into
   668 missingness cells. Add a separate 18-route `missing_response` axis.
3. Add immutable IDs. The current census axes contain 59 duplicate-key groups,
   so row position or the visible columns cannot be the identity.
4. Treat the six admitted routes as legacy implemented routes pending audit, not
   automatic final ticks. The four non-Gaussian routes do not consistently mask
   residuals, and the existing sentinel tests do not actually mutate the TMB
   response sentinel. Gaussian and bivariate Gaussian also need explicitly named
   missing-response recovery evidence.

## 4. The capability ledger

### Authoritative files

Create:

- `docs/dev-log/dashboard/capability-ledger/cells.tsv`: current state, one stable
  row per capability cell;
- `docs/dev-log/dashboard/capability-ledger/evidence.tsv`: one-to-many evidence;
- `docs/dev-log/dashboard/capability-ledger/transitions.tsv`: append-only state
  transitions;
- `docs/dev-log/dashboard/capability-ledger/schema.json`: enums, transition graph,
  and evidence requirements.

Generate, rather than hand-edit, the census projections, JSON widget data,
Markdown surface, HTML surface, pkgdown article/table, and tranche summaries.
Date-stamped surfaces may remain as archives; the canonical current surface
should have an undated generated filename.

### Orthogonal state fields

Each cell records three separate questions:

1. `capability_status`: `rejected_by_design | not_implemented | scaffolded |
   implemented`;
2. `work_status`: `backlog | designed | in_progress | implemented_unverified |
   verified | blocked | deferred`;
3. `evidence_gate`: `G0 | G1 | G2 | G3 | G4 | G5`.

The existing family inference tier remains a fourth, independent field.

### Gate meanings

| Gate | Meaning | Minimum evidence |
|---|---|---|
| G0 | Rejected or absent | specific front-door rejection and negative-neighbour test |
| G1 | Implemented | R builder/route, support-valid placeholder, full C++ row-density guard, starts from observed rows |
| G2 | Masking validated | observed-row likelihood identity, true sentinel mutation, objective/gradient parity, `nobs`/mask/fitted/residual contract |
| G3 | Recovery-grade | fixed-seed MCAR known-DGP recovery for every fitted distributional parameter; representative supported latent route |
| G4 | Interval-feasible | a finite correctly named interval at a known-DGP point; not a coverage claim |
| G5 | Inference-ready | archived replicated coverage evidence with MCSE and convergence accounting |

The visible **missing-response verified** tick appears at G3. G4 and G5 remain
visible as separate evidence badges and are not required to finish this arc.

Every transition records evidence IDs, commit, actor, date, claim boundary, and
next gate. Demotions are allowed and must update the generated visual immediately.

## 5. Implementation invariant

For an entirely unobserved response row,

\[
\log \int p(y_i \mid \theta, b)\,dy_i = 0.
\]

Each route therefore follows the same invariant:

1. The R builder validates only observed responses, retains rows with complete
   predictors, creates `observed_y`, uses a support-valid placeholder, and derives
   response-based starts only from observed rows.
2. A plain data-time `if (observed_y(i) == 1)` surrounds the **entire** row density
   and every unsafe transformation or mixture branch. Do not use `CondExp`.
3. The route enters the allow-list only with its focused tests and ledger
   transition.
4. Extractors preserve full row identity: fitted/predicted means may be returned
   for retained rows, but response residuals are `NA` where the response is
   missing and `nobs()` counts likelihood rows.

For a mixture route, a missing response supplies no evidence about component
membership; the complete mixture contribution is skipped.

## 6. Dependency-ordered tranches

### MR-T0 — ledger migration and truthful baseline

- Import all 668 existing model-surface rows without changing their counts.
- Resolve duplicate identities with an explicit immutable `cell_id` and
  `route_variant`.
- Add the 18 missing-response route rows.
- Seed current code truth, including G0 for both zero-inflated aliases.
- Build `tools/capability_ledger.py` and
  `tools/check-capability-runtime.R`.
- Regenerate Markdown, HTML, JSON, pkgdown inputs, and tranche summary from the
  ledger.
- Add a CI drift test and prove it fails after an intentional stale-artifact
  mutation.

**Exit:** unchanged 668-cell counts, exactly 18 missing-response routes, unique
IDs, no inherited alias tick, and zero hand-maintained headline counts.

### MR-T1 — shared contract and legacy-six audit

- Add a real sentinel oracle that directly mutates masked TMB response values;
  use family-aware valid alternatives for encoded responses.
- Route all univariate residual returns through the missing-response mask.
- Audit `gaussian`, `biv_gaussian`, `binomial`, `poisson`, `nbinom2`, and `beta`
  against G2/G3 instead of grandfathering them.
- Add named Gaussian and bivariate-Gaussian recovery tests.
- Preserve current rejections for response+`mi()` and explicit-missing REML.

**Exit:** the shared harness is trustworthy; each legacy route has an honest
gate, and the six-family count no longer hides extractor or recovery debt.

### MR-T2 — simple continuous routes

- `student`, `skew_normal`, `lognormal`, `gamma`.
- Student/skew-normal guard the complete standardized density calculation.
- Lognormal/Gamma prove that an invalid zero cannot leak into a taped `log(0)`;
  starts use observed positive responses only.

These four test-design slices may run in parallel after MR-T1, but integration
into `R/drmTMB.R`, `src/drmTMB.cpp`, and the route ledger is sequential.

### MR-T3 — semi-continuous and boundary mixtures

- `tweedie`, `zero_one_beta`.
- Mutate to genuinely different valid sentinels because zero is a legitimate
  response for both routes.
- Guard zero/one atom classification and all continuous-component calculations.

### MR-T4 — encoded finite-support responses

- `beta_binomial`: if either component of `cbind(success, failure)` is missing,
  the whole response row is missing; keep trials finite and aligned.
- `cumulative_logit`: preserve declared levels, guard before category conversion,
  and hard-error when the observed responses cannot identify fitted cutpoints.

### MR-T5 — truncated count base

- `truncated_nbinom2` with a positive placeholder.
- Guard the NB2 density and zero-truncation normalization together.

This tranche must reach G3 before the hurdle route begins.

### MR-T6 — explicit mixture routes

- `zi_poisson`, `zi_nbinom2`, then `hurdle_nbinom2` after MR-T5.
- Guard the whole structural-zero/count or hurdle/count mixture.
- Test missing zeros and missing positive counts separately.
- Recover every fitted mixture parameter; never inherit evidence from the base
  family.

### MR-T7 — consolidation and certification

- The 18-route runtime oracle and ledger agree.
- All route-specific G0 rejections have either advanced with evidence or remain
  explicitly blocked with a reason; no alias inherits silently.
- Full missing-response, missing-data-neighbour, and package suites pass.
- Documentation, NEWS, roadmap, check log, after-task report, capability surface,
  and pkgdown all regenerate from the same state.
- Local `document`, `--as-cran`, pkgdown, three-OS R-CMD-check, and the normal
  sanitizer workflow are green.

## 7. Verification at every tranche

### Per-route focused gate

- front-door positive and negative behaviour;
- equality to an explicit observed-row fit for coefficients, log likelihood,
  gradient, and observed-row fitted values;
- direct sentinel mutation invariance;
- row/mask/`nobs()`/fitted/residual contract;
- support and auxiliary-data edge cases;
- fixed-seed MCAR recovery of every fitted distributional parameter;
- one representative already-supported latent/random route where applicable.

### Integration gate

```r
devtools::test(filter = "missing-response")
devtools::test(filter = "missing")
devtools::test()
devtools::document()
devtools::check(args = "--as-cran")
pkgdown::check_pkgdown()
pkgdown::build_site()
```

Targets: all routine G0-G3 missing-response tests at most 45 seconds on the
reference machine and at most 60 seconds on a slow CRAN-like worker. Keep small
G2/G3 tests on CRAN unless measured platform evidence justifies moving only a
large recovery case to an explicit workflow.

### Independent final gate

- Rose: ledger/code/docs drift and demotion audit.
- Grace: package, pkgdown, CI, CRAN, and sanitizer audit.
- Fisher: recovery evidence and claim-boundary audit.
- Noether: likelihood, parameterization, and sentinel-domain alignment.
- Pat: capability page and missing-data article can be followed without hidden
  inheritance or ambiguous ticks.

## 8. Parallelism and compute

MR-T0 and MR-T1 are sequential foundations. After them, family-specific source
scouting, DGP design, and focused test authoring can run in bounded parallel
slices. Integration remains tranche-sequential because `R/drmTMB.R`,
`src/drmTMB.cpp`, the rejection matrix, and the ledger are shared hot files.

G0-G3 should remain local/CI-scale. Do not launch the proposed 14,400-fit
coverage campaign merely to finish missing-response support. If a later G5
campaign is authorized, use 3-seed plumbing, 25-seed smoke, then 400 seeds at
three sample sizes, with resumable artifacts, deterministic disjoint seeds,
`OPENBLAS_NUM_THREADS=1`, and no more than 90 Totoro workers or an appropriate
DRAC job array.

## 9. Release and git sequence

1. Keep submitted 0.5.0 frozen while its state is
   `submitted_awaiting_confirmation` or `submitted_awaiting_incoming`.
2. After CRAN acknowledgement, create a new post-release branch from synchronized
   `main`; bump to the decided development version before capability changes.
3. Land MR-T0 first. Each later tranche is a small reviewable PR with tests,
   ledger transitions, check-log evidence, and an after-task report.
4. Never describe 0.5.0 as accepted or on CRAN until the external CRAN state says
   so.

## 10. Decisions fixed by this plan

- “All families” means the 18 currently fitted user-visible routes, including
  three mixture aliases, not unfitted mixed-response combinations.
- The capability surface is the front end; the ledger is the source of truth.
- A route-level G3 tick means missing-response handling is verified, not that the
  family is generally inference-ready.
- Beta-binomial partial `cbind` missingness masks the whole response row.
- An ordinal category absent from the observed subset is a hard error for this
  first implementation.
- Missing mixture responses do not receive component-membership summaries.
- Fitted values remain available for retained missing-response rows; residuals
  are `NA` there.

## 11. Immediate next action

Review the generated ledger and capability page. The page now combines the
18-route execution board with the retained whole-package per-family map. If
Shinichi authorizes continuation, execute **MR-T1 only**: repair the shared
sentinel/residual/accounting harness and audit the six currently admitted routes
before implementing another family.
