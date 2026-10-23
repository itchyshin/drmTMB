# Response-mask red surface

## Method (what was run, when, how)

Branch `codex/response-missing-formula-surface`, worktree
`/private/tmp/drmtmb-response-missing-formula-surface`, 2026-08-14.

- 28 of the 30 evidence files were audited in parallel batches by other agents
  (`scratchpad/audit-batch-1.md` … `audit-batch-5.md`), each running
  `testthat::test_file(..., reporter = testthat::CheckReporter$new())` and
  capturing verbatim `Failure`/`Error` blocks.
- The two files not covered by the batches, `test-zero-one-beta.R` and
  `test-missing-response-boundary.R`, were re-run directly by me with the
  exact command the brief specified:
  `NOT_CRAN=true R_PROFILE_USER=/dev/null Rscript --no-init-file -e
  'suppressMessages(pkgload::load_all(".", compile = FALSE, quiet = TRUE));
  testthat::test_file("tests/testthat/<file>", reporter =
  testthat::CheckReporter$new())'`. Both runs also regenerated
  `tests/testthat/_problems/*.R`, which I used as a second, code-level
  cross-check on the exact assertion at each failing line.
- Cell-ID mapping was built by matching each failing formula/fixture
  (provider, group/tip count, observations-per-group, formula text) against
  `tools/response_mask_formula_inventory.py`'s `EXPLICIT_BOUNDARIES` tuple and
  `FORMULA_EVIDENCE` dict, cross-checked against
  `docs/dev-log/dashboard/capability-ledger/response-mask-formulas.tsv` and,
  where available, `docs/dev-log/check-log.md` prose entries. A mapping is
  reported only when the fixture description (group count, observations per
  group, exact formula text) matches the failing test's fixture; otherwise it
  is marked UNRESOLVED.

**Mid-audit correction (important — read before the tables below).** While this
report was being written, a coordinating agent repaired
`tests/testthat/helper-missing-response.R` in the working tree: the
`sentinels` invariant assertion changed from `expect_length(sentinels, 2L)`
(mischaracterized in the original task brief as the mechanism behind six
call sites) to `testthat::expect_true(length(sentinels) >= 2L)`, and the
helper now loops over every *consecutive pair* of a sentinel vector instead
of reading only `[[1]]`/`[[2]]`. I independently confirmed this by reading
the current helper source myself (not just taking the coordinator's word for
it) and by re-running `test-zero-one-beta.R`, which now reports **FAIL 17 /
PASS 3210**, not the originally briefed FAIL 20 / PASS 3151. **Mechanism class
(A) "SENTINEL ARITY" as originally briefed does not exist in the current
code and is retired below**, not listed as an open defect. See
"Class A — retired" for the full explanation and for what actually happens at
those six line numbers now.

Because of this repair, the true current total is **35 failures**, not the
38 the brief anticipated (13 batch-covered + 17 zero-one-beta + 5
missing-response-boundary). This is flagged explicitly rather than silently
reconciled; see "What this does NOT establish" for the residual 20→17
count discrepancy that could not be fully explained from static evidence
alone.

## Summary table: 30 files, FAIL/PASS, status

| # | File | FAIL | PASS | Status | Source |
|---|------|------|------|--------|--------|
| 1 | test-reml-binomial-coxreid.R | 1 | 32 | RED | batch-1 |
| 2 | test-control.R | 0 | 157 | GREEN | batch-1 |
| 3 | test-missing-response-recovery.R | 0 | 34 | GREEN | batch-1 |
| 4 | test-missing-response-beta.R | 0 | 65 | GREEN | batch-1 |
| 5 | test-missing-response-nbinom2.R | 0 | 80 | GREEN | batch-1 |
| 6 | test-animal-relmat-gaussian.R | 5 | 761 | RED | batch-1 |
| 7 | test-missing-response-truncated-nbinom2.R | 0 | 80 | GREEN | batch-2 |
| 8 | test-poisson-mean.R | 0 | 159 | GREEN | batch-2 |
| 9 | test-count-multiprovider-structured-mu.R | 0 | 30 | GREEN | batch-2 |
| 10 | test-missing-response-poisson.R | 0 | 63 | GREEN | batch-2 |
| 11 | test-missing-response-continuous.R | 0 | 351 | GREEN | batch-2 |
| 12 | test-count-structured-mu.R | 3 | 1034 | RED | batch-2 |
| 13 | test-beta-phylo-direct-sd.R | 0 | 65 | GREEN | batch-3 |
| 14 | test-reml-phylo-location.R | 0 | 46 | GREEN | batch-3 |
| 15 | test-missing-response-binomial.R | 0 | 93 | GREEN | batch-3 |
| 16 | test-phylo-gaussian.R | 0 | 520 | GREEN | batch-3 |
| 17 | test-spatial-gaussian.R | 3 | 421 | RED | batch-3 |
| 18 | test-cumulative-logit.R | 0 | 117 | GREEN | batch-4 |
| 19 | test-reml-structured-location.R | 0 | 284 | GREEN | batch-4 |
| 20 | test-missing-response-encoded.R | 0 | 140 | GREEN | batch-4 |
| 21 | test-reml-heteroscedastic.R | 0 | 80 | GREEN | batch-4 |
| 22 | test-nbinom2-sigma-structured-recovery.R | 1 | 105 | RED | batch-4 |
| 23 | test-nongaussian-structured-mu-slope.R | 0 | 157 | GREEN | batch-4 |
| 24 | test-hurdle-nbinom2-relmat-response-mask.R | 0 | 24 | GREEN | batch-5 |
| 25 | test-missing-response-biv-gaussian.R | 0 | 97 | GREEN | batch-5 |
| 26 | test-missing-response-gaussian.R | 0 | 127 | GREEN | batch-5 |
| 27 | test-phylo-interaction.R | 0 | 218 | GREEN | batch-5 |
| 28 | test-positive-continuous-structured-mu.R | 0 | 296 | GREEN | batch-5 |
| 29 | test-zero-one-beta.R | **17** | **3210** | RED | my rerun (post-repair) |
| 30 | test-missing-response-boundary.R | 5 | 257 | RED | my rerun |

**RED files: 7. GREEN files: 23. Current total failures: 35** (13 + 17 + 5).

## Failure inventory

Legend: **B** = non-convergence / substantive recovery miss; **C** = stale
fence (removed admission guard); **D** = tolerance-boundary numeric mismatch;
**E** = non-symbol structured-marker argument (new class, see below).
"Class A" (sentinel arity) is retired — see its own section.

| file:line | test name | class | cell(s) backed | claim impact |
|---|---|---|---|---|
| test-reml-binomial-coxreid.R:242 | binomial REML preserves unsupported-shape and missing-engine rejections | C | none (rejection fence, not a `formula_validated` source) | Confirms task brief: REML+missing-response was deliberately relaxed in `R/drmTMB.R`; this `expect_error` is stale, not evidence of breakage. |
| test-animal-relmat-gaussian.R:1645 | Gaussian matched one-slope relmat location-scale masks match observed data | B | mc-0317, mc-0318 | Sigma-SD recovery misses `log(2.5)` bound by `8.3` vs `0.9` — off by a factor of ~e^7.4, i.e. thousands-fold. Severe. |
| test-animal-relmat-gaussian.R:1816 | bivariate animal and relmat q2 response masks have exact conditional oracles | E | mc-0129, mc-0130 (animal, G2 sub-claim); mc-0151, mc-0152 (relmat, G2 sub-claim) | `relmat(1 \| p \| id, Q = sim$Q)` passes a non-symbol (`sim$Q`); `R/parse-formula.R:852` requires `is.symbol(structure_arg)`. `list(relmat = drmTMB(...), animal = drmTMB(...))` evaluates in order, so the relmat call errors first and the animal branch is never attempted in this block. |
| test-animal-relmat-gaussian.R:1872 | bivariate relmat q2 response masks recover an independent known DGP | E | mc-0151, mc-0152 (G3 sub-claim) | Same non-symbol `Q = sim$Q` bug. Fixture ("64 related IDs, 20-observation-per-ID") exactly matches mc-0151/0152's claim text, so this is very likely the row's *cited* G3 recovery test. |
| test-animal-relmat-gaussian.R:1904 | bivariate animal q2 response masks recover an independent known DGP | E | mc-0129, mc-0130 (G3 sub-claim) | Same bug, `Ainv = sim$Q`. Fixture matches mc-0129/0130's claim text exactly. |
| test-animal-relmat-gaussian.R:1978 | bivariate animal and relmat q2 slope masks recover independent DGPs | B | mc-0153/mc-0154 (relmat slope) **or** mc-0131/mc-0132 (animal slope) — UNRESOLVED which | Loop over `settings = list(relmat, animal)`; only ONE `expect_lt(rho recovery, 0.20)` failure printed (`0.217 >= 0.200`), a narrow ~8.5% overage. Cannot tell from the printed output which of the two provider iterations produced it. |
| test-count-structured-mu.R:1223 | NB2 structured q1 intercept-slope response masks have separate recovery evidence | B | one of {mc-0410 phylo, mc-0411 spatial, mc-0412 animal, mc-0413 relmat} — UNRESOLVED | `mu`-x-coefficient miss `0.49 >= 0.20`, ~2.5x over. Loop over 4 providers; only 3 total failures printed (1 at :1223, 2 at :1224), so at most 3 of the 4 iterations are implicated but exact attribution needs a rerun with per-iteration output. |
| test-count-structured-mu.R:1224 (×2) | (same test) | B | same 4-cell set — UNRESOLVED | Sigma-coefficient misses `0.29 >= 0.18` and `0.50 >= 0.18` (~1.6x and ~2.8x over) at the same reported line, i.e. two distinct provider iterations. |
| test-spatial-gaussian.R:966 | bivariate spatial q2 response masks recover at the 128-site rung | B | mc-0107 | mu1 recovery miss `1.20 >= 0.25`, ~4.8x over. Severe. |
| test-spatial-gaussian.R:967 | (same test) | B | mc-0108 | mu2 recovery miss `0.88 >= 0.25`, ~3.5x over. Severe. |
| test-spatial-gaussian.R:984 | bivariate spatial q2 slope masks recover at the 128-site rung | E | mc-0109, mc-0110 | `spatial(0 + x \| p \| site, coords = sim$coords)` — non-symbol `coords`. |
| test-nbinom2-sigma-structured-recovery.R:249 | NB2 phylo log-sigma response mask has oracle and recovery evidence | B | mc-0421 | Sigma-intercept miss `0.214 >= 0.200`, ~7% over — narrow. |
| test-zero-one-beta.R:898 | zero-one-beta phylo mu response mask has oracle and recovery evidence | D | mc-0583 | `coef(fit_masked,"mu")` vs `coef(fit_observed,"mu")` at `tolerance=1e-6`: actual diff `6.8e-6` on the x coefficient. The `obj$fn`/`obj$gr` equality checks earlier in the same block (tolerance `1e-8`/`2e-5`) **passed**. See "mc-0583 note" below. |
| test-zero-one-beta.R:899 | (same test) | D | mc-0583 | `sigma` coefficient: absolute diff `9e-7`, relative diff ≈`1.1e-6` — narrowly over the `1e-6` gate. |
| test-zero-one-beta.R:901 | (same test) | D | mc-0583 | `coi` coefficient: absolute diff `3.7e-6`, relative diff ≈`1.7e-5`. |
| test-zero-one-beta.R:942 (×4) | zero-one-beta phylo sigma response mask has oracle and recovery evidence | B | mc-0593 | Both consecutive sentinel pairs' re-optimized `opt_a`/`opt_b` hit `convergence = 1` (nlminb raw defaults, no `control=`). Matches the task's own prior mc-0593 diagnosis exactly. |
| test-zero-one-beta.R:945 | (same test) | B | mc-0593 | Sigma-intercept recovery miss `abs(coef+1) = 0.52 >= 0.15`, ~3.5x over. |
| test-zero-one-beta.R:976 (×4) | zero-one-beta animal sigma response mask has oracle and recovery evidence | B | mc-0594 | Same non-convergence pattern as mc-0593, for the animal-sigma DGP. Matches the task's prior mc-0594 diagnosis exactly. |
| test-zero-one-beta.R:1067 | zero-one-beta relmat mu response mask has oracle and recovery evidence | D | mc-0585 | `coi` coefficient: absolute diff `5e-7`, relative diff ≈`2.2e-6`. |
| test-zero-one-beta.R:1631 | zero-one-beta admits only the exact zoi random-intercept q1 gate | C | none | Confirms task's cited example: `expect_error` for a non-canonical zoi random-effect form no longer throws. |
| test-zero-one-beta.R:1639 | (same test) | C | none | Same mechanism, a second `expect_error` site in the same block. |
| test-zero-one-beta.R:1821 | zero-one-beta admits only the exact coi random-intercept q1 gate | C | none | Confirms task's cited example for `coi`. |
| test-zero-one-beta.R:1978 | zero-one-beta admits only the exact coi random-slope q1 gate | C | none | Confirms task's cited example for `coi` random slope. (Not to be confused with `test-animal-relmat-gaussian.R:1978`, a different file, different mechanism — Class B.) |
| test-missing-response-boundary.R:252 | zero-one-beta zoi random-slope response mask matches observed data | B | mc-0577 | SD recovery miss `0.45 >= 0.25`, the fitted SD is nearly double the gate. |
| test-missing-response-boundary.R:254 | (same test) | B | mc-0577 | Slope-effect correlation `0.16 <= 0.35` — under half the required correlation. |
| test-missing-response-boundary.R:327 | zero-one-beta coi random-slope response mask matches observed data | B | mc-0578 | SD recovery miss `0.45 >= 0.25`, same magnitude as mc-0577. |
| test-missing-response-boundary.R:329 | (same test) | B | mc-0578 | Slope-effect correlation `0.253 <= 0.350`. |
| test-missing-response-boundary.R:387 | Tweedie mu random-slope response mask matches observed data | B | mc-0539 | `nu` recovery miss `1.8 >= 0.15` — **~12x over the gate, the largest magnitude in this entire audit.** The upstream `coef(mu)`/`coef(sigma)` masked-vs-observed equality checks in the same block passed; only the DGP-recovery check for `nu` failed. See "mc-0539 note" below. |

## Class A — retired (do not action)

The task brief named `helper-missing-response.R:60`'s
`expect_length(sentinels, 2L)` as the mechanism behind six call sites
(897, 942, 976, 1015, 1051, 1121). I read the current helper source directly:
the assertion is `testthat::expect_true(length(sentinels) >= 2L)` (line 61),
which a length-3 vector like `c(0, 1, .5)` satisfies. A coordinating agent
separately confirmed this was a **repair landed in the working tree during
this audit** (old code silently read only `sentinels[[1]]`/`[[2]]` and
ignored any third element; new code loops over every consecutive pair). My
own fresh re-run against the repaired helper reproduces **zero** failures
attributable to sentinel length at any of the six cited lines. What the six
sites show *now*:

- `:897` — passes cleanly (no failure at this line in my rerun).
- `:942`, `:976` — fail, but on non-convergence (Class B, backing mc-0593 /
  mc-0594 — see table above), not arity.
- `:1015`, `:1051`, `:1121` — pass cleanly.

**Recommendation:** do not list Class A as an open defect anywhere in the
ledger or check-log. The `check-log.md` line claiming "direct atom/interior
response-sentinel retapes" for the affected cells is only true as of the
helper repair; before it, the third sentinel element was silently unexercised
at these six sites, so any claim resting on that line for those specific
cells should be understood as newly (not previously) substantiated.

## Class E — new (non-symbol structured-marker argument)

`R/parse-formula.R` intentionally requires a bare symbol for `relmat(K=/Q=)`,
`animal(pedigree=/A=/Ainv=)`, and `spatial(coords=/mesh=)` (`is.symbol(...)`
checks at lines ~690, 769, 852, 886). Four failures
(`test-animal-relmat-gaussian.R:1816,1872,1904`, `test-spatial-gaussian.R:984`)
pass a `$`-indexed expression (`sim$Q`, `sim$coords`) directly instead of
first binding a local symbol (`Q <- sim$Q`), which the parser rejects by
design. Other test blocks in the *same files* (e.g. the slope block at
`test-animal-relmat-gaussian.R:1935` that correctly does `Q <- sim$Q` before
calling `relmat(..., Q = Q)`) show the correct pattern side-by-side with the
broken one, confirming this is a test-authoring bug, not a package defect —
but see the impact note below: for four cells this bug means the cited
evidence currently **cannot run at all**, which is a stronger problem than an
ordinary harness defect (a test that runs and gives the wrong answer is at
least informative; a test that cannot execute gives no answer).

## Demote list (class B only) — with the reason per cell

Cells whose cited response-mask evidence includes a Class B (substantive,
non-tolerance, non-harness) failure, and for which I found no other
independent evidence in the ledger supporting the same G2/G3 claim:

- **mc-0317, mc-0318** (univariate Gaussian q2 relmat location-scale
  one-slope, `y ~ x + relmat(1+x|id,K=K)`, `sigma ~ relmat(1+x|id,K=K)`).
  Reason: sigma-SD recovery misses its `log(2.5)` bound by `8.3` vs `0.9` —
  a many-thousand-fold miss, not a borderline case.
- **mc-0107, mc-0108** (bivariate spatial q2 mu1/mu2 intercept). Reason:
  both mu1 and mu2 recovery miss their `0.25` bound by ~4.8x and ~3.5x
  respectively, at the exact 128-site fixture the cell's own claim text
  cites.
- **mc-0421** (NB2 sigma phylo intercept-plus-slope). Reason: sigma-intercept
  recovery narrowly misses its bound (`0.214` vs `0.200`, ~7% over). Narrow,
  but a real threshold violation with no competing evidence.
- **mc-0593** (zero-one-beta sigma phylo q1). Reason: reconfirms the task's
  own prior diagnosis — nlminb non-convergence on the retaped sentinel
  objective, plus a severe (~3.5x) sigma-intercept recovery miss.
- **mc-0594** (zero-one-beta sigma animal q1). Reason: reconfirms the task's
  own prior diagnosis — same non-convergence pattern.
- **mc-0577** (zero-one-beta zoi independent random slope). Reason: SD
  recovery misses its `0.25` bound at `0.45` (nearly double), and the
  slope-effect correlation (`0.16`) is under half the required `0.35`.
- **mc-0578** (zero-one-beta coi independent random slope). Reason: same
  magnitude of miss as mc-0577 (SD `0.45` vs `0.25`; correlation `0.253` vs
  `0.35`).

**Flagged but NOT placed on the hard demote list** (ambiguous attribution or
competing evidence — see notes):

- **mc-0410/mc-0411/mc-0412/mc-0413** (NB2 structured mu q1 intercept-slope,
  phylo/spatial/animal/relmat). At least one, and up to three, of the four
  provider iterations in the shared `test_that` block at
  `test-count-structured-mu.R:1163` fail a genuine (non-tolerance) recovery
  threshold. I cannot determine from the printed output which provider(s)
  are implicated without a rerun that prints `route$provider` per iteration.
  Recommend disambiguating before deciding which cell(s), if any, to demote.
- **mc-0131/mc-0132 or mc-0153/mc-0154** (bivariate animal-vs-relmat mu12 q2
  slope). Same ambiguity: one of the two provider iterations in
  `test-animal-relmat-gaussian.R:1935` misses its `0.20` rho-recovery bound
  by a narrow `0.017` (8.5% over); cannot tell which without a rerun.
- **mc-0539** (Tweedie mu ordinary random slope). The single largest-magnitude
  miss in the audit (`nu` off by `1.8` against a `0.15` gate) sits inside
  this cell's cited G3 recovery test. I did NOT add it to the hard demote
  list because mc-0539 carries substantial *additional*, independently-run
  interval/coverage evidence (the Arc 4c M16/M32/M64 profile-coverage
  campaign referenced in its `response-mask-formulas.tsv` row and in
  AGENTS.md's "3-cell mu-slope batch" entry) that this failure does not
  touch — so "ONLY evidence is a failing test" does not hold. The G3
  point-fit recovery sub-claim specifically, however, is not currently
  supported and should be treated as broken pending investigation; see the
  note below.
- **mc-0583** (zero-one-beta phylo mu q1) and **mc-0585** (zero-one-beta
  relmat mu q1). See "mc-0583 note" below — I classify these failures as
  Class D (tolerance), not Class B, based on directly measured magnitudes,
  which places them outside this list's scope by definition. A coordinating
  agent's message suggested treating mc-0583 as a demote candidate; I present
  both readings rather than resolve the disagreement unilaterally.

### mc-0583 / mc-0585 note (tolerance vs. substantive)

At `:898/:899/:901` and `:1067`, the failing assertion is a `tolerance=1e-6`
coefficient-level equality between two **independently re-optimized** fits
(`fit_masked` via the full `drmTMB()` pipeline with `missing =
miss_control(response = "include")`, vs. `fit_observed` via a completely
separate `drmTMB()` call on the row-dropped data). In the same test block,
the `obj$fn(probe)`/`obj$gr(probe)` equality checks against the analytic
oracle (`tolerance = 1e-8` and `2e-5` respectively) **passed** — i.e. the
formula's likelihood and gradient are exactly right at an arbitrary probe
point, which is the core claim `mc-0583`'s `claim_boundary` text leads with.
What fails is a much stronger, secondary claim: that two *separately
converged* optimizer runs land at the identical point to six decimal places.
That is not guaranteed by a correct formula alone; it additionally requires
optimizer-path determinism, which two independent `nlminb`/pipeline calls do
not provide by construction. Measured magnitudes were tiny in every case
(6.8e-6, ~1.1e-6 relative, 3.7e-6, and ~2.2e-6 relative) — one to two orders
of magnitude smaller than the Class B misses on this same list (which run
0.014 to 8.3 in absolute terms). On that basis I classify these as Class D.
**However**, `mc-0583`'s claim text does literally say "masked-versus-observed
fit equality," and that specific sub-claim, as tested, does not currently
hold at the stated tolerance — a defensible alternative reading (offered by
a coordinating agent) is to treat this as a genuine, if narrow, overreach of
the claim text and flag mc-0583/mc-0585 for narrowing rather than leaving
untouched. I record both positions rather than adjudicate the calibration
question myself.

### mc-0539 note (Tweedie mu random-slope, largest single miss)

The `nu` recovery failure at `test-missing-response-boundary.R:387` is by far
the largest-magnitude deviation in this audit (observed comparison `1.8`
against a `0.15` gate — roughly 12x over, versus the next-largest Class B
misses at 3.5–4.8x). Whether `coef(fit_mask, "nu")` is reported on a raw
link scale or an already-bounded scale was not verified in this audit (I did
not re-run the model to inspect `fit_mask$model` internals), so I cannot say
whether `1.8` represents an in-range-but-badly-biased `nu`, or an optimizer
excursion to a link-scale extreme that maps to a boundary `nu`. This
distinction matters for triage (numerical fragility vs. a possible genuine
defect in combining an independent `mu` random slope with a freely estimated
`nu` under response masking) and is flagged as **UNRESOLVED — would be
settled by inspecting `fit_mask$model$tmb_data`/the nu link function directly,
which this audit's scope (classify and map, do not fix) does not cover.**

## Harness-defect list (classes C, D, E) — cells NOT impugned, with why

- **Class C (stale `expect_error` fences), no cells impugned:**
  `test-reml-binomial-coxreid.R:242`;
  `test-zero-one-beta.R:1631,1639,1821,1978`. These are rejection tests
  asserting that a form the branch has since deliberately admitted (REML +
  missing response for binomial; zoi/coi random-intercept and random-slope
  forms other than the one exact gate) should still throw. Confirms the
  task's own prior finding for all four zero-one-beta lines and for
  `test-reml-binomial-coxreid.R:242`. None of these lines are themselves a
  `formula_validated` cell's cited G2/G3 evidence — they test the *absence*
  of a capability, and their failure means only that the guard is outdated,
  not that any admitted formula is wrong.
- **Class D (tolerance-boundary numeric mismatches), cells not impugned in my
  assessment (see mc-0583/mc-0585 note above for the dissenting view):**
  `test-zero-one-beta.R:898,899,901,1067`. All four are `tolerance=1e-6`
  coefficient-equality checks between two independently-converged fits, with
  measured absolute/relative diffs between 5e-7 and 6.8e-6 — one to four
  orders of magnitude tighter than any Class B miss in this audit, and
  co-located with passing 1e-8-tolerance objective/gradient equality checks
  that test the same underlying claim more directly.
- **Class E (non-symbol structured-marker argument), impact on cells is
  "evidence currently unrunnable," not "evidence disproven":**
  `test-animal-relmat-gaussian.R:1816,1872,1904`, `test-spatial-gaussian.R:984`.
  The parser's `is.symbol()` requirement is intentional, documented behaviour
  (`R/parse-formula.R`), and the exact same marker syntax with a properly
  bound local symbol is demonstrably used correctly elsewhere in the same
  test files. This is a test-authoring bug. **Important caveat:** for
  mc-0129/mc-0130/mc-0151/mc-0152, the specific tests that error out appear
  (by fixture match) to be the row's *only* cited G2 and G3 evidence in this
  lane — so while the mechanism does not disprove the formula, it also means
  there is currently **no functioning evidence** for these four cells'
  response-mask claims in this test file. I did not find alternate passing
  evidence for the same claim elsewhere in `test-animal-relmat-gaussian.R`
  (761 passing expectations exist in the file, but I did not exhaustively
  verify whether any of them independently re-establish the same G2/G3
  claims for these four cells under a correctly-bound `Q`/`Ainv`). This is
  flagged as UNRESOLVED rather than either cleared or demoted.

## Unmappable claims — cells with no locatable evidence

None found. Every one of the 35 currently-reproducible failures was traced to
a specific test block whose fixture (formula text, group/tip count,
observations-per-group) matches a specific `mc-XXXX` row's `claim_boundary`
text in `response-mask-formulas.tsv`, with the following exceptions, which
are ambiguous-among-a-known-set rather than unmappable:
`test-count-structured-mu.R:1223/1224` (4-way provider loop) and
`test-animal-relmat-gaussian.R:1978` (2-way provider loop) — see the
"flagged but not placed on the hard demote list" entries above. I want to be
precise about what this section does and does not claim: **I audited only
the cells backing the 35 reproducible failures**, not all 185
`formula_validated` rows in `response-mask-formulas.tsv`. A genuinely
unmappable claim — a `formula_validated` row with no locatable test anywhere
in the 30 files — could exist among the 22 files I did not personally
re-run and did not independently cross-reference cell-by-cell (I relied on
the other agents' batch summaries for those). That possibility is outside
this audit's scope; see "What this does NOT establish."

## What this does NOT establish

- **This is not a full audit of all 185 `formula_validated` cells.** It
  covers only the cells that back the 35 currently-reproducible failures. The
  23 GREEN files establish that their tests currently pass, not that every
  cell they claim to back is correctly and uniquely attributed — I did not
  verify cell-by-cell backing for green files; that would require repeating
  the same fixture-matching exercise done above for every passing
  `test_that()` block across ~5,900 additional passing expectations, which
  is out of scope for a red-surface audit. This report does not say "all 185
  cells are validated" or "everything not in the demote list is safe" — it
  only means: I traced these specific 35 failures to these specific test
  blocks and (where unambiguous) these specific cells.
- **The 20→17 zero-one-beta count discrepancy is not fully reconciled.**
  Six line numbers (897, 942, 976, 1015, 1051, 1121) were originally cited
  as failing on sentinel arity; my fresh run only reproduces convergence
  failures at two of them (942, 976). Since these tests re-seed
  deterministically (`set.seed(...)` calls inside each block) and the helper
  repair should not itself change *whether* a given `nlminb` call converges
  at the `(0,1)` sentinel pair (only whether a `(1,.5)` pair is *additionally*
  checked), the disappearance of failures at 897/1015/1051/1121 is not fully
  explained by the helper repair alone. Plausible contributing factors I did
  not verify: (a) the original 20-count audit ran against a different
  package build/commit state than my rerun, or (b) `nlminb` convergence on
  these boundary-heavy DGPs is genuinely sensitive to BLAS/threading
  nondeterminism on this machine (macOS Accelerate framework) even under a
  fixed R seed. Settling this would need two back-to-back reruns of the
  identical file against the identical build with `OPENBLAS_NUM_THREADS=1`
  (or equivalent single-threaded BLAS pinning) to see whether the failing-line
  set is stable.
- **No fixes were applied.** Per my brief, I did not edit tests, `R/`, or
  `tools/`, including the two one-line-fixable bugs I identified with high
  confidence (Class E's missing `Q <- sim$Q`/`Ainv <- sim$Q` binds, and the
  now-stale Class C `expect_error` fences).
- **Severity claims for mc-0539's `nu` miss are diagnostic, not causal.** I
  did not determine why `nu` misses by 12x its gate; see the mc-0539 note.
- **The demote list is not a merge-blocking ruling.** It states which cells'
  *cited* evidence is currently broken by a substantive (non-harness)
  failure and for which I found no competing evidence; whether the ledger
  maintainer should actually flip `formula_status` is a decision this audit
  informs but does not make.
