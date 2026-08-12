# Reader-workflow audit — ten applied analyses

## Purpose and boundary

This audit asks a narrower and more useful question than whether a model can
optimise: can an applied scientist start with a recognisable data structure,
fit a model using exported functions, inspect diagnostics, obtain a reportable
output, and be told the relevant limit before interpretation drifts? It is a
smoke audit on `origin/main` at `8a6557f22`, not a recovery study, coverage
campaign, or capability promotion.

The executable receipt is
[`2026-08-12-reader-workflow-smoke.tsv`](2026-08-12-reader-workflow-smoke.tsv).
It was made by `tools/run-reader-workflow-audit.R`, which generates its own
small fixtures, writes and reads each as CSV, calls only exported `drmTMB`
analysis functions after loading the development checkout, and retains
warnings/errors as the first blocking point.

## What ran

All ten workflows fit, ran `check_drm()`, and produced both a coefficient
summary and response-scale fitted output. Their total elapsed time was under
four seconds on this checkout. That is useful evidence that the public route
is mechanically connected; it does **not** make any interval calibrated,
promote a ledger cell, or establish that the small fixtures are representative.

| Reader question | Core public route | Honest uncertainty/reporting boundary |
| --- | --- | --- |
| Growth varies by habitat | Gaussian `mu` plus `sigma` | ordinary fixed-effect Wald output; `sigma` is residual SD |
| Counts have unequal effort | NB2 plus `offset(log(effort))` | rate effects and NB2 dispersion; no zero-inflation claim |
| Germination has denominators | beta-binomial `cbind(success, failure)` | ordinary fixed-effect output, not continuous-proportion analysis |
| Breeding condition is ordered | `cumulative_logit()` | fixed-effect category-shift output only; no public cutpoint profile target on main |
| Cover includes 0 and 1 | `zero_one_beta()` with `zoi`/`coi` | component-specific output; `coi` is conditional on a boundary |
| Trait follows phylogeny | Gaussian `phylo()` | inspect status before reporting structured-SD uncertainty |
| Sites are spatially related | Gaussian `spatial()` | projected coordinates; spatial target is status-led rather than generically interval-ready |
| Two traits covary | bivariate Gaussian with `rho12` | `rho12` is residual, not group/phylogenetic correlation |
| Effect sizes have known SEs | Gaussian `meta_V()` | known sampling variance plus between-study `sigma` |
| Responses are missing | `miss_control(response = "include")` | response masking is not general multiple imputation or an identified missingness mechanism |

## Findings: what is genuinely usable now

The basic exported route—`drmTMB()`/`bf()` or `drm_formula()`, `check_drm()`,
`summary()`, and response-scale `fitted()`—is connected across continuous,
count, denominator proportion, ordinal, boundary proportion, phylogenetic,
spatial, bivariate, meta-analytic, and missing-response examples. The audit
also caught a real teaching detail: a spatial formula must be wrapped in `bf()`
or `drm_formula()`; a bare formula is rejected. That is correct API behaviour,
but worth putting in the first spatial example rather than leaving readers to
discover it from an error.

No package defect surfaced in these ten small paths. A successful smoke fit is
not evidence for weakly identified structured targets; the limitations column
in the receipt is part of each workflow, not a footnote.

## Gap register

| Priority | Gap | Type | Why an applied reader feels it | Next bounded action |
| --- | --- | --- | --- | --- |
| P1 | Ordinal has no standalone biological workflow explaining cumulative cutpoints, fitted category probabilities, and the uncertainty boundary. | Documentation + missing public estimand | A reader can fit the model but cannot safely turn cutpoints into a reportable inference. | Land the separately reviewed ordinal-cutpoint interval work only after its own PR gate; then write one worked ordinal article. Until then, add a short fixed-effect ordinal workflow and state that cutpoint intervals are unavailable. |
| P1 | The phylogenetic tutorial teaches `fit$opt$convergence` and `fit$sdpars$mu` in its first route. | Documentation/API discipline | These are implementation fields, not the stable public analysis path. | Replace with `check_drm()`, `summary()`, `sigma()`, `ranef()`, and `profile_targets()` where appropriate. |
| P1 | The bipartite interaction article stops after fit/`ranef()`/target inspection. | Documentation workflow gap | There is no public diagnostic, interval-status, report-table, or figure endpoint in the article. | Add one honest point-estimate endpoint plus `check_drm()` and target-status table; do not invent an interval claim. |
| P2 | Count, robust, and denominator-proportion articles do not consistently show the same uncertainty-reporting handoff. | Documentation composition | Readers must infer how the general post-fit article applies to their family. | Reuse a six-line public reporting block: `prediction_grid()` → `predict_parameters(conf.int = TRUE)` → inspect `conf.status`/`interval_source` → `plot_parameter_surface()`. |
| P2 | Phylogenetic and spatial entry points are split across advanced articles. | Navigation/documentation | A first-time analyst has to choose an advanced mechanism before they see a minimal biological workflow. | Add “start here” links and label the first supported formula as the beginner route. |
| P2 | Structured correlation/SD intervals are deliberately target-specific, not blanket capabilities. | Scientifically unsupported request, not a bug | A reader may turn a clean Hessian or a finite computational interval into a stronger claim. | Keep status and interval provenance beside every structured output; do not widen evidence without a separately approved campaign. |
| P3 | `zoi`/`coi`, `rho12`, `sigma`, and `meta_V()` have easily confused meanings. | Interpretation/documentation | The model may be fitted correctly but described incorrectly in a paper. | Maintain component-specific plain-language captions in every figure/table template. |

## What should happen next

The useful sequence is documentation repair before another broad modelling
expansion:

1. Repair the three P1 reader paths (ordinal scope, phylogenetic public API,
   bipartite endpoint) as small independently reviewable changes.
2. Add the common post-fit reporting block to count, robust, and proportion
   articles, then render those articles and run the reader smoke receipt again.
3. Use this runner as a regression guard whenever a public formula/parser,
   diagnostic, or reporting accessor changes. Keep it a smoke test; it is not
   a substitute for the existing recovery and calibration ledgers.
4. Only then choose the next capability expansion from a real reader block.
   The strongest candidate is the separately scoped ordinal cutpoint interval
   work because it turns an already-fit ordinal analysis into a reportable
   estimand without pretending that structured ordinal inference is solved.

## What this does not establish

It does not certify coverage, random-effect recovery, spatial range estimation,
phylogenetic or bivariate correlation intervals, MNAR handling, response plus
`mi()` models, or any CRAN/release claim. Those remain governed by their
existing evidence and approval gates.
