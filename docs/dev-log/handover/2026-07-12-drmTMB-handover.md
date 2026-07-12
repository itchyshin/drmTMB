# Handover — distributional output & adequacy arc DONE; 0.6.0 arcs scoped (2026-07-12)

Meta: Claude → next session · repo `drmTMB` · arc branch
`feature/distributional-output-adequacy` (12 commits ahead of `main` 35db8917) ·
merge to `main` pending a clean `--as-cran` (running at handover write time).

## Mission and outcome

The **distributional output & adequacy layer** (#747 + #748) is COMPLETE and
CP4-certified. Every one of the 18 fitted families now has a verified per-family
`{d,p,q}` (`fitted_distribution()`), and both user surfaces work across all 18
(incl. `biv_gaussian` marginally):

- **#747 adequacy:** `residuals(type="quantile")`, `worm_plot()`, `qq_plot()`.
- **#748 outputs:** `predict(type="quantile")`, `exceedance()`, `centile_chart()`,
  plug-in intervals (`calibrated = FALSE`).

Version bumped `0.5.0.9001 → 0.6.0.9000`. This is the capability that fills the
gap toward the ratified **0.6.0-class "finished-for-scope" CRAN release**.

## The honest-scope finding (the intellectual core — do not lose it)

A 400-seed gated power campaign (`docs/dev-log/simulation-artifacts/2026-07-12-dg3-power-arm-gated/summary-gated-full.tsv`;
harness `inst/dg3-power-arm/`) *characterized the diagnostic's limits*:

- **Detects** distributional shape/atom mis-specs at power ≥ 0.8 (the KS+PIT
  statistic is conservative, so power is understated).
- **Structural blind spot** (parameter-verified): mis-specs a free nuisance
  parameter absorbs — heteroscedasticity → student `nu`, missing zero-inflation
  → nbinom2 `sigma`, omitted Gaussian covariate → biv `sigma` — leave the
  marginal genuinely N(0,1) and are undetectable. `hurdle`/`zoi` mechanism
  mis-specs stay flat through n=3000 (structural); `zi_poisson`/`zi_nbinom2`
  rise but stay far below 0.8 (impractical); `gamma`↔`lognormal` is the one
  cleanly sample-size-limited case (0.19→0.79→1.0).
- Everything labelled honestly: `calibrated=FALSE`, "no detectable departure"
  never "adequate", and a tested **firewall** (`test-dg-firewall.R`) — a DG tick
  never moves a model's inference tier.

## Landing state

| State | Item | Note |
| --- | --- | --- |
| LANDED (on branch) | The full arc — foundation+CP1 freeze, #747, #748, Batches A–D (18/18), gated evidence, DO-T4 docs+vignette, CP4 remediation | 12 commits; all arc + regression suites green; CRAN-lane test time ~37s |
| CP4-CERTIFIED | 3 fresh reviewers (Emmy DONE; Rose + Fisher NOT-DONE on narrow doc defects, all remediated + verified vs the tsv) | the 2-NOT-DONE gate did its job |
| MERGE-PENDING | `feature/distributional-output-adequacy` → `main` | gated on the running `--as-cran`; merge with a merge commit (preserve the 12-commit trail) |
| CARRIED-OVER, external | tweedie 400-seed power run | 99/400 done locally (atom detect 0.99; dispersion arm 66/99 non-converge). Full run needs **Totoro** → needs Shinichi MFA. Command in the artifact README. Disclosed as a limitation, not a gap. |
| CARRIED-OVER, follow-up | capability-ledger generator DG-axis | generator gate logic hardcoded to the MR axis; a real multi-file change, deferred. Hand-authored `docs/dev-log/dashboard/dist-output-adequacy-axis.md` covers it meanwhile. |
| CARRIED-OVER, follow-up | `R/missing-data.R` `1/σ²` dedup | Emmy P3 — pre-existing inline duplicates in the `mi()` subsystem, out of this arc's scope. |
| CARRIED-OVER, user-owned | the pre-existing untracked drafts/scratchpad/Ayumi files | preserve exactly; not this arc's. |

## CRAN state

- **0.5.0 fallback:** the incoming-pretest-fixed resubmission tarball
  (`scratchpad/cran-resubmit/drmTMB_0.5.0.tar.gz`, branch
  `release/0.5.0-cran-resubmit` @ `a25cc3b8`) is Windows-preflight-CLEAN and
  ready. Uwe Ligges confirmed the `NOT_CRAN` test-time fix. Frozen `v0.5.0` tag
  stays at `095409c0`. **Deprioritized** per Shinichi — capability first.
- **0.6.0-class release** is now the target (ROADMAP "First-CRAN-release
  strategy", 2026-07-12): systematic + finished-for-scope, honest limits stated.

## The next work — five candidate 0.6.0 arcs (Shinichi, 2026-07-12)

Full scoping: **`docs/dev-log/2026-07-12-0.6.0-candidate-arcs-plan.md`**. Summary
(not all must be done; some split into steps):

1. **REML** — close the Gaussian REML↔ML capability gap (structured providers,
   q2/q4); non-Gaussian REML stays guarded/POST-0.6.0.
2. **Random effects** — at least a random intercept for the 5 no-RE families +
   one slope per RE. **Recommended first — highest usability leverage.**
3. **Structured dependency** — extend phylo/relmat (then spatial/animal) to more
   families; depends on Arc 2.
4. **Intervals** — validate existing Wald/profile intervals per family, then the
   coverage campaign (Totoro, DG4/DG5). **Recommended second.**
5. **Missing predictors** — extend `mi()` beyond the current 5 families. "Last one."

Recommended sequence: 2a → 4a → 1a → 3 → (4b/5/1c post-0.6.0). Each arc reruns
this arc's discipline: interface-first → freeze → per-family batches with
DG2/DG3-style evidence → honest-scope docs → fresh adversarial CP-review
(default NOT-DONE). Heavy campaigns → Totoro/DRAC. `/ask-brain` before deriving.

## Next immediate steps

1. **Merge (one remaining mechanical step).** A full `R CMD check --as-cran` was
   started at handover and was running CLEAN through the examples stage (no
   errors/warnings observed). Once it confirms 0 errors / 0 warnings
   (`scratchpad/check-060.log`), merge preserving the 12-commit trail:
   ```sh
   git checkout main && git pull && \
     git merge --no-ff feature/distributional-output-adequacy \
       -m "Merge: distributional output & adequacy layer (#747/#748)" && \
     git push
   ```
   If the check surfaced anything, fix on the branch first — do NOT merge red.
2. Pick + sequence the 0.6.0 arcs from the scoping doc (recommend Arc 2a first).
3. When Shinichi can clear Totoro MFA: finish the tweedie 400-seed run + (later)
   the interval coverage campaign.
4. Keep the CRAN 0.5.0 fallback ready; do not move `v0.5.0`.

## One-command resume

```sh
claude "Rehydrate from docs/dev-log/handover/2026-07-12-drmTMB-handover.md, confirm the arc merged, then scope the next 0.6.0 arc from docs/dev-log/2026-07-12-0.6.0-candidate-arcs-plan.md (recommend Arc 2a random intercepts)."
```
