# drmTMB Full Audit — Handoff to the DRM.jl Coordination Team

**Date:** 2026-06-12
**For:** the team coordinating `drmTMB` (R) and `DRM.jl` (Julia)
**Type:** read-only, multi-perspective audit (no files changed)
**Produced by:** 13 standing review roles, via Claude Code

---

## 0. Read this first — scope and a critical caveat

This is a whole-package audit: **web articles + function docs + code** (architecture,
formula grammar, TMB likelihood/numerics, math-consistency, correctness, inference,
reproducibility/CRAN, figures, reference/learning-path). Each finding is tagged with a
standing-role author, a file:location, a severity, and a suggested fix. **Nothing was
edited.** Julia surfaces were reviewed and reported because this report goes to the team
that owns them.

**CRITICAL — what was audited:** the **current local working tree** (detached `HEAD` at the
`0.2.0` dev line, ~60 uncommitted files). This is **not** what the live site/`main` (0.1.4)
contains, and it is **not a committed state**. Two consequences the team must hold in mind:

1. **The local `0.2.0` tree has diverged from `main`.** The pkgdown build fixes that landed
   on `main` this session ([#535] index Julia topics + `cross-family`; [#536] strip internal
   `AGENTS`/`CLAUDE` pages) are **not in this local tree** — its `_pkgdown.yml` still lacks the
   Julia reference section, and `vignettes/cross-family.Rmd` / the `*.drmTMB_julia` man pages
   are absent locally while `R/julia-bridge.R` is present-but-untracked. **When the 0.2.0 line
   merges forward, those same pkgdown fixes must be carried over or the deploy breaks again.**
2. The compiled `src/drmTMB.so` on disk **predates** the modified `src/drmTMB.cpp`
   (Gauss/Grace). **Recompile (`devtools::document()` + build) before trusting any runtime
   check against this tree.**

Reviewers were told the tree is WIP; several findings may already be in-flight in open slices.

---

## 1. Fix-first (the HIGH items across all lenses)

| # | Author | Area | Item |
| --- | --- | --- | --- |
| 1 | Rose | Article/README | **False "CRAN release" install line.** `README.md:55–61`, `drmTMB.Rmd:30–34` say *"Install the CRAN release with"* `install.packages("drmTMB")` — package is **not on CRAN** → users get "not available". Use dev-install wording. |
| 2 | Gauss | C++ | **Silent NaN/Inf in q>2 covariance.** `src/drmTMB.cpp:3191-3192,207-208,252-253` use `.inverse()` + `log(.determinant())`; near a correlation/SD boundary this → -Inf/NaN poisoning nll & gradient. Use a Cholesky/`logdet` path. |
| 3 | Gauss | C++ | **Dense known-`V` MVNORM factorizes a possibly-non-PD `Omega`** (`src/drmTMB.cpp:3252,1892,3233`) → NaN with no diagnostic if user `V` is indefinite/PSD. Validate/repair `V` to PD on the R side, or detect the bad Cholesky. |
| 4 | Gauss | C++/R | **`pdHess = FALSE` does not block a `se = TRUE` fit from returning `status = "ok"`** (`R/drmTMB.R:401-440`); a caller reading `vcov()`/`fit$sdr$cov.fixed` gets a non-PD-Hessian covariance with no top-level warning. Record `pdHess` in fit-time state + warn once. |
| 5 | Emmy | API | **`drmTMB` vs `drmTMB_julia` extractor contracts silently diverge** — `sigma`/`corpairs.drmTMB_julia` return raw shapes vs the classed `drmTMB` returns; `predict.drmTMB_julia` silently narrows `type`; `summary.drmTMB_julia` is **missing** so `summary(julia_fit)` hits `summary.default`. Normalize shapes or abort explicitly + document the supported surface. |
| 6 | Emmy | API | **Link definitions are triplicated** (`family.R` `links=`, the `drm_dpar_link` switch `methods.R:4422-4453`, the `print.drmTMB` label switch) and must be hand-synced; the formula-derived `zi_poisson`/`hurdle_nbinom2` types have no constructor at all. Drive from one registry keyed by `model_type`. |
| 7 | Pat | Articles | **Getting-started inconsistency + two display-only articles.** `drmTMB.Rmd:81` uses `drm_formula()` while every other article uses `bf()` (no explanation); `convergence.Rmd:11` & `large-data.Rmd:11` are globally `eval = FALSE` so no example runs. |
| 8 | Darwin | Articles | **Four tutorials have weak/abstract biology** (`robust-student`, `bipartite-phylogenetic-interactions`, `spatial-models`, `bivariate-coscale`): generic `y ~ x`, unnamed organisms/units, no stated question or mechanism, and the advantage over the simpler fallback model is never articulated. |
| 9 | docs_writer | Fn docs | **`coef.drmTMB` (`methods.R:1826`) is a bare `#' @export`** with no title/params/return/examples; `drmTMB()` `@return` (`drmTMB.R:130`) is just "A `drmTMB` fit object" with none of the documented list slots. |
| 10 | Rose | README | **Stale pinned test count** — `README.md:239` "9,090 expectations" ≠ check-log `8,654`, and the suite keeps changing. Drop the literal integer. |
| 11 | Florence | Figures | **Axis labels inverted** in `figure-gallery.Rmd` bias panel (`simulation-operating-characteristics`, ~lines 2086-2087): "Estimate minus truth" lands on the parameter-name axis. Swap the `labs()` args (cf. `simulation-plot-grammar.Rmd:280`). |
| 12 | pkgdown_editor | Site | **`profile-likelihood` is reachable only from the articles index, not any navbar menu** (`_pkgdown.yml:207`) — a navigation black-hole. Add it to the `diagnostics:` menu. |

**Reassuring counterweight (verified solid):**
- **The likelihood math is correct.** Noether confirmed symbolic ↔ R ↔ C++ agree for all 10
  audited families (Gaussian, Student-t, lognormal, Gamma, NB2, Tweedie, beta, zero-one beta,
  skew-normal, biv_gaussian) — no link/precision-vs-SD/moment inversions.
- **Inference is disciplined.** Fisher found Wald SE / `vcov()` / CIs are hard-gated on
  `pdHess = TRUE`, and the heavy hedges (q8 "diagnostic not coverage/power",
  `pdHess=FALSE` unreliable, skew-normal weak `nu`) are applied consistently; no CI is
  advertised that identifiability forbids.
- **Local `R CMD check` is clean** (0 errors / 0 warnings / 1 harmless timestamp note); deps
  resolve; `JuliaCall`/`ggplot2`/`emmeans` are fully optional and guarded (Grace).

---

## 2. Code findings by lens

### 2A. Architecture & internal API — Emmy
Root cause for most of these: **there is no single document or schema for the `drmTMB`
fitted-object layout**, and `drmTMB`/`drmTMB_julia` share a method namespace with no shared
contract.

- HIGH — `sigma`/`corpairs.drmTMB_julia` return raw vectors/lists vs the classed,
  roundable `drmTMB_biv_sigma` / 21-col data frame (`julia-bridge.R:1042-1058,1090-1098`).
- HIGH — `predict.drmTMB_julia` accepts only `type="response"`, aborts on `newdata`, narrows
  `type` via `match.arg` (`julia-bridge.R:1066-1102` vs `methods.R:2096-2166`).
- HIGH — link defs triplicated; `drm_dpar_link` ignores `family$links` (see Fix-first #6).
- MED — `drm_family_type()` is a 90-line `inherits()`/`identical()` ladder; no family
  registry; every new family adds rungs in `drm_dpar_link`, `sigma`, `residuals`, `simulate`,
  `print` (`drmTMB.R:550-640`).
- MED — `simulate`/`residuals`/`sigma` are long per-family `if` chains with the **bivariate
  branch as an unlabeled fall-through** → an unknown future `model_type` silently routes into
  bivariate logic instead of erroring (`methods.R:2215-2511,2599-2799,2840-2869`).
- MED — non-parallel method sets; `summary.drmTMB_julia` missing → `summary.default`;
  `vcov.drmTMB_julia` returns only the fixed block (`NAMESPACE`, `julia-bridge.R:843-845`).
- MED — `is_converged.drmTMB_julia` ignores `include_hessian` (`julia-bridge.R:1061-1063`).
- MED — `confint` default differs by engine (tmb→wald, julia→profile).
- MED — Julia methods are bare `#' @export` with no `@rdname` → undocumented + this is the
  exact cause of the (now-fixed-on-`main`) pkgdown failure.
- LOW — inconsistent `.default` method discipline; `location` vs `mean` vocabulary
  (`predict-parameters.R` vs `methods.R`); `sdr`/`sdreport` duplicate fields.

### 2B. Formula grammar & R API — Boole
- MED — **LHS-as-dpar ambiguity**: an unnamed `bf(nu ~ x)` where `nu`/`zi`/`zoi`/`coi`/`hu`/
  `rho12` is a real response column is silently parsed as the *parameter* formula with no
  response (`parse-formula.R:48-53`). Warn/require explicit `mu = nu ~ x`.
- MED — **`nu` is overloaded** across three families: Student-t df (`logm2`), skew-normal
  slant (`identity`), Tweedie power (`logit12`) (`family.R:51-100,151-162`). Document the
  per-family meaning everywhere `nu` appears.
- MED — the named branch records the LHS as the response with **no validation**
  (`bf(mu = sigma ~ x)`, `bf(mu = sd(id) ~ x)` accepted) (`parse-formula.R:37-39`).
- LOW — `meta_V` rejects positional `V` while deprecated `meta_known_V` accepts it (alias is
  *less* strict than the preferred spelling, and stricter than `meta_V`'s own signature).
- LOW — `meta_known_V` can warn twice per model (no `.frequency="once"`).
- LOW — recognized vs documented `sd_*` vocabulary drift; `corpair(level="spatial")` parses
  then must be caught deeper; two reserved-name lists drift (`drm_known_dpars` vs
  `validate_random_mu_covariance_label`); duplicate-slope `(1 + x + x | id)` error text
  describes a different mistake; `gr()` deprecation doesn't map `cov` → `K`/`Q`.

### 2C. TMB likelihood & numerics — Gauss
(HIGH items 2–4 in Fix-first.)
- MED — raw `log(y)`/`log(1-y)`/`log(y)` in Gamma/beta/lognormal (`drmTMB.cpp:2106,2194-2195,
  2259-2260,2071`) → -Inf for boundary `y` from `simulate`/`newdata` even though the fit guard
  rejects them; mirror the `1e-12` floor used in the MI beta paths.
- MED — Tweedie power constrained to `(1,2)` (`type 16`) and fixed `1.5` for MI; Student-t df
  floored at 2 — both legitimate, both **undocumented constraints**.
- MED — skew-normal `log(skew_cdf + 1e-300)` (`drmTMB.cpp:2034`) creates a finite-but-huge
  gradient spike at large `|alpha|`; prefer a log-CDF. (reviewer confirmed: at `nu=-8,y=10`
  the floored log-density is `-705.6` vs exact `-924.2`.)
- MED — `obs_sigma = sqrt(V_known + sigma^2)` has no floor; `meta_V` with some `V=0` and
  `sigma→0` (a legitimate optimum) can underflow → Inf (`drmTMB.cpp:1880-1881,399`).
- MED — correlation guard constants (`0.99999999` residual vs `0.999999` RE) are scattered
  literals across C++ and three R files with no single source of truth.
- LOW — reported inverse-links use `1/(1+exp(-eta))`/`exp(eta)` (REPORT/fitted only, can
  overflow at extreme `eta`); MI `prior_norm` 0/0 guard; NB2 series branch overflow under AD
  for very large counts.

### 2D. Math consistency — Noether
**No wrong likelihood found.** Discrepancies are documentation-level:
- MED — beta/zero-one-beta apply a `1e-12` mean squeeze + `1e-8` shape floor in C++ that is
  **not stated** in `03-likelihoods.md` (the skew-normal floor already is). Document it.
- MED — Student-t doc "mean when `nu > 1`" understates the implementation (`nu>2` enforced,
  so `mu = E[y]` always) (`19-family-link-contract.md:23`).
- LOW — NB2 kernel variable named `alpha` (= `1/size`) invites misreading vs `dnbinom(size=)`;
  add a comment. `02-family-registry.md` "Required Fields" list is aspirational vs what the
  constructors actually expose — mark it as target schema.

### 2E. Correctness & tests — reviewer
Healthy tree; mostly low. Notables:
- LOW — `R/julia-bridge.R` is **1102 LOC, untracked, shipping in 0.2.0** (16 new S3 methods,
  `JuliaCall` in Suggests). Correctly scoped (gaussian/biv_gaussian only) and gated, but a
  large new surface for a release — a **release-scope decision** for the team.
- LOW — q8 (8-endpoint / 28-correlation) machinery is large but honestly held at
  `hold_diagnostic` (convergence 0.16–0.26, 0 usable Wald intervals) — ensure CI never gates
  on q8 recovery and no doc implies it's a validated workflow.
- LOW — `skew_normal_nu_start` `sd==0` guard is implicit (saved by `is.finite`); `engine` arg
  added before `...` (low API-stability risk); `profile_targets` abort message names only
  `drmTMB`; 0.2.0 `NEWS` bullets are 600+ words mixing API with audit provenance.

### 2F. Inference claims — Fisher
- MED — the `meta_V` + predictor-dependent-`sigma` "`pdHess=FALSE`" limitation
  (`known-limitations.md:40-49`) has **no reproducing fixture**; the only test of that exact
  shape asserts `pdHess=TRUE`, and the failure path is exercised only by a synthetic override.
  Add a seeded DGP that actually fails, or narrow the wording.
- MED — the Julia "`3e-6` AVONET parity" claim (`NEWS.md:3`) is backed only by an
  `eval=FALSE` vignette needing sibling checkouts, not a package/CI test. Add a
  `skip_if`-guarded parity test or soften the NEWS wording.
- LOW — README `mu_sigma` coverage figure `0.796–0.850` carries conflicting denominator
  labels across two after-task reports ("all-replicate" vs "interval-available").
- LOW — q8 summariser pulls `std.error` for derived-correlation rows; safe **only** because
  the runner uses `se=FALSE`; enforce the no-Wald-for-derived contract at the source.
- LOW — several README **"Stable"** families (beta, zero-one beta, ordinal, skew-normal) have
  **no external fit comparator** (only density scale-maps) — the register's hedge is right but
  "Stable" overstates it; add one comparator each or qualify the label.

### 2G. Reproducibility / CRAN — Grace
- MED — WIP/detached tree vs `cran-comments.md` "new submission 0.2.0": the clean check + the
  pkgdown fix were run against the **dirty** tree, not a commit. Commit/stash, re-check, align
  cran-comments to the exact tarball.
- MED — pkgdown breakage history (fixed on `main`; the **local tree's `_pkgdown.yml` differs**
  — see §0).
- MED — all 31 vignettes are `eval=TRUE`; the heaviest fit 16–22 models — CRAN per-platform
  **runtime risk**; consider precomputing/`.Rbuildignore`-ing the slowest as pkgdown-only.
- MED — `inst/sim/` ships **~1.48 MB / 215 scripts** in the tarball (only `inst/sim/results`
  is build-ignored) — the main avoidable contributor to the 5.36 MB size. Add `^inst/sim($|/)`
  to `.Rbuildignore`.
- LOW — `parallel` used via `::` but not in `Imports`; `parallel="multicore"` guarded OK;
  thin `skip_on_cran` coverage vs 341–384 s packaged test time; no `RNGkind`/seed pinning in a
  couple of tests; cran-comments lists *local* tool notes that aren't CRAN's; 3-OS matrix runs
  on **every** push/PR (per project policy, trim routine to PR + `ubuntu-latest`, expand before
  release); 122 KB single-TU `src/drmTMB.cpp` → long compile/memory on constrained builders.

---

## 3. Documentation findings

### 3A. Function documentation — documentation_writer
(HIGH items 9 in Fix-first.)
- MED — "coscale" appears in `print.drmTMB`/`predict_parameters` but is **never defined** on
  the `biv_gaussian()` / `rho12()` help pages.
- MED — `skew_normal()` calls `nu` "slant **or shape**"; `nu` is "shape" for Student-t/Tweedie
  elsewhere — use "slant" consistently.
- MED — `confint.drmTMB` `@return` omits the `std.error` column it actually appends; integer
  `parm` selector undocumented/undemonstrated.
- MED — `residuals.drmTMB` doesn't mention the skew-normal path (Pearson uses public `sigma`).
- MED — `check_drm` threshold params (`gradient_tolerance`, `rho_boundary`, `sd_boundary`) are
  on the method but not pulled onto the generic Rd (`@rdname`/document on generic).
- LOW — `gr()`/`meta_known_V()` examples rely on a load-bearing `suppressWarnings()` without
  saying so.

### 3B. Articles — understandability — Pat
(HIGH items 7 in Fix-first; plus `missing-data.Rmd:885` `MD1…MD9a` codes unexplained, and
`model-selection.Rmd:177-233` presents a 200-rep table it never interprets.)
- MED — "distributional regression" (`drmTMB.Rmd:17`) and "coscale" (`model-map.Rmd:29`)
  undefined at first use; the colon-heavy profile target string (`model-workflow.Rmd:425-435`)
  unexplained; `stats::Gamma(link="log")` prefix gotcha (`distribution-families.Rmd:300`); no
  recovery path when the convergence ladder fails (`convergence.Rmd:525-631`).
- LOW — MI-vs-multiple-imputation contrast; `bench/large-phylo-location.R` referenced as if
  installed.

### 3C. Articles — biological relevance — Darwin
(HIGH item 8 in Fix-first.)
- MED — `location-scale` response units undefined + "parrot beak" teaser never fitted;
  `animal-models` never mentions heritability / genetic correlation despite the title;
  `phylogenetic-models` never translates phylo-SD into a phylogenetic-signal statement;
  `count-nbinom2` "trap_nights" undefined; `meta-analysis` effect-size metric (Hedges' d? log
  RR?) unstated, which changes how `sigma` reads.
- LOW — `structural-dependence` route table is syntax-only; `relmat` inner unit "observation"
  vs group "line" confusing; no skew-normal-vs-Student-t choice heuristic.

### 3D. Articles — staleness / consistency — Rose
(HIGH items 1, 10 in Fix-first.)
- MED — `NEWS.md` jumps `0.2.0` → `0.1.3` with **no `0.1.4` entry** though a `v0.1.4` tag
  exists; three coexisting statuses ("0.2.0 release candidate" banner vs "under active
  development" vs the live 0.1.4 site).
- LOW — "Q4" casing vs dominant "q=4"; `bf`/`drm_formula` presented as two spellings without a
  stated house style; internal `MD9a` slice tag leaked into `README.md:239`.
- **Clean (verified):** terminology discipline holds (`sigma`/`rho12`/`tau`-as-contrast/
  `meta_known_V`-as-deprecated/`phi`-in-conversion-tables); `skew_normal` and q8
  fitted-vs-planned boundaries are consistent across pages.
- **Systems note:** the README hand-maintains volatile integers + status strings with nothing
  syncing them to `DESCRIPTION`/`NEWS`/tests — that one pattern produced 3 of 4 higher-severity
  status findings. Add a release-checklist grep that flags a literal expectation count, a
  CRAN-install claim, or a version string disagreeing with `DESCRIPTION`.

### 3E. Figures — Florence
(HIGH item 11 in Fix-first.)
- MED — double-`ggplot` chunk shares one `fig.alt` (bias+coverage)
  (`figure-gallery.Rmd:simulation-operating-characteristics`); `profile-likelihood.Rmd:119`
  plot chunk has no label/`fig.cap`/`fig.alt`; the empirical-marginal "averaged row-wise Wald"
  figure says "display approximation" in the caption but not the alt-text;
  `plot_parameter_surface()` puts the raw column-name string on the x-axis by default.
- LOW — `rmse-display` `nrow=2` vs `bias` `nrow=1`; `plot_corpairs(interval_style="line")`
  hard-codes grey and drops the colour channel; `random-effect-sd-surface` hollow markers read
  as data; `confidence-distribution-slopes` shared "Coefficient" x-label mixes `mu`-slope and
  log-SD scales; missing `dpi=144` on two vignettes; Rd plot examples give no figure description.

### 3F. Reference index & learning path — pkgdown_editor
(HIGH item 12 in Fix-first; **note these are against the local tree's `_pkgdown.yml`**, which
differs from `main`.)
- HIGH — `convergence`/`large-data` are in the navbar "Model Guides" but the articles index
  "Inference, Diagnostics, and Figures" — category whiplash; `model-selection` is placed
  **before any fitting tutorial** though it presupposes fitted models.
- MED — `location-scale`/`bivariate-coscale`/`meta-analysis` navbar "Tutorials" vs index
  "Choose Your Model"; the 16 `drmTMB_julia` S3 methods have **no reference grouping** in the
  local `_pkgdown.yml` (the [#535] "Julia engine" section is on `main`, not here); "Start Here"
  ordering (`model-workflow` before `missing-data`); dual "Getting Started" + "Start Here"
  onboarding sections.
- LOW — `intro` built-in duplicates the Tutorials "Getting started" entry; `cross-family` not
  present in the local tree (it's on `main`); `coef`/`print` S3 methods absent from the
  reference index (fold via `@rdname model-fit-extractors`).

---

## 4. Cross-cutting themes

1. **No single source of truth for repeated facts.** Links live in 3 places (Emmy); guard
   constants are scattered literals (Gauss); reserved-name lists drift (Boole); README pins
   integers/status strings nothing syncs (Rose). A `model_type` registry + a few shared
   constants + a release-checklist grep would dissolve a whole class of findings.
2. **`drmTMB` ↔ `drmTMB_julia` is a partial-parity skeleton.** Divergent return shapes,
   missing `summary`, ignored args, undocumented methods (Emmy) — the single biggest
   coherence risk, and squarely a **DRM.jl-team coordination item**.
3. **The math is right; the *documentation of the numerics* lags.** Noether found no wrong
   likelihood, but the C++ guards/constraints (beta squeeze, df floor, Tweedie range, tail
   floor) aren't all written down, and Gauss found several can still emit silent NaN/Inf.
4. **Evidence vs claims.** Inference is honestly hedged (Fisher), but a few specific claims
   (meta_V `pdHess=FALSE`, Julia `3e-6` parity, several "Stable" families) lack a reproducing
   fixture/comparator.
5. **Release hygiene.** Dirty detached tree vs "new submission", `inst/sim` tarball bloat,
   vignette runtime, untracked 1102-LOC Julia bridge, stale `.so` (Grace/reviewer).

---

## 5. Suggested triage order

1. The 12 **Fix-first** items (§1) — the user-facing falsehood (#1), the silent-NaN C++ paths
   (#2–4), and the navigation/figure breaks (#11–12).
2. The **single-source-of-truth** refactors (theme 1) — high leverage, dissolves many lows.
3. The **`drmTMB_julia` parity** contract (theme 2) — DRM.jl-team owned.
4. **Release hygiene** before any CRAN move (theme 5) — commit the tree, `.Rbuildignore`
   `inst/sim`, reconcile cran-comments, carry the pkgdown fixes forward from `main`.
5. Documentation polish (§3) — batchable; mostly "define the term, name the organism, state
   the unit, document the guard".

*Read-only audit — no code, docs, or config were changed in producing this report. Severities
are reviewer judgments against a WIP tree; confirm each against the intended `main` state
before acting.*
