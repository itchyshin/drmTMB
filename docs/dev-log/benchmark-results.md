# Benchmark Results

This file records selected development benchmark results from ignored CSV
outputs. Use it as evidence for internal planning, not as a public performance
claim.

## Large Phylogenetic Gaussian Location Model

All rows use a balanced synthetic tree, Gaussian responses,
`phylo(1 | species, tree = tree)`, and the same small numeric fixed-effect
location formula unless the `Factor levels` column says otherwise. The macOS
peak-memory values come from `/usr/bin/time -l`. `R heap after fit MB` is a
post-fit garbage-collector summary, not peak memory.
Rows collected before the 2026-05-10 `gc_used_mb()` cell-weight fix should use
this column only as rough historical context; prefer object sizes, max RSS, and
peak footprint when interpreting those rows.

| Date | Rows | Species | Family | Sigma formula | Factor levels | Memory-light | Status | Convergence | Fit seconds | Fit object MB | Model matrix MB | TMB data MB | R heap after fit MB | Max RSS bytes | Peak footprint bytes |
| --- | ---: | ---: | --- | --- | ---: | --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 2026-05-10 | 10,000 | 100 | Gaussian | `sigma ~ 1` | 0 | yes | timing usable | 0 | 2.283 | 4.658 | 1.528 | 2.140 | 251.397 | 454,672,384 | 332,383,288 |
| 2026-05-10 | 100,000 | 1,000 | Gaussian | `sigma ~ 1` | 0 | yes | timing usable | 0 | 25.074 | 45.730 | 15.261 | 21.326 | 405.741 | 1,415,626,752 | 723,666,504 |
| 2026-05-10 | 100,000 | 1,000 | Gaussian | `sigma ~ 1` | 0 | yes | timing usable, corrected heap | 0 | 28.450 | 45.730 | 15.261 | 21.326 | 165.544 | 1,401,323,520 | 721,061,472 |
| 2026-05-10 | 100,000 | 1,000 | Gaussian | `sigma ~ 1` | 0 | no | timing usable | 0 | 25.070 | 54.935 | 15.261 | 21.326 | 500.926 | 1,399,848,960 | 678,839,880 |
| 2026-05-10 | 100,000 | 1,000 | Gaussian | `sigma ~ x1` | 0 | yes | timing usable | 0 | 62.701 | 47.257 | 16.024 | 22.089 | 416.295 | 1,779,056,640 | 742,148,088 |
| 2026-05-10 | 100,000 | 1,000 | Gaussian | `sigma ~ 1` | 40 | yes | diagnostic only | 1 | 77.712 | 105.289 | 45.019 | 51.084 | 622.011 | 2,123,055,104 | 797,017,960 |
| 2026-05-10 | 100,000 | 5,000 | Gaussian | `sigma ~ 1` | 0 | yes | timing usable | 0 | 32.492 | 52.764 | 15.261 | 22.669 | 417.313 | 1,654,964,224 | 664,749,976 |
| 2026-05-10 | 500,000 | 1,000 | Gaussian | `sigma ~ 1` | 0 | yes | timing usable | 0 | 131.407 | 221.206 | 76.296 | 105.249 | 1092.205 | 5,050,040,320 | 2,045,808,360 |
| 2026-05-10 | 500,000 | 1,000 | Gaussian | `sigma ~ 1` | 0 | yes | timing usable, repeat | 0 | 133.997 | 221.206 | 76.296 | 105.249 | 1092.205 | 5,066,604,544 | 2,028,277,504 |

Interpretation:

- The 100k default-storage run retained about 9.2 MB more fitted-object state
  and used about 95 MB more post-fit R heap than the memory-light run.
  The post-fit R-heap comparison uses historical rows collected before the
  heap-weight fix; use it only as rough context.
- The memory-light rows use all three post-fit storage controls:
  `keep_data = FALSE`, `keep_model_frame = FALSE`, and
  `keep_tmb_object = FALSE`.
- The fresh corrected-heap 100k baseline reported 165.544 MB post-fit R heap,
  compared with about 1.4 GB macOS max RSS and a 45.730 MB fitted object.
- The two 100k runs had similar operating-system peak footprints. This is
  expected because the current storage controls drop objects after model
  construction and optimization; they do not yet reduce construction-time peak
  memory.
- The 100k rows / 5k species row and the 500k rows / 1k species row separate
  species-index pressure from row-count pressure. Both converged, but the
  500k-row run reached about 5.1 GB macOS max RSS on the test machine.
- The repeated 500k rows / 1k species baseline converged with the same
  optimizer message, 50 iterations, and 74 function evaluations. Fit seconds
  were 131.407 and 133.997, with macOS max RSS of 5,050,040,320 and
  5,066,604,544 bytes.
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
