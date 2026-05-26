# After Task: Ayumi/Santi q2 Objective 1 Runner

## Goal

Give Ayumi and Santi a concrete next step after the protocol formula gallery:
a developer-only runner that fits the Objective 1 bivariate phylogenetic
location model from prepared data and a tree.

## Implemented

Added `tools/ayumi-santi-q2-objective1-runner.R`. The script accepts CSV or
RDS data, an RDS/Nexus/Newick `phylo` tree, species and response columns,
optional fixed RHS terms for `mu1`, `mu2`, `sigma1`, and `sigma2`, and a
dry-run mode. It writes `formula.txt`, `preflight.csv`, and, when fitting,
`fit-summary.csv`, `fit-conditions.csv`, `fixed-effects.csv`,
`covariance.csv`, `corpairs.csv`, `sdpars.csv`, `rho12-summary.csv`,
`profile-targets.csv`, `check-rows.csv`, and `fit.rds`.

The improvement path and formula gallery now point to the runner as the Phase 2
Objective 1 harness.

## Mathematical Contract

The runner always fits the q2 Objective 1 model:

```r
bf(
  mu1 = response1 ~ mu1_rhs + phylo(1 | p | species, tree = tree),
  mu2 = response2 ~ mu2_rhs + phylo(1 | p | species, tree = tree),
  sigma1 = ~ sigma1_rhs,
  sigma2 = ~ sigma2_rhs,
  rho12 = ~ 1
)
```

The phylogenetic `corpairs()` row is the shared-ancestry location-location
correlation. `rho12()` is the residual complete-row correlation after fixed and
phylogenetic effects. The runner does not fit q4 location-scale phylogenetic
covariance and does not introduce class-specific covariance syntax.

## Files Changed

- `tools/ayumi-santi-q2-objective1-runner.R`
- `docs/design/76-ayumi-santi-phylo-model-improvement-path.md`
- `docs/design/77-ayumi-santi-protocol-formula-gallery.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-24-ayumi-santi-q2-objective1-runner.md`
- `docs/dev-log/recovery-checkpoints/2026-05-24-142024-codex-checkpoint.md`

## Checks Run

```sh
air format tools/ayumi-santi-q2-objective1-runner.R
Rscript --vanilla tools/ayumi-santi-q2-objective1-runner.R --help
Rscript --vanilla -e 'invisible(parse(file = "tools/ayumi-santi-q2-objective1-runner.R")); cat("parse ok\n")'
Rscript --vanilla -e 'tmp <- tempfile("q2-runner-fit-"); dir.create(tmp); requireNamespace("ape", quietly = TRUE) || stop("ape missing"); set.seed(24); tree <- ape::stree(16, type = "balanced"); tree$tip.label <- paste0("sp", seq_along(tree$tip.label)); tree$edge.length <- rep(1, nrow(tree$edge)); dat <- data.frame(species = tree$tip.label, y1 = rnorm(16), y2 = rnorm(16)); data_path <- file.path(tmp, "dat.rds"); tree_path <- file.path(tmp, "tree.rds"); out <- file.path(tmp, "out"); saveRDS(dat, data_path); saveRDS(tree, tree_path); status <- system2("Rscript", c("--vanilla", "tools/ayumi-santi-q2-objective1-runner.R", "--data", data_path, "--tree", tree_path, "--species", "species", "--response1", "y1", "--response2", "y2", "--se", "false", "--output-dir", out), stdout = TRUE, stderr = TRUE); cat(paste(status, collapse = "\n"), "\n", sep = ""); if (file.exists(file.path(out, "fit-summary.csv"))) cat(readLines(file.path(out, "fit-summary.csv")), sep = "\n")'
rg -n 'q4.*routine|routine.*q4|rho12.*phylogenetic|phylogenetic.*rho12|class-specific.*implemented|posterior pooling.*implemented|meta_gaussian\(|tau ~|rho ~|Santi|Ayumi|Objective 1|q2 Objective 1' docs/design/76-ayumi-santi-phylo-model-improvement-path.md docs/design/77-ayumi-santi-protocol-formula-gallery.md tools/ayumi-santi-q2-objective1-runner.R README.md ROADMAP.md NEWS.md vignettes docs/design --glob '!docs/design/76-ayumi-santi-phylo-model-improvement-path.md' --glob '!docs/design/77-ayumi-santi-protocol-formula-gallery.md'
gh issue list --repo itchyshin/drmTMB --state open --search "Ayumi Santi q2 Objective 1 phylogenetic runner" --limit 20 --json number,title,state,url,labels
gh issue list --repo itchyshin/drmTMB --state open --search "PV2 locphylo Objective 1 phylogenetic" --limit 20 --json number,title,state,url,labels
git diff --check
Rscript tools/codex-checkpoint.R --goal "Ayumi/Santi q2 Objective 1 runner" --next "Run tools/ayumi-santi-q2-objective1-runner.R --dry-run true on prepared Santi mammal and avian Objective 1 data"
```

The temporary 16-species smoke fit returned convergence code 0 with maximum
absolute gradient `1.48e-06`. It used `--se false`, so `pdHess` was deliberately
blank.

The recovery checkpoint was written after the checks so the next agent can see
the branch, dirty files, newest check-log entry, and next dry-run target before
editing.

## Tests Of The Tests

The smoke fit exercises the real script path: argument parsing, data and tree
loading, species matching, formula construction, `devtools::load_all()`, a q2
phylogenetic model fit, extraction, and CSV/RDS artifact writing. The dry-run
path was also checked on a temporary fixture and wrote the expected q2 formula.

This is not a biological validation test. It only proves the harness can run a
small q2 Objective 1 fit and write the expected diagnostics.

## Consistency Audit

The design docs now say the runner is developer-only and that users should run
`--dry-run true` before long applied fits. The stale-wording scan found expected
existing mentions of Ayumi, q4, `rho12`, `tau`, and `meta_gaussian()` in
roadmap, NEWS, design, and vignette files; it did not expose a new overclaim
from this slice.

No roxygen, package API, likelihood parameterization, formula grammar, NEWS, or
pkgdown navigation changed.

## GitHub Issue Maintenance

Issue searches for `"Ayumi Santi q2 Objective 1 phylogenetic runner"` and
`"PV2 locphylo Objective 1 phylogenetic"` returned no exact open issue. I did
not open or mutate an issue from this mixed dirty branch.

## What Did Not Go Smoothly

The repository still has substantial unrelated dirty work from NB2, pkgdown,
roadmap, and phylogenetic direct-SD lanes. This runner is therefore a local
applied harness, not a clean PR-sized package change yet.

## Team Learning

For applied phylogenetic work, the next shared tool should start with dry-run
preflight artifacts. That makes species matching, tree status, formula terms,
and estimands reviewable before a long fit produces tempting but unvetted
numbers.

## Known Limitations

No real Ayumi or Santi dataset was fitted in this slice. The runner assumes
responses and covariates are already prepared and transformed. It does not loop
over tree sets, compute profiles or bootstraps, fit q4, fit class-specific
covariance, or make biological interpretations.

## Next Actions

Run the harness in `--dry-run true` mode on Santi's mammal and avian Objective
1 prepared datasets, then fit one representative tree for each if the preflight
tables look clean. After that, repeat across a small tree set and build the
compact applied table with phylogenetic `corpairs()` and residual `rho12()` in
separate columns.
