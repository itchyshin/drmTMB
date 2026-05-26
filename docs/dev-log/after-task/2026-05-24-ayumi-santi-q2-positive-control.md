# After Task: Ayumi/Santi q2 Positive Control

## Goal

Move the Ayumi/Santi Objective 1 path from a runnable harness to a tested
positive control, using simulated species-level data because the real prepared
datasets are not in this repository.

## Implemented

Added `tools/ayumi-santi-q2-positive-control.R`. The script simulates a
species-level body-mass and reproductive-output dataset with a known
phylogenetic location-location correlation, known residual `rho12`, and known
phylogenetic SDs. It saves the simulated data and tree, then calls
`tools/ayumi-santi-q2-objective1-runner.R` so the positive control exercises
the same path planned for Santi's mammal and avian Objective 1 fits.

Added `docs/design/78-ayumi-santi-q2-objective1-positive-control.md` with a
compact ADEMP-style design note and a Williams et al. reporting checklist.

## Mathematical Contract

The data-generating model is:

```text
u = [u_1, u_2] ~ matrix normal(0, A, Sigma_phylo)
e_i = [e_i1, e_i2] ~ normal(0, Sigma_residual)
y_i = alpha + u_i + e_i
```

The fitted model is:

```r
bf(
  mu1 = log_body_mass ~ 1 + phylo(1 | p | species, tree = tree),
  mu2 = log_reproductive_output ~ 1 + phylo(1 | p | species, tree = tree),
  sigma1 = ~1,
  sigma2 = ~1,
  rho12 = ~1
)
```

The phylogenetic `corpairs()` row estimates the shared-ancestry
location-location correlation. `rho12()` estimates the residual complete-row
correlation. The positive control does not fit q4, class-specific covariance,
tree pooling, or missing-response marginalization.

## Files Changed

- `tools/ayumi-santi-q2-positive-control.R`
- `docs/design/76-ayumi-santi-phylo-model-improvement-path.md`
- `docs/design/77-ayumi-santi-protocol-formula-gallery.md`
- `docs/design/78-ayumi-santi-q2-objective1-positive-control.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-24-ayumi-santi-q2-positive-control.md`
- `docs/dev-log/ayumi-santi/q2-objective1/sim-positive-control/`

## Checks Run

```sh
air format tools/ayumi-santi-q2-positive-control.R tools/ayumi-santi-q2-objective1-runner.R
Rscript --vanilla -e 'invisible(parse(file = "tools/ayumi-santi-q2-positive-control.R")); invisible(parse(file = "tools/ayumi-santi-q2-objective1-runner.R")); cat("parse ok\n")'
Rscript --vanilla tools/ayumi-santi-q2-positive-control.R --help
Rscript --vanilla tools/ayumi-santi-q2-positive-control.R
Rscript -e "devtools::test(filter = 'phylo-gaussian', reporter = 'summary')"
sed -n '1,80p' docs/dev-log/ayumi-santi/q2-objective1/sim-positive-control/runner-fit/fit-summary.csv
sed -n '1,80p' docs/dev-log/ayumi-santi/q2-objective1/sim-positive-control/truth-vs-estimate.csv
sed -n '1,120p' docs/dev-log/ayumi-santi/q2-objective1/sim-positive-control/runner-fit/check-rows.csv
rg -n 'routine applied inference|full protocol.*routine|rho12.*phylogenetic|phylogenetic.*rho12|class-specific.*implemented|posterior pooling.*implemented|Monte Carlo|positive control|q2 Objective 1|q4' docs/design/76-ayumi-santi-phylo-model-improvement-path.md docs/design/77-ayumi-santi-protocol-formula-gallery.md docs/design/78-ayumi-santi-q2-objective1-positive-control.md docs/dev-log/after-task/2026-05-24-ayumi-santi-q2-positive-control.md tools/ayumi-santi-q2-positive-control.R tools/ayumi-santi-q2-objective1-runner.R
gh issue list --repo itchyshin/drmTMB --state open --search "Ayumi Santi q2 positive control" --limit 20 --json number,title,state,url,labels
gh issue list --repo itchyshin/drmTMB --state open --search "Objective 1 phylogenetic positive control" --limit 20 --json number,title,state,url,labels
git diff --check
Rscript tools/codex-checkpoint.R --goal "Ayumi/Santi q2 positive-control simulation" --next "Run Objective 1 runner with --dry-run true on prepared Santi mammal and avian data when data are available"
```

## Tests Of The Tests

The positive-control run exercises the real developer workflow:

- simulate data and tree;
- write prepared data, tree, and truth files;
- call the Objective 1 runner through its CLI;
- fit the q2 bivariate phylogenetic model;
- extract `corpairs()`, `rho12()`, `sdpars`, profile targets, and
  `check_drm()` rows;
- write truth-versus-estimate diagnostics.

The run returned convergence code 0, `pdHess = TRUE`, finite fixed-effect
standard errors, and maximum absolute gradient `5.91e-05`.

The focused `phylo-gaussian` test file passed.

The recovery checkpoint was written to
`docs/dev-log/recovery-checkpoints/2026-05-24-143015-codex-checkpoint.md`.
That directory is gitignored, so the checkpoint is a local handoff artifact
rather than a tracked package change.

## Consistency Audit

The positive-control design and script keep location, scale, and residual
coscale separate. The documentation says this is one positive-control replicate
and does not describe it as a Monte Carlo performance study. Stale-wording
scans focused on q4, residual `rho12`, class-specific covariance, posterior
pooling, and routine applied-inference claims; no new contradictory claim was
found.

No package API, formula grammar, likelihood parameterization, roxygen topic,
NEWS entry, or pkgdown navigation changed.

## GitHub Issue Maintenance

Issue searches for `"Ayumi Santi q2 positive control"` and
`"Objective 1 phylogenetic positive control"` returned no exact open issue. No
issue was opened or mutated. This is a local validation artifact on a mixed
dirty branch, and it does not yet need an issue separate from the broader
Ayumi/Santi phylogenetic validation path.

## What Did Not Go Smoothly

An initial weaker positive-control cell converged but underestimated one
phylogenetic SD. That was useful feedback: the smoke should first be a
strong-signal runner check, not a weak one-row-per-species identifiability
stress test. The final default uses 220 species, stronger phylogenetic SDs, and
lower residual SDs so the harness check is interpretable.

## Team Learning

For one-row-per-species protocol data, `check_drm()` notes about species
replication should not be hidden. They are expected for the protocol shape, but
they remind Ayumi and Santi that phylogenetic SDs and correlations need tree
sensitivity, profiles or bootstrap, and careful interpretation.

## Known Limitations

This is not a real data fit and not a replicated simulation grid. It has no
Monte Carlo standard errors, no tree uncertainty loop, no profile intervals,
and no q4 validation. The output supports the runner path, not a biological
claim.

## Next Actions

Use this positive control as the smoke before real prepared data. Then run the
Objective 1 runner with `--dry-run true` on Santi's mammal and avian datasets,
followed by one representative-tree fit if the preflight tables are clean.
