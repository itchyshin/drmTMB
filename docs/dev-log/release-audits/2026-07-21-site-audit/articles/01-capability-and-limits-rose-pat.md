# Rose + Pat audit: capability-and-limits article

**Reader audited:** an applied ecology/evolution graduate student deciding
whether a reported effect and interval are defensible.
**Scope:** `vignettes/capability-and-limits.Rmd`, its pkgdown placement, and the
release-facing cross-check requested for `README.md`, `NEWS.md`, `ROADMAP.md`,
`_pkgdown.yml`, and the 0.6.0 release-scope manifest. No source files were
edited and no rendering, package check, remote access, or compute was run.

## Verdict

**NOT READY as a trustworthy capability page.** The menu placement is sensible:
the article appears under **Diagnostics & Limits > Honest Limitations** in
`_pkgdown.yml:84-98` and `:251-259`, while `README.md:41-45` and `:113-120`
link readers to it at the decision point. But four P1 claim conflicts make the
page unsafe to use as the promised release-scope guide. All identified repairs
are documentation-only and do not change the package API, likelihood, or
evidence ledger.

Counts: **P1 4 · P2 3 · P3 1**.

## P1 — misleading or false public claim

1. **The page says a regression `rho12 ~ x` has no interval, although the
   corrected manifest says `newdata_required` means to supply `newdata`, then
   profile or Wald intervals are returned.**

   - Article: `vignettes/capability-and-limits.Rmd:367-374` tells the reader
     that supplied `newdata` does not change `NA` bounds and recommends
     refitting `rho12 ~ 1`.
   - Authority/correction: the release-scope manifest `:173-185` and `:224-231`
     records a fitted-model verification that both profile and Wald intervals
     are finite after supplying `newdata`; the active 0.6 plan `:56-58` calls
     the earlier interpretation a false positive.
   - Reader harm: a user is directed to fit a scientifically different constant
     correlation model instead of obtaining a row-specific interval.
   - Minimal repair: replace the subsection with the corrected action:
     `conf.status = "newdata_required"` asks for a biologically meaningful
     row; use `confint(fit, parm = "rho12", newdata = grid, method =
     "profile")` or `predict_parameters(..., dpar = "rho12", conf.int = TRUE)`.
     State that these regression intervals are **not coverage-certified** and
     retain constant `rho12 ~ 1` as the only certified reporting target.

2. **The article omits the promoted Gamma `sigma` ordinary-random-intercept
   interval cell (`mc-0242`).**

   - Article: the at-a-glance census `:66-85`, Tier 1 inventory `:92-191`, and
     ordinary non-Gaussian interval subsection `:231-266` list five `mu`
     slope cells but never give the Gamma `sigma` intercept route, its profile
     method, or its `M >= 32` reporting floor.
   - Authority: the release-scope manifest `:76-90` adds `mc-0242` explicitly;
     the generated family map already labels it
     `inference_ready_with_caveats` in
     `vignettes/includes/capability-ledger-family-map.md:7`.
   - Reader harm: a user with exactly this fitted Gamma model is told neither
     that an interval is evidence-backed nor its boundary (`M=16` is not the
     reporting floor).
   - Minimal repair: add one at-a-glance row and a short Tier 1 paragraph:
     Gamma `sigma ~ (1 | id)`, ML-Laplace profile for the natural-scale SD,
     certified at `M >= 32` with `n_each = 12`; no Wald or point-bias claim.

3. **The page overstates which ordinary bivariate-Gaussian random effects have
   the ledger's `supported` fit status.**

   - Article: `:68` says ordinary Gaussian/bivariate-Gaussian random effects
     include “intercepts, slopes”; `:195-204` again calls the bivariate
     `mu1`/`mu2` counterpart point-trustworthy.
   - Authority: the manifest `:45-56` lists exactly four `supported` cells:
     two bivariate **intercepts** (`mc-0069`, `mc-0070`), a univariate Gaussian
     intercept, and one univariate Gaussian independent slope. The generated
     map independently lists only the two bivariate intercept cells
     (`vignettes/includes/capability-ledger-family-map.md:4`).
   - Reader harm: the wording permits a reader to infer a bivariate slope has
     the highest point-estimate maturity when it does not.
   - Minimal repair: name the four cells or say “Gaussian univariate intercept
     and independent slope; bivariate-Gaussian `mu1`/`mu2` intercepts only.”
     Keep every bivariate slope outside this `supported` statement.

4. **The release posture is stale across the surfaces that route a reader to
   this article.**

   - `README.md:32-36` says 0.6.0 is being prepared for first CRAN submission;
     `README.md:57-58` says it will be tagged when it reaches CRAN.
     `NEWS.md:363-366` calls 0.6.0 the actual first CRAN submission.
   - Current decision: `docs/dev-log/2026-07-21-0.6-dev-arc-ultra-plan.md:9-10,
     :23-24, :80-87` says no 0.6 CRAN submission: the release gate and its
     later rungs are parked while the development arc continues.
   - The 2026-07-20 manifest still frames 0.6 as a release candidate
     (`:21-31`), so it needs an explicit dated supersession note rather than
     being silently treated as current release planning.
   - Minimal repair: change public copy to “0.6.0 development line; no CRAN
     submission is currently planned,” remove the promised tag-on-CRAN wording,
     and add a dated supersession note near the manifest heading. Keep the
     historical v0.5.0/CRAN facts as history, clearly labelled.

## P2 — important reader friction or taxonomy drift

1. **“Four tiers” is not the scheme used by the article's own table.**

   - Definitions `vignettes/capability-and-limits.Rmd:31-62` name four tiers,
     but table `:66-85` adds “Point-trustworthy (census `supported`, coverage
     planned)” and “Inference-ready with caveats.” Section `:193-204` then
     discusses point-trustworthy cells inside Tier 1 despite saying they do not
     meet Tier 1's coverage bar.
   - Minimal repair: introduce `supported`/point-trustworthy as a separate
     **fit-maturity label**, not a fifth interval-evidence tier; state that
     `inference_ready_with_caveats` is the ledger spelling of reader-facing
     inference-ready. Then give a one-line mapping from ledger statuses to the
     four reader categories.

2. **Tier 4's definition contradicts its own “higher-order covariance” row.**

   - Definition `:49-53` says Tier 4 means the package refuses to fit the
     request. But `:85` and `:352-358` say q4/q6/q8/q12 interval promotion is
     unavailable while a fitted point estimate and sometimes
     `profile_targets()` remain usable.
   - Minimal repair: split “rejected syntax” from “fitted but not
     inference-certified” (or route the latter to recovery-/diagnostic-only
     with its precise evidence boundary). Do not imply a valid fitted model was
     rejected.

3. **The generated missing-response table and the active development plan have
   no explicit synchronization receipt.**

   - The article `:410-430` and generated include
     `vignettes/includes/capability-ledger-missing-response.md:3-22` publicly
     present all 18 response routes as verified G3.
   - Yet the current plan `docs/dev-log/2026-07-21-0.6-dev-arc-ultra-plan.md:74,
     :86, :99-104` calls the slice “WIRED + TESTED but unclaimed” and schedules
     A3 to surface it by regenerating `cells.tsv` and the includes.
   - This may be a plan-state lag rather than a false capability claim, but the
     two sources leave no reader or maintainer receipt showing which status is
     authoritative.
   - Minimal repair: before changing the prose, reconcile A3 against the ledger
     and record one source-of-truth line in the plan/after-task note. Regenerate
     includes; never hand-edit them. If G3 is the final evidenced tier, say so
     consistently; otherwise demote the public wording.

## P3 — polish and actionability

1. **The exhaustive evidence destination is named but not linked.**

   - `vignettes/capability-and-limits.Rmd:498-506` sends a reader to a relative
     repository path without a clickable public URL or a direct pointer to the
     ledger README. The target does exist
     (`docs/dev-log/dashboard/capability-census/`), but this is awkward in a
     rendered pkgdown article.
   - Minimal repair: link to the GitHub capability-census directory (and, if it
     is the authority for row status, the ledger README) and say which answers
     “what fits” versus “what has evidence.”

## Minimal repair order and safeguards

1. Correct the `rho12 ~ x` action path everywhere before any pkgdown rebuild;
   the manifest itself says the prior error reached four public pages
   (`:178-185`).
2. Reconcile the four `supported` cells and add Gamma `mc-0242` from the
   ledger/manifest, not from prose memory.
3. Repair the tier taxonomy and Tier-4 wording, then regenerate the
   missing-data includes after A3's ledger decision.
4. Update the CRAN posture in README/NEWS/ROADMAP/pkgdown-adjacent copy and add
   a dated supersession note to the 2026-07-20 manifest.
5. Render this vignette and run the capability-ledger checks before claiming
   the public surfaces are aligned; verify the rendered article link and the
   `rho12` example on a toy fit.

**Docs-only repair safe?** **Yes**, for the P1/P2/P3 prose, navigation, and
generated-include synchronization work. The one conditional is missing-data:
confirm its exact ledger tier before editing derived content. No likelihood,
API, simulation, or remote-compute work is authorized or required by this
audit.
