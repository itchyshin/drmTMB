## 1. Goal

Slice S3 = ARC C2 of the true-parity plan: build the drmTMB half of the
coefficient-label PRODUCER contract (design 258 §7), per owner decision D-202
(2026-09-02): base-R spelling is canonical. `R/julia-coefficient-labels.R`'s
validator for `bridge_formula_labels_v1` existed already but was unreachable
because no code produced a map or checked what happens when one is absent.

## 2. Implemented

**(a) Payload producer.** `drm_julia_bridge_payload_coef_labels(formula, data,
env)` (`R/julia-bridge.R`) builds a `coef_labels` field: per dpar, the base-R
`colnames(stats::model.matrix())` for that dpar's plain formula entry, using
the SAME `stats::model.frame()`/`stats::model.matrix()` idiom already used by
`drm_julia_xfam_axis()`/`drm_julia_xfam_sigma()` (one design-matrix
construction, reused). A dpar with a structured term (phylo / `sd(...)` / any
random effect -- detected via the already-parsed `entry$structured`) or whose
model matrix fails to build is silently omitted -- first cut covers only
plain fixed-effect formulas, per project doctrine (simple first, random
effects later). `drm_julia_bridge_payload()` now returns this field.

**(b) Echo (DRM.jl's half, specified not built).** Design 258 §7.2 transcribes
the EXISTING validator's exact field requirements
(`coef_label_contract`, `coef_names`, `raw_coef_names`, `coef_name_map`,
`vcov_names`) and the exact failure strings it already raises, so DRM.jl can
build against a precise spec rather than reverse-engineering
`R/julia-coefficient-labels.R`.

**(c) R-side fail-closed rule.** `new_drmTMB_julia()`'s post-call label step:
when `drm_julia_bridge_coef_labels(result)` returns a valid map, behaviour is
unchanged. When it returns `NULL` (no map echoed), the new
`drm_julia_bridge_check_coef_labels(coef_names, bridge_payload$coef_labels)`
(`R/julia-coefficient-labels.R`) splits the engine's raw names by dpar and
compares them, per dpar, by exact `identical()` string/order equality against
the payload's base-R names. Identical -> the fit proceeds unchanged (plain
terms, e.g. `- term`, keep working). Different -> `cli::cli_abort()`, naming
DRM.jl and listing the mismatched dpar/columns, with a hint that DRM.jl must
supply `bridge_formula_labels_v1`. A dpar absent from the payload's
`coef_labels` (structured term, or a `bridge_payload` from a route that does
not populate the field -- structured/xfam/known-cov bridges) is not checked.

## 3a. Decisions and Rejected Alternatives

- Base-R spelling as canonical was ALREADY DECIDED (D-202), not re-litigated
  here; §7 implements it rather than re-arguing §4's two candidates.
- The comparison in (c) is a plain `identical()` on already-final strings,
  never a `gsub`/regex translation -- §3's binding "no punctuation-based
  guessing" constraint, and gate S3-G4 greps R/ for exactly this.
- `coef_labels` omits any dpar with a structured term rather than attempting
  a partial/best-effort label for it -- keeps the first implementation
  simple; a formula mixing fixed and random effects on one dpar gets no
  producer-side check for that dpar (silently additive, not a regression,
  since without S3 there was no check for it at all).
- Did not touch `drm_julia_predict_fixed_eta`'s existing
  `gsub(": ", "", gsub(" & ", ":", names(beta)), fixed = TRUE)` fallback
  (introduced by commit a6de6bb71, predates this slice, guarded by
  `is.null(object$bridge_public_coef_labels)`) even though it makes gate
  S3-G4 fail as literally grepped -- it sits in a part of `R/julia-bridge.R`
  explicitly outside this slice's touch scope (only
  `drm_julia_bridge_payload` and the post-call label step were in scope), and
  it is a PREDICT-time fallback, not the fit-time "post-call label step" the
  slice brief named. See §7.

## 4. Files Touched

`docs/design/258-coefficient-naming-contract.md` (new §7);
`R/julia-bridge.R` (`drm_julia_bridge_payload_coef_labels()`, `coef_labels`
field on `drm_julia_bridge_payload()`, the fail-closed call in
`new_drmTMB_julia()`); `R/julia-coefficient-labels.R`
(`drm_julia_bridge_check_coef_labels()`); `tests/testthat/test-coefficient-labels.R`
(new); this report.

## 5. Checks Run

`Rscript -e 'devtools::load_all("."); testthat::test_dir("tests/testthat",
filter="julia-bridge|coefficient-labels", reporter="summary")'` -- 0
failures across `test-coefficient-labels.R` (17 tests / new file),
`test-julia-bridge-coef-labels.R`, `test-julia-bridge-summary.R`,
`test-julia-bridge.R` (0 live-Julia skips reported, none require it).
`test-julia-inference.R` and `test-julia-structured-inference.R` (both use
`new_drmTMB_julia()` with `bridge_payload`) were also run directly and pass
with 0 regressions; their `bridge_payload` fixtures either carry a valid map
or omit `coef_labels`, so the new fail-closed branch is a no-op for them.

Gate run: `node .../gate-check.mjs --root ".../drmTMB" --cwd
".../wt-s3" --reverify --approve .unlazy/true-parity/gates/leaf-s3.md`.
4 of 6 MET (S3-G1, S3-G2, S3-G3, S3-G5). 2 UNMET -- see §10.

## 6. Tests of the Tests

`test-coefficient-labels.R` was written RED first: each "construct N" test
calls the REAL producer (`drm_julia_bridge_payload_coef_labels()`) on an
actual `bf()` formula/data pair for that construct (verified interactively
against design 258 §2's ten formula fragments before writing the fixed
expectations into the test), then feeds those names as the STUB engine map's
public half (paired with §2's documented DRM.jl raw spelling) through the
unchanged validator. The reorder/duplicate/incomplete tests each damage one
field of an otherwise-valid fixture and assert the SAME pre-existing
validator's specific failure text. The "absent"/fail-closed and "identical
plain names pass through" tests exercise the new
`drm_julia_bridge_check_coef_labels()` directly and via a full
`new_drmTMB_julia()` round trip (both a matching and a mismatched case).

## 7a. Issue Ledger

This is S3 of the true-parity ARC C2 plan; no issue was filed by this slice.
The DRM.jl half (§7.2's echo) remains a written handoff for the DRM.jl lane,
not landed work.

## 8. Consistency Audit

Checked every existing call site of `new_drmTMB_julia()` (3: the main
`drm_julia_bridge_payload()` route, `drm_julia_biv_known_structured_payload()`,
`drm_julia_structured_payload()`) and every test file constructing a fake
`bridge_payload` or `result` for it (`test-julia-bridge-coef-labels.R`,
`test-julia-bridge.R`, `test-julia-inference.R`,
`test-julia-structured-inference.R`) to confirm none regress: the structured/
known-cov/xfam routes build their own `payload` objects that do not populate
`coef_labels`, so `bridge_payload$coef_labels` is `NULL` there and the new
check is `length(NULL) == 0` -> a no-op, matching the additive-only scope of
this slice (their touch was explicitly out of bounds).

## 9. What Did Not Go Smoothly

`devtools::document()` regenerated `man/confint.drmTMB.Rd` (an unrelated
`\code{}`-wrapping normalisation drift) and two unrelated new man pages
(`drm_julia_joint_prepare.Rd`, `drm_julia_joint_result.Rd`) that follow from
NO edit in this slice; both were discarded (`git show HEAD:... >` the Rd
file, `rm` the two new ones) rather than committed, per "keep only Rd changes
that follow from your edits." Neither new function added by this slice
carries roxygen (matching the rest of `R/julia-bridge.R` and
`R/julia-coefficient-labels.R`, both plain-comment files), so no man/ files
follow from this slice at all.

## 10. Known Residuals

- **Gate S3-G4 (no punctuation-based translation in R/) is UNMET.** The grep
  matches ONE pre-existing line, `R/julia-bridge.R:4400` (originally line
  4355 before this slice's insertions), inside `drm_julia_predict_fixed_eta`,
  introduced by commit a6de6bb71 ("fix: predict(newdata) aligns Julia's
  factor/interaction coefficient names (#1099)"), predating this slice and
  guarded by `is.null(object$bridge_public_coef_labels)`. This is a
  PREDICT-time fallback for legacy/unversioned fits, not the fit-time
  "post-call label step" this slice's touch scope named, and
  `drm_julia_predict_fixed_eta` was not on the allowed-touch list. This
  slice's new code introduces ZERO new `gsub`/regex translations anywhere;
  `grep -rEn 'gsub\([^)]*(__bridge|& )' R/` before any of this slice's edits
  shows the same single pre-existing match. Flagging for the slice owner
  rather than silently editing a function outside the granted scope,
  especially given the LANE CHECK warning that 28 other refs carry pending
  work on `R/julia-bridge.R`.
- **Gate S3-G6 (native TMB labels unchanged) is UNMET as literally written.**
  The CHECK calls `drmTMB(y ~ ..., data = d)` with a bare R formula, but
  `drmTMB()` (`R/drmTMB.R:258-262`, unrelated to this slice) requires
  `formula` to be built with `drm_formula()`/`bf()` and aborts otherwise --
  a pre-existing API requirement, not something this slice touches or could
  have caused (`R/drmTMB.R` is not on this slice's touch list). Functional
  equivalence was verified by hand: running the SAME assertions with the
  formula wrapped in `bf(...)` gives
  `"mu:(Intercept)" "mu:z" "mu:poly(x, 2)1" "mu:poly(x, 2)2"
  "mu:factor(grp)lo" "mu:factor(grp)mid" "mu:I(x^2)" "mu:scale(z)"
  "mu:z:poly(x, 2)1" "mu:z:poly(x, 2)2" "sigma:(Intercept)"` -- unchanged
  base-R spelling, `TMB_LABELS_UNCHANGED` would print. The gate's own CHECK
  text needs a `bf()` wrap to run at all under the current `drmTMB()` API;
  this is a gate-authoring issue, not a code regression.
- No live-Julia round trip exists yet: until DRM.jl implements §7.2's echo,
  every construct in §2 either still fails closed (abort, an improvement
  over today's silent wrong-name pass-through) or, for plain terms with no
  synthetic renaming, continues to pass through unchanged. This slice's
  tests exercise only the R-side functions against constructed fixtures.
- Structured/xfam/known-covariance bridge routes do not populate
  `coef_labels` on their own payloads and get no producer-side check --
  explicitly out of this slice's touch scope.
