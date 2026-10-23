# Reader-facing article gap audit (Pat, PR 2 scoping)

Root checked: `.worktrees/external-oracle` (drmTMB 0.7.0, package rules apply — see
`AGENTS.md`/`CLAUDE.md`). Task: read the existing 37-vignette corpus and the
fail-closed reader-contract linter, then identify a genuinely new reader
journey for PR 2 rather than a fourth variation on an existing one.

## 1. Existing vignette inventory (37 rows, from `inst/reader-contracts/vignette-manifest.csv`)

Authoritative source: `inst/reader-contracts/vignette-manifest.csv:1-38` (37 data
rows + header). Titles pulled from each `.Rmd`'s YAML `title:` field
(`vignettes/*.Rmd:1-15`, one `grep` pass, 2026-08-14). "Dataset" column reports
what each vignette actually loads: with two exceptions every vignette builds
its own simulated data in-chunk via `set.seed()` + `rnorm()`/family-appropriate
generators (verified by `grep -c set.seed vignettes/*.Rmd` — every reader
vignette except `bivariate-nongaussian.Rmd`, `capability-and-limits.Rmd`,
`formula-grammar.Rmd`, `implementation-map.Rmd`, `julia-engine.Rmd`,
`large-data.Rmd`, `model-map.Rmd`, `source-map.Rmd`, `structural-dependence.Rmd`,
and `testing-likelihoods.Rmd` has at least one `set.seed()` call; those ten are
prose/reference articles with little or no simulation). No vignette reads a
CRAN or built-in real-world dataset such as `datasets::` or a package example
corpus.

| Vignette | Audience | Question it answers | Dataset |
| --- | --- | --- | --- |
| `drmTMB.Rmd` | reader | What is drmTMB and how do I fit a first model? | simulated |
| `capability-and-limits.Rmd` | reader | Can I fit and report this specific model/claim tier? | none (reference table) |
| `function-map-cheatsheet.Rmd` | reader | Which function do I call for which task? | none (reference) |
| `first-week-intervals.Rmd` | reader | How do I fit, profile, and read a boundary in week one? | simulated |
| `which-scale.Rmd` | reader | Am I modelling location, scale, shape, or coscale? | simulated |
| `distribution-families.Rmd` | reader | Which response family should I choose? | simulated |
| `model-map.Rmd` | reader | What can I fit today (coverage matrix)? | none (reference) |
| `implementation-map.Rmd` | reader | Where does grammar X live in the codebase? | none (reference) |
| `model-selection.Rmd` | reader | How do I compare models with AIC/BIC (incl. lme4 REML cross-check)? | simulated |
| `missing-data.Rmd` | reader | How does drmTMB handle missing predictors/responses? | simulated |
| `location-scale.Rmd` | reader | How do I model the mean and variance together (Part 1)? | simulated |
| `location-scale-scale.Rmd` | reader | How do I add a second scale parameter (Part 2)? | simulated |
| `bivariate-coscale.Rmd` | reader | How does `rho12` change residual coupling? | simulated |
| `bivariate-nongaussian.Rmd` | reader | Joint vs staged association for non-Gaussian bivariate pairs? | simulated (light) |
| `cross-family.Rmd` | reader | How do I model association between mixed-type outcome pairs? | simulated |
| `robust-student.Rmd` | reader | How do I fit a robust (Student-t-like) continuous response? | simulated |
| `count-nbinom2.Rmd` | reader | How do I model count abundance with extra zeros? | simulated |
| `proportion-beta-binomial.Rmd` | reader | How do I model proportions/success rates? | simulated |
| `meta-analysis.Rmd` | reader | How do I run random-effects meta-analysis with known V (incl. metafor cross-check)? | simulated |
| `model-workflow.Rmd` | reader | How do I check and use a fitted model day-to-day? | simulated |
| `distributional-outputs-and-adequacy.Rmd` | reader | How do I judge distributional adequacy of a fit? | simulated |
| `convergence.Rmd` | reader | What do errors/warnings/convergence diagnostics mean? | simulated |
| `large-data.Rmd` | reader | How does drmTMB behave/scale on large data? | simulated (large N) |
| `figure-gallery.Rmd` | reader | What do drmTMB's plotting helpers produce? | simulated |
| `structural-dependence.Rmd` | reader | Overview: what structured-dependence options exist? | none (reference) |
| `animal-models.Rmd` | reader | How do I fit an animal model with additive relatedness? | simulated response + `data(A)` |
| `phylogenetic-models.Rmd` | reader | How do I fit phylogenetic mixed models? | simulated |
| `bipartite-phylogenetic-interactions.Rmd` | reader | How do I model two-tree (bipartite) phylogenetic interactions? | simulated |
| `spatial-models.Rmd` | reader | How do I fit coordinate-spatial structured effects? | simulated |
| `relmat-known-matrices.Rmd` | reader | How do I use a known relatedness matrix with `relmat()`? | simulated response + `data(K)` |
| `phylogenetic-spatial.Rmd` | reader | Structural-dependence implementation details | simulated |
| `julia-engine.Rmd` | reader | What is the (future) Julia engine's status? | none (reference) |
| `testing-likelihoods.Rmd` | contributor | How are likelihoods verified against brute force? | simulated |
| `simulation-plot-grammar.Rmd` | reader | What is the shared grammar for simulation-check plots? | simulated |
| `formula-grammar.Rmd` | reader | What is the formula grammar (`bf()`, `~`, `sd()`, ...)? | none (reference) |
| `adding-families.Rmd` | contributor | How do I add a new distribution family? | simulated |
| `source-map.Rmd` | contributor | Where does each implemented model live in source? | none (reference) |

## 2. Gaps: questions a reader currently gets no answer to

- **No live, in-vignette cross-fit against a familiar package for the common
  applied cases.** `glmmTMB(...)` is never actually *called* anywhere in the
  37-vignette corpus — only mentioned in prose (`vignettes/capability-and-limits.Rmd:155`,
  `vignettes/convergence.Rmd:701`) as a claim about an internal dev-log check the
  reader cannot see or rerun. `betareg` is never mentioned at all (checked
  `grep -rn betareg vignettes/*.Rmd` — zero hits), even though
  `proportion-beta-binomial.Rmd` is exactly the use case betareg owns. `nlme`
  and `brms` are likewise never invoked. Only two vignettes run a real
  comparator fit: `meta-analysis.Rmd:228-242` (`metafor::rma()` ML cross-check)
  and `model-selection.Rmd:143-157` (`lme4::lmer(REML=TRUE)` logLik match).
  Both are narrow, single-parameter checks (intercept-only meta-analysis;
  Gaussian REML logLik), not a worked comparison on a distributional-regression
  model (heteroscedastic mean+variance, or a random-slope GLMM) where
  `drmTMB`'s actual value proposition (joint location+scale+shape formulas)
  diverges from what `glmmTMB`/`lme4` offer at all.
- **No real dataset anywhere.** All 37 vignettes (bar `data(A)`/`data(K)`
  relatedness matrices) simulate their own data from a known truth. A reader
  who wants to see drmTMB used on a dataset they can independently look up (a
  built-in R dataset, or one shared with a familiar package's own vignette)
  has no such article. This matters specifically for trust-building: recovering
  a *known* simulated parameter is a different claim from reproducing a
  *published* applied result.
- **No "does drmTMB agree with the package I already trust, on the model I
  already fit" journey.** The existing corpus is organized by drmTMB's own
  capability surface (families, structured RE, bivariate, workflow). None of
  the 37 articles is organized around "take a `glmmTMB`/`lme4` model you
  already know, refit it in drmTMB, and see the numbers line up" — which is the
  question a reader coming *from* those packages actually has before trusting
  a new one.

## 3. Where a side-by-side would genuinely reduce reader uncertainty

- **Heteroscedastic Gaussian (location-scale) vs `glmmTMB` `dispformula`.**
  `glmmTMB` supports `dispformula = ~x` for Gaussian sigma-regression; a
  side-by-side on the same simulated (or real) data against
  `location-scale.Rmd`'s existing model class would let a reader already
  familiar with `glmmTMB` verify drmTMB's `sigma ~` formula reproduces the same
  fit, then see what drmTMB adds (a second scale parameter, coscale, structured
  RE on `sigma`) that `glmmTMB` cannot do at all. This is the single highest-
  leverage comparison because location-scale is drmTMB's stated differentiator
  from `gllvmTMB`/`glmmTMB` (`CLAUDE.md` Project Identity).
- **Random-intercept/slope GLMM vs `glmmTMB`/`lme4`.** `capability-and-limits.Rmd:155`
  already *claims* binomial REML random-intercept SD agreement with
  `glmmTMB(REML=TRUE)`, but the reader cannot see or rerun that check — it is a
  table cell citing an internal diagnostic. A reader-facing vignette that
  actually calls `glmmTMB()` and `drmTMB()` on the same simulated grouped-binomial
  data and prints both SD estimates side by side would convert an assertion
  into a reproducible fact for the reader (also fixes a documentation
  smell: prose asserting an unshowable comparison).
- **Beta regression (mean-precision) vs `betareg`.** `proportion-beta-binomial.Rmd`
  covers proportions but never checks against the package (`betareg`) that
  owns that exact model class in the applied literature. A reader coming from
  `betareg::betareg()` has no anchor.
- **Meta-analysis vs `metafor`.** Already covered (`meta-analysis.Rmd:228-242`)
  — do not duplicate.

**Recommendation for PR 2:** a new vignette built around one or two worked
side-by-side comparisons against `glmmTMB` (heteroscedastic Gaussian
location-scale, and/or grouped-binomial random-intercept REML) is the
genuinely new journey. It is distinct from all four "variation" candidates
(another family tutorial, another structured-RE article, another workflow
article, another reference table) because none of the 37 existing articles
lets a reader *watch* a familiar-package fit and a drmTMB fit run side by side
on the same data.

## 4. Fail-closed linter requirements for a new vignette

Source: `tools/check-reader-contracts.R` (full read, 2026-08-14).

### 4a. Forbidden vocabulary (private-field vocabulary), enforced in **prose and code alike**

`tools/check-reader-contracts.R:6-8` defines the forbidden field list:

```r
reader_contract_private_fields <- c(
  "opt", "sdr", "sdpars", "corpars", "optimizer_used", "optimizer_attempts",
  "obj", "model", "missing_data", "random_effects"
)
```

The scanner (`reader_contract_private_accesses()`, `tools/check-reader-contracts.R:96-141`)
matches three patterns per source line, all case-sensitive on these exact
tokens:

1. `$field` access on any object name (`dollar_pattern`) — e.g. `fit$opt`,
   `x$sdr`, `arbitrary_name$sdpars$mu`. Object name is irrelevant; only the
   field name after `$` matters.
2. `[["field"]]` bracket access (`bracket_pattern`) — e.g. `x[["sdpars"]][["mu"]]`.
3. **A bare or backticked mention of the field name immediately followed by `$`
   or `[[`** (`route_pattern`, `tools/check-reader-contracts.R:106-109`) — e.g.
   prose that writes `` `sdpars`$mu `` or `random_effects[["sigma"]]` without
   ever writing `fit$sdpars`. This is what makes it a prose-and-code rule, not
   just a code-chunk rule: the comment in the source
   (`tools/check-reader-contracts.R:103-105`) states the rationale explicitly —
   prose can label a private component directly (`sdpars$mu`) without ever
   spelling `fit$sdpars`, and that must still be caught. Plain prose that only
   says "the model" (no following `$`/`[[`) is NOT flagged — the pattern
   requires the extraction operator to follow.

So a new vignette (reader audience) must never write, in either a code chunk
or narrative Markdown text, any of `opt`, `sdr`, `sdpars`, `corpars`,
`optimizer_used`, `optimizer_attempts`, `obj`, `model`, `missing_data`,
`random_effects` immediately followed by `$` or `[[`. Public accessors
(`summary(fit)$parameters`, `summary(fit)$covariance`, `ranef(fit)$terms`,
etc.) are unaffected — the field names inside those are not in the forbidden
list (verified: the linter's own test fixture asserts these pass,
`tests/testthat/test-reader-vignette-contracts.R` around the
"public summary and ranef fields are accepted" test).

For a `glmmTMB`-comparison vignette specifically: comparator-package objects
are not exempt by name — if a `glmmTMB` fit object is ever named `fit`, `mod`,
or similar and a chunk or prose writes `fit$obj`, `fit$model`, etc., the
scanner still flags it (patterns are field-name-driven, not object-name-driven,
per the doc comment at `tools/check-reader-contracts.R:2-4`). This is unlikely
to bite naturally (glmmTMB's own object doesn't expose fields named `opt`,
`sdpars`, etc.), but the same discipline that already applies to the drmTMB
fit object applies to any object in the vignette.

### 4b. The four coupled edits a new vignette needs

1. **The `.Rmd` itself** — `vignettes/<new-name>.Rmd`, reader-audience prose/code
   obeying §4a.
2. **`_pkgdown.yml` articles entry** — add the vignette's basename (no `.Rmd`
   extension) under one `articles:` `contents:` block (`_pkgdown.yml:232-320`).
   The existing structure is 10 topic sections; a comparison-focused vignette
   would fit most naturally as a new entry in "Model Checking and Practical
   Workflow" (`_pkgdown.yml:257-263`) or as a new top-level section — either is
   a genuine choice, not dictated by the linter.
3. **`inst/reader-contracts/vignette-manifest.csv` row** — one new row,
   `vignette,audience,permitted_private_fields,rationale`. For a reader
   vignette: `audience = "reader"`, `permitted_private_fields = ""` (empty —
   reader rows must have zero declared private fields;
   `tools/check-reader-contracts.R:210-215` fails closed if a reader row
   declares any). `reader_contract_lint()` (`tools/check-reader-contracts.R:145-152`)
   fails with "Missing manifest row(s)" if this row is absent, so this edit is
   mandatory the moment the `.Rmd` file exists in `vignettes/`.
4. **The hard-coded row count in `tests/testthat/test-reader-vignette-contracts.R`** —
   the final test, "the live corpus has the complete immutable manifest"
   (`tests/testthat/test-reader-vignette-contracts.R`, last `test_that` block),
   asserts `expect_equal(nrow(manifest), 37L)` against the live
   `inst/reader-contracts/vignette-manifest.csv`. Adding vignette #38 requires
   bumping this literal `37L` to `38L` in the same change, or the test fails
   even though the linter itself (`reader_contract_lint()`) would pass. This
   file is not in the five byte-pinned hard-constraint files for this task, so
   it may be edited, but it is a distinct required edit from the manifest CSV
   — both must move together.

No other file needs to change for a purely additive vignette: the linter has
no other list of vignette basenames to update, and
`private-access-exceptions.csv` only needs an edit if the new vignette needs a
documented reader-facing exception (e.g., a "this field is intentionally
unavailable" explanatory clause like `large-data.Rmd`'s `fit$obj` exception,
`tools/check-reader-contracts.R:24-38`) — ordinary comparison prose calling
`glmmTMB()`/`lme4::lmer()` and reading their public output should need none.

## Evidence trail

- Manifest: `inst/reader-contracts/vignette-manifest.csv:1-38` (37 rows).
- Vignette count: `ls vignettes/*.Rmd | wc -l` → 37.
- Titles: `grep -E '^title:' vignettes/*.Rmd` (2026-08-14 pass).
- Dataset check: `grep -oE 'data\("?[a-zA-Z_0-9]+"?\)' vignettes/*.Rmd` (only
  `animal-models.Rmd` → `data(A)`, `relmat-known-matrices.Rmd` → `data(K)`);
  `grep -c set.seed vignettes/*.Rmd` for the simulated-data confirmation.
- Comparator-package usage: `grep -rlE "glmmTMB|lme4|metafor|betareg|nlme::|brms" vignettes/*.Rmd`
  (10 files mention at least one name); `grep -n "glmmTMB(" vignettes/*.Rmd`
  (zero live calls, only prose at `capability-and-limits.Rmd:155` and
  `convergence.Rmd:701`); `grep -rn betareg vignettes/*.Rmd` (zero hits);
  live comparator calls confirmed only in `meta-analysis.Rmd:228-242`
  (`metafor::rma()`) and `model-selection.Rmd:143-157` (`lme4::lmer(REML=TRUE)`).
- Linter: `tools/check-reader-contracts.R` (full file read).
- pkgdown articles structure: `_pkgdown.yml:232-320`.
- Test count assertion: `tests/testthat/test-reader-vignette-contracts.R`,
  final `test_that("the live corpus has the complete immutable manifest", ...)`
  block, `expect_equal(nrow(manifest), 37L)`.
