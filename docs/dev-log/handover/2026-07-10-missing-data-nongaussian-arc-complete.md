# Handover — drmTMB, 2026-07-10 → next Claude / Shinichi

Meta: from Claude (Opus 4.8) · repo `drmTMB` · branch
`drmtmb/missing-data-nongaussian` (20 commits ahead of `main`, **not merged, not
pushed**). This closes the **missing-data non-Gaussian arc (P0–P5)**. Everything
below is committed **LOCAL** on the branch; nothing is pushed.

**The arc is complete.** Missing-data handling now works for non-Gaussian
responses in both modes — FIML response masking and missing-predictor `mi()` —
with a validated capability matrix, an anti-drift gate, and a full-suite green
run. Awaiting your review + release cut.

---

## What landed (this session: beta-P3, P4b, P5)

| Slice | Commit | What |
|---|---|---|
| P3 beta | `39bc62ad` | Missing-predictor `mi()` for a `beta()` response (model_type 10): binary predictor 2-point sum, `phi = exp(-2*log_sigma)`. Completes P3 (poisson/binomial/nbinom2/beta all done). |
| P4b | `e2afdd6c` | Capability matrix + honest prose in `vignette("missing-data")`; missing-data arc section in `NEWS.md`. |
| P5 | (this commit) | Full-suite close-out: caught + fixed **27 pre-existing arc regressions** (green on `main`, red on the branch); after-task report + this handoff. |

### P5 caught what the `missing` filter had been hiding

The full `test_dir` run surfaced 27 failures the arc had carried undetected
(prior slices verified against `filter="missing"`, not the whole suite). All were
arc-introduced (green on `main`), diagnosed to root cause, and fixed:

- **beta/nbinom2/binomial** builders were missing the `if (length(y) == 0L)`
  "No complete observations remain…" guard that poisson/Gaussian have (P1 added
  `observed_y` but not the guard) → all-`NA` complete-case aborted with the wrong
  message. Added the guard to all three (binomial had the latent bug too).
- **estimator-surface-conformance.tsv**: 6 REML-gate `evidence` line citations
  drifted out of window from the arc's cumulative line additions → recomputed and
  updated.
- **Q-Series claim guard**: the 0.5.0-retarget NEWS preamble said "Q-Series
  v1.0 … complete-capability", tripping the crude `Q-Series.*complete` regex on
  what is a *disclaimer* → reworded to "reserved for the later maturity milestone".

Prior-session arc slices already on the branch: P0 gate (`167b263d`,
`06970804`), P1 response masking (`e91a88d9`/`d9062af6`/`f332ab4b`/`7cd1e60a`/
`e62b3051`), P2 leaf extraction (`394772dc`), P3 poisson/binomial/nbinom2
(`7f7c6049`/`766a912b`/`9e371c1a`), P4a guardrails + SSOT (`0d6460f0`,
`ddf42386`).

## State of the code

- **Capability now (both modes validated per family, SSOT + anti-drift gate):**
  - Response masking (`miss_control(response = "include")`): gaussian,
    biv-gaussian, binomial, poisson, nbinom2, beta.
  - Predictor `mi()` (`miss_control(predictor = "model")` + `impute`): gaussian
    (broad predictor catalogue), poisson, binomial, nbinom2, beta (one **binary**
    predictor each for the non-Gaussian responses).
- **Byte-identity**: every non-Gaussian slice confines its kernel change to one
  `model_type` block; guards degenerate to the original when the feature is off,
  so other families are literally unchanged. `git diff` re-verifies this cheaply.

## Checks (green)

- Missing-data suite (`filter="missing"`): **626 pass / 0 fail** (2 pre-existing
  beta-binomial optimizer warnings, 2 Julia skips — both unrelated).
- Full `test_dir`: **36439 pass / 0 fail** (12 pre-existing optimizer warnings, 98 CRAN/Julia skips).
- beta-P3 recovery (n=4000): `mu` 0.43/0.48/0.67 (truth 0.4/0.5/0.7), `sigma`
  −1.05 (truth −1.04), `mi_x` 0.32/0.78 (truth 0.3/0.8).

## Next by leverage (your calls — maintainer-gated)

1. **Release cut to 0.5.0.** NEWS documents the arc under the 0.4.0 dev line. To
   cut the release: rename the NEWS heading to `# drmTMB 0.5.0`, bump
   `DESCRIPTION` `Version: 0.5.0`, then push / open PR / merge / tag. I did **not**
   do any of these (all maintainer-gated).
2. **`R CMD check --as-cran`** before the cut (I ran the full `test_dir` suite,
   not `--as-cran`; the previous arc left it at 0E/0W/0N).
3. **Optional depth** (post-0.5.0): non-binary missing predictors on non-Gaussian
   responses; `mi()` with RE/structured/zero-inflated response terms; the broad
   predictor catalogue on non-Gaussian responses.

## Gotchas / notes for the resume

- **Beta `mi()` block placement is deliberate**: it sits *before*
  `mu = plogis(eta)` in `model_type == 10` because the beta density loop reads a
  precomputed `mu` vector (nbinom2 recomputes `mu` from `eta` in-loop, so its mi
  block sits after). Moving it would silently drop the observed-x correction; the
  FIML identity test is the guard.
- **Two stale tests were fixed this session** (both flagged in the P3 handoff as
  traps): the predictor-axis drift regexp (keyed on decorated `` `mi()` `` text
  that had rotted) → repointed to `"models are currently validated only"`; the
  non-validated impute-reject loop (listed now-validated families) → repointed to
  gamma/tweedie/lognormal.
- **GAMLSS #747/#748** (per-family `{d,p,q}` object) is a separate workstream; its
  scout note `d3e4fa3b` happens to sit on this branch but is not part of the arc.

## How to resume

```bash
cd "/Users/z3437171/Dropbox/Github Local/drmTMB"
git checkout drmtmb/missing-data-nongaussian
git log --oneline main..HEAD          # the arc
# read the close-out:
#   docs/dev-log/after-task/2026-07-10-missing-data-nongaussian-p3-p5.md
# run the WHOLE suite (not filter="missing") — the P5 lesson:
Rscript -e 'devtools::load_all("."); testthat::test_dir("tests/testthat")'
```
