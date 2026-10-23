# Docs staleness: the two generated design docs re-derived over today's merges

**Reader**: anyone reading `docs/design/parity-matrix.md` or
`docs/design/261-reml-by-route.md` and deciding what drmTMB can and cannot do
today; anyone about to merge a PR that moves lines in `R/julia-bridge.R`,
`R/drmTMB.R`, or the two capability TSVs; anyone who wants to know why a
generated artefact can go stale without any test turning red.

Leaf ledger: `.unlazy/parity/gates/leaf-docs-staleness.md`. Worktree branch
`claude/parity-docs-staleness` off `origin/main`, `origin/main` merged in twice
(at `6370f9c5a` and again before push).

## 0. Which DRM.jl pin this leaf used, and why two

Two clones, deliberately:

* `drmjl-d3efbad2` (`d3efbad2f402cffb01e08eaf4efb25888d5fed96`) -- **the pin the
  committed `parity-matrix.md` names in its own header**. Every regeneration of
  that artefact here used this clone. Regenerating at the brief's pin
  `430ef64cc` would have rewound the whole native_Julia axis: `430ef64cc` is an
  ANCESTOR of `d3efbad2` (`git merge-base --is-ancestor` confirms), so the
  matrix would have moved backwards in DRM.jl time. Repinning the matrix is a
  different leaf's decision, not this one's.
* `drmjl-430ef64cc` -- the brief's pin, used for the one LIVE fit in this leaf
  (the hurdle cross-spelling probe, §2.5).

## 1. Goal

Clear the documentation staleness that today's merges left in the two
GENERATED design docs, by fixing the docs' INPUTS (a hand-maintained status
file and two generator scripts) and regenerating -- never by hand-editing a
generated file -- and then sweep for more of the same kind.

## 2. Implemented

Seven staleness items. Three were named in the brief; four more came out of the
sweep. Every one is a change to a generator INPUT followed by a regeneration.

### 2.1 Chi-bar-square boundary LRT p-value: `planned` -> `implemented`

`#1116` (`b76d46537`) shipped `chibar_pvalue()` and `lrt_boundary()` as native R
today. `docs/design/capability-status.md` still said `planned` and the matrix
still said "native R only flags wald_at_boundary ... NEXT: port to native R".
Verified in this run: `export(chibar_pvalue)` and `export(lrt_boundary)` are in
`NAMESPACE`; `R/lrt-boundary.R`, `man/lrt-boundary.Rd` and
`tests/testthat/test-lrt-boundary.R` all exist. The evidence tier is quoted from
that PR's own live receipt rather than restated as if freshly measured here.

### 2.2 Model comparison suite: `planned` -> `scope-limited`, not `implemented`

`#1117` (`b21581f95`) ported `aicc()` and `lrtest()`. `scope-limited` is the
honest word, measured here rather than assumed: `export(aicc)` with `default`
and `drmTMB` methods IS in `NAMESPACE`; `drm_lrtest()` exists at
`R/model-comparison.R:116` but appears nowhere in `NAMESPACE`;
`anova.drmTMB()` (`R/methods.R:2708`) still aborts with "`anova()`
likelihood-ratio comparisons are not implemented for `drmTMB` fits"; there is no
`S3method(update,drmTMB)`; and `weights.drmTMB()` (`R/methods.R:772`) returns
`object$model$weights`, the prior per-observation weights.

### 2.3 AGHQ: the status word is right, the reason given for it was wrong

Fixing 2.1/2.2 deleted the paragraph the AGHQ matrix row cited, which forced a
read of that row -- and it was wrong on its own terms. It claimed AGHQ has "no
implementation in `R/`". `R/aghq-coxreid.R` (added 2026-07-18, `1ed90599b`)
implements it, with `tests/testthat/test-aghq-coxreid.R`; it is simply not
exported (0 hits for `aghq`/`cox` in `NAMESPACE`). `planned` stays -- it records
an EXPOSURE gap, not an empty `R/`. The row now says so.

### 2.4 Coevolution accessors (#1118): shipped, and they have no row anywhere

The matrix's Heritability row said "DRM.jl-side coevolution accessors are ported
under leaf A7". `4708dfe5e` shipped them: `export(coevolution_cor)`,
`export(coevolution_vc)`, `export(coevolution_summary)`. The honest finding is
sharper than "they landed": **neither twin's `capability-status.md` names a
coevolution capability**, so the matrix -- which joins on row NAME -- structurally
cannot carry them. The row now says that, and the next action is to give them a
row on both sides.

### 2.5 Hurdle NB2 cross-spelling: half the boundary is no longer true (LIVE)

The matrix said "the bridge refuses truncated_nbinom2() and reaches DRM.jl only
as nbinom2() + `hu ~`". A4 (`#1173`, `40e878679`) admitted `truncated_nbinom2`
at the family tag, so that clause is false. Measured live at DRM.jl `430ef64cc`
(`docs/dev-log/evidence/julia-r-parity/docs-staleness/hurdle-cross-spelling-probe.R`):
the tag resolves, and the NATIVE spelling `truncated_nbinom2() + bf(y ~ x,
sigma ~ 1, hu ~ 1)` now fails INSIDE Julia instead:

    drm_bridge: coef_labels supplies names for unknown dpar "hu";
    the model has dpars: mu, sigma

The row's CONCLUSION ("no identical call fits on both engines") survives; its
REASON moved from the R side to the Julia side, and so did the next action.

### 2.6 Slope-phylo route: admitted-without-a-row -> a registered refusal

The matrix said the bridge "admits nbinom2/gamma/beta on this route without a
ledger row". `#1146` (`d240e3515`) registered the `structured_marker_slope` gate
and `drm_julia_marker_slope_pin_supports()` is `FALSE`, so the SLOPE half is now
refused BEFORE Julia. Measured with nbinom2 in this run:

    `engine = "julia"` cannot fit a random slope inside a `phylo()` marker.

The COUPLED mu+sigma half still reaches DRM.jl unledgered, and the row now
separates the two. `gate_ids` was deliberately NOT set on this row: it would
have reported the WHOLE row as a gated refusal when only half of it is.

### 2.7 Two stale leaf pointers

* Four A4-admitted families (`truncated_nbinom2`, `cumulative_logit`,
  `zero_one_beta`, `tweedie`) carried "NEXT: ledger the route with receipts
  (leaf A3)". A3 merged (`c5dd2cee4`) and `ultra-plan.md:160` scopes it to the
  SIX pre-A4 routes. Their rows arrive with the A4 integration PR (#1184, OPEN).
* "NEXT: measure with the estim_method oracle (leaf A5)" -- A5 merged
  (`e5cbbc5db`) and DID measure it; its result is already quoted on the sibling
  `Gaussian random intercept (mean)` row. What is missing is a TSV row, not a
  measurement.

### 2.8 The 261 row (item 3 of the brief)

`general_covariance_structured` (gaussian) said the structured-term gate "is
checked BEFORE any family dispatch and refuses unconditionally". Both halves are
over-broad, measured in
`docs/dev-log/evidence/julia-r-parity/docs-staleness/structured-reml-dispatch-probe.R`:
the family type IS resolved first (`biv_gaussian` with the same relmat marker
takes its own branch one step earlier and raises a DIFFERENT message), and
"unconditionally" is scoped to `drm_julia_structured_marker_types()` =
relmat/animal/spatial -- `drm_julia_has_structured_term()` is FALSE for a
`phylo()` term. The refusal for THIS cell still fires; only the gloss changed.
One line of the generator, one line of the output.

### 2.9 A retired gate id still cited in the generator

`fam("Beta-binomial proportions", ...)` carried a `refused_note` citing gate
`base_unsupported_family`, which `#1172` RETIRED (0 occurrences in
`inst/extdata/julia-gates.tsv` today). R's lazy argument evaluation hid it: the
note is only forced when the family is refused, and beta_binomial is admitted.
It would have aborted generation the moment anything re-refused the family.
Removed, with the reason in a comment.

## 3. What the sweep covered, and its denominator

**127 commits** on `origin/main` in the 24 h window (**64** non-merge), measured
in this run with `git log --since="24 hours ago" --oneline origin/main | wc -l`.

The sweep was mechanical, not a per-commit read: both generated design docs were
regenerated from the committed inputs and diffed against the committed
artefacts. Regeneration is exhaustive over commits by construction -- any input
change any commit made shows up as a diff. Every resulting hunk was then
attributed:

Regenerating `parity-matrix.md` from the UNMODIFIED committed inputs changed
**32 of its 45 rows** -- pure drift, none of it this leaf's doing:

| cause | rows |
|---|---|
| cited `file:line` numbers only (`R/julia-bridge.R`, `R/drmTMB.R`, `capability-status.md`) | 31 |
| substantive: gate count `14 => 15` (`fe_only_random_effects`, `b43897d03`) | 1 |

This leaf's own edits then took the total to **39 of 45** rows changed against
the committed artefact: the seven items above, plus three rows
(`Bivariate structured ... (q4 PLSM)`, `Missing-response handling`,
`Missing-predictor imputation (mi())`) whose only change is a
`capability-status.md` line number shifted by the longer prose in §2.1-2.3.

`docs/design/261-reml-by-route.md` regenerated **byte-identically** from the
unmodified inputs before this leaf touched it, so its only staleness was the
one hand-written row string in §2.8.

Attribution of the drift: the matrix was last regenerated at `1cde89fa8`
(2026-09-05 16:23). **8 non-merge commits** touched a matrix input after that
and none regenerated it.

Commits that changed `NAMESPACE` in the window: **4**. Three are items 2.1, 2.2,
2.4. The fourth, `b8103bb56`, adds `S3method(check_drm,drmTMB_julia)` -- checked
and NOT stale: the `R to Julia bridge (engine=julia)` row was already
`implemented` and no generated text claims `check_drm()` is missing.

## 4. Files touched

* `docs/design/capability-status.md` -- two status words, one prose block rewritten (INPUT).
* `tools/write-parity-matrix.R` -- seven `st()`/`fam()` entries + one default next_action (INPUT).
* `tools/write-reml-route-table.R` -- exactly one row string (INPUT).
* `docs/design/parity-matrix.md` -- REGENERATED.
* `docs/design/261-reml-by-route.md` -- REGENERATED.
* `docs/dev-log/evidence/julia-r-parity/docs-staleness/` -- two probes + their logs.
* this file.

## 5. Checks run

All measured in this run.

* `tools/write-parity-matrix.R` at `d3efbad2`: `wrote 45 parity-matrix rows (4 GREEN)`; run twice, byte-identical; matches the committed artefact.
* `tools/write-reml-route-table.R`: `wrote 30 REML route rows`; run twice, byte-identical.
* `NOT_CRAN=true`, `DRM_JL_PATH` = the d3efbad2 clone:
  * `test-parity-matrix.R` -- FAIL 0 | ERROR 0 | SKIP 1 | PASS 134
  * `test-reml-route-table.R` -- FAIL 0 | ERROR 0 | SKIP 0 | PASS 5
  * `test-julia-gate-vs-engine.R` -- FAIL 0 | ERROR 0 | SKIP 0 | PASS 144
  * `test-julia-family-registry.R` -- FAIL 0 | ERROR 0 | SKIP 0 | PASS 22
* The single SKIP is test 1 (four A4 routes awaiting #1184's TSV rows, a
  condition the test itself documents). The byte-identity + currency test is
  test 4: `skipped = FALSE, passed = 6`, so `expect_identical(gen, committed)`
  RAN and passed -- it is not one of the skips.
* `python3 tools/validate-mission-control.py`: 19 errors on this branch, 19 with
  `capability-status.md` reverted to `HEAD`. Delta **0**.
* Non-ASCII byte scan of both edited generators: **0** bytes > 127.

## 6. Tests of the tests (red controls)

* **The staleness itself.** Regenerating from the UNMODIFIED inputs at the
  artefact's own pin did NOT reproduce the committed `parity-matrix.md`
  (32 of its 45 rows differed). The committed artefact was stale before this leaf.
* **Why no test caught it.** `test-parity-matrix.R`'s currency assertion is
  guarded by `if (identical(clone_pin, committed_pin))` and SKIPS otherwise, so
  drift is invisible unless the DRM.jl clone happens to sit at the artefact's
  pin. That is the mechanism, named here rather than left implicit.
* **Full revert control.** With `tools/write-parity-matrix.R` AND
  `docs/design/capability-status.md` both restored from `HEAD`, regeneration put
  every stale string back: `NEXT: port to native R` x2, `coevolution accessors
  are ported under leaf A7` x1, `native R only flags wald_at_boundary` x1,
  `ledger the route with receipts (leaf A3` x4, and the Chi-bar-square row's
  native_R word back to `planned`. Both files restored byte-identically
  (sha256 before == after: generator
  `3ebe4c1e5630613845f8989312222521e23e65c976266c1caf0388a04ab3d669`).
* **Half-fix control.** With ONLY `capability-status.md` fixed and the generator
  reverted, generation ABORTS: `Error: citation anchor not found in
  docs/design/capability-status.md: `AGHQ`, chi-bar-square boundary tests`. The
  generator and its input are coupled, and a partial fix fails loudly.
* **261 control.** With `tools/write-reml-route-table.R` reverted, "is checked
  BEFORE any family dispatch and refuses unconditionally" comes back (1 hit);
  with the fix, 0 hits and 1 hit for the corrected text. Generator restored,
  sha256 MATCH.

## 7. Known residuals / NOT covered

* **The pin was NOT advanced.** `parity-matrix.md` still names `d3efbad2`.
  Deliberate: repinning is a separate decision.
* **No new test guards this class of drift.** The skip-on-pin-mismatch above is
  named but not fixed. Fixing it (a currency check that fails rather than skips)
  needs a decision about which pin CI should hold, which is not this leaf's.
* **`#1155`'s follow-up** ("file the REML ArgumentError-passthrough gate
  defect") was checked -- `#1155` is a MERGED PR and the defect is still
  unfiled, so the pointer is provenance, not staleness. Left as is.
* No claim is made about coverage or calibration of anything named here.
* The four A4 families' TSV rows remain absent; they belong to #1184 (OPEN).
* Sweep limits: it covers the two GENERATED design docs. Hand-written design
  docs, vignettes, roxygen and `NEWS.md` were NOT swept.

## 8. Errors made in this run

* First attempt at the slope-phylo row set `gate_ids = "structured_marker_slope"`,
  which flipped the entire row's `r_bridge_status` to a gated refusal when only
  the SLOPE half is gated. Caught by reading the regenerated row; corrected to
  cite the gate in prose and leave the row `unledgered`.
* The first dispatch's draft prose restated `#1116`'s parity numbers loosely
  ("1e-8 on the statistic"); the PR's own receipt says `|dstat|` at most
  `4.84e-09` and `1e-12` relative on `chibar_pvalue`. Corrected and attributed.
* An acceptance-gate `CHECK` used `grep -c 'A$\|B$\|C$'`. That returns 3 under
  the interactive shell's `grep` (a `ugrep` function) and **1** under
  `/usr/bin/grep` in `/bin/sh`, where BSD BRE has no `\|`. The gate failed and
  exposed it. Rewritten as portable `grep -cE '^export\(coevolution_(cor|vc|summary)\)$'`,
  and the one affected claim (three coevolution exports) re-verified with
  `/usr/bin/grep -cE` -> `3`. Every other count in this report is a literal
  fixed-string match, unaffected by the two greps' differing dialects.
* Two more gate `CHECK`s chained `grep -c` with `&&`: a legitimate count of `0`
  exits 1, so the chain reported failure on a passing condition. Rewritten to
  emit one success-only token and exit 0.
