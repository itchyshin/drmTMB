# valgrind — candidate `302ac2579`, seven-file subset, adjudicated CLEAN

**2026-08-15 21:19–21:37 UTC · Totoro · valgrind-3.22.0 · R 4.5.3 · total 17m45s**

## What ran

The exact frozen tarball (`0d150ef38b8d3b8b2d3dca084a62f8242832048b01e60caa4b08c5388b95e075`,
**SHA-256 re-verified on Totoro before installation**) was installed into a fresh library and the
**same seven-file subset** the superseded candidate documented was run under

```
R -d "valgrind --tool=memcheck --leak-check=full" --vanilla
```

one `testthat::test_file()` per process. Flags are stated because they differ from whatever
produced the prior candidate's "0 errors from 0 contexts" (that run's flags are not recoverable);
comparisons across the two candidates should compare *adjudications*, not raw context counts.

## Result — mechanical rule: any `drmTMB.so` frame in an error backtrace = FAIL

| file | elapsed | test failures | `drmTMB.so` frames | contexts (upstream) | definitely lost |
| --- | --- | --- | --- | --- | --- |
| family-dpq-batchC | 55s | 0 | **0** | 13 | 0 bytes |
| gaussian-random-intercepts | 205s | 0 | **0** | 30 | 0 bytes |
| count-structured-mu | 192s | 0 | **0** | 52 | 0 bytes |
| score-consistency | 225s | 0 | **0** | 34 | 0 bytes |
| nbinom2-location-scale | 125s | 0 | **0** | 9 | 0 bytes |
| adequacy | 54s | 0 | **0** | 11 | 0 bytes |
| phylo-gaussian | 209s | 0 | **0** | 41 | 0 bytes |

**Verdict: CLEAN on the documented subset, adjudicated by provenance.** Zero errors attributable
to drmTMB's compiled code; zero bytes definitely or indirectly lost in any file; zero test
failures under valgrind. The 190 upstream contexts sit in `cli`'s progress-thread creation
(glibc `pthread_create`/`allocate_dtv` TLS), `libR.so`, and TMB/CppAD headers
(`tmb_core.hpp:1497`, `thread_alloc.hpp:897`, `pod_vector.hpp:176`) — the same upstream class the
prior candidate's rchk adjudication documented for `tmb_core.hpp`. A pre-run on one file
established this provenance before the seven-file run was launched.

## What this does and does not prove

Cite as *"valgrind clean on the documented seven-file subset, zero drmTMB-attributable
findings"* — never as *"valgrind clean"* unqualified. The full suite exceeded R-hub's 6-hour
ceiling in the 0.6.0 era and was not attempted. Raw logs: Totoro
`~/drmtmb-valgrind-302ac2579/logs/valgrind-*.log`; per-file summary committed here as
`valgrind-seven.log` / `valgrind-seven-summary.txt`.
