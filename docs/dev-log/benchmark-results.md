# Benchmark Results

This file records selected development benchmark results from ignored CSV
outputs. Use it as evidence for internal planning, not as a public performance
claim.

## Large Phylogenetic Gaussian Location Model

All rows use a balanced synthetic tree, Gaussian responses, and
`phylo(1 | species, tree = tree)`. Except where noted, rows use `sigma ~ 1`
and a small fixed-effect location formula. The macOS peak-memory values come
from `/usr/bin/time -l`.

| Date | Rows | Species | Storage | Convergence | Fit seconds | Fit object MB | Model matrix MB | TMB data MB | R heap after fit MB | Max RSS bytes | Peak footprint bytes |
| --- | ---: | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 2026-05-10 | 10,000 | 100 | memory-light | 0 | 2.283 | 4.658 | 1.528 | 2.140 | 251.397 | 454,672,384 | 332,383,288 |
| 2026-05-10 | 100,000 | 1,000 | memory-light | 0 | 25.031 | 45.730 | 15.261 | 21.326 | 405.303 | 1,414,168,576 | 692,831,840 |
| 2026-05-10 | 100,000 | 1,000 | default | 0 | 24.793 | 54.935 | 15.261 | 21.326 | 500.488 | 1,365,606,400 | 682,952,216 |
| 2026-05-10 | 100,000 | 1,000 | memory-light, `sigma ~ x1` | 0 | 62.585 | 47.257 | 16.024 | 22.089 | 415.857 | 1,815,838,720 | 773,457,888 |
| 2026-05-10 | 100,000 | 1,000 | memory-light, 40-level factor | 1 | 77.712 | 105.289 | 45.019 | 51.084 | 622.011 | 2,123,055,104 | 797,017,960 |

Interpretation:

- The 100k default-storage run retained about 9.2 MB more fitted-object state
  and used about 95 MB more post-fit R heap than the memory-light run.
- The memory-light rows use all three post-fit storage controls:
  `keep_data = FALSE`, `keep_model_frame = FALSE`, and
  `keep_tmb_object = FALSE`.
- The two 100k runs had similar operating-system peak footprints. This is
  expected because the current storage controls drop objects after model
  construction and optimization; they do not yet reduce construction-time peak
  memory.
- Sparse fixed-effect matrices and sufficient-statistic aggregation remain the
  next features needed before making stronger claims about million-row data.
- The 40-level-factor row is a diagnostic stress run, not an accepted timing
  result, because `nlminb()` returned convergence code 1 with the message
  `function evaluation limit reached without convergence (9)` under the
  benchmark iteration settings. A rerun with `eval.max = 400` and
  `iter.max = 400` still returned convergence code 1, now with
  `false convergence (8)`. It still shows the dense fixed-effect matrix
  pressure that sparse design matrices and convergence diagnostics need to
  address.
