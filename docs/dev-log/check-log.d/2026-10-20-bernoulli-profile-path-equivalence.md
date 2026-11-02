# Bernoulli ordinary-SD profile-path comparison

Date: 2026-10-20

## Commands and result

- Parsed the comparison script locally with `Rscript -e 'invisible(parse(file="docs/dev-log/general-sd-regression/evidence/calibration-20261020/profile-equivalence-v1/compare-ordinary-bernoulli-profile.R"))'`.
- Transferred the comparison script and the fixed 45-row timing manifest to Totoro over the existing ControlMaster socket. Transfer hashes matched: script `0778504e5fd71442d56e196e53df23d68c7f889e69ccafbbbeae7212006619ea`; manifest `47461e810a80c8aa7f6618497f9fe963c586f4db63f83ade4efdefccc767c1c7`.
- On Totoro (R 4.6.1; `OPENBLAS_NUM_THREADS=1`, `OMP_NUM_THREADS=1`), ran the script once against the first-look v4 library and once against the current candidate library. Each run fit and profiled manifest rows 1, 16, and 31 with `confint(..., parm = "fixef:sd(id):w", method = "profile", level = 0.95)`.
- All six fits converged, had positive-definite Hessians, and returned finite non-boundary 95% intervals with profile status and message `ok`. The three paired outputs are byte-identical; each CSV SHA-256 is `47b5bb877f029651e9579cb35af35cbbc25b565a444b8a725c4697eda3ffed6e`.
- The Python stage-two adapter suite passed 36/36. The R stage-two rules and prior-seed checks passed. The combiner subprocess test passed its expected legacy-replay rejection (`STAGE_TWO_LEGACY_REPLAY_REJECT_PASS no_fits=TRUE status=1`).

## Scope

The profile comparison uses the same three synthetic seeds as the timing pilot and therefore adds no independent recovery or calibration attempts. It supports only ordinary Bernoulli SD fit-and-profile path equivalence for these rows. It does not close G2, establish coverage, or validate all candidate source changes. Details and output hashes are in `docs/dev-log/general-sd-regression/evidence/calibration-20261020/profile-equivalence-v1/README.md`.
