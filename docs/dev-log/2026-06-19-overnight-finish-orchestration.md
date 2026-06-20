# Overnight Finish-Plan Orchestration (Ada, 2026-06-19)

**Workspace:** `/Users/z3437171/.codex/worktrees/540b/drmTMB`, branch
`shannon/overnight-audit-gaps-20260619` off `bd1f3e46` (clean `origin/main`,
PR #636 merged).

**Posture:** autonomous overnight run while the maintainer is away. Local work +
local commits per slice. **Pushes/PRs/merges are HELD for morning review.** Every
slice follows the project Definition of Done (impl + tests + docs + check-log +
after-task + review) and the critical claim boundaries below.

## Canonical-tree resolution

The Wave 0 audit raised a "which tree is canonical?" alarm. It is a false alarm:
the synthesis agent's shell defaulted to the stale primary checkout
`/Users/z3437171/Dropbox/Github Local/drmTMB` (`b4a4d7be`, 159 commits behind,
dirty), while the mappers correctly audited `540b`. **`540b` (`bd1f3e46`) is
canonical** — it is the handover-designated workspace, clean at `origin/main`,
and has the full tooling (`tools/validate-mission-control.py`, design docs 176,
the 2026-06-17 pilots). Operational lesson carried into execution: **pin every
command and edit to absolute `540b` paths; never trust the default cwd, and
re-grep every line reference before editing** (the audit's cited cpp lines were
wrong for this tree).

## Wave 0 audit result

10 parallel mappers → 141 items; Rose adversarially verified 78 "closable-now &
boundary-safe" candidates → **18 wave-1 (docs/widget), 4 wave-2 (native code),
2 wave-3 (article/figure); 63 blocked** (design gates, method repair, evidence,
owner decisions, research-scoped). Full transcript:
`tasks/wugir0822` workflow run `wf_9d127051-22e`.

## Critical claim boundaries (Rose holds these)

- No bridge-row promotion from #636; no plain non-phylo binomial Julia bridge
  claim; no q4/q8 bridge parity claim.
- No release / CRAN readiness claim; no recovery/coverage/power claim unless a
  simulation directly measures it.
- No selectable Julia-side `engine_control` claim; REML/AI-REML wording stays
  Gaussian-only.
- Keep missing-data and complete-case boundaries separate.
- Keep native R/TMB, direct DRM.jl, and Julia-via-R evidence in separate lanes.
- Do not mark the long-running Big 4 goal complete. A numerical guard must not
  upgrade convergence/inference claims without sensitivity evidence.

## Execution sequence

### Wave 1 — docs / claims / widget (serialized on shared files)

Real edits:
1. `p5-gpu-backend-planned` — add an **accelerator-only** lint (GPU/CUDA/TPU/
   accelerator/compute-target/offload; NOT the overloaded token "backend") to
   `tools/validate-mission-control.py`; add a GPU/backend Claim-Guards bullet to
   design 168 (no new matrix row — the 17-row count is an invariant).
2. `high-7-getting-started-inconsistency` — one house-style note in
   `vignettes/drmTMB.Rmd` (`drm_formula()` primary, `bf()` exact alias).
3. `high-9-coef-drmtmb-bare-export` — roxygen for `coef.drmTMB` (R/methods.R:1841)
   via `@rdname model-fit-extractors`; add `drmTMB()` `@return` list slots.
4. `drift-readme-version` — README version token `0.1.3`→`0.1.4` (lines 53/60/65)
   only; preserve all pre-CRAN wording verbatim.

Verify-only (no edits; produce a verify ledger, escalate any contradiction):
`verify-q8-diagnostic-bound`, `verify-q4-phylo-derived-bound`,
`verify-recovery-diagnostic-qualification`, `verify-reml-gaussian-only`,
`verify-no-release-claims`, `verify-no-engine-control-public`,
`verify-missing-data-boundary`, `phase6-missing-response-vs-predictor-separation`,
`p7-figure-which-dont-imply-coverage`, `p9-logsigma-clamp-sensitivity-pilot-audit`,
`widget-validator-health`, `widget-served-copy-current`,
`widget-metrics-synchronized`, `widget-activity-rows-current`.

### Wave 2 — native R/TMB (SERIALIZE on the shared build; TDD per slice)

5. `high-2-silent-nan-inf-covariance` — stable factorization for
   `.inverse()`+`log(.determinant())` at `src/drmTMB.cpp:273-274, 318-319,
   3340-3341`; native boundary test for finite NLL/logdet near singular q>2.
6. `high-3-dense-v-indefinite` — close residual gap around the known-V MVNORM
   Cholesky at `src/drmTMB.cpp:1975, 3417` (R-side `validate_known_v_matrix()`
   rejection already exists); guard a non-PD `Omega` factorization.
7. `high-4-pdhess-false-does-not-block-se` — in `drm_compute_uncertainty`
   (R/drmTMB.R): when `sdreport()` succeeds but `pdHess=FALSE`, return status
   `non_pd_hessian` (not `ok`) + a classed warning; teach `print.drmTMB`,
   `check_drm`. **Watch the `*.drmTMB_julia` readers of this status (parity
   lane).**
8. `high-6-link-definitions-triplicated` — single `drm_link_registry()` keyed by
   all 18 `model_type`s; refactor `drm_dpar_link()`; assert `family.R` `links=`.

### Wave 3 — article / figure

9. `high-11-axis-labels-inverted` — swap `vignettes/figure-gallery.Rmd` bias-panel
   `labs()` (x="Estimate minus truth", y=NULL).
10. `p7-gaussian-baseline-article` — eval-on-build native Gaussian location-scale
    walkthrough; **authored-but-HELD for Florence/Darwin/Fisher review** (cannot
    reach "done" overnight).

### Integration

`devtools::document()` → `devtools::test()` →
`devtools::check(error_on="never")` → `pkgdown::check_pkgdown()` →
`tools/validate-mission-control.py` → `git diff --check`; update check-log,
after-task reports, widget activity/evidence; morning report.

## Morning shortlist (needs Shinichi / needs design gate)

**Needs Shinichi:** triage the stale dirty primary checkout (`b4a4d7be`,
untracked `R/julia-bridge.R` 1102 LOC shipped in 0.2.0 — release-scope call);
worktree sprawl (~30 worktrees) prune; schedule Florence/Darwin/Fisher article
review; Rose release sign-off + CRAN decision (owner-only).

**Needs a design gate (no code first):** Tier-B multi-slope & slope-correlation;
Tier-D random effects in `rho12`; structured residual-`sigma` slopes;
non-Gaussian labelled covariance (`count_labelled_q2_q4`); Phase-3 per-cell
parity schema before any promotion or parity plot; Phase-5 AI-REML / gradient /
benchmark-route gates.

**Blocked on evidence (report status, do not auto-run):** q8 coverage/power;
same-response q2 slope; skew-normal formal operating characteristics. The
recurring fixed-gradient/optimizer theme across Big-4 blocks 1–4 points to a
**shared optimizer/start method audit** (Gauss + Curie) as the higher-leverage
next investigation than per-block fixes.
