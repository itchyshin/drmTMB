# Bernoulli logit relmat q2: bounded native candidate

## 1. Goal

Admit one native Bernoulli logit `relmat(1 + x | id, K = K)` or named `Q`
model with independent intercept and numeric slope fields and two selected
group SD formulas. Check the likelihood with an independent calculation and
one fixed-seed recovery fit. This is a candidate in the open general SD goal.

## 2. Implemented

`R/drmTMB.R` admits an unlabelled K/Q q2 base with two free constant field
SDs, and its two-formula extension with separate `(Intercept)` and slope SD
designs. It requires complete unweighted 0/1 responses, distinct canonical
coefficient targets, a numeric varying slope, and complete coefficient-row
mapping. It retains the q1 routes and rejects one or duplicate q2 SD targets.
`src/drmTMB.cpp` multiplies each model 18 field by its own selected SD row
when the coefficient-map flag is set; the previous single-row route remains
the fallback. The existing independent `N(0,K)` field priors are unchanged.

Marginal simulation now supports this fitted q2 route. It parses each scale
target's coefficient selector, matches its predicted SDs to the precision-node
labels, and draws the two independent fields with covariance `D_j Q^-1 D_j`.
The public simulator admits only a native Binomial `relmat` q2 fit with two
matching coefficient-specific SD formulas and no fitted correlations. Other
multi-field structured routes keep their previous refusal behavior.

For field `k`, `u_k ~ N(0,K)` and `b_{gk}=exp(W_{gk} alpha_k)u_{gk}`. The two
field covariances are `D_k K D_k` with zero cross-field covariance, and
`eta_i=X_i beta+b_{g(i),0}+x_i b_{g(i),1}`. Bernoulli probability is
`logistic(eta_i)`. Both direct SD formulas replace the constant field scales;
there is no fitted field correlation or residual `sigma`. A runnable synthetic
example is `tools/general-sd-regression/bernoulli-relmat-q2/example.R`.

## 3a. Decisions and Rejected Alternatives

The first route is logit, unlabelled relmat K/Q, strict Bernoulli 0/1,
complete rows, and no extra ordinary or structured provider. The already
supported q1 links and providers were left intact. The comparator base uses
the same supplied non-unit kernel as the two-SD model. No post-fit seed,
sample size, or threshold was changed. Assumption made without asking: a
32-group comparator is enough for equivalence checks, while the 160-group
fixture supplies the sole recovery gate. A different comparator sample size
would require a new preregistered test, not reinterpretation of this result.

## 4. Files Touched

Owned code: `R/drmTMB.R`, `R/methods.R`, `R/profile.R`, and `src/drmTMB.cpp`. The user-facing
`simulate()` description is updated in `man/simulate.drmTMB.Rd`. Rebuilt local artifacts:
`src/drmTMB.o` and `src/drmTMB.so`; `src/init.o` and `src/meuwissen_luo.o`
were linked without source or object changes. New tests:
`tests/testthat/test-binomial-relmat-q2-sd.R`. New evidence, runner, example,
source capsule, and check fragment: `tools/general-sd-regression/bernoulli-relmat-q2/`.
This report is new. One exact paragraph was briefly added to
`docs/design/03-likelihoods.md`, then removed without reverting its foreign
edits after the file preflight found 74 other refs with work. Its revised text
is in `design-advisory.md` for the active docs owner. No shared check-log,
NEWS, README, vignette, pkgdown, Julia, or bridge file was edited.

## 5. Checks Run

The q1 before-source capsule is SHA-256 `c15b9f44b2c8a4fe25a5d10c53a18ff30a91516df0e1fa151cb2f33960c63e21`.
The final R and C++ source hashes are `5e2107f3496ad8268222177ed6e5a766f264d12b57301c5984add0cb42118346`
and `54f635fd488b0887ea6d2e1f619cdcd80d196587b8d770214b5b4594c5ddeb77`.
After adding marginal simulation and its documentation, `R/methods.R` is
`715c33cee6aa222274c57f984c7148a736e86a0662067fcb7dd800b01ce35f3a`,
`R/profile.R` is
`12467e807eb50068cb306a9d36526a2b70cd07478db6d4a7d7d0faa63d106791`,
`man/simulate.drmTMB.Rd` is
`4e14b37ff5a232009dd20b75901f248c9369ee50a2c0b9648f2e2eaa6e962062`, and the
updated q2 test is
`0f4a73467e2792268a74b5cb529fcee705c0dbe9f68d51a53af06d44a3a383c0`.
The regenerated 15-member source capsule SHA-256 is
`b59cb690ac400ca13c7844e9a09c46c765d6a5de7a6a602b62bac4cbc24d9acf`; the
manifest SHA-256 is
`ab99ea281f22012e08f600363aceb849ac2db1f587ea3346d48d20e8eeda375b`.
The first `pkgbuild::compile_dll(force=TRUE)` call only installed an existing
object (`make: Nothing to be done`); it was excluded from evidence. After
touching the owned C++ source, the second build compiled `drmTMB.cpp` and
linked `drmTMB.o init.o meuwissen_luo.o` with temporary `-O0 -g0`, one
compiler, and one BLAS/OpenMP thread. The DLL SHA-256 changed to
`82f5d958e0f382a65da83b723baecb617bb397bb4a125bdabad00ef278565c6b`.
The loaded pkgload copy and source DLL had matching MD5
`c143967e78a108133fa9977a561dbe05` in a separate load check and the
later exact q1 Julia neighbor log. Build work stayed under the stated 120 s.

The 160-group, 32-repeat, seed-2026102817 main test passed 58 assertions in
18.3 s. Its two SD slope estimates were `0.578755` and `-0.483936`, versus
`0.6` and `-0.5`; convergence was 0 and the outer fixed-parameter gradient
maximum was `6.36e-10`. The independent dense Laplace negative log likelihood
was `3174.742314671062`, versus native `3174.742313827634`: absolute gap
`8.4343e-7` below the frozen `1e-4` gate. Conditional predictor maximum gap
was `8.90e-7`; independent mode gradient `2.24e-6`; score and Hessian finite
difference gaps `7.86e-8` and `2.32e-10`. Both independent mode starts
converged to the same objective. This checks the implementation, not Laplace
accuracy against exact marginal integration.

The 32-group comparator passed 65 assertions. K/Q negative log likelihood
gap was 0; reversing SD formula order changed it by `1.14e-13`;
constant-SD versus no-SD base changed it by `4.72e-10`. Named fixed and SD
coefficients and both base field scales passed their frozen absolute gates.
All five comparator fits converged with fixed gradients at most `6.61e-9`.
The standalone example converged in 9.0 s.

After adding q2 marginal simulation, the complete focused q2 test file passed
after `devtools::load_all()` with `NOT_CRAN=true` and the summary reporter.
An initial direct `test_file()` call without package setup failed because
`bf()` and `drmTMB()` were not loaded; the corrected invocation passed. It
checks fixed-seed
reproducibility, the `re.form = ~0` alias, same-seed conditional-versus-marginal
behavior, reversed formula order, and direct agreement between each simulated
SD matrix column and the corresponding public fitted SD prediction in
precision-node order. The q2 recovery test now also checks target discovery and
a two-replicate bootstrap refit. The existing q1 logit related-matrix workflow
passed 22 expectations, including marginal simulation. A post-change probit/cloglog
Julia neighbor attempt was interrupted during package loading after exceeding
its 65-second estimate; it has no test outcome and is not counted as a pass or
model failure. The earlier q1 Julia neighbor pass predates this simulator edit.
`tools::checkRd("man/simulate.drmTMB.Rd")` passes after correcting the q2
markup escape and a non-ASCII apostrophe encoding warning. The source and Rd
now contain matching `relmat()` text.

The first q2 bootstrap workflow attempt returned two refit errors because the
generic refitter supplied the internally stored all-one weight vector as an
explicit argument. The refitter now omits all-one weights and still passes
non-unit weights. The selected 160-group recovery test passed 31 assertions,
including two successful bootstrap refits with the SD target identity retained.
The full q2 test file and the neighboring
`test-binomial-sd-target-workflows.R` both passed.

An anchored six-context Binomial neighbor run finished in 212.2 s with 484
passes and one existing q1 probit/cloglog Julia setup error because its
`DRMODELS_JL_PATH` was unset. The exact failed test block was rerun from its
unmodified AST with the existing pinned q1 Julia candidate and offline depot:
exit 0, 26 expectations, no failure or warning. It is q1 neighbor evidence,
not q2 Julia parity. Raw logs and metrics are under the evidence directory;
the initial failed neighbor log remains intact.

## 6. Tests of the Tests

The assembly test failed on the pre-change Binomial q1-only guard before the
source edit. An intermediate test asserted a nonexistent metadata field and
failed twice; it was corrected to check the two canonical public target names.
Adverse assembly tests reject one or duplicate selectors,
wrong coefficient, nonconstant group SD predictor, zero slope loading,
constant-loading nonidentifiability, probit, animal q2, labelled relmat q2,
count responses, weights, and malformed coefficient-row maps. The low-level
test mutates a single row to `-1` and then to a positive but wrong-size map.
The independent oracle was derived from full named `K`, rather than TMB's
internal precision, and checked score and Hessian away from the mode.

## 7a. Issue Ledger

A narrow open-issue search for `Binomial relmat q2` found tracker #1464 and
simulation framework #59, without an exact implementation issue. No issue was
posted or closed for this unlanded candidate. The broader general SD goal
remains open.

## 8. Consistency Audit

The code, R syntax, and equations agree on two independent fields, raw
non-unit K, a log SD link, and no free correlation. The existing q1 and
slope-only relmat tests ran as neighbors. An exact status-inventory search
used the pattern
`binomial.{0,70}relmat|bernoulli.{0,70}relmat|relmat.{0,70}(binomial|bernoulli)|q2.{0,60}sd|sd.{0,60}q2`
with `rg -n -i` over README, internal-roadmap, NEWS, known-limitations,
formula-grammar design/vignette, and `_pkgdown.yml`; its raw output is
`status-inventory-rg.log`. Public status maps were not promoted. The
design-file preflight and scoped lease receipts were reviewed; docs ownership
coordination is pending. The `simulate.drmTMB` roxygen text and its generated
Rd content were updated together. Package-wide `devtools::document()` was not
run because multiple documentation lanes have live changes in this heavily
dirty worktree; the exact native simulation entry was checked in source and Rd.

## 9. What Did Not Go Smoothly

The first build was a timestamp-driven no-op; the real rebuild was required
before a scientific fit. The first comparator used TMB `parList()` on a full
random-plus-fixed vector, causing a warning and wrong base SD extraction.
Using reported `sd_phylo` and public `base$sdpars$mu` resolved that test
harness error without changing its threshold. An early neighbor filter also
matched unrelated beta-binomial integration; that run was interrupted and is
not evidence. The exact neighbor filter reached one Julia test without a
configured checkout; its selected test passed after using the already pinned
candidate. The design file had overlapping foreign-ref work, so its proposed
paragraph remains an owned advisory rather than an applied design update.
The post-change Julia neighbor recheck exceeded its runtime estimate during
Julia package setup and was interrupted before the model test produced a result.

## 10. Known Residuals

This candidate is uncommitted in a heavily dirty shared worktree. The required
design-doc integration and public status review remain pending. `se = FALSE`
made `pdHess` null in the measured fits; outer curvature and interval
identifiability were not established. One seed does not measure bias,
coverage, or numerical reliability across data regimes. The q2 bootstrap smoke
passed with two replicates. Profile interval execution remains unverified: a
64-group fixture returned unavailable endpoints, and profiling the frozen
high-information fixture exceeded the three-minute limit and was stopped.
Other links and providers, missing data, Julia q2 parity, and release support
remain unverified.

## 11. Team Learning

The source file and object timestamps must be checked after a build command;
`pkgbuild::compile_dll(force=TRUE)` can install without recompiling when an
object is newer. A named full-kernel oracle and independently permuted K/Q
inputs reveal row and scale mistakes that internal precision reuse would
miss. A public `sdpars` check is safer than applying TMB `parList()` to a full
latent vector. Bootstrap refits should omit internally stored all-one weights
so a semantically unweighted fit remains unweighted when reconstructed. A
selected AST rerun can isolate one missing-environment neighbor test without
repeating a costly native suite.

## 12. Cross-Product Coverage

The candidate covers native logit Bernoulli 0/1, one unlabelled relmat K/Q
intercept and independent numeric slope, no-SD base, two selected SD formulas,
conditional prediction and conditional simulation smoke, canonical SD
extraction, saved-object prediction, seeded marginal simulation from both
coefficient-specific structured fields, `~0` alias behavior, one dense
likelihood oracle, and a two-replicate q2 bootstrap refit smoke. It does NOT
cover other Binomial links in q2, grouped count responses, weighted responses,
labelled blocks, other providers, extra random effects, missing-data
combinations, successful q2 profile interval execution, interval calibration,
Julia q2 parity, or public status-map/release promotion.

## Prose assessment

Independent technical report for R package contributors; full draft
self-reviewed 2026-10-28. Perceived AI-like style: 3/10, moderate confidence:
the exact NLL comparison and named files keep the report specific, while the
required twelve-section scaffold makes the rhythm formal. The long checks
section helps reproduce the result but may be shortened when the candidate
lands. Science gate: pass for the bounded equations and measured single-seed
claims, with coverage explicitly untested. Factual gate: pass against the raw
logs, RDS metrics, source hashes, and build log named above. Reference gate:
not applicable; no external literature claim is made. No prior draft control
was used for this self-review.
The saved-draft exact-assessment validator was not run (`NOTASSESSED` for
that validator); this manual assessment is an editorial note only.
