# After Task: Coupled-q4 penalty recovery sim (Phase 5)

## Goal

Answer the only question that mattered for the user once the penalized/MAP
estimator (#581) existed: **does the correlation penalty actually rescue the
coupled-q4 "Model E", is the rescued estimate data-informed or prior-dominated,
and what data would identify the full model cleanly?** Evidence behind the full
reply to the Ayumi thread.

## What was run

- `inst/sim/run/phylo_penalty_q4_recovery.R` (new): simulates a coupled-q4 model
  with KNOWN truth on a fixed coalescent tree (`ape::rcoal`, phylo correlation
  from `vcv.phylo`), draws the 4-axis latent field as `MVN(0, C (x) R_phylo)`,
  generates bivariate Gaussian responses, and fits Model E penalize-off vs
  penalize-on across a `cor_sd` grid at 1 and 3 observations per tip.
- A real-data companion (Model E on the 10,440-tip data, penalize-off vs
  penalize-on) recorded in the check-log; the `cor_sd = 1.0` real-data
  confirmation is a separate background run.

## Findings (see doc 173 for the tables)

1. **The penalty rescues the coupled model to a positive-definite fit.** At one
   obs/tip, penalize-off pins all six correlations at +/-1 (`pdHess = FALSE`);
   every `cor_sd` gives a clean, off-boundary, PD fit on the controlled n=300
   case.
2. **At one obs/tip the magnitudes are prior-sensitive.** Sweet spot at
   `cor_sd=0.5` recovers the strong true 0.60 (0.54) and 0.30 (0.26); stronger
   priors over-shrink; weak correlations collapse to ~0. The penalty makes Model
   E fittable and recovers strong couplings, but a prior-sensitivity sweep is
   mandatory and only strong/stable couplings are trustworthy.
3. **Replication is the clean fix.** At three obs/tip, plain ML already reaches
   `pdHess = TRUE` off the boundary; penalty + replication recovers all six
   correlations well. ~2-3 records/species identifies the full model from the
   data itself.
4. **Real-data note:** on the full 10,440-tip surface the penalty (`cor_sd=0.5`)
   converges with a sane gradient but did not reach a fully PD Hessian; the
   `cor_sd=1.0` confirmation is pending. The honest real-data recommendation is
   the penalized exploration plus replication, not a guaranteed clean PD fit at
   10k tips / 1 obs per species.

## Honesty contract

The penalty regularises a weakly-identified direction; a rescued Model E is a
MAP estimate, prior-sensitive, reported with the sweep, never as plain ML. A
successful rescue means "the coupled model returns a finite, PD,
sensitivity-checkable estimate," not "the data identify the correlation." The
data-vs-prior distinction is exactly what the sweep and the replication arm
quantify.

## Files Changed

- `inst/sim/run/phylo_penalty_q4_recovery.R` (new) -- the recovery sim runner.
- `docs/design/173-phylo-penalty-model-e-rescue.md` (results filled in).
- `docs/dev-log/after-task/2026-06-16-phylo-penalty-recovery-sim.md` -- this note.
- `docs/dev-log/check-log.md`.

No package `R/` / `src/` code changed; this is an evidence/sim slice on top of
the merged penalized/MAP estimator (#581).

## Team Perspective

Curie owns the DGP and the recovery design; Fisher holds the data-vs-prior
reading (sweet spot, prior-domination of weak couplings, the replication
threshold); Noether checks that the simulated truth and the recovered
parameterisation line up; Rose keeps the "fittable != identified" language
honest; Darwin frames the replication recommendation for the user. Ada gates.
The DGP bug (formula `tree` captured at top level before the trees existed) was
caught at the n=100 validation checkpoint and fixed by building `bf()` inside
the fitting helper.
