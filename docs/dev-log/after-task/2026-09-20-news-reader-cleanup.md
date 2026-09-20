# After task: NEWS reader-language cleanup, first bounded slice

## Goal

Make the native-model release notes understandable to an applied biology PhD reader. Remove internal project labels without changing scientific claims. The full NEWS is 3,544 lines and 50,304 words at base `d18889763`; this is a bounded first repair, not a claim that all release history is clean.

## Files changed

`NEWS.md`, this report, and the corresponding `docs/dev-log/check-log.d/2026-09-20-news-reader-cleanup.md` evidence entry. No model code, tests, workflow, configuration, API, or bridge behaviour changed.

## Implemented and consistency audit

Changed 16 heading-defined sections: 14 sections in the 0.6.0 history plus entries under the unsectioned 0.1.4 and 0.1.2 histories. Removed the eleven native Arc-labelled headings and their associated cross-references, rewrote all 13 paragraphs containing `artifact lane`, and replaced the Q-Series internal release-status link with the public capability-and-limits guide. These 13 historical simulation entries describe what the tools record and explicitly separate those outputs from an established coverage result.

Preserved model formulas, scientific exclusions, complete-pair and weighting restrictions, Bernoulli association versus residual correlation, the shared-scale interpretation of the Student-t model, sample sizes, recovery limitations, and historical supersession notes. Julia bridge release sections are unchanged. Named roles used as review perspectives: Pat for readability and Rose for claim boundaries; no additional reviewer agent was launched in this subtask.

## Checks run and exact outcomes

- `git diff --check`: PASS.
- `Rscript -e 'pkgdown::build_news(preview = FALSE)'`: PASS, wrote `pkgdown-site/news/index.html`. Initial sandbox attempt failed on CRAN metadata DNS and the Sass cache; rerunning with the normal approved network/cache access succeeded.
- Rendered NEWS was inspected in the local browser. The Bernoulli association and initial bivariate Student-t headings and their scientific caveats render correctly. The full release page retains older dense prose and internal tracking language, quantified below.
- Applied the existing `process_patterns` and `visible_text` definitions parsed directly from `tools/check-pkgdown-public-surface.R` to regenerated NEWS: PASS, zero hits. This narrow check does not cover all internal language: bare tracker numbers, generic Arc/Phase names, and gate/receipt/ledger wording escape those patterns.
- `Rscript tools/check-pkgdown-public-surface.R pkgdown-site`: FAIL on pre-existing `AGENTS.html`, `CLAUDE.html`, `CONTRIBUTING.html`, and `ROADMAP.html`. To supply the surrounding site, this isolated clone copied the existing local `pkgdown-site` and rebuilt only NEWS. This is an inherited snapshot failure, not evidence of a fresh full-site build. No pages were deleted to make the checker pass.
- Exhaustive source scan: 344 to 305 distinct matching lines using the union of the patterns below. There are zero remaining `artifact lane` phrases and zero `docs/dev-log` references. Remaining terms are backlog, not approved public-reader exceptions.

## Tests of the tests

The same pattern scan was applied to `git show HEAD:NEWS.md` before changes and to edited NEWS. It detects the original Arc headings, all 13 artifact-lane paragraphs, and the original internal release-audit link. Broader pattern counts intentionally report existing failures rather than narrowing the rule to the changed text. Numerical tests were not run because this is a prose-only change.

## What did not go smoothly

The full historical file is much larger than the initial named examples. A semantic rewrite of all 50,304 words would not be a safe narrow slice. The current public checker also misses many plain-language process identifiers, and the existing local site snapshot includes private pages. Both limits remain explicit.

## Team learning and process improvements

Use section-based NEWS repairs with a measured backlog. A public process-language scan should eventually include the visible changelog, bare tracker references, numbered Arc/Phase names, and claims hidden in long historical bullets; that checker change is outside this PR.

## Design-doc updates

None: no model, estimator, formula, or validation-policy decision changed.

## Pkgdown/documentation updates

The built-in `news` navigation item is selected by `_pkgdown.yml:22`. `pkgdown::build_news()` writes `news/index.html`; no config change is necessary. Only the local NEWS page was regenerated. Generated site files are not committed, deployed, or used as full-site verification.

## GitHub issue maintenance

Read open issues matching NEWS/documentation and open PRs. No matching standalone NEWS reader-cleanup issue was found among the returned results; no issue was changed or opened. Protected bridge and missing-response PRs were left unchanged. This work is submitted as one focused unmerged PR.

## Known limitations and next actions

Continue the measured backlog below in separate non-overlapping sections after this PR is reviewed and merged. Counts are matching lines, not necessarily individual defects; generic terms such as a numerical gate require contextual review. The 0.7.1 record has zero pattern hits but remains dense and contains implementation prose, so zero is not a readability verdict. Rebuild and run the entire public-site checker in the deployment task.

## Exhaustive scan and section backlog

Counts and source ranges below refer to this PR's edited NEWS. Patterns are case-insensitive: `\barcs?\b`, `\bphases?\b`, `\blanes?\b`, `\bworktrees?\b`, `docs/dev-log(?:/|\b)`, `\b(?:issue|PR|pull[ -]+request)\s*#\d+`, `#\d+`, `\bD-\d+\b`, and `\b(?:gates?|receipts?|ledgers?)\b`. Section ranges begin at a level-1 or level-2 heading and end immediately before the next such heading. Release ranges begin at a level-1 heading. Counts overlap between pattern categories; the union does not double-count matching lines.

```text
Pattern | before matching lines | after matching lines | after occurrences
Arc | 27 | 6 | 6
Phase | 125 | 113 | 117
lane | 43 | 30 | 41
worktree | 0 | 0 | 0
dev-log | 1 | 0 | 0
issue/PR identifier | 0 | 0 | 0
any numeric tracker | 88 | 88 | 92
decision identifier | 0 | 0 | 0
gate/receipt/ledger | 162 | 148 | 170
Union matching lines: 344 -> 305

Changed heading-defined sections:
2161 2206 ## `simulate()` redraws random effects (`re.form`) — corrected before first release
2231 2240 ## Bernoulli × Bernoulli association (superseded for intervals)
2241 2252 ## Exact bivariate Student-t likelihood: initial implementation
2253 2263 ## Exact bivariate lognormal likelihood: initial implementation
2279 2307 ## First-impression formula surface
2321 2339 ## Ordinary `mu` random-slope profile coverage
2340 2358 ## Beta q1 phylogenetic location intercept
2359 2378 ## Exact supplied-relatedness q2 REML intercept
2379 2409 ## Exact bivariate-spatial q2 REML intercept
2410 2427 ## Positive-continuous q1 structured location intercepts
2428 2450 ## Exact-Gaussian REML for mean-side structured providers
2451 2473 ## Residual-scale random intercepts for lognormal and Gamma
2474 2494 ## Random slopes for the intercept-only families
2495 2513 ## Random intercepts for every family
2945 3210 # drmTMB 0.1.4
3216 3444 # drmTMB 0.1.2 (2026-05-16)
TOTAL changed sections: 16

Remaining backlog by release (union matching lines):
1 381 0 # drmTMB 0.7.1
382 1987 112 # drmTMB 0.7.0
1988 2664 10 # drmTMB 0.6.0
2665 2776 3 # drmTMB 0.5.0
2777 2910 1 # drmTMB 0.3.0
2911 2944 0 # drmTMB 0.2.0
2945 3210 77 # drmTMB 0.1.4
3211 3215 2 # drmTMB 0.1.3 (2026-05-20)
3216 3444 94 # drmTMB 0.1.2 (2026-05-16)
3445 3493 3 # drmTMB 0.1.1 (2026-05-10)
3494 3540 3 # drmTMB 0.1.0 (2026-05-10)

Remaining backlog by heading (only sections with matching lines):
| 384-419 | 1 | `engine = "julia"` control surface: no silent drops, boundary made permanent (leaf-engine-control-surface) |
| 420-444 | 1 | Julia routes that refuse a whole `control` now name the offending settings (#1108) |
| 445-502 | 2 | `engine = "julia"` refuses a factor design it cannot reproduce, before Julia starts (DRM.jl #467, #609) |
| 524-557 | 1 | `biv_lognormal()` on the `engine = "julia"` fixed-effect route |
| 558-586 | 1 | Bootstrap replicates keep a masked fit's response mask (#1188) |
| 587-620 | 2 | `engine = "julia"` admits REML on the bivariate q = 2 structured routes |
| 663-684 | 1 | `engine = "julia"` default coefficient labels widened for the A4 family admissions |
| 685-708 | 3 | `engine = "julia"` target discovery closes over what `confint()` accepts (#1156) |
| 709-736 | 2 | `engine = "julia"` admits `REML = TRUE` for the residual-only bivariate Gaussian cell |
| 737-758 | 3 | Bridge-side profile and bootstrap inference qualified on the masked-response Julia route (#544) |
| 759-779 | 2 | Ordered cutpoints through `engine = "julia"`: discoverable, and refused by name (#1144) |
| 780-811 | 3 | Same-target REML receipts for three capabilities the parity scoreboard read UNCITED (#1142) |
| 812-838 | 1 | `biv_student()` admitted through `engine = "julia"` (leaf fam-biv-student) |
| 839-863 | 1 | `predict(type = "quantile")` now works through `engine = "julia"` (#1198) |
| 864-893 | 2 | Zero-inflated Poisson through `engine = "julia"`: focused tests, and a corrected registry note (leaf-fam-zi-poisson) |
| 917-942 | 1 | `engine = "julia"` zero-inflated NB2: `fitted()` and `residuals()` now agree with the native engine (DRM.jl bridge fix) |
| 943-961 | 4 | `engine = "julia"` scope fence for the fixed-effect-only family cohort (A4.G17) |
| 962-999 | 2 | Profile and bootstrap intervals on the residual bivariate Gaussian Julia route (#544) |
| 1000-1038 | 4 | `engine = "julia"` masked-response fits: convergence flag and bootstrap fixed upstream (DRM.jl #646) |
| 1039-1057 | 1 | `engine = "julia"` bridge-side profile/bootstrap inference qualified on two routes (G3) |
| 1058-1095 | 3 | `engine = "julia"` fits the mean-only phylogenetic Gaussian cell by REML |
| 1146-1163 | 1 | `predict()` on `cumulative_logit()` Julia fits now matches `engine = "tmb"` |
| 1164-1182 | 5 | REML support tabled by route, measured across both engines (#1142) |
| 1183-1193 | 1 | Coevolution accessors ported from DRM.jl (#1118) |
| 1194-1211 | 1 | Boundary-corrected likelihood-ratio test for variance components (DRM.jl #1116 port) |
| 1244-1253 | 1 | Model comparison: `aicc()` and the nested likelihood-ratio test, ported from DRM.jl (#1117) |
| 1254-1270 | 2 | `check_drm()` now reads DRM.jl's route-aware gradient/convergence diagnostics (#1108 / DRM.jl #569) |
| 1271-1291 | 7 | Pinned DRM.jl clone moved from `e0a65f96b` to `430ef64cc` |
| 1306-1324 | 5 | `engine = "julia"`: a structured marker with a non-intercept left side of the bar is refused before Julia boots |
| 1325-1350 | 4 | `engine = "julia"`: the ENGINE now decides which estimator ran, and two Poisson REML cells are admitted |
| 1351-1387 | 2 | Pinned DRM.jl clone moved from `77513aa0` to `e0a65f96b` |
| 1388-1421 | 4 | Breaking: `engine = "julia"` now REFUSES unsupported `REML = TRUE` instead of quietly fitting ML |
| 1422-1445 | 6 | Regression cover for the non-interactive `engine = "julia"` abort |
| 1467-1482 | 1 | Fixed: `profile_targets()` on an `engine = "julia"` fit listed one target where `confint()` accepts five (#1156) |
| 1483-1521 | 2 | Fixed: `nlminb` could report convergence short of the true optimum on flat surfaces (#1130) |
| 1522-1534 | 1 | Fixed: bootstrap `confint()` failed for `cbind(successes, failures)` binomial fits (#1123) |
| 1535-1544 | 1 | Fitted objects now store the final gradient (DRM.jl #569, R-side) |
| 1578-1610 | 1 | `objective_at()`: evaluate the fitted objective at a supplied point |
| 1611-1637 | 2 | Build provenance (`drm_provenance()`) |
| 1638-1650 | 2 | Student-t response + one binary `mi()` predictor |
| 1651-1664 | 2 | nbinom2 response + one Gaussian `mi()` predictor |
| 1665-1678 | 1 | Zero-inflated Poisson + one binary `mi()` predictor |
| 1679-1690 | 1 | Beta-binomial response + one binary `mi()` predictor |
| 1691-1702 | 2 | Lognormal response + one binary `mi()` predictor |
| 1703-1714 | 2 | Gamma response + one binary `mi()` predictor |
| 1715-1723 | 2 | Two independent Gaussian `mi()` terms |
| 1724-1743 | 3 | Lognormal ordinary correlated slope |
| 1744-1753 | 1 | Binomial ordinary correlated slope |
| 1754-1762 | 1 | Poisson ordinary correlated slope |
| 1763-1773 | 1 | NB2 ordinary correlated slope |
| 1774-1792 | 2 | Binomial responses accept a phylogenetic random effect |
| 1907-1924 | 3 | Live Workflow G `engine = "julia"` FE gate (#499) |
| 1967-1987 | 1 | REML capability wording now matches the callable surface |
| 1990-2010 | 1 | Five Prong B routes now have interval-feasible profile evidence |
| 2011-2061 | 1 | Profile intervals now warn at a variance-component boundary |
| 2115-2127 | 1 | Fixed-kappa Gaussian mesh intercept at point-fit recovery |
| 2143-2160 | 1 | Association alpha and eta intervals |
| 2340-2358 | 1 | Beta q1 phylogenetic location intercept |
| 2359-2378 | 1 | Exact supplied-relatedness q2 REML intercept |
| 2379-2409 | 1 | Exact bivariate-spatial q2 REML intercept |
| 2410-2427 | 1 | Positive-continuous q1 structured location intercepts |
| 2514-2590 | 1 | Distributional output & adequacy layer (#747, #748) |
| 2601-2612 | 1 | Missing responses: MR-T6 count mixtures |
| 2665-2678 | 3 | drmTMB 0.5.0 |
| 2779-2810 | 1 | Large direct-SD models: uncertainty no longer scales with the square of the group count |
| 2945-3210 | 77 | drmTMB 0.1.4 |
| 3211-3215 | 2 | drmTMB 0.1.3 (2026-05-20) |
| 3216-3444 | 94 | drmTMB 0.1.2 (2026-05-16) |
| 3445-3493 | 3 | drmTMB 0.1.1 (2026-05-10) |
| 3494-3540 | 3 | drmTMB 0.1.0 (2026-05-10) |
```
