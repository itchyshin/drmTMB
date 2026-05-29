# After Task: Sparse Phylo Source Map

## Goal

Resume the `codex/sparse-phylo-source-map` branch from repository evidence and
turn the sparse-phylogeny GLLVM.jl lesson into a verified `drmTMB` source map,
without changing likelihood code.

## Implemented

`docs/design/09-phylogenetic-and-spatial-speed.md` now records that `drmTMB`
already uses an augmented sparse Brownian-motion precision for fitted
`phylo()` structured effects. The note maps the current R helper, TMB data
contract, C++ likelihood declaration, and dense-parity tests, then reframes the
next step as a benchmark and API gate rather than an implementation-from-scratch
task.

The broad untracked Claude note remains triage input. This task did not promote
that note to the project plan because several of its sparse-phylogeny claims
describe work that is already present in current `drmTMB` source.

## Source Evidence

- `R/phylo-utils.R` validates ultrametric trees, builds dense Brownian
  comparators for small tests, and constructs `drm_phylo_augmented_precision()`.
- `R/drmTMB.R` routes structured terms through `build_structured_mu_structure()`
  and `make_tmb_data()`, including `Q_phylo`, `log_det_Q_phylo`, node indices,
  endpoint labels, and block metadata.
- `src/drmTMB.cpp` declares `DATA_SPARSE_MATRIX(Q_phylo)` and uses
  `Q_phylo * u` quadratic forms in the fitted phylogenetic prior paths.
- `tests/testthat/test-phylo-utils.R` and `tests/testthat/test-phylo-gaussian.R`
  contain sparse-versus-dense and fitted-objective comparator checks.

## Checks Run

```sh
gh pr list --limit 10 --state open
gh issue list --repo itchyshin/drmTMB --state open --search 'sparse phylo precision Hadfield Nakagawa relmat' --limit 20 --json number,title,state,url,labels
rg -n "Q_phylo|log_det_Q_phylo|phylo_mu_node_index|build_structured_mu_structure|empty_phylo_mu_structure|make_tmb_data|DATA_SPARSE_MATRIX" R src tests/testthat/test-phylo-utils.R tests/testthat/test-phylo-gaussian.R
rg -n "dense Brownian comparator|fitted phylogenetic mu objective|ordinary and phylogenetic species intercepts|phylogenetic meta-analysis objective" tests/testthat/test-phylo-utils.R tests/testthat/test-phylo-gaussian.R
Rscript --vanilla -e "devtools::test(filter = 'phylo-utils', reporter = 'summary')"
git diff --check
```

Result: no open PRs or matching sparse-phylo issue were found. The source scan
confirmed the existing sparse precision helper, TMB data path, C++ sparse
matrix declaration, and structured-term TMB data. The comparator scan found the
dense Brownian and dense marginal-likelihood phylogenetic tests cited by the
design note. `test-phylo-utils.R` passed, and `git diff --check` was clean.

## Team Learning

Ada kept the resumed slice design-only because likelihood code was already
present. Jason treated GLLVM.jl as a source-map prompt rather than a directive.
Gauss and Noether checked that the current implementation already evaluates a
sparse structured Gaussian prior. Grace limited validation to source scans and
issue/PR state because no code changed. Rose kept the untracked Claude note out
of the plan of record until each claim is source-checked.

No spawned subagents were running.

## Known Limitations

This task does not benchmark current sparse phylogenetic scaling, add matrix
inputs to `phylo()`, add a dense-versus-sparse switch, change `relmat()`, or
make a coverage or runtime claim. The next implementation slice should first
specify the benchmark cells, API boundary, diagnostics, and provenance rules.
