# After-task: certification + q4 reframe — the three "walls" were all small-sample

Meta: 2026-06-27 · Claude (ultracode) · the capstone of the local-coverage arc.
Verified by Fisher, Curie, Gauss. This is the result that reframes the q-series
completion picture.

## The arc

A team strategy panel named the g-sweep the highest-leverage experiment. Running
it locally (drmTMB compiles on this Mac; coverage was never cluster-bound)
produced three findings that converge on one conclusion: **the q-series slope/
location "walls" were small-sample limitations, not method or engine walls.**

## Finding 1 — sigma + q2 reach certified-nominal coverage (profile) at g=32

Certification grid (g=32, 500 reps, MCSE ~0.010; `cert-{sigma,q2}-g32`):

| lane / target | Wald | profile |
|---|---|---|
| sigma phylo sigma:(Int) | 0.940 | **0.948** |
| sigma phylo sigma:x | 0.964 | **0.954** |
| sigma relmat sigma:(Int) | 0.938 | **0.948** |
| sigma relmat sigma:x | — | **0.958** |
| q2 phylo mu1:x | 0.934 | **0.948** |
| q2 phylo mu2:x | 0.946 | **0.956** |
| q2 relmat mu1:x | 0.940 | **0.950** |
| q2 relmat mu2:x | 0.946 | **0.952** |

All 8 **profile** cells are at nominal (0.948–0.958, MCSE ~0.01). Banked in
`structured-re-slope-coverage-certification.tsv`.

## Finding 2 — q2 under-coverage is a Wald problem; the PROFILE channel is the fix (Fisher)

The under-coverage is ML SD-shrinkage making the **Wald** interval too narrow; the
**profile** interval self-corrects the same miss. REML would also fix it but is
engine-blocked this cycle (`drm_validate_reml_spec_biv` aborts on structured RE;
exact-Gaussian biv restricted-likelihood is a separate derivation slice). At the
deployment g=8, profile is a documented near-miss ~0.91 (vs Wald ~0.88); at g=32
it is nominal. **A "supported for g≥N" claim is design-inappropriate** (cells are
g-agnostic) — the honest q2 outcome is "profile is the supportable channel,
near-nominal, fully nominal with adequate groups."

## Finding 3 — q4-location pdHess fragility is also small-sample, NOT an engine wall (Gauss)

pdHess-failure rate vs g (q4-location, `q4-location-gsweep`):

| provider | g=8 | g=16 | g=32 |
|---|---|---|---|
| phylo | 48.6% | 30% | **5.0%** |
| relmat | 22.9% | 8.3% | **0.0%** |

Censoring (finite-fraction) climbs to 0.95–1.00 by g=32; coverage converges to
nominal as it lifts. The inner objective always converges (convergence==0); only
the **outer** joint-Hessian inversion fails at small g, and it evaporates with
replication. **`reparam_still_needed = false`** — g fixes q4-location. Gauss
designed a log-Cholesky RE-covariance reparam (PD-by-construction, no explicit
inverse) as an *optional* hardening for the deployment-g censored zone + the
full-4×4 derived-correlation path; it needs an A/B test (recompile + tests, no
likelihood change) and is filed as an optimization, not a blocker.
**Caveat:** this is q4-*location*; the all-four/scale-side q4 additionally hits
the sigma-SD lower-bound geometry, which g alone may not fix — do not extend the
"g fixes it" claim there without its own sweep.

## What this means for "finishing the q-series"

The honest completion picture is transformed — not because cells reached
`supported` (none did), but because the **character of the remaining work
changed**:

- **q2, q4-location: surmountable small-sample**, near-nominal at adequate g,
  with a supportable channel (profile). Documented at a HIGH ceiling, not a
  negative.
- **sigma: g-robust near-nominal.** count: converges (recovery).
- **Genuine remaining gates:** (a) the **interval-reliability rung** (width/
  symmetry calibration) is still unmeasured and is required before `supported`;
  (b) a **design decision** on whether/how near-nominal-at-deployment-g maps to a
  cell promotion; (c) **scale-side q4** sigma-SD lower-bound (separate mechanism);
  (d) **relmat-Q bridge** (upstream DRM.jl).

## Boundary / what was NOT promoted

Every result is DIAGNOSTIC + certification-at-g=32. NO cell's `coverage_status`
moved off `planned`; `interval_status` is untouched (coverage ≠ supported);
nothing reached `supported`. The g-agnostic cells are not promoted by a g=32
certification. No DRM.jl, no engine change shipped, no PR merge implied here.

## Checks

- All grids ran on drmTMB 0.1.4 locally. `python3 tools/validate-mission-control.py`:
  `mission_control_ok`, 8 certification rows + 18 g-sweep rows.
- Fisher + Curie verified the g-sweep and reproduced every figure from raw
  `wald_contains`; Gauss ran the q4-location g-sweep and read `src/drmTMB.cpp` for
  the reparam design.

## Team learning

Three independent "walls" — q2 interval under-coverage, q4 pdHess censoring, and
(earlier) the cluster-only coverage assumption — all turned out to be the same
thing: small-sample artifacts that vanish with more groups/replication or the
right interval channel. The highest-leverage move was never more engineering; it
was **one env-hook (`GSWEEP_N_GROUPS`) and a fan-out that measured the walls** —
and the verification panel kept every finding honest (no over-promotion, coverage
≠ interval reliability, certify-at-g≠promote-the-cell). Measuring the walls showed
they aren't walls.
