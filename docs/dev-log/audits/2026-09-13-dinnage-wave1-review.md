# Fisher review: four fixes answering Russell Dinnage's independent evaluation

Date: 2026-09-13 · Reviewer: Fisher (inference reviewer, review-only; no files
changed except this one) · Report reviewed against:
`rdinnager/drmTMB_eval` `REPORT.md`, pinned at `945da24f`.

## Purpose, for Shinichi

Four builders each took one finding from Russell's evaluation and shipped a fix.
This review asks, for each, three questions only: does the change address the
*mechanism* Russell described, would the new test have *failed* on the old code,
and does anything here move an estimand, a likelihood, or a documented promise.
Two fixes are sound in their algebra and should land with a small follow-up
(C1, M1). One should not land as written: the `drm_phylo_penalty()` docs commit
rewrites the help page to describe a `Gamma(2, rate)` prior the package never
intended, and the package's own design document and C++ comment say so in words
(S3). The fourth is right as far as it goes but leaves four families outside the
invariant on the strength of two tests that do not, on reading, assert the
invariant they are credited with (M4). Findings below are ordered by how hard
they push on an inference claim.

---

## 1. S3 — `drm_phylo_penalty()` documentation (`f8bed84bb`, worktree `drmTMB-audit-dinnage-wave2a`)

**VERDICT: REJECT as written.** The numeric behaviour is fine and unchanged; the
new prose asserts a design rationale that three independent places in the
package contradict, and it retracts a calibration promise that is in fact true.

### Mechanism check — the commit's premise is falsified by the package's own source

The commit's argument is: the compiled penalty is a `Gamma(shape = 2, rate)`
density on the SD, this is intentional Chung et al. (2013), therefore correct the
docs rather than the code. Each step is checkable, and the first one fails.

The compiled penalty, `src/drmTMB.cpp:93-108`, adds per phylogenetic SD

```
pen_k = lam * sd_k - log_sd_phylo(k) - log(lam),   sd_k = exp(log_sd_phylo(k))
```

Three pieces of evidence say this is an *exponential* prior on `sd` written as a
density in the working parameter `log_sd`, with the change-of-variables
Jacobian — not a Gamma(2) prior on `sd`:

1. **The function's own header comment**, `src/drmTMB.cpp:86-90`, verbatim:
   *"PC-prior penalty (negative log-prior) ... an exponential prior on each
   phylogenetic SD = exp(log_sd_phylo) with the log-Jacobian"*. The commit
   changed neither this comment nor the code it describes.
2. **The design document**, `docs/design/172-phylo-penalized-map.md:44-53`, which
   states the same formula under the heading "Mathematical contract" and then
   names the term explicitly: *"(the `- log_sd_phylo(k)` term is the
   `|d sd / d log_sd|` Jacobian)"*.
3. **The additive constant.** A Gamma(2, lam) negative log-density is
   `lam*sd - log(sd) - 2*log(lam)`. The code has `- log(lam)`, which is the
   *exponential* normalising constant. The commit message waves this off as
   "up to a sd-independent constant"; it is in fact the discriminating evidence
   between the two readings, and it points at the exponential.

The algebra: if `sd ~ Exp(lam)`, then the induced density of `theta = log sd` is
`lam * exp(-lam*sd) * sd`, whose negative log is exactly
`lam*sd - log(sd) - log(lam)`. The code is the PC prior, expressed correctly in
the parameter the optimiser actually moves.

### What is genuinely wrong, and it is not what either side says

Russell's measurement stands — under a true null the penalised `sd_phylo` came
back at 0.055-0.112 against an ML median of 2e-05, above the unpenalised value in
496 of 500 paired fits — but his *interpretation* (a mis-specified prior, tail
calibration out by 3-6x) is an artefact of reading the penalty as a density in
`sd`. His measured tail numbers reproduce exactly as
`P(Gamma(2, rate) > sd_u) = (1 + rate*sd_u) * exp(-rate*sd_u)`: at
`sd_alpha = 0.05`, `rate = 2.9957`, that is `3.9957 * 0.05 = 0.1998`, his figure
to four digits; at `sd_alpha = 0.01` it is `5.6052 * 0.01 = 0.0561`, again his
figure. Under the exponential-plus-Jacobian reading the prior tail is
`exp(-rate*sd_u) = sd_alpha` **exactly**, and the documented calibration promise
`P(sd > sd_u) = sd_alpha` is true as written.

The real defect is a different one, and it is a defect about *estimation*, not
about the prior: **a MAP on a positive parameter is not invariant to
reparameterisation.** drmTMB reports the joint mode in `log_sd`. Under a flat
likelihood that mode sits at `sd = 1/rate` (0.334 at defaults), not at zero,
because the Jacobian `-log(sd)` diverges as `sd -> 0`. So the *prior* has mass at
zero as documented, while the *reported point estimate* can never be zero and is
pulled upward. The old help page never said that, and neither does the new one.

### What a user who set `sd_u` / `sd_alpha` under the old docs actually got

They got the prior they asked for: exponential on the phylogenetic SD, with
`P(sd > sd_u) = sd_alpha` holding exactly. What they did not get is the
*shrink-to-zero point estimate* the page implied: with a weakly identified SD the
reported `sd_phylo` is pulled toward `1/rate` = 0.334 at defaults, and under a
true null lands around 0.055-0.112 rather than at the ML value near zero. Anyone
who turned that SD into a phylogenetic heritability or a Pagel's-lambda-like
quantity has a small but systematically non-zero signal manufactured by the
penalty. Under the *new* docs they would be told something different and also
wrong: that their prior is `Gamma(2, rate)` and that the tail promise fails.

### Negative-control check

The new test, `tests/testthat/test-dinnage-audit-wave2a.R` (S3 block), evaluates
an R-side copy of the closed form at `sd = 1e-4`, `1/rate`, `10/rate` and asserts
an interior minimum at `1/rate`. That assertion is **true and would have passed on
the old code too** — the formula did not change. It is therefore not a negative
control for anything; it is a characterisation test of arithmetic that was never
in dispute. It also duplicates the penalty formula in R rather than reading the
compiled value, so it cannot catch a future C++ change (the commit message is
honest that it leans on `test-phylo-penalized-map.R` for that link).

### Estimand / contract impact

No numeric change. The contract change is in prose, and it is a net loss: it
deletes a true calibration statement, attributes the shape to Chung et al. (2013)
when the source says Simpson et al. (2017) plus a Jacobian, and demotes `sd_u` /
`sd_alpha` to "legacy knobs" that no longer mean what they mean.

### Concrete change

1. Do not merge the current wording. Rewrite Details to say: the prior on each
   phylogenetic SD is exponential with rate `-log(sd_alpha)/sd_u`, so
   `P(sd > sd_u) = sd_alpha` holds; the penalty is evaluated on `log(sd)` and
   includes the `|d sd / d log sd|` Jacobian; **because a MAP is not invariant to
   reparameterisation, the reported penalised `sd_phylo` is the mode in `log(sd)`
   and is therefore never zero — with a flat likelihood it sits at `1/rate`
   (0.334 at defaults).** Keep the Simpson citation as the prior's source; keep
   Chung as the reference for why an off-zero, non-degenerate estimator is a
   defensible thing to want.
2. Add the sentence that matters for inference: a penalised `sd_phylo` must not
   be used to test a null of no phylogenetic signal, and a likelihood-ratio or
   Wald test against zero on a MAP fit is not valid. (`R/penalty.R:36-40` already
   says something adjacent about MAP SEs; this is the sharper statement.)
3. Fix `docs/design/172-phylo-penalized-map.md` in the same pass only if the
   decision in (4) changes; as of today that file is *correct* and the help page
   is the odd one out.
4. Shinichi's decision, stated in §5.

---

## 2. C1 — two-sided `log(sigma)` clamp detector (`328507d59`, worktree `drmTMB-audit-dinnage-wave1`)

**VERDICT: ACCEPT WITH CHANGE.** The predicate is right and matches Russell's
reference diff line for line. The user-visible sentence is still false on the
lower arm, and the severity is still `warning` where Russell explicitly asked for
a note — so a meta-analysis at `tau = 0` will now be warned at, with wrong text.

### Mechanism check — both arms

`R/drmTMB.R:3524-3556` now computes `hit_hi <- any(values > hi)` and
`hit_lo <- any(values < lo)` and returns `arm` plus the signed extreme. This is
Russell's §8.2 / §4 diff essentially verbatim, and it is the predicate already
used at `R/profile.R:4369` (`any(values < band[[1L]] | values > band[[2L]])`),
the reference site he names (his line number 4197 is the pre-drift offset).

One thing worth recording because it is not obvious and nobody stated it: the
detector reads the **post-clamp** reported vector — `src/drmTMB.cpp:2383-2385`
clamps `log_sigma` in place and `:2412` reports it afterwards. Detection still
works because the soft clamp
(`drm_softclamp_log_sigma_one()`, `src/drmTMB.cpp:26-32`) maps any `x < lo` to
`lo - margin*tanh((lo-x)/margin)`, which lies strictly in `(lo - margin, lo)`.
So `any(values < lo)` is true if and only if some raw predictor was below the
band. The predicate is exact. The *printed value*, however, is the clamped one
(-13.2, say) and not the raw predictor (-17.3 in Russell's fit) — a pre-existing
understatement on both arms, not introduced here.

### Negative-control check — passes

`tests/testthat/test-clamp-active-guard.R:29-40` now asserts
`expect_false(is.null(info))`, `info$arm == "lower"`, `info$value == -13.2`.
On `origin/main` (`git show origin/main:R/drmTMB.R`, line 3538) the guard is
`if (length(values) == 0L || !any(values > hi)) return(NULL)`, so the lower-arm
call returns `NULL` and the new test fails on the first assertion. This is a
genuine negative control, and it inverts exactly the assertion Russell named
(`origin/main` `test-clamp-active-guard.R:33`, `expect_null(...)`).

### Estimand / contract impact — and the part that is still broken

No estimand change: the likelihood, the clamp, and every estimate are untouched.
**The 91%-biased scale slope at `y * 1e-6` is still produced; only the label
changes.** That is the right scope for this commit, but it must be said plainly
wherever the fix is reported, because "C1 fixed" will otherwise be read as "the
estimate is now correct".

Two contract problems remain, both in `R/check.R`, which the commit message
declares out of lane:

* `R/check.R:610-618` builds the message with a hard-coded upper-arm sentence:
  `"The fitted log(sigma) reached %.2f, above the clamp band upper bound %g; ..."`
  with `info$value` and `info$hi`. On a lower-arm hit this prints, verbatim,
  *"The fitted log(sigma) reached -13.20, above the clamp band upper bound 12"* —
  a sentence that is false. C1 was graded Critical precisely because the row
  printed a false sentence; this commit replaces one false sentence with another.
* Severity is hard-coded `"warning"` at `R/check.R:612`. Russell's §8.2 asks for
  a **note** on the lower arm so a `tau -> 0` meta-analysis is not warned at, and
  his own attack found that case is legitimate (log-tau to -12.96, clamped vs
  unclamped differ by 0.0015, matches `metafor::rma(scale = ~x)` to 3 dp). As
  shipped, every legitimate variance-zero boundary fit now raises a `check_drm()`
  warning. Given M3 (the `fixed_gradient` row already warns on correct fits),
  this adds a second miscalibrated warning to the surface whose credibility M3
  already damaged. The in-source comment at `R/drmTMB.R:3573-3576` and the
  new test comment both assert that `check_drm()` reports the lower arm "as a
  note, not a warning" — that is not true as of this commit.

### Concrete change

1. `R/check.R:605-620`: branch on `info$arm`. Lower arm -> status `"note"`,
   message along the lines of *"The fitted log(sigma) reached -13.20, below the
   clamp band lower bound -12. If this is a variance-zero boundary (e.g.
   meta-analytic tau = 0) it is a legitimate result; if the response is on a very
   small numeric scale, rescale it or set `drm_control(logsigma_clamp = NULL)` —
   the scale coefficient may be badly biased."* Upper arm unchanged.
2. Fix the two comments that currently over-claim (`R/drmTMB.R:3573-3576`,
   `tests/testthat/test-clamp-active-guard.R:31-34`) or land (1) in the same PR.
3. Add the behavioural test Russell asks for in §4's invariant list and §8.5:
   `sigma:x` unchanged when `y` is multiplied by `1e-6`. Nothing in this commit
   tests the *consequence*; the unit test only pins the predicate. That test
   should be expected-to-fail-loudly (the clamp row is now a warning/note) rather
   than expected-to-be-correct, until M2 and the rescale advice land.

---

## 3. M1 — observation weights outside the `mi()` mixture (`bb7b0de8b`, worktree `drmTMB-audit-dinnage-wave1`)

**VERDICT: ACCEPT WITH CHANGE.** The algebra is correct at all ten sites it
touches; the prior weighting matches Russell's prescription; the test is a real
invariance test that fails on the old kernel. The change is a *partial* fix: the
same defect survives at eleven more sites covering every non-Bernoulli imputation
family, and nothing warns the user.

### Mechanism check — the algebra is right

At each of the ten `mi_family == 1` two-point sites, the missing branch now reads

```
Type log_denom = logspace_add(log_p1 + log_y1, log_p0 + log_y0);
nll -= weights(i) * log_denom;
```

with the leaves called unweighted (e.g. `src/drmTMB.cpp:1304`, `:2599`, `:2851`,
`:3000`, `:3133`, `:3559`, `:3736`, `:4021`, `:4141`, `:4427`). That is
`w * log(p1 f1 + p0 f0)`, the correct weighted mixture log-likelihood — not
`log(p1 w f1 + ...)` and not `w` inside one branch. Confirmed by reading every
hunk of the diff, not by pattern-matching the first one.

Two consequences that are right and are worth recording:

* The imputation posterior `posterior_p1 = exp(log_p1 + log_y1 - log_denom)` is
  now formed from **unweighted** leaves, so the weight no longer tempers the
  imputed value fed back into the linear predictor. That was the second half of
  Russell's mechanism ("also tempers the imputation posterior") and it is fixed
  as a by-product, correctly.
* The observed-row imputation prior is now weighted:
  `nll -= weights(i) * (mi_x(i)*log_p1 + (1 - mi_x(i))*log_p0)`
  (`src/drmTMB.cpp:1289`, and the nine siblings). This is exactly what Russell
  prescribes ("weight the imputation prior") and it is what makes `weights = 2`
  equal to row duplication: a row standing for `w` copies contributes `w` copies
  of both the response density and the covariate prior.

### Negative-control check — sound, with one caveat

`tests/testthat/test-dinnage-audit-wave1.R` fits at `weights = 1` and
`weights = 2` and asserts `expect_equal(coef_w1, coef_w2, tolerance = 1e-6)`,
plus `coef_dup` from literal `rbind(dat, dat)` against `coef_w2` at `1e-5`.
Pre-fix drift on the `mi(x)` slope is ~0.03 on a coefficient near 0.9, i.e. a
relative difference near 3e-2 against a 1e-6 tolerance — the test fails on the
old kernel by three orders of magnitude. The commit reports verifying this by
stashing and recompiling; I did not recompile (a double TMB rebuild of
`src/drmTMB.cpp` is well over the 30-minute line), but the failure follows from
the diff and the reported magnitudes, and the duplication arm is an independent
check that does not rely on the bug's sign.

The caveat: the test wraps the fits in `allow_nonconvergence()`. An invariance
assertion evaluated at a point that may not be an optimum is weaker evidence than
it looks — two non-converged fits can agree for the wrong reason, and `weights = 2`
doubles the objective so an absolute gradient tolerance is effectively halved in
relative terms. Add `expect_equal(fit$opt$convergence, 0L)` inside `fit_coef()`
(or return the fit and assert on it) so the invariance is asserted at a converged
optimum.

### Estimand / contract impact

The likelihood changes for any fit that combines `weights` with a Bernoulli
`mi()` term. `weights = 1` (and `weights = NULL`) is bit-for-bit unchanged, so
the default user sees nothing; `logLik`, AIC and all estimates move for weighted
`mi()` fits, in the direction of correctness. NEWS (`NEWS.md`, the M1 bullet) is
accurate and, creditably, names the unfixed remainder.

### The gap — and it is the part that still carries an inference risk

`weights(i) *` remains **inside** the mixture at eleven further sites:
`src/drmTMB.cpp:1384` and `:1464` (the multi-state / ordinal-categorical `mi()`
mixtures) and the nine Gauss-quadrature blocks at `:1548`, `:1686`, `:1817`,
`:1879`, `:1961`, `:2065`, `:2146`, `:2230`, `:2323` (continuous and count
imputation families). In each, `log_y = weights(i) * drm_response_log_density(...)`
is formed per node, the nodes are combined with `logspace_add()`, and the
combined `log_denom` is subtracted **with no outer weight at all**. So for
`mi()` with a Gaussian, Poisson, gamma, lognormal, NB2, Tweedie, beta, ordinal or
categorical imputation model, `weights = c` is still not equal to row
duplication, the row's contribution is not scaled by `w`, and the imputation prior
is unweighted. This is the identical estimand-level bias Russell graded Major,
untouched, and there is no test and no runtime guard for it. A user cannot tell
which `mi()` route they are on from the API.

### Concrete change

1. Apply the same transformation to the eleven remaining sites. It is mechanical
   and the pattern is identical; the only judgement call is that the outer
   `nll -= log_denom` must become `nll -= weights(i) * log_denom`, which is a
   *larger* behavioural change there than at the two-point sites because those
   rows are currently not weighted at all.
2. Until (1) lands, **warn or abort at fit time** when a non-`NULL` `weights` is
   combined with an `impute_model()` whose family is not `binomial()`. A silent
   point-estimate bias in a documented combination is exactly the case the
   package's own guard philosophy exists for.
3. Extend the invariance test to one non-Bernoulli imputation family (a Gaussian
   `impute_model()` is the cheapest) so the regression is covered, not just
   described in a commit message.

---

## 4. M4 — `simulate()` masks missing-response rows (`90afa4b6a`, worktree `drmTMB-audit-dinnage-wave2b`)

**VERDICT: ACCEPT WITH CHANGE.** Nine families are fixed correctly by routing
through the existing helper. The four exclusions should not stand: the two tests
cited as blockers pin the sentinel-leak behaviour incidentally and do not assert
the invariant they are credited with.

### Mechanism check

Each fixed branch now ends
`sims[] <- lapply(sims, function(col) drm_mask_missing_response_values(object, col))`
(`R/methods.R:3046`, `:3093`, `:3115`, `:3139`, `:3161`, `:3192`, `:3232`,
`:3267`, `:3285`, `:3313`, `:3330`, `:3378`, `:3537`), reusing the helper at
`R/missing-data.R:546-565` that `residuals()` already uses — the exact fix
Russell prescribes ("one masking pass on the assembled frame in a wrapper"). The
hand-rolled `beta_binomial` masking is folded onto the same helper.

### Negative-control check — passes for the nine

`tests/testthat/test-dinnage-audit-wave2b.R` asserts
`all(is.na(sims[!observed_y, ]))` for poisson, binomial, nbinom2, gamma, plus a
beta_binomial block. On the old code those rows carried the sentinel (0, or 1 for
lognormal/gamma), so `is.na()` is `FALSE` and the test fails. Genuine. It is
however 4 of 13 families, not the loop over families Russell asks for; lognormal,
student, skew_normal, tweedie, beta and zero_one_beta are fixed but untested, and
the four exclusions have no expectation at all recording the known gap.

### Do the two blocking tests assert a genuine invariant? No.

I read both.

* `tests/testthat/test-missing-response-count-mixtures.R:145-150` (inside
  *"MR-T6 ZIP masks the complete mixture contribution"*): `dim(sims)`,
  `all(as.matrix(sims) >= 0)`, `all(sims == round(sims))`, and two `expect_gt`
  that some draws are zero and some positive. Nothing states that masked rows
  should carry a draw. The block breaks under masking only through **NA
  propagation** — `all(NA >= 0)` is `NA` and `expect_true(NA)` errors. The test's
  title refers to the **likelihood** masking the whole ZI mixture contribution,
  not to `simulate()`'s output.
* `tests/testthat/test-missing-response-truncated-nbinom2.R:94-98` (inside
  *"MR-T5 mask equals the observed-row truncated NB2 fit"*): `dim`,
  `all(is.finite(...))`, `>= 1`, integer-valued. Same shape. The invariant the
  test is named for is an **estimation** parity — masked fit equals the
  complete-case fit — and it is asserted earlier in the same block.

Decisive, and it is in the same file: line 86 of that very test asserts
`all(is.na(residuals(fit_mask, type = "pearson")[!observed]))`. The package
already requires `residuals()` to be `NA` at masked rows while the tail of the
same test requires `simulate()` to be finite there. That is not two contracts, it
is one contract and one unexamined sanity check. `NEWS.md:201-211` settles it:
under #1188 the package adopted "replicates keep the seed fit's response mask" as
an explicit invariant, with measured bootstrap coverage evidence (0.720 -> 0.910
at 50% masking). Masking at masked rows is the established contract; the
finite-draw assertions are the outlier.

### Estimand / contract impact

`simulate()` is not an estimator, so no estimand moves. Two contract notes:

* **The parametric bootstrap is not affected either way.** `bootstrap_response_data()`
  (`R/profile.R:3022-3067`) re-applies the seed fit's NA mask to each simulated
  draw independently of what `simulate()` returned, and `bootstrap_refit_one()`
  (`R/profile.R:2920-2928`) refits under the seed fit's response policy. So the
  four unmasked families do **not** leak fabricated rows into
  `confint(method = "bootstrap")`. The exposure is confined to the user-facing
  `simulate()` -> `DHARMa::createDHARMa()` path, which is where Russell put it,
  and which he is explicit is reasoned rather than run.
* **Type change, unflagged.** `drm_mask_missing_response_values()` assigns
  `NA_real_` (`R/missing-data.R:563`), so a count family's `simulate()` columns
  are coerced from integer to double at any masked fit. `beta_binomial`
  previously used `NA_integer_` and kept integer type; the refactor changes that.
  No test asserts integer type today (checked), so nothing breaks now, but it is a
  silent API change and belongs in NEWS.

### Concrete change

1. Mask all four remaining families. They are the branches at `R/methods.R:3347`
   (zi_poisson), `:3402` (truncated_nbinom2), `:3445` (hurdle_nbinom2), `:3484`
   (zi_nbinom2). Replace the four NOTE comments with the same helper call.
2. Repair the two test blocks rather than deferring to them: restrict the support
   assertions to observed rows and add the invariant, e.g.
   `expect_true(all(is.na(sims[!observed, ])))` and
   `all(as.matrix(sims[observed, ]) >= 0)`. That is a three-line edit per file
   and it converts an incidental pin into a stated contract.
3. Then delete the paragraph added to `?simulate.drmTMB` (`R/methods.R:2964-2971`,
   `man/simulate.drmTMB.Rd:85-91`) telling users four families behave differently.
   A documented per-family exception to an invariant is a worse outcome than the
   bug, because it asks the user to remember which four.
4. Turn the wave2b test into the loop Russell specifies, one row per family, so
   the next family added inherits the assertion.

---

## 5. Decisions for Shinichi

1. **S3, prior semantics — the one that needs your call.** The code implements an
   exponential (PC) prior on the phylogenetic SD, evaluated on `log(sd)` with the
   Jacobian; the design doc and the C++ comment both say so. Nothing is wrong with
   the *prior*. What is wrong is that the reported penalised `sd_phylo` is the
   mode in `log(sd)`, so it cannot be zero and is pulled toward `1/rate` (0.334 at
   defaults) — which is the opposite of the "shrink a weakly identified SD toward
   no phylogenetic variance" purpose the page advertises. Three options:
   * **(A) Keep the code, tell the truth** (my recommendation, and reversible):
     the prior is as documented and calibrated; the penalised point estimate is a
     log-scale MAP and is never zero; do not test a null of zero phylogenetic
     signal on a penalised fit. Cheap, honest, no estimand change, lands today.
   * **(B) Drop the Jacobian** (`pen_k = lam*sd_k - log(lam)`): the MAP is then
     the mode in `sd` and does shrink toward zero, matching the advertised
     purpose. Cost: the estimator becomes boundary-capable at `sd = 0` — exactly
     the degeneracy Chung et al. (2013) exists to prevent — and every existing
     penalised fit changes. This is a likelihood change and needs its own
     simulation evidence (bias and coverage at a true null and at a true nonzero
     SD) before it ships.
   * **(C) Report a different summary** (posterior median, or the profile rather
     than the joint mode). More work than either; mentioned for completeness.
   I recommend **A now, B only if you decide the package's contract is "this
   penalty shrinks toward zero"** — in which case B needs a campaign, not a patch.
   Either way the current commit's wording should not ship.
2. **M4, the four count-mixture families.** Mask them, and fix the two tests. The
   tests do not assert the invariant they are credited with, `residuals()` in the
   same test file asserts the opposite, and #1188 already made "keep the mask" the
   package's rule. If you disagree and want `simulate()` to *impute* at masked
   rows, that is a defensible feature (it is single imputation under MAR) — but
   then it must be all thirteen families, opt-in via an argument, and documented
   as imputation, never as a per-family accident.
3. **C1 severity by arm.** Confirm that the lower arm should be a `check_drm()`
   **note** and the upper arm a **warning**, as Russell asks. As shipped, every
   `tau = 0` meta-analysis gets a `warning` row carrying a false sentence about
   the upper bound. This needs a one-function change in `R/check.R`, which the
   C1 lane declared out of scope — someone must own it.
4. **M1 scope.** Decide whether the eleven remaining `mi()` mixture sites get
   fixed now or whether `weights` + non-Bernoulli `mi()` gets a fit-time refusal
   in the meantime. Leaving a silent point-estimate bias documented only in a
   commit message is the weakest of the three options.
5. **Cross-cutting, and worth saying out loud.** C1's fix changes a *label*, not
   an estimate: a user on `y * 1e-6` still gets a 91%-biased scale slope and zero
   coverage in 2,000 Wald intervals. Anywhere "C1 fixed" is written — NEWS, the
   response to Russell, the release notes — it should read "C1's detector fixed;
   the estimate is still wrong when the clamp binds, and M2 plus the rescale
   advice are what make it safe".
