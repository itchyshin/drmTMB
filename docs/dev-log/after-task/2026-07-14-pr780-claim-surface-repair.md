# After Task: PR #780 claim-surface repair and merge disposition

## 1. Goal

Determine whether PR #780 should merge from updated `main`, repair the two
review-blocking claim defects without widening Arc 1a, and leave the branch in
a verified, pushed state for a separate human merge decision.

## 2. Implemented

The structured-effect scale explanation now uses one consistent contract:
for coefficient vector \(b_j\sim N(0,s_j^2K_h)\), the fitted structured SD is
\(s_j\), covariance is \(s_j^2K_h\), and node \(i\)'s marginal SD is
\(s_j\sqrt{K_{h,ii}}\). Intercept SDs are labelled in response units; slope
SDs are labelled in response units per predictor unit. Source prose, generated
capability outputs, rendered pkgdown pages, and `llms.txt` were synchronized.

The non-Gaussian Q-Series surface now separates 27 rows with point-fit recovery
evidence from 10 diagnostic-only feasibility rows. Those 10 rows explicitly do
not establish point-estimate recovery. The release ledger retains the legacy
`basic_distribution_recovery` track ID for structural compatibility, while
`fit_status` is the authoritative row-level distinction. Generators,
validators, preflight output, release status, public sources, rendered pages,
and regression tests now enforce that distinction.

## 3a. Decisions and Rejected Alternatives

The repair did not reinterpret diagnostic convergence as recovery. Renaming or
splitting the legacy release-track ID was rejected because the explicit
`fit_status` field provides the necessary truth without a wider schema
migration. The Arc 1a estimator boundary was not widened: it remains native
exact-Gaussian REML for univariate pure-`mu` models with `sigma ~ 1`, no sigma
random effect, and an unlabelled intercept or independent intercept-plus-one-
slope route for `spatial()`, `animal()`, or `relmat()` over the recorded
discrete evidence domains. No `supported` promotion was made.

## 4. Files Touched

The repair updated the live capability and Q-Series ledgers, their Python
generators and semantic guards, package tests, README/NEWS/ROADMAP and design
notes, affected vignettes, generated Markdown/HTML capability outputs,
rendered pkgdown pages, `pkgdown-site/llms.txt`, check logs, and Mission Control.
The large file count reflects a class-wide stale-wording sweep and regeneration
of tracked reader surfaces rather than a new estimator feature.

## 5. Checks Run

- All 33 capability-ledger semantic tests passed.
- Capability generation/check passed for all 30 tracked outputs.
- Q-Series release generation, preflight, and public-claim guards passed with
  27/37 recovery, 10/37 diagnostic-only, 8/104 `inference_ready`, and 0/104
  `supported`.
- `python3 tools/validate-mission-control.py` returned
  `mission_control_ok`.
- The full `devtools::test()` run completed with 0 failures, 0 errors, 62
  expected warnings, and 24 expected skips.
- A genuine `devtools::check(args = "--as-cran")` completed in 13m46s. The
  normalized result was 0 errors, 0 warnings, and 0 notes; raw R also emitted
  its non-enforcing report-only spelling comparison before that summary.
- `pkgdown::check_pkgdown()` found no problems after rebuilding articles,
  reference, home, NEWS, roadmap, and LLM documentation.
- `git diff --check`, rendered read-backs, the local Mission Control JSON, and
  `http://127.0.0.1:8823/home.json` passed.

## 6. Tests of the Tests

The semantic guard suite now fails if active capability or Q-Series surfaces
collapse diagnostic-only rows into recovery, if public count wording returns
to 37 recovery rows, if fixed-`zi` Poisson and NB2 routes drift asymmetrically,
or if the spatial plot again assigns intercept units to a slope SD. The full
suite initially exposed nine assertions that still required the old overclaim;
those assertions were changed to enforce the 27/10 truth and then passed inside
the complete package run.

## 7a. Issue Ledger

No issue was edited or closed during this repair. PR #780 still declares
`Closes #147`, so issue #147 should close only if the pull request is merged.
Broader issues and the external capability-artifact mirror remain outside this
repair. No new issue was opened. PR #780 was not merged.

## 8. Consistency Audit

The audit compared source prose, active TSV ledgers, generated Markdown and
HTML, rendered pkgdown pages, `llms.txt`, release status, preflight output,
Mission Control, and regression tests. Ten diagnostic-only routes were read
back consistently across these surfaces. The fixed-zero-inflation Poisson and
NB2 rows are symmetric; both remain diagnostic-only. Historical dev logs were
left historical where they clearly record prior state, while active teaching
and status surfaces were corrected.

## 9. What Did Not Go Smoothly

The first repair pass fixed the named vignette count but left neighbouring
generated and rendered surfaces stale. Iterative Fisher, Pat, and Rose reviews
then found additional diagnostic/recovery conflation, fixed-`zi` asymmetry,
ambiguous slope units, and stale LLM documentation. Pat's final reader audit
then found that the count-facing README and count article still omitted the two
fixed-`zi` spatial-`mu` diagnostic carve-outs from broad planned wording; both
sources, their rendered pages, `llms.txt`, and the semantic guard were repaired.
The first full-suite output also showed nine stale contract assertions; one
subsequent selector inspected the first recovery row rather than a diagnostic
row. The first final-head GitHub run then caught that the strengthened semantic
test unconditionally read ignored local `pkgdown-site/` output, which does not
exist in a clean checkout. The guard now always checks tracked source surfaces
and additionally checks rendered/LLM output when that local build exists. Each
finding was repaired and revalidated instead of being waived.

## 10. Known Residuals

The 10 diagnostic-only routes remain feasibility evidence, not recovery,
interval, coverage, `inference_ready`, `supported`, REML, AI-REML, broad
structured-covariance, bridge, or public-support evidence. Arc 1a evidence
remains discrete rather than a continuous-domain guarantee. The external
`a1bf21a1` mirror was not refreshed, and no Totoro campaign was rerun.

## 11. Team Learning

Evidence tier must be a typed field rather than inferred from prose. Generated
status summaries should report recovery and diagnostic counts separately even
when a legacy track groups them structurally. Reader-facing scale labels must
name both the response unit and, for slopes, the predictor denominator.

Memory receipt: the repository `AGENTS.md`, the latest Arc 1a handoff, and the
`ask-brain`, `ultra-plan`, `r-package-engineer`, `prose-style-review`, and
`after-task-audit` instructions shaped this repair. Ask Brain found no exact
PR #780 disposition note; its drmTMB project notes confirmed that the repository
and live evidence surfaces are technical truth, so no memory-derived claim was
used as merge evidence.

Golden Set: this repair strengthened the repository's mistake guards. The 33
semantic tests and the structured-conversion contract now fail if diagnostic
convergence is relabelled as recovery, if the 27/10 counts collapse back to 37
recovery rows, if fixed-`zi` count routes drift asymmetrically, or if slope SDs
lose their predictor-unit denominator.

## 12. Cross-Product Coverage

The repair checks all 37 non-Gaussian Q-Series rows as 27 recovery plus 10
diagnostic-only routes, and checks all three Arc 1a providers across the two
admitted Gaussian shapes. It **does NOT cover** non-Gaussian REML, bivariate
REML, labelled or multiple slopes, slope-only models, matched `mu+sigma`
structured effects, sigma random effects, estimated spatial range, broad
matrix geometries, or any new coverage promotion.

## Merge Disposition

With the repaired claim surfaces, green full package validation, and final
same-tree Fisher/Pat/Rose review, PR #780 is recommended to merge. Merge remains
a separate human action and was not performed in this task.
