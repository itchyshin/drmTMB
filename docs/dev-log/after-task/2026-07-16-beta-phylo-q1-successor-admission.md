# After Task: Beta phylogenetic q1 successor admission

## 1. Goal

Complete PR 1 of the approved two-PR Beta phylogenetic
location-scale-scale sequence: admit one native univariate ML `beta()` model
with an unlabelled q1 intercept-only `phylo()` effect in `mu`, fixed-effect
family `sigma`, and one constant latent phylogenetic location-effect SD. Cap the
claim at `point_fit_recovery`, preserve the moderate-information HOLDs, and do
not begin direct latent-`sd()` regression before PR 1 merges and its exact
post-merge CI is green.

## 2. Implemented

The R builder, native TMB Beta likelihood, prediction, extraction, diagnostic,
and profile-target routing admit only the exact constant-SD q1 phylogenetic
`mu` cell. The capability ledger promotes `mc-0017` only to
`point_fit_recovery` and adds `mc-0676` for the rejected remainder. Direct
`sd(species, level = "phylogenetic") ~ 1 + x` remains rejected and belongs only
to PR 2.

## 3. Mathematical Contract

For observation `i` in species `s(i)`, PR 1 fits

```text
y_i | a ~ Beta(mu_i phi_i, (1 - mu_i) phi_i)
logit(mu_i) = beta_0 + beta_x x_i + a_s(i)
log(sigma_i) = gamma_0 + gamma_x x_i
phi_i = sigma_i^(-2)
v_aug ~ Normal(0, Q_aug^(-1))
a_aug = tau v_aug
```

TMB stores the scaled field `u_phylo = a_aug`; it does not store the unit field
`v_aug`. Thus family `sigma` controls conditional Beta precision through
`phi = sigma^(-2)`, whereas `tau` is the constant latent phylogenetic
location-effect SD. These are distinct estimands.

## 4. Files Changed

- `R/drmTMB.R`, `R/methods.R`, `R/profile.R`, and `src/drmTMB.cpp` implement
  and expose the exact q1 route.
- `tests/testthat/test-beta-location-scale.R` supplies the independent joint-NLL
  and gradient oracle, prediction/extraction contracts, and exact negative
  neighbours.
- `tools/run-beta-phylo-q1-*.R` and their pure tests implement authenticated,
  retained-denominator recovery and the fail-closed estimator diagnostic.
- `docs/dev-log/simulation-artifacts/2026-07-16-beta-phylo-q1-pr1-*` records
  the retained prior HOLDs, D0 screen, successor smoke, and certification.
- `README.md`, `NEWS.md`, `ROADMAP.md`, `AGENTS.md`, formula-grammar source,
  known limitations, generated capability surfaces, and this report state the
  same bounded claim.

## 5. Checks Run

- Focused Beta contract after the exact PR 2 rejection repair: 107/107
  expectations passed.
- Successor runner contract: 76/76 pure expectations passed.
- Original repair-runner contract: 54/54 pure expectations passed after the
  source-package boundary repair.
- Extracted source-tarball runner tests: two intentional skips, one per
  development-runner file, because top-level `tools/` is excluded by
  `.Rbuildignore`; no failure and no package-runtime dependency on those files.
- Capability-ledger generator check: 30/30 generated outputs current.
- Capability-ledger unit tests: 37/37 passed.
- Runtime capability oracle: 18 verified response routes, G0/G1/G2 all zero.
- Mission Control validator: passed with `mc-0017` promoted and `mc-0676`
  preserving the rejected remainder.
- Final independent review: Fisher GO for the statistical boundary, Noether GO
  for symbolic/implementation/claim alignment, and Rose GO for public-surface
  consistency and two-PR sequencing. Gauss had already returned GO for the
  frozen-proposal diagnostic and recovery machinery before compute.
- `devtools::document()`: passed with no generated-file drift.
- `pkgdown::check_pkgdown()`: passed with no problems found.
- `pkgdown::build_site(preview = FALSE)`: passed. Rendered `index.html`,
  `AGENTS.html`, `ROADMAP.html`, `news/index.html`, and
  `articles/formula-grammar.html` expose the exact `g = 1024, m = 4` claim,
  retain `g = 256/512` HOLD, and distinguish family `sigma` from latent SD.
- `git diff --check`: passed outside verbatim `sessionInfo()` files, whose
  aligned console output intentionally contains trailing spaces.
- Broad `devtools::test()`: 38,964 passed, zero failed, 62 known warnings, and
  24 optional-DRM.jl skips. The post-edit Beta and runner-focused gates passed
  separately as recorded above.
- Final `devtools::check(document = FALSE, error_on = "never")`: zero errors
  and zero warnings. The outer R CMD check retained one pre-existing,
  report-only spelling `Rout.save` transcript NOTE; `devtools` reported
  0 errors, 0 warnings, and 0 actionable notes. Installed-package tests passed
  with the two intentional development-runner skips.

## 6. Tests of the Tests

The exact likelihood test reconstructs the augmented-GMRF joint NLL with
independent `dbeta()` and Gaussian-prior algebra at a displaced full parameter
vector, checks the analytic full gradient against central differences, and
confirms `phi = exp(-2 log_sigma)`. The new boundary test requests the exact
deferred `sd(species, level = "phylogenetic") ~ 1 + x` formula and verifies that
the Beta builder rejects its canonical `sd_phylo(species)` parameter before
fitting.

Runner negatives cover duplicate or overlapping seeds, caller RNG changes,
source/design/artifact drift, non-finite estimates, wrong output shapes,
partial/interrupted output, exact-design resume, D0-to-D1 authentication, and
objective-score disagreement under the frozen proposal.

## 7. Consistency Audit

The status inventory checked `README.md`, `ROADMAP.md`, `NEWS.md`, `AGENTS.md`,
`docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`,
`vignettes/formula-grammar.Rmd`, `R/drmTMB.R`, and the capability-ledger cells
and evidence. The exact search was:

```sh
rg -n -i 'beta.*phylo|phylo.*beta|g *= *256|g *= *512|g *= *1024|g *>= *1024|point_fit_recovery|sd\(species, level *=|family sigma|phi *= *sigma|D0|INCONCLUSIVE' README.md ROADMAP.md NEWS.md AGENTS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd R/drmTMB.R docs/dev-log/dashboard/capability-ledger/cells.tsv docs/dev-log/dashboard/capability-ledger/evidence.tsv
rg -n -i 'beta.*phylo.*planned|phylo.*beta.*planned|beta.*phylo.*unsupported|phylo.*beta.*unsupported|g *>= *1024' README.md ROADMAP.md NEWS.md AGENTS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd R/drmTMB.R docs/dev-log/dashboard/capability-ledger/cells.tsv docs/dev-log/dashboard/capability-ledger/evidence.tsv
```

Remaining `planned` or `unsupported` matches describe excluded neighbours,
not the admitted q1 cell. Every `g >= 1024` match explicitly rejects that
generalization. Historical stopped-arc notes remain intact and are superseded
by this successor report rather than rewritten.

## 8. GitHub Issue Maintenance

Read-only search found broad open issues #59, #491, and #710, but no focused
Beta phylogenetic q1 issue. No duplicate issue was opened or closed. Planning
handover PR #785 was verified as a three-file documentation-only transfer,
merged at `7eddc4811ed22dbcd9652da321acb1f3494d3f73`, and reconciled into the PR 1
branch before PR 1 closeout.

## 9. What Did Not Go Smoothly

The first evidence arcs exposed overlapping numeric seeds, incomplete DGP RNG
freezing, a hidden-output overwrite hole, and insufficient source/artifact
authentication. Those failures were repaired and covered before the successor
campaign. During closeout, Noether caught a unit-field versus scaled-field
notation error, stale Beta guidance, and the absence of an exact direct-`sd()`
rejection test. Fisher found one nonexistent ledger evidence path. Rose found
stale README/AGENTS state and the unresolved documentation-transfer PR. All
were repaired before the final GO verdicts.

The first final `devtools::check()` then exposed a packaging-only test defect:
two development-runner tests sourced top-level `tools/` files unconditionally,
but `.Rbuildignore` intentionally removes `tools/` from the source tarball. The
tests now run their full contracts in a source checkout and record one explicit
skip each in an extracted tarball. This preserves development coverage without
shipping campaign runners as package runtime files.

## 10. Team Learning

The N principle should be tested as a ladder, not used as an assumption. Here
larger information changed the decision, but the result supports only the exact
tested cell. The data do not establish a universal species threshold or why the
moderate-information bias occurs. A higher-accuracy diagnostic may motivate a
separate estimator-method arc only if it gives stable, authenticated causal
evidence.

Symbolic alignment must name unit and scaled latent fields separately. A
formula-boundary claim also needs the exact rejected syntax in a regression
test; parser inspection alone is weaker evidence.

## 11. Known Limitations

The retained evidence is deliberately uneven across the N ladder. Prior
`g = 256` cells remain HOLD. In the fresh successor campaign, exact
`g = 512, m = 4` also HOLDS because mean log-latent-SD bias was `-0.10129`
(MCSE `0.01255`; 95% MC interval `[-0.12589, -0.07668]`). Exact
`g = 1024, m = 4` PASSES at `-0.04645` (MCSE `0.00906`; interval
`[-0.06420, -0.02870]`). This is not `g >= 1024` and not a universal minimum
sample size.

D0 was `INCONCLUSIVE`: all five fits, Hessian, ESS, maximum-weight, and batch
gates passed, but sign stability passed only 2/5. D1 did not run. Therefore the
work attributes the moderate-information bias to neither Laplace approximation
nor finite information.

PR 1 does not support REML, q2/q4, labels, phylogenetic slopes, phylogeny in
family `sigma`, direct latent-`sd()` regression, hierarchical `sd()` RHS random
effects, `zero_one_beta()`, missing or external data, intervals, coverage,
`inference_ready`, or `supported` claims.

## 12. Cross-Product and Documentation Coverage

`drmTMB` R/TMB is the sole implementation and evidence authority. No claim or
code was transferred to `DRM.jl`, `gllvmTMB`, or `GLLVM.jl`; Julia remains
optional. The pkgdown source uses the exact R syntax and keeps family `sigma`
separate from latent phylogenetic SD. Mission Control reports the exact
`g = 1024, m = 4` recovery boundary, both moderate-information HOLDs, D0
inconclusiveness, and the PR 2 gate.

## 13. Next Actions

Complete final package, pkgdown, rendered-site, and PR-head CI gates; open and
merge PR 1 only if they remain green. Then verify the exact post-merge
R-CMD-check run for the PR 1 merge commit. Only after that receipt may PR 2 add
`sd(spp_id, level = "phylogenetic") ~ 1 + x` for the same latent `mu` effect.
PR 2 remains a separate branch, review, evidence campaign, and pull request.
