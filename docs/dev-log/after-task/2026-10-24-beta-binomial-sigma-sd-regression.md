# After Task: Beta-binomial sigma random-effect SD regression

## 1. Goal

Add a first native TMB route for predictor-dependent variation in the
beta-binomial dispersion parameter. This records one slice of the general SD
regression programme. Family-wide and two-engine parity remain open.

## 2. Implemented

For complete-response data with fixed-effect-only `mu`, one ordinary sigma
random intercept can now use a fixed-effect SD formula, for example
`sd(group, dpar = "sigma") ~ z`. The seeded synthetic test checks recovery,
group-level SD outputs, conditional `sigma`, marginal simulation,
save/reload, constant-SD equivalence, and bootstrap refit target retention.
Unsupported combinations receive an explicit error. An adjacent Beta builder
regression was also fixed so ordinary Beta sigma SD formulas receive a clear
unsupported-route error.

## 3a. Decisions and Rejected Alternatives

The model is
`log(sigma_ig) = x_ig' beta_sigma + b_g`,
`b_g ~ Normal(0, tau_g^2)`, and `log(tau_g) = w_g' alpha`. The beta-binomial
precision remains `phi_ig = 1 / sigma_ig^2`. SD predictors must be constant
within each random-effect group. Bernoulli retains no free residual `sigma`,
and existing kernel scaling is unchanged.

This first route is limited to one ordinary sigma random intercept, complete
responses, and fixed-effect-only `mu`. Structured effects, slopes, and
simultaneous mean random effects were deferred because they require separate
identifiability and integration checks. Coverage calibration remains the
separate follow-up Shinichi approved.

Assumptions made without asking: the narrow complete-data route is a useful
first implementation cell; if the intended first cell required simultaneous
mean and sigma effects, the capability inventory must treat that addition as
still outstanding.

## 4. Files Touched

Implementation and test: `R/drmTMB.R`, `R/methods.R`, `src/drmTMB.cpp`,
`tests/testthat/test-beta-binomial-sigma-sd-regression.R`, and
`tests/testthat/test-beta-location-scale.R`.

Documentation and tracking: `NEWS.md`, `docs/design/02-family-registry.md`,
`docs/design/03-likelihoods.md`,
`docs/design/18-random-effect-scale-models.md`,
`docs/design/34-validation-debt-register.md`,
`docs/dev-log/general-sd-regression/inventory.md`,
`docs/dev-log/internal-roadmap.md`, `docs/dev-log/known-limitations.md`,
`vignettes/formula-grammar.Rmd`,
`vignettes/predictor-dependent-random-sd.Rmd`, and
`.unlazy/general-sd-regression/GATES.md`.

The R and C++ files contain other in-flight general-SD work. Their hashes
identify composite candidate files: `R/drmTMB.R`
`ef8e2cb1f3fa0d1aabea6cb63462456c037be87f862cd98bb960394732f59d37`,
`R/methods.R`
`d5b79fd2087ebc163da7aab03b9e584ca7396c4a0e13449039d22716a832d447`,
`src/drmTMB.cpp`
`601194d716c3816b787e4360f438a060bae3dd11292a90002d338da7bbb7a2a6`, and
`tests/testthat/test-beta-binomial-sigma-sd-regression.R`
`b3a19a6985dbc4376487ecb273795f100b9159c29d9d16f43c0abb33dd884d8b`.

## 5. Checks Run

- `devtools::test(filter = "beta-binomial-sigma-sd-regression", reporter = "summary", stop_on_failure = TRUE)` passed on the current candidate with 22 expectations.
- `pkgdown::check_pkgdown()` passed with existing Pandoc `--mathml` deprecation warnings.
- The predictor-dependent SD vignette rendered to `/private/tmp/predictor-dependent-random-sd-beta-binomial-sigma-20261024-final.html` (289 KB; SHA-256 `2b1ce1b1510f08d3719b41b7456b7b4e57f4a69a1228cc7fa895891368938fa7`).
- Scoped `git diff --check` over the implementation and documentation files passed. The broader worktree contains whitespace findings in unrelated in-flight files.
- Formula and documentation scans found no stale claim that beta-binomial sigma random effects are wholly unsupported.
- The separate Julia Tweedie relmat validation file passed 24/24 assertions, including fit-time covariance rejection. This covers Tweedie only; Beta-binomial Julia parity remains open.

## 6. Tests of the Tests

The recovery fixture generates independent beta-binomial observations with
group-specific latent log-sigma values and a fixed seed. Assertions check the
direction and approximate value of the SD slope, and a constant-SD fit is
compared with its explicit baseline random-intercept route. Negative tests
exercise within-group predictor variation and unsupported Beta sigma syntax.
The two-refit bootstrap check verifies workflow and target retention. Interval
coverage remains unmeasured.

## 7a. Issue Ledger

The open-issue search for “beta-binomial sigma random effect” found no matching
implementation issue. No issue was opened, changed, or closed.

## 8. Consistency Audit

The TMB likelihood applies the sigma random intercept before converting sigma
to beta-binomial precision. The builder, extraction, simulation, prediction,
family registry, likelihood notes, limitations, roadmap, NEWS, and rendered
example describe the same restricted route. No navigation change was needed.
The candidate branch remains dirty and substantially behind its local
`origin/main` reference, so these are candidate-only results.

Naturalness review covered this whole technical report. I rate its perceived
AI-like style 3/10 with medium confidence: the opening identifies the tested
route and remaining scope, while the residuals section gives concrete
exclusions. Factual claims were checked against the listed code, tests, and
rendered example. Reference checking is not applicable.

## 9. What Did Not Go Smoothly

The first article render exposed an adjacent Beta builder error: a sigma-SD
entry variable was referenced before creation. The builder now gives ordinary
Beta sigma SD formulas an explicit unsupported-route error, and the focused
Beta tests pass. An initial constant-SD comparison also showed that the base
beta-binomial sigma random-intercept route was absent; that baseline route was
added before the equivalence check was accepted.

## 10. Known Residuals

This route currently requires complete responses, fixed-effect-only `mu`, and
one ordinary sigma random intercept. Structured effects, slopes, correlated
blocks, broader recovery grids, profile validation, and interval-coverage
calibration remain open. At this native-slice report's cutoff, Julia support
was still open. The later bridge follow-up in
`docs/dev-log/after-task/2026-10-24-beta-binomial-sigma-sd-julia-bridge.md`
adds one direct-Julia and bridge fit with focused point-recovery checks; it does
not establish numerical parity or interval calibration. Coverage claims await
separate simulation calibration.

Negative space: no collaborator data, email, compute campaign, commit, merge,
push, or public capability claim was involved. The task does not complete the
general SD-regression goal.

## 11. Team Learning

Family-specific SD support must be audited together with the constant-SD
baseline, formula routing, simulation, and public outputs. A green likelihood
fit alone would have missed both the missing baseline and the adjacent Beta
builder regression.

## 12. Cross-Product Coverage

This report records the native R/TMB implementation and its recovery/workflow
checks. The later Julia bridge follow-up records a restricted direct-Julia
implementation and one live bridge fit. Same-data numerical parity and
interval calibration remain unverified. The separate Julia Tweedie check above
validates only its own related-matrix route.

Memory receipt: the drmTMB project dossier, `WHAT-WORKS.md`, and
`CROSS-REPO-GUARDS.md` were consulted. The routed `route.py` manifest was not
found for this worktree, so it could not supply a LOAD-FIRST list. A brain
search routed through the project dossier and confirmed that repository source
is the technical authority. The lane-preflight lesson reinforced exact-path
ownership checks. Golden Set: `memory_regression.py --list` was reviewed. The
applicable cases are `partial-arc-negative-space`, `completion-overclaim`, and
`worktree-is-a-branch`; no transcript evaluation was run because this report is
not an agent-response evaluation.

Covers: one native TMB beta-binomial sigma random-intercept SD cell and its
focused fit, recovery, output, and documentation checks. Does NOT cover: Julia
parity, other families or effect types, interval calibration, or programme
completion.
