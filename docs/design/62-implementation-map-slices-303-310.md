# Implementation Map Slices 303-310

This note extends the implementation map into the next small planning lane. It
does not add likelihood code. The purpose is to keep future work useful for
applied users while preventing neighbouring planned syntax from looking fitted.

## Active Roles

Ada coordinates the roadmap, docs, and PR state. Pat reads the table as a new
applied user. Darwin asks whether each planned lane answers a real ecology,
evolution, or environmental-science question. Boole watches grammar and
discoverability. Fisher asks what evidence would justify simulation admission.
Gauss and Noether keep covariance dimensions and parameter meanings explicit.
Grace watches pkgdown and release hygiene. Rose records stale-claim risks and
the team learning loop.

No spawned subagents were running for this planning slice.

## Slice Table

| Slice | Lane | Status | User-facing result |
| --- | --- | --- | --- |
| 303 | Generic direct-SD design | Completed as plan | Future `sd*()` work should start with grammar and compatibility design, not by copying `sd_phylo*()` names to every structured layer. |
| 304 | p8/q8 location-scale planning | Completed as plan | Full location-scale slope covariance stays planned until endpoint labels, block size, parameterization, diagnostics, and interval policy are explicit. |
| 305 | Structured q=4 parity plan | Completed as plan | Spatial, animal, and `relmat()` q=4 parity should move one structured level at a time with `corpairs()`, diagnostics, and simulation evidence. |
| 306 | q=4 interval policy | Completed as plan | q=4 correlations remain derived-unavailable unless a direct or derived-profile method is designed, tested, and documented. |
| 307 | Inflation and hurdle random-effect gate | Completed as no-fit decision, later updated by fixed-effect zero-one beta | `zi`, `hu`, `zoi`, and `coi` stay fixed-effect-only where implemented; random effects are not a near-term implementation target. |
| 308 | Non-Gaussian structured-dependence candidate map | Completed as plan | The next non-Gaussian structured-dependence step should pick one family and one dependence layer after ordinary likelihood, diagnostics, extractor, and simulation gates are clear. |
| 309 | Implementation-map maintenance gate | Completed as process | After each substantial feature slice, update the implementation map, model-map, README, ROADMAP, NEWS, and stale-claim scans together. |
| 310 | User-route examples for the map | Completed as plan | The map now points readers toward fitted alternatives rather than planned syntax when a richer requested model is not ready. |

## Slice 307 Decision

Random effects in inflation, one-inflation, zero-one-inflation, and hurdle
parameters are not needed for the near-term public surface. They are plausible
future models, but they add a second latent process whose identifiability can
be weak even before structural dependence is introduced. The current fitted
route is fixed-effect modelling of these probability components:

```r
zi ~ predictors
hu ~ predictors
zoi ~ predictors
coi ~ predictors
```

The revisit gate for random effects in `zi`, `hu`, `zoi`, or `coi` should
require:

- a clear applied use case that fixed effects cannot answer;
- family-specific likelihood and simulation recovery evidence;
- boundary and separation diagnostics for near-zero or near-one probabilities;
- extractor and prediction semantics that distinguish conditional mean,
  zero probability, hurdle probability, and observed-response mean;
- interval-status rows that do not imply unsupported uncertainty;
- a tutorial boundary that tells users when a simpler fixed-effect model is the
  right answer.

Until then, the implementation map should call these components
fixed-effect-only where fitted, or planned where the family itself is not yet
implemented.

## Next Useful Order

The next coding work should not start by adding random effects to `zi`, `hu`,
`zoi`, or `coi`. A more useful order is:

1. Design generic direct-SD syntax across structured layers.
2. Plan the p8/q8 location-scale endpoint carefully before any likelihood work.
3. Pick one structured q=4 parity lane and close it with diagnostics and
   `corpairs()` evidence.
4. Choose the first non-Gaussian structured-dependence candidate only after the
   Gaussian and ordinary count boundaries stay stable.
5. Keep the implementation map synchronized with each completed feature slice.

This keeps `drmTMB` honest: users get a map they can trust, and planned models
remain visible without being advertised as fitted.
