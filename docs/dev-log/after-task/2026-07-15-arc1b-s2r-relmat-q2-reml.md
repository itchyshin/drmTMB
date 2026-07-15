# After Task: Arc 1b-S2R Exact relmat q2 REML

## 1. Goal

Deliver native-TMB REML for the exact bivariate-Gaussian, location-only model
with matching labelled supplied-covariance `relmat(1 | p | id, K = K)`
intercepts in `mu1` and `mu2`, capped at `point_fit_recovery`.

## 2. Implemented

`drm_validate_reml_spec_biv()` now admits only that exact supplied-`K` route.
The guard requires `biv_gaussian`, q2 location intercepts, one matching label,
identical group levels and named matrix, constant residual parameters, complete
pairs, unit weights, and no other random, structured, direct-SD, or known-`V`
component. Every declared neighbour remains fail-closed.

The implementation uses the existing authoritative R/TMB covariance path; no
C++ likelihood, exported function, formula grammar, or Julia-engine code was
added.

## 3. Mathematical Contract

For response-major data vector
`y = (y1[1:n], y2[1:n])`, the marginal covariance is the sum of the residual
block and `Z (Sigma_K tensor K) Z'`, where `Sigma_K` contains the two structured
SDs and their latent relatedness correlation. REML minimizes the dense Gaussian
restricted objective with the fixed-effect determinant correction. The frozen
symbolic alignment maps this equation term-by-term to the R syntax, DGP, TMB
data/parameter ordering, and extractors.

An independent dense oracle matched the TMB objective at the optimum and two
displaced parameter vectors. A deliberately wrong precision/orientation
calculation did not match. Extractor tests align both fixed-effect vectors, both
structured SDs, their latent correlation, both residual SDs, and `rho12`.

## 3a. Decisions and Rejected Alternatives

The smallest correct implementation is a narrow R-side admission predicate
over the existing authoritative native covariance engine. Rewriting the C++
likelihood was rejected because the independent oracle proves that the engine
already evaluates the required restricted objective. Provider-general,
precision-`Q`, slope, scale-side, q4+, interval, coverage, and Julia admissions
were rejected from this arc because each changes the mathematical or evidence
contract. The capability ceiling is therefore `point_fit_recovery`.

## 4. Files Touched

- Admission and documentation: `R/drmTMB.R`, `R/formula-markers.R`,
  `man/drmTMB.Rd`, `man/relmat.Rd`, `README.md`, `NEWS.md`, `ROADMAP.md`,
  and `AGENTS.md`.
- Mathematical and scope freezes: the five dated Arc 1b-S2R planning/design
  notes plus design documents 01, 03, 168, 211, and 217.
- Tests and evidence: the new relmat q2 oracle/admission test, recovery-runner
  contract test, runner, and complete hashed Totoro campaign directory.
- Capability truth: source ledger, evidence, transitions, schema, generator,
  generator tests, census, generated surfaces, runtime/conformance locators,
  and Mission Control.
- Reader surfaces: capability, relmat, formula-grammar, and source-map
  vignettes plus known limitations.

## 5. Checks Run

- Final focused relmat/spatial REML boundary tests: 107 PASS, zero failures.
- Recovery-runner, conformance, and ledger tests: PASS.
- Final full source-tree `devtools::test()`: 38,811 PASS, zero failures, 62
  existing warnings, and 24 expected optional-Julia skips.
- `devtools::document()`: PASS.
- Final genuine `devtools::check(document = FALSE, args = "--as-cran")`: 0
  errors, 0 warnings, and 0 normalized notes in 13m31.8s. The raw checker
  emitted only its known long-installed-test NOTE.
- Final `pkgdown::check_pkgdown()` and `pkgdown::build_site()`: PASS; rendered
  source, reference, navigation, search, sitemap, and `llms.txt` surfaces were
  read back after the documentation repairs.
- Capability ledger: 36 tests PASS; generated output PASS; runtime oracle PASS
  for all 18 routes; Mission Control PASS.
- Campaign provenance: every `SHA256SUMS` entry PASS; all 2,400 attempt keys are
  unique and all predeclared gates PASS.
- `git diff --check` and exact stale-wording scans: PASS.

## 6. Tests of the Tests

The post-merge exact formula failed before the admission change with the
spatial-only bivariate REML rejection, establishing genuine red evidence. The
new objective test is independent of the package's TMB objective and checks
three parameter vectors. Its deliberately wrong precision/orientation sentinel
must disagree materially. The rejection matrix covers `Q`, unlabelled or
mismatched blocks, ordering and matrix mismatches, a numerically identical
matrix supplied through a different formula symbol, slopes, q4/q6/q8/q12,
scale-only and location-plus-scale blocks, extra random effects, nonconstant
residual parameters, missing pairs, non-unit weights, direct-SD models, known
sampling covariance, and non-Gaussian families. Existing ML `K` and `Q`
behaviour remains tested.

## 7a. Issue Ledger

The mandatory post-merge refresh found PR #781 to be an unrelated
meta-analysis trust dossier. No open issue or PR owns this exact supplied-`K`
bivariate REML slice, so no unrelated thread was changed and no duplicate issue
was opened. The implementation is proposed in focused PR #784 and remains open
and unmerged pending separate authorization.

## 8. Consistency Audit

The symbolic equation, exact `bf()` syntax, DGP, response-major TMB ordering,
oracle, and extractor names agree. Public docs state `point_fit_recovery` and
do not imply intervals or coverage. The ledger has 675 model cells, with only
the exact supplied-`K` endpoint projections implemented and the remainder
rejected. Generated Markdown, HTML, census, runtime, and Mission Control
read-backs agree with the source ledger.

The future `sd()` work remains a planned sequence, not part of this feature:
Beta phylogenetic q1 `mu`, then the bounded Beta q1 location-scale-scale gate,
then a separate hierarchical-`sd()` subarc. Its first conservative admission
permits an RHS random term only at a genuinely higher replicated grouping level;
same-level and highest-level-without-parent formulations remain rejected.

Exact stale-wording searches included:

```sh
rg -n "relmat.*REML|REML.*relmat|point_fit_recovery|Q = Q|K = K" README.md ROADMAP.md NEWS.md docs/design docs/dev-log/known-limitations.md vignettes pkgdown-site
rg -n "all bivariate non-phylogenetic|any bivariate non-phylogenetic|spatial-only" README.md ROADMAP.md NEWS.md docs vignettes pkgdown-site
rg -n "hierarchical-`sd`|coarser|same-level|fixed-effect-only|family variability|latent.*target" AGENTS.md ROADMAP.md docs/dev-log/dashboard/README.md
```

Historical dated notes were not rewritten.

## 9. What Did Not Go Smoothly

The first Totoro smoke loaded `drmTMB_0.1.4` because `R_LIBS_USER` did not
override the host's default library. That smoke was discarded before the
campaign. The corrected command set an absolute `R_LIBS` path, printed package
version `0.6.0.9000`, and was reused for all 2,400 fits.

The first full package test found four hard-coded estimator-source line anchors
shifted by the new admission helper. The anchors were updated to the unchanged
authoritative statements and both focused and full tests then passed. Two
legacy validator filenames named in the plan no longer exist; the live Python
ledger test suite, generated-output check, R runtime oracle, and Mission Control
validator were used instead.

Rose's first final audit found that the rejection matrix had not yet encoded
every frozen sentinel and that `relmat()` help made a false blanket statement
about labelled structured slopes. The final tests now include the distinct
scale-only block and value-identical/different-symbol `K` cases, while the help
names the implemented bivariate labelled ML layouts before delimiting planned
extensions. Pat's first audit also found undefined objects in the worked
example and a rendered plotting warning; the example, fit name, help, and plot
were repaired and the final site was rebuilt. Noether removed an internal
finite-sample unbiasedness overstatement. Fresh Rose, Pat, Noether, Fisher, and
Curie reviews of the repaired tree all returned PASS.

## 10. Known Residuals

This arc does not admit supplied precision `Q`, `animal()`, slopes, q4+, scale-
side effects, extra random effects, incomplete pairs, non-unit weights,
nonconstant residual parameters, direct-SD models, known sampling covariance,
or non-Gaussian families. It provides point-fit recovery evidence only: no
profile/Wald/bootstrap intervals, interval calibration, or coverage claim is
made. The R/TMB implementation is authoritative; no Julia evidence transfers.

## 11. Team Learning

Remote compute provenance must authenticate the installed package, not only the
transferred source. The team-improvement log now requires an absolute `R_LIBS`
path and immediate package-version read-back before any remote smoke or
campaign.

The prose review also reinforced that `sigma` and `sd(target, ...)` are separate
scale axes. Keeping that distinction explicit prevents the planned hierarchical
`sd()` work from being mistaken for a residual-scale extension.

Memory receipt: the repository `AGENTS.md`, the Arc 1b-S1 handover, the
post-PR-#783 truth refresh, and the `ultra-plan`, `memory-recall`,
`r-package-engineer`, `symbolic-alignment`, `simulation-design`,
`validation-harness`, `prose-style-review`, and `after-task-audit` instructions
shaped this arc. Repository code, frozen contracts, live GitHub state, and raw
campaign artifacts—not memory—are the technical evidence for the claim.

Golden Set: this arc strengthens the fail-closed mistake guards. The independent
wrong-precision sentinel, complete rejected-neighbour matrix, exact 2,400-key
denominator checks, raw-evidence hashes, generator tests, runtime oracle, and
Mission Control validator now fail if `Q` is confused with `K`, response or
group ordering drifts, rejected neighbours are admitted, attempts disappear,
or the recovery-only claim is promoted by analogy.

## 12. Cross-Product Coverage

Code, equations, exact formula syntax, roxygen help, vignettes, README, NEWS,
ROADMAP, known limitations, capability ledger, generated Markdown/HTML/census,
runtime oracle, Mission Control, and Totoro artifacts cover the same native
R/TMB supplied-`K` bivariate q2 location-intercept cell. This arc does NOT cover
DRM.jl/Julia, supplied `Q`, `animal()`, slopes, q4+, scale-side
structure, additional random effects, incomplete or weighted pairs,
nonconstant residual parameters, direct-SD or known-`V` models, non-Gaussian
families, intervals, coverage, AI-REML, or the future hierarchical-`sd()` arc.

## 13. Next Actions

1. Push the docs-only PR/CI receipt, wait for its exact-head CI, and leave PR
   #784 unmerged.
2. After this arc is separately merged, begin the Beta phylogenetic q1 `mu`
   prerequisite; do not start the hierarchical-`sd()` subarc early.
