# Pre-0.7.0 capability-gap review — four independent reader lenses

**Date:** 2026-08-09 · **Lane:** Claude task 1, Stage A · **Baseline:** `origin/main@ac363cadb`
**Requested by:** Shinichi, 2026-08-09 — "what is missing and what our potential users notice"
**Status:** review only. No code, docs, or release state changed. Release verdict unchanged:
**NOT READY**, `DESCRIPTION` `0.6.0`.

## Method

Four reviewers were dispatched in parallel with self-contained briefs, **blind to each
other's findings**, each given the same measured ledger census and told to cite
`file:line` and mark anything unverified as INFERRED:

| Lens | Role | Ran live R? |
| --- | --- | --- |
| **Pat** | applied-PhD-student user tester | no — source trace only |
| **Darwin** | ecology/evolution audience | no — source + ledger queries |
| **Boole** | R API / formula grammar | no — source trace only |
| **Fisher** | statistical inference | **yes** — captured real `confint()` / `summary()` output |

Tooling note: Pat, Darwin, and Boole had no Write tool in their sessions and returned
findings in-message; this document is the durable capture. Fisher wrote
`fisher-inference-gaps.md` to scratchpad. Pat and Boole additionally lacked Bash, so
their behavioural claims are **static source traces, not executed observations** —
labelled below. Fisher's and Darwin's ledger claims are executed.

## The census this review is built on

`docs/dev-log/dashboard/capability-ledger/cells.tsv`, 723 rows:

| Axis | Counts |
| --- | --- |
| `capability_status` | 365 implemented · 348 rejected_by_design · 10 not_implemented |
| `evidence_tier` | 364 none · **192 interval_feasible** · 74 point_fit_recovery · 60 diagnostic_only · **29 inference_ready_with_caveats** · **4 supported** |
| `effect_type` | 449 structured · 100 fixed · 80 ordinary_re_slope · 76 ordinary_re_intercept · 18 response_missingness |

## The convergent finding

**Three of four reviewers independently reached the same conclusion: the evidence tier
is invisible at the point of use.**

- **Pat** (gap 2): `confint()` / `summary(conf.int=TRUE)` print the same-looking table
  for a calibrated fixed-effect Wald interval and an uncertified structured-RE interval;
  `conf.status` encodes *method*, not *calibration*.
- **Fisher** (traps 2–4): 192 `interval_feasible` cells have **zero runtime distinction**
  from the 33 certified ones. `profile.boundary = TRUE` never appears in printed summary
  output, and `conf.status` is dropped from the table entirely when all rows share a
  method — exactly what a usable-but-boundary-flagged interval looks like
  (`R/methods.R:4896-4934`).
- **Darwin** (mismatch 2): the README's "Stable-core matrix" labels most fixed-effect
  surfaces "Stable", which a reader can easily over-read as "CI-ready", while
  `vignettes/capability-and-limits.Rmd:69-77` says the legacy `supported` label does not
  by itself authorise an interval.

The package's own source concedes the gap: `summary.drmTMB`'s roxygen states the tier is
**"a documentation-level curation, not a runtime guard"** (`R/methods.R:4032-4033`).

This is a **surfacing** problem, not a correctness bug. The rigour exists — in the
ledger, the vignettes, and the shipped `drmTMB_profile_boundary_warning`. It does not
reach the object the user looks at.

## Ranked traps

Ordered by (probability a real user hits it) × (severity of the wrong conclusion).

| # | Trap | Evidence | Severity |
| --- | --- | --- | --- |
| 1 | **Bootstrap intervals near a boundary carry no flag and no warning.** Same fit and target: the profile path warns, the bootstrap path returns a clean-looking CI (`[2e-5, 0.38]`, `conf.status = "bootstrap"`) and says nothing. | Fisher, **executed** | HIGH |
| ~~2~~ | ~~**Bivariate random intercepts silently fit uncorrelated.**~~ **REFUTED — see below.** | Boole (source trace) vs. orchestrator (**executed**) | ~~HIGH~~ **none** |
| 3 | **`check_drm()` never inspects `conf.status`, `profile.boundary`, or tier.** The pre-report gate the capability vignette tells users to run cannot see the thing most likely to invalidate the report. | Fisher, `R/check.R` | HIGH |
| 4 | **`confint(method="profile")` and `summary(conf.int=TRUE, method="profile")` use different engines** (`"auto"`/`"endpoint"` vs `"tmbprofile"`) and can disagree on the identical fit — one succeeds with a boundary flag, the other returns `profile_failed`. | Fisher, **executed** | MED |
| 5 | **Skew-normal `nu ~ x` Wald has a documented false-positive rate up to 40.5% near `nu = 0`** — where the biological null sits. The package warns and redirects (correct behaviour), but that is the question users bring. | Darwin, ledger cell mc-0460 | MED |
| 6 | **README tells new users to install `@v0.5.0`**; `vignettes/drmTMB.Rmd:64-67` calls that tag an unsupported install target. Step one contradicts itself. | Pat, `README.md:84-90` | MED |
| 7 | **Inconsistent "try next" guidance in rejection messages.** Binomial's unsupported-dpar abort names `beta_binomial()` as the alternative; the identically-shaped Poisson (`R/drmTMB.R:6656-6660`) and nbinom2 (`:7090-7093`) messages give no hint — against this repo's own writing standard. | Boole | LOW |
| 8 | **`beta()`'s exact-0/1 abort omits the `zero_one_beta()` fallback inline** (`R/drmTMB.R:5253-5257`) — no `"i" =` hint line, unlike most rejections in the file. | Pat | LOW |

## Refuted finding — and why it matters methodologically

**Boole's trap 2 is false.** It was returned at HIGH severity from a static source trace
(Boole had no Bash tool). Running it refutes it:

```r
drmTMB(bf(mu1 = y1 ~ x + (1 | id), mu2 = y2 ~ x + (1 | id),
          sigma1 = ~1, sigma2 = ~1),
       data = d, family = c(gaussian(), gaussian()))
#> Error: Bivariate random-effect covariance blocks require
#>        covariance-block labels.
```

The unlabelled form does **not** silently fit two uncorrelated intercepts. It **fails
closed**, with a message that names the exact missing thing. That is the guard Boole
reported as absent, working correctly. Probe:
`scratchpad/biv-corr-probe.R`, M = 60 groups, n = 6, true cross-trait correlation 0.8.

Recorded rather than deleted, because the lesson generalises and this repo has paid for
it before: **a source trace is a lead, not a finding.** Two of four reviewers lacked
execution tools, and the one HIGH-severity claim that rested purely on reading was the
one that did not survive contact with the toolchain. Fisher's traps — which *were*
executed — all held. Weight the lenses accordingly when acting on this review.

## Biology frontier (Darwin)

**Answerable well today** — trait variability vs mean (flagship Gaussian location–scale);
bounded proportions in mean *and* dispersion (`beta`, certified); among-individual
variation in a binary-outcome slope (certified at M ≥ 32); **residual variability itself
phylogenetically structured** (the genuinely distinctive capability); meta-analysis with
known sampling variance.

**They will ask and cannot** —

1. **"What is the phylogenetic signal λ, with a confidence interval?"** Point estimate
   only; the two component SDs have `confint()` targets on differently-calibrated
   channels, but the ratio itself has none (`vignettes/phylogenetic-models.Rmd:193-228`).
   **Darwin's single highest-traffic gap** — applied phylogenetic papers report a CI on λ
   as standard.
2. Mixed-family bivariate (binary survival × continuous condition) — `not_implemented` by
   design; that is gllvmTMB's lane.
3. The full double-hierarchical individual-difference model — the pieces exist
   separately; `README.md:419-424` calls the whole thing planned. Notable because it is
   the question the package's own `mu` + `sigma` pitch invites.
4. Non-Gaussian animal-model REML heritability — `rejected_by_design` outside
   Gaussian/binomial.
5. Estimated spatial range (sdmTMB / R-INLA style) — only one fixed-`kappa` cell exists
   at `point_fit_recovery`, while the vignette title implies more.

## Documentation freshness defects found in passing

- **`vignettes/capability-and-limits.Rmd:161`** still lists the bivariate spatial-REML
  route as "Recovery-only", but `mc-0199` / `mc-0672` were promoted to
  `inference_ready_with_caveats` on 2026-08-03. Stale prose, not a capability gap.
- **README capability tables are unscannable** — Pat measured one `README.md:351` table
  cell at roughly 2,500 words of semicolon-joined clauses. The generated per-route cards
  in `vignettes/includes/capability-ledger-summary.md` are the good pattern already in
  the repo.
- **Three independent prose descriptions of the same capability cell** (README,
  `capability-and-limits.Rmd`, `formula-grammar.Rmd`) with no declared canonical source.
- Pat found vignette *navigation* itself is **solved well** — `_pkgdown.yml` navbar plus
  the README "Start here" handle 37 vignettes adequately.

## What this review does NOT do

Does not change release scope · does not advance any rung · does not bump `DESCRIPTION` ·
does not implement any fix · does not close any issue · does not reopen D-93 or D-117 ·
does not run any simulation.

## The decision it surfaces for Shinichi

The convergent finding is the only item that plausibly belongs *inside* 0.7.0 rather than
after it, because it concerns what the package tells users about its own reliability —
which is the package's central claim.

The cheapest form is to carry the tier (or at minimum the boundary flag and
`conf.status`) into `print.drmTMB` / `confint()` as one column or footnote. That is a
**change to user-facing output**, so it is a scope decision with an evidence and testing
burden, not a packaging tweak — and it competes directly with the release gate's own rule
against scope creep in a release slice.

**Recommendation: decide it deliberately now rather than discovering it in review after
release.** Two defensible answers:

- **Ship 0.7.0 as-is** and treat surfacing as the headline 0.8 arc, on the grounds that
  the vignettes and the boundary warning already discharge the honest-disclosure duty.
- **Take trap 1 only** (warn on the unguarded bootstrap boundary path, mirroring the
  shipped profile warning) as a narrow, well-scoped pre-release fix, and defer traps 2–4.

Trap 1 is the strongest candidate for the second option: it is a one-path gap in a
guardrail that already exists and already has a tested pattern to copy.
