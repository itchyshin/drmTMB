# 🎯 GOAL: CMR support in drmTMB and native DRModels.jl

```text
OWNER: Codex, with Ada coordinating.
DELIVERABLE: reviewable native implementations in both packages, independently
verified likelihoods, usable prediction/simulation, honest inference, tutorials
and retained evidence.

HEADLINE: exact first-capture-conditional Cormack–Jolly–Seber (CJS) models.

FOLLOW-ON: shared site/year effects; persistent individual effects;
predictor-dependent random-effect SDs; reference-cohort selection correction.

PARALLEL: independent R/TMB and Julia implementations after the mathematical
contract is frozen; research, fixtures and documentation in separate leaves.

DEFER: full population abundance, unknown entry/recruitment, unseen-animal
augmentation, survival–detection correlation, shared-plus-individual effects,
and reference selection combined with shared effects.

METHOD: ultra-plan for orchestration; unlazy for acceptance; symbolic alignment
for equations, data generation, fitting and recovery.

FINISH LINE: every required stage passes its declared gates. A simpler successful
stage does not silently replace the full programme.
```

This replaces the previous plan completely. It specifies the named team, model routing, dispatch mechanism, dependencies, acceptance commands, compute boundaries and closure.

## 1. Orientation, decisions and prior-work receipt

| Required ultra-plan item | Recorded position |
|---|---|
| **What the brain already knows** | Repository ownership, independent verification, exact-artifact evidence, compute limits and explicit publication boundaries govern execution. |
| **What Shinichi told us** | General ecology tool; broad Ranga research; multi-day programme; full staged heterogeneity; reference-cohort selection now; full population later. |
| **What the team raised** | The selection denominator must enter derivatives; ordinary-binomial Hessian assumptions do not transfer; 500 replicates are screening evidence; zero-SD inference needs separate treatment. |
| **Ada’s recommendation** | One programme with independently closable milestones. Research and specification precede implementation. Preserve validated simpler routes when a later route fails. |
| **Decisions locked** | Native implementations, dedicated CJS interfaces, ML, exact discrete-state summation, declared integration targets, individual-only reference selection. |
| **Questions still open** | No user preference blocks execution. Runtime, approximation accuracy and empirical identification remain measured outcomes, with prescribed failure actions below. |

**Sweep receipt**

- **Repositories:** `git status`, main identities, all-ref history/name searches, source searches and live CJS issue searches found no existing CJS implementation within their search scope.
- **Twin reuse:** design matrices, factor schemas, optimization controls and diagnostic helpers are reusable selectively. Ordinary response likelihoods, bootstrap dispatch and GLMM Hessian formulas require CJS-specific paths.
- **Brain:** vault search plus deterministic searches of decisions, work logs and research registries found no directly reusable CJS decision or implementation.
- **External methods:** CJS and mixed CJS are established. The programme makes integration and implementation claims, with no novelty claim.
- **Verdict:** build the missing CJS capability; do not rebuild ordinary-family infrastructure.

**Lane receipt:** preflight reports foreign activity and other Codex lanes. Both current checkouts contain work belonging elsewhere. Create isolated worktrees from freshly verified main identities; preserve those checkouts and untracked files.

**Runtime receipt:** the local catalogue exposes `gpt-6.1-sol`, `gpt-6-luna` and `gpt-6-astra` with the efforts used below. The current usage response reports 17% weekly usage; a second window is unavailable.

## 2. Named agents, models, efforts and dispatch

Personas provide the charter. Each actual job receives an explicit model, effort, ownership, tool grant and short brief.

| Agent / perspective | Responsibility | Model and effort | Dispatch |
|---|---|---|---|
| **Ada** | Scope, scientific decisions, dependencies, integration and approval boundaries | **GPT-6.1 Sol, high** | Parent coordinator |
| **Shannon / Ebbinghaus** | Lane census, prior-work refresh, provenance and existing evidence | **GPT-6 Luna, low** | Enforced CLI scout |
| **Ranganathan, with Pólya’s lens** | Two curated evidence corpora, cited synthesis and verified research findings | **GPT-6 Luna, medium** | Enforced CLI, external research tools |
| **Boole** | CJS data/formula contract; validation and actionable errors | **GPT-6 Luna, medium** after Ada freezes the contract | Bounded implementation leaf |
| **Hopper / Lovelace** | R preparation, TMB wiring, R methods and final bridge admission | **GPT-6 Luna, medium** | R-only implementation leaf |
| **Noether** | Native Julia kernel and difficult integration/derivative machinery | **GPT-6.1 Sol, high** | One bounded ceiling producer per milestone |
| **Fisher** | Inference specification; profiles, bootstrap accounting and eligibility rules | **Sol high** for Ada’s design decisions; **Luna medium** for specified implementation | Design in parent; bounded worker |
| **Curie** | Independent generators, fixtures, pilots, recovery campaigns and summaries | **GPT-6 Luna, medium** | Enforced CLI; controlled compute |
| **Pat / Florence** | Matched tutorials, interpretation, rendered figures and reader checks | **GPT-6 Luna, medium** | Documentation-only leaf |
| **Karpinski / Grace** | Numerical/performance instrumentation, package checks, docs builds and offline CI fixtures | **GPT-6 Luna, medium** | Verification leaf |
| **Rose** | Claims, capabilities, neighbouring material and licensing audit | **Luna medium** for inventories; **Sol high** for a consequential verdict | Fresh completion reviewer |
| **Melissa** | Scope, routing, evidence, safety, claims and handoff reconciliation | **GPT-6 Luna, medium** | Separate closeout leaf |
| **Independent adversary** | Selection normalization and derivative challenge | **GPT-6 Astra, high** | Fresh, narrowly bounded selection review |

**Why Noether gets Sol:** CJS history dependence, inner-mode differentiation and selection-normalized integration are load-bearing mathematical work. Routine validation, methods, docs and test execution remain Luna work. If a Luna leaf encounters an unspecified scientific decision, it returns that decision to Ada.

**Fan-out rules**

- Maximum **four active agents including Ada**; therefore at most three simultaneous children.
- Maximum **six new producer children per milestone**, including at most **one Sol/Astra ceiling producer**.
- Reuse a child for its slice and one repair follow-up. Start a fresh brief for a different slice.
- Completion panels are separate from producer budgets.
- Fresh briefs are the default. No full-history forks for execution.
- `reasoning_effort=ultra` is **off**. Jev is **off**.
- Audit actual dispatch receipts; a model written in a plan is not proof it ran.

Use the installed `codex-tier-batch.sh` with explicit model/effort columns, `--phase producer`, `--max-parallel 3` and `--require-scout` where applicable. Each milestone retains the TSV, brief, result, event stream and dispatch receipt. Run `codex-routing-audit.py` with the receipt directory and `--require-luna`.

Every worker brief contains: exact responsibility, allowed paths, input artifacts, output path, acceptance gates, time allowance and tool requirements. It also states: **other workers are present; preserve their edits; no nested delegation.**

## 3. Milestones, slices and dependencies

Times below are **staffing allowances**, not measured fit runtimes. The programme will span several working days. Compute estimates come from pilots.

| Milestone | Leaves and ownership | Dependency | Allowance |
|---|---|---|---|
| **M0: evidence and specification** | Shannon recon; Ranga corpora; Ada/Noether mathematical contract; Boole interface contract | Plan approval | 4–8 active hours |
| **M1: exact fixed-effects twins** | Boole validation; Hopper R/TMB kernel and fitter; Noether Julia kernel and fitter; Curie independent oracles | M0 acceptance | 8–16 active hours |
| **M2: usable fixed-effects models** | Fisher inference; Hopper/Noether prediction and simulation; Pat tutorials; Grace checks | M1 acceptance | 8–16 active hours |
| **M3: shared heterogeneity** | Hopper/Noether site effects, independent process pair, then year effects; Curie integration/recovery | M2 acceptance | 8–20 active hours |
| **M4: individual heterogeneity** | Noether integration design; Hopper/Julia builders; Fisher eligibility; Curie recovery | M2 acceptance | 8–16 active hours |
| **M5: SD predictors and reference selection** | SD-formula leaves; selection-normalized kernels; Curie selection generator; fresh Astra challenge | M4 and relevant M3 acceptance | 10–24 active hours |
| **M6: integration and closure** | Hopper fixed-effects bridge; Karpinski/Grace mechanical verification; Rose audit; Melissa reconciliation | Accepted implementation stages | 4–8 active hours, plus approved compute |

M3 and M4 may run concurrently when ownership and available slots permit. M5 selection depends on individual integration, not on completion of year effects. Documentation can follow accepted interfaces while recovery runs.

### M0: Ranga first, then freeze the contract

Create two focused notebooks within the broad campaign:

1. **Exact CJS:** conditioning, terminal confounding, intervals, masks, likelihood constants and comparator conventions.
2. **Heterogeneity and selection:** persistent/shared effects, quadrature/Laplace, reference-cohort selection, SD predictors and identification.

Curate primaries before expanding searches; inspect readability and deduplicate. Every load-bearing finding gets checked against its source. Deliver cited synthesis notes, notebook registration, report artifacts and audio/video attempts.

The last passive Notebook check reached the service but could not locate a CSRF token. Try the documented fallback. If unavailable, complete the primary-source synthesis locally and explicitly record unavailable notebook artifacts.

Freeze an alignment table linking each symbol to its data field, formula term, likelihood contribution, simulation draw and recovery extractor. Research findings that materially change the target return to Ada before implementation.

### M1–M2: exact, usable fixed-effects CJS

Add dedicated R `cmr_data()` / `drm_cjs()` interfaces and Julia `CMRData` / `cjs()` / `CJSFit`. Do not extend generic `bf()` with CJS parameters.

Both accept separate survival and detection formulas. Parameter-labelled Julia left sides require no dummy response columns. Preserve factor levels, contrasts, column names, offsets, units and training schemas.

The history object stores IDs, ordered occasions, masks, positive intervals, first captures and administrative endpoints. Reject malformed/all-zero histories and missing required predictors. Retain information-free final-first histories and terminal noncaptures.

Use logit unit-time survival \(s\), interval survival \(s^\Delta\), and logit occasion detection. Require constant predictors within intervals or explicit segmentation.

Write independent, stable two-state forward kernels in R/TMB-compatible C++ and Julia. Sum discrete states exactly. Structural impossibility returns minus infinity without an epsilon repair.

Provide process-specific coefficients, predictions, simulation, likelihood, diagnostics and guarded uncertainty. Reject unrestricted terminal time-specific survival/detection pairs; require an explicit constraint. The terminal product identification is documented in the [Stan CJS guide](https://mc-stan.org/docs/stan-users-guide/latent-discrete.html#mark-recapture-models).

### M3: shared effects

Implement, in order:

1. Site/group intercept on survival.
2. Site/group intercept on detection.
3. Independent intercepts on both processes.
4. Year effects, with separate repetition and identification evidence.

Integrate histories jointly under each shared effect. Use the actual CJS Hessian, with CJS-specific dense/block Laplace machinery and derivatives through the converged inner mode. Do not import independent-response `Z′WZ` assumptions.

Validate small shared-effect problems against independent low-dimensional integration before expanding dimensions. Retain inner-mode, Hessian and integration diagnostics.

### M4: persistent individual effects

Implement one effect on survival, one on detection, then an uncorrelated pair. Each individual receives one persistent draw across its entire history.

Use Gaussian quadrature with fixed nodes during each optimization. Select accuracy through order refinement between fits, avoiding changing quadrature rules inside an optimizer step. Check orders 25, 41, 65 and 97; refuse an accuracy claim if refinement fails at the cap.

One-dimensional and two-dimensional individual integrals are separate routes. Compare Laplace as an explicitly labelled approximation; quadrature remains available when Laplace is inadequate.

### M5: SD predictors and reference-cohort selection

Add process-specific `sd_phi` and `sd_p` formulas predicting **log random-effect SD**. Predictors must be constant within the effect’s unit. Test zero and nonzero slopes separately.

For reference selection, let \(w_i(b)\) be the probability of first capture at \(f_i\) from the declared eligibility time, and \(H_i(b)\) the subsequent CJS likelihood:

\[
L_i=
\frac{\int w_i(b)H_i(b)g_{\rm ref}(b)\,db}
     {\int w_i(b)g_{\rm ref}(b)\,db}.
\]

Differentiate numerator and denominator. Include pre-capture survival, surveyed nondetections and first-capture detection in \(w_i\).

Require known eligibility, an explicit alive-and-available reference assumption and complete prehistory predictors/masks. Use shared pre/post process coefficients; separate freely estimated pre-only coefficients are unsupported. Unknown origins and incomplete prehistory produce explicit errors.

This route conditions separately on each realized first-capture time. Final-first histories therefore contribute one. Reference predictions describe supplied covariate profiles; population averages also require a declared reference covariate distribution.

The [Sarzo, King and McCrea paper](https://academic.oup.com/biometrics/article-abstract/82/2/ujag086/8689490) establishes the relevance of survivorship selection. Its inaccessible full-text details are not treated as verified implementation instructions.

### M6: bridge and final integration

Admit **fixed-effects CJS only** through the R-to-Julia bridge after full history/design/conditioning transport and route-specific parity pass. Other CJS bridge routes retain explicit unsupported errors.

Native R and Julia support must work independently of the bridge.

## 4. Unlazy ledger and evidence gates

Create ignored `.unlazy/cmr/` state in each execution root. Store the mathematical contract, fixtures, reports and provenance in tracked evidence directories.

Each leaf declares disjoint `OWNS:` paths. Claim ownership before dispatch; a refused claim requires resequencing or narrower ownership. Shared exports, objective registration and generic-method integration belong exclusively to Ada’s serial integration leaf.

The following **new check runners are deliverables**, not commands claimed to exist already:

| Gate | Planned runner | Success marker |
|---|---|---|
| Data semantics and exact likelihood | R `tools/check-cmr.R --gate exact`; Julia `tools/check_cmr.jl --gate exact` | `CMR_EXACT_OK` |
| AD derivatives | Corresponding runner, `--gate derivatives` | `CMR_DERIVATIVES_OK` |
| Integration accuracy | `--gate integration` | `CMR_INTEGRATION_OK` |
| Selection normalization | `--gate selection` | `CMR_SELECTION_OK` |
| Cross-language fixtures | R runner, `--gate parity` | `CMR_PARITY_OK` |
| Recovery evidence | `--gate recovery --manifest <frozen-manifest>` | `CMR_RECOVERY_OK` |
| Existing regression checks | Repository-native tests/checks with retained logs | Exit zero and verified summaries |
| Docs/capability agreement | `--gate documentation` | `CMR_DOCS_OK` |

At setup, replace each ledger command with its exact interpreter, execution root, shell, environment and manifest. Ada reviews every command and called script before binding approval.

**Numerical gates**

- Reproduce all supplied short-history probabilities.
- Compare against independently enumerated states and suffixes.
- Test boundaries, masks, survival composition, administrative follow-up and covariate alignment.
- Prove intentionally wrong independent-binomial, first-capture-emission and omitted-suffix implementations fail.
- Exact probabilities: absolute/relative tolerance \(10^{-10}\).
- Aggregate R–Julia fixed-parameter likelihood: \(10^{-8}\).
- AD versus step-size-checked finite-difference gradients: \(10^{-6}\) at interior non-optimal points.
- Quadrature refinement: each log integral stabilizes within \(10^{-8}\), including both selection integrals.
- Zero-SD reduced models reproduce fixed effects.
- Independent frequency replication occurs after individual integration.

**Selection gates**

- Normalize over all post-capture histories in small problems.
- Recover ordinary integration when selection weights are constant.
- Verify final-first likelihood one and zero gradient.
- Generate eligible reference animals forward and retain them through simulated capture; do not use the fitted weighted distribution as the sole generator.
- Include a counterexample showing why shared-effect selection needs a joint normalization.

**Identification and approximation gates**

Numerical agreement does not establish identification. Examine profile shape, curvature, recovery and increasing information for each variance/SD-predictor target.

Compare matched likelihoods with pinned `marked` outputs. Compare Laplace against quadrature to measure approximation error, not to demand identical approximations. Any approximation failure remains visible and narrows that route’s status.

**Completion panels**

Fire once after candidate evidence exists:

- **M2:** two fresh Luna-medium reviewers for R and Julia usability/integration; one fresh Sol-high reviewer for likelihood/inference.
- **M3–M4 acceptance:** two Luna-medium reviewers for implementation/evidence; one Sol-high reviewer for integration and identification.
- **M5:** two Luna-medium reviewers for transport/tests; one Astra-high reviewer for selection normalization and derivatives.
- **M6:** two Luna-medium reviewers for regression/docs; one Sol-high Rose reviewer for claims and remaining limits.

Use `--phase completion`, exactly two build reviewers plus one ceiling reviewer. Re-run a panel only after material repairs.

## 5. Simulation, compute and qualification

Curie writes a frozen simulation manifest before fitting. Use literal shared datasets for cross-language comparisons; equal seeds are not assumed to produce equal draws.

**Core scenarios**

- Constant and covariate-dependent survival/detection.
- Short/long histories and low/high detection.
- Survey gaps, irregular intervals and terminal confounding.
- Group count varied separately from individuals per group.
- Individual survival, detection and two-component heterogeneity.
- Zero/positive SDs and zero/nonzero SD-predictor slopes.
- Weak/strong reference selection.
- Limited misspecification sentinels, reported as robustness limits.

Use reference-cohort generation for selection studies and marked-cohort generation for ordinary conditional studies. Allow selection-study capture layouts to vary; fit conditional on each realized layout.

**Three stages**

1. **Deterministic numerical checks**, before recovery.
2. **Ten pilot fits per candidate cell**, to measure runtime and partition failures.
3. **500-replicate screening**, followed by a separately frozen **2,000-replicate qualification campaign** for each primary route and inference claim.

The final campaign uses predetermined seeds and stopping rules. Do not repeatedly extend a run until it passes. Report Monte Carlo uncertainty following [Morris, White and Crowther](https://pmc.ncbi.nlm.nih.gov/articles/PMC6492164/).

**Qualification defaults for well-informed cells**

- Usable-estimate fraction: one-sided 95% lower confidence bound at least 95%.
- Survival/detection probability bias: its Monte Carlo interval lies within ±0.02 at declared covariate profiles \(x=-1,0,1\).
- Positive SDs of 0.5 or 1: relative-bias interval within ±20%.
- Zero-SD cases: report absolute error and boundary behaviour; do not apply relative-bias or ordinary two-sided interval rules.
- Nominal 95% coverage: its Monte Carlo interval lies within 92.5–97.5%.
- Report usable fraction, coverage among usable intervals, and usable-and-covering fraction among all attempts.

These are programme acceptance choices, not universal scientific thresholds. Stress cases describe limits. Failure of a well-informed primary cell blocks the corresponding qualification claim.

Wald, profile and bootstrap availability and calibration remain separate entries. Bootstrap accounting retains every attempted, converged and usable replicate. Bootstrap calibration requires its own approved nested-compute campaign.

**Compute routing**

- Mac: small tests/pilots, four Julia threads per lane, BLAS pinned to one.
- Totoro: CPU recovery campaigns, at most 150 cores in total, owned processes and retained outputs.
- No recovery campaigns on GitHub Actions.
- No GPU work is planned.

Before every fit, simulation or benchmark, state an estimate. Pilot timings supply the campaign estimate. A run above three hours requires displayed pre-run results and separate approval. An overrun stops and is re-estimated.

## 6. Approval, persistence and closeout

**G0 approval binds the agreed scope and commands.**

```text
PRE-AUTHORISED AFTER G0:
isolated worktrees; scoped implementation and tests; ordinary local builds;
small estimated pilots; checkpoints; local commits; reviewed gate commands.

REMOTE AUTHORITY:
none by default. Prepare exact issue/PR text and publication-ready evidence.
Request the required publication authority only when those artifacts are ready.

MUST STOP:
merge/release/public message; credentials or configuration changes;
foreign ownership conflict; destructive work; campaign above three hours;
material scientific/API expansion; or major engine restructuring.
```

During execution, keep safe reversible work moving. A blocked stage does not pause independent leaves.

At meaningful milestone closes, run the routing audit and efficiency gate. First compaction freezes scope to the current milestone; a second compaction or more than 25 guardian calls requires a durable checkpoint and fresh execution context. Never keep adding milestones to a large inherited transcript.

Each checkpoint records exact commits/worktrees, gate counts, active compute ownership, outstanding decisions, next command and a do-not-redo fence. Persist the approved goal and milestone state before execution; do not rely on chat history.

**Rose’s final audit** checks capability claims, GPL-to-MIT boundaries, neighbouring docs, unsupported errors, likelihood definitions and evidence provenance. No GPL R source is transplanted into Julia; share generated fixtures and mathematical contracts.

**Melissa’s reconciliation** records material differences across scope, evidence, model routing, safety, claims and handoff. Classify each as justified adaptation, unexplained drift or unresolved. No silently dropped leaf.

Final delivery includes:

1. Exact commits, final APIs and provenance in both packages.
2. Equations, conditioning and integration conventions.
3. Reproducible fixtures, comparator versions, commands and tolerances.
4. Recovery/coverage results with failures and denominators.
5. Matched runnable tutorials and inspected documentation.
6. Separate fitting, prediction, simulation and inference capability status.
7. Validated after-task reports and explicit pending publication/handoff state.

Run unlazy’s final `--reverify`; report measured met, unmet and abandoned counts. An abandonment remains a scope decision requiring disclosure, not a completion shortcut.

**Plan assessment:** self-reviewed as an implementation plan, perceived AI-like style 3/10 with moderate confidence. The dispatch table makes ownership checkable; the separation of numerical and statistical gates prevents a passing kernel test from becoming an inference claim. Science: reviewed by the fresh Astra challenge. Facts: catalogue and lane state checked this turn; repository architecture rests on the earlier bounded audit. References: cited support checked; inaccessible selection-paper details remain unverified.
