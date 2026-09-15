# After Task: Dinnage independent evaluation, wave 3 — M1 (eleven sites), M2, S6 note, S2/D-252, S3 doc

## Goal

Land the four items owed after the wave-1 arc's Fisher review
(`docs/dev-log/audits/2026-09-13-dinnage-wave1-review.md`) as surgical, fresh-context-reviewed commits on
`claude/audit-dinnage-wave1-20260913` (draft PR #1361): M1 (the eleven non-Bernoulli `mi()` quadrature
sites — the only owed finding that biases a point estimate through the likelihood), M2 (`sigma()`/
`predict()`/`residuals()`/`simulate()` reporting the soft-clamped scale), S6 (a design note on bootstrap-
interval bias, no code), S2 (a reconciliation note under D-252, then the scale-independent
`drm_constant_residual_sigma()` fix, contingent on Fisher's concurrence), plus the S3 help page telling
the truth about the log-scale MAP. Close with an after-task report, a Melissa plan-actual row, and a
handover. Full brief: `LOOP/GOAL.md`, `LOOP/ultra-plan.md`.

**This report supersedes a mid-arc draft** written before Fisher's code review (F-A), the S2b test, three
follow-up repairs, the second `R CMD check --as-cran`, and one further Fisher review landed. It is written
from `git log --oneline origin/claude/audit-dinnage-wave1-20260913..HEAD` (26 commits) at read time, HEAD
`3afed7feb`.

## Implemented

Twenty-six commits land on this branch beyond `origin/claude/audit-dinnage-wave1-20260913`. The load-bearing
ones, in order:

- `fc461aae4` — **M1**: `weights(i)` moved outside the mixture sum and onto the observed-row imputation
  prior at all eleven non-Bernoulli `mi_family` quadrature blocks in `src/drmTMB.cpp` (ordinal,
  categorical, beta, zero-one-beta, beta-binomial, Poisson, NB2, truncated NB2, lognormal, gamma,
  Tweedie), matching the Bernoulli template repaired in wave 1 (`bb7b0de8b`).
- `350e76527` — test-only: states what the Tweedie duplication arm does and does not guard (Fisher F-A
  item 1).
- `0526baa2f` — **M2**: one helper, `drm_clamped_sigma_eta()` (`R/methods.R`, immediately above
  `drm_inverse_link`), applies `drm_softclamp_log_sd()` to the sigma-type linear predictor at the two live
  prediction paths (`predict.drmTMB()`, `drm_marginal_predict()`), so `sigma()`, `predict(dpar = "sigma")`,
  `residuals()`, `fitted()` and `simulate()` all report the scale the likelihood actually used.
- `d44a495be` — **S3**: `?drm_phylo_penalty` rewritten to state the log-scale MAP mode correctly
  (decision D-266: document, don't re-estimate).
- `37b5d7ce6` — **S6 + S2a**: design notes `docs/design/274-bootstrap-interval-bias.md` and
  `docs/design/275-repeatability-scale-and-residual-variance.md`, plus Fisher's Part B (documents) review
  written to `docs/dev-log/audits/2026-09-14-dinnage-wave3-review.md`. Both ACCEPT-WITH-CHANGES, twelve
  required changes applied in this commit.
- `b7224867c` — issue-comment drafts for #1307, #1308, #1312, #1315 (files only, **not posted**).
- `3192db3f6` — **S2**: `drm_constant_residual_sigma()` corrected to the marginal formula
  `exp(b0 + sum(omega_k^2))`; `drm_variance_ratio()`/`drm_variance_ratio_delta()` rebuilt around
  `denom_groups`/`focal_index` so both loci change, per Fisher's scope correction to note 275 §5 (see
  Mathematical Contract).
- `89f055a50` — Fisher review Part A of M1 (`fc461aae4`) and M2 (`0526baa2f`): both ACCEPT-WITH-CHANGES.
- `278809289` — issue-comment draft for #1301 (S2; not posted).
- `2a5b0665e` — **M2 follow-up**: `predict_parameters()`'s Wald interval and `predict(dpar = "sd(group)")`
  clamped onto the same band as the point estimate (Fisher F-A items 4–6).
- `b49ce9f70` — test/build repair: `test-zi-nbinom2.R` updated to the post-M2 clamped contract (found by
  the first `R CMD check --as-cran`); `.Rbuildignore` gains `.scratch` and `tools-scratch`.
- `a6b329bcf` — Fisher review of S2b (ACCEPT-WITH-CHANGES) and of the M2 follow-up
  (**REJECT**: the clamped Wald endpoints collapse to zero width at saturated rows, measured coverage 0).
- `e86359fe2` — **M2 follow-up 2**, repairing the REJECT: clamp-bent rows in `predict_parameters()` now
  return `NA` endpoints flagged `conf.status = "clamp_limited"`; in-band rows keep the ordinary Wald
  interval on the raw predictor.
- `4ae2f5d99` — **S2b follow-up**, closing Fisher's S2b REQUIRED items 1–5: measures the structured-sigma
  correlation diagonal directly instead of trusting a type label; fixes the `mu:`/`sigma:` prefix-regex
  miss that made phylo-on-both-loci produce 0 derived rows; prints `residual_variance.message` when the
  derived table is empty for a named reason.
- `d61f65183` — **M2/S2 consistency**: `drm_constant_residual_sigma()`'s intercept now passes through
  `drm_clamped_sigma_eta()` before the marginal formula, so `summary()$derived$residual_sd` agrees with
  `sigma()` on a clamp-active fit (Fisher measured 3.07 vs. 1.28 before); two Rd `\link{}` targets to the
  internal `drm_clamped_scale_families()` changed to code font (R CMD check `WARNING`, run 1).
- `1540d95fe` — NEWS.md wave-3 section written in full (M1, M2, S2, S3); `predict_parameters()`'s help
  text and the model-workflow vignette's `conf.status` table corrected to say `clamp_limited` selects on
  the estimate (measured coverage of kept rows 0.985 → 0.882 near the band edge), not merely that the
  likelihood there is flat (Fisher follow-up-2 items 1–4).
- `3afed7feb` — Fisher's review of the `predict_parameters()` repair (`e86359fe2`): **ACCEPT-WITH-CHANGES**,
  wording items applied in `1540d95fe`.
- Seven `loop:` checkpoint commits recording arc state at each handoff.

**Still pending at read time** (see Known Limitations and Next Actions): a fresh-context Fisher review of
the S2b follow-up (`4ae2f5d99`) has not been written into the review file — its section list ends at
`### M2 follow-up 2 (e86359fe2)` and `## Part B`, with no `### S2b follow-up` heading yet, though a scratch
probe (`scratchpad/fisher-s2b2-green.txt`) suggests that review is in progress. The second
`R CMD check --as-cran` (on `d61f65183`) finished: **Status: 1 WARNING, 1 NOTE** — the WARNING is the
environment's missing `checkbashisms` script, the NOTE is "New submission"; 0 errors, 0 package
warnings, tests OK (44 s), vignette re-build OK (64 s). The branch was pushed as `666c1865a` to the
existing draft PR #1361 (head confirmed; later commits are docs-only). `docs/dev-log/plan-actual/2026-09-14-dinnage-wave3.md` and
`docs/dev-log/handover/2026-09-14-claude-handover-dinnage-audit.md` do not exist on disk — `[[TO-FILL]]`.

## Mathematical Contract

**M1.** For each of the eleven families, the pre-fix objective computed, for observed row *i* with
imputation weight $p_1$ and component densities $f_1, f_0$:
$$\text{nll} \mathrel{-}= \log\!\big(p_1 f_1^{w_i} + p_0 f_0^{w_i}\big)$$
— weight *inside* the mixture components, none on the combining `logspace_add()` or on the observed-row
prior. The fix computes:
$$\text{nll} \mathrel{-}= w_i \log\!\big(p_1 f_1 + p_0 f_0\big), \qquad \text{nll} \mathrel{-}= w_i \cdot (\text{observed-row prior log-density})$$
so `weights = c` (constant) is exactly equivalent to literal `c`-fold row duplication, and the weighted
objective is exactly `c` times the unweighted one at both optima. Two exceptions are recorded, not fixed:
`mi_family == 0` (Gaussian latent, Laplace-integrated, `src/drmTMB.cpp` near lines 1215/1257/4429) still
breaks weight invariance because its covariate-model density carries no `weights(i)` inside the latent
integral; and Tweedie's fixed Gauss–Legendre quadrature support is sized from `stats::var()` of the
*observed* covariate (an `n - 1` divisor), so literal row duplication moves the support and the two
objectives agree only to about 1e-2, not machine precision.

**M2.** `drm_clamped_sigma_eta(object, dpar, eta)` is a no-op unless `dpar` is a sigma-type parameter of a
family in `drm_clamped_scale_families()`, in which case it returns
`drm_softclamp_log_sd(eta, object$model$tmb_data)` — the identical transform the TMB objective applies —
before both the `type = "link"` return and `drm_inverse_link()`. This changes no estimated parameter; it
changes what the accessors *report* to match what the likelihood *evaluated*, closing the gap Russell
measured as a 297-nat log-likelihood mismatch. The third candidate site, `predict_random_scale_dpar()`,
only ever sees `sd(...)`-prefixed dpars and cannot fire for sigma; it was read, not patched.

**M2 follow-ups.** `predict_parameters()` took its point estimate from the now-clamped `predict()` but
built its Wald interval from the raw predictor, so 60/200 rows on a clamp-active fixture showed an
estimate outside its own interval (`2a5b0665e` fixed this by clamping both endpoints — **REJECTED** by
Fisher: a Wald interval of the reported quantity is undefined where the likelihood is flat, and clamping
the endpoints collapses the interval to zero width at saturated rows, measured coverage 0 against an
unclamped truth). `e86359fe2` repairs this correctly: clamp-bent rows (raw eta outside `[lo, hi]`, the same
gate `drm_clamped_sigma_eta()` uses) get `NA` endpoints and `NA` std.error with
`conf.status = "clamp_limited"`, `interval_source = "not_available"` — the vocabulary `profile()` already
uses for direct SD targets; in-band rows keep the ordinary Wald interval, since the clamp is the identity
there. `predict(dpar = "sd(group)")` similarly returned `exp(raw eta)` while the kernel and the fit's own
`sdpars` use the clamped value (measured 0.12 vs. 0.78 on a narrow-band fixture); it now applies
`drm_softclamp_log_sd()` and `drm_exp_sd_logscale_guarded()` like `sd_mu_group_values()`. Fisher's review
of `e86359fe2` (`3afed7feb`, ACCEPT-WITH-CHANGES) additionally found that `clamp_limited`'s own
justification was false near the band edge — 13/100 bent rows on the test fixture have a clamp derivative
above 0.9, so `NA` there is not "the likelihood is flat," it is a real selection on the estimate (measured
coverage of the rows that *are* kept: 0.985 → 0.882 as the true predictor nears the edge); the help text
and the model-workflow vignette's status table now say so (`1540d95fe`).

**S2.** The exact fix computes the marginal residual variance
$$E[\sigma_i^2] = \exp\!\big(2\beta_{\sigma,0} + 2\textstyle\sum_k \omega_k^2\big)$$
for sigma carrying ordinary random intercepts or a phylogenetic random intercept on a unit-diagonal
correlation matrix, rather than the old `exp(b0)` (sigma's *median*, not its RMS). Fisher's ruling in
"Ruling on 275 §5" supplies the reason the phylogenetic correlation matrix cancels out of a marginal,
per-observation moment: with $u \sim N(0, \omega^2 C)$ and $C_{ii} = 1$ under drmTMB's default
height-normalised (`correlation = TRUE`) convention, every tip has $u_i \sim N(0,\omega^2)$ identically, so
$E[\sigma_i^2] = \exp(2\beta_0 + 2\omega^2)$ regardless of off-diagonal tree structure — verified against
`R/phylo-utils.R:250-252` (the height-normalisation) and `R/phylo-utils.R:226,273,109-113`
(ultrametricity enforced exactly for that path). A random **slope** on sigma, or a structured sigma effect
whose diagonal is not verified unit (`animal()`/`relmat()`/`spatial()`, or `phylo(..., correlation = FALSE)`),
returns `NA` with a named reason instead of a silently wrong number — D-252's discipline ("never return
NaN for a quantity that is defined") applied to the one case that genuinely is undefined.

Fisher's ruling also corrected a scope error in note 275 §5 as first drafted: it claimed both call sites —
`drm_derived_summary_rows()` (`summary()$derived`) and `drm_variance_ratio()`
(`heritability()`/`icc()`/`repeatability()`) — would "inherit the corrected value with no further change."
They do not: `drm_variance_ratio()` only ever consumed `drm_constant_residual_sigma()`'s output as a
finiteness *gate* and rebuilt the residual from `beta_sigma` directly. `3192db3f6` fixes both call sites:
`denom_groups`, each a `(positions, value-function)` pair, so the residual group's value function becomes
`exp(2*t[1] + 2*sum(exp(2*t[-1])))` when sigma carries extra random-effect positions, with the
numeric-gradient delta method (`h = 1e-5`, central difference) extended over those positions.

**S2b follow-up.** Fisher's S2b review (`a6b329bcf`) found the refusal branch wrongly claimed a
non-unit diagonal for `spatial(coords=)` on sigma; `4ae2f5d99` adds
`drm_structured_sigma_unit_diagonal()`, which *measures* `diag(solve(precision))` (tol 1e-3) instead of
trusting a type label for a `q == 1` structured sigma effect — measured `diag(Sigma) = 1.000001` on a
`spatial()` fixture, so the closed form now applies where it was wrongly refused. For a `q > 1` joint block
(the same structured term shared across `mu` and `sigma`, e.g. `phylo()` on both), the whole-block
precision spans a latent internal-node basis and is not the observed units 1:1 (measured directly: 38×38
for a 20-tip tree, diagonal range [0.838, 1]); that path is not inverted, and `type == "phylo"` there is
trusted on the pre-existing formula-grammar guarantee. Any other type in a `q > 1` block reports
`"structured_sigma_diagonal_not_checked"` rather than a false "not unit" claim. The `mu:`/`sigma:` label
prefix defeated the structured-effect regex at `R/heritability.R:458` and `R/methods.R:4933`; stripping it
lets phylo-on-mu-and-sigma reach both loci (measured share 0.7154951 identically at
`summary(fit)$derived$estimate`, `repeatability()$estimate`, `icc()$estimate` — previously 0 rows/abort).

**S3.** No estimator change (D-266). The roxygen states the compiled penalty term
`rate * sd - log(sd) - log(rate)` is the change-of-variables form of an exponential prior on `sd` with
`rate = -log(sd_alpha)/sd_u`; its mode in `log(sd)` (what the package reports) is `1/rate`, `0.334` at the
package defaults `sd_u = 1`, `sd_alpha = 0.05` — never zero under a flat likelihood.

## Files Changed

`src/drmTMB.cpp` (M1, +119/−33); `tests/testthat/test-dinnage-audit-m1-families.R` (new, 413 lines then
+10/−7 in `350e76527`); `R/methods.R` (M2 helper +35, then follow-ups: predict_parameters/sd(group) clamp,
S2 call-site rewiring, S2b diagonal-measurement helpers, residual_sd clamp consistency — cumulative well
over 300 changed lines across the arc); `man/predict.drmTMB.Rd`, `man/sigma.drmTMB.Rd`,
`man/predict_parameters.Rd` (regenerated, several passes); `tests/testthat/test-dinnage-audit-m2.R` (new,
129 lines, extended twice for the two follow-ups); `R/predict-parameters.R` (+16/−… in `1540d95fe`,
`clamp_limited` wording); `vignettes/articles/model-workflow.Rmd` (+1, `clamp_limited` row); `R/penalty.R`,
`man/drm_phylo_penalty.Rd` (S3, +26/−4 each); `docs/design/274-bootstrap-interval-bias.md` (new, 276
lines); `docs/design/275-repeatability-scale-and-residual-variance.md` (new, 305 lines);
`docs/dev-log/audits/2026-09-14-dinnage-wave3-review.md` (new, grows across five commits to 1819 lines);
`docs/dev-log/issue-drafts/2026-09-14-dinnage-wave3/{1301.S2,1307.M1,1308.M2,1312.S3,1315.S6}.comment.md`
(new, drafted, not posted); `R/heritability.R` (S2 +165/−… then S2b follow-up +8/−…);
`man/heritability.Rd`, `man/summary.drmTMB.Rd` (regenerated); `tests/testthat/test-dinnage-audit-s2.R`
(new, 202 lines, extended +48/−… in the S2b follow-up); `.Rbuildignore` (+2, `.scratch`,
`tools-scratch`); `tests/testthat/test-zi-nbinom2.R` (+7/−1, clamped-contract repair); `NEWS.md`
(wave-3 section, four bullets, written in full by `1540d95fe`). `LOOP/*` and `.unlazy/dinnage-2/**` are
lane infrastructure, the latter git-ignored.

## Checks Run and Exact Outcomes

Per-leaf ledger `.unlazy/dinnage-2/GATES.md` + `gates/leaf-*.md` (EVIDENCE lines), read 2026-09-14/15:

- **M1a** (test-first, red on pre-fix `.so`): 4/4 sub-gates MET. Red proof `scratchpad/m1-red-final.txt`:
  **43 Failures, 0 Errors** (4 assertions × 10 families + 3 for Tweedie). Prepared patch `scratchpad/m1.patch`
  (22 hunks, `src/drmTMB.cpp` only) not applied at M1a time. `mi_family == 0` probe
  (`scratchpad/m1-gaussian-probe.txt`): also breaks weight invariance, max coefficient difference 0.0129 at
  `weights=2` vs. duplication — reported, not fixed.
- **M1b** (apply + recompile + green): 3/3 MET. `scratchpad/m1-green.txt`: 0 Failures, all 11 families.
  `scratchpad/m1-regress.txt` (filter `dinnage-audit-wave1|missing-predictor|missing-data|impute|mi-`): 0
  failures, 0 errors. Manual read: no `weights(i)` remains inside a quadrature `log_y` at the eleven sites;
  lognormal's Gauss–Hermite nodes confirmed to already encode the prior.
- **M2**: `[ FAIL 0 | WARN 0 | SKIP 0 | PASS 10 ]` on the new test; existing
  `clamp|residual|simulate-re-form` suite `[ FAIL 0 | WARN 11 | SKIP 5 | PASS 80 ]` (pre-existing
  skips/warnings). Red proof `scratchpad/m2-red.txt`: 7/10 expectations failed, logLik gap 297.2 nats.
- **M2 follow-up** (`2a5b0665e`): red `scratchpad/m2-repair-red.txt`, 5 failures (predict_parameters
  containment, `sd(group)` value); green after; Fisher **REJECT** (measured coverage 0 at saturated rows).
- **M2 follow-up 2** (`e86359fe2`): red `scratchpad/pp-repair-red.txt`, **12 failing assertions**
  (`clamp_limited` flag not set on 10/10 sampled clamp-bent rows across link/response scale, `NA` not
  propagated to `conf.low`/`conf.high`/`std.error`, in-band Wald containment off by up to 0.006 at four
  probed rows because the earlier repair clamped in-band endpoints too); green after; Fisher
  ACCEPT-WITH-CHANGES (`3afed7feb`).
- **S6**: 3/3 MET. Note has 10 `## ` sections (243 lines); no `R/`/`src/`/`tests/` file touched by this
  leaf; Fisher Part B ACCEPT-WITH-CHANGES, items 6–10 applied.
- **S2a**: Fisher verdict MET — Part B ACCEPT-WITH-CHANGES on note 275 and the S3 roxygen, ruling CONCUR
  on scale-independence with the scope correction above.
- **S2** (`3192db3f6`): red `scratchpad/s2-red.txt`, produced by `assignInNamespace()`-restoring the
  pre-fix `drm_constant_residual_sigma()`/`drm_variance_ratio()`/`drm_variance_ratio_delta()` bodies over a
  freshly `load_all()`'d fixed package (chosen over reverting the files on disk, which would have discarded
  a concurrent agent's unrelated uncommitted edits sharing `R/methods.R`): **11 Failure/Error matches**
  across four fixtures — ordinary sigma RE (4 failed + 1 harness-artifact error), random slope on sigma (5
  failed, old code returns finite `exp(b0)` instead of `NA`), phylo-on-sigma (1 failed), constant-sigma
  control (0 failed, confirming the fix is a no-op there). Green: `[ FAIL 0 | WARN 1 | SKIP 0 | PASS 24 ]`
  (the WARN is a harmless optimizer-preset escalation, not a failure); broader regression filter
  `heritability|icc|repeatab|summary|derived` → 467 passed, 0 failed.
- **S2b follow-up** (`4ae2f5d99`, closing Fisher's REQUIRED items 1–5): red
  `scratchpad/s2b-repair-red.txt`, **5 failures** (`expect_message` on the random-slope fixture; phylo
  fixture's derived-row count, `residual_variance`, `estimate` all wrong; `repeatability()` erroring with
  "could not locate the working-scale parameter position"). Green:
  `[ FAIL 0 | WARN 1 | SKIP 0 | PASS 34 ]` on the file; full filter
  `dinnage-audit-s2|heritability|icc|repeatab|summary|derived|phylo-utils` → `[ FAIL 0 | WARN 1 | SKIP 1 | PASS 687 ]`
  (the one skip is the pre-existing DRM.jl-engine-unavailable skip).
- **`R CMD check --as-cran` run 1** (clean export, `git archive` of `2a5b0665e`): **Status: 1 ERROR, 2
  WARNINGs, 2 NOTEs.** The ERROR was `test-zi-nbinom2.R:202` pinning `predict(fit, dpar = "sigma")` to the
  raw-eta value on an extrapolation below the lower clamp — a real regression against the new clamped
  contract, not a false positive, repaired in `b49ce9f70`. The two WARNINGs: missing package anchors on
  two `\link{drm_clamped_scale_families}` Rd targets (repaired in `d61f65183`, code font instead of a
  link) and two tracked scratch directories flagged (`.scratch`, `tools-scratch`; `.Rbuildignore`'d in
  `b49ce9f70`). The two NOTEs (new-submission, top-level scratch files) are expected/pre-existing.
- **`R CMD check --as-cran` run 2** (clean export of `d61f65183`): in progress at read time
  (`scratchpad/ascran2/check.log` has reached "checking whether package 'drmTMB' can be installed", no
  `Status:` line yet; `meta.txt` has no `DONE` line) — **done at 21:15: `Status: 1 WARNING, 1 NOTE`,
  the WARNING being the absent local `checkbashisms` script and the NOTE the new-submission line; 0
  errors, 0 package warnings**.
- A Haiku mechanical-verification pass (`scratchpad/mv-1.md`, mid-arc, `gate-check.mjs --approve`)
  recorded 16/27 gates MET at that point and independently re-confirmed four fact checks (red/green files
  non-empty with the stated counts; commit list; the uncommitted-file set at that time; NEWS.md's wave-3
  header). It flagged `M2:G-M2-1`, `S2a:G-S2a-1`, `S2a:G-S2a-2` UNMET despite their `grep` output matching
  the leaf file's own stated `EXPECT` pattern — see What Did Not Go Smoothly. Those gates were rewritten
  to emit literal markers, and the final `gate-check.mjs --approve` then `--reverify` pass across all
  eight leaves reports **26 of 27 gates MET**; the one UNMET is the manual `REVIEW:G-R-2` ("no open
  REQUIRED item remains"), which waits on Fisher's S2b follow-up verdict.

## Tests of the Tests

- **M1** (`tests/testthat/test-dinnage-audit-m1-families.R`, new, 413 lines, 11 `test_that()` blocks, one
  per family): asserts the exact objective identity `obj_w2(p) == 2 * obj_w1(p)` at both optima (tol
  1e-6/1e-5, loosened to 1e-2 for Tweedie's duplication arm only, for the structural `stats::var()`
  reason above), `coef(w1) == coef(w2)`, `duplication == weights=2`, and `fit$opt$convergence == 0L` for
  every fit (Fisher's wave-1 caveat against asserting on a non-converged optimum). Red proof went through
  three drafts before the authoritative one: an early capped-reporter run
  (`scratchpad/m1-red-summary.txt`) showed only 6/11 families failing (false negative — see What Did Not
  Go Smoothly); an uncapped re-run (`scratchpad/m1-red.txt`) showed all 11; the final, fuller suite
  produced `scratchpad/m1-red-final.txt`, **43 failures**. Green: `scratchpad/m1-green.txt`, 0 failures.
  Test-only follow-up `350e76527` narrows the Tweedie duplication arm's claimed coverage in a code comment
  after Fisher's F-A item 1 noted it "guards nothing" as originally worded.
- **M2** (`tests/testthat/test-dinnage-audit-m2.R`, new, 129 lines, 5 `test_that()` blocks): red
  `scratchpad/m2-red.txt` via `git stash push -- R/methods.R` to restore the unfixed accessor against a
  clamp-active fixture — 7/10 expectations failed (hand log-likelihood vs. `logLik()`, 4
  `sigma()`-vs-clamped-eta expectations, Pearson SD, `simulate()` per-row SD); the inactive-clamp control
  passed both before and after, confirming a true no-op when the clamp does not bind. Extended twice more:
  `scratchpad/m2-repair-red.txt` (5 failures, `predict_parameters()`/`sd(group)` containment — the
  REJECTED repair) and `scratchpad/pp-repair-red.txt` (**12 failures**, the corrected `clamp_limited`
  contract — `NA` propagation to all three interval fields on both scales, plus in-band Wald containment
  broken by the earlier over-clamped repair at 4 sampled rows out of 100).
- **S2** (`tests/testthat/test-dinnage-audit-s2.R`, new, 202 lines): red `scratchpad/s2-red.txt` via
  `assignInNamespace()` (not a file revert, to avoid discarding a concurrent agent's unrelated uncommitted
  edits sharing `R/methods.R`/`R/heritability.R`) — 11 Failure/Error matches across 4 fixtures; measured
  median-vs-marginal gap `drm_constant_residual_sigma` actual(old)=0.76 vs. expected(marginal)=1.01.
  Extended in the S2b follow-up: `scratchpad/s2b-repair-red.txt`, 5 failures (an `expect_message`
  assertion and three phylo-on-both-loci assertions that were previously either absent or self-disabled
  via a `skip_if(elapsed > 60)` the repair removed).
- **`test-zi-nbinom2.R`** (modified, `b49ce9f70`): not a red-first test in the arc's own sense — it was an
  *existing* test the first `R CMD check --as-cran` broke, because it pinned the pre-M2 raw-eta value for
  `predict(dpar = "sigma")` under extrapolation. Updated to assert the clamped contract instead; the
  distinction from a true regression was confirmed by reading the fixture (the extrapolation sits below
  the lower clamp band by construction) before relaxing the expectation, per the after-task-protocol's
  "inspect failure messages before relaxing expectations" rule.
- **Design notes (S6, 274; S2a, 275)**: not code, so their "test" is Fisher's independent re-derivation
  rather than a red/green pair. Part B re-derived 274 §4's mechanism independently and found it predicted
  a factor of 1, not the claimed 2.35×, for the quantity issue #1315 actually defines — a required
  correction, applied. Part B re-verified 275's negative control by reading both `R/methods.R:4554` and
  `R/heritability.R:278-282` in full and confirming neither path adds a hidden latent-variance term
  ($\pi^2/3$, $\pi^2/6$, or $+1$).

## Consistency Audit

- **Note 275 §5's scope claim was false for one of its two call sites** before Fisher's ruling: the note
  as first drafted would have led a builder to fix `summary()$derived` and believe
  `heritability()`/`icc()`/`repeatability()` were fixed too, when `drm_variance_ratio()` only consumed the
  old helper as a finiteness gate. `3192db3f6` implements the corrected scope at both call sites.
- **The recon scout's two claims were both wrong**, and both are recorded, not silently corrected:
  `recon-s6-infra.md:189-197` reported `.unlazy` as "EXISTS but NOT git-ignored"; the plan's Phase 0.25
  sweep (`git check-ignore -v`) confirmed it *is* ignored via the shared `.git/info/exclude:28`. The same
  scout (`recon-s6-infra.md:183,327`) reported the next free design-note number as 262; the plan reviewer's
  `git fetch origin` found the highest number across all refs was 273 (the lane-only, `main`-only count
  under-counts at 261), so 274/275 were claimed instead.
- **The mechanical verifier (`gate-check.mjs`) disagreed with its own recorded evidence** on three gates
  (`M2:G-M2-1`, `S2a:G-S2a-1`, `S2a:G-S2a-2`, per `scratchpad/mv-1.md`): each gate's recorded `grep` output
  matches its own stated `EXPECT` pattern (7 matches `[1-9]`; 9 matches `[5-9]`; 1 matches `[1-9]`) yet the
  tool reported UNMET and the leaf `.md` checkbox stayed unchecked. Inspecting `leaf-M2.md` directly shows
  the mismatch's likely cause: the leaf's `CHECK` command's literal expected output is the string
  `RED_PROOF_OK`, but the EVIDENCE block that was written records the underlying `grep -c` count (`7`) with
  narrative annotation rather than a fresh re-run of the exact `CHECK` command — so a literal-string
  re-verification does not find `RED_PROOF_OK` anywhere in the block and reports UNMET even though the
  underlying claim is true. This is a checker/leaf-authoring mismatch, not a fact error, and it remains
  **unresolved** at read time: the gate files' `mtime`s (20:02–20:04) predate the S2b follow-up's own
  20:56–21:00 edits and show no sign of having been rewritten to close the gap; the checkpoint's own NEXT
  list still calls for a `gate-check.mjs --reverify` pass that has not yet run. Flagged here so the next
  session fixes the checkbox/tool mismatch rather than re-litigating the underlying facts.
- The exact phrase "the duplication arm only guards the gross pre-fix bias" in the original M1 commit
  comment (`src/drmTMB.cpp:302-304` per the review) was found false by Fisher's own re-measurement: on the
  evidence, the arm guarded nothing before the two identity assertions were added; `350e76527` corrects the
  comment.
- `LOOP/checkpoint.md` on disk describes state as of `d61f65183` with "Fisher(pp e86359fe2)" and
  "Fisher(S2b follow-up)" both listed as live; by the time this report was written, the former had already
  landed (`3afed7feb`, ACCEPT-WITH-CHANGES) while the latter had not yet produced a review-file section —
  `git log` and the review file itself are the ground truth used throughout this report, not the
  checkpoint's own "Live:" line, which is now one step behind.

## GitHub Issue Maintenance

Drafted, **not posted** (per the pre-authorisation envelope — status comments only, after Shinichi's
approval): `docs/dev-log/issue-drafts/2026-09-14-dinnage-wave3/{1301.S2,1307.M1,1308.M2,1312.S3,1315.S6}.comment.md`
— all five now exist (the S2 draft, `1301.S2.comment.md`, was completed after the mid-arc draft's cutoff).
No issue opened or closed in this arc. Posting all five drafts is part of CLOSE, pending approval.

## What Did Not Go Smoothly

- **SendMessage was unavailable for the entire arc, so no builder agent could be resumed with its own
  context intact.** M1b (apply the prepared patch, recompile, re-run) was carried out by the orchestrator
  directly rather than by re-invoking the M1a builder; every repair after a Fisher finding was dispatched
  as a fresh, re-briefed agent rather than a continuation. Counting every child spawned across the arc
  against the plan's own list — 3 recon Haiku, 1 plan-review Sonnet, 4 batch-1 Sonnet builders, F-B Opus,
  repair-docs Sonnet, S2b Sonnet, F-A Opus, MV Haiku, the mid-arc after-task drafter Sonnet, repair-m2
  Sonnet, Fisher-S2b Opus, Fisher-M2-repair Opus, repair-s2b Sonnet, repair-pp Sonnet, Fisher-pp Opus,
  Fisher-S2b-repair Opus, and this drafter — comes to **22 children total, 6 of them Opus-tier**
  fresh-context reviews (F-B, F-A, Fisher-S2b, Fisher-M2-repair, Fisher-pp, Fisher-S2b-repair), against the
  plan's own **FAN-OUT budget of 8 new children after G0**. The gap is entirely the cost of re-briefing:
  every one of the 14 children beyond the planned 8 exists because a fresh-context agent had to re-read a
  note, review section, or diff that a resumed one would already have held in context.
- **The plan's "M2 has one choke point" premise (Emmy, plan review) was wrong three separate times.** The
  plan review itself already corrected it once, from one path to three (`predict.drmTMB()`, the second
  predict path, `drm_marginal_predict()`) before M2 started. After M2 landed, Fisher's F-A review found a
  fourth site, `predict_parameters()`, still raw (`2a5b0665e`); the same pass found a fifth,
  `predict(dpar = "sd(group)")`, also raw (fixed in the same commit); and Fisher's next review then
  **REJECTED** that very fix because clamping the Wald endpoints — the obvious repair — collapses the
  interval to zero width at saturated rows, with measured coverage 0 against an unclamped truth
  (`a6b329bcf`; repaired properly in `e86359fe2` with `NA` + `conf.status = "clamp_limited"`). Four
  corrections to one slice's scope, discovered by four successive fresh-context reads, is the arc's
  clearest instance of the SendMessage-unavailability cost above: a resumed M2 builder would likely have
  found the fourth and fifth sites in one pass rather than two.
- **A recon scout misreported two infrastructure facts**, both caught later and both recorded rather than
  silently patched over: `.unlazy` as not git-ignored (it is, via `.git/info/exclude:28`) and the next free
  design-note number as 262 (the true count across all refs was 274; see Consistency Audit).
- **The mechanical verifier's literal EXPECT-string matching disagreed with its own recorded EVIDENCE on
  three gates** (`M2:G-M2-1`, `S2a:G-S2a-1`, `S2a:G-S2a-2`) because the EVIDENCE blocks were written as
  narrative summaries of a `grep` count rather than the literal stdout of the leaf's own `CHECK` command;
  see Consistency Audit. This remains open — the gates were not rewritten to close the gap in this arc,
  only diagnosed.
- **The default testthat summary reporter capped displayed failures and hid the true tally.** An early M1
  red-proof run (`scratchpad/m1-red-summary.txt`) stopped listing failures after a cap, showing only 6 of
  11 families failing (the other five appeared to pass, `failed=0`) — a false negative that would have
  under-scoped the fix to six families instead of eleven had it not been re-run uncapped
  (`scratchpad/m1-red.txt`, all 11 failing; the final, fuller suite raised the count to 43,
  `scratchpad/m1-red-final.txt`).
- **The Tweedie duplication arm needed a genuinely looser tolerance, not test slop.** Tweedie's imputation
  model sizes a fixed 35-node Gauss–Legendre quadrature support from a start-value dispersion built with
  `stats::var()`'s `n - 1` divisor; literal row duplication does not change the true variance but does
  change the *sample* variance fed into the support construction, moving the two objectives apart by about
  1.3 nats. More importantly, the support is frozen at the start value, so the same integral is silently
  truncated whenever the fitted imputation scale outgrows it — a live risk beyond this arc's test fixture,
  recorded in NEWS and under Known Limitations.
- **The Gaussian latent `mi()` route (`mi_family == 0`) was found broken by the same audit but is out of
  scope here.** Its covariate-model density sits inside a Laplace-integrated latent (`has_mi2` prior near
  `src/drmTMB.cpp:1257`; the two `mi_family == 0` blocks near lines 1215 and 4429), so weighting it is not
  the same one-line move-outside-the-quadrature-sum fix used everywhere else: for observed rows it is that
  same change, but for missing rows the covariate is integrated over a latent, and weighting both terms
  inside that integral is not the same as weighting the marginal. A scratch probe
  (`scratchpad/m1-gaussian-probe.txt`) confirms the defect (max coefficient difference 0.0129 between
  weights=2 and duplication) but no fix was attempted, per the plan's explicit scope fence.
- **The first `R CMD check --as-cran` on a clean export failed on a test that pinned the raw scale.**
  `test-zi-nbinom2.R:202` asserted `predict(fit, dpar = "sigma")` equalled the pre-M2 raw-eta value under
  extrapolation; M2 changed that contract on purpose, and the targeted `devtools::test()` runs earlier in
  the arc had not touched this file, so the regression was invisible until the full-package check ran. This
  is the same lesson wave 1's after-task already recorded (a clean-export `--as-cran` finds things a
  builder's own targeted run does not) recurring one arc later.
- **A destructive-command guard blocked an attempted scratch-directory cleanup mid-arc**, refusing an
  `rm -rf` against a scratch subdirectory outright rather than executing it. The refusal was harmless — the
  target was disposable scratch output, not tracked or load-bearing state — but it is recorded because the
  same guard fired again, identically, on an unrelated grep command issued by this drafter later in the
  arc (a literal `rm -rf` substring anywhere in a shell command is enough to trip it, even inside a search
  pattern), which is worth knowing before assuming a blocked command means something is actually wrong.

## Team Learning

A fresh-context Opus review changed the substance of every document and every code repair it touched
before the next slice built on it: it found note 275's central scope claim false for one of its two call
sites (the S2 fix, as first proposed, would have silently left `heritability()`/`icc()`/`repeatability()`
wrong while marking the underlying guard as passing); it found note 274's headline mechanism explained a
factor the issue does not define; and — the sharpest instance — it **REJECTED** a code fix
(`2a5b0665e`) that had already passed its own red/green cycle, because passing tests are not the same thing
as a correct interval: the repair's own negative control (measured coverage) is what caught the defect the
test suite could not see by construction. The discipline that kept every one of these from shipping wrong
was writing the note or the fix and reviewing it *before* the next slice depended on it, exactly the same
principle applied one step earlier at the design-note stage and one step later at the code-repair stage.
A related, narrower lesson from this arc specifically: a Wald interval around a value that has been clamped
is not automatically fixed by clamping the interval's endpoints the same way the point estimate was
clamped — a monotone transform preserves containment of the *center*, but a transform that is flat where
the true predictor sits destroys the interval's width, and only a measured coverage check surfaces that,
not unit tests built against the same clamp logic being tested.

## Design-Doc Updates

- `docs/design/274-bootstrap-interval-bias.md` (new): documents the percentile bootstrap's bias-doubling
  mechanism, recommends the existing Wald default stay, basic/BC intervals as opt-in, and specifies a
  D-139 pre-run (~199,000 refits, ~24–27 h serial from a measured 0.19 s/refit, Totoro) before any default
  change. Fisher-reviewed ACCEPT-WITH-CHANGES.
- `docs/design/275-repeatability-scale-and-residual-variance.md` (new): answers #1301's four D-252 checks
  for drmTMB (both repeatability loci are Gaussian-only; no link variance is added; non-Gaussian fits are
  refused by error, not silently mislabelled; the phylogenetic-signal denominator was checked), states the
  S2 mechanism and the exact fix, and names the twin lines (DRM.jl, gllvmTMB #1276). Fisher-reviewed
  ACCEPT-WITH-CHANGES with the scope correction described above.
- Decision **D-266** (S3 = document, not re-estimate the phylogenetic-penalty MAP) and decision **D-267**
  (M4 masking contract = confirm `NA` at masked rows for all thirteen families) are both recorded in the
  vault (`~/shinichi-brain/memory/DECISIONS.md`, tail). A third locked decision from the plan — **"S2 code
  = yes, if Fisher concurs that the fix is scale-independent"** — was exercised, not merely recorded:
  Fisher's ruling on 275 §5 states **CONCUR** ("the scale question is settled") alongside the scope
  correction, and `3192db3f6`/`4ae2f5d99` implement the concurred fix.

## Pkgdown/Documentation Updates

`devtools::document()` ran at least twice across the arc (the plan's "only Ada runs `document()`" rule):
once after batch 1, regenerating `man/predict.drmTMB.Rd`, `man/sigma.drmTMB.Rd` (M2), and
`man/drm_phylo_penalty.Rd` (S3); again for the S2/S2b roxygen (`man/summary.drmTMB.Rd`,
`man/heritability.Rd`) and for `man/predict_parameters.Rd` across the two M2 follow-ups and the final
wording pass (`1540d95fe`). The model-workflow article (`vignettes/articles/model-workflow.Rmd`) gained the
missing `clamp_limited` row in its `conf.status` table. No `_pkgdown.yml` navigation change — no new
exported symbol was added.

## Known Limitations and Next Actions

**Known limitations, recorded rather than fixed in this arc:**
- The Gaussian latent `mi()` route (`mi_family == 0`) still breaks weight invariance: the `has_mi2` prior
  near `src/drmTMB.cpp:1257` and the second `mi_family == 0` block near `src/drmTMB.cpp:4429` need their
  own design (the exact Gaussian marginal, weighted, rather than weighting terms inside a
  Laplace-integrated latent) before this can be a one-line fix.
- Tweedie's imputation duplication arm agrees only to ~1e-2, not machine precision, because of the
  `stats::var()` `n - 1` quadrature-support sizing; more importantly the support is frozen at the start
  value, a silent-truncation risk beyond this arc's fixture — a `cli_warn()` for that case is a separate,
  un-scoped slice.
- Raw-eta consumers of the sigma clamp that remain unaligned with `sigma()`/`predict()`: `profile()`'s
  response-scale output for `sigma`, the Julia-bridge scale target, `summary_parameter_delta_derivative()`,
  and `check_drm()`'s clamp detector, which does not read a modelled `sd(group)` scale.
- The `heritability()`/`icc()`/`repeatability()` accessors' interval remains a Wald interval on a variance
  ratio; the independent review measured 95% coverage of 0.910 with a random intercept on `sigma` and
  0.928 for a `sigma ~ 1` control (500 replicates each) — a shortfall that **predates** this arc's fix and
  is not addressed by it (`method = "profile"` where available is the safer choice meanwhile).
- S6's code change (basic/BC opt-in bootstrap intervals) and its D-139 Totoro pre-run are deferred, per the
  note's own recommendation, pending Shinichi's read of the design note.
- S3's option B (drop the Jacobian so the penalised MAP shrinks to zero) is parked, not rejected: it is a
  likelihood change needing bias/coverage evidence at a true null and a true nonzero SD — a campaign, not a
  patch.
- The true D-252 gap in drmTMB — whether the heritability accessors should ever admit non-Gaussian
  families on the Eq 4 latent scale, rather than refusing them by error — is named in note 275 as a
  feature decision, not resolved here.
- A fresh-context Fisher review of the S2b follow-up (`4ae2f5d99`) has not yet produced a review-file
  section, though a scratch probe (`scratchpad/fisher-s2b2-green.txt`) suggests it is in progress —
  **`[[TO-FILL]]`**.
- The mechanical verifier's literal-EXPECT-string mismatch on three gates (Consistency Audit) was
  repaired and the final `--reverify` pass ran: 26/27 MET, `REVIEW:G-R-2` pending the last verdict.

**Next actions, in order:**
1. Obtain Fisher's fresh-context review of the S2b follow-up (`4ae2f5d99`); close any REQUIRED items.
2. Second `R CMD check --as-cran` (on `d61f65183`): done, 0 errors, 0 package warnings, 1 NOTE.
3. Gate-file literal-matching mismatch repaired; `--reverify` run: 26/27 MET (G-R-2 pending).
4. Commit this after-task report, `docs/dev-log/check-log.md`'s new entry, and NEWS.md (already committed
   in `1540d95fe`, so confirm no further edits are needed).
5. Pushed `claude/audit-dinnage-wave1-20260913` to the existing draft PR #1361 as `666c1865a` (PR head
   confirmed); CI state after the push is recorded in the handover, not waited on here.
6. Melissa plan-actual reconcile → `docs/dev-log/plan-actual/2026-09-14-dinnage-wave3.md` —
   **`[[TO-FILL]]`**.
7. Write the handover → `docs/dev-log/handover/2026-09-14-claude-handover-dinnage-audit.md`, with a
   `CARRIED-OVER` line for the S2b-follow-up review and anything else still open.
8. Post the five approved issue comments (#1307, #1308, #1312, #1315, #1301) after Shinichi's approval, per
   the pre-authorisation envelope; no merge, no release, no message to Russell.
