# DRAFT — reply to LS_ecogeographical-rules #28 (Ayumi's Julia validation report)

> STATUS: DRAFT ONLY. Not posted. Posting requires Shinichi's explicit approval and a fresh
> forbidden-claim scan (docs/design/205-ayumi-reply-readiness-gate.md) immediately before.
> Evidence links reference branch/PR state as of 2026-09-01; re-verify merge state before posting.

---

@Ayumi-495 — thank you, this is an exemplary validation report, and your seven limitations were
exactly the right list: they became our work queue. Point by point, here is what has changed since
you ran it, and what genuinely remains open.

**Your validation itself.** We can now reproduce your validation subset exactly: the 343-tip set is
deterministic (the intersection of the full tree's tips with species having non-missing lightness,
in `R/51_batch_clade_revised_spec.R`), so our checks below run on your fixture, not a stand-in.
Your headline reading — close agreement at N=343 for point estimates, profile bounds, and matched
bootstrap where both engines run — matches our own retained evidence, and we found nothing wrong
with how you conducted it.

**Your limitations, one by one:**

1. *Strictly binary phylogeny required.* Improved: DRM.jl now accepts non-binary (polytomy) trees
   subject to a validation contract (rooted, ultrametric, positive finite branch lengths), and a
   synthetic non-binary ultrametric q4 fit through `engine = "julia"` succeeds. Your
   `multi2di + epsilon` workaround should no longer be needed for trees meeting that contract —
   though we have verified synthetic cases, not yet your canonical production tree, so we would not
   yet call your case closed.

2. *Non-interactive sessions abort (your #29).* Fixed on the current branch: ordinary `Rscript`
   sessions are allowed unless a real R-CMD-check marker is present; an unopted non-interactive
   q4 script now runs, and today's validation runs were themselves unopted `Rscript`. Details in
   the #29 reply.

3. *Tip labels with spaces.* Fixed: a fixture with spaces in tip labels now round-trips the bridge.

4. *Coefficient-name translation.* Improved: explicit bivariate parameter syntax such as
   `sigma1 = sigma1 ~ ...` no longer mis-reads parameter labels as data columns (regression-tested,
   drmTMB #1112). Transformed-term naming through the bridge is still being tightened.

5. *Optimizer/control symmetry.* Partly by design: generic `optimizer$g_tol` now maps to the real
   Julia q4 tolerance, and the non-equivalent `algorithm` setting is rejected with a clear message
   (drmTMB #1112). But TMB's `robust` preset is an nlminb-ladder policy with deliberately no Julia
   equivalent — so a fully symmetric control contract is not the goal; a clearly *matched default*
   baseline is, and that is what our cross-engine comparisons now use.

6. *Julia gradient not exposed.* Improved: `fit$bridge$diagnostic` now carries route-aware
   convergence diagnostics (DRM.jl #573). Honest caveat: its scale is not directly comparable to
   TMB's raw gradient, so same-basis convergence comparison remains an open item rather than a
   solved one.

7. *Whole-tree profile CI impractical (2 h+ terminated).* Open, and we agree with your framing —
   a computational-feasibility limitation, not an inferential failure. Two notes: q4 profile calls
   currently run only when all q4 SD targets are requested together (`profile_targets(fit)$parm`),
   and deep raw trees now get depth-scaled initial values (DRM.jl #573), which removes one source
   of pathological starts. Whole-tree profile scaling is on the programme explicitly; we will not
   claim it solved until it is measured.

**On scaling the bootstrap beyond R=20:** worth doing eventually, but we'd hold for now — for an
honest reason. Our matched-baseline comparison on a synthetic bivariate q4 REML fixture found the
Julia solver landing at a slightly inferior optimum than TMB on that cell (|Δ logLik| ≈ 1.6e-2,
insensitive to tolerance; tracked as DRM.jl #575). That cell is a harder configuration than your
M6q family-scale fits — where your own receipts show 1e-6-level agreement — but until #575 is
understood we would rather not have you spend bootstrap compute through the bridge. The bootstrap
repair that discards nonconverged refits rather than folding them into percentile endpoints
(DRM.jl #573) also changes what a large-R run would mean. We'll say when it's worth your compute.

**Your interpretation stands.** TMB as the production engine for the whole-tree M6q analysis, with
Julia as strong independent validation where feasible, is exactly the right current reading — and
matches our own capability ledger, where the Julia bridge routes remain explicitly experimental.

---

## Evidence links to attach before posting (verify merge state first)
- drmTMB PR #1112 (alias repair + g_tol mapping + algorithm rejection; 125-test bridge suite green)
- DRM.jl PR #573 (route-aware bridge diagnostics; depth-scaled inits; bootstrap nonconverged-refit discard)
- Retained matched-control fixture receipts (v1 + v2 logs, 2026-09-01)
- Polytomy validation-contract evidence (docs/dev-log/evidence/julia-r-parity/polytomy/)
