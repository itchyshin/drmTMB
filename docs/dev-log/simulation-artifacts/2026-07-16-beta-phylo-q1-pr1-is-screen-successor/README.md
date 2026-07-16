# Beta phylogenetic q1 successor importance screen

**Status:** `INCONCLUSIVE`; D1 not authorized

This five-dataset Totoro screen ran from the clean pushed head
`da1a2fcc93f32d544b060344ac0f5e680301e2bf` with TMB 1.9.21 and one BLAS
thread per worker. The runner authenticated the complete protected tree, all
prior design hashes, the frozen 24-row diagnostic design, and zero seed
overlap before dispatch. Only the five predeclared D0 rows were fitted.

All five source fits returned convergence code zero and `pdHess = TRUE`.
Every marginal fixed-parameter Hessian was positive definite, with condition
numbers from 194 to 1,034. Pair-level importance weights were exceptionally
stable: at the `n = 32,768` rungs, ESS ranged from 32,765 to 32,768 and the
largest normalized pair weight was below `4e-5`. The two maximum-rung batches
agreed within the frozen `0.05` implied-shift tolerance for all five datasets.

The predeclared sign-stability condition passed only for replicates 3 and 5.
In replicates 1, 2, and 4, the implied log-latent-SD shift changed sign between
`n = 8,192` and `n = 32,768`. The largest-rung shifts were small, but the
contract is fail-closed: `2/5` complete passes gives `INCONCLUSIVE`, not
`PASS_TO_D1`. No corrected-refit D1 campaign ran, and this result supports no
causal claim about Laplace error versus finite information.

The exact command was:

```sh
R_PROFILE_USER=/dev/null OPENBLAS_NUM_THREADS=1 \
  Rscript --no-init-file tools/run-beta-phylo-q1-is-diagnostic.R \
  --mode=screen --cores=5 \
  --output=/home/snakagaw/drmtmb_results/2026-07-16-beta-phylo-q1-pr1-is-screen-da1a2fcc
```

Load-bearing SHA-256 values after exact Totoro-to-local read-back:

```text
fefc3ca7cd143f946cbd68d2a99ddfab56ad2acb5001659911d393bb6dbdce6f  design.tsv
378611d6f5a20a001e7146df183a55e97ce9002fd1eddd90c6cd2dd115026826  importance-screen.tsv
2730a17c93453d8ea65aec70257a8f3744fc040d7d31ff92c32174c12db9fc3f  preflight-manifest.tsv
5d007463d543b872550bfafe1d3a487bbd0c6f63492c9f271f6dde4b38a25566  run-provenance.tsv
16a3aa31ee05b15283cd8ac4780bd404d319973250b45202378beaa0fe1d867f  screen-decision.tsv
24cedf9dc8785adbc7eed62edfe32ddcee7d56052b40f5142b94fd2e5cb61bcd  screen-gates.tsv
d4c4ca96ab5139224d1af91353618c742cd49f5bb5d942b1e81496458d61dc96  seed-audit.tsv
d33d6d9cd64aabb82fd053a2f9fd8a2b8982af1e733e1288dffea31104259148  session-info.txt
```
