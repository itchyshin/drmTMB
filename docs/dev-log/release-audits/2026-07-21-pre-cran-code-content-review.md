# Pre-CRAN code + content review — BLOCKED

**Review baseline:** `origin/main` at `7abdd7e9f038d09554a28420dfcf2830dbc2f81d`
(merged PR #808, 2026-07-21).  This review deliberately did not rebuild or
re-check the frozen tarball-clean rung, run a platform matrix, change a
capability tier, or run new simulation compute.

## Verdict

**BLOCKED before the platform-clean gate.** Two shipped-surface findings meet
the predeclared blocker fence.  The manifest remains the truth ceiling; this
report does not alter a capability claim or prescribe a repair.

## BLOCKER — cross-family Julia post-fit contract (#806)

`new_drmTMB_julia_xfam()` constructs an object without the fields inherited
Julia methods require.  On a synthetic object of that class at this exact SHA,
`df.residual()` returned `integer(0)`, `vcov()` and `fitted()` returned `NULL`,
and `fixef(object, "sigma1")` rejected the axis although `coef()` exposes the
cross-family sigma blocks.  The constructor and inherited methods establish
the same result in source: `R/julia-bridge.R:4200-4235`, `:2008-2015`, and
`:2695-2706`.

This is a correctness defect.  It is also a false shipped claim because the
cross-family article lists `df.residual()` among working likelihood/dimension
summaries: `vignettes/cross-family.Rmd:283-290`.  The capability article
correctly discloses the other unwired extractors at
`vignettes/capability-and-limits.Rmd:398-406`, but does not make the documented
`df.residual()` output valid.

**Required disposition before platform checks:** a repair must make each
advertised extractor return a correct typed result, or a clear explicit error;
silent `NULL`/length-zero output is not acceptable.  Because this changes the
public Julia capability surface, implementation and wording require Shinichi's
decision.

## BLOCKER — Gamma inference wording contradicts the ledger

`README.md:361-363` says that only the exact lognormal Arc 4a domain has
coverage-backed `inference_ready_with_caveats` evidence and describes Gamma as
point recovery only.  The generated family map instead identifies Gamma
`mc-0242` as `inference_ready_with_caveats`:
`vignettes/includes/capability-ledger-family-map.md:7`.  The 20 July manifest
also records the Gamma promotion.  This is a false shipped claim, not a change
to the underlying evidence.

**Required disposition before platform checks:** reconcile the shipped prose
with the manifest/ledger only after Shinichi confirms the intended public
claim wording.

## FOLLOW-UP — native `coef()` discoverability

The list-return API is internally coherent: `coef(fit)` returns dpar-keyed
blocks (`R/methods.R:2260-2266`), `fixef()` delegates to it
(`R/methods.R:89-91`), and native tests check the contract
(`tests/testthat/test-gaussian-location-scale.R:34-47`).  Its lack of a direct
Rd alias/example is discoverability debt, not an incorrect result.  Do not
change the list-return API in this release review.

## Verified non-blocking evidence

- The C++ review found no demonstrated correctness defect in the six
  `asDouble()` casts, missing-response masks, positive-scale transforms, Beta
  direct-SD mapping, or bivariate covariance path.  Focused coverage reported
  283 expectations, 0 failures, 0 skips; expected beta-binomial convergence
  warnings remained visible.
- The five certified ordinary `mu`-slope claims agree with their retained
  artifacts and the manifest: skew-normal/Tweedie/zero-one-beta M>=16,
  binomial M>=32, and cumulative-logit M>=80 with AGHQ(25)+Cox--Reid.  No Wald
  or point-bias claim was found for those cells.  The zero-one-beta
  generator-qualified fence was not reopened.
- `python3 tools/capability_ledger.py --check` passed for 30 generated outputs;
  `Rscript tools/check-capability-runtime.R` passed for 18 routes with
  G0=G1=G2=0; `pkgdown::check_pkgdown()` found no problems.  The capability,
  cross-family, and Julia articles rendered successfully in the isolated
  review worktree.
- `devtools::test(filter = "xfam-bridge")` passed its pure-R bridge coverage;
  its four live DRM.jl round trips were correctly skipped because the required
  cross-family engines were unavailable.  The existing tests do not exercise
  the defective post-fit extractors, which is why the synthetic-object probe
  above is included in this review.

## Gate

Do not start win-builder, R-hub, the three-OS matrix, or Windows vignette timing
until both blockers have an approved fix and this review is rerun against the
new frozen candidate.

---

**Restoration note (2026-07-21, Claude session).** This file was present as an
untracked, carried-over draft at the start of the pre-CRAN review session and
was found missing later in that same session; no copy existed on `origin`. The
text above was restored verbatim from the copy read earlier in the session.
Content is unchanged; only this note was appended.
